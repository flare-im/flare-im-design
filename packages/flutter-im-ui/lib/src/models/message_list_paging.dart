/// The two ends of the message list and its back-to-latest key
/// (`spec/message-list-paging-vectors.json`, read by the Vue, SwiftUI and
/// Compose kits too). A window is the run of messages the host hands the list;
/// its older end (above the timeline) and its newer end (below it) follow one
/// rule.
library;

/// How close to an edge the reader must scroll before the list asks for the
/// next page there, in logical pixels.
const double flareMessageListOlderWithin = 160;
const double flareMessageListNewerWithin = 160;

/// One end of the window, as the host describes it.
class FlareMessageListEnd {
  const FlareMessageListEnd({
    required this.has,
    required this.loading,
    this.error,
    required this.handled,
  });

  /// There is more to read past this end.
  final bool has;

  /// A page past this end is being read.
  final bool loading;

  /// The last page past this end failed; null, empty or blank is no error.
  final String? error;

  /// The host takes this end's load intent.
  final bool handled;

  bool get failed => (error ?? '').trim().isNotEmpty;
}

/// What one end draws.
class FlareMessageListEdge {
  const FlareMessageListEdge({
    required this.spinner,
    required this.error,
    required this.button,
  });

  final bool spinner;
  final bool error;
  final bool button;

  bool get visible => spinner || error || button;

  @override
  bool operator ==(Object other) =>
      other is FlareMessageListEdge &&
      other.spinner == spinner &&
      other.error == error &&
      other.button == button;

  @override
  int get hashCode => Object.hash(spinner, error, button);

  @override
  String toString() =>
      'FlareMessageListEdge(spinner: $spinner, error: $error, button: $button)';
}

/// While loading, a spinner and nothing else (the last error is not repeated
/// while it is being retried); otherwise the error when there is one, and the
/// load or retry button while there is more and the host takes the intent.
FlareMessageListEdge flareMessageListEdge(FlareMessageListEnd end) {
  if (end.loading) {
    return const FlareMessageListEdge(
      spinner: true,
      error: false,
      button: false,
    );
  }
  return FlareMessageListEdge(
    spinner: false,
    error: end.failed,
    button: end.has && end.handled,
  );
}

/// The pages the list asks for as the reader scrolls: an end asks within its
/// distance of its edge (inclusive), while there is more, nothing is loading,
/// the last page did not fail (after a failure only the retry button asks) and
/// the host takes the intent. [fromTop] is how far the first row's top is above
/// the viewport's top, [fromBottom] how far the end of the timeline is below
/// the viewport's bottom.
({bool older, bool newer}) flareMessageListRequests({
  required double fromTop,
  required double fromBottom,
  required FlareMessageListEnd older,
  required FlareMessageListEnd newer,
}) {
  bool asks(FlareMessageListEnd end, double distance, double within) =>
      end.handled &&
      end.has &&
      !end.loading &&
      !end.failed &&
      distance <= within;
  return (
    older: asks(older, fromTop, flareMessageListOlderWithin),
    newer: asks(newer, fromBottom, flareMessageListNewerWithin),
  );
}

/// What the floating key at the bottom does.
enum FlareMessageListLatestAction { jumpToLatest, scrollToBottom }

/// A window detached from the latest ([hasNewer]) offers the way back to the
/// latest messages, without a count — rows below a detached reader are history
/// read in, not news — when the host takes the jump. Otherwise it is the
/// new-messages key: shown while messages arrived below a reader who scrolled
/// up, counting them, and it scrolls to the bottom.
({bool shown, int count, FlareMessageListLatestAction? action})
flareMessageListLatestEntry({
  required bool hasNewer,
  required bool handled,
  required int belowCount,
}) {
  if (hasNewer) {
    return handled
        ? (
            shown: true,
            count: 0,
            action: FlareMessageListLatestAction.jumpToLatest,
          )
        : (shown: false, count: 0, action: null);
  }
  return belowCount > 0
      ? (
          shown: true,
          count: belowCount,
          action: FlareMessageListLatestAction.scrollToBottom,
        )
      : (shown: false, count: 0, action: null);
}

/// Rows appended to a window that was detached are a newer page read in, not
/// messages that arrived: the core appends nothing to a detached window, and a
/// message sent from one comes back as a new latest window.
bool flareMessageListNewerPage(
  List<String> previous,
  List<String> next, {
  required bool wasDetached,
}) {
  if (!wasDetached || previous.isEmpty || next.length <= previous.length) {
    return false;
  }
  for (var i = 0; i < previous.length; i++) {
    if (previous[i] != next[i]) return false;
  }
  return true;
}

/// Whether the host replaced the window as a whole rather than grew or edited
/// the one the reader is in (`spec/message-list-paging-vectors.json`
/// `windows`). [previous] and [next] are row keys in timeline order. Both must
/// have rows, and then any of: the host's name for the window
/// ([previousWindowId] to [windowId], the core timeline view's `viewId`; null
/// or empty is none) changed from one name to another; the latest window the
/// reader asked for arrived ([jumpRequested], attached: not [hasNewer]); no
/// row of the new window was in the old one.
bool flareMessageListWindowReplaced(
  List<String> previous,
  List<String> next, {
  bool jumpRequested = false,
  bool hasNewer = false,
  String? previousWindowId,
  String? windowId,
}) {
  if (previous.isEmpty || next.isEmpty) return false;
  final before = previousWindowId ?? '';
  final after = windowId ?? '';
  if (before.isNotEmpty && after.isNotEmpty && before != after) return true;
  if (jumpRequested && !hasNewer) return true;
  final kept = previous.toSet();
  return !next.any(kept.contains);
}
