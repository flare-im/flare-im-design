import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// A numeric stepper — a −/+ pair around a value with [min]/[max]/[step]
/// clamping. [readonly] shows the value as static text; disabled dims the whole
/// control. Token-styled (bgSecondary pill, brand hover). Custom-built from
/// Flare tokens. Spec: Form/Stepper.
class FlareStepper extends StatelessWidget {
  const FlareStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = double.infinity,
    this.step = 1,
    this.size = FlareControlSize.md,
    this.readonly = false,
    this.disabled = false,
    this.onChanged,
  });

  final num value;
  final num min;
  final num max;
  final num step;
  final FlareControlSize size;

  /// Hide the editable middle field, showing the value as static text.
  final bool readonly;
  final bool disabled;
  final void Function(num)? onChanged;

  double get _height => switch (size) {
        FlareControlSize.sm => 32,
        FlareControlSize.md => 40,
        FlareControlSize.lg => 48,
      };

  double get _btnSize => switch (size) {
        FlareControlSize.sm => 30,
        FlareControlSize.md => 38,
        FlareControlSize.lg => 46,
      };

  double get _iconSize => switch (size) {
        FlareControlSize.sm => 15,
        FlareControlSize.md => 18,
        FlareControlSize.lg => 20,
      };

  double get _fontSize => switch (size) {
        FlareControlSize.sm => 13,
        FlareControlSize.md => 14,
        FlareControlSize.lg => 15,
      };

  double get _fieldWidth => size == FlareControlSize.lg ? 52 : 44;

  num _clamp(num n) => n < min ? min : (n > max ? max : n);

  void _set(num n) {
    final next = _clamp(n);
    if (next == value) return;
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final canDec = !disabled && value > min;
    final canInc = !disabled && value < max;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          border: Border.all(color: colors.borderPrimary),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove,
              enabled: canDec,
              size: _btnSize,
              iconSize: _iconSize,
              colors: colors,
              onTap: () => _set(value - step),
            ),
            SizedBox(
              width: _fieldWidth,
              child: Text(
                _format(value),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: colors.textPrimary,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              enabled: canInc,
              size: _btnSize,
              iconSize: _iconSize,
              colors: colors,
              onTap: () => _set(value + step),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(num v) {
    if (v is int) return v.toString();
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.size,
    required this.iconSize,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final double size;
  final double iconSize;
  final FlareColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: iconSize,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
