import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

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
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final canDec = !disabled && value > min;
    final canInc = !disabled && value < max;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      // The −/+ keys are full touch targets at every size: they are laid over
      // the pill and reach past its edges, so the pill keeps its height.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
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
                  _StepGlyph(
                    icon: 'remove',
                    enabled: canDec,
                    size: _btnSize,
                    iconSize: _iconSize,
                    colors: colors,
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
                  _StepGlyph(
                    icon: 'add',
                    enabled: canInc,
                    size: _btnSize,
                    iconSize: _iconSize,
                    colors: colors,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  FlareIconControl(
                    label: strings.decrease,
                    enabled: canDec,
                    onTap: () => _set(value - step),
                    child: const SizedBox.shrink(),
                  ),
                  const Spacer(),
                  FlareIconControl(
                    label: strings.increase,
                    enabled: canInc,
                    onTap: () => _set(value + step),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
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

/// What a −/+ key shows inside the pill; its touch target is laid over it.
class _StepGlyph extends StatelessWidget {
  const _StepGlyph({
    required this.icon,
    required this.enabled,
    required this.size,
    required this.iconSize,
    required this.colors,
  });

  final String icon;
  final bool enabled;
  final double size;
  final double iconSize;
  final FlareColors colors;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SizedBox(
        width: size,
        height: size,
        child: FlareIcon(icon, size: iconSize, color: colors.textSecondary),
      ),
    );
  }
}
