import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The kit's modal sheet frame — drag handle, optional [title], [child] and the
/// bottom safe area, lifted above the keyboard. Present it with
/// [FlareBottomSheet.show], which owns the route, scrim, drag and dismissal, so
/// hosts never build a sheet route of their own. Spec: Overlay/BottomSheet
/// (`FlareBottomSheet`).
class FlareBottomSheet extends StatelessWidget {
  const FlareBottomSheet({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  /// Shows what [builder] returns in a kit sheet and resolves with the value
  /// the sheet pops (null when dismissed). The sheet fits its content up to
  /// the full height below the top safe area; a scrollable child takes that
  /// height. [dismissible] false blocks the scrim, drag and back gesture while
  /// an operation owns the sheet. Motion is skipped when the platform asks for
  /// reduced motion.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    bool dismissible = true,
    required WidgetBuilder builder,
  }) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
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

  @override
  Widget build(BuildContext context) {
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
