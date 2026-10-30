import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/read_receipt.dart';
import '../models/read_receipt_list.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_overlay.dart';
import 'icon_control.dart';

/// The read list of one of the viewer's group messages: read and unread
/// columns that page on their own, with loading, error and unavailable
/// states. Spec: Message/ReadReceiptSheet (`FlareReadReceiptSheet`,
/// `spec/read-receipt-vectors.json`).
///
/// The host holds both columns: [readers] and [unread] are the members loaded
/// so far (one page or more), [readHasMore] / [unreadHasMore] say a column has
/// a next page, and [onLoadMore] asks for it. A tab's number is the summary
/// count the host passes ([readCount] / [unreadCount], from the message's read
/// summary); without one the tab has no number — never the length of a list
/// that may be one page. While a column is [loadingMore] its list ends with a
/// spinner and asks for nothing; after a failed read ([loadMoreFailed]) it ends
/// with a retry key. Switching tabs emits nothing.
///
/// The sheet takes its container's width. Standing alone (beside a bubble) it
/// draws its own card shell, at most 320 wide, its rows scrolling within 320.
/// Inside a kit overlay (FlareBottomSheet, FlareModal) it draws no shell and
/// fills the surface; it brings its own header ([FlareSheetOwnHeader]), so
/// open it with `FlareBottomSheet.show(fill: true)` and the sheet's title is
/// the accessible name only, the rows taking the remaining height.
///
/// A host that lets the kit page the list passes a [FlareReadReceiptListState]
/// to [FlareReadReceiptSheet.list] instead of the columns and their marks.
class FlareReadReceiptSheet extends StatefulWidget
    implements FlareSheetOwnHeader {
  const FlareReadReceiptSheet({
    super.key,
    required this.readers,
    required this.unread,
    this.readCount,
    this.unreadCount,
    this.state = FlareReadReceiptState.ready,
    this.readHasMore = false,
    this.unreadHasMore = false,
    this.loadingMore,
    this.loadMoreFailed,
    this.initialTab = FlareReadReceiptColumn.read,
    this.dismissible = false,
    this.onSelect,
    this.onClose,
    this.onLoadMore,
    this.onRetry,
  }) : list = null;

  /// The sheet over the list [list] keeps (`spec/read-receipt-list-vectors.json`):
  /// its columns, state and paging come from the holder, and its load-more and
  /// retry keys ask the holder; [readCount] / [unreadCount] stay the
  /// message's summary counts. Until the holder has opened a message the
  /// sheet reads as loading.
  const FlareReadReceiptSheet.list({
    super.key,
    required FlareReadReceiptListState this.list,
    this.readCount,
    this.unreadCount,
    this.initialTab = FlareReadReceiptColumn.read,
    this.dismissible = false,
    this.onSelect,
    this.onClose,
  }) : readers = const [],
       unread = const [],
       state = FlareReadReceiptState.loading,
       readHasMore = false,
       unreadHasMore = false,
       loadingMore = null,
       loadMoreFailed = null,
       onLoadMore = null,
       onRetry = null;

  /// The paging holder of [FlareReadReceiptSheet.list]; null otherwise.
  final FlareReadReceiptListState? list;

  /// Members of the read column loaded so far.
  final List<FlareContact> readers;

  /// Members of the unread column loaded so far.
  final List<FlareContact> unread;

  /// The summary's read count: the read tab's number. Null: no number.
  final int? readCount;

  /// The summary's unread count: the unread tab's number. Null: no number.
  final int? unreadCount;
  final FlareReadReceiptState state;
  final bool readHasMore;
  final bool unreadHasMore;

  /// The column whose next page is being read.
  final FlareReadReceiptColumn? loadingMore;

  /// The column whose last next-page read failed.
  final FlareReadReceiptColumn? loadMoreFailed;

  /// The column shown first.
  final FlareReadReceiptColumn initialTab;

  /// Draws a close key at the end of the title row.
  final bool dismissible;
  final void Function(String id)? onSelect;
  final VoidCallback? onClose;

  /// A column's next page, from its load-more or retry key.
  final ValueChanged<FlareReadReceiptColumn>? onLoadMore;

  /// The error state's retry key.
  final VoidCallback? onRetry;

  /// Keys for tests and hosts.
  static Key tabKey(FlareReadReceiptColumn column) =>
      ValueKey('flare-read-receipt-tab-${column.name}');
  static Key rowKey(String id) => ValueKey('flare-read-receipt-row-$id');
  static const Key spinnerKey = ValueKey('flare-read-receipt-spinner');
  static const Key errorKey = ValueKey('flare-read-receipt-error');
  static const Key retryKey = ValueKey('flare-read-receipt-retry');
  static const Key unavailableKey = ValueKey('flare-read-receipt-unavailable');
  static const Key emptyKey = ValueKey('flare-read-receipt-empty');
  static const Key tailKey = ValueKey('flare-read-receipt-tail');
  static const Key shellKey = ValueKey('flare-read-receipt-shell');

  /// The width of the shell standing alone, and the height its rows scroll in.
  static const double maxCardExtent = 320;

  @override
  State<FlareReadReceiptSheet> createState() => _FlareReadReceiptSheetState();
}

