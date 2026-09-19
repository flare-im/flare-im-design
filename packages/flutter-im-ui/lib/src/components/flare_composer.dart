import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'flare_bottom_sheet.dart';
import 'flare_inline_voice.dart';
import 'flare_mention_picker.dart';
import '../emoji_sticker/flare_emoji_sticker_picker.dart';
import 'composer/rich_text_composer_formatter.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'composer/flare_composer_action_panel.dart';
import 'composer/flare_composer_parts.dart';
import '../models/directory_data.dart' show FlareMentionCandidate;
import '../models/form_behavior.dart';
import '../models/message_data.dart' show FlareReplyTarget;

export 'composer/flare_composer_action_panel.dart';
export 'composer/flare_composer_parts.dart';
export 'composer/flare_voice_hold_button.dart';
export '../models/message_data.dart' show FlareReplyTarget;

enum FlareComposerSubmitMode { enter, modifierEnter }

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
/// [band] is a phone: the field runs the full width of the screen with the
/// rounding taken off, and the tools rest on the app ground below it. Anything
/// wider keeps the bordered card the desktop layout is built around.
class _Metrics {
  const _Metrics({
    required this.band,
    required this.text,
    required this.stripHeight,
    required this.stripInset,
    required this.toolInset,
  });

  final bool band;
  final EdgeInsets text;
  final double stripHeight;
  final double stripInset;
  final double toolInset;

