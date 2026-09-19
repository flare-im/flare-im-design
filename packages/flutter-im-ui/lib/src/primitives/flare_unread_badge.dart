import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The unread pill uses semantic primary color, tabular digits, and caps at 99+. Shared by the
/// conversation row, tabs and nav. Renders nothing when [count] is 0 unless
/// [dot] is set (a small marker with no number).
class FlareUnreadBadge extends StatelessWidget {
  const FlareUnreadBadge({
    super.key,
    required this.count,
    this.dot = false,
    this.quiet = false,
    this.maxCount = 99,
  });

  final int count;
  final bool dot;
  final bool quiet;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    if (count <= 0 && !dot) return const SizedBox.shrink();

    if (dot && count <= 0) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
      );
    }

    final base = quiet ? colors.bgTertiary : colors.primary;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > maxCount ? '$maxCount+' : '$count',
        style: TextStyle(
          color: quiet
              ? colors.textSecondary
              : colors.messageOutgoingForeground,
          fontSize: FlareSizes.fontSizeXs,
          fontWeight: FontWeight.w600,
          height: 1,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
