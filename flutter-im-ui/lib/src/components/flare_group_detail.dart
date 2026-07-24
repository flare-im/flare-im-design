import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_button.dart';
import 'flare_checkbox.dart';
import 'flare_empty_state.dart';
import 'flare_group_member_grid.dart';
import 'flare_input.dart';
import 'flare_radio_group.dart';
import 'flare_settings_list.dart';

const int _joinInvite = 1;
const int _joinApproval = 2;
const int _joinOpen = 3;

/// Group detail / management — hero, member grid and Feishu-style settings:
/// 群信息 / 我在本群 / 群管理 / 群权限 (owner-admin gated), plus member actions,
/// join-request approval, invite picker, join policy and invite link. Purely
/// presentational — it renders [model] and raises intents; the host performs the
/// social.group.* writes and refreshes the model. It owns all of its own sheets
/// and dialogs, and reuses [FlareGroupMemberGrid].
/// Spec: Contacts/GroupDetail (`FlareGroupDetail`).
class FlareGroupDetail extends StatefulWidget {
  const FlareGroupDetail({
    super.key,
    required this.model,
    this.loading = false,
    this.joinRequests = const [],
    this.loadingJoinRequests = false,
    this.inviteCode,
    this.loadingInviteLink = false,
    this.invitableContacts = const [],
    this.labels = const FlareGroupDetailLabels(),
    this.onBack,
    this.onOpenChat,
    this.onUpdateName,
    this.onUpdateAnnouncement,
    this.onUpdateMyNickname,
    this.onSetJoinPolicy,
    this.onToggleMuteAll,
    this.onSetFlag,
    this.onToggleMyMuted,
    this.onToggleMyPinned,
    this.onLoadJoinRequests,
    this.onRespondRequest,
    this.onEnsureInviteLink,
    this.onPromoteMember,
    this.onMuteMember,
    this.onTransferOwner,
    this.onRemoveMember,
    this.onLoadContacts,
    this.onInviteMembers,
    this.onLeave,
  });

  final FlareGroupDetailModel? model;
  final bool loading;
  final List<FlareGroupJoinRequestView> joinRequests;
  final bool loadingJoinRequests;
  final String? inviteCode;
  final bool loadingInviteLink;

  /// Friends the viewer can add to the group (already-members are filtered out).
  final List<FlareContact> invitableContacts;

  final FlareGroupDetailLabels labels;

  final VoidCallback? onBack;
  final void Function(List<String> userIds, String name)? onOpenChat;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateAnnouncement;
  final ValueChanged<String>? onUpdateMyNickname;
  final ValueChanged<int>? onSetJoinPolicy;
  final ValueChanged<bool>? onToggleMuteAll;

  /// key ∈ {onlyAdminCanAtAll, onlyAdminCanPin, shareCardPermission}.
  final void Function(String key, bool value)? onSetFlag;
  final ValueChanged<bool>? onToggleMyMuted;
  final ValueChanged<bool>? onToggleMyPinned;
  final VoidCallback? onLoadJoinRequests;
  final void Function(String requestId, bool accept)? onRespondRequest;
  final VoidCallback? onEnsureInviteLink;
  final ValueChanged<String>? onPromoteMember;
  final ValueChanged<String>? onMuteMember;
  final ValueChanged<String>? onTransferOwner;
  final ValueChanged<String>? onRemoveMember;
  final VoidCallback? onLoadContacts;
  final ValueChanged<List<String>>? onInviteMembers;
  final VoidCallback? onLeave;

  @override
  State<FlareGroupDetail> createState() => _FlareGroupDetailState();
}

class _FlareGroupDetailState extends State<FlareGroupDetail> {
  FlareGroupDetailModel? get _m => widget.model;
  bool get _canManage => _m?.canManage ?? false;
  FlareGroupDetailLabels get _l => widget.labels;

  String _joinPolicyLabel(int p) => switch (p) {
        _joinInvite => _l.joinInvite,
        _joinApproval => _l.joinApproval,
        _ => _l.joinOpen,
      };

