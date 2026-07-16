import 'package:flutter/material.dart';

/// The dark capsule popover raised by a moment's ··· button: a Like/Unlike
/// action and a Comment action split by a hairline divider.
/// Spec: Moments/ActionPopover (`FlareMomentActionPopover`).
class FlareMomentActionPopover extends StatelessWidget {
  const FlareMomentActionPopover({
    super.key,
    this.liked = false,
    this.onLike,
    this.onComment,
  });

  final bool liked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

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
            liked ? 'Unlike' : 'Like',
            onLike,
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white.withValues(alpha: 0.16),
          ),
          _btn(Icons.chat_bubble_outline, 'Comment', onComment),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFF2F0F7)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF2F0F7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
