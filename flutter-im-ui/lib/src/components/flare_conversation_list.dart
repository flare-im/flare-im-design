import 'package:flutter/material.dart';

import '../models/conversation_row_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_conversation_row.dart';

/// The inbox — a virtualised list of [FlareConversationRow]s.
/// Spec: Conversation/ConversationList (`FlareConversationList`).
///
/// Uses [ListView.builder] so rendering is O(visible), never a full re-layout
/// on update (spec requirement). Behaviour/data come from the host, which feeds
/// [items] from `client.views.openConversationList()`.
class FlareConversationList extends StatelessWidget {
  const FlareConversationList({
    super.key,
    required this.items,
    this.activeId,
    this.loading = false,
    this.onSelect,
    this.onLongPress,
    this.onLoadMore,
    this.emptyPlaceholder,
  });

  final List<ConversationRowData> items;

  /// Id of the open conversation (highlighted).
  final String? activeId;

  /// Initial-load spinner (shown only when [items] is empty).
  final bool loading;

  final ValueChanged<ConversationRowData>? onSelect;
  final ValueChanged<ConversationRowData>? onLongPress;

  /// Called once when the list is scrolled near the end (pagination).
  final VoidCallback? onLoadMore;

  /// Shown when there are no items and not loading.
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      if (loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: emptyPlaceholder ?? const _DefaultEmpty(),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (onLoadMore != null &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 240) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return FlareConversationRow(
            item: item,
            active: item.id == activeId,
            onSelect: onSelect == null ? null : () => onSelect!(item),
            onAction: onLongPress == null ? null : () => onLongPress!(item),
          );
        },
      ),
    );
  }
}

/// The inbox as a **sliver**, for hosts that drive their own [CustomScrollView]
/// and want per-row subscriptions: each [rowBuilder] child may be an independent
/// listenable widget, so a single conversation update rebuilds only its row, not
/// the whole list. Standardises the empty / loading sliver treatment; the host
/// keeps ownership of the scroll view, pull-to-refresh and pagination.
///
/// Complements [FlareConversationList] (the self-contained `ListView` variant):
/// reach for this when the surrounding screen is already a sliver scroll view or
/// when the host maps its own store into per-id row widgets for local refresh.
class FlareConversationSliverList extends StatelessWidget {
  const FlareConversationSliverList({
    super.key,
    required this.ids,
    required this.rowBuilder,
    this.loading = false,
    this.emptyPlaceholder,
    this.padding = const EdgeInsets.symmetric(
      horizontal: FlareSizes.spacingLg,
      vertical: FlareSizes.spacingSm,
    ),
  });

  /// Stable ids in display order; the host owns filtering / ordering / sectioning.
  final List<String> ids;

  /// Builds one row for [id]. Return a widget that subscribes to just that
  /// conversation to keep updates O(changed-row).
  final Widget Function(BuildContext context, String id) rowBuilder;

  /// Initial-load spinner (shown only when [ids] is empty).
  final bool loading;

  /// Shown (filling the viewport) when [ids] is empty and not loading. The host
  /// supplies its own layout/padding; falls back to a plain default.
  final Widget? emptyPlaceholder;

  /// Padding around the row list.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : (emptyPlaceholder ?? const Center(child: _DefaultEmpty())),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => rowBuilder(context, ids[index]),
          childCount: ids.length,
        ),
      ),
    );
  }
}

class _DefaultEmpty extends StatelessWidget {
  const _DefaultEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacing2xl),
      child: Text(
        'No conversations',
        style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeLg),
      ),
    );
  }
}
