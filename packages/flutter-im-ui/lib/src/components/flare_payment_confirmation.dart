import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/capability_ui.dart';
import '../models/directory_data.dart';
import '../models/server_clock.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_modal.dart';
import 'flare_status_banner.dart';

/// The payment confirmation a host shows for the engine's confirmPayment
/// request (design 7.3; spec Message/PaymentConfirmation). The amount, payee,
/// what it is for and the order number come only from the order, so a plugin
/// cannot change the panel; the countdown runs on the server clock and an
/// expired order cannot be confirmed.
///
/// Verifying the viewer (payment password, biometrics) stays the host's
/// existing reauthenticate flow: [onConfirm] only says the viewer confirmed;
/// the host verifies and answers the engine with its proof. A host that asks
/// for the password inside the panel passes the field — a `FlarePinInput` for
/// a 6-digit payment password — as [credential]. This is
/// the panel's content, its title included; [show] presents it on the kit
/// sheet (phone) or a centred 400-wide dialog (PC).
///
/// docs/plugin-experience.md §4.3, top to bottom: the title, "由「…」发起",
/// the amount, the details — the order number folds into an "订单号 ›" row that
/// opens to the number and a copy key — the countdown (warning colour under a
/// minute), the [credential] slot, then the keys. An expired order greys the
/// amount and its key reads "重新发起" ([onStartAgain]); a [shortfall] cannot
/// be paid and offers "去充值" ([onTopUp]).
class FlarePaymentConfirmation extends StatefulWidget {
  const FlarePaymentConfirmation({
    super.key,
    required this.order,
    this.pluginName,
    this.busy = false,
    this.error,
    this.confirmDisabled = false,
    this.credential,
    this.shortfall,
    this.onConfirm,
    this.onCancel,
    this.onExpire,
    this.onTopUp,
    this.onStartAgain,
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

  /// Insufficient balance: the missing amount, already formatted ("¥6.64").
  /// Confirm is disabled, "余额不足，还差 …" reads above it and a "去充值" key
  /// calls [onTopUp]. Only an amount above zero counts (§12.19): "¥0.00" is
  /// no shortfall.
  final String? shortfall;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// The order ran out while the panel was open (once).
  final VoidCallback? onExpire;

  /// The viewer wants to top up the wallet ([shortfall] only).
  final VoidCallback? onTopUp;

  /// "重新发起" on an expired order; [onCancel] when null.
  final VoidCallback? onStartAgain;

  /// Presents what [builder] returns — normally a [FlarePaymentConfirmation]
  /// — on the kit sheet on the phone form factor (under breakpoints.sm, the
  /// kit's `bottomSheet` capability), elsewhere as a centred dialog
  /// [FlareSizes.componentPaymentDialogWidth] wide (§0.2). The panel draws its
  /// own title, so the frame keeps it as the accessible name only. While
  /// [busy] — or the panel's own `busy` — is true nothing closes it; the sheet
  /// never closes by drag.
  static Future<T?> show<T>(
    BuildContext context, {
    ValueListenable<bool>? busy,
    required WidgetBuilder builder,
  }) {
    if (flareCapabilitiesOf(context).bottomSheet) {
      return FlareBottomSheet.show<T>(
        context,
        titleBuilder: (inner) =>
            FlareStrings.of(inner).paymentConfirmationTitle,
        titleHidden: true,
        // A busy listenable, even one that never fires, turns off
        // drag-to-close, which would bypass the panel's own lock.
        busy: busy ?? _idle,
        builder: builder,
      );
    }
    return FlareModal.show<T>(
      context,
      framed: false,
      builder: (inner) {
        Widget dialog(bool locked) => FlareModal(
          title: FlareStrings.of(inner).paymentConfirmationTitle,
          titleHidden: true,
          width: FlareSizes.componentPaymentDialogWidth,
          busy: locked,
          showClose: false,
          scrollable: false,
          // The sheet's handle gives the panel this room at the top.
          child: Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingMd),
            child: builder(inner),
          ),
        );
        return busy == null
            ? dialog(false)
            : ValueListenableBuilder<bool>(
                valueListenable: busy,
                builder: (_, locked, _) => dialog(locked),
              );
      },
    );
  }

