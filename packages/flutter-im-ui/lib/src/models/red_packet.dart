import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_strings.dart';
import 'plugin_view.dart' show flarePluginRenderPattern;

/// Red packet v5 presentation (docs/design/red-packet-v5-roles-and-wallet.md,
/// facts in `spec/red-packet-vectors.json`). The card never shows an amount;
/// what each viewer may see is decided by the plugin's server, and the kit
/// draws only what arrived.

/// What a red packet card shows (spec RedPacketCardState, vectors →
/// cardState): [unopened] the saturated envelope the viewer can open;
/// [viewable] an open packet the viewer looks at but does not open here (the
/// sender's, or one that is meant for someone else); [claimed], [finished],
/// [expired] and [refunded] the same envelope, faded.
enum FlareRedPacketCardState {
  unopened,
  viewable,
  claimed,
  finished,
  expired,
  refunded,
}

/// The plugin's packet status (public layer).
enum FlareRedPacketStatus { open, completed, expired, refunded }

/// Where a card tap goes, from the viewer's personal layer: the open sheet,
/// the details, or the not-eligible notice.
enum FlareRedPacketTapAction { open, details, notEligible }

/// Who is looking at the details, as the server decided.
enum FlareRedPacketViewerRole { sender, claimer, eligible, ineligible }

/// Phase of `FlareRedPacketOpenSheet` (spec RedPacketOpenSheet `state`).
/// [opening] flips the 開 coin while the host claims; [finished], [expired],
/// [refunded] and [notEligible] say why nothing opens; [error] offers 開
/// again. A host maps a claim refused with PACKET_REFUNDED, or a public layer
/// whose status is refunded, to [refunded].
enum FlareRedPacketOpenState {
  ready,
  opening,
  finished,
  expired,
  refunded,
  notEligible,
  error,
}

/// Packet kinds a host can offer in `FlareRedPacketComposer`; a 1:1
/// conversation only has [normal]. On a card, [lucky] and [exclusive] draw a
/// badge and [normal] none.
enum FlareRedPacketKind { lucky, normal, exclusive }

