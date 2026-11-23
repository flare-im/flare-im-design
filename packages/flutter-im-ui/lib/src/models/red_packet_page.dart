import 'package:flutter/foundation.dart';

import 'plugin_view.dart';
import 'red_packet.dart';

/// The red packet product pages (docs/plugin-experience.md §4, §11): a plugin
/// page whose resolved presentation is `redPacket.compose`,
/// `redPacket.review` or `redPacket.detail` draws the kit's red packet components
/// ([FlareRedPacketPage]) instead of the generic document. These pure
/// mappings read the resolved view only — renderer, props, bound actions and
/// inputs — never a plugin id; null means "draw the generic document".

Map<String, Object?> _map(Object? v) => v is Map
    ? {
        for (final e in v.entries)
          if (e.key is String) e.key as String: e.value,
      }
    : const {};

FlarePluginAction? _bound(FlarePluginViewModel view, String name) {
  final id = _map(view.presentation?['actions'])[name];
  return id is String
      ? view.actions.where((a) => a.id == id).firstOrNull
      : null;
}

/// An action the red packet page may run itself: no confirm, no native
/// target, no password to collect. Anything else stays with the generic view.
bool _ownable(FlarePluginViewModel view, FlarePluginAction action) =>
    action.confirm == null &&
    action.target?.kind != 'native' &&
    !action.form.any(
      (id) => view.inputs.any(
        (i) => i.id == id && i.kind == FlarePluginInputKind.password,
      ),
    );

const _composeKinds = {
  FlarePluginInputKind.money,
  FlarePluginInputKind.text,
  FlarePluginInputKind.select,
  FlarePluginInputKind.number,
  FlarePluginInputKind.members,
};

