import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_brand_logo.dart';
import 'flare_screen.dart';

/// A product account entrance: a quiet desktop brand story and a focused form.
///
/// The kit owns presentation, responsive layout, safe areas and scroll behavior.
/// Hosts supply localized copy, available authentication controls and their state.
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
    this.eyebrow,
    this.footer,
    this.backLabel,
    this.onBack,
  });

  final String product;
  final String title;
  final String subtitle;
  final String? tagline;
  final String? headline;
  final String? description;
  final String? eyebrow;
  final String? footer;
  final String? backLabel;
  final VoidCallback? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => FlareScreen(
    surface: FlareScreenSurface.canvas,
    scroll: false,
    child: LayoutBuilder(
      builder: (context, viewport) {
        final wide = viewport.maxWidth >= FlareSizes.appShellCompactMinWidth;
        final colors = FlareColors.of(context);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  colors.primary.withValues(alpha: 0.10),
                  colors.bgSecondary,
                ),
                colors.bgSecondary,
              ],
              stops: const [0, 0.7],
            ),
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 44, child: _BrandPanel(this)),
                    Expanded(flex: 56, child: _FormPanel(this, compact: false)),
                  ],
                )
              : _FormPanel(this, compact: true),
        );
      },
    ),
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel(this.shell);
  final FlareAuthShell shell;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSelected,
        border: BorderDirectional(end: BorderSide(color: colors.borderPrimary)),
      ),
      child: LayoutBuilder(
        builder: (context, viewport) {
          final padding = viewport.maxWidth < 460 ? 40.0 : 56.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (viewport.maxHeight - padding * 2).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BrandLockup(shell, logoSize: FlareSizes.authBrandLogoSize),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (shell.headline case final headline?)
                            Text(
                              headline,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: FlareSizes.fontSizeAuthHeadline,
                                fontWeight: FontWeight.w700,
                                height: FlareSizes.lineHeightTight,
                                letterSpacing: -0.8,
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
                          const SizedBox(height: FlareSizes.spacing2xl),
                          ExcludeSemantics(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: FlareSizes.authArtworkWidth,
                              ),
                              child: AspectRatio(
                                aspectRatio: 320 / 200,
                                child: CustomPaint(
                                  painter: _LinkedChatsPainter(colors),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    shell.product,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: FlareSizes.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel(this.shell, {required this.compact});
  final FlareAuthShell shell;
  final bool compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      final horizontal = compact ? FlareSizes.spacing2xl : 48.0;
      final vertical = compact ? 32.0 : 48.0;
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (viewport.maxHeight - vertical * 2).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: Align(
            alignment: compact ? Alignment.topCenter : Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: FlareSizes.authFormMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (compact) ...[
                    _BrandLockup(
                      shell,
                      logoSize: FlareSizes.authMobileLogoSize,
                    ),
                    const SizedBox(height: FlareSizes.spacing2xl),
                  ],
                  _TaskSurface(shell, compact: compact),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TaskSurface extends StatelessWidget {
  const _TaskSurface(this.shell, {required this.compact});
  final FlareAuthShell shell;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        border: Border.all(color: colors.borderPrimary),
        borderRadius: BorderRadius.circular(FlareSizes.radius2xl),
        boxShadow: FlareShadows.of(Theme.of(context).brightness).sm,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          compact ? FlareSizes.spacingXl : FlareSizes.spacing2xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            if (shell.eyebrow case final eyebrow?) ...[
              Text(
                eyebrow,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: FlareSizes.spacingSm),
            ],
            Semantics(
              header: true,
              child: Text(
                shell.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeAuthTitle,
                  fontWeight: FontWeight.w700,
                  height: FlareSizes.lineHeightTight,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: FlareSizes.spacingSm),
            Text(
              shell.subtitle,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeLg,
                height: FlareSizes.lineHeightRelaxed,
              ),
            ),
            const SizedBox(height: FlareSizes.spacing2xl),
            shell.child,
            if (shell.footer case final footer?) ...[
              const SizedBox(height: FlareSizes.spacing2xl),
              Text(
                footer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: FlareSizes.fontSizeSm,
                  height: FlareSizes.lineHeightRelaxed,
                ),
              ),
            ],
          ],
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
        ExcludeSemantics(child: FlareBrandLogo(size: logoSize)),
        const SizedBox(width: FlareSizes.spacing2md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shell.product,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSize4xl,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              if (shell.tagline case final tagline?) ...[
                const SizedBox(height: FlareSizes.spacingXs),
                Text(
                  tagline,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                    height: FlareSizes.lineHeightSnug,
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

/// The same linked-chat geometry as Vue, Compose and SwiftUI; no simulated data.
class _LinkedChatsPainter extends CustomPainter {
  const _LinkedChatsPainter(this.colors);
  final FlareColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 200);
    final rear = RRect.fromRectAndRadius(
      const Rect.fromLTRB(28, 24, 220, 140),
      const Radius.circular(20),
    );
    final front = RRect.fromRectAndRadius(
      const Rect.fromLTRB(120, 82, 292, 178),
      const Radius.circular(18),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rear, Paint()..color = colors.bgSelected);
    canvas.drawRRect(
      rear,
      stroke..color = colors.primaryText.withValues(alpha: 0.24),
    );
    canvas.drawPath(
      Path()
        ..moveTo(58, 140)
        ..lineTo(58, 158)
        ..lineTo(80, 140),
      stroke,
    );
    canvas.drawRRect(front, Paint()..color = colors.bgPrimary);
    canvas.drawRRect(
      front,
      stroke..color = colors.primaryText.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      Path()
        ..moveTo(258, 178)
        ..lineTo(258, 194)
        ..lineTo(238, 178),
      stroke,
    );
    for (final x in [166.0, 198.0, 230.0]) {
      canvas.drawCircle(
        Offset(x, 130),
        4,
        Paint()..color = colors.primaryText.withValues(alpha: 0.7),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LinkedChatsPainter oldDelegate) =>
      colors != oldDelegate.colors;
}
