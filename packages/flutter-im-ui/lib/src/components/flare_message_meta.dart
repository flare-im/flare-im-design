import 'package:flutter/material.dart';

import '../models/message_lifecycle.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_message_status.dart';

enum FlareMessageMetaDensity { compact, normal }

/// Stable metadata row for time, mutation, ephemeral state, and outgoing receipt.
class FlareMessageMeta extends StatelessWidget {
  const FlareMessageMeta({
    super.key,
    this.timestamp = '',
    this.edited = false,
    this.status,
    this.lifecycle,
    this.ephemeral = FlareMessageEphemeralState.none,
    this.density = FlareMessageMetaDensity.compact,
    this.tint,
    this.onResend,
  });

  final String timestamp;
  final bool edited;
  final FlareMessageDeliveryStatus? status;
  final FlareMessageLifecycle? lifecycle;
  final FlareMessageEphemeralState ephemeral;
  final FlareMessageMetaDensity density;
  final Color? tint;
  final VoidCallback? onResend;

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
    final color = tint ?? colors.textTertiary;
    final gap = density == FlareMessageMetaDensity.compact
        ? FlareSizes.spacingXs
        : FlareSizes.spacing2xs;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 2;
    final children = <Widget>[
      if (labels.isNotEmpty)
        Text(
          labels.join(' · '),
          maxLines: largeText ? null : 1,
          overflow: largeText ? TextOverflow.visible : TextOverflow.fade,
          softWrap: largeText,
          style: TextStyle(
            color: color,
            fontSize: FlareSizes.fontSizeXs,
            height: FlareSizes.lineHeightTight,
          ),
        ),
      if (status != null || lifecycle != null)
        FlareMessageStatus(
          status: status ?? FlareMessageDeliveryStatus.sent,
          lifecycle: lifecycle,
          variant: FlareMessageStatusVariant.compact,
          tint: tint,
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
}
