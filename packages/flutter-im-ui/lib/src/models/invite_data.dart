/// Invite contracts — pure logic shared by the four platforms behind the
/// registration form's invite-code field (`FlareInviteCodeField`) and the
/// "my invite" card (`FlareMyInvitePanel`). Vectors: spec/invite-vectors.json.
///
/// The host owns the network: it runs the pre-check, fetches the code, the
/// stats and the invitees, and performs copy / share / regenerate. Nothing here
/// has a side effect. The alphabet is Crockford base32 without I / L / O / U,
/// so what a person types is corrected the way the server reads it (O→0,
/// I/L→1) before it is shown.
library;

/// Tenant invite mode: `off` hides the field, `optional` and `required` show it.
enum FlareInviteCodeMode { off, optional, required }

/// Result of the host's pre-check for one code.
class FlareInviteCodeCheckResult {
  const FlareInviteCodeCheckResult({required this.valid, this.inviterDisplayName});

  final bool valid;

  /// Masked display name of the inviter the code resolves to.
  final String? inviterDisplayName;
}

/// The invite-code field's state vector.
enum FlareInviteCodeFieldState { off, idle, typing, checking, valid, invalid, disabled }

/// Referral counts per depth for the current person.
class FlareReferralStats {
  const FlareReferralStats({
    required this.direct,
    required this.l2,
    required this.l3,
    required this.total,
  });

  final int direct;
  final int l2;
  final int l3;
  final int total;

  int of(FlareReferralDepth depth) => switch (depth) {
    FlareReferralDepth.direct => direct,
    FlareReferralDepth.l2 => l2,
    FlareReferralDepth.l3 => l3,
    FlareReferralDepth.total => total,
  };
}

/// One person invited directly by the current person.
class FlareInvitee {
  const FlareInvitee({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.joinedAt,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  /// Registration time, epoch milliseconds.
  final int joinedAt;
}

const int flareInviteCodeDefaultLength = 6;

/// Delay between the last keystroke and the check request.
const Duration flareInviteCheckDebounce = Duration(milliseconds: 400);

/// What the server would read from what the person typed or pasted: whitespace
/// and separators dropped, uppercased, O→0 and I/L→1, cut to [length].
/// Idempotent, so it can run on every keystroke.
String normalizeInviteCode(String? raw, [int length = flareInviteCodeDefaultLength]) {
  final cap = length > 0 ? length : flareInviteCodeDefaultLength;
  final out = StringBuffer();
  for (final rune in (raw ?? '').toUpperCase().runes) {
    if (out.length >= cap) break;
    final ch = String.fromCharCode(rune);
    if (ch == 'O') {
      out.write('0');
    } else if (ch == 'I' || ch == 'L') {
      out.write('1');
    } else if (RegExp(r'[0-9A-Z]').hasMatch(ch)) {
      out.write(ch);
    }
  }
  return out.toString();
}

/// One state at a time, in priority order: `off` beats everything, `disabled`
/// beats what the host says about the value, a host error beats a check
/// result, an in-flight check beats a stale result, then the result itself,
/// then whether anything has been typed.
FlareInviteCodeFieldState inviteCodeFieldState({
  required FlareInviteCodeMode mode,
  required String value,
  bool checking = false,
  FlareInviteCodeCheckResult? checkResult,
  String? error,
  bool disabled = false,
}) {
  if (mode == FlareInviteCodeMode.off) return FlareInviteCodeFieldState.off;
  if (disabled) return FlareInviteCodeFieldState.disabled;
  if (error != null && error.isNotEmpty) return FlareInviteCodeFieldState.invalid;
  if (checking) return FlareInviteCodeFieldState.checking;
  if (checkResult != null) {
    return checkResult.valid ? FlareInviteCodeFieldState.valid : FlareInviteCodeFieldState.invalid;
  }
  return value.isEmpty ? FlareInviteCodeFieldState.idle : FlareInviteCodeFieldState.typing;
}

/// The code the host should pre-check for [value], or null when no request
/// should be made: a partial code is never sent, a disabled or hidden field
/// never asks.
String? inviteCodeToCheck({
  required String value,
  int length = flareInviteCodeDefaultLength,
  FlareInviteCodeMode mode = FlareInviteCodeMode.optional,
  bool disabled = false,
}) {
  if (mode == FlareInviteCodeMode.off || disabled) return null;
  final code = normalizeInviteCode(value, length);
  return code.length == length ? code : null;
}

enum FlareReferralDepth { direct, l2, l3, total }

/// Which rows the panel lists for [stats], honouring the tenant's visibility
/// depth (1–3, clamped). `total` is always the last row once stats exist.
List<FlareReferralDepth> referralDepthRows(FlareReferralStats? stats, [int maxDepthShown = 3]) {
  if (stats == null) return const [];
  final depth = maxDepthShown.clamp(1, 3);
  return [
    FlareReferralDepth.direct,
    if (depth >= 2) FlareReferralDepth.l2,
    if (depth >= 3) FlareReferralDepth.l3,
    FlareReferralDepth.total,
  ];
}

enum FlareInviteCooldownUnit { minute, hour, day }

class FlareInviteCooldown {
  const FlareInviteCooldown(this.unit, this.count);
  final FlareInviteCooldownUnit unit;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is FlareInviteCooldown && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);

  @override
  String toString() => 'FlareInviteCooldown($unit, $count)';
}

class FlareRegenerateAvailability {
  const FlareRegenerateAvailability({required this.shown, required this.enabled, this.remaining});

  /// The control is drawn at all (the tenant allows regenerating).
  final bool shown;

  /// The control can be pressed now.
  final bool enabled;

  /// Time left before it can, in the coarsest whole unit that is not zero.
  final FlareInviteCooldown? remaining;
}

/// Whether regenerating is offered, and if so whether it is still cooling
/// down. The remaining time rounds *up* so the control never re-enables before
/// the server would.
FlareRegenerateAvailability regenerateAvailability(bool canRegenerate, int? availableAt, int now) {
  if (!canRegenerate) return const FlareRegenerateAvailability(shown: false, enabled: false);
  final remainingMs = availableAt == null ? 0 : availableAt - now;
  if (remainingMs <= 0) return const FlareRegenerateAvailability(shown: true, enabled: true);
  const minute = 60000;
  const hour = 60 * minute;
  const day = 24 * hour;
  final FlareInviteCooldown remaining;
  if (remainingMs < hour) {
    final n = (remainingMs / minute).ceil();
    remaining = FlareInviteCooldown(FlareInviteCooldownUnit.minute, n < 1 ? 1 : n);
  } else if (remainingMs < day) {
    remaining = FlareInviteCooldown(FlareInviteCooldownUnit.hour, (remainingMs / hour).ceil());
  } else {
    remaining = FlareInviteCooldown(FlareInviteCooldownUnit.day, (remainingMs / day).ceil());
  }
  return FlareRegenerateAvailability(shown: true, enabled: false, remaining: remaining);
}

/// `YYYY-MM-DD` for a calendar date — the same on every platform.
String formatInviteJoinedDate(int year, int month, int day) {
  String pad(int n) => n < 10 ? '0$n' : '$n';
  return '$year-${pad(month)}-${pad(day)}';
}

/// `YYYY-MM-DD` of an epoch-millisecond instant in the device's time zone.
String inviteJoinedDateLabel(int epochMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
  return formatInviteJoinedDate(d.year, d.month, d.day);
}
