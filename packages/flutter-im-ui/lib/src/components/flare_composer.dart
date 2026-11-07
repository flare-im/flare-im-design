import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'flare_inline_voice.dart';
import 'flare_mention_picker.dart';
import '../emoji_sticker/flare_composer_emoji_span_builder.dart';
import '../emoji_sticker/flare_emoji_sticker_catalog.dart';
import '../emoji_sticker/flare_emoji_sticker_picker.dart';
import 'composer/rich_text_composer_formatter.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'composer/flare_composer_action_panel.dart';
import 'composer/flare_composer_parts.dart';
import '../models/directory_data.dart' show FlareMentionCandidate;
import '../models/form_behavior.dart';
import '../models/display_name.dart' show flareQuoteSenderText;
import '../models/message_data.dart' show FlareReplyTarget;
import '../platform/flare_platform.dart';

export 'composer/flare_composer_action_panel.dart';
export 'composer/flare_composer_parts.dart';
export 'composer/flare_voice_hold_button.dart';
export '../models/message_data.dart' show FlareReplyTarget;

enum FlareComposerSubmitMode { enter, modifierEnter }

enum _ComposerPanel { emoji, mention, more }

/// The message input — the **complete, ready-to-use** composer, assembled from
/// composable parts (voice / attach panel / emoji / send / reply strip). Spec:
/// Composer/Composer (`FlareComposer`). [onSend] reports whether the send was
/// accepted; the text and the reply clear only then. The host owns local echo
/// and persistence.
///
/// Free composition: the parts are exported (`FlareVoiceHoldButton`,
/// `FlareComposerActionPanel`, `FlareComposerIconButton`, `FlareComposerSendButton`,
/// `FlareComposerReplyStrip`) so a product can build its own bar instead.
/// The two shapes a composer takes, resolved once from the width it is given so
/// build() reads as one composer with values in it rather than two layouts
/// interleaved.
///
/// [wide] follows the same container breakpoint as the Web composer. A wide
/// chat puts the field and compact tools on one flat footer row; a narrower
/// chat keeps full touch targets on a second row.
class _Metrics {
  const _Metrics({
    required this.wide,
    required this.mobile,
    required this.text,
    required this.stripHeight,
    required this.stripInset,
    required this.toolInset,
  });

  final bool wide;
  final bool mobile;
  final EdgeInsets text;
  final double stripHeight;
  final double stripInset;
  final double toolInset;

  factory _Metrics.of(double width, int keys, {required bool mobile}) {
    // The Web kit's FLARE_BREAKPOINT_TABLET_MIN is the same 600px boundary.
    if (width >= FlareSizes.navigationRailMinWidth) {
      return _Metrics(
        wide: true,
        mobile: mobile,
        text: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        stripHeight: 32,
        stripInset: 0,
        toolInset: 0,
      );
    }
    // 11 above and below a 24px line is a 46px band: the text sits in the middle
    // of it without the field growing into a panel of its own. The tool inset is
    // whatever the keys do not need, up to 10 — seven 44px targets already fill
    // a 320px screen, and the targets are the part that must not shrink.
    return _Metrics(
      wide: false,
      mobile: mobile,
      text: const EdgeInsets.fromLTRB(16, 11, 0, 11),
      stripHeight: FlareSizes.componentComposerActionWidth,
      stripInset: 6,
      toolInset: ((width - keys * 44.0) / 2).clamp(0.0, 10.0),
    );
  }
}

class FlareComposer extends StatefulWidget {
  const FlareComposer({
    super.key,
    this.conversationKey = '',
    this.specialTextSpanBuilder,
    this.controller,
    this.focusNode,
    this.onSendRich,
    this.onImage,
    this.rich = false,
    this.placeholder,
    this.disabled = false,
    this.replyTo,
    this.maxLength,
    this.onSend,
    this.onAttach,
    this.onEmoji,
    this.onSendSticker,
    this.onTyping,
    this.onCancelReply,
    this.actions,
    this.capabilities = const FlareComposerCapabilities(),
    this.onAction,
    this.replyLabel,
    this.enableVoice = false,
    this.voiceLabel,
    this.voiceRecordingLabel,
    this.voiceCancelLabel,
    this.onVoiceSend,
    this.onVoiceStart,
    this.onVoiceEnd,
    this.onVoiceCancel,
    this.desktopSubmitMode = FlareComposerSubmitMode.enter,
    this.mentionCandidates = const [],
    this.enableMentions = true,
  });

  final String conversationKey;
  final SpecialTextSpanBuilder? specialTextSpanBuilder;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSendRich;
  final VoidCallback? onImage;
  final bool rich;

