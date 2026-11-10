import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plugin_view.dart';
import '../models/contact_picker.dart';
import '../models/directory_data.dart';
import '../models/red_packet.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_plugin_view.dart';
import 'flare_contact_picker.dart';
import 'flare_bottom_sheet.dart';
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
  FlarePluginMember? _recipient;
  bool _recipientRequired = false;
  final _memberRevision = ValueNotifier(0);
  ModalRoute<Object?>? _recipientRoute;
  NavigatorState? _recipientNavigator;
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
    _memberRevision.dispose();
    super.dispose();
  }

  void _disposePaymentDraft() {
    _paymentPassword.dispose();
    _paymentRevision.dispose();
    _paymentBusy.dispose();
  }

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
  bool get paymentBlocked =>
      unknown || ((widget.error?.isNotEmpty ?? false) && passwordInput == null);
  bool get _paymentEligible =>
      ['redPacket.pay', 'payment.confirm'].contains(renderer) &&
      bound('confirm') != null &&
      !paymentBlocked;
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
    _schedulePayment();
  }

  @override
  void didUpdateWidget(covariant FlareResolvedPresentation old) {
    super.didUpdateWidget(old);
    _resolve();
    if (old.membersRevision != widget.membersRevision) {
      _recipient = null;
      _recipientRequired = true;
      final route = _recipientRoute, navigator = _recipientNavigator;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator?.mounted == true && route?.isActive == true)
          navigator!.removeRoute(route!);
      });
    }
    if (old.view.presentation?['props'] is Map &&
        _map(old.view.presentation?['props'])['conversationType'] !=
            p['conversationType']) {
      _kind = FlareRedPacketKind.normal;
      _recipient = null;
      _recipientRequired = false;
    }
    if (widget.onMemberSearch == null &&
        _recipient != null &&
        !widget.members.any((m) => m.userId == _recipient!.userId)) {
      _recipient = null;
    }
    final entered = old.view.presentation?['renderer'] != renderer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (old.view != widget.view) _paymentPassword.clear();
      _paymentBusy.value = widget.busy;
      _paymentRevision.value++;
      _memberRevision.value++;
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

  List<FlareRedPacketKind> get _composerKinds =>
      switch (_text(p['conversationType'])) {
        'single' => const [FlareRedPacketKind.normal],
        'group' => const [
          FlareRedPacketKind.normal,
          FlareRedPacketKind.lucky,
          FlareRedPacketKind.exclusive,
        ],
        _ => const [],
      };
  FlareRedPacketKind get _composerKind => _composerKinds.contains(_kind)
      ? _kind
      : (_composerKinds.firstOrNull ?? FlareRedPacketKind.normal);
  FlarePluginInput? get _recipientInput => widget.view.inputs
      .where(
        (input) =>
            input.id == 'designatedUserIds' &&
            input.kind == FlarePluginInputKind.members,
      )
      .firstOrNull;

  Future<void> _pickRecipient() async {
    if (widget.busy ||
        unknown ||
        _composerKind != FlareRedPacketKind.exclusive ||
        _recipientInput == null)
      return;
    final revision = widget.membersRevision;
    widget.onMemberSearch?.call('');
    final selected = await FlareBottomSheet.show<List<FlareContactPickerEntry>>(
      context,
      title: _recipientInput!.label,
      fill: true,
      listenable: _memberRevision,
      builder: (sheet) {
        _recipientRoute = ModalRoute.of(sheet);
        _recipientNavigator = Navigator.of(sheet);
        return FlareContactPicker(
          title: _recipientInput!.label,
          groups: [
            FlareContactPickerGroup(
              id: flareContactPickerGroupMembers,
              entries: [
                for (final m in widget.members)
                  FlareContactPickerEntry(
                    userId: m.userId,
                    name: m.name,
                    avatarUrl: m.avatarUrl,
                  ),
              ],
            ),
          ],
          multiple: false,
          loading: widget.membersLoading,
          error: widget.membersError,
          onSearch: widget.onMemberSearch,
          onRetry: widget.onMembersRetry,
          onSelect: (entries) {
            if (!mounted ||
                revision != widget.membersRevision ||
                widget.busy ||
                unknown ||
                _composerKind != FlareRedPacketKind.exclusive ||
                widget.membersLoading ||
                (widget.membersError?.isNotEmpty ?? false))
              return;
            Navigator.of(sheet).pop(entries);
          },
          onCancel: () => Navigator.of(sheet).pop(),
        );
      },
    );
    _recipientRoute = null;
    _recipientNavigator = null;
    if (!mounted ||
        revision != widget.membersRevision ||
        selected == null ||
        selected.length != 1 ||
        _composerKind != FlareRedPacketKind.exclusive ||
        widget.membersLoading ||
        (widget.membersError?.isNotEmpty ?? false))
      return;
    final member = widget.members
        .where((m) => m.userId == selected.single.userId)
        .firstOrNull;
    if (member != null)
      setState(() {
        _recipient = member;
        _recipientRequired = false;
      });
  }

  Widget _recipientField(FlareStrings strings) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (_recipient != null)
        Text(
          _recipient!.name,
          key: const ValueKey('flare-red-packet-recipient-name'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      Wrap(
        spacing: FlareSizes.spacingXs,
        children: [
          FlareButton(
            key: const ValueKey('flare-red-packet-recipient-choose'),
            label: strings.select,
            variant: FlareButtonVariant.secondary,
            size: FlareControlSize.sm,
            disabled: widget.busy || unknown || _recipientInput == null,
            onPressed: _pickRecipient,
          ),
          if (_recipient != null)
            FlareButton(
              key: const ValueKey('flare-red-packet-recipient-clear'),
              label: strings.clear,
              variant: FlareButtonVariant.text,
              size: FlareControlSize.sm,
              disabled: widget.busy || unknown,
              onPressed: () => setState(() {
                _recipient = null;
                _recipientRequired = true;
              }),
            ),
        ],
      ),
      if (_recipientRequired && _recipient == null)
        Text(
          strings.pluginFormRequired,
          key: const ValueKey('flare-red-packet-recipient-required'),
          style: TextStyle(color: FlareColors.of(context).error),
        ),
    ],
  );

  Widget composer(FlareStrings strings) {
    final kind = _composerKind;
    final asset = _map(p['funding']);
    final exponent = asset['currencyExponent'] is int
        ? asset['currencyExponent'] as int
        : 2;
    final minor = flareRedPacketAmountMinor(_amount, exponent);
    final total = minor != null && minor.length <= 64
        ? flareRedPacketMinorText(
            (BigInt.parse(minor) *
                    BigInt.from(
                      kind == FlareRedPacketKind.normal &&
                              _text(p['conversationType']) == 'group'
                          ? _count
                          : 1,
                    ))
                .toString(),
            exponent,
          )
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlareRedPacketComposer(
          kinds: _composerKinds,
          kind: kind,
          amount: _amount,
          currencyExponent: exponent,
          count: _count,
          greeting: _greeting,
          total: '${_text(asset['currency'])} ${total ?? ''}',
          busy: widget.busy,
          locked: unknown || _composerKinds.isEmpty || bound('submit') == null,
          error: widget.formErrors.isEmpty ? null : strings.pluginFormInvalid,
          submitLabel: bound('submit')?.label,
          recipient: _recipientField(strings),
          onKindChange: (v) {
            if (_composerKinds.contains(v))
              setState(() {
                _kind = v;
                _recipientRequired = false;
              });
          },
          onAmountChange: (v) => setState(() => _amount = v),
          onCountChange: (v) => setState(() => _count = v),
          onGreetingChange: (v) => setState(() => _greeting = v),
          onSubmit: () {
            final a = bound('submit');
            if (a == null || unknown || widget.busy || _composerKinds.isEmpty)
              return;
            if (kind == FlareRedPacketKind.exclusive &&
                (_recipient == null || _recipientInput == null)) {
              setState(() => _recipientRequired = true);
              return;
            }
            widget.onAction?.call(
              a.id,
              FlarePluginActionPayload(
                formValues: {
                  'designatedUserIds': kind == FlareRedPacketKind.exclusive
                      ? [_recipient!.userId]
                      : <String>[],
                  'kind': kind.name,
                  'decimalAmount': _amount,
                  'shareCount':
                      kind == FlareRedPacketKind.exclusive ||
                          _text(p['conversationType']) == 'single'
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
