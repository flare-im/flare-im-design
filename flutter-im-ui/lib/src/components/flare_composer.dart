import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'flare_inline_voice.dart';
import '../emoji_sticker/flare_emoji_sticker_picker.dart';
import 'composer/rich_text_composer_formatter.dart';

import '../tokens/flare_tokens.dart';
import 'composer/flare_composer_action_panel.dart';
import 'composer/flare_composer_parts.dart';

import 'flare_message_action_sheet.dart' show FlareComposerAction;

export 'composer/flare_composer_action_panel.dart';
export 'composer/flare_composer_parts.dart';
export 'composer/flare_voice_hold_button.dart';

/// A lightweight reply target shown as a strip above the composer input.
class FlareReplyTarget {
  const FlareReplyTarget({required this.senderName, required this.summary});
  final String senderName;
  final String summary;
}

/// The message input — the **complete, ready-to-use** composer, assembled from
/// composable parts (voice / attach panel / emoji / send / reply strip). Spec:
/// Composer/Composer (`FlareComposer`). Send is optimistic: [onSend] fires
/// immediately; the host does the local echo + core write.
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
    this.placeholder = '发送消息',
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
    this.onAction,
    this.replyLabel = '回复',
    this.enableVoice = false,
    this.voiceLabel = '按住 说话',
    this.voiceRecordingLabel = '松开发送 · 上滑取消',
    this.voiceCancelLabel = '松开手指，取消发送',
    this.onVoiceSend,
    this.onVoiceStart,
    this.onVoiceEnd,
    this.onVoiceCancel,
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
  final String replyLabel;
  final String voiceLabel;
  final String voiceRecordingLabel;
  final String voiceCancelLabel;
  final String placeholder;
  final bool disabled;
  final FlareReplyTarget? replyTo;
  final int? maxLength;

  final ValueChanged<String>? onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onEmoji;
  final void Function(String packageId, String stickerId)? onSendSticker;
  final ValueChanged<String>? onTyping;
  final VoidCallback? onCancelReply;

  /// When provided, the "+" button toggles an inline action panel (下方功能区)
  /// with these actions; otherwise "+" calls [onAttach].
  final List<FlareComposerAction>? actions;
  final void Function(FlareComposerAction action)? onAction;

  /// Show the voice (按住说话) toggle.
  final bool enableVoice;
  final Future<bool> Function(String path, int durationMs)? onVoiceSend;
  final VoidCallback? onVoiceStart;
  final VoidCallback? onVoiceEnd;
  final VoidCallback? onVoiceCancel;

  @override
  State<FlareComposer> createState() => FlareComposerState();
}