T? _enumOf<T extends Enum>(List<T> values, Object? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

/// The card state from the public layer's [status] and the personal layer's
/// [claimedByMe] and [tapAction] (vectors → cardState): a share the viewer
/// claimed wins; then a spent status; an open packet is [unopened] unless the
/// tap goes to the details or the not-eligible notice.
FlareRedPacketCardState flareRedPacketCardState({
  required FlareRedPacketStatus status,
  bool claimedByMe = false,
  FlareRedPacketTapAction? tapAction,
}) {
  if (claimedByMe) return FlareRedPacketCardState.claimed;
  return switch (status) {
    FlareRedPacketStatus.completed => FlareRedPacketCardState.finished,
    FlareRedPacketStatus.expired => FlareRedPacketCardState.expired,
    FlareRedPacketStatus.refunded => FlareRedPacketCardState.refunded,
    FlareRedPacketStatus.open =>
      tapAction == FlareRedPacketTapAction.details ||
              tapAction == FlareRedPacketTapAction.notEligible
          ? FlareRedPacketCardState.viewable
          : FlareRedPacketCardState.unopened,
  };
}

/// The status line of a card (vectors → card): busy, then the host's
/// [statusLabel], then the state's copy — where a [disabled] card that could
/// otherwise be opened or viewed says it is unavailable.
String flareRedPacketCardStatus(
  FlareStrings strings, {
  required FlareRedPacketCardState state,
  bool busy = false,
  bool disabled = false,
  String? statusLabel,
}) {
  if (busy) return strings.packetBusy;
  if (statusLabel != null) return statusLabel;
  return switch (state) {
    FlareRedPacketCardState.unopened ||
    FlareRedPacketCardState.viewable when disabled => strings.packetUnavailable,
    FlareRedPacketCardState.unopened => strings.packetTapToClaim,
    FlareRedPacketCardState.viewable => strings.packetView,
    FlareRedPacketCardState.claimed => strings.packetStateClaimed,
    FlareRedPacketCardState.finished => strings.packetFinished,
    FlareRedPacketCardState.expired => strings.packetStateExpired,
    FlareRedPacketCardState.refunded => strings.packetRefunded,
  };
}

/// Whether a card in [state] is drawn faded (claimed, finished, expired,
/// refunded). Busy and disabled never fade a card on their own.
bool flareRedPacketCardDimmed(FlareRedPacketCardState state) =>
    state != FlareRedPacketCardState.unopened &&
    state != FlareRedPacketCardState.viewable;

/// The kind badge of a card and the exclusive recipient line (vectors →
/// cardBadge): lucky and exclusive have a badge, normal none; "给 {name}"
/// only on an exclusive packet with a name.
({String? badge, String? recipient}) flareRedPacketCardBadge(
  FlareStrings strings, {
  required FlareRedPacketKind kind,
  String? recipientName,
}) {
  final name = recipientName?.trim() ?? '';
  return switch (kind) {
    FlareRedPacketKind.lucky => (badge: strings.packetBadgeLucky, recipient: null),
    FlareRedPacketKind.normal => (badge: null, recipient: null),
    FlareRedPacketKind.exclusive => (
      badge: strings.packetBadgeExclusive,
      recipient: name.isEmpty
          ? null
          : strings.packetForRecipient.replaceAll('{name}', name),
    ),
  };
}

/// Which keys the open sheet offers (vectors → openSheet, openSheetRefunded):
/// 開 while ready, opening or failed; the details key only for a finished,
/// expired or refunded packet the personal layer lets the viewer see
/// ([canViewDetails]); never for [FlareRedPacketOpenState.notEligible].
({bool coin, bool details}) flareRedPacketOpenSheetKeys(
  FlareRedPacketOpenState state, {
  bool canViewDetails = true,
}) => switch (state) {
  FlareRedPacketOpenState.ready ||
  FlareRedPacketOpenState.opening ||
  FlareRedPacketOpenState.error => (coin: true, details: false),
  FlareRedPacketOpenState.finished ||
  FlareRedPacketOpenState.expired ||
  FlareRedPacketOpenState.refunded => (coin: false, details: canViewDetails),
  FlareRedPacketOpenState.notEligible => (coin: false, details: false),
};

// ── amounts (vectors → amount) ─────────────────────────────────────────────

/// Currency symbols the kit writes before an amount; any other code is
/// written as "{CODE} {amount}".
const Map<String, String> flareRedPacketCurrencySymbols = {
  'CNY': '¥',
  'JPY': '¥',
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'HKD': r'HK$',
};

final RegExp _asciiDigits = RegExp(r'^[0-9]+$');

/// A minor-unit amount (a string of ASCII digits) as a decimal with exactly
/// [exponent] fraction digits (ISO 4217, the contract's currencyExponent),
/// leading zeros folded, no grouping, by integer string arithmetic — never
/// floating point. Null for anything that is not digits.
String? flareRedPacketMinorText(String? minor, int exponent) {
  final raw = minor ?? '';
  if (!_asciiDigits.hasMatch(raw) || exponent < 0 || exponent > 12) return null;
  var digits = raw.replaceFirst(RegExp(r'^0+'), '');
  if (digits.length <= exponent) {
    digits = digits.padLeft(exponent + 1, '0');
  }
  final whole = digits.substring(0, digits.length - exponent);
  final fraction = digits.substring(digits.length - exponent);
  return exponent == 0 ? whole : '$whole.$fraction';
}

/// [flareRedPacketMinorText] with its currency: the symbol for a code in
/// [flareRedPacketCurrencySymbols], else "{CODE} {text}".
String? flareRedPacketMoney(String? minor, int exponent, String currency) {
  final text = flareRedPacketMinorText(minor, exponent);
  if (text == null) return null;
  final symbol = flareRedPacketCurrencySymbols[currency.toUpperCase()];
  return symbol == null ? '$currency $text' : '$symbol$text';
}

// ── details (vectors → detail) ─────────────────────────────────────────────

/// The plugin's details result for one viewer (spec RedPacketDetailsView):
/// amounts the viewer may not see are absent — the server never sends them.
@immutable
class FlareRedPacketDetailsView {
  const FlareRedPacketDetailsView({
    required this.viewerRole,
    required this.status,
    this.kind = FlareRedPacketKind.normal,
    required this.greeting,
    required this.currency,
    required this.currencyExponent,
    this.totalMinor,
    this.claimedMinor,
    this.refundedMinor,
    this.myAmountMinor,
    this.claimedCount = 0,
    required this.shareCount,
    required this.createdAtMs,
    this.completedAtMs,
    required this.expiresAtMs,
    this.refundedAtMs,
    this.claimsListed = false,
  });

  /// The details JSON as the plugin returns it (camelCase).
  factory FlareRedPacketDetailsView.fromJson(Map<String, Object?> json) {
    String? minor(Object? v) => v is String ? v : (v is int ? '$v' : null);
    int? ms(Object? v) => v is num ? v.toInt() : null;
    return FlareRedPacketDetailsView(
      viewerRole:
          _enumOf(FlareRedPacketViewerRole.values, json['viewerRole']) ??
          FlareRedPacketViewerRole.ineligible,
      status:
          _enumOf(FlareRedPacketStatus.values, json['status']) ??
          FlareRedPacketStatus.open,
      kind:
          _enumOf(FlareRedPacketKind.values, json['kind']) ??
          FlareRedPacketKind.normal,
      greeting: json['greeting'] is String ? json['greeting'] as String : '',
      currency: json['currency'] is String ? json['currency'] as String : '',
      currencyExponent: ms(json['currencyExponent']) ?? 2,
      totalMinor: minor(json['totalMinor']),
      claimedMinor: minor(json['claimedMinor']),
      refundedMinor: minor(json['refundedMinor']),
      myAmountMinor: minor(json['myAmountMinor']),
      claimedCount: ms(json['claimedCount']) ?? 0,
      shareCount: ms(json['shareCount']) ?? 0,
      createdAtMs: ms(json['createdAtMs']) ?? 0,
      completedAtMs: ms(json['completedAtMs']),
      expiresAtMs: ms(json['expiresAtMs']) ?? 0,
      refundedAtMs: ms(json['refundedAtMs']),
      claimsListed: json['claimsListed'] == true,
    );
  }

  final FlareRedPacketViewerRole viewerRole;
  final FlareRedPacketStatus status;
  final FlareRedPacketKind kind;
  final String greeting;

  /// ISO 4217 code.
  final String currency;

  /// Fraction digits of [currency].
  final int currencyExponent;

  /// Sender only.
  final String? totalMinor;
  final String? claimedMinor;
  final String? refundedMinor;

  /// What the viewer received.
  final String? myAmountMinor;
  final int claimedCount;
  final int shareCount;
  final int createdAtMs;
  final int? completedAtMs;
  final int expiresAtMs;
  final int? refundedAtMs;

  /// The viewer may see the claim list.
  final bool claimsListed;
}

/// One row of `FlareRedPacketDetail`'s claim list: the host resolves the name
/// and avatar from its directory; the kit formats the amount (in the details'
/// currency) and the time. [best] is the server's best-luck mark.
@immutable
class FlareRedPacketClaim {
  const FlareRedPacketClaim({
    required this.id,
    required this.name,
    this.avatar,
    required this.amountMinor,
    required this.claimedAtMs,
    this.best = false,
  });

  final String id;
  final String name;
  final String? avatar;
  final String amountMinor;
  final int claimedAtMs;
  final bool best;
}

/// What `FlareRedPacketDetail` draws for one viewer (vectors → detail).
@immutable
class FlareRedPacketDetailPresentation {
  const FlareRedPacketDetailPresentation({
    this.amount,
    this.headline,
    this.summary,
    this.claims = false,
    this.note,
  });

  /// The viewer's own amount, drawn large; null when the server sent none.
  final String? amount;

  /// "已存入钱包" under [amount].
  bool get deposited => amount != null;

  /// Why the viewer cannot open it (too late, expired, not designated).
  final String? headline;
  final String? summary;

  /// Whether the claim list shows.
  final bool claims;

  /// The sender's refund line.
  final String? note;
}

DateTime _wallAt(int ms, int? utcOffsetMinutes) => utcOffsetMinutes == null
    ? DateTime.fromMillisecondsSinceEpoch(ms)
    : DateTime.fromMillisecondsSinceEpoch(
        ms + utcOffsetMinutes * 60000,
        isUtc: true,
      );

String _two(int n) => n.toString().padLeft(2, '0');

/// A red packet time (vectors → detail rules.time): HH:mm on the viewer's day
/// of [nowMs], else the plugin view's date-time pattern, with the year
/// outside the current one.
String flareRedPacketTime(
  int atMs,
  int nowMs,
  FlareStrings strings, {
  int? utcOffsetMinutes,
}) {
  final at = _wallAt(atMs, utcOffsetMinutes);
  final now = _wallAt(nowMs, utcOffsetMinutes);
  if (at.year == now.year && at.month == now.month && at.day == now.day) {
    return '${_two(at.hour)}:${_two(at.minute)}';
  }
  return flarePluginRenderPattern(
    at.year == now.year
        ? strings.pluginViewDateTimeFormat
        : strings.pluginViewDateTimeYearFormat,
    at,
  );
}

/// How long the packet took to run out (rules.duration): seconds, whole
/// minutes, whole hours, then whole days.
String flareRedPacketDuration(int ms, FlareStrings strings) {
  final seconds = ms ~/ 1000;
  String n(String template, int value) =>
      template.replaceAll('{n}', '$value');
  if (seconds < 60) return n(strings.packetDurationSeconds, seconds);
  if (seconds < 3600) return n(strings.packetDurationMinutes, seconds ~/ 60);
  if (seconds < 86400) return n(strings.packetDurationHours, seconds ~/ 3600);
  return n(strings.packetDurationDays, seconds ~/ 86400);
}

String _fill(String template, Map<String, String> values) {
  var out = template;
  values.forEach((key, value) => out = out.replaceAll('{$key}', value));
  return out;
}

/// What the details page draws for [details] (vectors → detail rules): the
/// viewer's own amount when the server returned it; a headline for the
/// eligible who came too late and for a viewer the packet is not meant for;
/// the summary line (totals only when the server returned them, i.e. to the
/// sender); the claim list exactly when [FlareRedPacketDetailsView.claimsListed];
/// the sender's refund note.
FlareRedPacketDetailPresentation flareRedPacketDetailPresentation(
  FlareRedPacketDetailsView details, {
  required FlareStrings strings,
  required int nowMs,
  String? designatedName,
  int? utcOffsetMinutes,
}) {
  String? money(String? minor) => (minor ?? '').isEmpty
      ? null
      : flareRedPacketMoney(minor, details.currencyExponent, details.currency);
  String time(int ms) =>
      flareRedPacketTime(ms, nowMs, strings, utcOffsetMinutes: utcOffsetMinutes);
  final role = details.viewerRole;
  final status = details.status;
  final spent =
      status == FlareRedPacketStatus.expired ||
      status == FlareRedPacketStatus.refunded;
  final name = designatedName?.trim() ?? '';

  final String? headline = switch (role) {
    FlareRedPacketViewerRole.ineligible =>
      name.isEmpty
          ? strings.packetNotEligible
          : strings.packetNotEligibleName.replaceAll('{name}', name),
    FlareRedPacketViewerRole.eligible
        when status == FlareRedPacketStatus.completed =>
      strings.packetMissed,
    FlareRedPacketViewerRole.eligible when spent => strings.packetExpiredNotice,
    _ => null,
  };

  String? summary;
  final shares = '${details.shareCount}';
  final claimed = '${details.claimedCount}';
  if (role == FlareRedPacketViewerRole.ineligible ||
      (role == FlareRedPacketViewerRole.eligible && spent)) {
    summary = null;
  } else if (status == FlareRedPacketStatus.completed &&
      money(details.totalMinor) != null &&
      details.completedAtMs != null) {
    summary = _fill(strings.packetSummaryCompleted, {
      'shares': shares,
      'totalMoney': money(details.totalMinor)!,
      'duration': flareRedPacketDuration(
        details.completedAtMs! - details.createdAtMs,
        strings,
      ),
    });
  } else if (money(details.totalMinor) != null &&
      money(details.claimedMinor) != null) {
    summary = _fill(strings.packetSummarySender, {
      'claimed': claimed,
      'shares': shares,
      'claimedMoney': money(details.claimedMinor)!,
      'totalMoney': money(details.totalMinor)!,
    });
  } else {
    summary = _fill(strings.packetSummaryCount, {
      'claimed': claimed,
      'shares': shares,
    });
  }

  String? note;
  if (role == FlareRedPacketViewerRole.sender) {
    if (status == FlareRedPacketStatus.open && details.expiresAtMs > 0) {
      note = strings.packetRefundAt.replaceAll(
        '{time}',
        time(details.expiresAtMs),
      );
    } else if (spent) {
      final refunded = money(details.refundedMinor);
      final positive = (details.refundedMinor ?? '').replaceAll('0', '');
      if (refunded != null && positive.isNotEmpty) {
        final at = details.refundedAtMs;
        note = at == null
            ? strings.packetRefundedNote
                  .replaceAll(' · {time}', '')
                  .replaceAll('{money}', refunded)
            : _fill(strings.packetRefundedNote, {
                'money': refunded,
                'time': time(at),
              });
      }
    }
  }

  return FlareRedPacketDetailPresentation(
    amount: money(details.myAmountMinor),
    headline: headline,
    summary: summary,
    claims: details.claimsListed,
    note: note,
  );
}

const int _fullWidthZero = 0xFF10;
const Set<String> _decimalPoints = {'.', '．', '。'};

String? _asciiDigit(String ch) {
  final code = ch.codeUnitAt(0);
  if (code >= 0x30 && code <= 0x39) return ch;
  if (code >= _fullWidthZero && code <= _fullWidthZero + 9) {
    return String.fromCharCode(0x30 + code - _fullWidthZero);
  }
  return null;
}

/// The amount field's currency exponent: [exponent] rounded and held to
/// 0..12, matching dynamic wallet units.
int flareRedPacketExponent(num exponent) => exponent.round().clamp(0, 12);

/// Format-only filter for the composer's amount field: digits and one decimal
/// point with at most [exponent] decimals (the currency's ISO 4217 exponent,
/// default 2), leading zeros folded (`spec/red-packet-vectors.json` →
/// amountInput, amountInputExponent). With exponent 0 every decimal point is
/// dropped and only whole numbers go in. Full-width digits and 「．」「。」
/// count; a second point is dropped; a trailing point stays. Range checks are
/// the host's.
String flareRedPacketAmount(String raw, [int exponent = 2]) {
  final places = flareRedPacketExponent(exponent);
  final out = StringBuffer();
  var point = false;
  var decimals = 0;
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    final digit = _asciiDigit(ch);
    if (digit != null) {
      if (point) {
        if (decimals >= places) continue;
        decimals += 1;
      }
      out.write(digit);
    } else if (_decimalPoints.contains(ch) && !point && places > 0) {
      point = true;
      out.write(out.isEmpty ? '0.' : '.');
    }
  }
  return out.toString().replaceFirst(RegExp(r'^0+(?=\d)'), '');
}

