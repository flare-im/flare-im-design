import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_hit_slop.dart';
import 'flare_icon.dart';

/// How [FlareRadioGroup] lays its options out (spec RadioGroup.optionLayout):
/// [compact] inline or [FlareRadioGroup.vertical]; [list] full-width 48 rows
/// with a selected tint; [cards] one 48-high card per option, the selected
/// one outlined in color.border.selected with a check, stacked on phones and
/// in equal columns on PC (plugin forms, a select of ≤ 4 choices).
enum FlareRadioOptionLayout { compact, list, cards }

/// A group of single-select radio rows. Inline ([Wrap]) by default, or a
/// [Column] when [vertical]. Per-option [FlareSelectOption.disabled] dims the
/// row and blocks selection. Custom-built from Flare tokens. Spec: Form/RadioGroup.
class FlareRadioGroup extends StatelessWidget {
  const FlareRadioGroup({
    super.key,
    required this.options,
    required this.value,
    this.vertical = false,
    this.optionLayout = FlareRadioOptionLayout.compact,
    this.grouped = false,
    this.onSelect,
  });

  final List<FlareSelectOption> options;
  final String value;
  final bool vertical;
  final FlareRadioOptionLayout optionLayout;
  final bool grouped;
  final void Function(String)? onSelect;

  @override
  Widget build(BuildContext context) {
    final groupedList = grouped && optionLayout == FlareRadioOptionLayout.list;
    final rows = [
      for (final (index, option) in options.indexed)
        _RadioOption(
          key: ValueKey((index, option.value)),
          option: option,
          selected: option.value == value,
          onSelect: onSelect,
          layout: optionLayout,
          grouped: groupedList,
        ),
    ];
    if (groupedList) {
      final colors = FlareColors.of(context);
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.bgElevated,
          border: Border.all(color: colors.borderPrimary),
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, row) in rows.indexed) ...[
              if (index > 0) Divider(height: 1, color: colors.borderSecondary),
              row,
            ],
          ],
        ),
      );
    }
    if (optionLayout == FlareRadioOptionLayout.cards &&
        (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
            FlareSizes.appShellCompactMinWidth) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(width: FlareSizes.spacingSm),
            Expanded(child: rows[i]),
          ],
        ],
      );
    }
    if (optionLayout != FlareRadioOptionLayout.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 && optionLayout == FlareRadioOptionLayout.cards)
              const SizedBox(height: FlareSizes.spacingSm),
            rows[i],
          ],
        ],
      );
    }
    if (vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            rows[i],
          ],
        ],
      );
    }
    return Wrap(spacing: 18, runSpacing: 12, children: rows);
  }
}

class _RadioOption extends StatefulWidget {
  const _RadioOption({
    super.key,
    required this.option,
    required this.selected,
    required this.onSelect,
    this.layout = FlareRadioOptionLayout.compact,
    this.grouped = false,
  });
  final FlareSelectOption option;
  final bool selected;
  final ValueChanged<String>? onSelect;
  final FlareRadioOptionLayout layout;
  final bool grouped;

  @override
  State<_RadioOption> createState() => _RadioOptionState();
}

class _RadioOptionState extends State<_RadioOption> {
  final _focus = FocusNode();
  bool _focused = false;
  bool _showFocus = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final option = widget.option;
    final enabled = !option.disabled && widget.onSelect != null;
    void select() {
      if (enabled) widget.onSelect?.call(option.value);
    }

    return FocusableActionDetector(
      enabled: enabled,
      focusNode: _focus,
      includeFocusSemantics: false,
      onFocusChange: (value) => setState(() => _focused = value),
      onShowFocusHighlight: (value) => setState(() => _showFocus = value),
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            select();
            return null;
          },
        ),
      },
      child: Semantics(
        excludeSemantics: true,
        inMutuallyExclusiveGroup: true,
        checked: widget.selected,
        enabled: enabled,
        focusable: enabled,
        focused: _focused,
        label: option.label,
        hint: option.description,
        onTap: enabled ? select : null,
        onFocus: enabled ? _focus.requestFocus : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: widget.layout != FlareRadioOptionLayout.compact
              ? _block(colors, enabled, select)
              : FlareHitSlop(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                      border: Border.all(
                        color: _showFocus && enabled
                            ? colors.borderSelected
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled ? select : null,
                      child: Padding(
                        padding: const EdgeInsets.all(FlareSizes.spacing2xs),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: FlareSizes.componentRadioIndicator,
                              height: FlareSizes.componentRadioIndicator,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.bgPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.selected
                                      ? colors.primary
                                      : colors.borderHover,
                                  width: 1.5,
                                ),
                              ),
                              child: widget.selected
                                  ? Container(
                                      width: FlareSizes.componentRadioDot,
                                      height: FlareSizes.componentRadioDot,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: FlareSizes.spacingSm),
                            Flexible(
                              child: Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: FlareSizes.fontSizeMd,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// A list row or a choice card: full width, at least 48 high.
  Widget _block(FlareColors colors, bool enabled, VoidCallback select) {
    final cards = widget.layout == FlareRadioOptionLayout.cards;
    final selected = widget.selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? select : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd,
          vertical: FlareSizes.spacingSm,
        ),
        decoration: BoxDecoration(
          color: cards
              ? colors.bgPrimary
              : selected && !widget.grouped
              ? colors.bgSelected
              : null,
          borderRadius: BorderRadius.circular(
            cards ? FlareSizes.radiusLg : FlareSizes.radiusMd,
          ),
          border: Border.all(
            color: _showFocus && enabled
                ? colors.borderSelected
                : cards
                ? (selected ? colors.borderSelected : colors.borderPrimary)
                : Colors.transparent,
            width: cards && selected ? 1.5 : (cards ? 1 : 2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.option.label,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: selected || widget.grouped
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected && widget.grouped
                          ? colors.primaryText
                          : colors.textPrimary,
                    ),
                  ),
                  if (widget.option.description case final description?) ...[
                    const SizedBox(height: FlareSizes.spacing3xs),
                    Text(
                      description,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FlareSizes.fontSizeSm,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: FlareSizes.spacingSm),
              FlareIcon(
                'check',
                size: FlareSizes.iconSizeSm,
                color: colors.primaryText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