class _FlareReadReceiptSheetState extends State<FlareReadReceiptSheet> {
  late FlareReadReceiptColumn _active = widget.initialTab;

  /// The holder's list, loading until it opened a message; null without one.
  FlareReadReceiptPages? get _pages {
    final list = widget.list;
    if (list == null) return null;
    return list.pages ??
        const FlareReadReceiptPages(state: FlareReadReceiptState.loading);
  }

  List<FlareContact> get _readers => _pages?.read.people ?? widget.readers;
  List<FlareContact> get _unread => _pages?.unread.people ?? widget.unread;
  FlareReadReceiptState get _state => _pages?.state ?? widget.state;

  ValueChanged<FlareReadReceiptColumn>? get _onLoadMore {
    final list = widget.list;
    if (list == null) return widget.onLoadMore;
    return (column) => unawaited(list.loadMore(column));
  }

  VoidCallback? get _onRetry {
    final list = widget.list;
    if (list == null) return widget.onRetry;
    return () => unawaited(list.retry());
  }

  List<FlareContact> get _list =>
      _active == FlareReadReceiptColumn.read ? _readers : _unread;

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    if (list == null) return _sheet(context);
    return ListenableBuilder(
      listenable: list,
      builder: (context, _) => _sheet(context),
    );
  }

  Widget _sheet(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final layout = flareReadReceiptLayout(
      state: _state,
      active: _active,
      readers: _readers.length,
      unread: _unread.length,
      readCount: widget.readCount,
      unreadCount: widget.unreadCount,
      readHasMore: _pages?.read.hasMore ?? widget.readHasMore,
      unreadHasMore: _pages?.unread.hasMore ?? widget.unreadHasMore,
      loadingMore: _pages == null ? widget.loadingMore : _pages!.loadingMore,
      loadMoreFailed: _pages == null
          ? widget.loadMoreFailed
          : _pages!.loadMoreFailed,
    );
    final onSurface = FlareOverlaySurface.maybeOf(context) != null;
    final body = _body(colors, strings, layout, onSurface: onSurface);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(colors, strings),
        if (layout.tabs case final tabs?) _tabs(colors, strings, tabs),
        Flexible(child: body),
      ],
    );
    if (onSurface) return column;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(
                0.0,
                FlareReadReceiptSheet.maxCardExtent,
              )
            : FlareReadReceiptSheet.maxCardExtent;
        return Align(
          alignment: AlignmentDirectional.topStart,
          widthFactor: 1,
          heightFactor: 1,
          child: Container(
            key: FlareReadReceiptSheet.shellKey,
            width: width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.bgPrimary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
              border: Border.all(color: colors.borderPrimary),
              boxShadow: FlareShadows.of(Theme.of(context).brightness).lg,
            ),
            child: column,
          ),
        );
      },
    );
  }

  Widget _header(FlareColors colors, FlareStrings strings) {
    return Padding(
      // The close control is a touch target tall; it takes the place of the
      // vertical padding instead of adding to it.
      padding: EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        widget.dismissible ? 0 : FlareSizes.spacingMd,
        FlareSizes.spacingSm,
        widget.dismissible ? 0 : FlareSizes.spacingMd,
      ),
      child: Row(
        children: [
          FlareIcon('read', size: 18, color: colors.primaryText),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                strings.readReceipt,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeXl,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.dismissible)
            FlareIconControl(
              label: strings.close,
              onTap: widget.onClose,
              alignment: AlignmentDirectional.centerEnd,
              child: FlareIcon('close', size: 18, color: colors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _tabs(
    FlareColors colors,
    FlareStrings strings,
    List<FlareReadReceiptTab> tabs,
  ) {
    String label(FlareReadReceiptTab tab) => switch ((tab.column, tab.count)) {
      (FlareReadReceiptColumn.read, final int count) => strings.readTab(count),
      (FlareReadReceiptColumn.read, null) => strings.readReceiptRead,
      (FlareReadReceiptColumn.unread, final int count) => strings.unreadTab(
        count,
      ),
      (FlareReadReceiptColumn.unread, null) => strings.readReceiptUnread,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderPrimary)),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            _tab(
              colors,
              tab.column,
              label(tab),
              _active == tab.column,
              () => setState(() => _active = tab.column),
            ),
        ],
      ),
    );
  }

  Widget _tab(
    FlareColors colors,
    FlareReadReceiptColumn column,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          key: FlareReadReceiptSheet.tabKey(column),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? colors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? colors.primaryText : colors.textSecondary,
                fontSize: FlareSizes.fontSizeMd,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    FlareColors colors,
    FlareStrings strings,
    FlareReadReceiptLayout layout, {
    required bool onSurface,
  }) {
    switch (layout.body) {
      case FlareReadReceiptBody.spinner:
        return Padding(
          key: FlareReadReceiptSheet.spinnerKey,
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: SizedBox.square(
              dimension: FlareSizes.iconSizeLg,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ),
        );
      case FlareReadReceiptBody.error:
        return _notice(
          colors,
          key: FlareReadReceiptSheet.errorKey,
          text: strings.readReceiptLoadFailed,
          action: FlareButton(
            key: FlareReadReceiptSheet.retryKey,
            label: strings.retry,
            variant: FlareButtonVariant.secondary,
            size: FlareControlSize.sm,
            onPressed: _onRetry,
          ),
        );
      case FlareReadReceiptBody.unavailable:
        return _notice(
          colors,
          key: FlareReadReceiptSheet.unavailableKey,
          text: strings.readReceiptUnavailable,
        );
      case FlareReadReceiptBody.empty:
        return _notice(
          colors,
          key: FlareReadReceiptSheet.emptyKey,
          text: _active == FlareReadReceiptColumn.read
              ? strings.noReadersYet
              : strings.everyoneHasRead,
        );
      case FlareReadReceiptBody.list:
        final list = _list;
        final tail = _tail(colors, strings, layout);
        final rows = ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
          children: [for (final contact in list) _row(colors, contact), ?tail],
        );
        // Standing alone the rows scroll within the card's extent; on a kit
        // surface they take the height the surface leaves.
        return onSurface
            ? rows
            : ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: FlareReadReceiptSheet.maxCardExtent,
                ),
                child: rows,
              );
    }
  }

  Widget? _tail(
    FlareColors colors,
    FlareStrings strings,
    FlareReadReceiptLayout layout,
  ) {
    final column = _active;
    switch (layout.tail) {
      case FlareReadReceiptTail.none:
        return null;
      case FlareReadReceiptTail.busy:
        return Padding(
          key: FlareReadReceiptSheet.tailKey,
          padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
          child: Center(
            child: SizedBox.square(
              dimension: FlareSizes.iconSizeMd,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ),
        );
      case FlareReadReceiptTail.loadMore:
      case FlareReadReceiptTail.retry:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingLg),
          child: FlareButton(
            key: FlareReadReceiptSheet.tailKey,
            label: layout.tail == FlareReadReceiptTail.retry
                ? strings.readReceiptLoadMoreFailed
                : strings.readReceiptLoadMore,
            variant: FlareButtonVariant.quiet,
            size: FlareControlSize.sm,
            block: true,
            onPressed: _onLoadMore == null
                ? null
                : () => _onLoadMore!(column),
          ),
        );
    }
  }

  Widget _notice(
    FlareColors colors, {
    required Key key,
    required String text,
    Widget? action,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: FlareSizes.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: FlareSizes.fontSizeMd,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            action,
          ],
        ],
      ),
    );
  }

  Widget _row(FlareColors colors, FlareContact c) {
    return InkWell(
      key: FlareReadReceiptSheet.rowKey(c.id),
      onTap: widget.onSelect == null ? null : () => widget.onSelect!(c.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg,
          vertical: FlareSizes.spacingSm,
        ),
        child: Row(
          children: [
            FlareAvatar(
              userId: c.id,
              displayName: c.name,
              avatarUrl: c.avatarUrl,
              size: 36,
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeLg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
