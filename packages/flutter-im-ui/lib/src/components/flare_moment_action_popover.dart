import 'package:flutter/material.dart';

import 'flare_icon.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// The dark capsule popover raised by a moment's ··· button: a Like/Unlike
/// action and a Comment action split by a hairline divider, plus a destructive
/// Delete action shown only for the viewer's own moments ([canDelete]), or a
/// Report action in the same slot for everyone else's ([canReport]).
///
/// The two are the same shape on purpose: both are "act on this one post", both
/// low-frequency, and they are mutually exclusive — you do not report your own
/// post and you do not delete someone else's. Hosts used to have nowhere to put
/// 举报 and hung a text button *below* the card, which drew a per-post action
/// outside the post and gave other people's moments a different row rhythm.
/// Spec: Moments/ActionPopover (`FlareMomentActionPopover`).
class FlareMomentActionPopover extends StatelessWidget {
  const FlareMomentActionPopover({
    super.key,
    this.liked = false,
    this.canDelete = false,
    this.canReport = false,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.onReport,
    this.likeLabel,
    this.unlikeLabel,
    this.commentLabel,
    this.deleteLabel,
    this.reportLabel,
  });

  final bool liked;
  final bool canDelete;
  final bool canReport;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  /// 每个标签都可以由宿主指定；留空则取 [FlareStrings]，也就是随宿主装的语言走。
  ///
  /// 这些参数原来带着写死的中文默认值（`'赞'`、`'取消'`…），于是：宿主换成英文预设
  /// 时这一片仍是中文，而且 `unlikeLabel` 的 `'取消'` 和其它端的「取消赞」也对不上。
  final String? likeLabel;
  final String? unlikeLabel;
  final String? commentLabel;
  final String? deleteLabel;
  final String? reportLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final s = FlareStrings.of(context);
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _btn(
            colors,
            liked ? Icons.heart_broken_outlined : Icons.favorite_border,
            liked ? (unlikeLabel ?? s.unlike) : (likeLabel ?? s.like),
            onLike,
          ),
          _divider(colors),
          _btn(colors, Icons.chat_bubble_outline, commentLabel ?? s.comment, onComment),
          if (canDelete) ...[
            _divider(colors),
            _btn(
              colors,
              Icons.delete_outline,
              deleteLabel ?? s.delete,
              onDelete,
              danger: true,
            ),
          ]
          // 举报 destroys nothing of mine, so it keeps the normal tint: the
          // danger colour stays reserved for "this deletes something of yours".
          else if (canReport) ...[
            _divider(colors),
            _btn(colors, flareIconMap['report']!, reportLabel ?? s.report, onReport),
          ],
        ],
      ),
    );
  }

  Widget _divider(FlareColors colors) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: colors.borderSecondary,
    );
  }

  Widget _btn(
    FlareColors colors,
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool danger = false,
  }) {
    final color = danger ? colors.error : colors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacing2md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
