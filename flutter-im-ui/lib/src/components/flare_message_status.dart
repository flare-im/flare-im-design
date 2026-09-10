import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// Delivery state of an outgoing message. Neutral spec string union
/// `'pending' | 'sent' | 'read' | 'failed'`, expressed here as an enum.
enum FlareMessageDeliveryStatus { pending, sent, read, failed }

/// Visual density of [FlareMessageStatus]. Neutral union `'tick' | 'compact'`.
enum FlareMessageStatusVariant { tick, compact }

/// Small delivery-status indicator shown on outgoing message bubbles.
/// Spec: General/MessageStatus (`FlareMessageStatus`).
class FlareMessageStatus extends StatelessWidget {
  const FlareMessageStatus({
    super.key,
    required this.status,
    this.variant = FlareMessageStatusVariant.tick,
    this.tint,
    this.onResend,
  });

  /// Current delivery state.
  final FlareMessageDeliveryStatus status;

  /// Rendering density; [FlareMessageStatusVariant.compact] is slightly smaller.
  final FlareMessageStatusVariant variant;

  /// Optional tint override for sent/read/pending (e.g. white on a self bubble);
  /// failed always keeps the error color for visibility.
  final Color? tint;

  /// Contract event `resend`. Only the [FlareMessageDeliveryStatus.failed]
  /// glyph is tappable, and only when this is non-null; other states stay
  /// inert and no affordance is added.
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final double dim =
        variant == FlareMessageStatusVariant.compact ? 12 : 14;

    if (status == FlareMessageDeliveryStatus.failed && onResend != null) {
      return Semantics(
        button: true,
        label: FlareStrings.of(context).retry,
        child: GestureDetector(
          onTap: onResend,
          behavior: HitTestBehavior.opaque,
          child: Icon(Icons.error_outline, size: dim, color: colors.error),
        ),
      );
    }

    switch (status) {
      case FlareMessageDeliveryStatus.pending:
        return SizedBox(
          width: dim,
          height: dim,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: tint ?? colors.textTertiary,
          ),
        );
      case FlareMessageDeliveryStatus.sent:
        return Icon(Icons.check, size: dim, color: tint ?? colors.textTertiary);
      case FlareMessageDeliveryStatus.read:
        return Icon(Icons.done_all, size: dim, color: tint ?? colors.primary);
      case FlareMessageDeliveryStatus.failed:
        return Icon(Icons.error_outline, size: dim, color: colors.error);
    }
  }
}
