import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Flare 品牌 Logo 呈现方式。
/// - [gradient]: 品牌渐变 squircle + 白色 F(中性/浅底、app 图标)。
/// - [plate]: 白色 squircle + 品牌渐变 F(品牌色背景上,如登录头)。
enum FlareBrandLogoVariant { gradient, plate }

/// Flare 品牌 Logo(通用件,归属 kit)。前倾几何 F,取自品牌色阶。
/// 四端共用同一几何(skewX -9°)与同一 token。
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
    final c = FlareColors.of(Theme.of(context).brightness);
    final grad = [c.primaryActive, c.primary, c.info];
    final plate = variant == FlareBrandLogoVariant.plate;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: plate ? Colors.white : null,
        gradient: plate
            ? null
            : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: grad),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FMarkPainter(plate ? grad : const [Colors.white, Colors.white]),
      ),
    );
  }
}

class _FMarkPainter extends CustomPainter {
  _FMarkPainter(this.fFill);
  final List<Color> fFill;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: fFill,
      ).createShader(Offset.zero & size);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(28 * s, 22 * s, 15 * s, 58 * s), Radius.circular(7 * s)))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(28 * s, 22 * s, 44 * s, 15 * s), Radius.circular(7 * s)))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(28 * s, 45 * s, 34 * s, 13 * s), Radius.circular(6 * s)));
    final k = math.tan(-9 * math.pi / 180);
    canvas.save();
    canvas.translate(-k * size.height / 2, 0);
    canvas.skew(k, 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FMarkPainter old) => old.fFill != fFill;
}
