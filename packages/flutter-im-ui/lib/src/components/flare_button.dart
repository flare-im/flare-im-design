import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_hit_slop.dart';

enum FlareButtonAppearance { standard, text }

/// A general-purpose pill action button with five [FlareButtonVariant]s and
/// three [FlareControlSize]s. Custom-built from Flare tokens (not a Material
/// button). Spec: General/Button.
class FlareButton extends StatefulWidget {
  const FlareButton({
    super.key,
    this.label,
    this.variant = FlareButtonVariant.primary,
    this.size = FlareControlSize.md,
    this.appearance = FlareButtonAppearance.standard,
    this.loading = false,
    this.disabled = false,
    this.block = false,
    this.icon,
    this.onPressed,
    this.child,
    this.contentPadding,
    this.maintainTouchTarget = false,
  });

  final String? label;
  final FlareButtonVariant variant;
  final FlareControlSize size;
  final FlareButtonAppearance appearance;
  final bool loading;
  final bool disabled;
  final bool block;

  /// A semantic icon name from [flareIconNames], drawn before the label.
  final String? icon;
  final VoidCallback? onPressed;
  final Widget? child;

  /// Override inner spacing for composed controls such as compact action tiles.
  final EdgeInsetsGeometry? contentPadding;

  /// Keep a full touch target even when the visible button is compact.
  final bool maintainTouchTarget;

  /// How far a pressed key shrinks (§7, §12.10); none under reduced motion,
  /// where only the colour changes.
  static const double pressScale = FlareSizes.componentPressScale;

  @override
  State<FlareButton> createState() => _FlareButtonState();
}

class _FlareButtonState extends State<FlareButton> {
  bool _hovering = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _off =>
      widget.disabled || widget.loading || widget.onPressed == null;

  @override
  void didUpdateWidget(FlareButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A key that turns off mid-press (it starts loading) never hears tap-up.
    if (_off) _pressed = false;
  }

  void _press(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  double get _height => switch (widget.size) {
    FlareControlSize.sm => FlareSizes.controlHeightSm,
    FlareControlSize.md => FlareSizes.controlHeightMd,
    FlareControlSize.lg => FlareSizes.controlHeightLg,
  };

  double get _hPad => switch (widget.size) {
    FlareControlSize.sm => FlareSizes.controlPadXSm,
    FlareControlSize.md =>
      widget.variant == FlareButtonVariant.text
          ? FlareSizes.spacingSm
          : FlareSizes.controlPadXMd,
    FlareControlSize.lg => FlareSizes.controlPadXLg,
  };

  double get _fontSize => switch (widget.size) {
    FlareControlSize.sm => FlareSizes.fontSizeMd,
    FlareControlSize.md => FlareSizes.fontSizeLg,
    FlareControlSize.lg => FlareSizes.fontSizeXl,
  };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final off = _off;
    final hover = _hovering && !off;
    // §12.10: pressed takes the pressed colour (primaryActive, errorActive;
    // bgHover for the quieter keys) over the hover one.
    final pressed = _pressed && !off;

    late Color background;
    late Color foreground;
    Color borderColor = Colors.transparent;
    switch (widget.variant) {
      case FlareButtonVariant.primary:
        background = pressed
            ? colors.primaryActive
            : hover
            ? colors.primaryHover
            : colors.primary;
        foreground = Colors.white;
      case FlareButtonVariant.secondary:
        background = pressed
            ? colors.bgHover
            : hover
            ? colors.bgSelected
            : colors.bgSecondary;
        foreground = colors.textPrimary;
        borderColor = hover ? colors.primary : colors.borderPrimary;
      case FlareButtonVariant.ghost:
        background = pressed
            ? colors.bgHover
            : hover
            ? colors.bgSelected
            : Colors.transparent;
        // 文字取 primaryText:暗色下 primary 是 #7047D6(2.66:1,AA 正文要 4.5),
        // primaryText 才提亮成 #A78BFA(5.77:1)。描边保持 primary —— 描边是填充。
        foreground = colors.primaryText;
        borderColor = colors.primary.withValues(alpha: 0.4);
      case FlareButtonVariant.danger:
        background = pressed
            ? colors.errorActive
            : hover
            ? colors.errorHover
            : colors.error;
        foreground = Colors.white;
      case FlareButtonVariant.text:
        background = pressed
            ? colors.bgHover
            : hover
            ? colors.bgSecondary
            : Colors.transparent;
        foreground = colors.primaryText;
      case FlareButtonVariant.quiet:
        background = pressed
            ? colors.bgHover
            : hover
            ? colors.bgSecondary
            : Colors.transparent;
        foreground = hover || pressed
            ? colors.textPrimary
            : colors.textSecondary;
    }

    final textAction = widget.appearance == FlareButtonAppearance.text;
    final labelledTextAction =
        textAction && (widget.label != null || widget.child != null);
    final focusTint = labelledTextAction && _focused && !off;
    if (textAction) {
      background = Colors.transparent;
      borderColor = Colors.transparent;
      foreground = switch (widget.variant) {
        FlareButtonVariant.primary ||
        FlareButtonVariant.text ||
        FlareButtonVariant.ghost => colors.primaryText,
        FlareButtonVariant.danger => colors.errorText,
        _ => colors.textSecondary,
      };
    }

    if (focusTint) background = foreground.withValues(alpha: 0.1);
    final focusBorder =
        _focused &&
        !off &&
        (!labelledTextAction ||
            (MediaQuery.maybeOf(context)?.highContrast ?? false));

    Widget label;
    if (widget.child != null) {
      label = DefaultTextStyle.merge(
        style: TextStyle(
          color: foreground,
          fontSize: _fontSize,
          fontWeight: focusTint ? FontWeight.w700 : FontWeight.w600,
          decoration: textAction ? TextDecoration.none : null,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground),
          child: widget.child!,
        ),
      );
    } else {
      label = Text(
        widget.label ?? '',
        style: TextStyle(
          color: foreground,
          fontSize: _fontSize,
          fontWeight: focusTint ? FontWeight.w700 : FontWeight.w600,
          decoration: textAction ? TextDecoration.none : null,
        ),
      );
    }