/// The composer's amount text as a minor-unit integer string for
/// [exponent] decimals, by integer string arithmetic — never floating point
/// ("8.8", 2 → "880"; "8.", 2 → "800"; "12", 0 → "12"). Leading zeros fold;
/// all zeros is "0". Null while the text is not an amount yet: empty, a point
/// alone, more decimals than [exponent], anything but ASCII digits and one
/// point (`spec/red-packet-vectors.json` → amountMinor).
String? flareRedPacketAmountMinor(String input, int exponent) {
  final places = flareRedPacketExponent(exponent);
  final parts = input.split('.');
  if (parts.length > 2) return null;
  final whole = parts[0];
  final fraction = parts.length == 2 ? parts[1] : '';
  if (whole.isEmpty && fraction.isEmpty) return null;
  final digitsOnly = RegExp(r'^[0-9]*$');
  if (!digitsOnly.hasMatch(whole) || !digitsOnly.hasMatch(fraction)) {
    return null;
  }
  if (fraction.length > places) return null;
  final minor = '$whole${fraction.padRight(places, '0')}'.replaceFirst(
    RegExp(r'^0+'),
    '',
  );
  return minor.isEmpty ? '0' : minor;
}

/// The amount field's placeholder: zero written with [exponent] decimals
/// ("0", "0.00", "0.000").
String flareRedPacketAmountPlaceholder(int exponent) =>
    flareRedPacketMinorText('0', flareRedPacketExponent(exponent))!;

