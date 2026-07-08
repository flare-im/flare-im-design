import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'composer/flare_composer_action_panel.dart';
import 'composer/flare_composer_parts.dart';
import 'composer/flare_voice_hold_button.dart';
import 'flare_message_action_sheet.dart' show FlareComposerAction;
import 'flare_rich_markdown_input.dart';

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
class FlareComposer extends StatefulWidget {
  const FlareComposer({
    super.key,
    this.rich = false,
    this.placeholder = 'Message',
    this.disabled = false,
    this.replyTo,
    this.maxLength,
    this.onSend,
    this.onAttach,
    this.onEmoji,
    this.onTyping,
    this.onCancelReply,
    this.actions,
    this.onAction,
    this.enableVoice = false,
    this.onVoiceStart,
    this.onVoiceEnd,
    this.onVoiceCancel,
  });

  final bool rich;
  final String placeholder;
  final bool disabled;
  final FlareReplyTarget? replyTo;
  final int? maxLength;

  final ValueChanged<String>? onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onEmoji;
  final ValueChanged<String>? onTyping;
  final VoidCallback? onCancelReply;

  /// When provided, the "+" button toggles an inline action panel (下方功能区)
  /// with these actions; otherwise "+" calls [onAttach].
  final List<FlareComposerAction>? actions;
  final void Function(FlareComposerAction action)? onAction;

  /// Show the voice (按住说话) toggle.
  final bool enableVoice;
  final VoidCallback? onVoiceStart;
  final VoidCallback? onVoiceEnd;
  final VoidCallback? onVoiceCancel;

  @override
  State<FlareComposer> createState() => _FlareComposerState();
}

class _FlareComposerState extends State<FlareComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;
  bool _voiceMode = false;
  bool _panelOpen = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
      widget.onTyping?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _controller.clear();
  }

  void _onPlus() {
    if (widget.actions != null) {
      setState(() => _panelOpen = !_panelOpen);
    } else {
      widget.onAttach?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        border: Border(top: BorderSide(color: colors.borderPrimary)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: FlareSizes.spacingSm,
              right: FlareSizes.spacingSm,
              top: FlareSizes.spacingSm,
              bottom: _panelOpen ? FlareSizes.spacingSm : FlareSizes.spacingSm +
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.replyTo != null)
                  FlareComposerReplyStrip(
                    senderName: widget.replyTo!.senderName,
                    summary: widget.replyTo!.summary,
                    onCancel: widget.onCancelReply,
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.enableVoice)
                      FlareComposerIconButton(
                        icon: _voiceMode ? Icons.keyboard_outlined : Icons.mic_none,
                        active: _voiceMode,
                        disabled: widget.disabled,
                        onTap: () => setState(() => _voiceMode = !_voiceMode),
                      ),
                    FlareComposerIconButton(
                      icon: Icons.add_circle_outline_rounded,
                      active: _panelOpen,
                      disabled: widget.disabled,
                      onTap: _onPlus,
                    ),
                    Expanded(child: _voiceMode ? _voiceBar() : _inputField(colors)),
                    if (!_voiceMode)
                      FlareComposerIconButton(
                        icon: Icons.emoji_emotions_outlined,
                        disabled: widget.disabled,
                        onTap: widget.onEmoji,
                      ),
                    if (!_voiceMode)
                      FlareComposerSendButton(
                          active: _canSend && !widget.disabled, onTap: _send),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: (_panelOpen && widget.actions != null)
                ? FlareComposerActionPanel(
                    actions: widget.actions!,
                    onAction: (a) {
                      widget.onAction?.call(a);
                      setState(() => _panelOpen = false);
                    },
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _voiceBar() {
    return FlareVoiceHoldButton(
      onStart: widget.onVoiceStart,
      onEnd: widget.onVoiceEnd,
      onCancel: widget.onVoiceCancel,
    );
  }

  Widget _inputField(FlareColors colors) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
      ),
      child: widget.rich
          ? FlareRichMarkdownInput(
              controller: _controller,
              disabled: widget.disabled,
              maxLength: widget.maxLength,
              placeholder: widget.placeholder,
              onSubmit: (_) => _send(),
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _controller,
                enabled: !widget.disabled,
                minLines: 1,
                maxLines: 5,
                maxLength: widget.maxLength,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                buildCounter: (_,
                        {required currentLength,
                        maxLength,
                        required isFocused}) =>
                    null,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(color: colors.textTertiary),
                ),
              ),
            ),
    );
  }
}
