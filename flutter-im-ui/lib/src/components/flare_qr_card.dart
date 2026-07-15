import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// QR contact card — an identity header above a scannable-looking QR frame.
/// When no [qrImageUrl] is supplied a deterministic decorative (NOT scannable)
/// matrix is drawn. Spec: Profile/QRCard (`FlareQRCard`).
class FlareQRCard extends StatelessWidget {
  const FlareQRCard({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarUrl,
    this.qrImageUrl,
  });

  final String name;
  final String? subtitle;
  final String? avatarUrl;
  final String? qrImageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x2915131C), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlareAvatar(
                userId: name,
                displayName: name,
                avatarUrl: avatarUrl,
                size: 44,
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: FlareSizes.fontSize2xl,
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: FlareSizes.fontSizeSm)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FlareSizes.spacingLg),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                border: Border.all(color: colors.borderPrimary),
              ),
              child: qrImageUrl != null
                  ? Image.network(qrImageUrl!, fit: BoxFit.contain)
                  : CustomPaint(
                      painter: _QrMatrixPainter(seed: name, color: colors.textPrimary),
                      size: Size.infinite,
                    ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          SizedBox(
            width: double.infinity,
            child: Text('Scan to add me',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
          ),
        ],
      ),
    );
  }
}

/// Draws a deterministic, decorative (non-scannable) 11×11 QR-like matrix.
class _QrMatrixPainter extends CustomPainter {
  _QrMatrixPainter({required this.seed, required this.color});

  final String seed;
  final Color color;

  static const int _grid = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _grid;
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final radius = Radius.circular(cell * 0.25);
    final seedValue = seed.codeUnits.fold<int>(7, (a, c) => a + c);

    for (var y = 0; y < _grid; y++) {
      for (var x = 0; x < _grid; x++) {
        final isFinder =
            (x < 3 && y < 3) || (x > 7 && y < 3) || (x < 3 && y > 7);
        if (isFinder) continue;
        if ((x * 31 + y * 17 + seedValue) % 5 == 0) {
          final rect = Rect.fromLTWH(
            x * cell + cell * 0.12,
            y * cell + cell * 0.12,
            cell * 0.76,
            cell * 0.76,
          );
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), fill);
        }
      }
    }

    _finder(canvas, cell, 0, 0, color);
    _finder(canvas, cell, _grid - 3, 0, color);
    _finder(canvas, cell, 0, _grid - 3, color);
  }

  void _finder(Canvas canvas, double cell, int gx, int gy, Color color) {
    final left = gx * cell;
    final top = gy * cell;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.28;
    final outer = Rect.fromLTWH(
      left + cell * 0.3,
      top + cell * 0.3,
      cell * 2.4,
      cell * 2.4,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(outer, Radius.circular(cell * 0.5)), stroke);

    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final inner = Rect.fromLTWH(
      left + cell * 1.1,
      top + cell * 1.1,
      cell * 0.8,
      cell * 0.8,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.2)), fill);
  }

  @override
  bool shouldRepaint(_QrMatrixPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}
