import 'package:flutter/material.dart';

import '../models/message_lifecycle.dart';
import '../models/message_surface.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_hit_slop.dart';

/// The receipt status a bubble draws (the core SDK's MessageReceiptView
/// status, or the visual projection of the lifecycle): five states, with no
/// delivered one — a single check means the server has the message, a double
/// check that it was read (`spec/message-receipt-vectors.json`).
enum FlareMessageDeliveryStatus { pending, sending, sent, read, failed }

enum FlareMessageStatusVariant { tick, compact }

/// The double-check silhouette of a read receipt.
class _MessageDoubleCheck extends StatelessWidget {
  const _MessageDoubleCheck({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _MessageCheckPainter(color: color, doubleCheck: true),
  );
}

class _MessageCheckPainter extends CustomPainter {
  const _MessageCheckPainter({required this.color, required this.doubleCheck});

  final Color color;
  final bool doubleCheck;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 16;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path check(List<Offset> points) => Path()
      ..moveTo(points[0].dx * scale, points[0].dy * scale)
      ..lineTo(points[1].dx * scale, points[1].dy * scale)
      ..lineTo(points[2].dx * scale, points[2].dy * scale);
    if (doubleCheck) {
      canvas.drawPath(
        check(const [
          Offset(1.75, 8.5),
          Offset(4.5, 11.25),
          Offset(9.25, 5.75),
        ]),
        paint,
      );
      canvas.drawPath(
        check(const [Offset(6, 8.5), Offset(8.75, 11.25), Offset(14.25, 4.75)]),
        paint,
      );
    } else {
      canvas.drawPath(
        check(const [Offset(3.5, 8), Offset(6.5, 11), Offset(12.5, 4.75)]),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MessageCheckPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.doubleCheck != doubleCheck;
}

/// One receipt glyph (spec MessageStatus, `spec/message-receipt-vectors.json`):
/// pending clock, sending spinner (static under reduced motion), sent single
/// check, read double check in `status.read`, failed alert. With [onResend] a
/// failed glyph is the retry control: its touch target is at least
/// `layout.touchTarget` square ([FlareHitSlop]) while the glyph keeps its size.
class FlareMessageStatus extends StatelessWidget {
  /// Locates the read double-check glyph (tests, golden hooks).
  static const Key doubleCheckKey = ValueKey('flare-message-double-check');

  /// Locates the retry control of a failed glyph.
  static const Key retryKey = ValueKey('flare-message-status-retry');

  const FlareMessageStatus({
    super.key,
    required this.status,
    this.lifecycle,
    this.variant = FlareMessageStatusVariant.tick,
    this.tint,
    this.onResend,
  });

  final FlareMessageDeliveryStatus status;
  final FlareMessageLifecycle? lifecycle;
  final FlareMessageStatusVariant variant;
  final Color? tint;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final effectiveStatus = lifecycle?.visualStatus ?? status;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dim = variant == FlareMessageStatusVariant.compact ? 12.0 : 16.0;
    final label = flareMessageStatusLabel(effectiveStatus, strings);
    final glyph = _glyph(colors, effectiveStatus, dim, reduceMotion);

    if (effectiveStatus == FlareMessageDeliveryStatus.failed &&
        onResend != null) {
      return Semantics(
        button: true,
        label: strings.messageSendFailedRetry,
        excludeSemantics: true,
        child: FlareHitSlop(
          key: retryKey,
          child: GestureDetector(
            onTap: onResend,
            behavior: HitTestBehavior.opaque,
            child: glyph,
          ),
        ),
      );
    }
    return Semantics(label: label, excludeSemantics: true, child: glyph);
  }

  Widget _glyph(
    FlareColors colors,
    FlareMessageDeliveryStatus state,
    double dim,
    bool reduceMotion,
  ) {
    final pendingColor = tint ?? colors.messageStatusPending;
    switch (state) {
      case FlareMessageDeliveryStatus.pending:
        return Icon(Icons.schedule_outlined, size: dim, color: pendingColor);
      case FlareMessageDeliveryStatus.sending:
        if (reduceMotion)
          return Icon(Icons.schedule_outlined, size: dim, color: pendingColor);
        return SizedBox.square(
          dimension: dim,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: pendingColor,
          ),
        );
      case FlareMessageDeliveryStatus.sent:
        return CustomPaint(
          size: Size.square(dim),
          painter: _MessageCheckPainter(
            color: tint ?? colors.messageStatusSent,
            doubleCheck: false,
          ),
        );
      case FlareMessageDeliveryStatus.read:
        return _MessageDoubleCheck(
          key: FlareMessageStatus.doubleCheckKey,
          color: tint ?? colors.messageStatusRead,
          size: dim,
        );
      case FlareMessageDeliveryStatus.failed:
        return Icon(
          Icons.error_outline,
          size: dim,
          color: colors.messageStatusFailed,
        );
    }
  }
}