FlareRedPacketKind? _kindOf(Object? name) {
  for (final kind in FlareRedPacketKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

/// What the `redPacket.compose` page sends: the bound submit action, its form
/// inputs in form order, the money input and the kinds on offer.
@immutable
class FlareRedPacketComposePlan {
  const FlareRedPacketComposePlan({
    required this.action,
    required this.inputs,
    required this.money,
    required this.kinds,
    this.maxRecipients,
  });

  final FlarePluginAction action;
  final List<FlarePluginInput> inputs;

  /// The `amount` input (kind money, with a currency).
  final FlarePluginInput money;

  /// From the `kind` input's choices, or only normal without one (1:1).
  final List<FlareRedPacketKind> kinds;

  /// The deployment's share cap (`props.maxRecipients`), when positive.
  final int? maxRecipients;

  int get scale => money.money?.scale ?? 2;
  String get currency => money.money?.currency ?? '';

  /// The default greeting the plugin declared.
  String get greetingDefault {
    final value = inputs
        .where((i) => i.id == 'greeting')
        .firstOrNull
        ?.defaultValue;
    return value is String ? value : '';
  }
}

/// The compose page's plan, or null for the generic document: renderer
/// `redPacket.compose`, an available bound view with no unconfirmed original
/// command, a bound submit (`submit`, else `submitDirect`) the page may run,
/// whose form resolves to an `amount` money input with a currency, a
/// `greeting` text input and only money, text, select, number and members
/// inputs; every offered kind known.
FlareRedPacketComposePlan? flareRedPacketComposePlan(
  FlarePluginViewModel view,
) {
  final presentation = view.presentation;
  if (presentation?['renderer'] != 'redPacket.compose' ||
      !view.available ||
      view.unavailableReason == FlarePluginUnavailableReason.unboundCopy) {
    return null;
  }
  final props = _map(presentation!['props']);
  final journal = _map(props['journal']);
  // The original command's outcome is unknown: recover it on the generic page.
  if (journal['commandId'] is String && journal['known'] == false) return null;
  final action = _bound(view, 'submit') ?? _bound(view, 'submitDirect');
  if (action == null || !_ownable(view, action) || action.form.isEmpty) {
    return null;
  }
  final inputs = <FlarePluginInput>[];
  for (final id in action.form) {
    final input = view.inputs.where((i) => i.id == id).firstOrNull;
    if (input == null) return null;
    inputs.add(input);
  }
  final money = inputs
      .where((i) => i.id == 'amount' && i.kind == FlarePluginInputKind.money)
      .firstOrNull;
  if (money == null ||
      (money.money?.currency ?? '').isEmpty ||
      !inputs.any(
        (i) => i.id == 'greeting' && i.kind == FlarePluginInputKind.text,
      ) ||
      inputs.any((i) => !_composeKinds.contains(i.kind))) {
    return null;
  }
  final kindInput = inputs.where((i) => i.id == 'kind').firstOrNull;
  final kinds = kindInput == null
      ? const [FlareRedPacketKind.normal]
      : [
          for (final choice in kindInput.choices)
            if (_kindOf(choice.value) case final kind?) kind,
        ];
  if (kinds.isEmpty ||
      (kindInput != null && kinds.length != kindInput.choices.length)) {
    return null;
  }
  final cap = props['maxRecipients'];
  return FlareRedPacketComposePlan(
    action: action,
    inputs: inputs,
    money: money,
    kinds: kinds,
    maxRecipients: cap is int && cap > 0 ? cap : null,
  );
}

/// One claim row as the server listed it; the page names it.
typedef FlareRedPacketClaimRow = ({
  String id,
  String amountMinor,
  int claimedAtMs,
  bool best,
});

/// What the `redPacket.detail` page shows and runs.
@immutable
class FlareRedPacketDetailPlan {
  const FlareRedPacketDetailPlan({
    required this.details,
    this.claims = const [],
    this.senderId = '',
    this.designatedUserIds = const [],
    this.claimAction,
    this.walletAction,
    this.paidClaimPending = false,
  });

  final FlareRedPacketDetailsView details;
  final List<FlareRedPacketClaimRow> claims;
  final String senderId;
  final List<String> designatedUserIds;

  /// The bound `claim`: the open sheet's 開.
  final FlarePluginAction? claimAction;

  /// The bound `wallet`: 「已存入钱包 ›」.
  final FlarePluginAction? walletAction;

  /// The viewer's claim is paid while its original command is unconfirmed.
  final bool paidClaimPending;

  /// The actions this page runs itself; the rest stay generic.
  List<String> get ownedActionIds => [?claimAction?.id, ?walletAction?.id];
}

final _digits = RegExp(r'^\d+$');
bool _count(Object? v) => v is int && v >= 0;
bool _minor(Object? v) => v is String && _digits.hasMatch(v);

/// The detail page's plan, or null for the generic document: renderer
/// `redPacket.detail`, an available view whose `props.details` is a complete
/// details result (known role, status and kind; greeting; currency and an
/// exponent 0..12; counts and times as non-negative integers; claimsListed;
/// minor amounts absent or digits).
FlareRedPacketDetailPlan? flareRedPacketDetailPlan(FlarePluginViewModel view) {
  final presentation = view.presentation;
  if (presentation?['renderer'] != 'redPacket.detail' || !view.available) {
    return null;
  }
  final props = _map(presentation!['props']);
  final raw = _map(props['details']);
  final currency = raw['currency'];
  final exponent = raw['currencyExponent'];
  if (!const {
        'sender',
        'claimer',
        'eligible',
        'ineligible',
      }.contains(raw['viewerRole']) ||
      !const {
        'open',
        'completed',
        'expired',
        'refunded',
      }.contains(raw['status']) ||
      _kindOf(raw['kind']) == null ||
      raw['greeting'] is! String ||
      currency is! String ||
      currency.isEmpty ||
      !_count(exponent) ||
      (exponent as int) > 12 ||
      !_count(raw['claimedCount']) ||
      !_count(raw['shareCount']) ||
      !_count(raw['createdAtMs']) ||
      !_count(raw['expiresAtMs']) ||
      raw['claimsListed'] is! bool) {
    return null;
  }
  for (final key in const [
    'totalMinor',
    'claimedMinor',
    'refundedMinor',
    'myAmountMinor',
  ]) {
    if (raw[key] != null && !_minor(raw[key])) return null;
  }
  final completedIn = raw['completedInMs'];
  final details = FlareRedPacketDetailsView.fromJson({
    ...raw,
    if (_count(completedIn))
      'completedAtMs': (raw['createdAtMs'] as int) + (completedIn as int),
  });
  final journal = _map(props['journal']);
  final claim = _bound(view, 'claim');
  final wallet = _bound(view, 'wallet');
  final designated = raw['designatedUserIds'];
  return FlareRedPacketDetailPlan(
    details: details,
    claims: [
      for (final item
          in (props['claims'] is List ? props['claims'] as List : const []))
        if (_map(item) case final row
            when row['id'] is String &&
                _minor(row['amountMinor']) &&
                row['claimedAtMs'] is int)
          (
            id: row['id'] as String,
            amountMinor: row['amountMinor'] as String,
            claimedAtMs: row['claimedAtMs'] as int,
            best: row['best'] == true,
          ),
    ],
    senderId: props['senderId'] is String ? props['senderId'] as String : '',
    designatedUserIds: [
      for (final id in (designated is List ? designated : const []))
        if (id is String) id,
    ],
    claimAction: claim != null && _ownable(view, claim) && claim.form.isEmpty
        ? claim
        : null,
    walletAction:
        wallet != null && _ownable(view, wallet) && wallet.form.isEmpty
        ? wallet
        : null,
    paidClaimPending:
        journal['known'] == false &&
        const {
          'flare.redpacket.ui.claim',
          'flare.redpacket.claim',
        }.contains(journal['capabilityId']) &&
        raw['viewerRole'] == 'claimer' &&
        raw['myAmountMinor'] is String,
  );
}

/// What the `redPacket.review` page (the send confirmation, §4.3) shows and
/// sends: the bound submit and the packet's amount, kind, count and greeting.
@immutable
class FlareRedPacketReviewPlan {
  const FlareRedPacketReviewPlan({
    required this.action,
    required this.amount,
    this.currency,
    this.kind,
    this.shareCount,
    this.blessing,
    this.kindLabel,
  });

  final FlarePluginAction action;

  /// The total as the plugin wrote it (a decimal, or already formatted).
  final String amount;
  final String? currency;
  final FlareRedPacketKind? kind;
  final int? shareCount;
  final String? blessing;

  /// The plugin's own kind line, when it wrote one.
  final String? kindLabel;

  List<String> get ownedActionIds => [action.id];
}

/// The review page's plan, or null for the generic document (which keeps
/// the page's note, status and recovery): renderer `redPacket.review`, an
/// available bound view with no unconfirmed original command and a bound
/// `submit` the page may run in one tap (no form).
FlareRedPacketReviewPlan? flareRedPacketReviewPlan(FlarePluginViewModel view) {
  final presentation = view.presentation;
  if (presentation?['renderer'] != 'redPacket.review' ||
      !view.available ||
      view.unavailableReason == FlarePluginUnavailableReason.unboundCopy) {
    return null;
  }
  final props = _map(presentation!['props']);
  final journal = _map(props['journal']);
  if (journal['commandId'] is String && journal['known'] == false) return null;
  final action = _bound(view, 'submit');
  if (action == null || !_ownable(view, action) || action.form.isNotEmpty) {
    return null;
  }
  String? text(String key) =>
      props[key] is String && (props[key] as String).isNotEmpty
      ? props[key] as String
      : null;
  final shares = props['shareCount'];
  return FlareRedPacketReviewPlan(
    action: action,
    amount: text('amount') ?? '',
    currency: text('currency'),
    kind: _kindOf(props['kind']),
    shareCount: shares is int && shares > 0 ? shares : null,
    blessing: text('blessing'),
    kindLabel: text('kindLabel'),
  );
}

/// Whether `FlarePluginPage` draws [view] as the red packet page.
bool flareRedPacketPageDraws(FlarePluginViewModel view) =>
    flareRedPacketComposePlan(view) != null ||
    flareRedPacketReviewPlan(view) != null ||
    flareRedPacketDetailPlan(view) != null;
