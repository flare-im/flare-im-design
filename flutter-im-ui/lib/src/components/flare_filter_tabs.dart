import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A single option in a [FlareFilterTabs] row.
class FlareFilterTabOption {
  const FlareFilterTabOption({
    required this.value,
    required this.label,
    this.badge,
  });

  final String value;
  final String label;
  final int? badge;
}

/// A horizontal, scrollable tablist for filtering (conversations, search
/// kinds…). Replaces per-app bespoke conversation-filter rows. Spec:
/// General/FilterTabs (`FlareFilterTabs`).
class FlareFilterTabs extends StatelessWidget {
  const FlareFilterTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<FlareFilterTabOption> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _FilterTab(
              option: options[i],
              active: options[i].value == selected,
              onTap: () => onSelect(options[i].value),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final FlareFilterTabOption option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? colors.primary.withValues(alpha: 0.12)
              : colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          border: Border.all(
            color: active
                ? colors.primary.withValues(alpha: 0.26)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.label,
              style: TextStyle(
                color: active ? colors.primary : colors.textSecondary,
                fontSize: FlareSizes.fontSizeMd,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
              ),
            ),
            if (option.badge != null && option.badge! > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                ),
                child: Text(
                  '${option.badge}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: FlareSizes.fontSizeXs,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
