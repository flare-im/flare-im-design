import 'package:flutter/material.dart';
import '../models/capability_ui.dart';
import '../models/plugin_view.dart';
import '../models/red_packet.dart';
import '../models/red_packet_page.dart';
import '../tokens/flare_tokens.dart';
import 'flare_plugin_view.dart';
import 'flare_red_packet_card.dart';
import 'flare_red_packet_review.dart';

Map<String, Object?> _map(Object? v) => v is Map
    ? {
        for (final e in v.entries)
          if (e.key is String) e.key as String: e.value,
      }
    : {};
String _text(Object? v) => v is String ? v : '';

/// Whether [view] is drawn by a compiled-in renderer: the red packet card and
/// the red packet review (the send confirm page). The payment confirmation is
/// the host capability paymentConfirmation now ([FlarePaymentConfirmation],
/// drawn by the host for the engine's confirmPayment request);
/// `redPacket.pay` and `payment.confirm` draw as the plain document like every
/// retired renderer. A review that does not map (an unconfirmed original
/// command, no send key) draws the plain document, which keeps the page's
/// note, status and recovery ([flareRedPacketReviewPlan]).
bool flareHasResolvedPresentation(FlarePluginViewModel view) =>
    view.available &&
    _renderers.contains(view.presentation?['renderer']) &&
    (view.presentation?['renderer'] != 'redPacket.review' ||
        flareRedPacketReviewPlan(view) != null);

const _renderers = {'redPacket.card', 'redPacket.review'};

/// Compiled-in visual composition over already-resolved props. It never
/// dispatches or interprets targets.
class FlareResolvedPresentation extends StatelessWidget {
  const FlareResolvedPresentation({
    super.key,
    required this.view,
    this.busy = false,
    this.fileStates = const {},
    this.onFileAction,
    this.onRequest,
  });
  final FlarePluginViewModel view;
  final bool busy;
  final Map<String, FlarePluginFileState> fileStates;
  final ValueChanged<FlarePluginFileAction>? onFileAction;
  final ValueChanged<String>? onRequest;

  Map<String, Object?> get _props => _map(view.presentation?['props']);

  FlarePluginAction? _bound(String name) {
    final id = _map(view.presentation?['actions'])[name];
    return view.actions.where((a) => a.id == id).firstOrNull;
  }

  bool get _unknown => _map(_props['journal'])['known'] == false;

  void _request(String name) {
    final a = _bound(name);
    if (a != null && !busy && !_unknown) onRequest?.call(a.id);
  }

  FlarePluginViewModel get _remainder {
    final handled = _map(view.presentation?['actions']).values.toSet();
    return FlarePluginViewModel(
      available: view.available,
      title: '',
      fields: const [],
      blocks: const [],
      actions: view.actions.where((a) => !handled.contains(a.id)).toList(),
      inputs: view.inputs,
      menuActions: view.menuActions,
      unavailableReason: view.unavailableReason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _props;
    if (view.presentation?['renderer'] == 'redPacket.review') {
      final amount = _text(p['amount']);
      final review = FlareRedPacketReview(
        // A plain decimal with its currency gets the symbol (R10); an amount
        // the plugin already formatted is drawn as it came.
        amount: flarePaymentAmountText(amount, _text(p['currency'])) ?? amount,
        kindLabel: _text(p['kindLabel']),
        blessing: _text(p['blessing']),
        submitLabel: _text(p['submitLabel']).isEmpty
            ? null
            : _text(p['submitLabel']),
        error: _text(p['error']),
        busy: busy,
        onSubmit: _bound('submit') == null || _unknown
            ? null
            : () => _request('submit'),
      );
      if (view.unavailableReason != FlarePluginUnavailableReason.unboundCopy) {
        return review;
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          review,
          FlarePluginView(
            view: _remainder,
            embedded: true,
            fileStates: fileStates,
            onFileAction: onFileAction,
          ),
        ],
      );
    }
    final card = FlareRedPacketCard(
      blessing: _text(p['blessing']),
      brandName: _text(p['brandName']),
      kind:
          FlareRedPacketKind.values
              .where((k) => k.name == p['kind'])
              .firstOrNull ??
          FlareRedPacketKind.normal,
      state: flareRedPacketCardState(
        status:
            FlareRedPacketStatus.values
                .where((s) => s.name == p['status'])
                .firstOrNull ??
            FlareRedPacketStatus.open,
        claimedByMe: p['claimedByMe'] == true,
        tapAction: p['canClaim'] == false
            ? FlareRedPacketTapAction.details
            : FlareRedPacketTapAction.open,
      ),
      busy: busy,
      disabled: _bound('open') == null,
      onOpen: () => _request('open'),
    );
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: FlareSizes.componentRedPacketCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            card,
            if (view.unavailableReason ==
                FlarePluginUnavailableReason.unboundCopy)
              FlarePluginView(
                view: _remainder,
                embedded: true,
                fileStates: fileStates,
                onFileAction: onFileAction,
              ),
          ],
        ),
      ),
    );
  }
}
