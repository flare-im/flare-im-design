import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plugin_view.dart';
import '../models/red_packet.dart';
import '../tokens/flare_tokens.dart';
import 'flare_plugin_view.dart';
import 'flare_input.dart';
import 'flare_button.dart';
import 'flare_red_packet_card.dart';
import 'flare_red_packet_pay_confirm.dart';

Map<String, Object?> _map(Object? v) => v is Map
    ? {
        for (final e in v.entries)
          if (e.key is String) e.key as String: e.value,
      }
    : {};
String _text(Object? v) => v is String ? v : '';

/// Whether [view] is drawn by a compiled-in renderer: the red packet card and
/// the payment confirmation are all that is left after vocabulary 2 (the
/// composer and detail are declarative: money input; hero, entries, banner).
bool flareHasResolvedPresentation(FlarePluginViewModel view) =>
    view.available &&
    const [
      'redPacket.card',
      'redPacket.pay',
      'payment.confirm',
    ].contains(view.presentation?['renderer']);

/// Compiled-in visual composition over already-resolved props. It never dispatches or interprets targets.
class FlareResolvedPresentation extends StatefulWidget {
  const FlareResolvedPresentation({
    super.key,
    required this.view,
    this.busy = false,
    this.error,
    this.formErrors = const [],
    this.fileStates = const {},
    this.onFileAction,
    this.members = const [],
    this.membersLoading = false,
    this.membersRevision = 0,
    this.membersError,
    this.onMemberSearch,
    this.onMembersRetry,
    this.settleToken = 0,
    this.resolveUser,
    this.onAction,
    this.onRequest,
  });
  final FlarePluginViewModel view;
  final bool busy;
  final String? error;
  final List<FlarePluginFormError> formErrors;
  final Map<String, FlarePluginFileState> fileStates;
  final ValueChanged<FlarePluginFileAction>? onFileAction;
  final List<FlarePluginMember> members;

  /// Server member-search state; without onMemberSearch the picker filters locally.
  final bool membersLoading;

  /// An authoritative roster/permission invalidation, never an ordinary search result.
  final int membersRevision;
  final String? membersError;
  final ValueChanged<String>? onMemberSearch;
  final VoidCallback? onMembersRetry;
  final int settleToken;
  final FlarePluginResolveUser? resolveUser;
  final FlarePluginActionCallback? onAction;
  final ValueChanged<String>? onRequest;
  @override
  State<FlareResolvedPresentation> createState() =>
      _FlareResolvedPresentationState();
}

class _FlareResolvedPresentationState extends State<FlareResolvedPresentation> {
  final _paymentPassword = TextEditingController();
  final _paymentRevision = ValueNotifier(0);
  final _paymentBusy = ValueNotifier(false);
  ModalRoute<Object?>? _paymentRoute;
  NavigatorState? _paymentNavigator;
  bool _paymentOpen = false;
  bool _paymentClosing = false;
  bool _paymentDispatchPending = false;
  FlarePluginInput? get passwordInput => widget.view.inputs
      .where(
        (i) =>
            i.kind == FlarePluginInputKind.password &&
            (bound('confirm')?.form.contains(i.id) ?? false),
      )
      .firstOrNull;
  @override
  void dispose() {
    final route = _paymentRoute;
    _removePaymentSheet();
    if (route == null) {
      _disposePaymentDraft();
    } else {
      // The overlay can outlive its page until the navigator removes it.
      // Keep its field/controller valid until its widgets are unmounted.
      unawaited(route.completed.then((_) => _disposePaymentDraft()));
    }
    super.dispose();
  }

  void _disposePaymentDraft() {
    _paymentPassword.dispose();
    _paymentRevision.dispose();
    _paymentBusy.dispose();
  }

