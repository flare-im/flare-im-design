import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_empty_state.dart';

/// New friends — incoming friend requests with accept / reject.
/// Spec: Contacts/NewFriendRequests (`FlareNewFriendRequests`).
class FlareNewFriendRequests extends StatelessWidget {
  const FlareNewFriendRequests({
    super.key,
    required this.items,
    this.onAccept,
    this.onReject,
    this.onView,
  });

  final List<FlareFriendRequest> items;
  final ValueChanged<FlareFriendRequest>? onAccept;
  final ValueChanged<FlareFriendRequest>? onReject;
  final ValueChanged<FlareFriendRequest>? onView;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    if (items.isEmpty) {
      return const FlareEmptyState(title: '没有新的好友申请');
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final r = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
          child: Row(
            children: [
              FlareAvatar(userId: r.id, displayName: r.name, avatarUrl: r.avatarUrl, size: 44),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: GestureDetector(
                  onTap: onView == null ? null : () => onView!(r),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.name,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: FlareSizes.fontSizeXl,
                              fontWeight: FontWeight.w500)),
                      if (r.message != null && r.message!.isNotEmpty)
                        Text(r.message!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: FlareSizes.fontSizeSm)),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onReject == null ? null : () => onReject!(r),
                style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact),
                child: const Text('拒绝'),
              ),
              const SizedBox(width: FlareSizes.spacingSm),
              FilledButton(
                onPressed: onAccept == null ? null : () => onAccept!(r),
                style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    visualDensity: VisualDensity.compact),
                child: const Text('接受'),
              ),
            ],
          ),
        );
      },
    );
  }
}
