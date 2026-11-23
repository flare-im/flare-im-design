import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_button.dart';
import 'flare_empty_state.dart';
import 'flare_status_banner.dart';

/// New friends — incoming requests with accept / reject, and the current
/// user's outgoing requests with their pending status and, when [onWithdraw]
/// is given, a withdraw action. Labels default to [FlareStrings].
/// Spec: Contacts/NewFriendRequests (`FlareNewFriendRequests`).
///
/// Row status is the host's, per request id: [pendingActions] puts a spinner
/// on the key being carried out and disables both keys of that row only (one
/// request in flight never disables the others); [errors] draws a danger
/// banner under the row, with a retry key while the row is idle and
/// [onRetry] is handled.
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
    this.pendingActions = const {},
    this.errors = const {},
    this.onRetry,
    this.empty,
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

  /// Request id → the action in flight (`accept` or `reject`).
  final Map<String, FlareFriendRequestAction> pendingActions;

  /// Request id → why its last action failed.
  final Map<String, String> errors;
  final ValueChanged<FlareFriendRequest>? onRetry;

  /// Replaces the kit empty state, for an empty list only the host can explain
  /// (a search with no match, an invitation to add someone).
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    if (items.isEmpty) {
      return empty ??
          FlareEmptyState(title: emptyText ?? strings.newFriendRequestsEmpty);
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final r = items[i];
        final pending = pendingActions[r.id];
        final error = errors[r.id];
        final row = Padding(
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
                size: 40,
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
                      // 来源是另一件事:自己一行,不和验证消息挤在一行。
                      if (r.source != null && r.source!.isNotEmpty)
                        Text(
                          r.source!,
                          key: ValueKey('flare-friend-request-source-${r.id}'),
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
                  FlareButton(
                    label: withdrawLabel ?? strings.newFriendRequestsWithdraw,
                    variant: FlareButtonVariant.quiet,
                    size: FlareControlSize.sm,
                    onPressed: () => onWithdraw!(r),
                  ),
                ],
              ] else ...[
                // 两颗都走 kit 自己的 FlareButton。从前是 Material 的 OutlinedButton +
                // FilledButton —— 拒绝那颗描边按钮和接受那颗填充按钮分量相当,两个都想被点;
                // kit 从前没有「中性的低强度」这一档,现在有了 quiet。
                FlareButton(
                  label: rejectLabel ?? strings.newFriendRequestsReject,
                  variant: FlareButtonVariant.quiet,
                  size: FlareControlSize.sm,
                  loading: pending == FlareFriendRequestAction.reject,
                  disabled: pending != null,
                  onPressed: onReject == null ? null : () => onReject!(r),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                FlareButton(
                  label: acceptLabel ?? strings.newFriendRequestsAccept,
                  size: FlareControlSize.sm,
                  loading: pending == FlareFriendRequestAction.accept,
                  disabled: pending != null,
                  onPressed: onAccept == null ? null : () => onAccept!(r),
                ),
              ],
            ],
          ),
        );
        if (error == null || error.isEmpty) return row;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row,
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingMd,
                0,
                FlareSizes.spacingMd,
                FlareSizes.spacingSm,
              ),
              child: FlareStatusBanner(
                text: error,
                tone: FlareStatusTone.danger,
                actionText: pending == null && onRetry != null
                    ? strings.retry
                    : null,
                onAction: pending == null && onRetry != null
                    ? () => onRetry!(r)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The action a row of [FlareNewFriendRequests] is carrying out.
enum FlareFriendRequestAction { accept, reject }
