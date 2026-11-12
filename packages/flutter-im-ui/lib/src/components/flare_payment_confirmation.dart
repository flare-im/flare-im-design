import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/capability_ui.dart';
import '../models/directory_data.dart';
import '../models/server_clock.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';

/// The payment confirmation a host shows for the engine's confirmPayment
/// request (design 7.3; spec Message/PaymentConfirmation). The amount, payee,
/// what it is for and the order number come only from the order, so a plugin
/// cannot change the panel; the countdown runs on the server clock and an
/// expired order cannot be confirmed.
///
/// Verifying the viewer (payment password, biometrics) stays the host's
/// existing reauthenticate flow: [onConfirm] only says the viewer confirmed;
/// the host verifies and answers the engine with its proof. A host that asks
/// for the password inside the panel passes the field as [credential]. This is
/// the panel's content; [show] presents it on the kit sheet.
class FlarePaymentConfirmation extends StatefulWidget {
  const FlarePaymentConfirmation({
    super.key,
    required this.order,
    this.pluginName,
    this.busy = false,
    this.error,
    this.confirmDisabled = false,
    this.credential,
    this.onConfirm,
    this.onCancel,
    this.onExpire,
  });

  final FlarePaymentOrder order;

  /// The plugin's display name: "Requested by …".
  final String? pluginName;

  /// The host is verifying the viewer: every key is locked.
  final bool busy;

  /// The host's last failure (a wrong password); the panel stays open.
  final String? error;
  final bool confirmDisabled;
  final Widget? credential;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// The order ran out while the panel was open (once).
  final VoidCallback? onExpire;

  static Future<T?> show<T>(
    BuildContext context, {
    ValueListenable<bool>? busy,
    required WidgetBuilder builder,
  }) => FlareBottomSheet.show<T>(
    context,
    titleBuilder: (inner) => FlareStrings.of(inner).paymentConfirmationTitle,
    busy: busy,
    builder: builder,
  );

  @override
  State<FlarePaymentConfirmation> createState() =>
      _FlarePaymentConfirmationState();
}

class _FlarePaymentConfirmationState extends State<FlarePaymentConfirmation> {
  Timer? _timer;
  int _now = FlareServerClock.nowMs();
  bool _expiredSaid = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = FlareServerClock.nowMs());
      if (flarePaymentCountdown(widget.order.expiresAtMs - _now).expired &&
          !_expiredSaid) {
        _expiredSaid = true;
        widget.onExpire?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _row(String label, String value, FlareColors colors, {Key? key}) =>
      MergeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareSizes.fontSizeLg,
                ),
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Text(
                  value,
                  key: key,
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
      );

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final order = widget.order;
    final amount = flarePaymentAmountText(order.amount, order.currency);
    final countdown = flarePaymentCountdown(order.expiresAtMs - _now);
    final canConfirm =
        !widget.busy &&
        !widget.confirmDisabled &&
        !countdown.expired &&
        amount != null;
    Text alert(String text, {Key? key}) => Text(
      text,
      key: key,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.errorText,
        fontSize: FlareSizes.fontSizeMd,
      ),
    );
    final meta = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareSizes.fontSizeSm,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
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
            amount ?? '—',
            key: const ValueKey('flare-payment-amount'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: FlareSizes.componentRedPacketAmountFontSize,
              height: FlareSizes.lineHeightTight,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: colors.borderSecondary),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingXs,
              ),
              child: Column(
                children: [
                  _row(
                    strings.paymentConfirmationPayee,
                    order.payee,
                    colors,
                    key: const ValueKey('flare-payment-payee'),
                  ),
                  if (order.title.isNotEmpty)
                    _row(strings.paymentConfirmationItem, order.title, colors),
                  _row(strings.paymentConfirmationOrder, order.orderId, colors),
                ],
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          Semantics(
            liveRegion: true,
            child: amount == null
                ? alert(strings.paymentConfirmationInvalid)
                : countdown.expired
                ? alert(
                    strings.paymentConfirmationExpired,
                    key: const ValueKey('flare-payment-expired'),
                  )
                : Text(
                    strings.paymentConfirmationExpiresIn.replaceAll(
                      '{time}',
                      countdown.text,
                    ),
                    key: const ValueKey('flare-payment-countdown'),
                    textAlign: TextAlign.center,
                    style: meta,
                  ),
          ),
          if (widget.pluginName != null) ...[
            const SizedBox(height: FlareSizes.spacingXs),
            Text(
              strings.paymentConfirmationRequestedBy.replaceAll(
                '{plugin}',
                widget.pluginName!,
              ),
              textAlign: TextAlign.center,
              style: meta,
            ),
          ],
          if (widget.credential != null) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            widget.credential!,
          ],
          if (widget.error != null) ...[
            const SizedBox(height: FlareSizes.spacingSm),
            Semantics(liveRegion: true, child: alert(widget.error!)),
          ],
          const SizedBox(height: FlareSizes.spacingLg),
          FlareButton(
            key: const ValueKey('flare-payment-confirm'),
            block: true,
            size: FlareControlSize.lg,
            label: widget.busy
                ? strings.paymentConfirmationVerifying
                : strings.paymentConfirmationConfirm,
            loading: widget.busy,
            disabled: !canConfirm && !widget.busy,
            onPressed: canConfirm ? widget.onConfirm : null,
          ),
          const SizedBox(height: FlareSizes.spacingSm),
          FlareButton(
            block: true,
            size: FlareControlSize.lg,
            variant: FlareButtonVariant.quiet,
            label: strings.cancel,
            disabled: widget.busy,
            onPressed: widget.onCancel,
          ),
        ],
      ),
    );
  }
}