    // Both inline and block labels respect a bounded parent's width. Loose flex
    // also retains intrinsic sizing inside an unconstrained inline Row.
    final row = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox.square(
            dimension: FlareSizes.iconSizeSm,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        else if (widget.icon != null)
          Icon(
            flareIconGlyph(widget.icon!),
            size: _fontSize + 4,
            color: foreground,
          ),
        if ((widget.loading || widget.icon != null) &&
            (widget.label != null || widget.child != null))
          const SizedBox(width: FlareSizes.spacing2xs),
        if (widget.label != null || widget.child != null)
          Flexible(child: label),
      ],
    );

    final target = GestureDetector(
      onTap: off ? null : widget.onPressed,
      onTapDown: off ? null : (_) => _press(true),
      onTapUp: off ? null : (_) => _press(false),
      onTapCancel: off ? null : () => _press(false),
      // The width is not animated: a block key and a sized one cannot tween
      // (finite and unbounded constraints), and a layout change may flip it.
      child: AnimatedScale(
        scale: pressed && !reduceMotion ? FlareButton.pressScale : 1,
        duration: FlareMotion.fast,
        curve: FlareMotion.fastCurve,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : FlareMotion.fast,
          constraints: BoxConstraints(
            minHeight: widget.appearance == FlareButtonAppearance.text
                ? FlareSizes.touchTarget
                : _height,
            minWidth: widget.appearance == FlareButtonAppearance.text
                ? FlareSizes.touchTarget
                : 0,
          ),
          padding:
              widget.contentPadding ??
              EdgeInsets.symmetric(
                horizontal: widget.appearance == FlareButtonAppearance.text
                    ? 0
                    : _hPad,
                vertical: FlareSizes.spacing2xs,
              ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            border: Border.all(
              color: focusBorder ? colors.borderSelected : borderColor,
              width: focusBorder ? 2 : 1,
            ),
          ),
          child: row,
        ),
      ),
    );
    final sized = widget.block
        ? SizedBox(width: double.infinity, child: target)
        : target;

    return Semantics(
      button: true,
      enabled: !off,
      child: FocusableActionDetector(
        enabled: !off,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (!off) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: Opacity(
          opacity: widget.disabled || widget.onPressed == null
              ? FlareOpacity.disabled
              : 1,
          child: MouseRegion(
            cursor: off ? SystemMouseCursors.basic : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: widget.maintainTouchTarget
                ? FlareHitSlop(minSize: FlareSizes.touchTargetMin, child: sized)
                : sized,
          ),
        ),
      ),
    );
  }
}
