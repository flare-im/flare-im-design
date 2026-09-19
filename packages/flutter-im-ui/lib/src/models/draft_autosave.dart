/// When what someone typed and did not send is written down, and what it is written as.
///
/// The rule is shared with the Vue, SwiftUI and Compose kits and tested against `spec/draft-vectors.json`.
/// It lives here rather than in each app because all five were writing it, and writing it to five
/// different places with five different lifetimes: the web app saved to the core after 1200 ms, so a
/// draft roamed to another device; the Tauri app to `localStorage` after 450 ms, so it survived a restart
/// on that machine and nowhere else; the Android app to a map in memory, so it survived switching
/// conversations and nothing else; the Flutter and iOS apps did not save at all — leave the chat and what
/// you typed was gone. "Draft" meant four different things.
library;

/// A pause this long after the last edit writes the draft down.
const int flareDraftSaveDelayMs = 1200;

/// One write this client owes the core. [text] of '' clears the conversation's draft.
class FlareDraftSave {
  const FlareDraftSave(this.conversationId, this.text, this.atMs);

  final String conversationId;
  final String text;

  /// The instant the write is for — the deadline when a pause triggered it, else the moment it happened.
  final int atMs;

  @override
  bool operator ==(Object other) =>
      other is FlareDraftSave && other.conversationId == conversationId && other.text == text && other.atMs == atMs;

  @override
  int get hashCode => Object.hash(conversationId, text, atMs);

  @override
  String toString() => 'FlareDraftSave($conversationId, ${text.length} chars, $atMs)';
}

/// The text a send that reached nothing leaves behind: above whatever was typed while it was in flight,
/// and never twice. A failed send of nothing changes nothing.
String flareRestoredDraft(String current, String failed) {
  final back = failed.trim();
  if (back.isEmpty) return current;
  if (current.trim().isEmpty) return failed;
  if (current.contains(back)) return current;
  return '$failed\n$current';
}

String _stored(String text) => text.trim().isEmpty ? '' : text;

class FlareDraftAutosave {
  final Map<String, String> _saved = {};
  ({String conversationId, String text})? _pending;
  int _deadlineMs = 0;

  /// What the core already holds for a conversation, so an unchanged draft is never written back.
  void seed(String conversationId, String text) {
    if (conversationId.isEmpty) return;
    _saved[conversationId] = _stored(text);
  }

  /// The draft this client believes the core holds.
  String storedText(String conversationId) => _saved[conversationId] ?? '';

  /// When the pending write is due, or null when none is. Hosts arm a timer on it.
  int? get pendingDeadline => _pending == null ? null : _deadlineMs;

  /// The composer's text changed. Editing a sent message is not this: the host does not report it here.
  List<FlareDraftSave> edit(String conversationId, String text, int nowMs) {
    final out = <FlareDraftSave>[...tick(nowMs)];
    if (conversationId.isEmpty) return out;
    // Moving to another conversation writes the one being left before starting the new one.
    final pending = _pending;
    if (pending != null && pending.conversationId != conversationId) out.addAll(_flush(nowMs));
    _pending = (conversationId: conversationId, text: _stored(text));
    _deadlineMs = nowMs + flareDraftSaveDelayMs;
    return out;
  }

  /// The message went out: the draft it came from is gone, and any pending write with it.
  List<FlareDraftSave> send(String conversationId, int nowMs) {
    final out = <FlareDraftSave>[...tick(nowMs)];
    if (_pending?.conversationId == conversationId) _pending = null;
    return [...out, ..._write(conversationId, '', nowMs)];
  }

  /// The reader left the conversation, the screen or the app: write the pending draft now.
  List<FlareDraftSave> leave(int nowMs) => [...tick(nowMs), ..._flush(nowMs)];

  /// A send that reached nothing. Its text goes back immediately, never on the timer: a draft lost to a
  /// pending write is the one case where losing it is unforgivable.
  List<FlareDraftSave> restore(String conversationId, String failedText, int nowMs) {
    final out = <FlareDraftSave>[...tick(nowMs)];
    if (conversationId.isEmpty) return out;
    if (_pending?.conversationId == conversationId) _pending = null;
    return [...out, ..._write(conversationId, flareRestoredDraft(storedText(conversationId), failedText), nowMs)];
  }

  /// Time passed. Fires the pending write at its deadline, not at [nowMs].
  List<FlareDraftSave> tick(int nowMs) {
    if (_pending == null || nowMs < _deadlineMs) return const [];
    return _flush(_deadlineMs);
  }

  List<FlareDraftSave> _flush(int atMs) {
    final pending = _pending;
    if (pending == null) return const [];
    _pending = null;
    _deadlineMs = 0;
    return _write(pending.conversationId, pending.text, atMs);
  }

  List<FlareDraftSave> _write(String conversationId, String text, int atMs) {
    if (conversationId.isEmpty) return const [];
    final next = _stored(text);
    if (storedText(conversationId) == next) return const [];
    _saved[conversationId] = next;
    return [FlareDraftSave(conversationId, next, atMs)];
  }
}
