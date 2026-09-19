import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

/// Actions a [FlareConversationActionSheet] can emit. Names match the
/// cross-platform contract (Vue `action` payload / SwiftUI / Compose enums).
enum FlareConversationAction {
  pin,
  unpin,
  mute,
  unmute,
  markRead,
  markUnread,
  archive,
  unarchive,
  hide,
  clearHistory,
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
    this.markUnread = false,
    this.archive = false,
    this.hide = false,
    this.clearHistory = false,
    this.delete = false,
  });
  final bool pin,
      mute,
      markRead,
      markUnread,
      archive,
      hide,
      clearHistory,
      delete;
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
/// with unread > 0 and markUnread only without; clearHistory and delete close
/// the list in the danger group.
List<FlareConversationActionEntry> conversationActions(
  FlareConversationActionSnapshot conversation,
  FlareConversationActionCapabilities capabilities,
) {
  final out = <FlareConversationActionEntry>[];
  if (capabilities.pin) {
    out.add(
      FlareConversationActionEntry(
        conversation.pinned
            ? FlareConversationAction.unpin
            : FlareConversationAction.pin,
      ),
    );
  }
  if (capabilities.mute) {
    out.add(
      FlareConversationActionEntry(
        conversation.muted
            ? FlareConversationAction.unmute
            : FlareConversationAction.mute,
      ),
    );
  }
  if (conversation.unreadCount > 0) {
    if (capabilities.markRead) {
      out.add(
        const FlareConversationActionEntry(FlareConversationAction.markRead),
      );
    }
  } else if (capabilities.markUnread) {
    out.add(
      const FlareConversationActionEntry(FlareConversationAction.markUnread),
    );
  }
  if (capabilities.archive) {
    out.add(
      FlareConversationActionEntry(
        conversation.archived
            ? FlareConversationAction.unarchive
            : FlareConversationAction.archive,
      ),
    );
  }
  if (capabilities.hide) {
    out.add(const FlareConversationActionEntry(FlareConversationAction.hide));
  }
  if (capabilities.clearHistory) {
    out.add(
      const FlareConversationActionEntry(
        FlareConversationAction.clearHistory,
        danger: true,
      ),
    );
  }
  if (capabilities.delete) {
    out.add(
      const FlareConversationActionEntry(
        FlareConversationAction.delete,
        danger: true,
      ),
    );
  }
  return out;
}

/// Conversation action menu — the body of a long-press / "more" sheet for ONE
/// conversation. Owns no positioning: present it with `FlareBottomSheet.show`
/// or in a popover. Spec: Conversation/ConversationActionSheet.
class FlareConversationActionSheet extends StatelessWidget {
  const FlareConversationActionSheet({
    super.key,
    required this.conversation,
    this.capabilities = const FlareConversationActionCapabilities(),
    this.busy = false,
    this.pinText,
    this.unpinText,
    this.muteText,
    this.unmuteText,
    this.markReadText,
    this.archiveText,
    this.unarchiveText,
    this.hideText,
    this.deleteText,
    this.emptyText,
    this.onAction,
    this.onClose,
  });

  final FlareConversationActionSnapshot conversation;
  final FlareConversationActionCapabilities capabilities;

  /// Host sets this synchronously before dispatching; disables every row.
  final bool busy;

  /// Label overrides; null falls back to `FlareStrings`
  /// (`conversationActionSheet*`, `delete`). Mark-as-unread and clear-history
  /// read the strings table only, as on Vue.
  final String? pinText,
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

  /// The label [action] shows: its text parameter when given, else [strings]
  /// (the ambient `FlareStrings.of(context)` when the sheet builds).
  String labelFor(
    FlareConversationAction action, [
    FlareStrings strings = const FlareStrings(),
  ]) => switch (action) {
    FlareConversationAction.pin =>
      pinText ?? strings.conversationActionSheetPin,
    FlareConversationAction.unpin =>
      unpinText ?? strings.conversationActionSheetUnpin,
    FlareConversationAction.mute =>
      muteText ?? strings.conversationActionSheetMute,
    FlareConversationAction.unmute =>
      unmuteText ?? strings.conversationActionSheetUnmute,
    FlareConversationAction.markRead =>
      markReadText ?? strings.conversationActionSheetMarkRead,
    FlareConversationAction.markUnread =>
      strings.conversationActionSheetMarkUnread,
    FlareConversationAction.archive =>
      archiveText ?? strings.conversationActionSheetArchive,
    FlareConversationAction.unarchive =>
      unarchiveText ?? strings.conversationActionSheetUnarchive,
    FlareConversationAction.hide =>
      hideText ?? strings.conversationActionSheetHide,
    FlareConversationAction.clearHistory =>
      strings.conversationActionSheetClearHistory,
    FlareConversationAction.delete => deleteText ?? strings.delete,
  };

  static IconData iconFor(FlareConversationAction action) =>
      flareIconGlyph(switch (action) {
        FlareConversationAction.pin => 'pin',
        FlareConversationAction.unpin => 'unpin',
        FlareConversationAction.mute => 'mute',
        FlareConversationAction.unmute => 'notification',
        FlareConversationAction.markRead => 'read',
        FlareConversationAction.markUnread => 'mark-unread',
        FlareConversationAction.archive => 'archive',
        FlareConversationAction.unarchive => 'unarchive',
        FlareConversationAction.hide => 'eye-off',
        FlareConversationAction.clearHistory => 'clear-history',
        FlareConversationAction.delete => 'delete',
      });

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
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
                        emptyText ?? strings.conversationActionSheetEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FlareSizes.fontSizeLg,
                        ),
                      ),
                    ),
                  if (primary.isNotEmpty)
                    _group(primary, colors, strings, danger: false),
                  if (danger.isNotEmpty) ...[
                    const SizedBox(height: FlareSizes.spacingSm),
                    _group(danger, colors, strings, danger: true),
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
    FlareColors colors,
    FlareStrings strings, {
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
        children: [for (final e in entries) _row(e, colors, strings)],
      ),
    );
  }

  Widget _row(
    FlareConversationActionEntry entry,
    FlareColors colors,
    FlareStrings strings,
  ) {
    final enabled = !busy && onAction != null;
    final accent = entry.danger ? colors.error : colors.primary;
    final fg = enabled
        ? (entry.danger ? colors.error : colors.textPrimary)
        : colors.textDisabled;
    final iconFg = enabled ? accent : colors.textDisabled;
    final iconBg = enabled
        ? accent.withValues(alpha: entry.danger ? 0.12 : 0.10)
        : colors.bgDisabled;
    final label = labelFor(entry.action, strings);
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
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
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
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconFor(entry.action), size: 20, color: iconFg),
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
