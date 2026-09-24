import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/conversation_row_data.dart';
import '../primitives/flare_unread_badge.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import '../models/workspace_layout.dart';
import 'flare_avatar.dart';
import 'flare_conversation_action_sheet.dart';
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
  final bool? compact;
  final List<FlareConversationSwipeAction> swipeActions;
  final ValueChanged<FlareConversationAction>? onAction;
  final List<InlineSpan> Function(BuildContext context, TextStyle baseStyle)?
  previewSpansBuilder;

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
    final shellMode = FlareShellScope.responsiveModeOf(context);
    final dense =
        widget.compact ??
        (shellMode == null
            ? MediaQuery.sizeOf(context).width >= 1024
            : shellMode != FlareApplicationResponsiveMode.mobile);
    final kind = widget.item.previewKind;
    final prefix = switch (kind) {
      'failed' => '[${strings.messageFailed}] ',
      'draft' => widget.draftLabel ?? strings.conversationRowDraft,
      'mention' => widget.mentionLabel ?? strings.conversationRowMention,
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
      if (widget.item.mentioned)
        widget.mentionLabel ?? strings.conversationRowMention,
      if (widget.item.pinned) strings.conversationActionSheetPin,
      if (widget.item.muted) strings.conversationActionSheetMute,
      '$prefix$preview',
      widget.item.timestampLabel,
    ].where((value) => value.isNotEmpty).join(', ');
    final row = Semantics(
      label: label,
      selected: widget.active,
      button: widget.onSelect != null,
      child: Material(
        color: widget.active ? colors.bgSelected : Colors.transparent,
        child: InkWell(
          onTap: widget.onSelect,
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onLongPress,
          hoverColor: colors.bgHover,
          focusColor: Colors.transparent,
          onFocusChange: (value) => setState(() => _focused = value),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: dense ? 72 : 80),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingSm,
                  vertical: dense
                      ? FlareSizes.spacing2sm
                      : FlareSizes.spacing2md,
                ),
                child: Row(
                  children: [
                    FlareAvatar(
                      userId: widget.item.id,
                      displayName: widget.item.title,
                      avatarUrl: widget.item.avatarUrl,
                      size: dense ? 40 : widget.avatarSize,
                      presence: widget.item.presence,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: FlareSizes.fontSizeLg,
                                    fontWeight:
                                        widget.item.titleEmphasis == 'strong'
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
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(style: base, children: spans),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: FlareSizes.componentConversationRowMetaWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
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
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 20,
                            child: widget.item.hasUnread
                                ? FlareUnreadBadge(
                                    count: widget.item.unreadCount,
                                    maxCount: 999,
                                    quiet:
                                        widget.item.muted &&
                                        !widget.item.mentioned,
                                  )
                                : null,
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
    final framed = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: _focused ? colors.borderSelected : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      ),
      child: row,
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
