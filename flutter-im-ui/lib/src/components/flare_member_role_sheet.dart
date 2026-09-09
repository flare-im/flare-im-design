import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// A member's role in the group.
enum FlareGroupMemberRole { owner, admin, member }

/// Management actions a [FlareMemberRoleSheet] can emit; names match the
/// cross-platform contract (Vue `action` payload / SwiftUI / Compose enums).
enum FlareMemberRoleAction { promote, demote, mute, unmute, transferOwner, remove }

/// The member the sheet acts on; [id] must be stable and is echoed in the callback.
@immutable
class FlareGroupMemberSnapshot {
  const FlareGroupMemberSnapshot({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.muted = false,
  });
  final String id;
  final String name;
  final String? avatarUrl;
  final FlareGroupMemberRole role;
  final bool muted;
}

/// Host-declared capabilities. `false` → the action is not rendered.
@immutable
class FlareMemberRoleCapabilities {
  const FlareMemberRoleCapabilities({
    this.promote = false,
    this.demote = false,
    this.mute = false,
    this.unmute = false,
    this.remove = false,
    this.transferOwner = false,
  });
  final bool promote, demote, mute, unmute, remove, transferOwner;
}

/// One host-supplied mute duration option; the kit ships no durations of its own.
@immutable
class FlareMemberMuteDuration {
  const FlareMemberMuteDuration({required this.id, required this.label});
  final String id;
  final String label;
}

/// One displayable action; [danger] entries render in the trailing danger group.
@immutable
class FlareMemberRoleActionEntry {
  const FlareMemberRoleActionEntry(this.action, {this.danger = false});
  final FlareMemberRoleAction action;
  final bool danger;
}

/// Ordered management actions for [member] as seen by [viewerRole] — the same
/// rule set as the other platforms. Rank rules come first, capabilities only
/// narrow further:
///
///  - the owner is untouchable — no promote / demote / mute / remove / transfer;
///  - a plain member sees nothing (the sheet then says it has no rights);
///  - an admin cannot act on a peer admin and can never transfer ownership;
///  - only the owner can transfer ownership;
///  - promote only applies to a member, demote only to an admin;
///  - mute / unmute are mutually exclusive by `member.muted`.
///
/// `mute` still needs host-supplied durations — a sheet with none hides the row.
List<FlareMemberRoleActionEntry> memberRoleActions(
  FlareGroupMemberSnapshot member,
  FlareGroupMemberRole viewerRole,
  FlareMemberRoleCapabilities capabilities,
) {
  if (member.role == FlareGroupMemberRole.owner) return const [];
  if (viewerRole == FlareGroupMemberRole.member) return const [];
  if (viewerRole == FlareGroupMemberRole.admin &&
      member.role == FlareGroupMemberRole.admin) {
    return const [];
  }
  final out = <FlareMemberRoleActionEntry>[];
  if (capabilities.promote && member.role == FlareGroupMemberRole.member) {
    out.add(const FlareMemberRoleActionEntry(FlareMemberRoleAction.promote));
  }
  if (capabilities.demote && member.role == FlareGroupMemberRole.admin) {
    out.add(const FlareMemberRoleActionEntry(FlareMemberRoleAction.demote));
  }
  if (capabilities.mute && !member.muted) {
    out.add(const FlareMemberRoleActionEntry(FlareMemberRoleAction.mute));
  }
  if (capabilities.unmute && member.muted) {
    out.add(const FlareMemberRoleActionEntry(FlareMemberRoleAction.unmute));
  }
  if (capabilities.transferOwner && viewerRole == FlareGroupMemberRole.owner) {
    out.add(const FlareMemberRoleActionEntry(FlareMemberRoleAction.transferOwner,
        danger: true));
  }
  if (capabilities.remove) {
    out.add(const FlareMemberRoleActionEntry(FlareMemberRoleAction.remove, danger: true));
  }
  return out;
}

