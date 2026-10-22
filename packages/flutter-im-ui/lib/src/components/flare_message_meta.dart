import 'package:flutter/material.dart';

import '../models/message_lifecycle.dart';
import '../models/message_surface.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_hit_slop.dart';
import 'flare_message_status.dart';

enum FlareMessageMetaDensity { compact, normal }

/// Stable metadata row for time, mutation, ephemeral state and the outgoing
/// receipt (spec MessageMeta; placement in
/// `spec/message-meta-placement-vectors.json`, receipt in
/// `spec/message-receipt-vectors.json`).
///
/// [placement] says where the row sits; the bubble lays it out. Under
/// bare media and cards ([FlareMessageMetaPlacement.below]) the row uses the
/// default palette and a failure is the text key "发送失败，重试" before the
/// time instead of the failed glyph. Inside a bubble [tint] is the on-bubble
/// colour of an outgoing message, and the failed glyph is the retry control.
///
/// [readSummary] (the viewer's own group message) replaces the check of a sent
/// or read message with "N 人未读" / "全部已读"; with [onReadReceiptOpen] it is
/// a text key. Every key here answers a tap anywhere in its
/// `layout.touchTarget` square ([FlareHitSlop]).
class FlareMessageMeta extends StatelessWidget {
  const FlareMessageMeta({
    super.key,
    this.timestamp = '',
    this.edited = false,
    this.status,
    this.lifecycle,
    this.ephemeral = FlareMessageEphemeralState.none,
    this.density = FlareMessageMetaDensity.compact,
    this.placement = FlareMessageMetaPlacement.bubbleFooter,
    this.readSummary,
    this.tint,
    this.readTint,
    this.onResend,
    this.onReadReceiptOpen,
  });

  final String timestamp;
  final bool edited;

  /// The receipt; null for incoming messages (no glyph, no summary).
  final FlareMessageDeliveryStatus? status;
  final FlareMessageLifecycle? lifecycle;
  final FlareMessageEphemeralState ephemeral;
  final FlareMessageMetaDensity density;
  final FlareMessageMetaPlacement placement;
  final FlareMessageReadSummary? readSummary;

  /// The text and glyph colour on an outgoing bubble; null is the default
  /// palette (`message.metaForeground`).
  final Color? tint;

  /// The all-read colour on an outgoing bubble; null is `status.read`.
  final Color? readTint;
  final VoidCallback? onResend;
  final VoidCallback? onReadReceiptOpen;

  /// The "发送失败，重试" key under a card or media.
  static const Key retryTextKey = ValueKey('flare-message-meta-retry');

  /// The read summary ("N 人未读" / "全部已读").
  static const Key readSummaryKey = ValueKey('flare-message-meta-read-summary');

  String _ephemeralLabel(
    FlareStrings strings,
    FlareMessageEphemeralState state,
  ) => switch (state) {
    FlareMessageEphemeralState.none => '',
    FlareMessageEphemeralState.readOnce => strings.messageReadOnce,
    FlareMessageEphemeralState.burnAfterRead => strings.messageBurnAfterRead,
    FlareMessageEphemeralState.expired => strings.messageExpired,
  };

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final resolvedEphemeral = lifecycle?.ephemeral ?? ephemeral;
    final labels = <String>[
      if (timestamp.isNotEmpty) timestamp,
      if (edited || lifecycle?.mutation == FlareMessageMutationState.edited)
        strings.messageEdited,
      if (_ephemeralLabel(strings, resolvedEphemeral).isNotEmpty)
        _ephemeralLabel(strings, resolvedEphemeral),
    ];
    final below = placement == FlareMessageMetaPlacement.below;
    // Under a card or media the meta never takes the bubble's colours.
    final color = (below ? null : tint) ?? colors.messageMetaForeground;
    final gap = density == FlareMessageMetaDensity.compact
        ? FlareSizes.spacingXs
        : FlareSizes.spacing2xs;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final textStyle = TextStyle(
      color: color,
      fontSize: FlareSizes.fontSizeXs,
      height: FlareSizes.lineHeightTight,
    );
    // The lifecycle's projection outranks a bare status (FlareMessageStatus).
    final state = status == null && lifecycle == null
        ? null
        : (lifecycle?.visualStatus ?? status);
    final receipt = state == null
        ? const FlareMessageReceiptPresentation()
        : flareMessageReceiptPresentation(
            self: true,
            status: state,
            group: readSummary != null,
            readSummary: readSummary,
          );
    final failedText = below && state == FlareMessageDeliveryStatus.failed;
    final children = <Widget>[
      if (failedText) _retryText(strings, colors),
      if (labels.isNotEmpty)
        Text(
          labels.join(' · '),
          maxLines: largeText ? null : 1,
          overflow: largeText ? TextOverflow.visible : TextOverflow.fade,
          softWrap: largeText,
          style: textStyle,
        ),
      if (receipt.summary case final summary?)
        _summary(strings, colors, summary, textStyle)
      else if (state != null && !failedText)
        FlareMessageStatus(
          status: state,
          variant: FlareMessageStatusVariant.compact,
          tint: below ? null : tint,
          onResend: onResend,
        ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FlareSizes.iconSizeSm),
      child: largeText
          ? Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: gap,
              children: children,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0) SizedBox(width: gap),
                  children[index],
                ],
              ],
            ),
    );
  }

  /// "发送失败，重试" in `status.failed`: a key when the host can resend, plain
  /// text otherwise.
  Widget _retryText(FlareStrings strings, FlareColors colors) {
    final text = Text(
      strings.messageSendFailedRetry,
      maxLines: 1,
      style: TextStyle(
        color: colors.messageStatusFailed,
        fontSize: FlareSizes.fontSizeXs,
        height: FlareSizes.lineHeightTight,
        fontWeight: FontWeight.w500,
      ),
    );
    final resend = onResend;
    if (resend == null) {
      return KeyedSubtree(key: retryTextKey, child: text);
    }
    return Semantics(
      button: true,
      label: strings.messageSendFailedRetry,
      excludeSemantics: true,
      child: FlareHitSlop(
        key: retryTextKey,
        child: GestureDetector(
          onTap: resend,
          behavior: HitTestBehavior.opaque,
          child: text,
        ),
      ),
    );
  }

  Widget _summary(
    FlareStrings strings,
    FlareColors colors,
    FlareMessageReadSummaryText summary,
    TextStyle style,
  ) {
    final label = summary.text(strings);
    final below = placement == FlareMessageMetaPlacement.below;
    final read = (below ? null : readTint) ?? colors.messageStatusRead;
    final text = Text(
      label,
      maxLines: 1,
      style: style.copyWith(
        color: summary.allRead ? read : style.color,
        fontWeight: FontWeight.w500,
      ),
    );
    final open = onReadReceiptOpen;
    if (open == null) {
      return KeyedSubtree(key: readSummaryKey, child: text);
    }
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: FlareHitSlop(
        key: readSummaryKey,
        child: GestureDetector(
          onTap: open,
          behavior: HitTestBehavior.opaque,
          child: text,
        ),
      ),
    );
  }
}
