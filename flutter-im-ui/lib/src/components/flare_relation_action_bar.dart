import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Relation between the viewer and the contact, as decided by the host.
/// Names match the cross-platform contract (Vue / SwiftUI / Compose enums).
enum FlareRelationState { none, pendingOut, pendingIn, friends, blocked }

/// Commands the bar may ask the host to run.
enum FlareRelationAction { add, accept, reject, remove, block, unblock, message }

/// Capabilities the host can honour. `false` → the action is not rendered.
@immutable
class FlareRelationCapabilities {
  const FlareRelationCapabilities({
    this.add = false,
    this.accept = false,
    this.reject = false,
    this.remove = false,
    this.block = false,
    this.unblock = false,
    this.message = false,
  });
  final bool add, accept, reject, remove, block, unblock, message;

  bool allows(FlareRelationAction action) => switch (action) {
        FlareRelationAction.add => add,
        FlareRelationAction.accept => accept,
        FlareRelationAction.reject => reject,
        FlareRelationAction.remove => remove,
        FlareRelationAction.block => block,
        FlareRelationAction.unblock => unblock,
        FlareRelationAction.message => message,
      };
}

/// One displayable entry; [destructive] entries render in the trailing group.
@immutable
class FlareRelationActionEntry {
  const FlareRelationActionEntry(this.action,
      {this.primary = false, this.destructive = false});
  final FlareRelationAction action;
  final bool primary;
  final bool destructive;
}

/// The full, ordered rule table. Capabilities filter it; they never reorder it,
/// so a button keeps its slot whichever switches the host flips.
const Map<FlareRelationState, List<FlareRelationActionEntry>> _relationRules = {
  FlareRelationState.none: [
    FlareRelationActionEntry(FlareRelationAction.add, primary: true),
    FlareRelationActionEntry(FlareRelationAction.block),
  ],
  // pendingOut deliberately omits `add`: the request is already out, so the bar
  // shows a disabled "waiting" notice instead of a button that would re-send.
  FlareRelationState.pendingOut: [
    FlareRelationActionEntry(FlareRelationAction.block),
  ],
  FlareRelationState.pendingIn: [
    FlareRelationActionEntry(FlareRelationAction.accept, primary: true),
    FlareRelationActionEntry(FlareRelationAction.reject),
    FlareRelationActionEntry(FlareRelationAction.block),
  ],
  FlareRelationState.friends: [
    FlareRelationActionEntry(FlareRelationAction.message, primary: true),
    FlareRelationActionEntry(FlareRelationAction.remove, destructive: true),
    FlareRelationActionEntry(FlareRelationAction.block, destructive: true),
  ],
  // While blocked nothing else is offered — no message, no friend request.
  FlareRelationState.blocked: [
    FlareRelationActionEntry(FlareRelationAction.unblock, primary: true),
  ],
};

/// Ordered, displayable actions for [relation] under [capabilities].
/// The host owns the relation; the component owns nothing but this table.
List<FlareRelationActionEntry> relationActions(
  FlareRelationState? relation,
  FlareRelationCapabilities? capabilities,
) {
  final rules = _relationRules[relation ?? FlareRelationState.none]!;
  final caps = capabilities ?? const FlareRelationCapabilities();
  return rules.where((e) => caps.allows(e.action)).toList();
}

/// True while an outgoing request is waiting: the bar shows a disabled primary
/// notice in place of the add button, regardless of capabilities, because it
/// reports state rather than offering a command.
bool relationShowsPending(FlareRelationState? relation) =>
    relation == FlareRelationState.pendingOut;

/// Relation action bar for the bottom of a contact detail page. The host owns
/// the relation state and every command; the bar only decides which buttons
/// exist and emits intent. It never mutates the relation, never retries, and
/// keeps the previous failure reason on screen until it is dismissed.
/// Spec: Contacts/RelationActionBar.
class FlareRelationActionBar extends StatefulWidget {
  const FlareRelationActionBar({
    super.key,
    required this.relation,
    this.capabilities = const FlareRelationCapabilities(),
    this.busy = false,
    this.error,
    this.onAction,
    this.onDismissError,
    this.addText = '添加好友',
    this.acceptText = '接受',
    this.rejectText = '拒绝',
    this.removeText = '删除好友',
    this.blockText = '加入黑名单',
    this.unblockText = '移出黑名单',
    this.messageText = '发消息',
    this.pendingText = '等待对方验证',
    this.busyText = '处理中',
    this.dismissErrorText = '关闭错误提示',
    this.emptyText = '暂无可用操作',
  });

  final FlareRelationState relation;
  final FlareRelationCapabilities capabilities;

  /// Host sets this synchronously before dispatching; disables every button.
  final bool busy;