  /// Copy for the inline reply strip and the hold-to-talk button. Defaults are
  /// Chinese; hosts localize by passing their own.
  final String? replyLabel;
  final String? voiceLabel;
  final String? voiceRecordingLabel;
  final String? voiceCancelLabel;
  final String? placeholder;
  final bool disabled;
  final FlareReplyTarget? replyTo;
  final int? maxLength;

  /// Sends [text] and answers whether it went out. The field clears — and
  /// [onCancelReply] drops the reply — only on true. While a returned Future
  /// is pending the send key shows busy and repeat sends are ignored; false
  /// or a thrown error keeps the text for another try.
  final FutureOr<bool> Function(String text)? onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onEmoji;
  final void Function(String packageId, String stickerId)? onSendSticker;
  final ValueChanged<String>? onTyping;
  final VoidCallback? onCancelReply;

  /// When provided, the "+" button toggles an inline action panel (下方功能区)
  /// with these actions; otherwise "+" calls [onAttach].
  final List<FlareComposerAction>? actions;
  final FlareComposerCapabilities capabilities;
  final void Function(FlareComposerAction action)? onAction;

  /// Show the voice (按住说话) toggle.
  final bool enableVoice;
  final Future<bool> Function(String path, int durationMs)? onVoiceSend;
  final VoidCallback? onVoiceStart;
  final VoidCallback? onVoiceEnd;
  final VoidCallback? onVoiceCancel;
  final FlareComposerSubmitMode desktopSubmitMode;

  /// Members to mention. Typing "@" at the start of a word, or the mention
  /// tool, opens a [FlareMentionPicker] over them; a pick writes "@name ".
  /// Empty, both only put in "@".
  final List<FlareMentionCandidate> mentionCandidates;

  /// Whether this conversation supports mentions. Pass false for 1:1 chats so
  /// the desktop tool row matches Web instead of showing an inert `@` action.
  /// A group may keep this true while its roster is still loading.
  final bool enableMentions;

  @override
  State<FlareComposer> createState() => FlareComposerState();
}

class FlareComposerState extends State<FlareComposer> {
  bool _allowsTool(String id) => widget.capabilities.allowsTool(id);
  bool get _effectiveRich =>
      _allowsTool('richText') && (_richMode || widget.rich);
  List<FlareComposerAction> get _resolvedActions => resolveFlareComposerActions(
    actions: widget.actions,
    capabilities: widget.capabilities,
  );
  bool get _hasActionPanel =>
      _resolvedActions.isNotEmpty &&
      (widget.actions != null || widget.onAttach == null);

  /// "+" with nothing to open or attach is hidden, not drawn disabled.
  bool get _plusShown =>
      _allowsTool('attachments') &&
      (_hasActionPanel || widget.onAttach != null);
  String get _placeholder =>
      widget.placeholder ?? FlareStrings.of(context).composerPlaceholder;
  String get _replyLabel =>
      widget.replyLabel ?? FlareStrings.of(context).composerReply;
  late TextEditingController _controller;
  late bool _ownsController;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  _ComposerPanel? _panel;
  bool _expanded = false;
  bool _richMode = false;
  bool _formatLevelsOpen = false;
  RichComposerFormatting _formatting = const RichComposerFormatting();
  void dismissPanel() {
    if (_panel != null) setState(_closeTransientPanels);
  }

  bool _canSend = false;
  bool _voiceMode = false;
  bool _sending = false;
  int? _typedMentionOffset;
  TextEditingValue _lastValue = TextEditingValue.empty;
  bool _suppressTyping = false;

  List<FlareMentionCandidate> get _availableMentionCandidates =>
      widget.disabled || !widget.enableMentions || !_allowsTool('mention')
      ? const []
      : widget.mentionCandidates;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _canSend = _controller.text.trim().isNotEmpty;
    _lastValue = _controller.value;
    _controller.addListener(_changed);
    FlareEmojiStickerCatalog.instance.addListener(_emojiCatalogChanged);
    FlareEmojiStickerCatalog.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _emojiCatalogChanged() {
    if (mounted) setState(() {});
  }

  /// The composer's own clear — after a send, or when the conversation changes — is not an edit by the
  /// person, so [FlareComposer.onTyping] stays quiet for it. A host driving a typing signal from
  /// `onTyping` would otherwise read the composer's housekeeping as someone typing.
  void _clearWithoutTyping() {
    _suppressTyping = true;
    try {
      _controller.clear();
    } finally {
      _suppressTyping = false;
    }
  }

