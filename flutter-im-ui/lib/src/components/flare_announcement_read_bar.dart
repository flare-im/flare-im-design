import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Group-announcement read bar — confirm while unread, x/y read once confirmed.
///
/// [readCount] and [memberCount] must be the server's own counts. The unread
/// member list that ships alongside them is truncated (the server caps it), so
/// deriving a count from its length silently under-reports in large groups —
/// a wrong number that never raises an error.
/// Spec: General/AnnouncementReadBar (`FlareAnnouncementReadBar`).
class FlareAnnouncementReadBar extends StatelessWidget {
  const FlareAnnouncementReadBar({
    super.key,
    required this.readCount,
    required this.memberCount,
    required this.selfRead,
    this.canViewUnread = false,
    this.labels = const FlareAnnouncementReadLabels(),
    this.onConfirm,
    this.onViewUnread,
  });

  final int readCount;
  final int memberCount;
  final bool selfRead;

  /// Show the view-unread entry — typically admins only.
  final bool canViewUnread;
  final FlareAnnouncementReadLabels labels;
  final VoidCallback? onConfirm;
  final VoidCallback? onViewUnread;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    // Counts are hidden until the data lands, so "0/0" never flashes.
    final showCount = memberCount > 0;
    final allRead = memberCount > 0 && readCount >= memberCount;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      ),
      child: Row(
        children: [
          Icon(selfRead ? Icons.check_circle : Icons.campaign_outlined,
              size: 16,
              color: selfRead ? colors.textTertiary : colors.textSecondary),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: showCount
                ? Text(labels.readCount(readCount, memberCount),
                    style: TextStyle(
                        color: selfRead ? colors.textTertiary : colors.textSecondary,
                        fontSize: FlareSizes.fontSizeMd))
                : const SizedBox.shrink(),
          ),
          if (!selfRead)
            FilledButton.tonal(
              onPressed: onConfirm,
              child: Text(labels.confirmRead),
            ),
          if (canViewUnread && !allRead)
            TextButton(
              onPressed: onViewUnread,
              child: Text(labels.viewUnread),
            ),
        ],
      ),
    );
  }
}

/// Copy for [FlareAnnouncementReadBar].
class FlareAnnouncementReadLabels {
  const FlareAnnouncementReadLabels({
    this.confirmRead = '已读',
    this.viewUnread = '查看未读',
    this.readCount = _defaultReadCount,
  });

  final String confirmRead;
  final String viewUnread;

  /// Formats the x/y line. A callback rather than a template string so locales
  /// that reorder or pluralise the counts can express it.
  final String Function(int read, int total) readCount;

  static String _defaultReadCount(int read, int total) => '$read/$total 人已读';
}
