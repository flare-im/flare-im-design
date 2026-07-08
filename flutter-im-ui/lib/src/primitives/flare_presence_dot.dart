import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The presence indicator — a colour dot with a ring so it reads on any avatar.
/// Colour-agnostic (the caller maps presence → colour) so it stays free of the
/// avatar's enum; the ring defaults to the surface colour for a clean cut-out.
class FlarePresenceDot extends StatelessWidget {
  const FlarePresenceDot({
    super.key,
    required this.color,
    this.size = 12,
    this.ringColor,
    this.ringWidth = 2,
  });

  final Color color;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? colors.bgPrimary, width: ringWidth),
      ),
    );
  }
}
