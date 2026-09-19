import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'content_control.dart';

/// The comment list under a moment. Each line reads `<author>` (+
/// ` 回复 <name>` when a reply) `：<text>`. Spec: Moments/CommentThread
/// (`FlareCommentThread`).
///
/// A comment is a control only when the host replies to it ([onSelect]): the
/// whole row, named [FlareStrings.momentReplyToComment]. Inside such a row the
/// author's name opens the author when the host handles that
/// ([onSelectAuthor]) — a pointer shortcut, since a control cannot hold
/// another control. Without [onSelect] the comments are plain text.
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

  static const _lineStyle = TextStyle(
    fontSize: FlareSizes.fontSizeMd,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) return const SizedBox.shrink();
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [for (final c in comments) _row(c, colors, strings)],
    );
  }

  Widget _row(FlareMomentComment c, FlareColors colors, FlareStrings strings) {
    final nameStyle = TextStyle(
      color: colors.primaryText,
      fontWeight: FontWeight.w500,
    );
    final quietStyle = TextStyle(color: colors.textTertiary);
    final select = onSelect;
    final selectAuthor = select == null ? null : onSelectAuthor;
    final line = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(
          style: _lineStyle,
          children: [
            if (selectAuthor == null)
              TextSpan(text: c.author.name, style: nameStyle)
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => selectAuthor(c.author.id),
                    child: Text(
                      c.author.name,
                      // The span already scales what it holds.
                      textScaler: TextScaler.noScaling,
                      style: _lineStyle.merge(nameStyle),
                    ),
                  ),
                ),
              ),
            if (c.replyToName != null && c.replyToName!.isNotEmpty) ...[
              TextSpan(text: ' ${strings.momentReplyTo} ', style: quietStyle),
              TextSpan(text: c.replyToName, style: nameStyle),
            ],
            TextSpan(text: '：', style: quietStyle),
            TextSpan(
              text: c.text,
              style: TextStyle(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
    if (select == null) return line;
    return FlareContentControl(
      label: strings.momentReplyToComment(c.author.name, c.text),
      onTap: () => select(c),
      child: line,
    );
  }
}
