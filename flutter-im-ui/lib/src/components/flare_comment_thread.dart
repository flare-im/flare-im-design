import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// The comment list under a moment. Each line reads
/// `<author>` (+ ` replying to <name>` when a reply) `：<text>`, tappable as a
/// whole (→ [onSelect]) with the author name tappable independently
/// (→ [onSelectAuthor]). Spec: Moments/CommentThread (`FlareCommentThread`).
class FlareCommentThread extends StatelessWidget {
  const FlareCommentThread({
    super.key,
    required this.comments,
    this.onSelect,
    this.onSelectAuthor,
  });

  final List<FlareMomentComment> comments;
  final void Function(FlareMomentComment comment)? onSelect;
  final void Function(String id)? onSelectAuthor;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) return const SizedBox.shrink();
    final colors = FlareColors.of(Theme.of(context).brightness);

    final nameStyle = TextStyle(
      color: colors.primary,
      fontWeight: FontWeight.w500,
    );
    final replyStyle = TextStyle(color: colors.textTertiary);
    final textStyle = TextStyle(color: colors.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in comments)
          GestureDetector(
            onTap: onSelect == null ? null : () => onSelect!(c),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                  ),
                  children: [
                    _nameSpan(c.author.id, c.author.name, nameStyle),
                    if (c.replyToName != null && c.replyToName!.isNotEmpty) ...[
                      TextSpan(text: ' replying to ', style: replyStyle),
                      TextSpan(text: c.replyToName, style: nameStyle),
                    ],
                    TextSpan(text: '：', style: replyStyle),
                    TextSpan(text: c.text, style: textStyle),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  TextSpan _nameSpan(String id, String name, TextStyle style) {
    return TextSpan(
      text: name,
      style: style,
      recognizer: onSelectAuthor == null
          ? null
          : (TapGestureRecognizer()..onTap = () => onSelectAuthor!(id)),
    );
  }
}
