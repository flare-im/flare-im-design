import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
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
    required this.child,
  });

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

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final base = surface == FlareScreenSurface.surface
        ? colors.bgPrimary
        : colors.bgSecondary;
    final hasHeader =
        title != null || onBack != null || (actions?.isNotEmpty ?? false);

    Widget body = padded
        ? Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: child,
          )
        : child;
    if (scroll) body = SingleChildScrollView(child: body);

    // A page with a way back is not its destination's root: a shell hides its
    // phone navigation under it.
    return FlareDestinationDepth(
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FlareSizes.spacingMd,
                    FlareSizes.spacingSm,
                    FlareSizes.spacingMd,
                    FlareSizes.spacingSm,
                  ),
                  child: Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textPrimary,
                          ),
                          onPressed: onBack,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: FlareSizes.touchTarget,
                            minHeight: FlareSizes.touchTarget,
                          ),
                        ),
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: FlareSizes.fontSize5xl,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      ...?actions,
                    ],
                  ),
                ),
              Expanded(child: body),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}