/// Management menu for ONE group member: change role, mute, remove, transfer
/// ownership. Owns no positioning — place it in `showModalBottomSheet` or a
/// popover. It only emits intent: the second confirmation for remove /
/// transferOwner is the host's job (FlareDangerConfirm), and mute durations
/// come from the host. Spec: Contacts/MemberRoleSheet.
class FlareMemberRoleSheet extends StatefulWidget {
  const FlareMemberRoleSheet({
    super.key,
    required this.member,
    required this.viewerRole,
    this.capabilities = const FlareMemberRoleCapabilities(),
    this.muteDurations = const <FlareMemberMuteDuration>[],
    this.busy = false,
    this.ownerRoleText = '群主',
    this.adminRoleText = '管理员',
    this.memberRoleText = '成员',
    this.mutedText = '已禁言',
    this.promoteText = '设为管理员',
    this.demoteText = '取消管理员',
    this.muteText = '禁言',
    this.unmuteText = '解除禁言',
    this.removeText = '移出群聊',
    this.transferOwnerText = '转让群主',
    this.dangerGroupText = '危险操作',
    this.emptyText = '你没有管理权限',
    this.ownerProtectedText = '群主不可被管理',
    this.onAction,
    this.onClose,
  });

  final FlareGroupMemberSnapshot member;

  /// The viewer's own role in this group — rank rules come before capabilities.
  final FlareGroupMemberRole viewerRole;
  final FlareMemberRoleCapabilities capabilities;

  /// Host-supplied mute durations; empty hides mute — the kit invents no durations.
  final List<FlareMemberMuteDuration> muteDurations;

  /// Host sets this synchronously before dispatching; disables every action.
  final bool busy;

  final String ownerRoleText,
      adminRoleText,
      memberRoleText,
      mutedText,
      promoteText,
      demoteText,
      muteText,
      unmuteText,
      removeText,
      transferOwnerText,
      dangerGroupText,
      emptyText,
      ownerProtectedText;

  /// `durationId` is non-null for `mute` only.
  final void Function(String memberId, FlareMemberRoleAction action, String? durationId)?
      onAction;
  final VoidCallback? onClose;

  String labelFor(FlareMemberRoleAction action) => switch (action) {
        FlareMemberRoleAction.promote => promoteText,
        FlareMemberRoleAction.demote => demoteText,
        FlareMemberRoleAction.mute => muteText,
        FlareMemberRoleAction.unmute => unmuteText,
        FlareMemberRoleAction.transferOwner => transferOwnerText,
        FlareMemberRoleAction.remove => removeText,
      };

  @override
  State<FlareMemberRoleSheet> createState() => _FlareMemberRoleSheetState();
}

class _FlareMemberRoleSheetState extends State<FlareMemberRoleSheet> {
  bool _muteOpen = false;

