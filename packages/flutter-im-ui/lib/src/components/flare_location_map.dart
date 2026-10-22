import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_media_image.dart';

/// The map area of a location card and of the location picker: the static
/// map when there is one, otherwise — and when the picture fails — a drawn
/// map texture with a centre pin, never an empty box. The static map carries
/// its own centre marker (the geo proxy draws it), so the pin is only drawn on
/// the texture. The same rule as the Vue kit's `LocationMapSurface`.
class FlareLocationMapSurface extends StatelessWidget {
  const FlareLocationMapSurface({
    super.key,
    this.src,
    this.onError,
    this.attribution,
  });

  final String? src;

  /// The picture could not be drawn: the texture shows instead.
  final VoidCallback? onError;

  /// The map data's credit (OpenStreetMap's ODbL line), drawn as a small line
  /// in the bottom-right corner of the picture, clear of the centre marker.
  /// Only over the picture: the drawn texture is not map data.
  final String? attribution;

  /// The key of the drawn texture, for tests and hosts' tests.
  static const Key placeholderKey = ValueKey('flare-location-map-placeholder');

  /// The key of the [attribution] line.
  static const Key attributionKey = ValueKey('flare-location-map-attribution');

  @override
  Widget build(BuildContext context) {
    const texture = _MapTexture(key: placeholderKey);
    final provider = flareMediaImageProvider(src);
    if (provider == null) return texture;
    return Image(
      image: provider,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (!wasSynchronouslyLoaded && frame == null) return texture;
        final credit = attribution;
        if (credit == null || credit.isEmpty) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              right: 0,
              bottom: 0,
              child: _Attribution(text: credit),
            ),
          ],
        );
      },
      errorBuilder: (_, __, ___) {
        final report = onError;
        if (report != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => report());
        }
        return texture;
      },
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: constraints.maxWidth.isFinite ? constraints.maxWidth * 0.6 : 200,
        ),
        child: DecoratedBox(
          key: FlareLocationMapSurface.attributionKey,
          decoration: BoxDecoration(
            color: colors.bgPrimary.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(FlareSizes.radiusXs),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingXs),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: FlareSizes.fontSize2xs,
                height: FlareSizes.lineHeightSnug,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapTexture extends StatelessWidget {
  const _MapTexture({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return CustomPaint(
      painter: _MapTexturePainter(
        ground: colors.bgTertiary,
        street: colors.bgPrimary,
        block: colors.borderSecondary,
      ),
      child: Center(
        // The pin's tip (y 32 of 36) sits on the centre of the box.
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: CustomPaint(
            size: const Size(28, 36),
            painter: _PinPainter(
              body: colors.primary,
              rim: colors.bgPrimary,
              shadow: colors.textPrimary.withValues(alpha: 0.18),
            ),
          ),
        ),
      ),
    );
  }
}

/// Streets on a light block grid, in the surface colours of the theme.
class _MapTexturePainter extends CustomPainter {
  const _MapTexturePainter({
    required this.ground,
    required this.street,
    required this.block,
  });
  final Color ground;
  final Color street;
  final Color block;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final grid = Paint()
      ..color = block
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final road = Paint()
      ..color = street
      ..strokeCap = StrokeCap.square;
    void diagonal(double degrees, double offset, double width) {
      final angle = degrees * math.pi / 180;
      final reach = size.longestSide;
      final centre = size.center(Offset.zero) + Offset(offset, 0);
      final direction = Offset(math.cos(angle), -math.sin(angle)) * reach;
      canvas.drawLine(
        centre - direction,
        centre + direction,
        road..strokeWidth = width,
      );
    }

    diagonal(28, 0, size.shortestSide * 0.1);
    diagonal(118, size.width * 0.18, size.shortestSide * 0.05);
  }

  @override
  bool shouldRepaint(_MapTexturePainter old) =>
      old.ground != ground || old.street != street || old.block != block;
}

class _PinPainter extends CustomPainter {
  const _PinPainter({
    required this.body,
    required this.rim,
    required this.shadow,
  });
  final Color body;
  final Color rim;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(14, 33.5), width: 10, height: 3.6),
      Paint()..color = shadow,
    );
    final pin = Path()
      ..moveTo(14, 32)
      ..cubicTo(14, 32, 24, 22.9, 24, 14.8)
      ..arcToPoint(const Offset(4, 14.8), radius: const Radius.circular(10), clockwise: false)
      ..cubicTo(4, 22.9, 14, 32, 14, 32)
      ..close();
    canvas.drawPath(pin, Paint()..color = body);
    canvas.drawPath(
      pin,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(const Offset(14, 14.6), 3.6, Paint()..color = rim);
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.body != body || old.rim != rim || old.shadow != shadow;
}
