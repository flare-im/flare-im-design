import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Compact equal-width segmented selector (分段选择器) — mutually-exclusive
/// [options]; the selected segment is surfaced on a raised chip. Emits the
/// chosen index via [onSelect]. Spec: General/SegmentedControl.
class FlareSegmentedControl extends StatelessWidget {
  const FlareSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    this.onSelect,
  });

  final List<String> options;
  final int selectedIndex;
  final void Function(int index)? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect?.call(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? colors.bgPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                  boxShadow: active
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Text(
                  options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? colors.primary : colors.textSecondary,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
