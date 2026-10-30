import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plugin_view.dart';
import '../models/red_packet.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_plugin_view.dart';
import 'flare_input.dart';
import 'flare_button.dart';
import 'flare_red_packet_card.dart';
import 'flare_red_packet_composer.dart';
import 'flare_red_packet_detail.dart';
import 'flare_red_packet_open_sheet.dart';
import 'flare_red_packet_pay_confirm.dart';

Map<String, Object?> _map(Object? v) => v is Map
    ? {
        for (final e in v.entries)
          if (e.key is String) e.key as String: e.value,
      }
    : {};
String _text(Object? v) => v is String ? v : '';
bool flareHasResolvedPresentation(FlarePluginViewModel view) {
  final renderer = view.presentation?['renderer'];
  return view.available &&
      [
        'redPacket.card',
        'redPacket.composer',
        'redPacket.detail',
        'redPacket.pay',
        'payment.confirm',
      ].contains(renderer) &&
      (renderer != 'redPacket.detail' ||
          _map(view.presentation?['props'])['details'] is Map);
}

/// Compiled-in visual composition over already-resolved props. It never dispatches or interprets targets.
class FlareResolvedPresentation extends StatefulWidget {
  const FlareResolvedPresentation({
    super.key,
    required this.view,
    this.busy = false,
    this.error,
    this.formErrors = const [],
    this.members = const [],
    this.settleToken = 0,
    this.resolveUser,
    this.onAction,
    this.onRequest,
  });
  final FlarePluginViewModel view;
  final bool busy;
  final String? error;
  final List<FlarePluginFormError> formErrors;
  final List<FlarePluginMember> members;
  final int settleToken;
  final FlarePluginResolveUser? resolveUser;
  final FlarePluginActionCallback? onAction;
  final ValueChanged<String>? onRequest;
  @override
  State<FlareResolvedPresentation> createState() =>
      _FlareResolvedPresentationState();
}

class _FlareResolvedPresentationState extends State<FlareResolvedPresentation> {
  var _recipient = '';
  var _kind = FlareRedPacketKind.normal;
  var _amount = '';
  var _count = 1;
  var _greeting = '';
  final _users = <String, FlarePluginUser>{};
  Map<String, Object?> get p => _map(widget.view.presentation?['props']);
  String get renderer => _text(widget.view.presentation?['renderer']);
  FlarePluginAction? bound(String name) {
    final a = _map(widget.view.presentation?['actions']);
    final id = a[name] ?? (name == 'confirm' ? a['authorize'] : null);
    return widget.view.actions.where((a) => a.id == id).firstOrNull;
  }

  bool get unknown => _map(p['journal'])['known'] == false;
  bool get paymentBlocked => unknown || (widget.error?.isNotEmpty ?? false);
  @override
  void initState() {
    super.initState();
    _greeting = _text(
      widget.view.inputs
          .where((i) => i.id == 'greeting')
          .firstOrNull
          ?.defaultValue,
    );
    _resolve();
  }

  @override
  void didUpdateWidget(covariant FlareResolvedPresentation old) {
    super.didUpdateWidget(old);
    _resolve();
  }

  void _resolve() {
    final ids = {
      _text(p['senderId']),
      ...((p['claims'] is List)
          ? (p['claims'] as List).map((c) => _text(_map(c)['id']))
          : <String>[]),
    };
    for (final id in ids) {
      if (id.isEmpty || _users.containsKey(id) || widget.resolveUser == null)
        continue;
      _users[id] = FlarePluginUser(name: flarePluginFallbackName(id));
      Future.sync(() => widget.resolveUser!(id)).then((u) {
        if (mounted && u != null) setState(() => _users[id] = u);
      }, onError: (_) {});
    }
  }

  FlarePluginUser person(String id) =>
      _users[id] ?? FlarePluginUser(name: flarePluginFallbackName(id));
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

  Future<void> envelope(FlareRedPacketDetailsView details) async {
    if (widget.busy || unknown || bound('open') == null) return;
    final sender = person(_text(p['senderId']));
    final claim = await FlareRedPacketOpenSheet.show<bool>(
      context,
      builder: (inner) => FlareRedPacketOpenSheet(
        senderName: sender.name,
        senderAvatar: sender.avatarUrl,
        blessing: details.greeting,
        state: FlareRedPacketOpenState.ready,
        onOpen: () => Navigator.of(inner).pop(true),
        onClose: () => Navigator.of(inner).pop(false),
        onViewDetails: () => Navigator.of(inner).pop(false),
      ),
    );
    if (mounted && claim == true) request('open');
  }

