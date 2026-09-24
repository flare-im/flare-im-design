import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'qr/flare_qr_encoder.dart';

/// QR contact card — an identity header above the user's QR code.
///
/// The kit encodes [qrPayload] itself (byte mode UTF-8, error correction M, the
/// smallest version, 4-module quiet zone) and paints crisp modules, dark on a
/// light panel in both themes, so any scanner reads it. Without a payload — or
/// with one too long for a QR code — the frame says "QR code unavailable"
/// instead; the card never draws a look-alike matrix.
/// Spec: Profile/QRCard (`FlareQRCard`).
class FlareQRCard extends StatelessWidget {
  const FlareQRCard({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarUrl,
    this.qrPayload,
    this.hint,
  });

  final String name;
  final String? subtitle;
  final String? avatarUrl;

  /// Text encoded into the code, e.g. the host's add-friend token or link.
  final String? qrPayload;

  /// Scan hint under the code; defaults to [FlareStrings.qrCardHint]. It is
  /// not shown while the code is unavailable.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2915131C),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
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
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSize2xl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FlareSizes.spacingLg),
          _QrCodeSection(payload: qrPayload, name: name, hint: hint),
        ],
      ),
    );
  }
}

/// The square frame (code or unavailable notice) and the scan hint. Keeps the
/// encoded symbol so rebuilds with the same payload do not encode again.
class _QrCodeSection extends StatefulWidget {
  const _QrCodeSection({
    required this.payload,
    required this.name,
    required this.hint,
  });

  final String? payload;
  final String name;
  final String? hint;

  @override
  State<_QrCodeSection> createState() => _QrCodeSectionState();
}

class _QrCodeSectionState extends State<_QrCodeSection> {
  QrSymbol? _symbol;

  static QrSymbol? _encode(String? payload) =>
      payload == null || payload.isEmpty ? null : QrEncoder.encodeText(payload);

  @override
  void initState() {
    super.initState();
    _symbol = _encode(widget.payload);
  }

  @override
  void didUpdateWidget(_QrCodeSection oldWidget) {
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
