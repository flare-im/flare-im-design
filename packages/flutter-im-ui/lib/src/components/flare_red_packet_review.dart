import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_status_banner.dart';
import 'red_packet_arch.dart';
import 'red_packet_tint.dart';

/// The confirm step of sending a red packet (presentation.renderer
/// `redPacket.review`): the compact arch, the total large, kind and count, the
/// blessing and the red send key. Spec: RedPacket/RedPacketReview
/// (`FlareRedPacketReview`); docs/plugin-experience.md §4.3.
///
/// Every value is already formatted by the host or the plugin. While [busy]
/// the key spins and is locked; [error] reads in a danger banner above it.
class FlareRedPacketReview extends StatelessWidget {
  const FlareRedPacketReview({
    super.key,
    required this.amount,
    this.kindLabel,
    this.blessing,
    this.submitLabel,
    this.busy = false,
    this.error,
    this.onSubmit,
  });

  /// The formatted total ("¥26.64").
  final String amount;

  /// Kind and count, such as "拼手气红包 · 3 个".
  final String? kindLabel;
  final String? blessing;

  /// The send key's label; `packetSend` ("发红包") when null.
  final String? submitLabel;
  final bool busy;
  final String? error;
  final VoidCallback? onSubmit;

  /// The total (tests).
  static const Key amountKey = ValueKey('flare-red-packet-review-amount');

  /// The send key (tests).
  static const Key submitKey = ValueKey('flare-red-packet-review-submit');

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final kind = kindLabel?.trim() ?? '';
    final greeting = blessing?.trim() ?? '';
    final failure = error?.trim() ?? '';
    final send = submitLabel ?? strings.packetSend;
    final secondary = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareSizes.fontSizeLg,
    );
    // The group is named by what is sent ("总金额 ¥26.64"); the send key
    // says "发红包" once, on itself.
    return Semantics(
      container: true,
      label: '${strings.packetFieldTotal} $amount',
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlareRedPacketArch(compact: true),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: FlareSizes.detailPaneMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FlareSizes.spacingLg,
                  FlareSizes.spacing2xl,
                  FlareSizes.spacingLg,
                  FlareSizes.spacingLg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Spoken by the group's name, not again here.
                    ExcludeSemantics(
                      child: Text(
                        amount,
                        key: amountKey,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: flareRedPacketAmountFontSize(context),
                          height: FlareSizes.lineHeightTight,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (kind.isNotEmpty) ...[
                      const SizedBox(height: FlareSizes.spacingSm),
                      Text(kind, textAlign: TextAlign.center, style: secondary),
                    ],
                    if (greeting.isNotEmpty) ...[
                      const SizedBox(height: FlareSizes.spacingXs),
                      Text(
                        greeting,
                        textAlign: TextAlign.center,
                        style: secondary,
                      ),
                    ],
                    const SizedBox(height: FlareSizes.spacing2xl),
                    if (failure.isNotEmpty) ...[
                      Semantics(
                        liveRegion: true,
                        child: FlareStatusBanner(
                          text: failure,
                          tone: FlareStatusTone.danger,
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacingMd),
                    ],
                    FlareRedPacketTint(
                      child: FlareButton(
                        key: submitKey,
                        block: true,
                        size: FlareControlSize.lg,
                        label: send,
                        // Busy spins without dimming, like the composer's key:
                        // loading alone locks it.
                        loading: busy,
                        onPressed: onSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
