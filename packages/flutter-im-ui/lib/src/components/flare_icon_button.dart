import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

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

  /// A semantic icon name from [flareIconNames]; an unknown name draws the
  /// registry fallback and warns on the debug console.
  final String icon;
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
    final colors = FlareColors.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
        foreground = hover ? colors.primaryText : colors.textSecondary;
      case FlareIconButtonVariant.solid:
        background = colors.primary;
        foreground = Colors.white;
        if (hover) background = colors.primaryHover;
    }

    if (widget.active) {
      background = colors.bgSelected;
      foreground = colors.primaryText;
    }

    // Explicit overrides win over any variant/active/hover-derived color.
    if (widget.backgroundColor != null) background = widget.backgroundColor!;
    if (widget.tintColor != null) foreground = widget.tintColor!;

    return Opacity(
      opacity: off ? 0.45 : 1,
      child: Semantics(
        label: widget.semanticLabel,
        button: true,
        // enabled 必须写上,而且判据不能只看 disabled:onPressed 为 null 的那些同样点不动。
        // 少了它,一颗停用的图标按钮会被念成一颗普通按钮 —— 用户点下去什么也没发生,
        // 而唯一的提示是 0.45 的淡化,读屏用户看不见。文字按钮那边一直是对的
        // (flare_button.dart: `Semantics(button: true, enabled: !off)`)。
        enabled: !off && widget.onPressed != null,
        child: MouseRegion(
          cursor: off ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          // 裸 GestureDetector 默认 deferToChild,命中区就等于那个 30/38/46 的圆盘 ——
          // 低于 iOS 的 44 与 Android 的 48,而且 Flutter 不像 Material 那样自带
          // MaterialTapTargetSize 兜底。同一个包里的 icon_control.dart 早就写对了:
          // opaque + ConstrainedBox(touchTarget) + Align,圆盘居中不动、命中区撑满。
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: off ? null : widget.onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: FlareSizes.touchTarget,
                minHeight: FlareSizes.touchTarget,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : FlareMotion.fast,
                  width: _side,
                  height: _side,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: widget.square
                        ? BorderRadius.circular(FlareSizes.radiusMd)
                        : BorderRadius.circular(FlareSizes.radiusFull),
                  ),
                  child: Icon(
                    flareIconGlyph(widget.icon),
                    size: _glyph,
                    color: foreground,
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
