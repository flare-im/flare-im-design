import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// How [FlareBottomSheet.show] presents its content (spec `presentation`).
enum FlareSheetPresentation {
  /// A bottom sheet (the phone form factor).
  sheet,

  /// A full-height panel docked at the inline end — for longer secondary
  /// panels beside a workspace, such as a conversation's info and settings.
  drawer,
}

/// The kit's modal sheet frame — drag handle, optional [title], [child] and the
/// bottom safe area, lifted above the keyboard. Present it with
/// [FlareBottomSheet.show], which owns the route, scrim, drag and dismissal, so
/// hosts never build a sheet route of their own. Spec: Overlay/BottomSheet
/// (`FlareBottomSheet`).
class FlareBottomSheet extends StatelessWidget {
  const FlareBottomSheet({
    super.key,
    this.title,
    this.presentation = FlareSheetPresentation.sheet,
    required this.child,
  });

  final String? title;

  /// The frame to draw: the bottom sheet (handle, rounded top) or the drawer
  /// (full height, leading title). [show] picks the route that matches.
  final FlareSheetPresentation presentation;
  final Widget child;

  /// Shows what [builder] returns in a kit sheet and resolves with the value
  /// the sheet pops (null when dismissed). The sheet fits its content up to
  /// the full height below the top safe area; a scrollable child takes that
  /// height. [dismissible] false blocks the scrim, drag and back gesture while
  /// an operation owns the sheet. Motion is skipped when the platform asks for
  /// reduced motion.
  ///
  /// [presentation] [FlareSheetPresentation.drawer] shows it instead as a
  /// full-height panel sliding in from the inline end, at most
  /// [FlareSizes.componentSheetWidth] wide; the title, when given, leads it.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    bool dismissible = true,
    FlareSheetPresentation presentation = FlareSheetPresentation.sheet,
    required WidgetBuilder builder,
  }) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (presentation == FlareSheetPresentation.drawer) {
      return _showDrawer<T>(
        context,
        title: title,
        dismissible: dismissible,
        reduceMotion: reduceMotion,
        builder: builder,
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      elevation: 0,
      sheetAnimationStyle: reduceMotion ? AnimationStyle.noAnimation : null,
      builder: (_) => PopScope(
        canPop: dismissible,
        child: FlareBottomSheet(
          title: title,
          child: Builder(builder: builder),
        ),
      ),
    );
  }

  static Future<T?> _showDrawer<T>(
    BuildContext context, {
    String? title,
    required bool dismissible,
    required bool reduceMotion,
    required WidgetBuilder builder,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: reduceMotion ? Duration.zero : FlareMotion.slow,
      pageBuilder: (routeContext, _, _) => PopScope(
        canPop: dismissible,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FlareBottomSheet(
            title: title,
            presentation: FlareSheetPresentation.drawer,
            child: Builder(builder: builder),
          ),
        ),
      ),
      transitionBuilder: (routeContext, animation, _, child) {
        final rtl = Directionality.of(routeContext) == TextDirection.rtl;
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: Offset(rtl ? -1 : 1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: FlareMotion.slowCurve,
                ),
              ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (presentation == FlareSheetPresentation.drawer) {
      return _FlareSheetDrawer(title: this.title, child: child);
    }
    final colors = FlareColors.of(context);
    final title = this.title;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(FlareSizes.radiusXl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: FlareSizes.spacingSm,
                  ),
                  width: FlareSizes.iconSizeXl,
                  height: FlareSizes.spacingXs,
                  decoration: BoxDecoration(
                    color: colors.borderHover,
                    borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                  ),
                ),
              ),
              if (title != null && title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FlareSizes.spacingLg,
                    0,
                    FlareSizes.spacingLg,
                    FlareSizes.spacingSm,
                  ),
                  child: Semantics(
                    header: true,
                    namesRoute: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      // 面板名比它里面的每一行都轻一档 —— 说明这块界面「是什么」的那行字
                      // 不该盖过界面里的内容。iOS / Android / web 手机档都是 13/500/tertiary,
                      // 这份从前写的是 15/600/primary,同一个 prop 在四端落在两个层级上。
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeMd,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// The drawer surface: full height at the inline end, the kit's sheet width,
/// separated from the workspace by a hairline on its start edge.
class _FlareSheetDrawer extends StatelessWidget {
  const _FlareSheetDrawer({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final title = this.title;
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width < FlareSizes.componentSheetWidth
          ? width
          : FlareSizes.componentSheetWidth,
      height: double.infinity,
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.bgPrimary,
            border: BorderDirectional(
              start: BorderSide(color: colors.borderPrimary),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null && title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FlareSizes.spacingLg,
                      FlareSizes.spacingLg,
                      FlareSizes.spacingLg,
                      FlareSizes.spacingSm,
                    ),
                    child: Semantics(
                      header: true,
                      namesRoute: true,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeXl,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
