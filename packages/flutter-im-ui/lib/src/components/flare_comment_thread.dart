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
///
/// A comment longer than [maxLines] (3 inline, 5 in [detail]) folds behind
/// Expand / Collapse. In [detail] the text sits under the names instead of
/// after a colon. [focusCommentId] names the comment a detail view was opened
/// to: it is unfolded, tagged [FlareStrings.momentLocatedComment], highlighted
/// and scrolled into view.
class FlareCommentThread extends StatelessWidget {
  const FlareCommentThread({
    super.key,
    required this.comments,
    this.onSelect,
    this.onSelectAuthor,
    this.detail = false,
    this.maxLines,
    this.focusCommentId,
  });

  final List<FlareMomentComment> comments;
  final void Function(FlareMomentComment comment)? onSelect;
  final void Function(String id)? onSelectAuthor;
  final bool detail;

  /// Lines before a comment folds; defaults to 3 inline and 5 in [detail].
  final int? maxLines;
  final String? focusCommentId;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in comments)
          _CommentRow(
            key: ValueKey(c.id),
            comment: c,
            onSelect: onSelect,
            onSelectAuthor: onSelect == null ? null : onSelectAuthor,
            detail: detail,
            maxLines: maxLines ?? (detail ? 5 : 3),
            focused: c.id == focusCommentId,
          ),
      ],
    );
  }
}

class _CommentRow extends StatefulWidget {
  const _CommentRow({
    super.key,
    required this.comment,
    required this.onSelect,
    required this.onSelectAuthor,
    required this.detail,
    required this.maxLines,
    required this.focused,
  });

  final FlareMomentComment comment;
  final void Function(FlareMomentComment comment)? onSelect;
  final void Function(String id)? onSelectAuthor;
  final bool detail;
  final int maxLines;
  final bool focused;

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  static const _lineStyle = TextStyle(
    fontSize: FlareSizes.fontSizeMd,
    height: 1.5,
  );

  late bool _expanded = widget.focused;

  @override
  void initState() {
    super.initState();
    if (widget.focused) _reveal();
  }

  @override
  void didUpdateWidget(_CommentRow old) {
    super.didUpdateWidget(old);
    if (widget.comment.text != old.comment.text) _expanded = widget.focused;
    if (widget.focused && !old.focused) {
      _expanded = true;
      _reveal();
    }
  }

  /// Only the nearest scrolling surface moves, so the row lands mid-view.
  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !widget.focused) return;
    Scrollable.ensureVisible(context, alignment: 0.5);
  });

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final c = widget.comment;
    final nameStyle = TextStyle(
      color: colors.primaryText,
      fontWeight: FontWeight.w500,
    );
    final quietStyle = TextStyle(color: colors.textTertiary);
    final textStyle = TextStyle(color: colors.textPrimary);
    final select = widget.onSelect;
    final selectAuthor = widget.onSelectAuthor;
    final reply = c.replyToName != null && c.replyToName!.isNotEmpty;
    final InlineSpan author = selectAuthor == null
        ? TextSpan(text: c.author.name, style: nameStyle)
        : WidgetSpan(
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
          );
    final relation = <InlineSpan>[
      author,
      if (reply) ...[
        TextSpan(text: ' ${strings.momentReplyTo} ', style: quietStyle),
        TextSpan(text: c.replyToName, style: nameStyle),
      ],
    ];
    // Measured as plain text: a WidgetSpan has no size until laid out.
    final plain = TextSpan(
      style: _lineStyle,
      text: widget.detail
          ? c.text
          : '${c.author.name}${reply ? ' ${strings.momentReplyTo} ${c.replyToName}' : ''}：${c.text}',
    );
    final line = LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: plain,
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        final clamp = overflows && !_expanded;
        final Widget text = widget.detail
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(TextSpan(style: _lineStyle, children: relation)),
                  Text(
                    c.text,
                    maxLines: clamp ? widget.maxLines : null,
                    overflow: clamp ? TextOverflow.ellipsis : null,
                    style: _lineStyle.merge(textStyle),
                  ),
                ],
              )
            : Text.rich(
                TextSpan(
                  style: _lineStyle,
                  children: [
                    ...relation,
                    TextSpan(text: '：', style: quietStyle),
                    TextSpan(text: c.text, style: textStyle),
                  ],
                ),
                maxLines: clamp ? widget.maxLines : null,
                overflow: clamp ? TextOverflow.ellipsis : null,
              );
        final row = Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: text,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (select == null)
              row
            else
              FlareContentControl(
                label: strings.momentReplyToComment(c.author.name, c.text),
                onTap: () => select(c),
                child: row,
              ),
            if (overflows)
              Semantics(
                expanded: _expanded,
                child: FlareContentControl(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? strings.collapse : strings.expand,
                    style: _lineStyle.merge(
                      TextStyle(color: colors.primaryText),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (!widget.focused) return line;
    return Semantics(
      selected: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgSelected,
          borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingXs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.momentLocatedComment,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeSm,
                  color: colors.primaryText,
                ),
              ),
              line,
            ],
          ),
        ),
      ),
    );
  }
}
