import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

enum FlareSkeletonVariant { conversation, message, profile, text }

/// Loading skeleton — shimmering placeholder blocks for lists, bubbles and
/// profiles. Spec: General/Skeleton (`FlareSkeleton`).
class FlareSkeleton extends StatefulWidget {
  const FlareSkeleton({
    super.key,
    this.variant = FlareSkeletonVariant.conversation,
    this.rows = 4,
    this.still = false,
  });

  final FlareSkeletonVariant variant;
  final int rows;
  final bool still;

  @override
  State<FlareSkeleton> createState() => _FlareSkeletonState();
}

class _FlareSkeletonState extends State<FlareSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final animate = !widget.still && !MediaQuery.of(context).disableAnimations;
    final content = switch (widget.variant) {
      FlareSkeletonVariant.conversation => _conversation(colors),
      FlareSkeletonVariant.message => _message(colors),
      FlareSkeletonVariant.profile => _profile(colors),
      FlareSkeletonVariant.text => _text(colors),
    };
    if (!animate) return content;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            colors.bgPrimary.withValues(alpha: 0.55),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: _SweepTransform(_c.value),
        ).createShader(rect),
        child: child,
      ),
      child: content,
    );
  }

  Widget _block(
    FlareColors colors, {
    double? width,
    required double height,
    double radius = FlareSizes.radiusSm,
    bool circle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }

  Widget _line(FlareColors colors, double widthFactor, double height) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: _block(colors, height: height),
    );
  }

  Widget _conversation(FlareColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(colors, width: 44, height: 44, circle: true),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      _line(colors, 0.42, 11),
                      const SizedBox(height: 8),
                      _line(colors, 0.68, 11),
                    ],
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _block(colors, width: 34, height: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _message(FlareColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
            child: i.isEven
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _block(colors, width: 32, height: 32, circle: true),
                      const SizedBox(width: FlareSizes.spacingSm),
                      Expanded(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (45 + (i * 13) % 40) / 100,
                          child: _block(colors, height: 40, radius: FlareSizes.radiusLg),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: (45 + (i * 13) % 40) / 100,
                          child: _block(colors, height: 40, radius: FlareSizes.radiusLg),
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _profile(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacing2xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _block(colors, width: 72, height: 72, circle: true),
          const SizedBox(height: FlareSizes.spacingLg),
          FractionallySizedBox(widthFactor: 0.4, child: _block(colors, height: 15)),
          const SizedBox(height: FlareSizes.spacingSm),
          FractionallySizedBox(widthFactor: 0.6, child: _block(colors, height: 11)),
        ],
      ),
    );
  }

  Widget _text(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.rows; i++) ...[
            if (i > 0) const SizedBox(height: FlareSizes.spacingMd),
            _line(colors, (100 - (i * 17) % 45) / 100, 11),
          ],
        ],
      ),
    );
  }
}

class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.t);
  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = (t * 2 - 1) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}