  // ── Settings model ─────────────────────────────────────────────────────────
  List<FlareSettingsSection> _sections() {
    final m = _m;
    if (m == null) return const [];
    final sections = <FlareSettingsSection>[
      FlareSettingsSection(title: _l.info, items: [
        FlareSettingsItem(
            key: 'name', label: _l.name, icon: Icons.tag, kind: FlareSettingKind.value, detail: m.name),
        FlareSettingsItem(
            key: 'announcement',
            label: _l.announcement,
            icon: Icons.campaign_outlined,
            kind: FlareSettingKind.value,
            detail: (m.announcement?.isNotEmpty ?? false) ? m.announcement! : _l.notSet),
        FlareSettingsItem(
            key: 'members',
            label: _l.members,
            icon: Icons.people_outline,
            kind: FlareSettingKind.value,
            detail: _l.memberCount(m.memberCount)),
      ]),
      FlareSettingsSection(title: _l.myInGroup, items: [
        FlareSettingsItem(
            key: 'myNickname',
            label: _l.myNickname,
            icon: Icons.edit_outlined,
            kind: FlareSettingKind.value,
            detail: (m.myNickname?.isNotEmpty ?? false) ? m.myNickname! : _l.notSet),
        FlareSettingsItem(
            key: 'notif',
            label: _l.muteNotif,
            icon: Icons.notifications_off_outlined,
            kind: FlareSettingKind.toggle,
            value: m.myMuted),
        FlareSettingsItem(
            key: 'pin', label: _l.pinGroup, icon: Icons.push_pin_outlined, kind: FlareSettingKind.toggle, value: m.myPinned),
      ]),
    ];
    if (m.canManage) {
      sections.add(FlareSettingsSection(title: _l.manage, items: [
        FlareSettingsItem(
            key: 'joinPolicy',
            label: _l.joinMode,
            icon: Icons.lock_outline,
            kind: FlareSettingKind.value,
            detail: _joinPolicyLabel(m.joinPolicy)),
        FlareSettingsItem(
            key: 'joinRequests',
            label: _l.joinRequests,
            icon: Icons.person_add_alt_outlined,
            kind: FlareSettingKind.navigation,
            detail: widget.joinRequests.isNotEmpty ? '${widget.joinRequests.length}' : null),
        FlareSettingsItem(
            key: 'muteAll', label: _l.muteAll, icon: Icons.volume_off_outlined, kind: FlareSettingKind.toggle, value: m.muteAll),
        FlareSettingsItem(
            key: 'inviteLink', label: _l.inviteLink, icon: Icons.link, kind: FlareSettingKind.navigation),
      ]));
      sections.add(FlareSettingsSection(title: _l.perms, items: [
        FlareSettingsItem(
            key: 'atAll',
            label: _l.onlyAdminAtAll,
            icon: Icons.alternate_email,
            kind: FlareSettingKind.toggle,
            value: m.onlyAdminCanAtAll),
        FlareSettingsItem(
            key: 'pinPerm',
            label: _l.onlyAdminPin,
            icon: Icons.push_pin_outlined,
            kind: FlareSettingKind.toggle,
            value: m.onlyAdminCanPin),
        FlareSettingsItem(
            key: 'shareCard',
            label: _l.shareCard,
            icon: Icons.share_outlined,
            kind: FlareSettingKind.toggle,
            value: m.shareCardPermission),
      ]));
    }
    return sections;
  }

  void _onSelect(FlareSettingsItem item) {
    final m = _m;
    if (m == null) return;
    switch (item.key) {
      case 'myNickname':
        _editNickname();
      case 'name':
        if (_canManage) _editName();
      case 'announcement':
        if (_canManage) _editAnnouncement();
      case 'joinPolicy':
        if (_canManage) _pickJoinPolicy();
      case 'joinRequests':
        if (_canManage) _showJoinRequests();
      case 'inviteLink':
        if (_canManage) _showInviteLink();
    }
  }

  void _onToggle(FlareSettingsItem item, bool value) {
    switch (item.key) {
      case 'notif':
        widget.onToggleMyMuted?.call(value);
      case 'pin':
        widget.onToggleMyPinned?.call(value);
      case 'muteAll':
        if (_canManage) widget.onToggleMuteAll?.call(value);
      case 'atAll':
        if (_canManage) widget.onSetFlag?.call('onlyAdminCanAtAll', value);
      case 'pinPerm':
        if (_canManage) widget.onSetFlag?.call('onlyAdminCanPin', value);
      case 'shareCard':
        if (_canManage) widget.onSetFlag?.call('shareCardPermission', value);
    }
  }

