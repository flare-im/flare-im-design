import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_tokens.dart';

/// Actions a [FlareConversationActionSheet] can emit. Names match the
/// cross-platform contract (Vue `action` payload / SwiftUI / Compose enums).
enum FlareConversationAction {
  pin,
  unpin,
  mute,
  unmute,
  markRead,
  archive,
  unarchive,
  hide,
  delete,
}

/// Snapshot of the conversation the sheet acts on; [id] must be stable.
@immutable
class FlareConversationActionSnapshot {
  const FlareConversationActionSnapshot({
    required this.id,
    required this.title,
    this.pinned = false,
    this.muted = false,
    this.unreadCount = 0,
    this.archived = false,
  });
  final String id;
  final String title;
  final bool pinned;
  final bool muted;
  final int unreadCount;
  final bool archived;
}

/// Capabilities the host can honour. `false` → the action is not rendered.
@immutable
class FlareConversationActionCapabilities {
  const FlareConversationActionCapabilities({
    this.pin = false,
    this.mute = false,
    this.markRead = false,
    this.archive = false,
    this.delete = false,
    this.hide = false,
  });
  final bool pin, mute, markRead, archive, delete, hide;
}

/// One displayable entry; [danger] entries render in the trailing group.
@immutable
class FlareConversationActionEntry {
  const FlareConversationActionEntry(this.action, {this.danger = false});
  final FlareConversationAction action;
  final bool danger;
}

/// Ordered, displayable actions — the same rule set as the other platforms:
/// pin/unpin, mute/unmute, archive/unarchive invert by state; markRead only
/// with unread > 0; delete always last and flagged danger.
List<FlareConversationActionEntry> conversationActions(
  FlareConversationActionSnapshot conversation,
  FlareConversationActionCapabilities capabilities,
) {
  final out = <FlareConversationActionEntry>[];
  if (capabilities.pin) {
    out.add(FlareConversationActionEntry(conversation.pinned
        ? FlareConversationAction.unpin
        : FlareConversationAction.pin));
  }
  if (capabilities.mute) {
    out.add(FlareConversationActionEntry(conversation.muted
        ? FlareConversationAction.unmute
        : FlareConversationAction.mute));
  }
  if (capabilities.markRead && conversation.unreadCount > 0) {
    out.add(const FlareConversationActionEntry(FlareConversationAction.markRead));
  }
  if (capabilities.archive) {
    out.add(FlareConversationActionEntry(conversation.archived
        ? FlareConversationAction.unarchive
        : FlareConversationAction.archive));
  }
  if (capabilities.hide) {
    out.add(const FlareConversationActionEntry(FlareConversationAction.hide));
  }
  if (capabilities.delete) {
    out.add(const FlareConversationActionEntry(FlareConversationAction.delete,
        danger: true));
  }
  return out;
}

/// Conversation action menu — the body of a long-press / "more" sheet for ONE
/// conversation. Owns no positioning: place it in `showModalBottomSheet` or a
/// popover. Spec: Conversation/ConversationActionSheet.
class FlareConversationActionSheet extends StatelessWidget {
  const FlareConversationActionSheet({
    super.key,
    required this.conversation,
    this.capabilities = const FlareConversationActionCapabilities(),
    this.busy = false,
    this.pinText = '置顶',
    this.unpinText = '取消置顶',
    this.muteText = '免打扰',
    this.unmuteText = '取消免打扰',
    this.markReadText = '标为已读',
    this.archiveText = '归档',
    this.unarchiveText = '取消归档',
    this.hideText = '隐藏',
    this.deleteText = '删除',
    this.emptyText = '暂无可用操作',
    this.onAction,
    this.onClose,
  });

  final FlareConversationActionSnapshot conversation;
  final FlareConversationActionCapabilities capabilities;

  /// Host sets this synchronously before dispatching; disables every row.
  final bool busy;
  final String pinText,
      unpinText,
      muteText,
      unmuteText,
      markReadText,
      archiveText,
      unarchiveText,
      hideText,
      deleteText,
      emptyText;
  final void Function(String id, FlareConversationAction action)? onAction;
  final VoidCallback? onClose;

  String labelFor(FlareConversationAction action) => switch (action) {
        FlareConversationAction.pin => pinText,
        FlareConversationAction.unpin => unpinText,
        FlareConversationAction.mute => muteText,
        FlareConversationAction.unmute => unmuteText,
        FlareConversationAction.markRead => markReadText,
        FlareConversationAction.archive => archiveText,
        FlareConversationAction.unarchive => unarchiveText,
        FlareConversationAction.hide => hideText,
        FlareConversationAction.delete => deleteText,
      };

  static IconData _iconFor(FlareConversationAction action) => switch (action) {
        FlareConversationAction.pin ||
        FlareConversationAction.unpin =>
          Icons.push_pin_outlined,
        FlareConversationAction.mute => Icons.notifications_off_outlined,
        FlareConversationAction.unmute => Icons.notifications_outlined,
        FlareConversationAction.markRead => Icons.done_all,
        FlareConversationAction.archive => Icons.archive_outlined,
        FlareConversationAction.unarchive => Icons.unarchive_outlined,
        FlareConversationAction.hide => Icons.visibility_off_outlined,
        FlareConversationAction.delete => Icons.delete_outline,
      };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final entries = conversationActions(conversation, capabilities);
    final primary = entries.where((e) => !e.danger).toList();
    final danger = entries.where((e) => e.danger).toList();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => onClose?.call(),
      },
      child: FocusTraversalGroup(
        child: Semantics(
          container: true,
          label: conversation.title,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingSm,
                vertical: FlareSizes.spacingXs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingMd,
                      vertical: FlareSizes.spacingXs,
                    ),
                    child: Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(FlareSizes.spacingMd),
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FlareSizes.fontSizeLg,
                        ),
                      ),
                    ),
                  if (primary.isNotEmpty) _group(primary, colors, danger: false),
                  if (danger.isNotEmpty) ...[
                    const SizedBox(height: FlareSizes.spacingSm),
                    _group(danger, colors, danger: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(
    List<FlareConversationActionEntry> entries,
    FlareColors colors, {
    required bool danger,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radius2xl),
        border: danger
            ? Border(top: BorderSide(color: colors.borderSecondary))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingXs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final e in entries) _row(e, colors)],
      ),
    );
  }

  Widget _row(FlareConversationActionEntry entry, FlareColors colors) {
    final enabled = !busy && onAction != null;
    final accent = entry.danger ? colors.error : colors.primary;
    final fg = enabled
        ? (entry.danger ? colors.error : colors.textPrimary)
        : colors.textDisabled;
    final iconFg = enabled ? accent : colors.textDisabled;
    final iconBg = enabled
        ? accent.withValues(alpha: entry.danger ? 0.12 : 0.10)
        : colors.bgDisabled;
    final label = labelFor(entry.action);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled ? () => onAction!(conversation.id, entry.action) : null,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        hoverColor: colors.bgHover,
        focusColor: colors.bgHover,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd,
              vertical: FlareSizes.spacingSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(_iconFor(entry.action), size: 20, color: iconFg),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: FlareSizes.fontSize2xl,
                      fontWeight: FontWeight.w600,
                      height: FlareSizes.lineHeightTight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