  Widget composer(FlareStrings strings) {
    final asset = _map(p['funding']);
    final exponent = asset['currencyExponent'] is int
        ? asset['currencyExponent'] as int
        : 2;
    final minor = flareRedPacketAmountMinor(_amount, exponent);
    final total = minor != null && minor.length <= 64
        ? flareRedPacketMinorText(
            (BigInt.parse(minor) *
                    BigInt.from(
                      _kind == FlareRedPacketKind.normal ? _count : 1,
                    ))
                .toString(),
            exponent,
          )
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlareRedPacketComposer(
          kinds: FlareRedPacketKind.values,
          kind: _kind,
          amount: _amount,
          currencyExponent: exponent,
          count: _count,
          greeting: _greeting,
          total: '${_text(asset['currency'])} ${total ?? ''}',
          busy: widget.busy,
          locked: unknown || bound('submit') == null,
          error: widget.formErrors.isEmpty ? null : strings.pluginFormInvalid,
          submitLabel: bound('submit')?.label,
          recipient: FlareInput(
            placeholder: widget.view.inputs
                .where((i) => i.id == 'designatedUserId')
                .firstOrNull
                ?.label,
            maxLength: 128,
            disabled: widget.busy || unknown,
            onChanged: (value) => _recipient = value,
          ),
          onKindChange: (v) => setState(() => _kind = v),
          onAmountChange: (v) => setState(() => _amount = v),
          onCountChange: (v) => setState(() => _count = v),
          onGreetingChange: (v) => setState(() => _greeting = v),
          onSubmit: () {
            final a = bound('submit');
            if (a != null && !unknown && !widget.busy)
              widget.onAction?.call(
                a.id,
                FlarePluginActionPayload(
                  formValues: {
                    'designatedUserId': _kind == FlareRedPacketKind.exclusive
                        ? _recipient
                        : '',
                    'kind': _kind.name,
                    'decimalAmount': _amount,
                    'shareCount': _kind == FlareRedPacketKind.exclusive
                        ? 1
                        : _count,
                    'greeting': _greeting,
                  },
                ),
              );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    if (renderer == 'redPacket.card') {
      final card = FlareRedPacketCard(
        blessing: _text(p['blessing']),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          card,
          if (widget.view.unavailableReason ==
              FlarePluginUnavailableReason.unboundCopy)
            FlarePluginView(view: remainder, embedded: true),
        ],
      );
    }
    final children = <Widget>[];
    if (renderer == 'redPacket.composer') children.add(composer(strings));
    if (renderer == 'redPacket.detail') {
      final details = FlareRedPacketDetailsView.fromJson(_map(p['details'])),
          sender = person(_text(p['senderId']));
      final claims = [
        for (final raw in (p['claims'] is List ? p['claims'] as List : []))
          if (_map(raw) case final c)
            FlareRedPacketClaim(
              id: _text(c['id']),
              name: person(_text(c['id'])).name,
              avatar: person(_text(c['id'])).avatarUrl,
              amountMinor: _text(c['amountMinor']),
              claimedAtMs: c['claimedAtMs'] is int
                  ? c['claimedAtMs'] as int
                  : 0,
              best: c['best'] == true,
            ),
      ];
      children.add(
        FlareRedPacketDetail(
          senderName: sender.name,
          senderAvatar: sender.avatarUrl,
          details: details,
          claims: claims,
        ),
      );
      final open = bound('open');
      if (open != null)
        children.add(
          FlareButton(
            label: open.label,
            disabled: widget.busy || unknown,
            onPressed: () => envelope(details),
          ),
        );
    }
    if (['redPacket.pay', 'payment.confirm'].contains(renderer) &&
        bound('confirm') != null &&
        !paymentBlocked)
      children.add(
        FlareRedPacketPayConfirm(
          confirmLabel: bound('confirm')?.label,
          amount: _text(p['amount']),
          methodLabel: _text(p['methodLabel']),
          busy: widget.busy,
          onConfirm: () => request('confirm'),
        ),
      );
    children.add(
      FlarePluginView(
        view: remainder,
        embedded: true,
        busy: widget.busy,
        error: widget.error,
        formErrors: widget.formErrors,
        settleToken: widget.settleToken,
        members: widget.members,
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
