import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A brand gradient with a white IM mark, or a white plate with a gradient mark.
enum FlareBrandLogoVariant { gradient, plate }

/// The Flare IM mark, using the shared 100×100 squircle and -9° IM geometry.
class FlareBrandLogo extends StatelessWidget {
  const FlareBrandLogo({
    super.key,
    this.size = 64,
    this.variant = FlareBrandLogoVariant.gradient,
  });

  final double size;
  final FlareBrandLogoVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      label: 'Flare IM',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _IMMarkPainter(
            colors: [colors.primaryActive, colors.primary, colors.info],
            plate: variant == FlareBrandLogoVariant.plate,
          ),
        ),
      ),
    );
  }
}

class _IMMarkPainter extends CustomPainter {
  const _IMMarkPainter({required this.colors, required this.plate});
  final List<Color> colors;
  final bool plate;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: const [0, 0.55, 1],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    final platePath = Path()
      ..moveTo(50, 3)
      ..cubicTo(12, 3, 3, 12, 3, 50)
      ..cubicTo(3, 88, 12, 97, 50, 97)
      ..cubicTo(88, 97, 97, 88, 97, 50)
      ..cubicTo(97, 12, 88, 3, 50, 3)
      ..close();
    canvas.drawPath(
      platePath,
      plate ? (Paint()..color = Colors.white) : (Paint()..shader = gradient),
    );
    final mark = Path()
      ..addRect(const Rect.fromLTRB(22, 27, 32, 75))
      ..moveTo(40, 75)
      ..lineTo(40, 27)
      ..lineTo(50, 27)
      ..lineTo(60, 48)
      ..lineTo(70, 27)
      ..lineTo(80, 27)
      ..lineTo(80, 75)
      ..lineTo(70, 75)
      ..lineTo(70, 48)
      ..lineTo(60, 65)
      ..lineTo(50, 48)
      ..lineTo(50, 75)
      ..close();
    final skew = math.tan(-9 * math.pi / 180);
    canvas.translate(-skew * 51, 0);
    canvas.skew(skew, 0);
    canvas.drawPath(
      mark,
      plate ? (Paint()..shader = gradient) : (Paint()..color = Colors.white),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IMMarkPainter oldDelegate) =>
      plate != oldDelegate.plate || !listEquals(colors, oldDelegate.colors);
}
