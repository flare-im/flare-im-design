import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'composer/flare_composer_parts.dart';
import 'flare_button.dart';
import 'flare_textarea.dart';

/// The comment box under a moment opened on its own (an inbox's detail view):
/// an optional reply strip naming the comment being answered, the host's
/// error, a one-to-three-line field and Send. Spec: Moments/CommentComposer
/// (`FlareCommentComposer`), the Vue kit's component of the same name.
///
/// Controlled: the host owns [value] (a draft per moment survives closing the
/// view), [replyTo], [error] and [busy]. Send — or ⌘/Ctrl+Enter; Enter alone
/// is a new line — reports [onSubmit] when the trimmed text is not empty and
/// nothing is [busy] or [disabled]. After a failure the key reads Retry. The
/// count appears from 80% of [maxLength].
class FlareCommentComposer extends StatelessWidget {
  const FlareCommentComposer({
    super.key,
    required this.value,
    required this.onChanged,
    this.onSubmit,
    this.replyTo,
    this.onCancelReply,
    this.error,
    this.busy = false,
    this.disabled = false,
    this.maxLength = 500,
    this.placeholder,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;
  final FlareMomentComment? replyTo;
  final VoidCallback? onCancelReply;
  final String? error;
  final bool busy;
  final bool disabled;
  final int maxLength;

  /// The empty field's hint; the host's "Comment…".
  final String? placeholder;

  void _submit() {
    if (busy || disabled || value.trim().isEmpty) return;
    onSubmit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final reply = replyTo;
    final locked = busy || disabled;
    final error = this.error;
    return Semantics(
      container: true,
      label: strings.comment,
      child: Padding(
        padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reply != null)
              FlareComposerReplyStrip(
                senderName: reply.author.name,
                summary: reply.text,
                label: strings.momentReplyTo,
                onCancel: locked ? null : onCancelReply,
              ),
            if (error != null && error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeSm,
                      color: colors.errorText,
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FlareTextarea(
                    value: value,
                    placeholder: placeholder,
                    size: FlareControlSize.sm,
                    rows: 1,
                    maxRows: 3,
                    maxlength: maxLength,
                    showCount: value.length >= maxLength * 0.8,
                    disabled: locked,
                    onChanged: onChanged,
                    onSubmit: _submit,
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                FlareButton(
                  size: FlareControlSize.sm,
                  loading: busy,
                  disabled: locked || value.trim().isEmpty,
                  label: error != null && error.isNotEmpty
                      ? strings.retry
                      : strings.send,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
