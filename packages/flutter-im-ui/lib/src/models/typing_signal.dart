/// What this client tells a conversation about its own typing.
///
/// The rule is shared with the Vue, SwiftUI and Compose kits and tested against the `signal` half of
/// `spec/typing-vectors.json`. It lives here rather than in each app because all five were writing it, and
/// writing it differently: the pause that ends typing was 3000, 2800, 1500, 1500 and — on iOS — never, two
/// apps re-reported `true` on every keystroke, and the two that deduplicated the report never refreshed it,
/// so a message that took longer than the peer's belief to write stopped showing as typing while it was
/// still being typed.
///
/// The engine is a state machine with the clock passed in, not read: the same script must produce the same
/// reports on four platforms, and a rule that reads the wall clock cannot be tested at all.
library;

/// A pause this long after the last edit ends typing.
const int flareTypingIdleStopMs = 4000;

/// `typing: true` is reported at most this often while the user keeps typing.
const int flareTypingRefreshMs = 2500;

/// How long a peer stays "typing" on this belief without a fresh signal (the receiving half of the rule).
const int flareTypingPeerTtlMs = 6000;

/// One report this client owes a conversation.
class FlareTypingReport {
  const FlareTypingReport(this.conversationId, this.typing, this.atMs);

  final String conversationId;
  final bool typing;

  /// The instant the report is for. Usually the `nowMs` handed in, but an idle stop is timestamped at its
  /// deadline, so a host whose timer fired late still reports the moment typing actually ended — and the
  /// shared table can assert *when*, not only *what*.
  final int atMs;

  @override
  bool operator ==(Object other) =>
      other is FlareTypingReport && other.conversationId == conversationId && other.typing == typing && other.atMs == atMs;

  @override
  int get hashCode => Object.hash(conversationId, typing, atMs);

  @override
  String toString() => 'FlareTypingReport($conversationId, $typing, $atMs)';
}

/// One conversation types at a time: the composer is one control, so an edit somewhere else ends the
/// previous conversation before it starts the new one. Every method answers with the reports to send, in
/// order — the caller does the sending, and a send that fails is not this rule's business.
class FlareTypingSignal {
  String _activeId = '';
  int _lastTrueAtMs = 0;
  int _idleDeadlineMs = 0;

  /// The conversation currently reported as typing, or '' when none is.
  String get typingConversationId => _activeId;

  /// When the idle stop is due, or null when nothing is typing. Hosts arm a timer on it.
  int? get idleDeadline => _activeId.isEmpty ? null : _idleDeadlineMs;

  /// The composer's text changed. Text that trims to nothing is not typing.
  List<FlareTypingReport> edit(String conversationId, String text, int nowMs) {
    final out = <FlareTypingReport>[...tick(nowMs)];
    if (text.trim().isEmpty || conversationId.isEmpty) return [...out, ..._stop(nowMs)];
    if (_activeId != conversationId) {
      out.addAll(_stop(nowMs));
      _activeId = conversationId;
      _lastTrueAtMs = nowMs;
      out.add(FlareTypingReport(conversationId, true, nowMs));
    } else if (nowMs - _lastTrueAtMs >= flareTypingRefreshMs) {
      _lastTrueAtMs = nowMs;
      out.add(FlareTypingReport(conversationId, true, nowMs));
    }
    _idleDeadlineMs = nowMs + flareTypingIdleStopMs;
    return out;
  }

  /// The message went out. It says more than the signal does, so typing ends with it.
  List<FlareTypingReport> send(String conversationId, int nowMs) => [...tick(nowMs), ..._stop(nowMs)];

  /// The reader left the conversation, the screen or the app.
  List<FlareTypingReport> close(int nowMs) => [...tick(nowMs), ..._stop(nowMs)];

  /// Time passed. Fires the idle stop at its deadline, not at [nowMs], so a late tick still reports on time.
  List<FlareTypingReport> tick(int nowMs) {
    if (_activeId.isEmpty || nowMs < _idleDeadlineMs) return const [];
    return _stop(_idleDeadlineMs);
  }

