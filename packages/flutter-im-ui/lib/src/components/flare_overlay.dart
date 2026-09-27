import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon_button.dart';

// Internal plumbing shared by the overlay family — FlareBottomSheet, FlareModal
// and FlareDrawer. Not exported from the package: hosts only see the three
// components and their presenters.

/// Which kind of kit overlay surface a subtree is drawn on.
enum FlareOverlayKind { sheet, modal, drawer }

/// Marks content drawn on a kit overlay surface, so a body that frames itself
/// when it stands alone (FlareMessageActionSheet, FlareDangerConfirm) leaves
/// the frame, the title and the safe area to the surface it is shown on.
/// [animation] is the presenting route's animation, for surfaces that animate
/// themselves (the drawer slides its own panel, not the whole window).
class FlareOverlaySurface extends InheritedWidget {
  const FlareOverlaySurface({
    super.key,
    required this.kind,
    this.animation,
    required super.child,
  });

  final FlareOverlayKind kind;
  final Animation<double>? animation;

  static FlareOverlaySurface? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlareOverlaySurface>();

  @override
  bool updateShouldNotify(FlareOverlaySurface oldWidget) =>
      kind != oldWidget.kind || animation != oldWidget.animation;
}

/// How [FlareBottomSheet.show] resolved a sheet when it opened, read by the
/// FlareBottomSheet frame it builds: whether the content is handed to a
/// FlareModal ([asModal]), whether the host allows dismissal at all, and the
/// host's live busy flag. A FlareBottomSheet built without this scope resolves
/// its own presentation from the form factor on every build.
class FlareSheetResolution extends InheritedWidget {
  const FlareSheetResolution({
    super.key,
    required this.asModal,
    required this.dismissible,
    this.busy,
    required super.child,
  });

  final bool asModal;
  final bool dismissible;
  final ValueListenable<bool>? busy;

  static FlareSheetResolution? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlareSheetResolution>();

  @override
  bool updateShouldNotify(FlareSheetResolution oldWidget) =>
      asModal != oldWidget.asModal ||
      dismissible != oldWidget.dismissible ||
      busy != oldWidget.busy;
}

/// Carries the kit scopes a route loses when it is built under the navigator
/// rather than under the widget that opened it: the kit theme (brand, mode,
/// colours), the strings table and the platform adapter. None of them is an
/// [InheritedTheme], so [InheritedTheme.capture] does not carry them.
Widget Function(Widget child) flareOverlayScopes(BuildContext context) {
  final theme = context.getInheritedWidgetOfExactType<FlareTheme>();
  final strings = context.getInheritedWidgetOfExactType<FlareStringsScope>();
  final platform = context.getInheritedWidgetOfExactType<FlarePlatformScope>();
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  return (child) {
    var wrapped = child;
    if (platform != null) {
      wrapped = FlarePlatformScope(adapter: platform.adapter, child: wrapped);
    }
    if (strings != null) {
      wrapped = FlareStringsScope(strings: strings.strings, child: wrapped);
    }
    if (theme != null) {
      wrapped = FlareTheme(
        brand: theme.brand,
        mode: theme.mode,
        colors: theme.colors,
        child: wrapped,
      );
    }
    return themes.wrap(wrapped);
  };
}

/// Whether the platform asks for reduced motion.
bool flareReduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// The share of the available height an overlay may take unless the host
/// caps it (spec BottomSheet / Modal `maxHeight`, Vue 72vh).
const double flareOverlayHeightRatio = 0.72;

/// The default overlay height cap: [flareOverlayHeightRatio] of the height left
/// once the keyboard and the safe areas are taken off, so a cap never pushes a
/// form under the keyboard.
double flareOverlayDefaultMaxHeight(BuildContext context) {
  final media = MediaQuery.of(context);
  final available =
      media.size.height -
      media.viewInsets.bottom -
      media.padding.top -
      media.padding.bottom;
  return (available < 0 ? 0.0 : available) * flareOverlayHeightRatio;
}

/// The elevation of a floating overlay surface (modal box, drawer panel).
List<BoxShadow> flareOverlayShadow(BuildContext context) {
  final dark = flareThemeIsDark(
    FlareTheme.maybeOf(context)?.mode ?? FlareThemeMode.system,
    systemDark: flareSystemDark(context),
  );
  return FlareShadows.of(dark ? Brightness.dark : Brightness.light).lg;
}

/// The header row shared by FlareModal and FlareDrawer:
/// `[back?] title … [actions] [close?]`. The title leads and names the route;
/// the close control is disabled while the overlay cannot be closed.
class FlareOverlayHeader extends StatelessWidget {
  const FlareOverlayHeader({
    super.key,
    required this.title,
    required this.actions,
    required this.showClose,
    required this.closeEnabled,
    required this.onClose,
    this.onBack,
    this.backEnabled = true,
    required this.padding,
  });

  /// The visible title, or null when the row carries only controls.
  final String? title;
  final List<Widget> actions;
  final bool showClose;
  final bool closeEnabled;
  final VoidCallback onClose;

  /// Draws a leading back control when given.
  final VoidCallback? onBack;
  final bool backEnabled;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final title = this.title;
    final onBack = this.onBack;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (onBack != null)
            FlareIconButton(
              icon: 'back',
              semanticLabel: strings.back,
              disabled: !backEnabled,
              onPressed: onBack,
            ),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Semantics(
                    header: true,
                    namesRoute: true,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeXl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          ...actions,
          if (showClose)
            FlareIconButton(
              icon: 'close',
              semanticLabel: strings.close,
              disabled: !closeEnabled,
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}