  /// Reason the previous command failed; kept until dismissed, never auto-cleared.
  final String? error;
  final void Function(FlareRelationAction action)? onAction;
  final VoidCallback? onDismissError;
  final String addText,
      acceptText,
      rejectText,
      removeText,
      blockText,
      unblockText,
      messageText,
      pendingText,
      busyText,
      dismissErrorText,
      emptyText;

  @override
  State<FlareRelationActionBar> createState() => _FlareRelationActionBarState();
}

class _FlareRelationActionBarState extends State<FlareRelationActionBar> {
  FlareRelationAction? _pending;

  @override
  void didUpdateWidget(covariant FlareRelationActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.busy) _pending = null;
  }

  String _label(FlareRelationAction action) => switch (action) {
        FlareRelationAction.add => widget.addText,
        FlareRelationAction.accept => widget.acceptText,
        FlareRelationAction.reject => widget.rejectText,
        FlareRelationAction.remove => widget.removeText,
        FlareRelationAction.block => widget.blockText,
        FlareRelationAction.unblock => widget.unblockText,
        FlareRelationAction.message => widget.messageText,
      };

  static IconData _icon(FlareRelationAction action) => switch (action) {
        FlareRelationAction.add => Icons.person_add_alt,
        FlareRelationAction.accept => Icons.check,
        FlareRelationAction.reject => Icons.close,
        FlareRelationAction.remove => Icons.delete_outline,
        FlareRelationAction.block => Icons.block,
        FlareRelationAction.unblock => Icons.check_circle_outline,
        FlareRelationAction.message => Icons.chat_bubble_outline,
      };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final entries = relationActions(widget.relation, widget.capabilities);
    final safe = entries.where((e) => !e.destructive).toList();
    final danger = entries.where((e) => e.destructive).toList();
    final pendingNotice = relationShowsPending(widget.relation);
    final isEmpty = entries.isEmpty && !pendingNotice;
    final error = (widget.error ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        border: Border(top: BorderSide(color: colors.borderSecondary)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error.isNotEmpty) _errorStrip(colors, error),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingSm,
              children: [
                if (pendingNotice)
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
                      padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingMd),
                      decoration: BoxDecoration(
                        color: colors.bgDisabled,
                        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 16, color: colors.textDisabled),
                          const SizedBox(width: 6),
                          Text(
                            widget.pendingText,
                            style: TextStyle(
                              color: colors.textDisabled,
                              fontSize: FlareSizes.fontSizeMd,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isEmpty)
                  Container(
                    constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.emptyText,
                      style: TextStyle(
                          color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd),
                    ),
                  ),
                for (final entry in safe) _button(colors, entry),
                if (danger.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.only(left: FlareSizes.spacingSm),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: colors.borderSecondary)),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: FlareSizes.spacingSm,
                      runSpacing: FlareSizes.spacingSm,
                      children: [for (final entry in danger) _button(colors, entry)],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorStrip(FlareColors colors, String error) {
    final enabled = !widget.busy && widget.onDismissError != null;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.10),
        border: Border(bottom: BorderSide(color: colors.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: colors.error),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: colors.error, fontSize: FlareSizes.fontSizeMd),
              ),
            ),
          ),
          if (widget.onDismissError != null)
            Semantics(
              button: true,
              enabled: enabled,
              label: widget.dismissErrorText,
              child: Opacity(
                opacity: enabled ? 1 : 0.45,
                child: GestureDetector(
                  onTap: enabled ? widget.onDismissError : null,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: FlareSizes.touchTarget,
                    height: FlareSizes.touchTarget,
                    child: Icon(Icons.close, size: 16, color: colors.textSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _button(FlareColors colors, FlareRelationActionEntry entry) {
    final enabled = !widget.busy && widget.onAction != null;
    final pending = widget.busy && _pending == entry.action;
    final label = _label(entry.action);
    final fg = entry.primary
        ? Colors.white
        : entry.destructive
            ? colors.error
            : colors.textPrimary;
    final bg = entry.primary
        ? colors.primary
        : entry.destructive
            ? colors.error.withValues(alpha: 0.10)
            : colors.bgSecondary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: pending ? '$label · ${widget.busyText}' : label,
      child: Opacity(
        opacity: enabled ? 1 : (pending ? 0.85 : 0.45),
        child: GestureDetector(
          onTap: enabled
              ? () {
                  setState(() => _pending = entry.action);
                  widget.onAction!(entry.action);
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(
                minHeight: FlareSizes.touchTarget, minWidth: FlareSizes.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingMd),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pending)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else
                  Icon(_icon(entry.action), size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  softWrap: false,
                  style: TextStyle(
                      color: fg, fontSize: FlareSizes.fontSizeMd, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
