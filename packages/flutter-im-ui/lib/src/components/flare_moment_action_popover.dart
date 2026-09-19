import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The dark capsule popover raised by a moment's ··· button: a Like/Unlike
/// action and a Comment action split by a hairline divider, plus a destructive
/// Delete action shown only for the viewer's own moments ([canDelete]).
/// Spec: Moments/ActionPopover (`FlareMomentActionPopover`).
class FlareMomentActionPopover extends StatelessWidget {
  const FlareMomentActionPopover({
    super.key,
    this.liked = false,
    this.canDelete = false,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.likeLabel = '赞',
    this.unlikeLabel = '取消',
    this.commentLabel = '评论',
    this.deleteLabel = '删除',
  });

  final bool liked;
  final bool canDelete;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final String likeLabel;
  final String unlikeLabel;
  final String commentLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
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
            liked ? unlikeLabel : likeLabel,
            onLike,
          ),
          _divider(colors),
          _btn(colors, Icons.chat_bubble_outline, commentLabel, onComment),
          if (canDelete) ...[
            _divider(colors),
            _btn(
              colors,
              Icons.delete_outline,
              deleteLabel,
              onDelete,
              danger: true,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
