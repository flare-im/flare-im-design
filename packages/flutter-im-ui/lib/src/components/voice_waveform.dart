import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A voice waveform: [levels] (0–1) drawn as rounded bars spread across the
/// width it is given, the first [filled] bars in [filledColor].
///
/// It takes no minimum width. When the space cannot hold every bar with a
/// visible gap — a narrow bubble, or a row squeezed by large text — it draws
/// fewer bars sampled from [levels] instead of overflowing.
///
/// Internal: not exported from the package.
class FlareVoiceWaveform extends StatelessWidget {
  const FlareVoiceWaveform({
    super.key,
    required this.levels,
    required this.color,
    this.filledColor,
    this.filled = 0,
    this.barWidth = 2.5,
    this.minHeight = 4,
    this.maxHeight = 22,
  });

  final List<double> levels;
  final Color color;
  final Color? filledColor;

  /// How many of [levels], from the start, are drawn in [filledColor].
  final int filled;
  final double barWidth;

  /// Bar height at level 0 and level 1; the waveform is [maxHeight] tall.
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          levels: levels,
          color: color,
          filledColor: filledColor ?? color,
          filled: filled,
          barWidth: barWidth,
          minHeight: minHeight,
          maxHeight: maxHeight,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.levels,
    required this.color,
    required this.filledColor,
    required this.filled,
    required this.barWidth,
    required this.minHeight,
    required this.maxHeight,
  });

  final List<double> levels;
  final Color color;
  final Color filledColor;
  final int filled;
  final double barWidth;
  final double minHeight;
  final double maxHeight;

  /// The narrowest gap that still reads as separate bars.
  static const double _minGap = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final total = levels.length;
    if (total == 0 || size.width < barWidth) return;
    final fits = ((size.width + _minGap) / (barWidth + _minGap)).floor();
    final count = math.max(1, math.min(total, fits));
    final gap = count > 1 ? (size.width - count * barWidth) / (count - 1) : 0.0;
    final paint = Paint();
    final radius = Radius.circular(math.min(2, barWidth / 2));
    for (var i = 0; i < count; i++) {
      // Sample evenly so the last bar is still the last level.
      final index = count == 1 ? 0 : (i * (total - 1) / (count - 1)).round();
      final level = levels[index].clamp(0.0, 1.0);
      final height = minHeight + level * (maxHeight - minHeight);
      final left = i * (barWidth + gap);
      paint.color = index < filled ? filledColor : color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, (size.height - height) / 2, barWidth, height),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.color != color ||
      old.filledColor != filledColor ||
      old.filled != filled ||
      old.barWidth != barWidth ||
      old.minHeight != minHeight ||
      old.maxHeight != maxHeight ||
      !identical(old.levels, levels);
}
