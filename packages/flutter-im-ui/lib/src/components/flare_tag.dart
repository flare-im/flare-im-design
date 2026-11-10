import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_status_banner.dart';

/// A presentational status/category label. Its words carry the meaning.
class FlareTag extends StatelessWidget {
  const FlareTag({
    super.key,
    required this.label,
    this.tone = FlareStatusTone.neutral,
    this.dot = false,
    this.monospace = false,
  });
  final String label;
  final FlareStatusTone tone;
  final bool dot;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final ink = switch (tone) {
      FlareStatusTone.neutral => colors.textSecondary,
      FlareStatusTone.info => colors.infoText,
      FlareStatusTone.success => colors.successText,
      FlareStatusTone.warning => colors.warningText,
      FlareStatusTone.danger => colors.errorText,
    };
    final tint = switch (tone) {
      FlareStatusTone.neutral => colors.bgTertiary,
      FlareStatusTone.info => Color.lerp(colors.bgPrimary, colors.info, 0.06)!,
      FlareStatusTone.success => Color.lerp(
        colors.bgPrimary,
        colors.success,
        0.06,
      )!,
      FlareStatusTone.warning => Color.lerp(
        colors.bgPrimary,
        colors.warning,
        0.06,
      )!,
      FlareStatusTone.danger => Color.lerp(
        colors.bgPrimary,
        colors.error,
        0.06,
      )!,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
        border: Border.all(color: ink.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacing2xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: FlareSizes.spacing2xs,
                height: FlareSizes.spacing2xs,
                decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
              ),
              const SizedBox(width: FlareSizes.spacing2xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  height: FlareSizes.lineHeightNormal,
                  color: ink,
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
