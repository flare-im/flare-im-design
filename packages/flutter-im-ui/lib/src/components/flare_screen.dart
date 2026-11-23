import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon_button.dart';
import 'flare_shell_scope.dart';

/// Page surface for [FlareScreen] — mirrors the Vue contract.
enum FlareScreenSurface { canvas, surface, brand }

/// FlareScreen — the base page scaffold every Flare business page builds on.
///
/// It owns the themed page surface (auto light/dark — the app's [ThemeMode]
/// drives it, so `ThemeMode.system` follows the OS), an optional header
/// (back / large title / actions), and a scrollable, safe-area body. Business
/// code writes `FlareScreen(title: '设置', onBack: pop, child: …)` and gets a
/// consistent, fully themeable page — no page-level colours are hard-coded.
class FlareScreen extends StatelessWidget {
  const FlareScreen({
    super.key,
    this.title,
    this.onBack,
    this.actions,
    this.surface = FlareScreenSurface.canvas,
    this.padded = false,
    this.scroll = true,
    this.footer,
    this.contentMaxWidth,
    this.detail = false,
    required this.child,
  });

  /// The page is the detail pane beside a list (Vue `layout="detail"`): kit
  /// panels in it keep their keys at their own size instead of filling the row.
  final bool detail;

  /// The reading column of a readable page or a detail pane (Vue
  /// `--flare-component-screen-reading-width`).
  static const double readingWidth = 720;

  /// Large-title text. Omit for a headerless page.
  final String? title;

  /// When non-null, a leading back button is shown and calls this.
  final VoidCallback? onBack;

  /// Trailing header widgets (icons / buttons).
  final List<Widget>? actions;

  /// `canvas` grouped-list bg, `surface` flat panel, `brand` theme accent wash.
  final FlareScreenSurface surface;

  /// Pad the body (16px).
  final bool padded;

  /// Scrollable body. Default true.
  final bool scroll;

  /// Optional pinned footer.
  final Widget? footer;

  /// Center a focused directory/form on wide windows; phones remain full width.
  final double? contentMaxWidth;

  final Widget child;

  /// The title of the [FlareScreen] [context] is in, or null. A kit panel
  /// leaves out its own heading when the screen already says it (Vue
  /// `useScreenLayout().title`).
  static String? titleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScreenTitle>()?.title;

  /// Whether [context] is in a [FlareScreen] marked [detail].
  static bool detailOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScreenTitle>()?.detail ??
      false;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final base = surface == FlareScreenSurface.surface
        ? colors.bgPrimary
        : colors.bgSecondary;
    final hasHeader =
        title != null || onBack != null || (actions?.isNotEmpty ?? false);
    final maxWidth = contentMaxWidth;

    Widget body = padded
        ? Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: child,
          )
        : child;
    body = _ScreenTitle(title: title, detail: detail, child: body);
    // Vue `.flare-screen--detail`: the pane owns one 20 gutter and a reading
    // column (720), start-aligned; kit children inside drop their own insets.
    if (detail) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(
          FlareSizes.spacingXl,
          FlareSizes.spacingSm,
          FlareSizes.spacingXl,
          FlareSizes.spacingXl,
        ),
        child: body,
      );
    }
    if (scroll) body = SingleChildScrollView(child: body);

    // A page with a way back is not its destination's root: a shell hides its
    // phone navigation under it.
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: colors.textPrimary,
          decoration: TextDecoration.none,
        ),
        child: FlareDestinationDepth(
          active: onBack != null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface == FlareScreenSurface.brand ? null : base,
              gradient: surface == FlareScreenSurface.brand
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Color.alphaBlend(
                          colors.primary.withValues(alpha: 0.18),
                          base,
                        ),
                        base,
                      ],
                    )
                  : null,
            ),
            child: Align(
              alignment: detail
                  ? AlignmentDirectional.topStart
                  : Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      maxWidth != null && maxWidth.isFinite && maxWidth > 0
                      ? maxWidth
                      : detail
                      ? readingWidth + FlareSizes.spacingXl * 2
                      : double.infinity,
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasHeader)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            detail
                                ? FlareSizes.spacingXl
                                : FlareSizes.spacingMd,
                            FlareSizes.spacingSm,
                            detail
                                ? FlareSizes.spacingXl
                                : FlareSizes.spacingMd,
                            FlareSizes.spacingSm,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: FlareSizes.touchTarget,
                            ),
                            child: Row(
                              children: [
                                if (onBack != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_back,
                                      size:
                                          FlareHeaderIconScope.phoneWidth(
                                            context,
                                          )
                                          ? FlareSizes.iconSizeLg
                                          : FlareSizes.iconSizeMd,
                                      color: colors.textPrimary,
                                    ),
                                    onPressed: onBack,
                                    // The kit's own word: a host without Material zh localizations would say "Back".
                                    tooltip: FlareStrings.of(context).back,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: FlareSizes.touchTarget,
                                      minHeight: FlareSizes.touchTarget,
                                    ),
                                  ),
                                if (onBack != null)
                                  const SizedBox(width: FlareSizes.spacingSm),
                                if (title != null)
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        title!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: detail
                                              ? FlareSizes.fontSize4xl
                                              : FlareSizes.fontSize5xl,
                                          fontWeight: detail
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  const Spacer(),
                                for (final action
                                    in actions ?? const <Widget>[])
                                  FlareHeaderIconScope(child: action),
                              ],
                            ),
                          ),
                        ),
                      Expanded(child: body),
                      if (footer != null) footer!,
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

class _ScreenTitle extends InheritedWidget {
  const _ScreenTitle({
    required this.title,
    required this.detail,
    required super.child,
  });

  final String? title;
  final bool detail;

  @override
  bool updateShouldNotify(_ScreenTitle oldWidget) =>
      oldWidget.title != title || oldWidget.detail != detail;
}
