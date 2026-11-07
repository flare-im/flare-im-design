import 'package:flutter/material.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import '../primitives/flare_unread_badge.dart';
import 'flare_avatar.dart';
import 'flare_empty_state.dart';

/// Presentational notification row; recipients, read state and badge counts
/// come from the host. No business event taxonomy or local read side effects.
class FlareActivityItem {
  const FlareActivityItem({
    required this.id,
    required this.title,
    this.description = '',
    this.time = '',
    this.avatarUrl,
    this.unread = false,
  });
  final String id, title, description, time;
  final String? avatarUrl;
  final bool unread;
}

class FlareActivityList extends StatelessWidget {
  const FlareActivityList({
    super.key,
    required this.items,
    required this.emptyText,
    this.onSelect,
    this.footer,
  });
  final List<FlareActivityItem> items;
  final String emptyText;
  final ValueChanged<String>? onSelect;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Material(
      type: MaterialType.transparency,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            items.length + (footer == null ? 0 : 1) + (items.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (items.isEmpty && index == 0)
            return FlareEmptyState(title: emptyText);
          if (index >= items.length) return footer!;
          final item = items[index];
          return Semantics(
            button: onSelect != null,
            label: item.unread
                ? '${item.title}, ${FlareStrings.of(context).unreadTab(1)}'
                : item.title,
            child: InkWell(
              onTap: onSelect == null ? null : () => onSelect!(item.id),
              child: Padding(
                padding: const EdgeInsets.all(FlareSizes.spacingLg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlareAvatar(
                      userId: item.id,
                      displayName: item.title,
                      avatarUrl: item.avatarUrl,
                      size: FlareSizes.avatarSize,
                    ),
                    const SizedBox(width: FlareSizes.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: item.unread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          if (item.description.isNotEmpty)
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          if (item.time.isNotEmpty)
                            Text(
                              item.time,
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: FlareSizes.fontSizeSm,
                                decoration: TextDecoration.none,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (item.unread)
                      const Padding(
                        padding: EdgeInsets.only(
                          left: FlareSizes.spacingSm,
                          top: FlareSizes.spacingXs,
                        ),
                        child: FlareUnreadBadge(count: 0, dot: true),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
