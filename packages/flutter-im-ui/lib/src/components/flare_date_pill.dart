import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Timeline date separator — a small centered chip labelling a day (or a
/// floating scroll hint). Spec: Message/DatePill (`FlareDatePill`).
///
/// In the timeline it is a quiet day marker on the secondary ground, with no
/// border, shadow or blur: the messages outrank it. Only a [floating] pill,
/// which sits over scrolled messages, gets a surface of its own.
class FlareDatePill extends StatelessWidget {
  const FlareDatePill({super.key, required this.label, this.floating = false});

  final String label;

  /// Drawn over the timeline while scrolling: the chip gets a translucent
  /// surface, a hairline border and a soft shadow so it reads over messages.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd,
          vertical: 3,
        ),
        decoration: floating
            ? BoxDecoration(
                color: colors.bgPrimary.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                border: Border.all(color: colors.borderPrimary),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              )
            : BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
              ),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: FlareSizes.fontSizeSm,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
