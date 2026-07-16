import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

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
    final colors = FlareColors.of(Theme.of(context).brightness);
    final rows = options.map((o) => _row(context, colors, o)).toList();
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

  Widget _row(BuildContext context, FlareColors colors, FlareSelectOption o) {
    final selected = o.value == value;
    return Opacity(
      opacity: o.disabled ? 0.5 : 1,
      child: MouseRegion(
        cursor: o.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: o.disabled ? null : () => onSelect?.call(o.value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.bgPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.primary : colors.borderHover,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(o.label, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
