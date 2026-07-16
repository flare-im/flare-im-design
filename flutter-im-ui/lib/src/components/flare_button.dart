import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// A general-purpose pill action button with five [FlareButtonVariant]s and
/// three [FlareControlSize]s. Custom-built from Flare tokens (not a Material
/// button). Spec: General/Button.
class FlareButton extends StatefulWidget {
  const FlareButton({
    super.key,
    this.label,
    this.variant = FlareButtonVariant.primary,
    this.size = FlareControlSize.md,
    this.loading = false,
    this.disabled = false,
    this.block = false,
    this.icon,
    this.onPressed,
    this.child,
  });

  final String? label;
  final FlareButtonVariant variant;
  final FlareControlSize size;
  final bool loading;
  final bool disabled;
  final bool block;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  State<FlareButton> createState() => _FlareButtonState();
}

class _FlareButtonState extends State<FlareButton> {
  bool _hovering = false;

  double get _height => switch (widget.size) {
        FlareControlSize.sm => 32,
        FlareControlSize.md => 40,
        FlareControlSize.lg => 48,
      };

  double get _hPad => switch (widget.size) {
        FlareControlSize.sm => 12,
        FlareControlSize.md => widget.variant == FlareButtonVariant.text ? 8 : 18,
        FlareControlSize.lg => 24,
      };

  double get _fontSize => switch (widget.size) {
        FlareControlSize.sm => 13,
        FlareControlSize.md => 14,
        FlareControlSize.lg => 15,
      };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final off = widget.disabled || widget.loading;

    late Color background;
    late Color foreground;
    Color borderColor = Colors.transparent;
    switch (widget.variant) {
      case FlareButtonVariant.primary:
        background = colors.primary;
        foreground = Colors.white;
        if (_hovering && !off) background = colors.primaryHover;
      case FlareButtonVariant.secondary:
        background = _hovering && !off ? colors.bgSelected : colors.bgSecondary;
        foreground = colors.textPrimary;
        borderColor = _hovering && !off ? colors.primary : colors.borderPrimary;
      case FlareButtonVariant.ghost:
        background = _hovering && !off ? colors.bgSelected : Colors.transparent;
        foreground = colors.primary;
        borderColor = colors.primary.withValues(alpha: 0.4);
      case FlareButtonVariant.danger:
        background = colors.error;
        foreground = Colors.white;
        if (_hovering && !off) background = colors.error.withValues(alpha: 0.92);
      case FlareButtonVariant.text:
        background = _hovering && !off ? colors.bgSecondary : Colors.transparent;
        foreground = colors.primary;
    }

    Widget label;
    if (widget.child != null) {
      label = DefaultTextStyle.merge(
        style: TextStyle(color: foreground, fontSize: _fontSize, fontWeight: FontWeight.w600),
        child: widget.child!,
      );
    } else {
      label = Text(
        widget.label ?? '',
        style: TextStyle(color: foreground, fontSize: _fontSize, fontWeight: FontWeight.w600),
      );
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: _fontSize + 4, color: foreground),
        if ((widget.loading || widget.icon != null) &&
            (widget.label != null || widget.child != null))
          const SizedBox(width: 6),
        if (widget.label != null || widget.child != null) label,
      ],
    );

    return Opacity(
      opacity: widget.disabled ? 0.5 : 1,
      child: MouseRegion(
        cursor: off ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: off ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: _height,
            width: widget.block ? double.infinity : null,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: _hPad),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: row,
          ),
        ),
      ),
    );
  }
}
