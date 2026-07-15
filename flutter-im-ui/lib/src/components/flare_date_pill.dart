import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Timeline date separator — a small centered chip labelling a day (or a
/// floating scroll hint). Spec: Message/DatePill (`FlareDatePill`).
class FlareDatePill extends StatelessWidget {
  const FlareDatePill({
    super.key,
    required this.label,
    this.floating = false,
  });

  final String label;

  /// Hint that the pill is shown floating over the timeline while scrolling.
  /// Purely advisory — the chip renders identically either way.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: colors.bgPrimary.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.borderPrimary),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Text(label,
            style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}
