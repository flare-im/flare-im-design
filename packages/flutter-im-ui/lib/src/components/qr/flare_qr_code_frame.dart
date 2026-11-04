import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/flare_strings.dart';
import '../../tokens/flare_tokens.dart';
import 'flare_qr_encoder.dart';

/// The square frame (code or unavailable notice) and the scan hint. Keeps the
/// encoded symbol so rebuilds with the same payload do not encode again.
class FlareQrCodeFrame extends StatefulWidget {
  const FlareQrCodeFrame({
    required this.payload,
    required this.name,
    required this.hint,
  });

  final String? payload;
  final String name;
  final String? hint;

  @override
  State<FlareQrCodeFrame> createState() => _FlareQrCodeFrameState();
}

class _FlareQrCodeFrameState extends State<FlareQrCodeFrame> {
  QrSymbol? _symbol;

  static QrSymbol? _encode(String? payload) =>
      payload == null || payload.isEmpty ? null : QrEncoder.encodeText(payload);

  @override
  void initState() {
    super.initState();
    _symbol = _encode(widget.payload);
  }

  @override
  void didUpdateWidget(FlareQrCodeFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload != widget.payload) _symbol = _encode(widget.payload);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final radius = BorderRadius.circular(FlareSizes.radiusLg);
    final border = Border.all(color: colors.borderPrimary);
    final symbol = _symbol;
    if (symbol == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(FlareSizes.spacing2md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: radius,
            border: border,
          ),
          child: Text(
            strings.qrCardUnavailable,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: FlareSizes.fontSizeSm,
            ),
          ),
        ),
      );
    }
    // Scanners expect dark modules on a light ground, so the code keeps the
    // light palette whatever the current theme is. The painted quiet zone is
    // the code's margin, so the frame adds no padding of its own.
    final light = FlareColors.resolve(
      Brightness.light,
      brand: FlareTheme.maybeOf(context)?.brand ?? FlareBrandTheme.violet,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: light.bgPrimary,
              borderRadius: radius,
              border: border,
            ),
            child: Semantics(
              container: true,
              image: true,
              label: '${strings.qrCode}, ${widget.name}',
              child: CustomPaint(
                size: Size.infinite,
                painter: _QrCodePainter(
                  symbol: symbol,
                  color: light.textPrimary,
                  devicePixelRatio:
                      MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
                  cornerRadius: FlareSizes.radiusLg,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: FlareSizes.spacingMd),
        SizedBox(
          width: double.infinity,
          child: Text(
            widget.hint ?? strings.qrCardHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: FlareSizes.fontSizeSm,
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints [symbol] centred with its quiet zone: one rectangle per run of dark
/// modules, each module a whole number of device pixels, no anti-aliasing — so
/// module edges stay crisp at any size.
class _QrCodePainter extends CustomPainter {
  _QrCodePainter({
    required this.symbol,
    required this.color,
    required this.devicePixelRatio,
    required this.cornerRadius,
  });

  final QrSymbol symbol;
  final Color color;
  final double devicePixelRatio;

  /// Corner radius of the light panel behind the code.
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final count = symbol.size + 2 * QrEncoder.quietZone;
    // The whole quiet zone stays on the rounded light panel: a square corner
    // clears a corner arc of radius r once it sits r·(1 − 1/√2) inside.
    final inset = cornerRadius * (1 - math.sqrt1_2);
    final side = math.min(size.width, size.height) - 2 * inset;
    final devicePixels = (side * devicePixelRatio / count).floorToDouble();
    final module = devicePixels >= 1
        ? devicePixels / devicePixelRatio
        : side / count;
    final left =
        (size.width - module * count) / 2 + module * QrEncoder.quietZone;
    final top =
        (size.height - module * count) / 2 + module * QrEncoder.quietZone;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (var y = 0; y < symbol.size; y++) {
      var x = 0;
      while (x < symbol.size) {
        if (!symbol.isDark(x, y)) {
          x++;
          continue;
        }
        final start = x;
        while (x < symbol.size && symbol.isDark(x, y)) {
          x++;
        }
        canvas.drawRect(
          Rect.fromLTWH(
            left + start * module,
            top + y * module,
            (x - start) * module,
            module,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrCodePainter oldDelegate) =>
      oldDelegate.symbol != symbol ||
      oldDelegate.color != color ||
      oldDelegate.devicePixelRatio != devicePixelRatio ||
      oldDelegate.cornerRadius != cornerRadius;
}
