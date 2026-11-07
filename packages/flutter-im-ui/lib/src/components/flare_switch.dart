import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// A pill toggle with a sliding knob. Spec: Form/Switch.
class FlareSwitch extends StatelessWidget {
  const FlareSwitch({
    super.key,
    required this.value,
    this.size = FlareControlSize.md,
    this.disabled = false,
    this.onChanged,
  });

  final bool value;
  final FlareControlSize size;
  final bool disabled;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final (width, height, thumb) = switch (size) {
      FlareControlSize.sm => (
        FlareSizes.componentSwitchWidthSm,
        FlareSizes.componentSwitchHeightSm,
        FlareSizes.componentSwitchThumbSm,
      ),
      FlareControlSize.md => (
        FlareSizes.componentSwitchWidthMd,
        FlareSizes.componentSwitchHeightMd,
        FlareSizes.componentSwitchThumbMd,
      ),
      FlareControlSize.lg => (
        FlareSizes.componentSwitchWidthLg,
        FlareSizes.componentSwitchHeightLg,
        FlareSizes.componentSwitchThumbLg,
      ),
    };
    final enabled = !disabled && onChanged != null;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : FlareMotion.normal;
    final track = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      padding: EdgeInsets.all((height - thumb) / 2),
      decoration: BoxDecoration(
        color: value ? colors.primary : colors.borderHover,
        borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: thumb,
          height: thumb,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF151220).withValues(alpha: 0.28),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
    if (onChanged == null) {
      return Opacity(opacity: disabled ? 0.5 : 1, child: track);
    }
    void toggle() => onChanged?.call(!value);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Semantics(
        toggled: value,
        enabled: enabled,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                toggle();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? toggle : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: FlareSizes.touchTarget,
                minHeight: FlareSizes.touchTarget,
              ),
              child: Align(widthFactor: 1, heightFactor: 1, child: track),
            ),
          ),
        ),
      ),
    );
  }
}
