import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_empty_state.dart';

/// My groups — group avatar, name, member count.
/// Spec: Contacts/GroupList (`FlareGroupList`). [activeId] marks the group a
/// neighbouring pane is showing, as [FlareContactList.activeId] does.
class FlareGroupList extends StatelessWidget {
  const FlareGroupList({
    super.key,
    required this.items,
    this.onSelect,
    this.emptyText = '暂无群聊',
    this.empty,
    this.memberCountText,
    this.activeId,
  });

  final List<FlareGroupSummary> items;
  final ValueChanged<FlareGroupSummary>? onSelect;
  final String emptyText;

  /// Replaces the kit empty state when the list is empty for a reason only the host knows
  /// (a failed load with a way back, an invitation to create the first group).
  final Widget? empty;

  /// Formats the member-count subtitle (defaults to "N 名成员").
  final String Function(int count)? memberCountText;
  final String? activeId;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    if (items.isEmpty) {
      // Scrollable even with nothing in it, so a pull to refresh above still reaches the host.
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: empty ?? Center(child: FlareEmptyState(title: emptyText)),
            ),
          ],
        ),
      );
    }
    // The kit is also hosted by Cupertino-style app shells. InkWell still needs
    // a Material paint target there, so provide the smallest possible one inside
    // the reusable component instead of making every host wrap this list.
    return Material(
      type: MaterialType.transparency,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final g = items[i];
          final current = activeId == g.id;
          return InkWell(
            onTap: onSelect == null ? null : () => onSelect!(g),
            // Vue `.flare-group-list__row`: no chevron; the current row is
            // tinted with a 3px primary bar at its start.
            child: Ink(
              decoration: current
                  ? BoxDecoration(
                      color: colors.bgSelected,
                      border: BorderDirectional(
                        start: BorderSide(color: colors.primary, width: 3),
                      ),
                    )
                  : null,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  current ? FlareSizes.spacing2md - 3 : FlareSizes.spacing2md,
                  FlareSizes.spacingSm,
                  FlareSizes.spacing2md,
                  FlareSizes.spacingSm,
                ),
                child: Row(
                  children: [
                    FlareAvatar(
                      userId: g.id,
                      displayName: g.name,
                      avatarUrl: g.avatarUrl,
                      size: 40,
                    ),
                    const SizedBox(width: FlareSizes.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            g.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: current
                                  ? colors.primaryText
                                  : colors.textPrimary,
                              fontSize: FlareSizes.fontSizeLg,
                              fontWeight: current
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            memberCountText?.call(g.memberCount) ??
                                strings.memberCount(g.memberCount),
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                        ],
                      ),
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
