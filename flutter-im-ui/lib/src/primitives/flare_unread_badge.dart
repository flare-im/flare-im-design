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

    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = colors.primary;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      // A mini Aurora light source — echoes the glowing message bubble: a violet
      // gradient, a luminous top edge (lit corner), and a soft violet glow.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: 0.18), base),
            base,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.12), base),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.50 : 0.40),
            blurRadius: dark ? 8 : 6,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
        ],
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
