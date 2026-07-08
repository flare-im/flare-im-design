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
