import 'dart:async';

import 'package:flutter/foundation.dart';

import 'directory_data.dart';
import 'read_receipt.dart';

// The group read list's paging, without UI (spec/read-receipt-list-vectors.json):
// what a host keeps for FlareReadReceiptSheet. The host gives one loader that
// reads a page of one column; the kit owns the rest — both first pages on
// opening, a column's next page on loadMore, the whole-list state, the
// per-column busy and failed marks. The kit calls no SDK: the loader maps the
// SDK's answer (names the user ids, turns "not offered" into null).

/// A column as far as it is read: its people in order, and the next page's
/// cursor while there is one.
@immutable
class FlareReadReceiptMembers {
  const FlareReadReceiptMembers({this.people = const [], this.nextCursor});

  final List<FlareContact> people;

  /// The cursor of the column's next page; null on its last page.
  final String? nextCursor;

  /// The column has a next page (the sheet's readHasMore / unreadHasMore).
  bool get hasMore => nextCursor != null;

  @override
  bool operator ==(Object other) =>
      other is FlareReadReceiptMembers &&
      other.nextCursor == nextCursor &&
      listEquals(
        other.people.map((p) => p.id).toList(),
        people.map((p) => p.id).toList(),
      );

  @override
  int get hashCode =>
      Object.hash(nextCursor, Object.hashAll(people.map((p) => p.id)));

  @override
  String toString() =>
      'FlareReadReceiptMembers(${people.map((p) => p.id).join(',')}'
      '${nextCursor == null ? '' : ' → $nextCursor'})';
}

/// The list: its state, both columns, and the column reading (or last failing
/// to read) its next page. The tab numbers are not here: the host passes the
/// message's current read summary, which follows the receipts as they arrive.
@immutable
class FlareReadReceiptPages {
  const FlareReadReceiptPages({
    required this.state,
    this.read = const FlareReadReceiptMembers(),
    this.unread = const FlareReadReceiptMembers(),
    this.loadingMore,
    this.loadMoreFailed,
  });

  final FlareReadReceiptState state;
  final FlareReadReceiptMembers read;
  final FlareReadReceiptMembers unread;

  /// The column whose next page is being read (the one asked last).
  final FlareReadReceiptColumn? loadingMore;

  /// The column whose last next-page read failed.
  final FlareReadReceiptColumn? loadMoreFailed;

  FlareReadReceiptMembers members(FlareReadReceiptColumn column) =>
      column == FlareReadReceiptColumn.read ? read : unread;

  FlareReadReceiptPages _with({
    FlareReadReceiptColumn? column,
    FlareReadReceiptMembers? members,
    required FlareReadReceiptColumn? loadingMore,
    required FlareReadReceiptColumn? loadMoreFailed,
  }) => FlareReadReceiptPages(
    state: state,
    read: column == FlareReadReceiptColumn.read ? members! : read,
    unread: column == FlareReadReceiptColumn.unread ? members! : unread,
    loadingMore: loadingMore,
    loadMoreFailed: loadMoreFailed,
  );

  /// [column]'s next page arrived ([page]; null: the column ends): its people
  /// after the column's, someone already listed kept once, and its cursor.
  FlareReadReceiptPages _appended(
    FlareReadReceiptColumn column,
    FlareReadReceiptMembers? page,
  ) {
    final shown = members(column);
    final FlareReadReceiptMembers next;
    if (page == null) {
      next = FlareReadReceiptMembers(people: shown.people);
    } else {
      final listed = {for (final person in shown.people) person.id};
      next = FlareReadReceiptMembers(
        people: [
          ...shown.people,
          for (final person in page.people)
            if (listed.add(person.id)) person,
        ],
        nextCursor: page.nextCursor,
      );
    }
    return _with(
      column: column,
      members: next,
      loadingMore: loadingMore == column ? null : loadingMore,
      loadMoreFailed: loadMoreFailed,
    );
  }

  /// [column]'s next page failed: the sheet offers to read it again.
  FlareReadReceiptPages _failed(FlareReadReceiptColumn column) => _with(
    loadingMore: loadingMore == column ? null : loadingMore,
    loadMoreFailed: column,
  );

  @override
  bool operator ==(Object other) =>
      other is FlareReadReceiptPages &&
      other.state == state &&
      other.read == read &&
      other.unread == unread &&
      other.loadingMore == loadingMore &&
      other.loadMoreFailed == loadMoreFailed;

  @override
  int get hashCode =>
      Object.hash(state, read, unread, loadingMore, loadMoreFailed);

