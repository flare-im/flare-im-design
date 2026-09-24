import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_empty_state.dart';

/// My groups — group avatar, name, member count.
/// Spec: Contacts/GroupList (`FlareGroupList`).
class FlareGroupList extends StatelessWidget {
  const FlareGroupList({
    super.key,
    required this.items,
    this.onSelect,
    this.emptyText = '暂无群聊',
    this.empty,
    this.memberCountText,
  });

  final List<FlareGroupSummary> items;
  final ValueChanged<FlareGroupSummary>? onSelect;
  final String emptyText;

  /// Replaces the kit empty state when the list is empty for a reason only the host knows
  /// (a failed load with a way back, an invitation to create the first group).
  final Widget? empty;

  /// Formats the member-count subtitle (defaults to "N 名成员").
  final String Function(int count)? memberCountText;

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
          return InkWell(
            onTap: onSelect == null ? null : () => onSelect!(g),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd,
                vertical: FlareSizes.spacingSm,
              ),
              child: Row(
                children: [
                  FlareAvatar(
                    userId: g.id,
                    displayName: g.name,
                    avatarUrl: g.avatarUrl,
                    size: 44,
                  ),
                  const SizedBox(width: FlareSizes.spacingMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        g.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
