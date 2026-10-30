import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'red_packet_tint.dart';

/// Payment confirmation after "塞钱进红包": the amount drawn large, the paying
/// method row, confirm and cancel. Spec: Message/RedPacketPayConfirm
/// (`FlareRedPacketPayConfirm`).
///
/// This is the panel's content; [FlareRedPacketPayConfirm.show] presents it on
/// the kit sheet (a bottom sheet on the phone form factor, a centered modal
/// elsewhere) under the localized title. Whether the balance covers the amount
/// is the host's call: [insufficient] disables confirm and says why. While
/// [busy] both buttons are locked; pass the same state to [show] as its `busy`
/// listenable so the scrim, drag, Escape and back are locked too.
class FlareRedPacketPayConfirm extends StatelessWidget {
  const FlareRedPacketPayConfirm({
    super.key,
    required this.amount,
    required this.methodLabel,
    this.confirmLabel,
    this.insufficient = false,
    this.busy = false,
    this.onConfirm,
    this.onCancel,
  });

  /// The amount to pay, formatted by the host ("¥5.00").
  final String amount;

  /// The paying account, e.g. "钱包（余额 ¥12.00）".
  final String methodLabel;
  final String? confirmLabel;
  final bool insufficient;
  final bool busy;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Presents what [builder] returns — normally a [FlareRedPacketPayConfirm]
  /// the host rebuilds as [busy] changes — on the kit sheet, titled with the
  /// strings table's `packetPayTitle`. Resolves with the value the sheet pops.
  static Future<T?> show<T>(
    BuildContext context, {
    ValueListenable<bool>? busy,
    required WidgetBuilder builder,
  }) => FlareBottomSheet.show<T>(
    context,
    title: FlareStrings.of(context).packetPayTitle,
    busy: busy,
    builder: builder,
  );

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingSm,
        FlareSizes.spacingLg,
        FlareSizes.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            amount,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: FlareSizes.componentRedPacketAmountFontSize,
              height: FlareSizes.lineHeightTight,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: FlareSizes.spacingLg),
          MergeSemantics(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: FlareSizes.touchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingXs,
              ),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: colors.borderSecondary),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    strings.packetPayMethod,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FlareSizes.fontSizeLg,
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingMd),
                  Expanded(
                    child: Text(
                      methodLabel,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeLg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (insufficient) ...[
            const SizedBox(height: FlareSizes.spacingSm),
            Semantics(
              liveRegion: true,
              child: Text(
                strings.packetInsufficient,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: colors.errorText,
                  fontSize: FlareSizes.fontSizeMd,
                ),
              ),
            ),
          ],
          const SizedBox(height: FlareSizes.spacingLg),
          FlareRedPacketTint(
            child: FlareButton(
              block: true,
              size: FlareControlSize.lg,
              label: confirmLabel ?? strings.packetPayConfirm,
              loading: busy,
              disabled: insufficient,
              onPressed: onConfirm,
            ),
          ),
          const SizedBox(height: FlareSizes.spacingSm),
          FlareButton(
            block: true,
            size: FlareControlSize.lg,
            variant: FlareButtonVariant.quiet,
            label: strings.cancel,
            disabled: busy,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
