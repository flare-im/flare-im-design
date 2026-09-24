import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Visual treatment for a filter row. [quiet] is the persistent inbox style:
/// text plus an underline, without a row of competing filled pills.
enum FlareFilterTabsAppearance { filled, quiet }

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
    this.padding = const EdgeInsets.all(2),
    this.appearance = FlareFilterTabsAppearance.filled,
  });

  final List<FlareFilterTabOption> options;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Content padding for the scroll viewport (tabs scroll under it). Lets a host
  /// give the row its own horizontal gutter without breaking the scroll edges.
  final EdgeInsetsGeometry padding;
  final FlareFilterTabsAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final quiet = appearance == FlareFilterTabsAppearance.quiet;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: quiet
            ? Border(bottom: BorderSide(color: colors.borderSecondary))
            : null,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (!quiet && i > 0) const SizedBox(width: 6),
              _FilterTab(
                option: options[i],
                active: options[i].value == selected,
                appearance: appearance,
                onTap: () => onSelect(options[i].value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.option,
    required this.active,
    required this.appearance,
    required this.onTap,
  });

  final FlareFilterTabOption option;
  final bool active;
  final FlareFilterTabsAppearance appearance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final quiet = appearance == FlareFilterTabsAppearance.quiet;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: quiet ? FlareSizes.spacingSm : FlareSizes.spacing2md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: quiet
              ? Colors.transparent
              : active
              ? colors.primary.withValues(alpha: 0.12)
              : colors.bgSecondary,
          borderRadius: quiet
              ? BorderRadius.zero
              : BorderRadius.circular(FlareSizes.radiusFull),
          border: quiet
              ? Border(
                  bottom: BorderSide(
                    color: active ? colors.primary : Colors.transparent,
                    width: 2,
                  ),
                )
              : Border.all(
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