  @override
  String toString() =>
      'FlareReadReceiptPages(${state.name}, read: $read, unread: $unread, '
      'loadingMore: ${loadingMore?.name}, '
      'loadMoreFailed: ${loadMoreFailed?.name})';
}

/// One page of [column] after [cursor] (the first page when null), its user
/// ids named as the host names people. Completes with null when the message's
/// list is not offered (the SDK's NOT_FOUND, `available: false`); throws on
/// any other failure.
typedef FlareReadReceiptPageLoader =
    Future<FlareReadReceiptMembers?> Function(
      FlareReadReceiptColumn column,
      String? cursor,
    );

/// The read list of the message a key names, for [FlareReadReceiptSheet]
/// (`FlareReadReceiptSheet.list` listens to it): [pages] is null while no
/// message is open. [loadMore] and [retry] are the sheet's onLoadMore and
/// onRetry; the tab numbers stay the host's summary counts.
///
/// [open] a message's key to read both first pages; a new key reads them
/// again and drops what the previous one still had in flight; null or empty
/// closes the list. [dispose] drops every answer still to come.
class FlareReadReceiptListState extends ChangeNotifier {
  FlareReadReceiptListState(this._page);

  final FlareReadReceiptPageLoader _page;
  FlareReadReceiptPages? _pages;
  String? _key;
  int _generation = 0;
  bool _disposed = false;

  /// Columns whose next page is being read: the sheet shows one busy column,
  /// but neither asks twice.
  final Set<FlareReadReceiptColumn> _reading = {};

  /// The open list; null while no message is open.
  FlareReadReceiptPages? get pages => _pages;

  /// The key of the open message, or null.
  String? get key => _key;

  void _set(FlareReadReceiptPages? next) {
    if (_disposed || next == _pages) return;
    _pages = next;
    notifyListeners();
  }

  /// Opens the list of the message [key] names (null or empty: closes it).
  /// The same key again does nothing.
  void open(String? key) {
    final opened = key == null || key.isEmpty ? null : key;
    if (opened == _key) return;
    _key = opened;
    if (opened == null) {
      _drop();
      _set(null);
    } else {
      unawaited(_read());
    }
  }

  /// Reads the list again from both first pages (the sheet's retry), whatever
  /// its state; nothing while no message is open.
  Future<void> retry() => _key == null ? Future.value() : _read();

  /// The next page of [column] (the sheet's loadMore). Nothing happens unless
  /// the list is ready, the column has a next page and is not reading it
  /// already; the other column pages on its own meanwhile.
  Future<void> loadMore(FlareReadReceiptColumn column) async {
    final current = _pages;
    if (current == null || current.state != FlareReadReceiptState.ready) {
      return;
    }
    final cursor = current.members(column).nextCursor;
    if (cursor == null || _reading.contains(column)) return;
    final mine = _generation;
    _reading.add(column);
    _set(
      current._with(
        loadingMore: column,
        loadMoreFailed: current.loadMoreFailed == column
            ? null
            : current.loadMoreFailed,
      ),
    );
    FlareReadReceiptPages Function(FlareReadReceiptPages) settle;
    try {
      final next = await _page(column, cursor);
      settle = (latest) => latest._appended(column, next);
    } catch (_) {
      settle = (latest) => latest._failed(column);
    }
    if (mine != _generation) return;
    _reading.remove(column);
    final latest = _pages;
    if (latest != null) _set(settle(latest));
  }

  Future<void> _read() async {
    _drop();
    final mine = _generation;
    _set(const FlareReadReceiptPages(state: FlareReadReceiptState.loading));
    FlareReadReceiptPages next;
    try {
      // Both at once: either failing fails the pair, either not offered makes
      // the list unavailable.
      final answers = await Future.wait([
        _page(FlareReadReceiptColumn.read, null),
        _page(FlareReadReceiptColumn.unread, null),
      ]);
      final read = answers[0], unread = answers[1];
      next = read != null && unread != null
          ? FlareReadReceiptPages(
              state: FlareReadReceiptState.ready,
              read: read,
              unread: unread,
            )
          : const FlareReadReceiptPages(
              state: FlareReadReceiptState.unavailable,
            );
    } catch (_) {
      next = const FlareReadReceiptPages(state: FlareReadReceiptState.error);
    }
    if (mine == _generation) _set(next);
  }

  /// Forgets what is in flight: its answers land nowhere.
  void _drop() {
    _generation += 1;
    _reading.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _drop();
    super.dispose();
  }
}