  @override
  void didUpdateWidget(FlareMemberRoleSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member.id != oldWidget.member.id || widget.busy) _muteOpen = false;
  }

  static IconData _iconFor(FlareMemberRoleAction action) => switch (action) {
        FlareMemberRoleAction.promote => Icons.verified_user_outlined,
        FlareMemberRoleAction.demote => Icons.person_outline,
        FlareMemberRoleAction.mute => Icons.volume_off_outlined,
        FlareMemberRoleAction.unmute => Icons.notifications_outlined,
        FlareMemberRoleAction.transferOwner => Icons.star_outline,
        FlareMemberRoleAction.remove => Icons.logout,
      };

  String get _roleText => switch (widget.member.role) {
        FlareGroupMemberRole.owner => widget.ownerRoleText,
        FlareGroupMemberRole.admin => widget.adminRoleText,
        FlareGroupMemberRole.member => widget.memberRoleText,
      };

  void _select(FlareMemberRoleActionEntry entry) {
    if (widget.busy || widget.onAction == null) return;
    if (entry.action == FlareMemberRoleAction.mute) {
      setState(() => _muteOpen = !_muteOpen);
      return;
    }
    widget.onAction!(widget.member.id, entry.action, null);
  }

  void _chooseDuration(FlareMemberMuteDuration duration) {
    if (widget.busy || widget.onAction == null) return;
    widget.onAction!(widget.member.id, FlareMemberRoleAction.mute, duration.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final entries = memberRoleActions(widget.member, widget.viewerRole, widget.capabilities)
        // mute needs host durations; with none supplied the row is not offered.
        .where((e) =>
            e.action != FlareMemberRoleAction.mute || widget.muteDurations.isNotEmpty)
        .toList();
    final primary = entries.where((e) => !e.danger).toList();
    final danger = entries.where((e) => e.danger).toList();
    final emptyReason = widget.member.role == FlareGroupMemberRole.owner
        ? widget.ownerProtectedText
        : widget.emptyText;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_muteOpen) {
            setState(() => _muteOpen = false);
          } else {
            widget.onClose?.call();
          }
        },
      },
      child: FocusTraversalGroup(
        child: Semantics(
          container: true,
          label: widget.member.name,
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
                  _head(colors),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(FlareSizes.spacingMd),
                      child: Text(
                        emptyReason,
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

  Widget _head(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingMd,
        vertical: FlareSizes.spacingSm,
      ),
      child: Row(
        children: [
          FlareAvatar(
            userId: widget.member.id,
            displayName: widget.member.name,
            avatarUrl: widget.member.avatarUrl,
            size: 40,
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeXl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: widget.member.role == FlareGroupMemberRole.member
                            ? colors.bgSecondary
                            : colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                      ),
                      child: Text(
                        _roleText,
                        style: TextStyle(
                          color: widget.member.role == FlareGroupMemberRole.member
                              ? colors.textSecondary
                              : colors.primary,
                          fontSize: FlareSizes.fontSizeSm,
                          fontWeight: widget.member.role == FlareGroupMemberRole.member
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.member.muted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_off_outlined, size: 12, color: colors.warning),
                          const SizedBox(width: 3),
                          Text(
                            widget.mutedText,
                            style: TextStyle(color: colors.warning, fontSize: FlareSizes.fontSizeSm),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(
    List<FlareMemberRoleActionEntry> entries,
    FlareColors colors, {
    required bool danger,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radius2xl),
        border: danger ? Border(top: BorderSide(color: colors.borderSecondary)) : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingXs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (danger)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd,
                vertical: FlareSizes.spacingXs,
              ),
              child: Text(
                widget.dangerGroupText,
                style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm),
              ),
            ),
          for (final entry in entries) ...[
            _row(entry, colors),
            if (entry.action == FlareMemberRoleAction.mute && _muteOpen)
              _durations(colors),
          ],
        ],
      ),
    );
  }

  Widget _durations(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 56,
        right: FlareSizes.spacingMd,
        top: FlareSizes.spacingXs,
        bottom: FlareSizes.spacingSm,
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final duration in widget.muteDurations)
            Semantics(
              button: true,
              enabled: !widget.busy && widget.onAction != null,
              label: duration.label,
              child: InkWell(
                onTap: widget.busy || widget.onAction == null
                    ? null
                    : () => _chooseDuration(duration),
                borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                child: Opacity(
                  opacity: widget.busy || widget.onAction == null ? 0.5 : 1,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.bgSecondary,
                      border: Border.all(color: colors.borderPrimary),
                      borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                    ),
                    child: Text(
                      duration.label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeMd,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(FlareMemberRoleActionEntry entry, FlareColors colors) {
    final enabled = !widget.busy && widget.onAction != null;
    final accent = entry.danger ? colors.error : colors.primary;
    final fg = enabled
        ? (entry.danger ? colors.error : colors.textPrimary)
        : colors.textDisabled;
    final iconFg = enabled ? accent : colors.textDisabled;
    final iconBg =
        enabled ? accent.withValues(alpha: entry.danger ? 0.12 : 0.10) : colors.bgDisabled;
    final label = widget.labelFor(entry.action);
    final expandable = entry.action == FlareMemberRoleAction.mute;
    return Semantics(
      button: true,
      enabled: enabled,
      expanded: expandable ? _muteOpen : null,
      label: label,
      child: InkWell(
        onTap: enabled ? () => _select(entry) : null,
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
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
                if (expandable)
                  Icon(
                    _muteOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: colors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
