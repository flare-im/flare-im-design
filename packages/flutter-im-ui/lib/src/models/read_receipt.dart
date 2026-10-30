import 'package:flutter/foundation.dart';

/// State of a read list (`FlareReadReceiptSheet.state`,
/// `spec/read-receipt-vectors.json`): [ready] draws the tabs and the active
/// column; [loading] the tabs and a spinner; [error] a notice with a retry
/// key and no tabs; [unavailable] a notice with no retry and no tabs (the
/// host's answer to NOT_FOUND or `available: false`).
enum FlareReadReceiptState { ready, loading, error, unavailable }

/// A column of the read list.
enum FlareReadReceiptColumn { read, unread }

/// What the body of the read list shows.
enum FlareReadReceiptBody {
  /// The list is loading.
  spinner,

  /// The list failed to load: a notice and a retry key.
  error,

  /// The message has no read list to show: a notice, no retry.
  unavailable,

  /// The active column's rows (possibly none yet, with a next page).
  list,

  /// The active column has no rows and no next page: its empty notice.
  empty,
}

/// The last row of the active column's list.
enum FlareReadReceiptTail {
  /// Nothing after the rows.
  none,

  /// The next page is being read: a spinner, not a control.
  busy,

  /// The load-more key (readReceiptLoadMore), emitting loadMore(column).
  loadMore,

  /// The last next-page read failed: the retry key
  /// (readReceiptLoadMoreFailed), emitting loadMore(column).
  retry,
}

/// One tab of the read list and the number it shows: the host's summary
/// count, or null for no number — never the length of the loaded rows.
@immutable
class FlareReadReceiptTab {
  const FlareReadReceiptTab(this.column, this.count);

  final FlareReadReceiptColumn column;
  final int? count;

  @override
  bool operator ==(Object other) =>
      other is FlareReadReceiptTab &&
      other.column == column &&
      other.count == count;

  @override
  int get hashCode => Object.hash(column, count);

  @override
  String toString() => 'FlareReadReceiptTab(${column.name}, $count)';
}

/// What a read list draws for its inputs (`spec/read-receipt-vectors.json`).
@immutable
class FlareReadReceiptLayout {
  const FlareReadReceiptLayout({
    required this.tabs,
    required this.body,
    required this.rows,
    required this.tail,
  });

  /// The two tabs in order, or null when no tabs are drawn.
  final List<FlareReadReceiptTab>? tabs;
  final FlareReadReceiptBody body;

  /// How many member rows are drawn.
  final int rows;
  final FlareReadReceiptTail tail;

  /// The column a tap on [tail] asks for, or null when it is not a control.
  FlareReadReceiptColumn? tailRequest(FlareReadReceiptColumn active) =>
      tail == FlareReadReceiptTail.loadMore ||
          tail == FlareReadReceiptTail.retry
      ? active
      : null;
}

/// The read list's layout:
///
/// - tabs: in ready and loading, read then unread, each with the summary
///   count the host passes ([readCount] / [unreadCount]) or no number; none
///   in error and unavailable;
/// - body: spinner (loading), error, unavailable, else the [active] column —
///   empty when it has no rows and no next page, else its list;
/// - tail (a list only): busy while that column is [loadingMore], else retry
///   when its last next-page read failed ([loadMoreFailed]), else load more
///   when it has a next page, else none. A column never asks twice while it
///   loads more; the other column pages on its own.
///
/// [readers] and [unread] are the counts of the rows loaded so far.
FlareReadReceiptLayout flareReadReceiptLayout({
  required FlareReadReceiptState state,
  required FlareReadReceiptColumn active,
  required int readers,
  required int unread,
  int? readCount,
  int? unreadCount,
  bool readHasMore = false,
  bool unreadHasMore = false,
  FlareReadReceiptColumn? loadingMore,
  FlareReadReceiptColumn? loadMoreFailed,
}) {
  final tabs = switch (state) {
    FlareReadReceiptState.ready || FlareReadReceiptState.loading => [
      FlareReadReceiptTab(FlareReadReceiptColumn.read, readCount),
      FlareReadReceiptTab(FlareReadReceiptColumn.unread, unreadCount),
    ],
    _ => null,
  };
  if (state != FlareReadReceiptState.ready) {
    return FlareReadReceiptLayout(
      tabs: tabs,
      body: switch (state) {
        FlareReadReceiptState.loading => FlareReadReceiptBody.spinner,
        FlareReadReceiptState.error => FlareReadReceiptBody.error,
        _ => FlareReadReceiptBody.unavailable,
      },
      rows: 0,
      tail: FlareReadReceiptTail.none,
    );
  }
  final rows = active == FlareReadReceiptColumn.read ? readers : unread;
  final hasMore = active == FlareReadReceiptColumn.read
      ? readHasMore
      : unreadHasMore;
  if (rows == 0 && !hasMore) {
    return FlareReadReceiptLayout(
      tabs: tabs,
      body: FlareReadReceiptBody.empty,
      rows: 0,
      tail: FlareReadReceiptTail.none,
    );
  }
  final tail = loadingMore == active
      ? FlareReadReceiptTail.busy
      : loadMoreFailed == active
      ? FlareReadReceiptTail.retry
      : hasMore
      ? FlareReadReceiptTail.loadMore
      : FlareReadReceiptTail.none;
  return FlareReadReceiptLayout(
    tabs: tabs,
    body: FlareReadReceiptBody.list,
    rows: rows,
    tail: tail,
  );
}
