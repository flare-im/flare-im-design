import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A rounded checkbox with an optional [label]. When [value] or [indeterminate]
/// the box fills with the brand primary and shows a check / remove glyph.
/// Custom-built from Flare tokens. Spec: Form/Checkbox.
class FlareCheckbox extends StatelessWidget {
  const FlareCheckbox({
    super.key,
    required this.value,
    this.label,
    this.indeterminate = false,
    this.disabled = false,
    this.onChanged,
  });

  final bool value;
  final String? label;
  final bool indeterminate;
  final bool disabled;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final on = value || indeterminate;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: disabled ? null : () => onChanged?.call(!value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? colors.primary : colors.bgPrimary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                  border: Border.all(
                    color: on ? colors.primary : colors.borderHover,
                    width: 1.5,
                  ),
                ),
                child: on
                    ? Icon(
                        indeterminate ? Icons.remove : Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(label!, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