  Map<String, Object?> get p => _map(widget.view.presentation?['props']);
  String get renderer => _text(widget.view.presentation?['renderer']);
  FlarePluginAction? bound(String name) {
    final a = _map(widget.view.presentation?['actions']);
    final id = a[name] ?? (name == 'confirm' ? a['authorize'] : null);
    return widget.view.actions.where((a) => a.id == id).firstOrNull;
  }

  bool get unknown => _map(p['journal'])['known'] == false;
  bool get paymentBlocked =>
      unknown || ((widget.error?.isNotEmpty ?? false) && passwordInput == null);
  bool get _paymentEligible =>
      ['redPacket.pay', 'payment.confirm'].contains(renderer) &&
      bound('confirm') != null &&
      !paymentBlocked;
  @override
  void initState() {
    super.initState();
    _schedulePayment();
  }

  @override
  void didUpdateWidget(covariant FlareResolvedPresentation old) {
    super.didUpdateWidget(old);
    final entered = old.view.presentation?['renderer'] != renderer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (old.view != widget.view) _paymentPassword.clear();
      _paymentBusy.value = widget.busy;
      _paymentRevision.value++;
      if (!_paymentEligible ||
          (old.settleToken != widget.settleToken &&
              ((widget.error?.isNotEmpty ?? false) ||
                  widget.formErrors.isNotEmpty))) {
        _removePaymentSheet();
      } else if (entered) {
        unawaited(_showPayment(automatic: true));
      }
    });
  }

  void _schedulePayment() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showPayment(automatic: true));
    });
  }

  void _removePaymentSheet() {
    final route = _paymentRoute, navigator = _paymentNavigator;
    if (route == null || navigator == null) return;
    _paymentClosing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route.isActive) {
        _paymentPassword.clear();
        navigator.removeRoute(route);
      }
    });
  }

  void _closePayment(BuildContext sheet) {
    if (!mounted ||
        !_paymentOpen ||
        !sheet.mounted ||
        widget.busy ||
        _paymentClosing)
      return;
    _paymentClosing = true;
    _paymentPassword.clear();
    Navigator.of(sheet).pop();
  }

  Future<void> _showPayment({bool automatic = false}) async {
    if (!mounted ||
        !_paymentEligible ||
        _paymentOpen ||
        _paymentDispatchPending ||
        (!automatic && widget.busy))
      return;
    _paymentOpen = true;
    _paymentClosing = false;
    _paymentPassword.clear();
    _paymentBusy.value = widget.busy;
    try {
      await FlareRedPacketPayConfirm.show<void>(
        context,
        busy: _paymentBusy,
        builder: (sheet) {
          _paymentRoute = ModalRoute.of(sheet);
          _paymentNavigator = Navigator.of(sheet);
          return ListenableBuilder(
            listenable: _paymentRevision,
            builder: (_, _) =>
                SingleChildScrollView(child: _paymentPanel(sheet)),
          );
        },
      );
    } finally {
      _paymentRoute = null;
      _paymentNavigator = null;
      _paymentOpen = false;
      _paymentClosing = false;
      if (mounted) _paymentPassword.clear();
    }
  }

  Future<void> _confirmPayment(BuildContext sheet) async {
    final action = bound('confirm'), credential = passwordInput;
    final route = _paymentRoute;
    final owner = ModalRoute.of(context);
    final source = widget.view;
    if (!mounted ||
        !_paymentOpen ||
        _paymentClosing ||
        _paymentDispatchPending ||
        widget.busy ||
        paymentBlocked ||
        action == null ||
        route == null)
      return;
    if (credential != null &&
        !RegExp(r'^[0-9]{6}$').hasMatch(_paymentPassword.text))
      return;
    final payload = credential == null
        ? null
        : FlarePluginActionPayload(
            formValues: {credential.id: _paymentPassword.text},
          );
    _paymentDispatchPending = true;
    _closePayment(sheet);
    try {
      // A pop result precedes the overlay's exit animation. Dispatch only when
      // its route is gone, so a synchronous success may close the owning flow.
      await route.completed;
      if (!mounted ||
          widget.view != source ||
          owner?.isCurrent != true ||
          widget.busy ||
          !_paymentEligible ||
          bound('confirm')?.id != action.id)
        return;
      if (payload == null) {
        request('confirm');
      } else {
        widget.onAction?.call(action.id, payload);
      }
    } finally {
      // Host callbacks may publish busy in this same frame. Keep a second
      // confirmation from reopening before those props have reached the Kit.
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _paymentDispatchPending = false;
        });
      }
    }
  }

  Widget _paymentPanel(BuildContext sheet) {
    final input = passwordInput;
    return FlareRedPacketPayConfirm(
      confirmLabel: bound('confirm')?.label,
      amount: _text(p['amount']),
      methodLabel: _text(p['methodLabel']),
      busy: widget.busy,
      confirmDisabled:
          input != null &&
          !RegExp(r'^[0-9]{6}$').hasMatch(_paymentPassword.text),
      credential: input == null
          ? null
          : FlareInput(
              controller: _paymentPassword,
              secure: true,
              maxLength: 6,
              semanticLabel: input.label,
              placeholder: input.placeholder ?? input.label,
              keyboardType: TextInputType.number,
              disabled: widget.busy,
              onChanged: (_) => _paymentRevision.value++,
            ),
      onCancel: () => _closePayment(sheet),
      onConfirm: () => unawaited(_confirmPayment(sheet)),
    );
  }

  FlarePluginViewModel get remainder {
    final handled = _map(widget.view.presentation?['actions']).values.toSet();
    return FlarePluginViewModel(
      available: widget.view.available,
      title: '',
      fields: ['redPacket.pay', 'payment.confirm'].contains(renderer)
          ? widget.view.fields
          : const [],
      blocks: renderer == 'redPacket.card' ? const [] : widget.view.blocks,
      actions: widget.view.actions
          .where((a) => !handled.contains(a.id))
          .toList(),
      inputs: widget.view.inputs,
      menuActions: widget.view.menuActions,
      unavailableReason: widget.view.unavailableReason,
    );
  }

  void request(String name) {
    final a = bound(name);
    if (a != null &&
        !widget.busy &&
        !unknown &&
        !(name == 'confirm' && paymentBlocked))
      widget.onRequest?.call(a.id);
  }

  @override
  Widget build(BuildContext context) {
    if (renderer == 'redPacket.card') {
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
        busy: widget.busy,
        disabled: bound('open') == null,
        onOpen: () => request('open'),
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
              if (widget.view.unavailableReason ==
                  FlarePluginUnavailableReason.unboundCopy)
                FlarePluginView(
                  view: remainder,
                  embedded: true,
                  fileStates: widget.fileStates,
                  onFileAction: widget.onFileAction,
                ),
            ],
          ),
        ),
      );
    }
    final children = <Widget>[];
    if (['redPacket.pay', 'payment.confirm'].contains(renderer) &&
        bound('confirm') != null)
      children.add(
        FlareButton(
          label: bound('confirm')!.label,
          disabled: widget.busy || paymentBlocked,
          onPressed: () => unawaited(_showPayment()),
        ),
      );
    children.add(
      FlarePluginView(
        view: remainder,
        embedded: true,
        busy: widget.busy,
        error: widget.error,
        formErrors: widget.formErrors,
        fileStates: widget.fileStates,
        onFileAction: widget.onFileAction,
        settleToken: widget.settleToken,
        members: widget.members,
        membersLoading: widget.membersLoading,
        membersRevision: widget.membersRevision,
        membersError: widget.membersError,
        onMemberSearch: widget.onMemberSearch,
        onMembersRetry: widget.onMembersRetry,
        resolveUser: widget.resolveUser,
        onAction: widget.onAction,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in children)
          Padding(
            padding: const EdgeInsets.only(bottom: FlareSizes.spacingMd),
            child: c,
          ),
      ],
    );
  }
}