  List<FlareTypingReport> _stop(int atMs) {
    if (_activeId.isEmpty) return const [];
    final conversationId = _activeId;
    _activeId = '';
    _idleDeadlineMs = 0;
    return [FlareTypingReport(conversationId, false, atMs)];
  }
}

/// What this client believes about its peers — the receiving half of the same rule.
///
/// Facts in (someone started, someone stopped, the server listed everyone typing, a message arrived from
/// a typer), the people typing in a conversation out, in the order they started. Nothing here knows a wire
/// shape: the app parses its own events and calls these, which is the boundary the kit is not allowed to
/// cross. A belief expires [flareTypingPeerTtlMs] after the signal that made it, so a client that dies
/// mid-sentence does not leave a peer typing forever.
///
/// Two of five apps had this, with two different expiries and two different sets of facts — one of them
/// only ever heard "someone started", so a server listing of who is typing did nothing — and three apps
/// had no idea a peer could be typing at all. Tested against the `roster` half of `spec/typing-vectors.json`.
class FlareTypingRoster {
  /// [selfId] never appears among the typers: this client's own signal is not news to itself.
  FlareTypingRoster([this.selfId = '']);

  final String selfId;

  /// conversationId → (userId → the instant this belief expires), in the order they started.
  final Map<String, Map<String, int>> _state = {};

  /// Someone began typing in a conversation.
  void started(String conversationId, String userId, int nowMs) {
    if (conversationId.isEmpty || userId.isEmpty || userId == selfId) return;
    (_state[conversationId] ??= <String, int>{})[userId] = nowMs + flareTypingPeerTtlMs;
  }

  /// Someone stopped — an explicit signal, believed at once.
  void stopped(String conversationId, String userId) {
    final users = _state[conversationId];
    if (users == null || users.remove(userId) == null) return;
    if (users.isEmpty) _state.remove(conversationId);
  }

  /// The server listed everyone typing in a conversation: that listing is the whole truth for it.
  void replaced(String conversationId, List<String> userIds, int nowMs) {
    if (conversationId.isEmpty) return;
    final kept = userIds.where((id) => id.isNotEmpty && id != selfId).toList();
    if (kept.isEmpty) {
      _state.remove(conversationId);
      return;
    }
    _state[conversationId] = {for (final id in kept) id: nowMs + flareTypingPeerTtlMs};
  }

  /// A message arrived. It says more than the signal did, so its sender is no longer typing.
  void sent(String conversationId, String senderId) => stopped(conversationId, senderId);

  /// Drops every belief whose time has run out. Hosts call it on a timer armed from [nextExpiry].
  void prune(int nowMs) {
    for (final conversationId in _state.keys.toList()) {
      final users = _state[conversationId]!;
      users.removeWhere((_, expiresAt) => expiresAt <= nowMs);
      if (users.isEmpty) _state.remove(conversationId);
    }
  }

  /// Who is typing in a conversation, in the order they started.
  List<String> typers(String conversationId) => _state[conversationId]?.keys.toList() ?? const [];

  /// When the soonest belief runs out, or null when nothing is typing.
  int? get nextExpiry {
    int? next;
    for (final users in _state.values) {
      for (final expiresAt in users.values) {
        next = next == null || expiresAt < next ? expiresAt : next;
      }
    }
    return next;
  }

  /// Forgets everything — signing out, or switching account.
  void clear() => _state.clear();
}

/// The names a typing indicator shows. A typer the roster has but the directory has not introduced yet
/// falls back to [fallback] — the conversation's own name in a 1:1, a generic "member" word in a group —
/// because a raw id is never shown to a reader. An empty fallback drops the unnamed typer instead.
List<String> flareTypingNames(
  List<String> userIds,
  String Function(String userId) nameOf,
  String fallback,
) {
  final out = <String>[];
  for (final userId in userIds) {
    final name = nameOf(userId).isNotEmpty ? nameOf(userId) : fallback;
    if (name.isNotEmpty) out.add(name);
  }
  return out;
}