  // ── Edit dialogs ────────────────────────────────────────────────────────────
  Future<String?> _editDialog(String title, String initial,
      {String? placeholder, bool multiline = false, int? maxLength}) async {
    final ctrl = TextEditingController(text: initial);
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: FlareInput(
            controller: ctrl, placeholder: placeholder, multiline: multiline, maxLength: maxLength),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(_l.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: Text(_l.save)),
        ],
      ),
    );
    ctrl.dispose();
    return v;
  }

  Future<void> _editName() async {
    final v = await _editDialog(_l.editName, _m?.name ?? '', placeholder: _l.name, maxLength: 30);
    if (v != null) widget.onUpdateName?.call(v);
  }

  Future<void> _editAnnouncement() async {
    final v = await _editDialog(_l.editAnnouncement, _m?.announcement ?? '',
        placeholder: _l.announcement, multiline: true, maxLength: 200);
    if (v != null) widget.onUpdateAnnouncement?.call(v);
  }

  Future<void> _editNickname() async {
    final v = await _editDialog(_l.myNickname, _m?.myNickname ?? '',
        placeholder: _l.nicknamePlaceholder, maxLength: 20);
    if (v != null) widget.onUpdateMyNickname?.call(v);
  }

  // ── Join policy ─────────────────────────────────────────────────────────────
  Future<void> _pickJoinPolicy() async {
    var draft = '${_m?.joinPolicy ?? _joinOpen}';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (c) => SafeArea(
        child: StatefulBuilder(
          builder: (c, setSheet) => Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _sheetTitle(_l.joinMode),
              const SizedBox(height: FlareSizes.spacingMd),
              FlareRadioGroup(
                vertical: true,
                value: draft,
                options: [
                  FlareSelectOption(value: '$_joinOpen', label: _l.joinOpen),
                  FlareSelectOption(value: '$_joinApproval', label: _l.joinApproval),
                  FlareSelectOption(value: '$_joinInvite', label: _l.joinInvite),
                ],
                onSelect: (v) => setSheet(() => draft = v),
              ),
              const SizedBox(height: FlareSizes.spacingLg),
              Row(children: [
                Expanded(
                    child: FlareButton(
                        label: _l.cancel,
                        variant: FlareButtonVariant.secondary,
                        onPressed: () => Navigator.pop(c, false))),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(child: FlareButton(label: _l.save, onPressed: () => Navigator.pop(c, true))),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (ok == true) widget.onSetJoinPolicy?.call(int.tryParse(draft) ?? _joinOpen);
  }

  // ── Join requests ─────────────────────────────────────────────────────────────
  Future<void> _showJoinRequests() async {
    widget.onLoadJoinRequests?.call();
    final local = [...widget.joinRequests];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(FlareSizes.spacingLg), child: _sheetTitle(_l.joinRequests)),
            Expanded(
              child: widget.loadingJoinRequests
                  ? Center(child: Text(_l.loading))
                  : local.isEmpty
                      ? Center(child: Text(_l.noRequests))
                      : ListView(
                          children: local
                              .map((r) => ListTile(
                                    leading: FlareAvatar(
                                        userId: r.applicantId,
                                        displayName: r.applicantName,
                                        avatarUrl: r.avatarUrl,
                                        size: 44),
                                    title: Text(r.applicantName),
                                    subtitle: (r.message?.isNotEmpty ?? false) ? Text(r.message!) : null,
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      FlareButton(
                                          label: _l.reject,
                                          size: FlareControlSize.sm,
                                          variant: FlareButtonVariant.secondary,
                                          onPressed: () {
                                            widget.onRespondRequest?.call(r.requestId, false);
                                            setSheet(() => local.removeWhere((x) => x.requestId == r.requestId));
                                          }),
                                      const SizedBox(width: FlareSizes.spacingSm),
                                      FlareButton(
                                          label: _l.approve,
                                          size: FlareControlSize.sm,
                                          onPressed: () {
                                            widget.onRespondRequest?.call(r.requestId, true);
                                            setSheet(() => local.removeWhere((x) => x.requestId == r.requestId));
                                          }),
                                    ]),
                                  ))
                              .toList()),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Invite link ───────────────────────────────────────────────────────────────
  Future<void> _showInviteLink() async {
    widget.onEnsureInviteLink?.call();
    await showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingXl),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _sheetTitle(_l.inviteLink),
            const SizedBox(height: FlareSizes.spacingMd),
            Text(_l.inviteLinkHint,
                style: TextStyle(
                    color: FlareColors.of(Theme.of(c).brightness).textSecondary,
                    fontSize: FlareSizes.fontSizeLg)),
            const SizedBox(height: FlareSizes.spacingLg),
            if (widget.loadingInviteLink)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (widget.inviteCode?.isNotEmpty ?? false) ...[
              Container(
                padding: const EdgeInsets.all(FlareSizes.spacingLg),
                decoration: BoxDecoration(
                    color: FlareColors.of(Theme.of(c).brightness).bgSecondary,
                    borderRadius: BorderRadius.circular(FlareSizes.radiusLg)),
                child: SelectableText(widget.inviteCode!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
              const SizedBox(height: FlareSizes.spacingLg),
              FlareButton(
                  block: true,
                  label: _l.copyCode,
                  icon: Icons.copy,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.inviteCode!));
                    if (c.mounted) Navigator.pop(c);
                  }),
            ] else
              Text(_l.cannotGenerate,
                  style: TextStyle(color: FlareColors.of(Theme.of(c).brightness).textTertiary)),
          ]),
        ),
      ),
    );
  }

  // ── Member actions ─────────────────────────────────────────────────────────────
  void _onMemberSelect(String id) {
    final m = _m;
    if (m == null || !_canManage || id == m.ownerId) return;
    _memberActions(id);
  }

  Future<void> _memberActions(String id) async {
    final m = _m!;
    final isAdmin = m.adminIds.contains(id);
    final isMuted = m.mutedIds.contains(id);
    await showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _sheetTitle(_l.memberManage),
            const SizedBox(height: FlareSizes.spacingMd),
            FlareButton(
                block: true,
                variant: FlareButtonVariant.secondary,
                label: isAdmin ? _l.unsetAdmin : _l.setAdmin,
                onPressed: () {
                  Navigator.pop(c);
                  widget.onPromoteMember?.call(id);
                }),
            const SizedBox(height: FlareSizes.spacingSm),
            FlareButton(
                block: true,
                variant: FlareButtonVariant.secondary,
                label: isMuted ? _l.unmute : _l.mute,
                onPressed: () {
                  Navigator.pop(c);
                  widget.onMuteMember?.call(id);
                }),
            if (m.isOwner) ...[
              const SizedBox(height: FlareSizes.spacingSm),
              FlareButton(
                  block: true,
                  variant: FlareButtonVariant.secondary,
                  label: _l.transferOwner,
                  onPressed: () {
                    Navigator.pop(c);
                    _confirmTransfer(id);
                  }),
            ],
            const SizedBox(height: FlareSizes.spacingSm),
            FlareButton(
                block: true,
                variant: FlareButtonVariant.danger,
                label: _l.removeMember,
                onPressed: () {
                  Navigator.pop(c);
                  widget.onRemoveMember?.call(id);
                }),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmTransfer(String id) async {
    var name = '';
    for (final x in _m?.members ?? const <FlareContact>[]) {
      if (x.id == id) {
        name = x.name;
        break;
      }
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_l.transferOwner),
        content: Text(_l.transferConfirm(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_l.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(_l.confirmTransfer)),
        ],
      ),
    );
    if (ok == true) widget.onTransferOwner?.call(id);
  }

  // ── Invite members ─────────────────────────────────────────────────────────────
  Future<void> _openInvite() async {
    widget.onLoadContacts?.call();
    final m = _m;
    final memberIds = m?.members.map((x) => x.id).toSet() ?? <String>{};
    final options = widget.invitableContacts.where((c) => !memberIds.contains(c.id)).toList();
    final picked = <String>{};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(FlareSizes.spacingLg), child: _sheetTitle(_l.invite)),
            Expanded(
              child: options.isEmpty
                  ? Center(child: Text(_l.inviteEmpty))
                  : ListView(
                      children: options
                          .map((ct) => CheckboxListTileLike(
                                contact: ct,
                                checked: picked.contains(ct.id),
                                onTap: () => setSheet(() {
                                  if (picked.contains(ct.id)) {
                                    picked.remove(ct.id);
                                  } else {
                                    picked.add(ct.id);
                                  }
                                }),
                              ))
                          .toList()),
            ),
            Padding(
              padding: const EdgeInsets.all(FlareSizes.spacingLg),
              child: FlareButton(
                  block: true,
                  disabled: picked.isEmpty,
                  label: _l.inviteConfirm(picked.length),
                  onPressed: () => Navigator.pop(c, true)),
            ),
          ]),
        ),
      ),
    );
    if (ok == true && picked.isNotEmpty) widget.onInviteMembers?.call(picked.toList());
  }

  // ── Leave / dissolve ───────────────────────────────────────────────────────────
  Future<void> _confirmLeave() async {
    final owner = _m?.isOwner ?? false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(owner ? _l.dissolve : _l.leave),
        content: Text(owner ? _l.dissolveConfirm : _l.leaveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_l.cancel)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(owner ? _l.dissolve : _l.leave)),
        ],
      ),
    );
    if (ok == true) widget.onLeave?.call();
  }

  Widget _sheetTitle(String text) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Text(text,
        style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSize2xl, fontWeight: FontWeight.w600));
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final m = _m;
    if (m == null) {
      if (widget.loading) return const Center(child: CircularProgressIndicator());
      return FlareEmptyState(
          icon: Icons.groups_2_outlined, title: _l.unavailable, description: _l.unavailableHint);
    }
    final name = m.name.isNotEmpty ? m.name : _l.groupFallback;
    return ListView(
      children: [
        // Hero.
        Padding(
          padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg, FlareSizes.spacingXl,
              FlareSizes.spacingLg, FlareSizes.spacingSm),
          child: Column(children: [
            FlareAvatar(userId: m.groupId, displayName: name, avatarUrl: m.avatarUrl, size: 72),
            const SizedBox(height: FlareSizes.spacingSm),
            Text(name,
                style: TextStyle(
                    color: colors.textPrimary, fontSize: FlareSizes.fontSize3xl, fontWeight: FontWeight.w600)),
          ]),
        ),

        FlareGroupMemberGrid(
          members: m.members,
          ownerId: m.ownerId,
          adminIds: m.adminIds,
          showAdd: _canManage,
          onSelect: _onMemberSelect,
          onAddMember: _openInvite,
        ),

        FlareSettingsList(sections: _sections(), onSelect: _onSelect, onToggle: _onToggle, shrinkWrap: true),

        // Bottom actions.
        Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Column(children: [
            FlareButton(
                block: true,
                size: FlareControlSize.lg,
                label: _l.message,
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => widget.onOpenChat?.call(m.members.map((x) => x.id).toList(), name)),
            const SizedBox(height: FlareSizes.spacingMd),
            FlareButton(
                block: true,
                size: FlareControlSize.lg,
                variant: FlareButtonVariant.danger,
                label: m.isOwner ? _l.dissolve : _l.leave,
                onPressed: _confirmLeave),
          ]),
        ),
      ],
    );
  }
}