class FlareComposerState extends State<FlareComposer> {
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

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _canSend = _controller.text.trim().isNotEmpty;
    _controller.addListener(_changed);
  }

  void _changed() {
    final can = _controller.text.trim().isNotEmpty;
    if (can != _canSend) setState(() => _canSend = can);
    widget.onTyping?.call(_controller.text);
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
    }
    if (widget.conversationKey != oldWidget.conversationKey) {
      if (_ownsController) _controller.clear();
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

  void _send() {
    final text = _controller.text.trim();
    if (widget.disabled ||
        text.isEmpty ||
        (widget.onSend == null && widget.onSendRich == null))
      return;
    if ((_richMode || widget.rich) && widget.onSendRich != null) {
      widget.onSendRich!(
        RichComposerMarkdownSerializer.serialize(text, _formatting),
      );
    } else {
      widget.onSend?.call(text);
    }
    _controller.clear();
  }

  void _onPlus() {
    if (widget.actions != null) {
      widget.focusNode?.unfocus();
      setState(() {
        _panelOpen = !_panelOpen;
        _emojiOpen = false;
      });
    } else {
      widget.onAttach?.call();
    }
  }

  String _label(String zh, String en) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  Widget _tool(
    IconData icon,
    String label,
    VoidCallback? action, {
    bool active = false,
    bool enabled = true,
    bool compact = false,
  }) {
    final colors = FlareColors.of(Theme.of(context).brightness);
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

  Widget _formatBar(_Metrics m, FlareColors colors) => Column(
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
                (Icons.format_bold, '粗体', 'Bold', RichComposerInlineStyle.bold),
                (
                  Icons.format_italic,
                  '斜体',
                  'Italic',
                  RichComposerInlineStyle.italic,
                ),
                (
                  Icons.strikethrough_s,
                  '删除线',
                  'Strike',
                  RichComposerInlineStyle.strike,
                ),
                (Icons.code, '代码', 'Code', RichComposerInlineStyle.inlineCode),
                (Icons.link, '链接', 'Link', RichComposerInlineStyle.link),
              ])
                SizedBox(
                  width: 36,
                  child: _tool(
                    entry.$1,
                    _label(entry.$2, entry.$3),
                    () => setState(
                      () => _formatting = _formatting.toggleInline(entry.$4),
                    ),
                    compact: true,
                    active: _formatting.isInlineActive(entry.$4),
                  ),
                ),
              for (final entry in [
                (Icons.title, '标题', 'Heading', RichComposerBlockStyle.heading),
                (
                  Icons.format_quote,
                  '引用',
                  'Quote',
                  RichComposerBlockStyle.quote,
                ),
                (
                  Icons.format_list_bulleted,
                  '列表',
                  'List',
                  RichComposerBlockStyle.bulletList,
                ),
                (
                  Icons.format_list_numbered,
                  '有序列表',
                  'Ordered list',
                  RichComposerBlockStyle.orderedList,
                ),
              ])
                SizedBox(
                  width: 36,
                  child: _tool(
                    entry.$1,
                    _label(entry.$2, entry.$3),
                    () => setState(
                      () => _formatting = _formatting.toggleBlock(entry.$4),
                    ),
                    compact: true,
                    active: _formatting.isBlockActive(entry.$4),
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
  // One row, two homes: inside the card on a tablet, on the app ground below
  // the band on a phone. Writing it twice is how the two drift apart.
  Widget _tools(_Metrics m) {
    final keys = <Widget>[
      _tool(
        Icons.emoji_emotions_outlined,
        _label('表情', 'Emoji'),
        widget.onEmoji ??
            () => setState(() {
              _emojiOpen = !_emojiOpen;
              _panelOpen = false;
            }),
      ),
      _tool(Icons.alternate_email, _label('提及', 'Mention'), () => _insert('@')),
      if (widget.enableVoice)
        _tool(
          Icons.mic_none,
          _label('语音', 'Voice'),
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
        Icons.image_outlined,
        _label('图片', 'Image'),
        widget.onImage ?? widget.onAttach,
      ),
      _tool(
        Icons.text_fields,
        _label('富文本', 'Rich text'),
        () => setState(() {
          _richMode = !_richMode;
          if (!_richMode) _formatting = const RichComposerFormatting();
          _panelOpen = false;
        }),
        active: _richMode || widget.rich,
      ),
      _tool(
        _panelOpen ? Icons.close : Icons.add,
        _label('更多', 'More'),
        _onPlus,
        active: _panelOpen,
      ),
      FlareComposerSendButton(
        active:
            !widget.disabled &&
            (_canSend || _controller.text.trim().isNotEmpty) &&
            (widget.onSend != null || widget.onSendRich != null),
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
    final colors = FlareColors.of(Theme.of(context).brightness);
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
                    label: widget.replyLabel,
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
                                          event.logicalKey ==
                                              LogicalKeyboardKey.enter &&
                                          !HardwareKeyboard
                                              .instance
                                              .isShiftPressed &&
                                          !_controller
                                              .value
                                              .composing
                                              .isValid) {
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
                                          hintText: widget.placeholder,
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
                                _expanded
                                    ? Icons.close_fullscreen
                                    : Icons.open_in_full,
                                _label(
                                  _expanded ? '收起' : '展开',
                                  _expanded ? 'Collapse input' : 'Expand input',
                                ),
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
                  if (_panelOpen && widget.actions != null)
                    FlareComposerActionPanel(
                      actions: widget.actions!,
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