  static final ValueNotifier<bool> _idle = ValueNotifier(false);

  @override
  State<FlarePaymentConfirmation> createState() =>
      _FlarePaymentConfirmationState();
}

class _FlarePaymentConfirmationState extends State<FlarePaymentConfirmation> {
  Timer? _timer;
  int _now = FlareServerClock.nowMs();
  bool _expiredSaid = false;
  bool _orderOpen = false;

  void _checkExpiry() {
    if (!mounted) return;
    if (flarePaymentCountdown(widget.order.expiresAtMs - _now).expired &&
        !_expiredSaid) {
      _expiredSaid = true;
      widget.onExpire?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExpiry());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = FlareServerClock.nowMs());
      _checkExpiry();
    });
  }

  @override
  void didUpdateWidget(FlarePaymentConfirmation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderId != widget.order.orderId ||
        oldWidget.order.expiresAtMs != widget.order.expiresAtMs) {
      _expiredSaid = false;
      _now = FlareServerClock.nowMs();
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkExpiry());
    }
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
                  fontSize: FlareSizes.fontSizeMd,
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
                    fontSize: FlareSizes.fontSizeMd,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  /// "订单号 ›": folded by default; open, it shows the number and a copy key.
  Widget _orderRow(FlareColors colors, FlareStrings strings, String orderId) {
    final style = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareSizes.fontSizeMd,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final head = Semantics(
      button: true,
      expanded: _orderOpen,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('flare-payment-order-toggle'),
          onTap: () => setState(() => _orderOpen = !_orderOpen),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(strings.paymentConfirmationOrder, style: style),
                ),
                FlareIcon(
                  _orderOpen ? 'chevron-down' : 'chevron-right',
                  size: FlareSizes.iconSizeSm,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!_orderOpen) return head;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        Row(
          children: [
            Expanded(
              child: Text(
                orderId,
                key: const ValueKey('flare-payment-order'),
                style: style.copyWith(color: colors.textPrimary),
              ),
            ),
            FlareIconButton(
              key: const ValueKey('flare-payment-order-copy'),
              icon: 'copy',
              semanticLabel: strings.pluginViewCopyReference.replaceAll(
                '{label}',
                strings.paymentConfirmationOrder,
              ),
              onPressed: () => Clipboard.setData(ClipboardData(text: orderId)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final order = widget.order;
    final amount = flarePaymentAmountText(order.amount, order.currency);
    final remaining = order.expiresAtMs - _now;
    final countdown = flarePaymentCountdown(remaining);
    final expired = countdown.expired;
    final shortfall = widget.shortfall?.trim() ?? '';
    final insufficient = flarePaymentShortfallOwed(shortfall) && !expired;
    final canConfirm =
        !widget.busy &&
        !widget.confirmDisabled &&
        !expired &&
        !insufficient &&
        amount != null;
    final onPrimary = widget.busy
        ? null
        : expired
        ? (widget.onStartAgain ?? widget.onCancel)
        : canConfirm
        ? widget.onConfirm
        : null;
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
    // The sheet hands bounded height and lifts over the keyboard; the
    // details scroll and the keys stay under them, so confirm and cancel are
    // on screen when the keyboard leaves less room than the panel needs (the
    // focused password field scrolls itself into view). While busy the scrim,
    // Escape and back cannot close it, however the host presented it.
    final details = <Widget>[
      Semantics(
        header: true,
        child: Text(
          strings.paymentConfirmationTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: FlareSizes.fontSizeXl,
            fontWeight: FontWeight.w600,
          ),
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
      const SizedBox(height: FlareSizes.spacingLg),
      Text(
        amount ?? '—',
        key: const ValueKey('flare-payment-amount'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: expired ? colors.textDisabled : colors.textPrimary,
          fontSize: FlareSizes.componentAmountHeroFontSize,
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
          padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingXs),
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
              _orderRow(colors, strings, order.orderId),
            ],
          ),
        ),
      ),
      const SizedBox(height: FlareSizes.spacingSm),
      // Only the failure and the expiry are read out; a ticking countdown
      // is not announced every second.
      amount == null
          ? Semantics(
              liveRegion: true,
              child: alert(strings.paymentConfirmationInvalid),
            )
          : countdown.expired
          ? Semantics(
              liveRegion: true,
              child: alert(
                strings.paymentConfirmationExpired,
                key: const ValueKey('flare-payment-expired'),
              ),
            )
          : Text(
              strings.paymentConfirmationExpiresIn.replaceAll(
                '{time}',
                countdown.text,
              ),
              key: const ValueKey('flare-payment-countdown'),
              textAlign: TextAlign.center,
              style: remaining < 60000
                  ? meta.copyWith(color: colors.warningText)
                  : meta,
            ),
      // §4.3 expired: the order cannot be paid, so no password and no
      // earlier failure, only 付款已过期 and 重新发起.
      if (widget.credential != null && !expired) ...[
        const SizedBox(height: FlareSizes.spacingMd),
        widget.credential!,
      ],
      if (widget.error != null && !expired) ...[
        const SizedBox(height: FlareSizes.spacingMd),
        Semantics(
          liveRegion: true,
          child: FlareStatusBanner(
            text: widget.error!,
            tone: FlareStatusTone.danger,
          ),
        ),
      ],
      if (insufficient) ...[
        const SizedBox(height: FlareSizes.spacingMd),
        Semantics(
          liveRegion: true,
          child: alert(
            strings.paymentConfirmationInsufficient.replaceAll(
              '{amount}',
              shortfall,
            ),
            key: const ValueKey('flare-payment-insufficient'),
          ),
        ),
      ],
    ];
    final keys = <Widget>[
      const SizedBox(height: FlareSizes.spacingLg),
      FlareButton(
        key: const ValueKey('flare-payment-confirm'),
        block: true,
        size: FlareControlSize.md,
        maintainTouchTarget: true,
        label: widget.busy
            ? strings.paymentConfirmationVerifying
            : expired
            ? strings.paymentConfirmationStartAgain
            : strings.paymentConfirmationConfirm,
        loading: widget.busy,
        disabled: onPrimary == null && !widget.busy,
        onPressed: onPrimary,
      ),
      if (insufficient) ...[
        const SizedBox(height: FlareSizes.spacingSm),
        FlareButton(
          key: const ValueKey('flare-payment-top-up'),
          block: true,
          size: FlareControlSize.md,
          maintainTouchTarget: true,
          variant: FlareButtonVariant.secondary,
          label: strings.paymentConfirmationTopUp,
          disabled: widget.busy,
          onPressed: widget.onTopUp,
        ),
      ],
      const SizedBox(height: FlareSizes.spacingSm),
      FlareButton(
        key: const ValueKey('flare-payment-cancel'),
        block: true,
        size: FlareControlSize.md,
        maintainTouchTarget: true,
        variant: FlareButtonVariant.secondary,
        label: strings.cancel,
        disabled: widget.busy,
        onPressed: widget.onCancel,
      ),
    ];
    const sides = EdgeInsets.symmetric(horizontal: FlareSizes.spacingLg);
    final panel = LayoutBuilder(
      builder: (context, constraints) {
        final column = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...details, ...keys],
        );
        if (!constraints.hasBoundedHeight) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              FlareSizes.spacingSm,
              FlareSizes.spacingLg,
              FlareSizes.spacingLg,
            ),
            child: column,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              // Anchored at its end: short of room (the keyboard up) the
              // password cells and the error stay in view, the title scrolls.
              child: SingleChildScrollView(
                reverse: true,
                padding: sides.copyWith(top: FlareSizes.spacingSm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: details,
                ),
              ),
            ),
            Padding(
              padding: sides.copyWith(bottom: FlareSizes.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: keys,
              ),
            ),
          ],
        );
      },
    );
    return PopScope(canPop: !widget.busy, child: panel);
  }
}

/// Whether a formatted shortfall ("¥6.64", "0.00 CNY") owes anything: a
/// nonzero digit and no minus sign (§12.19 — only above zero).
bool flarePaymentShortfallOwed(String? shortfall) {
  final text = shortfall ?? '';
  return RegExp('[1-9]').hasMatch(text) && !RegExp('[-\u2212]').hasMatch(text);
}
