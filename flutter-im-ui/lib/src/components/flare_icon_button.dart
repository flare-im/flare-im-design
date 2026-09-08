import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Visual weight of a [FlareIconButton].
enum FlareIconButtonVariant { plain, tinted, solid }

/// A square/circular icon-only button — three [FlareIconButtonVariant]s, three
/// [FlareControlSize]s and an [active] toggle look. Custom-built from Flare
/// tokens. Spec: General/IconButton.
class FlareIconButton extends StatefulWidget {
  const FlareIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.size = FlareControlSize.md,
    this.variant = FlareIconButtonVariant.plain,
    this.square = false,
    this.disabled = false,
    this.active = false,
    this.onPressed,
    this.tintColor,
    this.backgroundColor,
    this.customSize,
  });

  final IconData icon;
  final String semanticLabel;
  final FlareControlSize size;
  final FlareIconButtonVariant variant;

  /// Square (radiusMd) instead of the default circle.
  final bool square;
  final bool disabled;

  /// Toggle-active look (e.g. a selected filter).
  final bool active;
  final VoidCallback? onPressed;

  /// Foreground/icon color override. Wins over the variant/active/hover-derived
  /// foreground (including hover) when non-null.
  final Color? tintColor;

  /// Background color override. Wins over the variant/active/hover-derived
  /// background when non-null.
  final Color? backgroundColor;

  /// Explicit side length (logical px). When set, the button side = customSize
  /// and the glyph size = round(customSize * 0.46). When null, the sm/md/lg
  /// bucket is used unchanged.
  final double? customSize;

  @override
  State<FlareIconButton> createState() => _FlareIconButtonState();
}

class _FlareIconButtonState extends State<FlareIconButton> {
  bool _hovering = false;

  double get _side =>
      widget.customSize ??
      switch (widget.size) {
        FlareControlSize.sm => 30,
        FlareControlSize.md => 38,
        FlareControlSize.lg => 46,
      };

  double get _glyph => widget.customSize != null
      ? (widget.customSize! * 0.46).roundToDouble()
      : switch (widget.size) {
          FlareControlSize.sm => 16,
          FlareControlSize.md => 19,
          FlareControlSize.lg => 22,
        };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final off = widget.disabled;
    final hover = _hovering && !off;

    Color background = Colors.transparent;
    Color foreground = colors.textSecondary;

    switch (widget.variant) {
      case FlareIconButtonVariant.plain:
        if (hover) {
          background = colors.bgSecondary;
          foreground = colors.textPrimary;
        }
      case FlareIconButtonVariant.tinted:
        background = hover ? colors.bgSelected : colors.bgSecondary;
        foreground = hover ? colors.primary : colors.textSecondary;
      case FlareIconButtonVariant.solid:
        background = colors.primary;
        foreground = Colors.white;
        if (hover) background = colors.primaryHover;
    }

    if (widget.active) {
      background = colors.bgSelected;
      foreground = colors.primary;
    }

    // Explicit overrides win over any variant/active/hover-derived color.
    if (widget.backgroundColor != null) background = widget.backgroundColor!;
    if (widget.tintColor != null) foreground = widget.tintColor!;

    return Opacity(
      opacity: off ? 0.45 : 1,
      child: Semantics(
        label: widget.semanticLabel,
        button: true,
        child: MouseRegion(
          cursor: off ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: off ? null : widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _side,
              height: _side,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: widget.square
                    ? BorderRadius.circular(FlareSizes.radiusMd)
                    : BorderRadius.circular(FlareSizes.radiusFull),
              ),
              child: Icon(widget.icon, size: _glyph, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
