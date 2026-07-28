import 'package:flutter/material.dart';

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
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2B33),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x472C2B33),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _btn(
            liked ? Icons.heart_broken_outlined : Icons.favorite_border,
            liked ? unlikeLabel : likeLabel,
            onLike,
          ),
          _divider(),
          _btn(Icons.chat_bubble_outline, commentLabel, onComment),
          if (canDelete) ...[
            _divider(),
            _btn(
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

  Widget _divider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withValues(alpha: 0.16),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback? onTap,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFFF8A80) : const Color(0xFFF2F0F7);
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
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
