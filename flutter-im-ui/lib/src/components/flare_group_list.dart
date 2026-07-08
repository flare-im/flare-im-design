import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_empty_state.dart';

/// My groups — group avatar, name, member count.
/// Spec: Contacts/GroupList (`FlareGroupList`).
class FlareGroupList extends StatelessWidget {
  const FlareGroupList({super.key, required this.items, this.onSelect});

  final List<FlareGroupSummary> items;
  final ValueChanged<FlareGroupSummary>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    if (items.isEmpty) return const FlareEmptyState(title: 'No groups yet');
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final g = items[i];
        return InkWell(
          onTap: onSelect == null ? null : () => onSelect!(g),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
            child: Row(
              children: [
                FlareAvatar(userId: g.id, displayName: g.name, avatarUrl: g.avatarUrl, size: 44),
                const SizedBox(width: FlareSizes.spacingMd),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(g.name,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: FlareSizes.fontSizeXl,
                            fontWeight: FontWeight.w500)),
                    Text('${g.memberCount} members',
                        style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: FlareSizes.fontSizeSm)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
