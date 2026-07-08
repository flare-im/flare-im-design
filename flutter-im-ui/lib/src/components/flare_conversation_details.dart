import 'package:flutter/material.dart';

import '../models/conversation_summary.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_message_bubble.dart' show FlareConversationKind;

/// Connection-status tone — spec union `'ok' | 'warn' | 'error'`.
enum FlareConnectionTone { ok, warn, error }

/// The conversation info/settings panel — counts, connection state, and
/// per-conversation actions. Spec: Conversation/ConversationDetails
/// (`FlareConversationDetails`). Pure: raises one callback per action.
class FlareConversationDetails extends StatelessWidget {
  const FlareConversationDetails({
    super.key,
    required this.conversation,
    this.connectionText,
    this.connectionTone = FlareConnectionTone.ok,
    this.messageCount,
    this.onMute,
    this.onPin,
    this.onArchive,
    this.onClearHistory,
    this.onDelete,
    this.onMarkRead,
    this.onMarkUnread,
    this.onSync,
    this.onOpenDevtools,
  });

  final FlareConversationSummary conversation;
  final String? connectionText;
  final FlareConnectionTone connectionTone;
  final int? messageCount;

  final ValueChanged<bool>? onMute;
  final ValueChanged<bool>? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onClearHistory;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onSync;
  final VoidCallback? onOpenDevtools;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final c = conversation;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingLg),
      children: [
        Center(
          child: Column(
            children: [
              FlareAvatar(
                userId: c.id,
                displayName: c.title,
                avatarUrl: c.avatarUrl,
                size: 64,
              ),
              const SizedBox(height: FlareSizes.spacingSm),
              Text(c.title,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSize4xl,
                      fontWeight: FontWeight.w600)),
              if (c.kind == FlareConversationKind.group && c.memberCount != null)
                Text('${c.memberCount} members',
                    style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeSm)),
            ],
          ),
        ),
        const SizedBox(height: FlareSizes.spacingLg),

        if (connectionText != null && connectionText!.isNotEmpty)
          _connectionChip(colors),
        if (messageCount != null)
          _infoRow('Messages', '$messageCount', colors),

        _sectionGap(colors),
        if (onMute != null)
          _switchRow('Mute', Icons.notifications_off_outlined, c.muted,
              onMute!, colors),
        if (onPin != null)
          _switchRow('Pin conversation', Icons.push_pin_outlined, c.pinned, onPin!, colors),

        _sectionGap(colors),
        if (onMarkRead != null)
          _actionRow('Mark as read', Icons.mark_email_read_outlined, onMarkRead!, colors),
        if (onMarkUnread != null)
          _actionRow('Mark as unread', Icons.mark_email_unread_outlined, onMarkUnread!,
              colors),
        if (onSync != null)
          _actionRow('Sync conversation', Icons.sync_rounded, onSync!, colors),
        if (onOpenDevtools != null)
          _actionRow('Developer tools', Icons.bug_report_outlined, onOpenDevtools!, colors),

        _sectionGap(colors),
        if (onArchive != null)
          _actionRow(c.archived ? 'Unarchive' : 'Archive conversation', Icons.archive_outlined,
              onArchive!, colors),
        if (onClearHistory != null)
          _actionRow('Clear chat history', Icons.cleaning_services_outlined,
              onClearHistory!, colors),
        if (onDelete != null)
          _actionRow('Delete conversation', Icons.delete_outline, onDelete!, colors,
              danger: true),
      ],
    );
  }

  Widget _connectionChip(FlareColors colors) {
    final tone = switch (connectionTone) {
      FlareConnectionTone.ok => colors.success,
      FlareConnectionTone.warn => colors.warning,
      FlareConnectionTone.error => colors.error,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingXs),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
          const SizedBox(width: FlareSizes.spacingSm),
          Text(connectionText!,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: FlareSizes.fontSizeMd)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: colors.textSecondary, fontSize: FlareSizes.fontSizeLg)),
          Text(value,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
        ],
      ),
    );
  }

  Widget _switchRow(String label, IconData icon, bool value,
      ValueChanged<bool> onChanged, FlareColors colors) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: colors.primary,
      secondary: Icon(icon, color: colors.textSecondary),
      title: Text(label,
          style: TextStyle(
              color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
    );
  }

  Widget _actionRow(String label, IconData icon, VoidCallback onTap,
      FlareColors colors,
      {bool danger = false}) {
    final color = danger ? colors.error : colors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: danger ? colors.error : colors.textSecondary),
      title: Text(label,
          style: TextStyle(color: color, fontSize: FlareSizes.fontSizeLg)),
      onTap: onTap,
    );
  }

  Widget _sectionGap(FlareColors colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
        child: Divider(height: 1, color: colors.borderSecondary),
      );
}