  factory _Metrics.of(double width, int keys) {
    if (width >= 600) {
      return const _Metrics(
        band: false,
        text: EdgeInsets.fromLTRB(12, 12, 0, 8),
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
      band: true,
      text: const EdgeInsets.fromLTRB(16, 11, 0, 11),
      stripHeight: 44,
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

  @override
  State<FlareComposer> createState() => FlareComposerState();
}

class FlareComposerState extends State<FlareComposer> {
  List<FlareComposerAction> get _resolvedActions => resolveFlareComposerActions(
    actions: widget.actions,
    capabilities: widget.capabilities,
  );
  bool get _hasActionPanel =>
      _resolvedActions.isNotEmpty &&
      (widget.actions != null || widget.onAttach == null);
  String get _placeholder =>
      widget.placeholder ?? FlareStrings.of(context).composerPlaceholder;
  String get _replyLabel =>
      widget.replyLabel ?? FlareStrings.of(context).composerReply;
  late TextEditingController _controller;
  late bool _ownsController;
  bool _emojiOpen = false;
  bool _expanded = false;
  bool _richMode = false;
  RichComposerFormatting _formatting = const RichComposerFormatting();
  void dismissPanel() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  bool _canSend = false;
  bool _voiceMode = false;
  bool _panelOpen = false;
  bool _sending = false;
  bool _mentionOpen = false;
  TextEditingValue _lastValue = TextEditingValue.empty;
  bool _suppressTyping = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _canSend = _controller.text.trim().isNotEmpty;
    _lastValue = _controller.value;
    _controller.addListener(_changed);
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
    final value = _controller.value;
    final typedAt = _typedMentionAt(_lastValue, value);
    // A controller notifies for the caret and the selection too. Tapping into a composer that already
    // holds a draft changes nothing about the text, and must not tell the conversation someone is typing.
    final textChanged = _lastValue.text != value.text;
    _lastValue = value;
    final can = value.text.trim().isNotEmpty;
    if (can != _canSend) setState(() => _canSend = can);
    if (textChanged && !_suppressTyping) widget.onTyping?.call(value.text);
    if (typedAt != null && widget.mentionCandidates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickMention(typedAt: typedAt);
      });
    }
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

  /// Presents the member picker. A pick replaces the "@" typed at [typedAt]
  /// with "@name ", or goes in at the caret; closing leaves the text alone.
  Future<void> _pickMention({int? typedAt}) async {
    if (_mentionOpen || widget.mentionCandidates.isEmpty) return;
    _mentionOpen = true;
    final picked = await FlareBottomSheet.show<FlareMentionCandidate>(
      context,
      title: FlareStrings.of(context).composerMention,
      builder: (sheetContext) => FlareMentionPicker(
        candidates: widget.mentionCandidates,
        autofocus: true,
        framed: false,
        onSelect: (candidate) => Navigator.of(sheetContext).pop(candidate),
      ),
    );
    _mentionOpen = false;
    if (picked == null || !mounted) return;
    final mention = '@${picked.name} ';
    final text = _controller.text;
    if (typedAt != null && typedAt < text.length && text[typedAt] == '@') {
      _controller.value = TextEditingValue(
        text: text.replaceRange(typedAt, typedAt + 1, mention),
        selection: TextSelection.collapsed(offset: typedAt + mention.length),
      );
    } else {
      _insert(mention);
    }
  }

  @override
  void didUpdateWidget(covariant FlareComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_changed);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_changed);
      _canSend = _controller.text.trim().isNotEmpty;
      _lastValue = _controller.value;
    }
    if (widget.conversationKey != oldWidget.conversationKey) {
      if (_ownsController) _clearWithoutTyping();
      _voiceMode = false;
      _panelOpen = false;
      _emojiOpen = false;
      _expanded = false;
      _formatting = const RichComposerFormatting();
      _richMode = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (widget.disabled ||
        _sending ||
        text.isEmpty ||
        (widget.onSend == null && widget.onSendRich == null))
      return;
    if ((_richMode || widget.rich) && widget.onSendRich != null) {
      widget.onSendRich!(
        RichComposerMarkdownSerializer.serialize(text, _formatting),
      );
      _clearWithoutTyping();
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

  void _onPlus() {
    if (_hasActionPanel) {
      widget.focusNode?.unfocus();
      setState(() {
        _panelOpen = !_panelOpen;
        _emojiOpen = false;
      });
    } else {
      widget.onAttach?.call();
    }
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
      iconSize: compact ? 14 : 20,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: compact ? 36 : 44,
        height: compact ? 32 : 44,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size(compact ? 36 : 44, compact ? 32 : 44),
        maximumSize: Size(compact ? 36 : 44, compact ? 32 : 44),
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

  Widget _formatBar(_Metrics m, FlareColors colors) {
    final s = FlareStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: m.stripHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: m.stripInset),
            child: Row(
              children: [
                for (final entry in [
                  (
                    Icons.format_bold,
                    s.composerBold,
                    RichComposerInlineStyle.bold,
                  ),
                  (
                    Icons.format_italic,
                    s.composerItalic,
                    RichComposerInlineStyle.italic,
                  ),
                  (
                    Icons.strikethrough_s,
                    s.composerStrike,
                    RichComposerInlineStyle.strike,
                  ),
                  (
                    Icons.code,
                    s.composerCode,
                    RichComposerInlineStyle.inlineCode,
                  ),
                  (Icons.link, s.composerLink, RichComposerInlineStyle.link),
                ])
                  SizedBox(
                    width: 36,
                    child: _tool(
                      entry.$1,
                      entry.$2,
                      () => setState(
                        () => _formatting = _formatting.toggleInline(entry.$3),
                      ),
                      compact: true,
                      active: _formatting.isInlineActive(entry.$3),
                    ),
                  ),
                for (final entry in [
                  (
                    Icons.title,
                    s.composerHeading,
                    RichComposerBlockStyle.heading,
                  ),
                  (
                    Icons.format_quote,
                    s.composerQuote,
                    RichComposerBlockStyle.quote,
                  ),
                  (
                    Icons.format_list_bulleted,
                    s.composerList,
                    RichComposerBlockStyle.bulletList,
                  ),
                  (
                    Icons.format_list_numbered,
                    s.composerOrderedList,
                    RichComposerBlockStyle.orderedList,
                  ),
                ])
                  SizedBox(
                    width: 36,
                    child: _tool(
                      entry.$1,
                      entry.$2,
                      () => setState(
                        () => _formatting = _formatting.toggleBlock(entry.$3),
                      ),
                      compact: true,
                      active: _formatting.isBlockActive(entry.$3),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The row is the top of the same band; a hairline is all that separates
        // it from the text it formats.
        Container(height: 1, color: colors.borderPrimary),
      ],
    );
  }

  // One row, two homes: inside the card on a tablet, on the app ground below
  // the band on a phone. Writing it twice is how the two drift apart.
  Widget _tools(_Metrics m) {
    final s = FlareStrings.of(context);
    final keys = <Widget>[
      _tool(
        flareIconGlyph('emoji'),
        s.composerEmoji,
        widget.onEmoji ??
            () => setState(() {
              _emojiOpen = !_emojiOpen;
              _panelOpen = false;
            }),
      ),
      _tool(
        flareIconGlyph('mention'),
        s.composerMention,
        widget.mentionCandidates.isEmpty
            ? () => _insert('@')
            : () => _pickMention(),
      ),
      if (widget.enableVoice)
        _tool(
          flareIconGlyph('mic'),
          s.composerVoiceInput,
          widget.onVoiceSend == null
              ? null
              : () {
                  widget.focusNode?.unfocus();
                  setState(() {
                    _voiceMode = true;
                    _panelOpen = false;
                    _emojiOpen = false;
                  });
                },
        ),
      _tool(
        flareIconGlyph('image'),
        s.actionImage,
        widget.onImage ?? widget.onAttach,
      ),
      _tool(
        flareIconGlyph('rich-text'),
        s.composerRichText,
        () => setState(() {
          _richMode = !_richMode;
          if (!_richMode) _formatting = const RichComposerFormatting();
          _panelOpen = false;
        }),
        active: _richMode || widget.rich,
      ),
      _tool(
        flareIconGlyph(_panelOpen ? 'close' : 'add'),
        s.more,
        _onPlus,
        active: _panelOpen,
        enabled: _hasActionPanel || widget.onAttach != null,
      ),
      FlareComposerSendButton(
        active:
            !widget.disabled &&
            (_canSend || _controller.text.trim().isNotEmpty) &&
            (widget.onSend != null || widget.onSendRich != null),
        busy: _sending,
        onTap: _send,
      ),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m.toolInset),
      child: Row(
        mainAxisAlignment: m.band
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: keys,
      ),
    );
  }

  /// Emoji, mention, [voice], image, rich text, more, send.
  int get _keyCount => widget.enableVoice ? 7 : 6;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final inline = _formatting.inlineStyles;
    // Measured once, here: the composer can be narrower than the window when it
    // sits in a pane, and every value below comes from the width it really got.
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final m = _Metrics.of(constraints.maxWidth, _keyCount);
          return Container(
            color: m.band ? colors.bgSecondary : colors.bgPrimary,
            padding: m.band
                ? const EdgeInsets.only(bottom: 4)
                : const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.replyTo != null)
                  FlareComposerReplyStrip(
                    label: _replyLabel,
                    senderName: widget.replyTo!.senderName,
                    summary: widget.replyTo!.summary,
                    onCancel: widget.onCancelReply,
                    flush: m.band,
                  ),
                if (_voiceMode && widget.onVoiceSend != null)
                  FlareInlineVoice(
                    disabled: widget.disabled,
                    onKeyboard: () {
                      setState(() => _voiceMode = false);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) widget.focusNode?.requestFocus();
                      });
                    },
                    onSend: widget.onVoiceSend!,
                  )
                else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: colors.bgPrimary,
                      border: m.band
                          ? null
                          : Border.all(color: colors.borderPrimary),
                      borderRadius: m.band ? null : BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_panelOpen) ...[
                          if (_richMode || widget.rich) _formatBar(m, colors),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: m.text,
                                  child: Focus(
                                    onKeyEvent: (_, event) {
                                      if (!m.band &&
                                          event is KeyDownEvent &&
                                          _shouldSubmit(event)) {
                                        _send();
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: ScrollConfiguration(
                                      behavior: ScrollConfiguration.of(
                                        context,
                                      ).copyWith(scrollbars: false),
                                      child: ExtendedTextField(
                                        specialTextSpanBuilder:
                                            widget.specialTextSpanBuilder,
                                        controller: _controller,
                                        focusNode: widget.focusNode,
                                        enabled: !widget.disabled,
                                        minLines: _expanded ? 9 : 1,
                                        maxLines: _expanded ? 14 : 5,
                                        maxLength: widget.maxLength,
                                        textInputAction:
                                            TextInputAction.newline,
                                        onSubmitted: (_) => _send(),
                                        buildCounter:
                                            (
                                              _, {
                                              required currentLength,
                                              maxLength,
                                              required isFocused,
                                            }) => null,
                                        style: TextStyle(
                                          color:
                                              inline.contains(
                                                RichComposerInlineStyle.link,
                                              )
                                              ? colors.primary
                                              : colors.textPrimary,
                                          fontSize: 15,
                                          height: 1.45,
                                          fontWeight:
                                              inline.contains(
                                                RichComposerInlineStyle.bold,
                                              )
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontStyle:
                                              inline.contains(
                                                RichComposerInlineStyle.italic,
                                              )
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          decoration:
                                              inline.contains(
                                                RichComposerInlineStyle.strike,
                                              )
                                              ? TextDecoration.lineThrough
                                              : inline.contains(
                                                  RichComposerInlineStyle.link,
                                                )
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          border: InputBorder.none,
                                          hintText: _placeholder,
                                          hintStyle: TextStyle(
                                            color: colors.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _tool(
                                flareIconGlyph(
                                  _expanded ? 'collapse' : 'expand',
                                ),
                                _expanded
                                    ? FlareStrings.of(context).collapse
                                    : FlareStrings.of(context).expand,
                                () => setState(() => _expanded = !_expanded),
                              ),
                            ],
                          ),
                        ],
                        if (!m.band) _tools(m),
                      ],
                    ),
                  ),
                  // The tools leave the band and rest on the ground, taking back
                  // the inset the band gave up.
                  if (m.band) _tools(m),
                  if (_emojiOpen)
                    FlareEmojiStickerPicker(
                      height: 240,
                      onInsertEmoji: (key) => _insert('[$key]'),
                      onSendSticker: widget.onSendSticker,
                    ),
                  if (_panelOpen && _hasActionPanel)
                    FlareComposerActionPanel(
                      actions: _resolvedActions,
                      onAction: (a) {
                        widget.onAction?.call(a);
                        setState(() => _panelOpen = false);
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
