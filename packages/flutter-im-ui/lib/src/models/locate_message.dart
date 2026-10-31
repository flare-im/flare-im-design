import 'dart:async';

/// How a tapped quote's trip ended.
enum FlareLocateOutcome {
  /// The list is showing the message.
  shown,

  /// The history was read to its end (or to the budget) without finding it. This is the only answer the
  /// host says out loud, and it chooses the words: a page that failed and a message that is genuinely gone
  /// read differently, and only the host knows which happened.
  notInHistory,

  /// The reader left the conversation while the trip was running. Nothing is said.
  cancelled,
}

/// Older pages one locate may read before it gives up.
const int flareLocateMaxPages = 24;

/// How many more times the list is asked after the history is spent. The rows of the last page read may not
/// be drawn yet, and a list answers for the pass it last drew.
const int flareLocateSettleAttempts = 6;

/// The trip a tapped quote takes when the message it names is not loaded yet: ask the list, read a page of
/// older history, ask again, and stop with one of three answers.
///
/// The rule is shared with the Vue, SwiftUI and Compose kits and tested against
/// `spec/locate-orchestration-vectors.json`. It lives in the kit rather than in each app because all four
/// were writing it, and writing it differently: the page budgets were 24, 20, 5 and 24, only one of them
/// waited for the list to draw the page it had just read, and only one stopped when the reader left.
///
/// - [showInList] asks the list to show the message and answers whether it had it — on this kit that is
///   `FlareMessageListController.scrollToMessage`.
/// - [readOlder] reads one older page and answers whether it brought anything in; a page that failed
///   answers false and ends the search.
/// - [settle] lets the list draw one pass.
/// - [isCurrent] is false once the reader has left this conversation.
Future<FlareLocateOutcome> flareLocateMessage({
  required FutureOr<bool> Function() showInList,
  required bool Function() hasOlder,
  required FutureOr<bool> Function() readOlder,
  required FutureOr<void> Function() settle,
  required bool Function() isCurrent,
}) async {
  var advanced = true;
  var pages = 0;
  while (true) {
    if (!isCurrent()) return FlareLocateOutcome.cancelled;
    if (await showInList()) return FlareLocateOutcome.shown;
    if (!(hasOlder() && advanced && pages < flareLocateMaxPages)) break;
    advanced = await readOlder();
    pages += 1;
    await settle();
  }
  for (var attempt = 0; attempt < flareLocateSettleAttempts; attempt++) {
    if (!isCurrent()) return FlareLocateOutcome.cancelled;
    await settle();
    if (await showInList()) return FlareLocateOutcome.shown;
  }
  return FlareLocateOutcome.notInHistory;
}

/// The message a locate opens a window around: its id (server or client), and
/// its seq when the caller has it.
class FlareLocateAnchor {
  const FlareLocateAnchor({required this.messageId, this.seq});

  final String messageId;
  final int? seq;

  @override
  bool operator ==(Object other) =>
      other is FlareLocateAnchor &&
      other.messageId == messageId &&
      other.seq == seq;

  @override
  int get hashCode => Object.hash(messageId, seq);

  @override
  String toString() => 'FlareLocateAnchor($messageId, seq: $seq)';
}

/// The same trip when the host can open a window around the message (a
/// timeline view opened with an anchor) instead of paging back to it: ask the
/// list, open once around the anchor, then let the list draw and ask for the
/// anchor key up to [flareLocateSettleAttempts] times
/// (`spec/locate-orchestration-vectors.json` `around`). The list scrolls to the
/// row and marks it itself.
///
/// - [showInList] asks the list to show the message with this id and answers
///   whether it had it — on this kit that is
///   `FlareMessageListController.scrollToMessage`.
/// - [openAround] opens the timeline around the anchor and answers the anchor
///   key — the row key the list will draw the message with — or null (or a
///   blank key) when the message is not in the history. A failed open answers
///   null.
/// - [settle] lets the list draw one pass.
/// - [isCurrent] is false once the reader has left this conversation.
Future<FlareLocateOutcome> flareLocateMessageAround({
  required FlareLocateAnchor anchor,
  required FutureOr<bool> Function(String messageId) showInList,
  required FutureOr<String?> Function(FlareLocateAnchor anchor) openAround,
  required FutureOr<void> Function() settle,
  required bool Function() isCurrent,
}) async {
  if (!isCurrent()) return FlareLocateOutcome.cancelled;
  if (await showInList(anchor.messageId)) return FlareLocateOutcome.shown;
  if (!isCurrent()) return FlareLocateOutcome.cancelled;
  final key = ((await openAround(anchor)) ?? '').trim();
  if (!isCurrent()) return FlareLocateOutcome.cancelled;
  if (key.isEmpty) return FlareLocateOutcome.notInHistory;
  for (var attempt = 0; attempt < flareLocateSettleAttempts; attempt++) {
    if (!isCurrent()) return FlareLocateOutcome.cancelled;
    await settle();
    if (await showInList(key)) return FlareLocateOutcome.shown;
  }
  return FlareLocateOutcome.notInHistory;
}