/// Digits only, at most three, as a number; empty is 0
/// (`spec/red-packet-vectors.json` → countInput).
int flareRedPacketCount(String raw) {
  final digits = StringBuffer();
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    final digit = _asciiDigit(ch);
    if (digit == null ||
        digits.length >= 3 ||
        (digit == '0' && digits.isEmpty)) {
      continue;
    }
    digits.write(digit);
  }
  return digits.isEmpty ? 0 : int.parse(digits.toString());
}

/// [flareRedPacketAmount] as a field formatter. The caret goes to the end of
/// the filtered text: it is a short numeric field, and a filtered edit has no
/// stable position to keep.
class FlareRedPacketAmountFormatter extends TextInputFormatter {
  const FlareRedPacketAmountFormatter({this.exponent = 2});

  /// The currency's exponent: how many decimals the field keeps.
  final int exponent;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _filtered(newValue, flareRedPacketAmount(newValue.text, exponent));
}

/// [flareRedPacketCount] as a field formatter; zero shows as an empty field.
class FlareRedPacketCountFormatter extends TextInputFormatter {
  const FlareRedPacketCountFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final count = flareRedPacketCount(newValue.text);
    return _filtered(newValue, count > 0 ? '$count' : '');
  }
}

TextEditingValue _filtered(TextEditingValue value, String text) {
  if (text == value.text) return value;
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}
