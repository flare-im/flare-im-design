import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Re-tints the kit's primary role with the red packet's deep red for the
/// money buttons ("塞钱进红包", "确认支付"), so they stay [FlareButton]s —
/// focus, loading, disabled and touch target included — instead of a second
/// button drawn here. The deep red keeps white text above 4.5:1. Vue does the
/// same by overriding `--flare-color-primary` on the button's wrapper.
class FlareRedPacketTint extends StatelessWidget {
  const FlareRedPacketTint({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final inherited = FlareTheme.maybeOf(context);
    final red = colors.redPacketEnd;
    return FlareTheme(
      brand: inherited?.brand ?? FlareBrandTheme.violet,
      mode: inherited?.mode ?? FlareThemeMode.system,
      colors: colors.copyWith(
        primary: red,
        primaryHover: colors.redPacketEndHover,
        primaryActive: colors.redPacketEndActive,
      ),
      child: child,
    );
  }
}

/// The large packet total of the composer and the review:
/// [FlareSizes.componentRedPacketAmountFontSize] (44), and
/// [FlareSizes.componentRedPacketAmountFontSizeWide] (36) in a PC window
/// (≥ breakpoints.md, [FlareSizes.appShellCompactMinWidth]).
double flareRedPacketAmountFontSize(BuildContext context) =>
    (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
        FlareSizes.appShellCompactMinWidth
    ? FlareSizes.componentRedPacketAmountFontSizeWide
    : FlareSizes.componentRedPacketAmountFontSize;

/// A spent packet's colour: [color] mixed in sRGB with the theme's
/// `redPacketFadedMixTarget` (white in light mode, a deep red in dark mode),
/// the target taking [FlareSizes.componentRedPacketFadedMix] — the same lerp
/// the other kits do and Vue's `color-mix(in srgb, colour, target 40%)`
/// (`spec/red-packet-vectors.json` → faded). The hue stays; only the depth goes.
Color flareRedPacketFaded(Color color, FlareColors colors) => Color.lerp(
  color,
  colors.redPacketFadedMixTarget,
  FlareSizes.componentRedPacketFadedMix,
)!;
