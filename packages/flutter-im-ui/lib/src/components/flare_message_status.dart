import 'package:flutter/material.dart';

import '../models/message_lifecycle.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// Final visual projection of the orthogonal message lifecycle.
enum FlareMessageDeliveryStatus {
  pending,
  sending,
  sent,
  delivered,
  read,
  failed,
  retrying,
}

enum FlareMessageStatusVariant { tick, compact }

/// One compact double-check silhouette shared by delivered and read receipts.
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

class FlareMessageStatus extends StatelessWidget {
  /// Locates the shared delivered / read double-check glyph (tests, golden hooks).
  static const Key doubleCheckKey = ValueKey('flare-message-double-check');

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

  String _label(FlareStrings strings, FlareMessageDeliveryStatus state) =>
      switch (state) {
        FlareMessageDeliveryStatus.pending => strings.messagePending,
        FlareMessageDeliveryStatus.sending => strings.messageSending,
        FlareMessageDeliveryStatus.sent => strings.messageSent,
        FlareMessageDeliveryStatus.delivered => strings.messageDelivered,
        FlareMessageDeliveryStatus.read => strings.messageRead,
        FlareMessageDeliveryStatus.failed => strings.messageFailed,
        FlareMessageDeliveryStatus.retrying => strings.messageRetrying,
      };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final effectiveStatus = lifecycle?.visualStatus ?? status;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dim = variant == FlareMessageStatusVariant.compact ? 12.0 : 16.0;
    final label = _label(strings, effectiveStatus);
    final glyph = _glyph(colors, effectiveStatus, dim, reduceMotion);

    if (effectiveStatus == FlareMessageDeliveryStatus.failed &&
        onResend != null) {
      return Semantics(
        button: true,
        label: '$label, ${strings.retry}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onResend,
          behavior: HitTestBehavior.opaque,
          child: glyph,
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
      case FlareMessageDeliveryStatus.retrying:
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
      case FlareMessageDeliveryStatus.delivered:
        return _MessageDoubleCheck(
          key: FlareMessageStatus.doubleCheckKey,
          color: tint ?? colors.messageStatusDelivered,
          size: dim,
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
