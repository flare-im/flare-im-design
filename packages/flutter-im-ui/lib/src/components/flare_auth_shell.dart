import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_brand_logo.dart';
import 'flare_screen.dart';

/// Product-grade authentication scaffold shared by Flare applications.
///
/// The kit owns the responsive brand/form composition and semantic hierarchy;
/// hosts provide localized copy and their business form as [child].
class FlareAuthShell extends StatelessWidget {
  const FlareAuthShell({
    super.key,
    required this.product,
    required this.title,
    required this.subtitle,
    required this.child,
    this.tagline,
    this.headline,
    this.description,
    this.backLabel,
    this.onBack,
  });

  final String product;
  final String title;
  final String subtitle;
  final String? tagline;
  final String? headline;
  final String? description;
  final String? backLabel;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return LayoutBuilder(
      builder: (context, viewport) {
        final wide = viewport.maxWidth >= FlareSizes.appShellCompactMinWidth;
        return FlareScreen(
          surface: wide ? FlareScreenSurface.brand : FlareScreenSurface.surface,
          scroll: false,
          child: ColoredBox(
            color: colors.bgPrimary,
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: _BrandPanel(this)),
                      Expanded(
                        flex: 6,
                        child: _FormPanel(this, showBrand: false),
                      ),
                    ],
                  )
                : _FormPanel(this, showBrand: true),
          ),
        );
      },
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel(this.shell);
  final FlareAuthShell shell;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              colors.info.withValues(alpha: 0.18),
              colors.bgPrimary,
            ),
            Color.alphaBlend(
              colors.primary.withValues(alpha: 0.10),
              colors.bgSecondary,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandLockup(shell, logoSize: 72),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shell.headline case final headline?)
                        Text(
                          headline,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: FlareSizes.fontSize5xl,
                            fontWeight: FontWeight.w700,
                            height: FlareSizes.lineHeightTight,
                          ),
                        ),
                      if (shell.description case final description?) ...[
                        const SizedBox(height: FlareSizes.spacingLg),
                        Text(
                          description,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: FlareSizes.fontSize2xl,
                            height: FlareSizes.lineHeightRelaxed,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel(this.shell, {required this.showBrand});
  final FlareAuthShell shell;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final horizontal = showBrand ? FlareSizes.spacing2xl : 64.0;
    final vertical = showBrand ? FlareSizes.spacing2xl : 48.0;
    return ColoredBox(
      color: colors.bgPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - vertical * 2)
                  .clamp(0.0, double.infinity)
                  .toDouble(),
            ),
            child: Align(
              alignment: showBrand ? Alignment.topCenter : Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBrand) ...[
                      _BrandLockup(shell, logoSize: 52),
                      const SizedBox(height: FlareSizes.spacing2xl),
                    ],
                    if (shell.onBack != null && shell.backLabel != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: shell.onBack,
                          icon: const Icon(
                            Icons.arrow_back,
                            size: FlareSizes.iconSizeSm,
                          ),
                          label: Text(shell.backLabel!),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textLink,
                            minimumSize: const Size(
                              FlareSizes.touchTargetMin,
                              FlareSizes.touchTargetMin,
                            ),
                          ),
                        ),
                      ),
                    Semantics(
                      header: true,
                      child: Text(
                        shell.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSize5xl,
                          fontWeight: FontWeight.w700,
                          height: FlareSizes.lineHeightTight,
                        ),
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacingSm),
                    Text(
                      shell.subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FlareSizes.fontSize2xl,
                        height: FlareSizes.lineHeightRelaxed,
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacing2xl),
                    shell.child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup(this.shell, {required this.logoSize});
  final FlareAuthShell shell;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlareBrandLogo(size: logoSize),
        const SizedBox(width: FlareSizes.spacingLg),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shell.product,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSize3xl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (shell.tagline case final tagline?) ...[
                const SizedBox(height: FlareSizes.spacingXs),
                Text(
                  tagline,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: FlareSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