  void _changed() {
    final previous = _lastValue;
    final wasMultiline = _textNeedsMultipleLines(previous.text);
    final value = _controller.value;
    final typedAt = _typedMentionAt(previous, value);
    // A controller notifies for the caret and the selection too. Tapping into a composer that already
    // holds a draft changes nothing about the text, and must not tell the conversation someone is typing.
    final textChanged = previous.text != value.text;
    _lastValue = value;
    final can = value.text.trim().isNotEmpty;
    final isMultiline = _textNeedsMultipleLines(value.text);
    if (can != _canSend ||
        wasMultiline != isMultiline ||
        (_typedMentionOffset != null && previous != value)) {
      setState(() {
        _canSend = can;
        if (_typedMentionOffset != null && _typedMentionRange(value) == null) {
          _closeTransientPanels();
        }
      });
    }
    if (textChanged && !_suppressTyping) widget.onTyping?.call(value.text);
    if (typedAt != null && _availableMentionCandidates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller.value == value &&
            _availableMentionCandidates.isNotEmpty) {
          setState(() {
            _closeTransientPanels();
            _panel = _ComposerPanel.mention;
            _typedMentionOffset = typedAt;
          });
        }
      });
    }
  }

  static bool _textNeedsMultipleLines(String text) =>
      text.contains('\n') || text.length > 56;

  void _focusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _closeTransientPanels() {
    _panel = null;
    _typedMentionOffset = null;
    _formatLevelsOpen = false;
  }

  void _togglePanel(_ComposerPanel panel, {required bool hideKeyboard}) {
    if (hideKeyboard) _focusNode.unfocus();
    final next = _panel == panel ? null : panel;
    setState(() {
      _closeTransientPanels();
      _panel = next;
    });
  }

  void _toggleExpanded() {
    _focusNode.unfocus();
    setState(() {
      _closeTransientPanels();
      _expanded = !_expanded;
    });
  }

  /// Where "@" was just typed at the start of a word as a pure insertion
  /// (keystroke, input-method commit or paste), or null. An "@" the input
  /// method is still composing does not count.
  static int? _typedMentionAt(TextEditingValue before, TextEditingValue after) {
    final text = after.text;
    final caret = after.selection;
    if (text.length != before.text.length + 1 || !caret.isCollapsed) {
      return null;
    }
    final at = caret.baseOffset - 1;
    if (at < 0 || at >= text.length || text[at] != '@') return null;
    if (text.substring(0, at) != before.text.substring(0, at) ||
        text.substring(at + 1) != before.text.substring(at)) {
      return null;
    }
    final composing = after.composing;
    if (composing.isValid && composing.start <= at && at < composing.end) {
      return null;
    }
    return at == 0 || text[at - 1].trim().isEmpty ? at : null;
  }

  TextRange? _typedMentionRange(TextEditingValue value) {
    final start = _typedMentionOffset;
    final caret = value.selection.end;
    if (start == null ||
        !value.selection.isCollapsed ||
        caret <= start ||
        caret > value.text.length ||
        value.text[start] != '@' ||
        value.text.substring(start + 1, caret).contains(RegExp(r'\s'))) {
      return null;
    }
    return TextRange(start: start, end: caret);
  }

  void _onMention(_Metrics m) {
    if (_panel == _ComposerPanel.mention ||
        _availableMentionCandidates.isNotEmpty) {
      _togglePanel(_ComposerPanel.mention, hideKeyboard: m.mobile);
    } else {
      if (m.mobile) _focusNode.unfocus();
      dismissPanel();
      _insert('@');
    }
  }

  /// Use the latest authorized roster even if an older row callback runs.
  void _selectMention(FlareMentionCandidate picked) {
    if (_panel != _ComposerPanel.mention) return;
    final current = _availableMentionCandidates
        .where(
          (candidate) =>
              candidate.id == picked.id &&
              candidate.isEveryone == picked.isEveryone,
        )
        .firstOrNull;
    if (current == null) return;
    final mention = '@${current.name} ';
    final range = _typedMentionRange(_controller.value);
    if (_typedMentionOffset != null && range == null) return;
    setState(_closeTransientPanels);
    if (range != null) {
      _controller.value = TextEditingValue(
        text: _controller.text.replaceRange(range.start, range.end, mention),
        selection: TextSelection.collapsed(
          offset: range.start + mention.length,
        ),
      );
      if (!_focusNode.hasFocus) _focusInput();
    } else {
      _insert(mention);
    }
  }

  @override
  void didUpdateWidget(covariant FlareComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Revocation changes presentation immediately, including already-open
    // panels. The controller/draft is deliberately not cleared.
    final panelAvailable = switch (_panel) {
      _ComposerPanel.emoji => _allowsTool('emoji'),
      _ComposerPanel.mention => widget.enableMentions && _allowsTool('mention'),
      _ComposerPanel.more => _allowsTool('attachments') && _hasActionPanel,
      null => true,
    };
    if (widget.disabled || !panelAvailable) _closeTransientPanels();
    if (widget.disabled || !_allowsTool('voice') || !widget.enableVoice)
      _voiceMode = false;
    if (widget.disabled || !_allowsTool('richText')) {
      _richMode = false;
      _formatLevelsOpen = false;
      _formatting = const RichComposerFormatting();
    }
    if (widget.controller != oldWidget.controller) {
      if (_panel == _ComposerPanel.mention) _closeTransientPanels();
      _controller.removeListener(_changed);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_changed);
      _canSend = _controller.text.trim().isNotEmpty;
      _lastValue = _controller.value;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.conversationKey != oldWidget.conversationKey) {
      if (_ownsController) _clearWithoutTyping();
      _voiceMode = false;
      _closeTransientPanels();
      _expanded = false;
      _formatting = const RichComposerFormatting();
      _richMode = false;
    }
  }

  @override
  void dispose() {
    FlareEmojiStickerCatalog.instance.removeListener(_emojiCatalogChanged);
    _controller.removeListener(_changed);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (widget.disabled ||
        _sending ||
        text.isEmpty ||
        (widget.onSend == null && widget.onSendRich == null))
      return;
    if (_effectiveRich && widget.onSendRich != null) {
      widget.onSendRich!(
        RichComposerMarkdownSerializer.serialize(text, _formatting),
      );
      _clearWithoutTyping();
      setState(() {
        _expanded = false;
        _closeTransientPanels();
      });
      return;
    }
    final onSend = widget.onSend;
    if (onSend == null) return;
    var sent = false;
    try {
      final result = onSend(text);
      if (result is Future<bool>) {
        setState(() => _sending = true);
        sent = await result;
      } else {
        sent = result;
      }
    } catch (_) {
      // A thrown error is a failed send: the text stays for another try.
    } finally {
      if (_sending && mounted) setState(() => _sending = false);
    }
    if (!sent || !mounted) return;
    // Clear what was sent; anything typed while it was on its way stays.
    if (_controller.text.trim() == text) _clearWithoutTyping();
    if (widget.replyTo != null) widget.onCancelReply?.call();
    setState(() {
      _expanded = false;
      _closeTransientPanels();
    });
  }

  bool _shouldSubmit(KeyDownEvent event) {
    if (HardwareKeyboard.instance.isShiftPressed) return false;
    final modifierPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    // Ask the shared contract instead of re-deciding: `composing.isValid` is the
    // IME's half-typed word, and Enter belongs to it until the word is committed.
    final intent = resolveFormKeyboardIntent(
      event.logicalKey == LogicalKeyboardKey.enter
          ? 'enter'
          : event.logicalKey.keyLabel,
      composing: _controller.value.composing.isValid,
      submitOnEnter:
          widget.desktopSubmitMode == FlareComposerSubmitMode.enter ||
          modifierPressed,
    );
    return intent == FlareFormKeyboardIntent.submit;
  }

  void _onPlus(_Metrics m) {
    if (widget.disabled || !_allowsTool('attachments')) return;
    if (_hasActionPanel) {
      _togglePanel(_ComposerPanel.more, hideKeyboard: m.mobile);
    } else {
      _focusNode.unfocus();
      dismissPanel();
      widget.onAttach?.call();
    }
  }

  void _activatePanelAction(FlareComposerAction action) {
    if (widget.disabled ||
        !_allowsTool('attachments') ||
        !_resolvedActions.any((x) => x.id == action.id && x.enabled))
      return;
    _focusNode.unfocus();
    // Voice is already a first-class composer mode. The Web composer exposes
    // it both in the toolbar and in the "+" surface; selecting either entry
    // must reach the same recorder instead of asking every host to recreate
    // the composer's private state transition.
    if (action.id == 'voice' &&
        widget.enableVoice &&
        _allowsTool('voice') &&
        widget.onVoiceSend != null) {
      setState(() {
        _voiceMode = true;
        _expanded = false;
        _closeTransientPanels();
      });
      return;
    }
    widget.onAction?.call(action);
    dismissPanel();
  }

  void _onEmoji(_Metrics m) {
    if (widget.disabled || !_allowsTool('emoji')) return;
    final handler = widget.onEmoji;
    if (handler == null) {
      _togglePanel(_ComposerPanel.emoji, hideKeyboard: m.mobile);
      return;
    }
    _focusNode.unfocus();
    setState(_closeTransientPanels);
    handler();
  }

  void _openImage() {
    if (widget.disabled || !_allowsTool('image')) return;
    _focusNode.unfocus();
    setState(_closeTransientPanels);
    (widget.onImage ?? widget.onAttach)?.call();
  }

  void _toggleRichMode() {
    if (widget.disabled || !_allowsTool('richText')) return;
    _focusNode.unfocus();
    setState(() {
      _richMode = !_richMode;
      _closeTransientPanels();
      if (!_richMode) _formatting = const RichComposerFormatting();
    });
  }

  Widget _tool(
    IconData icon,
    String label,
    VoidCallback? action, {
    bool active = false,
    bool enabled = true,
    bool compact = false,
  }) {
    final colors = FlareColors.of(context);
    return IconButton(
      tooltip: label,
      onPressed: widget.disabled || !enabled ? null : action,
      // Desktop uses a denser footprint, not a smaller glyph. Web keeps the
      // toolbar artwork at 20px inside its compact 34–36px controls; shrinking
      // the glyph to 14px made the Flutter desktop footer look visibly weak.
      iconSize: FlareSizes.iconSizeMd,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: compact ? 34 : FlareSizes.componentComposerActionWidth,
        height: compact ? 36 : FlareSizes.componentComposerActionWidth,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size(
          compact ? 34 : FlareSizes.componentComposerActionWidth,
          compact ? 36 : FlareSizes.componentComposerActionWidth,
        ),
        maximumSize: Size(compact ? 34 : 44, compact ? 36 : 44),
      ),
      icon: Icon(
        icon,
        color: !enabled || widget.disabled
            ? colors.textDisabled
            : active
            ? colors.primary
            : colors.textSecondary,
      ),
    );
  }

  void _insert(String insert) {
    final value = _controller.value;
    final start = value.selection.isValid
        ? value.selection.start
        : value.text.length;
    final end = value.selection.isValid
        ? value.selection.end
        : value.text.length;
    _controller.value = TextEditingValue(
      text: value.text.replaceRange(start, end, insert),
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
  }

  Widget _formatControl({
    required String id,
    required String label,
    required Widget glyph,
    required FlareColors colors,
    required bool coarse,
    VoidCallback? onTap,
    bool active = false,
    double? visualWidth,
    double? layoutWidth,
  }) {
    final visualExtent = coarse ? 36.0 : FlareSizes.controlHeightSm;
    final hitExtent = coarse
        ? FlareSizes.touchTargetMin
        : FlareSizes.controlHeightSm;
    final foreground = widget.disabled
        ? colors.textDisabled
        : active
        ? colors.primaryText
        : colors.textSecondary;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: SizedBox(
          key: ValueKey('composer-format-$id'),
          width: layoutWidth ?? hitExtent,
          height: hitExtent,
          child: Center(
            child: Material(
              color: active ? colors.bgSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
              child: InkWell(
                onTap: widget.disabled ? null : onTap,
                borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                child: SizedBox(
                  width: visualWidth ?? visualExtent,
                  height: visualExtent,
                  child: IconTheme(
                    data: IconThemeData(color: foreground, size: 16),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: foreground),
                      child: Center(child: glyph),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formatBar(_Metrics m, FlareColors colors) {
    final s = FlareStrings.of(context);
    final coarse =
        FlarePlatform.of(context).capabilities.pointer ==
        FlarePointerKind.coarse;
    final heading = _formatting.blockStyle == RichComposerBlockStyle.heading
        ? _formatting.headingLevel
        : 0;
    final headingLabel = heading == 0
        ? s.composerParagraph
        : '${s.composerHeading} $heading';

    Text textGlyph(
      String value, {
      FontStyle? style,
      TextDecoration? decoration,
      double size = 14,
    }) => Text(
      value,
      style: TextStyle(
        fontSize: size,
        height: 1,
        fontWeight: FontWeight.w700,
        fontStyle: style,
        decoration: decoration,
        decorationThickness: 2,
      ),
    );

    Widget inlineAction(
      String id,
      String label,
      Widget glyph,
      RichComposerInlineStyle style,
    ) => _formatControl(
      id: id,
      label: label,
      glyph: glyph,
      colors: colors,
      coarse: coarse,
      active: _formatting.isInlineActive(style),
      onTap: () =>
          setState(() => _formatting = _formatting.toggleInline(style)),
    );

    Widget blockAction(
      String id,
      String label,
      Widget glyph,
      RichComposerBlockStyle style,
    ) => _formatControl(
      id: id,
      label: label,
      glyph: glyph,
      colors: colors,
      coarse: coarse,
      active: _formatting.isBlockActive(style),
      onTap: () => setState(() => _formatting = _formatting.toggleBlock(style)),
    );

    Widget groupDivider(String id) => Container(
      key: ValueKey('composer-format-divider-$id'),
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingXs),
      color: colors.borderSecondary,
    );

    Widget headingFace({VoidCallback? onTap}) => _formatControl(
      id: 'heading',
      label: headingLabel,
      glyph: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading == 0 ? 'P' : 'H$heading',
            style: const TextStyle(
              fontSize: FlareSizes.fontSizeLg,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: FlareSizes.spacing3xs),
          Icon(
            _formatLevelsOpen
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 14,
          ),
        ],
      ),
      colors: colors,
      coarse: coarse,
      active: heading > 0,
      onTap: onTap,
      visualWidth: 48,
      layoutWidth: coarse ? 52 : 48,
    );

    final headingControl = coarse
        ? headingFace(
            onTap: () => setState(() => _formatLevelsOpen = !_formatLevelsOpen),
          )
        : PopupMenuButton<int>(
            enabled: !widget.disabled,
            tooltip: headingLabel,
            position: PopupMenuPosition.over,
            initialValue: heading,
            onSelected: (level) => setState(
              () => _formatting = _formatting.withHeadingLevel(
                level == 0 ? null : level,
              ),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 0,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('P'),
                ),
              ),
              for (var level = 1; level <= 6; level++)
                PopupMenuItem(
                  value: level,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('H$level'),
                  ),
                ),
            ],
            child: headingFace(),
          );

    final controls = coarse && _formatLevelsOpen
        ? <Widget>[
            for (var level = 0; level <= 6; level++)
              _formatControl(
                id: level == 0 ? 'paragraph' : 'heading-$level',
                label: level == 0
                    ? s.composerParagraph
                    : '${s.composerHeading} $level',
                glyph: textGlyph(level == 0 ? 'P' : 'H$level', size: 12),
                colors: colors,
                coarse: coarse,
                active: heading == level,
                onTap: () => setState(() {
                  _formatting = _formatting.withHeadingLevel(
                    level == 0 ? null : level,
                  );
                  _formatLevelsOpen = false;
                }),
              ),
          ]
        : <Widget>[
            headingControl,
            inlineAction(
              'bold',
              s.composerBold,
              textGlyph('B'),
              RichComposerInlineStyle.bold,
            ),
            inlineAction(
              'strike',
              s.composerStrike,
              textGlyph('S', decoration: TextDecoration.lineThrough),
              RichComposerInlineStyle.strike,
            ),
            inlineAction(
              'italic',
              s.composerItalic,
              textGlyph('I', style: FontStyle.italic),
              RichComposerInlineStyle.italic,
            ),
            inlineAction(
              'underline',
              s.composerUnderline,
              textGlyph('U', decoration: TextDecoration.underline),
              RichComposerInlineStyle.underline,
            ),
            groupDivider('inline-block'),
            blockAction(
              'ordered',
              s.composerOrderedList,
              const Icon(Icons.format_list_numbered),
              RichComposerBlockStyle.orderedList,
            ),
            blockAction(
              'bullet',
              s.composerList,
              const Icon(Icons.format_list_bulleted),
              RichComposerBlockStyle.bulletList,
            ),
            blockAction(
              'quote',
              s.composerQuote,
              const Icon(Icons.format_quote_outlined),
              RichComposerBlockStyle.quote,
            ),
            groupDivider('block-insert'),
            inlineAction(
              'link',
              s.composerLink,
              const Icon(Icons.link_outlined),
              RichComposerInlineStyle.link,
            ),
            if (_allowsTool('image'))
              _formatControl(
                id: 'image',
                label: s.actionImage,
                glyph: const Icon(Icons.image_outlined),
                colors: colors,
                coarse: coarse,
                onTap: () {
                  if (widget.disabled || !_allowsTool('image')) return;
                  if (widget.onImage != null) {
                    _openImage();
                  } else {
                    _insert('![]()');
                  }
                },
              ),
            inlineAction(
              'code',
              s.composerCode,
              textGlyph('<>', size: 12),
              RichComposerInlineStyle.inlineCode,
            ),
            blockAction(
              'code-block',
              s.composerCodeBlock,
              textGlyph('</>', size: 11),
              RichComposerBlockStyle.codeBlock,
            ),
            _formatControl(
              id: 'horizontal-rule',
              label: s.composerDivider,
              glyph: const Icon(Icons.horizontal_rule),
              colors: colors,
              coarse: coarse,
              onTap: () => _insert('\n---\n'),
            ),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: m.stripHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: m.stripInset),
            child: Row(children: controls),
          ),
        ),
        // The format row owns this lower hairline. The wide rich composer drops
        // its generic top inset below so both sides of the row have the same
        // visual gap, matching the Web/Tauri reference.
        Container(
          key: const ValueKey('composer-format-divider-line'),
          height: 1,
          color: colors.borderPrimary,
        ),
      ],
    );
  }

  // The same ordered tools live beside the field on a wide chat and on their
  // own touch-friendly row below it everywhere else.
  Widget _tools(_Metrics m) {
    final s = FlareStrings.of(context);
    final keys = <Widget>[
      if (m.wide) _resizeTool(m),
      if (_allowsTool('emoji'))
        _tool(
          flareIconGlyph('emoji'),
          s.composerEmoji,
          () => _onEmoji(m),
          active: _panel == _ComposerPanel.emoji,
          compact: m.wide,
        ),
      if (widget.enableMentions && _allowsTool('mention'))
        _tool(
          flareIconGlyph('mention'),
          s.composerMention,
          () => _onMention(m),
          active: _panel == _ComposerPanel.mention,
          compact: m.wide,
        ),
      if (widget.enableVoice && _allowsTool('voice'))
        _tool(
          flareIconGlyph('mic'),
          s.composerVoiceInput,
          widget.onVoiceSend == null
              ? null
              : () {
                  _focusNode.unfocus();
                  setState(() {
                    _voiceMode = true;
                    _expanded = false;
                    _closeTransientPanels();
                  });
                },
          compact: m.wide,
        ),
      if (_allowsTool('image'))
        _tool(
          flareIconGlyph('image'),
          s.actionImage,
          _openImage,
          compact: m.wide,
        ),
      if (_allowsTool('richText'))
        _tool(
          flareIconGlyph('rich-text'),
          s.composerRichText,
          _toggleRichMode,
          active: _effectiveRich,
          compact: m.wide,
        ),
      if (_plusShown)
        _tool(
          flareIconGlyph(_panel == _ComposerPanel.more ? 'close' : 'add'),
          s.more,
          () => _onPlus(m),
          active: _panel == _ComposerPanel.more,
          compact: m.wide,
        ),
      FlareComposerSendButton(
        active:
            !widget.disabled &&
            (_canSend || _controller.text.trim().isNotEmpty) &&
            (widget.onSend != null || widget.onSendRich != null),
        busy: _sending,
        onTap: () {
          _focusNode.unfocus();
          _send();
        },
        compact: m.wide,
      ),
    ];
    return TapRegion(
      groupId: _focusNode,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: m.toolInset),
        child: Row(
          mainAxisAlignment: m.wide
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceBetween,
          children: keys,
        ),
      ),
    );
  }

  Widget _resizeTool(_Metrics m) {
    final colors = FlareColors.of(context);
    final label = _expanded
        ? FlareStrings.of(context).collapse
        : FlareStrings.of(context).expand;
    return IconButton(
      key: const ValueKey('composer-resize-action'),
      tooltip: label,
      onPressed: widget.disabled ? null : _toggleExpanded,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: m.wide ? 34 : FlareSizes.componentComposerActionWidth,
        height: m.wide ? 36 : FlareSizes.componentComposerActionWidth,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size(
          m.wide ? 34 : FlareSizes.componentComposerActionWidth,
          m.wide ? 36 : FlareSizes.componentComposerActionWidth,
        ),
        maximumSize: Size(m.wide ? 34 : 44, m.wide ? 36 : 44),
      ),
      color: _expanded ? colors.primary : colors.textSecondary,
      disabledColor: colors.textDisabled,
      icon: FlareComposerResizeIcon(expanded: _expanded),
    );
  }

  /// Emoji, mention, [voice], image, rich text, more, send.
  int get _keyCount =>
      1 +
      ['emoji', 'image', 'richText'].where(_allowsTool).length +
      (_plusShown ? 1 : 0) +
      (widget.enableVoice && _allowsTool('voice') ? 1 : 0) +
      (widget.enableMentions && _allowsTool('mention') ? 1 : 0);

  Widget _inputField(_Metrics m, FlareColors colors) {
    final inline = _formatting.inlineStyles;
    return Padding(
      padding: m.text,
      child: Focus(
        onKeyEvent: (_, event) {
          if (_panel != null &&
              event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            dismissPanel();
            return KeyEventResult.handled;
          }
          if ((m.wide ||
                  FlarePlatform.of(context).capabilities.keyboardShortcut) &&
              event is KeyDownEvent &&
              _shouldSubmit(event)) {
            _send();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          // Dismiss after the tap reaches its target. Changing the keyboard
          // inset on pointer down can move a toolbar button before it is tapped.
          child: TapRegion(
            groupId: _focusNode,
            onTapUpOutside: (_) {
              _focusNode.unfocus();
              dismissPanel();
            },
            child: ExtendedTextField(
              // Keep the editable state and its platform text-input connection
              // alive while the async catalog arrives. Re-keying this field used
              // to discard the first keystroke on a cold composer. The rebuilt
              // span builder below is enough to repaint restored `[key]` drafts.
              key: const ValueKey('composer-input'),
              specialTextSpanBuilder: FlareComposerEmojiSpanBuilder(
                delegate: widget.specialTextSpanBuilder,
                locale: Localizations.localeOf(context).toLanguageTag(),
              ),
              controller: _controller,
              focusNode: _focusNode,
              groupId: _focusNode,
              onTap: dismissPanel,
              onTapAlwaysCalled: true,
              onTapOutside: (_) {},
              enabled: !widget.disabled,
              minLines: _expanded ? 6 : 1,
              maxLines: _expanded ? 14 : 6,
              maxLength: widget.maxLength,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _send(),
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    maxLength,
                    required isFocused,
                  }) => null,
              style: TextStyle(
                color: inline.contains(RichComposerInlineStyle.link)
                    ? colors.primary
                    : colors.textPrimary,
                fontSize: 15,
                height: 1.45,
                fontWeight: inline.contains(RichComposerInlineStyle.bold)
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: inline.contains(RichComposerInlineStyle.italic)
                    ? FontStyle.italic
                    : FontStyle.normal,
                decoration:
                    inline.contains(RichComposerInlineStyle.strike) ||
                        inline.contains(RichComposerInlineStyle.underline) ||
                        inline.contains(RichComposerInlineStyle.link)
                    ? TextDecoration.combine([
                        if (inline.contains(RichComposerInlineStyle.strike))
                          TextDecoration.lineThrough,
                        if (inline.contains(
                              RichComposerInlineStyle.underline,
                            ) ||
                            inline.contains(RichComposerInlineStyle.link))
                          TextDecoration.underline,
                      ])
                    : null,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: _placeholder,
                hintStyle: TextStyle(color: colors.textTertiary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mentionPanel() {
    final range = _typedMentionRange(_controller.value);
    final query = range == null
        ? ''
        : _controller.text.substring(range.start + 1, range.end).toLowerCase();
    final candidates = _availableMentionCandidates;
    final conversationKey = widget.conversationKey;
    final controller = _controller;
    return FlareMentionPicker(
      candidates: query.isEmpty
          ? candidates
          : candidates.where((candidate) {
              return candidate.name.toLowerCase().contains(query) ||
                  (candidate.detail?.toLowerCase().contains(query) ?? false);
            }).toList(),
      framed: false,
      onClose: dismissPanel,
      onSelect: (candidate) {
        if (mounted &&
            widget.conversationKey == conversationKey &&
            identical(_controller, controller)) {
          _selectMention(candidate);
        }
      },
    );
  }

  Widget? _panelContent(_Metrics m) => switch (_panel) {
    _ComposerPanel.emoji => FlareEmojiStickerPicker(
      height: 240,
      onInsertEmoji: (key) => _insert('[$key]'),
      onSendSticker: widget.onSendSticker,
    ),
    _ComposerPanel.mention => _mentionPanel(),
    _ComposerPanel.more => FlareComposerActionPanel(
      actions: _resolvedActions,
      onAction: _activatePanelAction,
      formFactor: m.mobile
          ? FlareComposerPanelFormFactor.mobile
          : FlareComposerPanelFormFactor.desktop,
    ),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    // Toolbar density follows the pane width. Panel direction follows the
    // form factor so a narrow desktop pane still opens above the editor.
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final m = _Metrics.of(
            constraints.maxWidth,
            _keyCount,
            mobile: FlarePlatform.usesMobileComposerPanels(context),
          );
          final rich = _effectiveRich;
          final content = _panelContent(m);
          final panel = content == null
              ? null
              : TapRegion(groupId: _focusNode, child: content);
          final multiline =
              _expanded ||
              rich ||
              widget.replyTo != null ||
              _textNeedsMultipleLines(_controller.text);
          return Container(
            decoration: BoxDecoration(
              color: m.wide ? colors.bgPrimary : colors.bgSecondary,
              border: m.wide
                  ? Border(top: BorderSide(color: colors.borderPrimary))
                  : null,
            ),
            padding: m.wide
                ? EdgeInsets.fromLTRB(
                    FlareSizes.spacingMd,
                    rich ? 0 : FlareSizes.spacingSm,
                    FlareSizes.spacingMd,
                    FlareSizes.spacingSm,
                  )
                : const EdgeInsets.only(bottom: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.replyTo != null)
                  FlareComposerReplyStrip(
                    label: _replyLabel,
                    senderName: flareQuoteSenderText(
                      widget.replyTo!,
                      FlareStrings.of(context),
                    ),
                    summary: widget.replyTo!.summary,
                    onCancel: widget.onCancelReply,
                    flush: !m.wide,
                  ),
                if (_voiceMode && widget.onVoiceSend != null)
                  FlareInlineVoice(
                    disabled: widget.disabled,
                    onKeyboard: () {
                      setState(() => _voiceMode = false);
                      _focusInput();
                    },
                    onSend: widget.onVoiceSend!,
                  )
                else ...[
                  if (!m.mobile && panel != null) panel,
                  Container(
                    key: const ValueKey('composer-editor'),
                    color: colors.bgPrimary,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rich) _formatBar(m, colors),
                        if (m.wide && !multiline)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _inputField(m, colors)),
                              _tools(m),
                            ],
                          )
                        else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _inputField(m, colors)),
                              if (!m.wide) _resizeTool(m),
                            ],
                          ),
                          if (m.wide)
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: _tools(m),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (!m.wide) _tools(m),
                  if (m.mobile && panel != null) panel,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
