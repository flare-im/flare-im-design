import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A 44×26 pill toggle with a sliding white knob — off track uses borderHover,
/// on track the brand primary. Custom-built from Flare tokens. Spec: Form/Switch.
class FlareSwitch extends StatelessWidget {
  const FlareSwitch({
    super.key,
    required this.value,
    this.disabled = false,
    this.onChanged,
  });

  final bool value;
  final bool disabled;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Semantics(
        toggled: value,
        child: MouseRegion(
          cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: disabled ? null : () => onChanged?.call(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? colors.primary : colors.borderHover,
                borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
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
            ),
          ),
        ),
      ),
    );
  }
}
