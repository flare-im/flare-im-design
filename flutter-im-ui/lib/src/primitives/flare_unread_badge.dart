import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The unread pill — brand-purple, tabular digits, caps at 99+. Shared by the
/// conversation row, tabs and nav. Renders nothing when [count] is 0 unless
/// [dot] is set (a small marker with no number).
class FlareUnreadBadge extends StatelessWidget {
  const FlareUnreadBadge({super.key, required this.count, this.dot = false});

  final int count;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    if (count <= 0 && !dot) return const SizedBox.shrink();

    if (dot && count <= 0) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      );
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: FlareSizes.fontSizeXs,
          fontWeight: FontWeight.w600,
          height: 1,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