/// A brand-styled multi-select row used by the invite picker (avatar + name +
/// [FlareCheckbox]). Private helper for [FlareGroupDetail].
class CheckboxListTileLike extends StatelessWidget {
  const CheckboxListTileLike({
    super.key,
    required this.contact,
    required this.checked,
    required this.onTap,
  });
  final FlareContact contact;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
        child: Row(children: [
          FlareAvatar(userId: contact.id, displayName: contact.name, avatarUrl: contact.avatarUrl, size: 36),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(child: Text(contact.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          IgnorePointer(child: FlareCheckbox(value: checked)),
        ]),
      ),
    );
  }
}

/// Localizable copy for [FlareGroupDetail] (Chinese defaults).
class FlareGroupDetailLabels {
  const FlareGroupDetailLabels({
    this.groupFallback = '群聊',
    this.info = '群信息',
    this.name = '群名称',
    this.announcement = '群公告',
    this.members = '群成员',
    this.notSet = '未设置',
    this.myInGroup = '我在本群',
    this.myNickname = '我的群昵称',
    this.nicknamePlaceholder = '群内显示名',
    this.muteNotif = '消息免打扰',
    this.pinGroup = '置顶该群',
    this.manage = '群管理',
    this.joinMode = '进群方式',
    this.joinOpen = '允许任何人加入',
    this.joinApproval = '需管理员审批',
    this.joinInvite = '仅邀请加入',
    this.joinRequests = '入群申请',
    this.muteAll = '全员禁言',
    this.inviteLink = '群邀请链接',
    this.inviteLinkHint = '将邀请码分享给好友，对方可凭码加入本群。',
    this.copyCode = '复制邀请码',
    this.cannotGenerate = '暂无法生成邀请链接，请稍后重试。',
    this.perms = '群权限',
    this.onlyAdminAtAll = '仅管理员可@全体成员',
    this.onlyAdminPin = '仅管理员可置顶消息',
    this.shareCard = '允许分享群名片',
    this.message = '发消息',
    this.leave = '退出群聊',
    this.dissolve = '解散群聊',
    this.leaveConfirm = '退出后将不再接收该群消息。',
    this.dissolveConfirm = '解散后群聊将被永久删除，无法恢复。',
    this.cancel = '取消',
    this.save = '保存',
    this.editName = '修改群名称',
    this.editAnnouncement = '修改群公告',
    this.memberManage = '成员管理',
    this.setAdmin = '设为管理员',
    this.unsetAdmin = '取消管理员',
    this.mute = '禁言',
    this.unmute = '解除禁言',
    this.transferOwner = '转让群主',
    this.confirmTransfer = '确认转让',
    this.removeMember = '移出群聊',
    this.invite = '邀请成员',
    this.inviteEmpty = '没有可邀请的好友。',
    this.reject = '拒绝',
    this.approve = '通过',
    this.loading = '加载中…',
    this.noRequests = '暂无入群申请。',
    this.unavailable = '群信息不可用',
    this.unavailableHint = '未连接服务时无法加载。',
    this.memberCount = _defaultMemberCount,
    this.inviteConfirm = _defaultInviteConfirm,
    this.transferConfirm = _defaultTransferConfirm,
  });

