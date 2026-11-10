import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_hit_slop.dart';

/// A group of single-select radio rows. Inline ([Wrap]) by default, or a
/// [Column] when [vertical]. Per-option [FlareSelectOption.disabled] dims the
/// row and blocks selection. Custom-built from Flare tokens. Spec: Form/RadioGroup.
class FlareRadioGroup extends StatelessWidget {
  const FlareRadioGroup({
    super.key,
    required this.options,
    required this.value,
    this.vertical = false,
    this.onSelect,
  });

  final List<FlareSelectOption> options;
  final String value;
  final bool vertical;
  final void Function(String)? onSelect;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final (index, option) in options.indexed)
        _RadioOption(
          key: ValueKey((index, option.value)),
          option: option,
          selected: option.value == value,
          onSelect: onSelect,
        ),
    ];
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
  });
  final FlareSelectOption option;
  final bool selected;
  final ValueChanged<String>? onSelect;

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
        onTap: enabled ? select : null,
        onFocus: enabled ? _focus.requestFocus : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: FlareHitSlop(
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
}
