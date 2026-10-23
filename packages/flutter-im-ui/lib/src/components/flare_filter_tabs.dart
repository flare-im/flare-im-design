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
///
/// A filled pill keeps the size it is drawn at and sits centred in a cell at
/// least [FlareSizes.touchTarget] square that takes the taps; the quiet strip
/// keeps its compact rule-to-rule height.
class FlareFilterTabs extends StatelessWidget {
  const FlareFilterTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.padding = const EdgeInsets.all(2),
    this.appearance = FlareFilterTabsAppearance.filled,
    this.enabled = true,
  });

  final List<FlareFilterTabOption> options;
  final String selected;
  final ValueChanged<String> onSelect;

  /// Content padding for the scroll viewport (tabs scroll under it). Lets a host
  /// give the row its own horizontal gutter without breaking the scroll edges.
  final EdgeInsetsGeometry padding;
  final FlareFilterTabsAppearance appearance;

  /// False while what the tabs filter is loading: the row dims to the
  /// disabled opacity and taps do nothing until it is enabled again.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final quiet = appearance == FlareFilterTabsAppearance.quiet;
    final row = DecoratedBox(
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
                enabled: enabled,
                onTap: () => onSelect(options[i].value),
              ),
            ],
          ],
        ),
      ),
    );
    return enabled ? row : Opacity(opacity: FlareOpacity.disabled, child: row);
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.option,
    required this.active,
    required this.appearance,
    required this.enabled,
    required this.onTap,
  });

  final FlareFilterTabOption option;
  final bool active;
  final FlareFilterTabsAppearance appearance;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final quiet = appearance == FlareFilterTabsAppearance.quiet;
    final pill = Container(
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
    );
    final tab = GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: quiet
          ? pill
          : ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: FlareSizes.touchTarget,
                minHeight: FlareSizes.touchTarget,
              ),
              child: Align(widthFactor: 1, heightFactor: 1, child: pill),
            ),
    );
    return Semantics(
      button: true,
      selected: active,
      enabled: enabled,
      child: tab,
    );
  }
}
