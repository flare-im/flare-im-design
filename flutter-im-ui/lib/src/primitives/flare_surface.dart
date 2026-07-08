import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A themed surface — the shared card primitive behind received bubbles, cards,
/// panels and sheets. White (bg-primary) with an optional hairline border and a
/// soft shadow, following the Flare thread look from the reference app. Theming
/// flows through the design tokens, so it adapts to light/dark automatically.
class FlareSurface extends StatelessWidget {
  const FlareSurface({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius,
    this.borderRadius,
    this.bordered = true,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? radius;

  /// Explicit per-corner radius (e.g. an asymmetric bubble tail); overrides [radius].
  final BorderRadius? borderRadius;
  final bool bordered;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.bgPrimary,
        borderRadius: borderRadius ?? BorderRadius.circular(radius ?? FlareSizes.radiusLg),
        border: bordered ? Border.all(color: colors.borderSecondary) : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
