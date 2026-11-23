import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/conversation_row_data.dart';
import '../primitives/flare_unread_badge.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import '../models/workspace_layout.dart';
import 'flare_avatar.dart';
import 'flare_conversation_action_sheet.dart';
import 'flare_message_bubble.dart' show FlareConversationKind;
import 'flare_shell_scope.dart';

/// Host-approved swipe intent with its localized label. The kit owns its presentation.
class FlareConversationSwipeAction {
  const FlareConversationSwipeAction(
    this.action,
    this.label, {
    this.enabled = true,
  });
  final FlareConversationAction action;
  final String label;
  final bool enabled;
}

/// Canonical inbox row. SDK commands and action capabilities remain host-owned.
class FlareConversationRow extends StatefulWidget {
  const FlareConversationRow({
    super.key,
    required this.item,
    this.active = false,
    this.avatarSize = FlareSizes.avatarSize,
    this.draftLabel,
    this.mentionLabel,
    this.onSelect,
    this.onLongPress,
    this.onContextMenu,
    this.previewSpansBuilder,
    this.compact,
    this.swipeActions = const [],
    this.onAction,
  });
  final ConversationRowData item;
  final bool active;
  final double avatarSize;

  /// Host override for the draft / mentioned prefix; defaults to `FlareStrings`
  /// (`conversationRowDraft` / `conversationRowMention`), the same fallback the
  /// SwiftUI row uses.
  final String? draftLabel;
  final String? mentionLabel;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;

  /// A secondary click, with the pointer's global position, so the host can
  /// open the menu where the pointer is (Vue's right-click). Without it a
  /// secondary click is a long press.
  final ValueChanged<Offset>? onContextMenu;
  final bool? compact;
  final List<FlareConversationSwipeAction> swipeActions;
  final ValueChanged<FlareConversationAction>? onAction;
  final List<InlineSpan> Function(BuildContext context, TextStyle baseStyle)?
  previewSpansBuilder;

  /// Whether rows under [context] take the list-pane density (Vue desktop row)
  /// rather than the phone's: inside a shell by its mode, else by width.
  static bool denseIn(BuildContext context) {
    final shellMode = FlareShellScope.responsiveModeOf(context);
    return shellMode == null
        ? MediaQuery.sizeOf(context).width >= 1024
        : shellMode != FlareApplicationResponsiveMode.mobile;
  }

  @override
  State<FlareConversationRow> createState() => _FlareConversationRowState();
}