  final String groupFallback;
  final String info;
  final String name;
  final String announcement;
  final String members;
  final String notSet;
  final String myInGroup;
  final String myNickname;
  final String nicknamePlaceholder;
  final String muteNotif;
  final String pinGroup;
  final String manage;
  final String joinMode;
  final String joinOpen;
  final String joinApproval;
  final String joinInvite;
  final String joinRequests;
  final String muteAll;
  final String inviteLink;
  final String inviteLinkHint;
  final String copyCode;
  final String cannotGenerate;
  final String perms;
  final String onlyAdminAtAll;
  final String onlyAdminPin;
  final String shareCard;
  final String message;
  final String leave;
  final String dissolve;
  final String leaveConfirm;
  final String dissolveConfirm;
  final String cancel;
  final String save;
  final String editName;
  final String editAnnouncement;
  final String memberManage;
  final String setAdmin;
  final String unsetAdmin;
  final String mute;
  final String unmute;
  final String transferOwner;
  final String confirmTransfer;
  final String removeMember;
  final String invite;
  final String inviteEmpty;
  final String reject;
  final String approve;
  final String loading;
  final String noRequests;
  final String unavailable;
  final String unavailableHint;

  /// e.g. `(3) => '3 位成员'`.
  final String Function(int count) memberCount;

  /// e.g. `(2) => '邀请 (2)'`.
  final String Function(int count) inviteConfirm;

  /// e.g. `('Alice') => '确定把群主转让给「Alice」…'`.
  final String Function(String name) transferConfirm;

  static String _defaultMemberCount(int count) => '$count 位成员';
  static String _defaultInviteConfirm(int count) => '邀请 ($count)';
  static String _defaultTransferConfirm(String name) =>
      '确定把群主转让给「$name」？转让后你将成为普通成员，此操作不可撤销。';
}
