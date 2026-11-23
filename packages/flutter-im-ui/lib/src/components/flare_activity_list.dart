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

/// [compact] rows (avatar 32, tighter padding) suit an inbox in a side panel.
/// While [disabled] the rows are inert (a read or an acknowledgement is under
/// way). The empty state takes an optional [emptyDescription] and one action
/// ([emptyActionText] / [onEmptyAction]).
class FlareActivityList extends StatelessWidget {
  const FlareActivityList({
    super.key,
    required this.items,
    required this.emptyText,
    this.emptyDescription,
    this.emptyActionText,
    this.onEmptyAction,
    this.onSelect,
    this.footer,
    this.compact = false,
    this.disabled = false,
  });
  final List<FlareActivityItem> items;
  final String emptyText;
  final String? emptyDescription;
  final String? emptyActionText;
  final VoidCallback? onEmptyAction;
  final ValueChanged<String>? onSelect;
  final Widget? footer;
  final bool compact;
  final bool disabled;
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
          if (items.isEmpty && index == 0) {
            return FlareEmptyState(
              title: emptyText,
              description: emptyDescription,
              actionText: emptyActionText,
              onAction: onEmptyAction,
            );
          }
          if (index >= items.length) return footer!;
          final item = items[index];
          final select = disabled ? null : onSelect;
          return Semantics(
            button: onSelect != null,
            enabled: select != null,
            label: item.unread
                ? '${item.title}, ${FlareStrings.of(context).unreadTab(1)}'
                : item.title,
            child: InkWell(
              onTap: select == null ? null : () => select(item.id),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? FlareSizes.spacingMd : FlareSizes.spacingLg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlareAvatar(
                      userId: item.id,
                      displayName: item.title,
                      avatarUrl: item.avatarUrl,
                      size: compact ? 32 : FlareSizes.avatarSize,
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
