import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_empty_state.dart';

/// New friends — incoming requests with accept / reject, and the current
/// user's outgoing requests with their pending status and, when [onWithdraw]
/// is given, a withdraw action. Labels default to [FlareStrings].
/// Spec: Contacts/NewFriendRequests (`FlareNewFriendRequests`).
class FlareNewFriendRequests extends StatelessWidget {
  const FlareNewFriendRequests({
    super.key,
    required this.items,
    this.onAccept,
    this.onReject,
    this.onView,
    this.onWithdraw,
    this.emptyText,
    this.acceptLabel,
    this.rejectLabel,
    this.withdrawLabel,
  });

  final List<FlareFriendRequest> items;
  final ValueChanged<FlareFriendRequest>? onAccept;
  final ValueChanged<FlareFriendRequest>? onReject;
  final ValueChanged<FlareFriendRequest>? onView;
  final ValueChanged<FlareFriendRequest>? onWithdraw;
  final String? emptyText;
  final String? acceptLabel;
  final String? rejectLabel;
  final String? withdrawLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    if (items.isEmpty) {
      return FlareEmptyState(
        title: emptyText ?? strings.newFriendRequestsEmpty,
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final r = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingMd,
            vertical: FlareSizes.spacingSm,
          ),
          child: Row(
            children: [
              FlareAvatar(
                userId: r.id,
                displayName: r.name,
                avatarUrl: r.avatarUrl,
                size: 44,
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: GestureDetector(
                  onTap: onView == null ? null : () => onView!(r),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (r.message != null && r.message!.isNotEmpty)
                        Text(
                          r.message!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: FlareSizes.fontSizeSm,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (r.direction == FlareFriendRequestDirection.outgoing) ...[
                Text(
                  strings.newFriendRequestsPending,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
                if (onWithdraw != null) ...[
                  const SizedBox(width: FlareSizes.spacingSm),
                  OutlinedButton(
                    onPressed: () => onWithdraw!(r),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      withdrawLabel ?? strings.newFriendRequestsWithdraw,
                    ),
                  ),
                ],
              ] else ...[
                OutlinedButton(
                  onPressed: onReject == null ? null : () => onReject!(r),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(rejectLabel ?? strings.newFriendRequestsReject),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                FilledButton(
                  onPressed: onAccept == null ? null : () => onAccept!(r),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(acceptLabel ?? strings.newFriendRequestsAccept),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