/// The row tracks its own keyboard focus so the box can draw a real 2px ring.
/// The Compose and SwiftUI rows draw one; the Material focus wash this used to
/// rely on is a 35%-alpha tint that reaches ~1.7:1 against the unfocused row,
/// under WCAG 2.4.11's 3:1 floor. The ink well still owns the focus node, so
/// this stays one tab stop.
class _FlareConversationRowState extends State<FlareConversationRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final dense = widget.compact ?? FlareConversationRow.denseIn(context);
    final kind = widget.item.previewKind;
    final mention = (widget.mentionLabel ?? strings.conversationRowMention)
        .trim()
        .replaceAll(RegExp(r'^\[|\]$'), '');
    final prefix = switch (kind) {
      'failed' => '[${strings.messageFailed}] ',
      'draft' => widget.draftLabel ?? strings.conversationRowDraft,
      _ => '',
    };
    final preview = kind == 'draft'
        ? widget.item.draftPreview!.trim()
        : kind == 'typing'
        ? strings.typing
        : widget.item.preview;
    final base = TextStyle(
      fontSize: FlareSizes.fontSizeMd,
      color: colors.textSecondary,
      height: 1.4,
    );
    final spans = <InlineSpan>[
      if (prefix.isNotEmpty)
        TextSpan(
          text: prefix,
          style: TextStyle(
            color: kind == 'draft' ? colors.primaryText : colors.errorText,
          ),
        ),
      ...((kind == 'normal' || kind == 'mention' || kind == 'failed')
          ? widget.previewSpansBuilder?.call(context, base) ??
                [TextSpan(text: preview)]
          : [TextSpan(text: preview)]),
    ];
    final label = [
      widget.item.title,
      if (widget.item.hasUnread) strings.unreadTab(widget.item.unreadCount),
      if (widget.item.mentioned) mention,
      if (widget.item.pinned) strings.conversationActionSheetPin,
      if (widget.item.muted) strings.conversationActionSheetMute,
      '$prefix$preview',
      widget.item.timestampLabel,
    ].where((value) => value.isNotEmpty).join(', ');
    final row = Semantics(
      label: label,
      selected: widget.active,
      button: widget.onSelect != null,
      // Vue: a rounded row in a list pane, a full-bleed one on a phone.
      child: Material(
        color: widget.active ? colors.bgSelected : Colors.transparent,
        borderRadius: dense ? BorderRadius.circular(FlareSizes.radiusMd) : null,
        clipBehavior: dense ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: widget.onSelect,
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onContextMenu == null
              ? widget.onLongPress
              : null,
          onSecondaryTapUp: widget.onContextMenu == null
              ? null
              : (details) => widget.onContextMenu!(details.globalPosition),
          hoverColor: colors.bgHover,
          focusColor: Colors.transparent,
          onFocusChange: (value) => setState(() => _focused = value),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              // Vue `--flare-conversation-row-height`: 68 on a phone, 64 in a
              // list pane, with the phone's 12 (pane: 10) above and below.
              constraints: BoxConstraints(
                minHeight: dense
                    ? FlareSizes.conversationRowDesktopHeight
                    : FlareSizes.conversationRowMobileHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingSm,
                  vertical: dense
                      ? FlareSizes.spacing2sm
                      : FlareSizes.spacingMd,
                ),
                child: Row(
                  children: [
                    FlareAvatar(
                      userId: widget.item.id,
                      displayName: widget.item.title,
                      avatarUrl: widget.item.avatarUrl,
                      size: dense ? 40 : widget.avatarSize,
                      presence: widget.item.presence,
                      group: widget.item.kind == FlareConversationKind.group,
                    ),
                    const SizedBox(width: FlareSizes.spacingMd),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vue `__top` / `__bottom`: the time ends the title
                          // line and the unread pill ends the preview line, so
                          // the preview runs on under the time.
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: dense
                                              ? FlareSizes.fontSizeLg
                                              : FlareSizes.fontSize2xl,
                                          fontWeight:
                                              widget.item.titleEmphasis ==
                                                  'strong'
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (widget.item.pinned)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.push_pin_outlined,
                                          size: 12,
                                          color: colors.textTertiary,
                                        ),
                                      ),
                                    if (widget.item.muted)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.notifications_off_outlined,
                                          size: 12,
                                          color: colors.textTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: FlareSizes
                                      .componentConversationRowMetaWidth,
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: FlareSizes.spacingSm,
                                  ),
                                  child: Text(
                                    widget.item.timestampLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: FlareSizes.fontSizeXs,
                                      color: widget.active
                                          ? colors.textSecondary
                                          : colors.textTertiary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 20,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(style: base, children: spans),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.item.mentioned) ...[
                                  const SizedBox(width: FlareSizes.spacingXs),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colors.bgSelected,
                                      borderRadius: BorderRadius.circular(
                                        FlareSizes.radiusFull,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: FlareSizes.spacingXs,
                                      ),
                                      child: Text(
                                        mention,
                                        style: TextStyle(
                                          fontSize: FlareSizes.fontSizeXs,
                                          fontWeight: FontWeight.w600,
                                          color: colors.primaryText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.item.hasUnread) ...[
                                  const SizedBox(width: FlareSizes.spacingSm),
                                  FlareUnreadBadge(
                                    count: widget.item.unreadCount,
                                    maxCount: 999,
                                    quiet: widget.item.muted,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final menu = widget.onContextMenu;
    // Shift+F10 / the context-menu key open the menu at the row's top-left
    // plus (16, 40), as the Vue row does.
    void menuFromKey() {
      final box = context.findRenderObject();
      if (menu != null && box is RenderBox && box.hasSize) {
        menu(box.localToGlobal(const Offset(16, 40)));
      }
    }

    final framed = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: _focused ? colors.borderSelected : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      ),
      child: menu == null
          ? row
          : CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.f10, shift: true):
                    menuFromKey,
                const SingleActivator(LogicalKeyboardKey.contextMenu):
                    menuFromKey,
              },
              child: row,
            ),
    );
    if (widget.swipeActions.isEmpty || widget.onAction == null) return framed;
    return Slidable(
      key: ValueKey(widget.item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: (widget.swipeActions.length * .23).clamp(.23, .7),
        children: [
          for (final action in widget.swipeActions)
            SlidableAction(
              onPressed: action.enabled
                  ? (_) => widget.onAction!(action.action)
                  : null,
              label: action.label,
              icon: FlareConversationActionSheet.iconFor(action.action),
              // The sheet's danger group: clear history and delete.
              backgroundColor: switch (action.action) {
                FlareConversationAction.clearHistory ||
                FlareConversationAction.delete => colors.errorText,
                _ => colors.primary,
              },
              foregroundColor: colors.messageOutgoingForeground,
            ),
        ],
      ),
      child: framed,
    );
  }
}
