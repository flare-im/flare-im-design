import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../models/group_management.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_checkbox.dart';
import 'flare_contact_list.dart';
import 'flare_empty_state.dart';
import 'flare_group_member_grid.dart';
import 'flare_radio_group.dart';
import 'flare_scene_panels.dart';
import 'flare_search_bar.dart';
import 'flare_settings_list.dart';

/// Group detail / management — hero, member grid and Feishu-style settings:
/// 群信息 / 我在本群 / 群管理 / 群权限, plus member actions, join-request
/// approval, invite picker, join policy and invite link. Purely presentational —
/// it renders [model] and raises intents; the host performs the social.group.*
/// writes and refreshes the model. It owns its editing sheets and dialogs, and
/// reuses [FlareGroupMemberGrid].
///
/// Every management entry follows the host's answer: `model.capabilities`
/// through [groupManagementEntries], and each member's sheet through
/// `model.memberActions` ([groupDetailMemberActions]). The kit reads no role or
/// owner rule of its own.
///
/// Transferring ownership is confirmed here, inside the member sheet it starts
/// from. Removing a member and leaving / dissolving are emitted as tapped: the
/// host confirms them (e.g. with `FlareDangerConfirm.show(action:)`) because it
/// owns the busy and error states of the write.
///
/// The member grid previews the first [previewMemberCells] cells (the add
/// tile included when the viewer may invite); the 群成员 row opens a sheet of
/// every member with a search field, where choosing a member opens the same
/// member actions as the grid.
///
/// Editing the name, the announcement or my nickname opens the kit's prompt.
/// With [submitEdit] the prompt waits for the host's write: it stays busy while
/// the write runs, keeps the draft and shows the error when the write fails
/// (confirming again retries), and closes once it succeeds. Without it the
/// prompt closes on confirm and [onUpdateName], [onUpdateAnnouncement] or
/// [onUpdateMyNickname] reports the value.
///
/// Hosts place their own content in two slots, [afterInfo] and [footer], which
/// scroll with the page; nothing is drawn for a slot left null.
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
    this.submitEdit,
    this.onUpdateName,
    this.onUpdateAnnouncement,
    this.onUpdateMyNickname,
    this.onToggleDiscoverable,
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
    this.onSearchMembers,
    this.onLeave,
    this.extraActions = const [],
    this.onExtraAction,
    this.afterInfo,
    this.footer,
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

  /// Opens the group's conversation. The 发消息 button is drawn only when the
  /// host handles it.
  final void Function(List<String> userIds, String name)? onOpenChat;

  /// Persists an edit before its prompt closes; a thrown error stays in the
  /// prompt with the draft. When given, the three `onUpdate…` callbacks are
  /// not called.
  final Future<void> Function(FlareGroupEditKind kind, String value)?
  submitEdit;
  final ValueChanged<String>? onUpdateName;
  final ValueChanged<String>? onUpdateAnnouncement;
  final ValueChanged<String>? onUpdateMyNickname;

  /// Controls whether this group is returned by public group search.
  final ValueChanged<bool>? onToggleDiscoverable;

  /// The join policy the viewer picked and saved.
  final ValueChanged<FlareGroupJoinPolicy>? onSetJoinPolicy;
  final ValueChanged<bool>? onToggleMuteAll;

  /// key ∈ {onlyAdminCanAtAll, onlyAdminCanPin, shareCardPermission}.
  final void Function(String key, bool value)? onSetFlag;
  final ValueChanged<bool>? onToggleMyMuted;
  final ValueChanged<bool>? onToggleMyPinned;
  final VoidCallback? onLoadJoinRequests;
  final void Function(String requestId, bool accept)? onRespondRequest;
  final VoidCallback? onEnsureInviteLink;

  /// `admin` is the role the member should have after the change: true makes
  /// them an admin, false revokes it — the change the tapped button named.
  final void Function(String userId, bool admin)? onPromoteMember;

  /// `muted` is the state the member should have after the change.
  final void Function(String userId, bool muted)? onMuteMember;
  final ValueChanged<String>? onTransferOwner;
  final ValueChanged<String>? onRemoveMember;
  final VoidCallback? onLoadContacts;
  final ValueChanged<List<String>>? onInviteMembers;

  /// Optional host-backed member search. When absent, the members sheet keeps
  /// its local filter over [FlareGroupDetailModel.members].
  final Future<List<FlareContact>> Function(String keyword)? onSearchMembers;
  final VoidCallback? onLeave;

  /// Host actions the kit cannot know about (report, an admin tool), drawn above leaving the
  /// group; the kit reports the id back and nothing else (FR-046).
  final List<FlareDetailExtraAction> extraActions;
  final ValueChanged<String>? onExtraAction;

  /// Host content drawn right after the group information section (群信息),
  /// inset like its card — e.g. the announcement read bar.
  final Widget? afterInfo;

  /// Host content drawn after the message and leave buttons, inset like them —
  /// e.g. a report entry.
  final Widget? footer;

  /// Cells in the member preview grid, the add tile included: four rows of
  /// five.
  static const previewMemberCells = 20;

  @override
  State<FlareGroupDetail> createState() => _FlareGroupDetailState();
}

class _FlareGroupDetailState extends State<FlareGroupDetail> {
  FlareGroupDetailModel? get _m => widget.model;

  /// The management entries the host's capabilities name; nothing else is
  /// offered (Vue `groupManagementEntries`).
  Set<FlareGroupManagementEntry> get _entries =>
      groupManagementEntries(_m?.capabilities).toSet();
  bool _can(FlareGroupManagementEntry entry) => _entries.contains(entry);

  /// My group nickname is editable when the host persists it.
  bool get _canEditNickname =>
      widget.submitEdit != null || widget.onUpdateMyNickname != null;
  FlareGroupDetailLabels get _l => widget.labels;

  /// "A setting the host could not read". Not in [FlareGroupDetailLabels]:
  /// new copy goes to the platform strings table, which hosts already
  /// override as a whole.
  String get _settingUnavailable =>
      FlareStrings.of(context).groupDetailSettingUnavailable;

  /// The latest model for the sheets this view presents: they live in routes
  /// of their own and do not rebuild with it.
  late final _model = ValueNotifier<FlareGroupDetailModel?>(widget.model);

  /// The invite link the host is fetching for the open sheet: the code arrives
  /// after the sheet opened, so the sheet follows these props instead of
  /// reading them once.
  late final _invite = ValueNotifier<(String?, bool)>((
    widget.inviteCode,
    widget.loadingInviteLink,
  ));

  /// The join requests for the open sheet: the host loads them after the
  /// sheet opened and reloads them after each answer, so the sheet follows
  /// these props instead of copying them once.
  late final _joinRequests =
      ValueNotifier<(List<FlareGroupJoinRequestView>, bool)>((
        widget.joinRequests,
        widget.loadingJoinRequests,
      ));

  @override
  void didUpdateWidget(covariant FlareGroupDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final invite = (widget.inviteCode, widget.loadingInviteLink);
    final modelChanged = !identical(widget.model, oldWidget.model);
    final joinChanged =
        !identical(widget.joinRequests, oldWidget.joinRequests) ||
        widget.loadingJoinRequests != oldWidget.loadingJoinRequests;
    if (!modelChanged && !joinChanged && invite == _invite.value) return;
    // The listeners are outside this subtree; tell them after this build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (modelChanged) _model.value = widget.model;
      _invite.value = (widget.inviteCode, widget.loadingInviteLink);
      if (joinChanged) {
        _joinRequests.value = (widget.joinRequests, widget.loadingJoinRequests);
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _invite.dispose();
    _joinRequests.dispose();
    super.dispose();
  }

  String _joinPolicyLabel(FlareGroupJoinPolicy policy) => switch (policy) {
    FlareGroupJoinPolicy.open => _l.joinOpen,
    FlareGroupJoinPolicy.approval => _l.joinApproval,
    FlareGroupJoinPolicy.invite => _l.joinInvite,
  };

  // ── Settings model ─────────────────────────────────────────────────────────
  List<FlareSettingsSection> _sections() {
    final m = _m;
    if (m == null) return const [];
    final sections = <FlareSettingsSection>[
      FlareSettingsSection(
        title: _l.info,
        items: [
          FlareSettingsItem(
            key: 'name',
            label: _l.name,
            icon: 'tag',
            // Rows the viewer can change open their editor and carry a
            // chevron; the rest read as values, not as buttons.
            kind: _can(FlareGroupManagementEntry.editName)
                ? FlareSettingKind.navigation
                : FlareSettingKind.value,
            detail: m.name,
          ),
          FlareSettingsItem(
            key: 'announcement',
            label: _l.announcement,
            icon: 'announcement',
            kind: _can(FlareGroupManagementEntry.editAnnouncement)
                ? FlareSettingKind.navigation
                : FlareSettingKind.value,
            detail: (m.announcement?.isNotEmpty ?? false)
                ? m.announcement!
                : _l.notSet,
          ),
          FlareSettingsItem(
            key: 'members',
            label: _l.members,
            icon: 'people',
            kind: FlareSettingKind.navigation,
            detail: _l.memberCount(m.memberCount),
          ),
        ],
      ),
      FlareSettingsSection(
        title: _l.myInGroup,
        items: [
          FlareSettingsItem(
            key: 'myNickname',
            label: _l.myNickname,
            icon: 'edit',
            kind: _canEditNickname
                ? FlareSettingKind.navigation
                : FlareSettingKind.value,
            detail: (m.myNickname?.isNotEmpty ?? false)
                ? m.myNickname!
                : _l.notSet,
          ),
          // A setting that could not be read claims neither state: it shows
          // as information, not as a switch that is off.
          if (m.myMuted case final muted?)
            FlareSettingsItem(
              key: 'notif',
              label: _l.muteNotif,
              icon: 'mute',
              kind: FlareSettingKind.toggle,
              value: muted,
            )
          else
            FlareSettingsItem(
              key: 'notif',
              label: _l.muteNotif,
              icon: 'mute',
              kind: FlareSettingKind.value,
              detail: _settingUnavailable,
            ),
          if (m.myPinned case final pinned?)
            FlareSettingsItem(
              key: 'pin',
              label: _l.pinGroup,
              icon: 'pin',
              kind: FlareSettingKind.toggle,
              value: pinned,
            )
          else
            FlareSettingsItem(
              key: 'pin',
              label: _l.pinGroup,
              icon: 'pin',
              kind: FlareSettingKind.value,
              detail: _settingUnavailable,
            ),
        ],
      ),
    ];
    // Each row shows only when the host's capabilities name it; an empty
    // section is not drawn.
    final manage = [
      if (_can(FlareGroupManagementEntry.discoverable))
        FlareSettingsItem(
          key: 'discoverable',
          label: _l.discoverable == FlareStrings.groupDetailDiscoverableDefault
              ? FlareStrings.of(context).groupDetailDiscoverable
              : _l.discoverable,
          icon: 'search',
          kind: FlareSettingKind.toggle,
          value: m.discoverable,
        ),
      if (_can(FlareGroupManagementEntry.joinPolicy))
        FlareSettingsItem(
          key: 'joinPolicy',
          label: _l.joinMode,
          icon: 'lock',
          // The row is shown only to a viewer who may change it, and it
          // opens the picker.
          kind: FlareSettingKind.navigation,
          // An unknown policy is shown as not set, never as a guess.
          detail: switch (m.joinPolicy) {
            final policy? => _joinPolicyLabel(policy),
            null => _l.notSet,
          },
        ),
      if (_can(FlareGroupManagementEntry.joinRequests))
        FlareSettingsItem(
          key: 'joinRequests',
          label: _l.joinRequests,
          icon: 'join-request',
          kind: FlareSettingKind.navigation,
          detail: widget.joinRequests.isNotEmpty
              ? '${widget.joinRequests.length}'
              : null,
        ),
      if (_can(FlareGroupManagementEntry.muteAll))
        FlareSettingsItem(
          key: 'muteAll',
          label: _l.muteAll,
          icon: 'silence',
          kind: FlareSettingKind.toggle,
          value: m.muteAll,
        ),
      if (_can(FlareGroupManagementEntry.inviteLink))
        FlareSettingsItem(
          key: 'inviteLink',
          label: _l.inviteLink,
          icon: 'link',
          kind: FlareSettingKind.navigation,
        ),
    ];
    if (manage.isNotEmpty) {
      sections.add(FlareSettingsSection(title: _l.manage, items: manage));
    }
    final perms = [
      if (_can(FlareGroupManagementEntry.onlyAdminCanAtAll))
        FlareSettingsItem(
          key: 'atAll',
          label: _l.onlyAdminAtAll,
          icon: 'mention',
          kind: FlareSettingKind.toggle,
          value: m.onlyAdminCanAtAll,
        ),
      if (_can(FlareGroupManagementEntry.onlyAdminCanPin))
        FlareSettingsItem(
          key: 'pinPerm',
          label: _l.onlyAdminPin,
          icon: 'pin',
          kind: FlareSettingKind.toggle,
          value: m.onlyAdminCanPin,
        ),
      if (_can(FlareGroupManagementEntry.shareCardPermission))
        FlareSettingsItem(
          key: 'shareCard',
          label: _l.shareCard,
          icon: 'share',
          kind: FlareSettingKind.toggle,
          value: m.shareCardPermission,
        ),
    ];
    if (perms.isNotEmpty) {
      sections.add(FlareSettingsSection(title: _l.perms, items: perms));
    }
    return sections;
  }

  void _onSelect(FlareSettingsItem item) {
    final m = _m;
    if (m == null) return;
    switch (item.key) {
      case 'members':
        _showMembers();
      case 'myNickname':
        if (_canEditNickname) _editNickname();
      case 'name':
        if (_can(FlareGroupManagementEntry.editName)) _editName();
      case 'announcement':
        if (_can(FlareGroupManagementEntry.editAnnouncement)) {
          _editAnnouncement();
        }
      case 'joinPolicy':
        if (_can(FlareGroupManagementEntry.joinPolicy)) _pickJoinPolicy();
      case 'joinRequests':
        if (_can(FlareGroupManagementEntry.joinRequests)) _showJoinRequests();
      case 'inviteLink':
        if (_can(FlareGroupManagementEntry.inviteLink)) _showInviteLink();
    }
  }

  void _onToggle(FlareSettingsItem item, bool value) {
    switch (item.key) {
      case 'discoverable':
        if (_can(FlareGroupManagementEntry.discoverable)) {
          widget.onToggleDiscoverable?.call(value);
        }
      case 'notif':
        widget.onToggleMyMuted?.call(value);
      case 'pin':
        widget.onToggleMyPinned?.call(value);
      case 'muteAll':
        if (_can(FlareGroupManagementEntry.muteAll)) {
          widget.onToggleMuteAll?.call(value);
        }
      case 'atAll':
        if (_can(FlareGroupManagementEntry.onlyAdminCanAtAll)) {
          widget.onSetFlag?.call('onlyAdminCanAtAll', value);
        }
      case 'pinPerm':
        if (_can(FlareGroupManagementEntry.onlyAdminCanPin)) {
          widget.onSetFlag?.call('onlyAdminCanPin', value);
        }
      case 'shareCard':
        if (_can(FlareGroupManagementEntry.shareCardPermission)) {
          widget.onSetFlag?.call('shareCardPermission', value);
        }
    }
  }

  // ── Edit dialogs ────────────────────────────────────────────────────────────
  /// One value through the kit's prompt presenter. With [FlareGroupDetail.submitEdit]
  /// the prompt waits for the host's write and resolves only once it succeeded;
  /// without it the value goes to [report] after the prompt closes.
  Future<void> _edit(
    FlareGroupEditKind kind,
    String title,
    String initial, {
    required ValueChanged<String>? report,
    String? placeholder,
    bool multiline = false,
    int? maxLength,
    bool allowEmpty = true,
  }) async {
    final submit = widget.submitEdit;
    final value = await FlareBottomSheet.prompt(
      context,
      title: title,
      initialValue: initial,
      placeholder: placeholder,
      multiline: multiline,
      maxLength: maxLength,
      allowEmpty: allowEmpty,
      confirmText: _l.save,
      cancelText: _l.cancel,
      onSubmit: submit == null ? null : (value) => submit(kind, value),
    );
    if (value != null && submit == null) report?.call(value);
  }

  Future<void> _editName() => _edit(
    FlareGroupEditKind.name,
    _l.editName,
    _m?.name ?? '',
    report: widget.onUpdateName,
    placeholder: _l.name,
    maxLength: 30,
    allowEmpty: false,
  );

  Future<void> _editAnnouncement() => _edit(
    FlareGroupEditKind.announcement,
    _l.editAnnouncement,
    _m?.announcement ?? '',
    report: widget.onUpdateAnnouncement,
    placeholder: _l.announcement,
    multiline: true,
    maxLength: 200,
  );

  Future<void> _editNickname() => _edit(
    FlareGroupEditKind.nickname,
    _l.myNickname,
    _m?.myNickname ?? '',
    report: widget.onUpdateMyNickname,
    placeholder: _l.nicknamePlaceholder,
    maxLength: 20,
  );

  // ── Join policy ─────────────────────────────────────────────────────────────
  Future<void> _pickJoinPolicy() async {
    // An unknown policy opens with nothing selected; saving waits for a pick.
    var draft = _m?.joinPolicy;
    final ok = await FlareBottomSheet.show<bool>(
      context,
      title: _l.joinMode,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => SingleChildScrollView(
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlareRadioGroup(
                vertical: true,
                value: draft?.name ?? '',
                options: [
                  for (final policy in FlareGroupJoinPolicy.values)
                    FlareSelectOption(
                      value: policy.name,
                      label: _joinPolicyLabel(policy),
                    ),
                ],
                onSelect: (v) => setSheet(
                  () => draft = FlareGroupJoinPolicy.values.byName(v),
                ),
              ),
              const SizedBox(height: FlareSizes.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: FlareButton(
                      label: _l.cancel,
                      variant: FlareButtonVariant.secondary,
                      onPressed: () => Navigator.pop(c, false),
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingMd),
                  Expanded(
                    child: FlareButton(
                      label: _l.save,
                      disabled: draft == null,
                      onPressed: () => Navigator.pop(c, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final picked = draft;
    if (ok == true && picked != null) widget.onSetJoinPolicy?.call(picked);
  }

  // ── Join requests ─────────────────────────────────────────────────────────────
  Future<void> _showJoinRequests() async {
    widget.onLoadJoinRequests?.call();
    // A request the viewer just answered keeps its row, with its buttons off,
    // until the host's list changes: the host's reload drops it once the
    // answer landed, and a failed answer comes back usable.
    final answered = <String>{};
    List<FlareGroupJoinRequestView>? seen;
    await FlareBottomSheet.show<void>(
      context,
      title: _l.joinRequests,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => ValueListenableBuilder(
          valueListenable: _joinRequests,
          builder: (c, state, _) {
            final (requests, loading) = state;
            if (!identical(requests, seen)) {
              seen = requests;
              answered.clear();
            }
            void answer(FlareGroupJoinRequestView r, bool accept) {
              if (answered.contains(r.requestId)) return;
              setSheet(() => answered.add(r.requestId));
              widget.onRespondRequest?.call(r.requestId, accept);
            }

            return Column(
              children: [
                Expanded(
                  child: loading
                      ? Center(child: Text(_l.loading))
                      : requests.isEmpty
                      ? Center(child: Text(_l.noRequests))
                      : ListView(
                          children: requests
                              .map(
                                (r) => ListTile(
                                  leading: FlareAvatar(
                                    userId: r.applicantId,
                                    displayName: r.applicantName,
                                    avatarUrl: r.avatarUrl,
                                    size: 44,
                                  ),
                                  title: Text(r.applicantName),
                                  subtitle: (r.message?.isNotEmpty ?? false)
                                      ? Text(r.message!)
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FlareButton(
                                        label: _l.reject,
                                        size: FlareControlSize.sm,
                                        variant: FlareButtonVariant.secondary,
                                        disabled: answered.contains(
                                          r.requestId,
                                        ),
                                        onPressed: () => answer(r, false),
                                      ),
                                      const SizedBox(
                                        width: FlareSizes.spacingSm,
                                      ),
                                      FlareButton(
                                        label: _l.approve,
                                        size: FlareControlSize.sm,
                                        disabled: answered.contains(
                                          r.requestId,
                                        ),
                                        onPressed: () => answer(r, true),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Invite link ───────────────────────────────────────────────────────────────
  Future<void> _showInviteLink() async {
    widget.onEnsureInviteLink?.call();
    await FlareBottomSheet.show<void>(
      context,
      title: _l.inviteLink,
      builder: (c) => SingleChildScrollView(
        padding: const EdgeInsets.all(FlareSizes.spacingXl),
        child: ValueListenableBuilder(
          valueListenable: _invite,
          builder: (c, invite, _) {
            final (code, loading) = invite;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _l.inviteLinkHint,
                  style: TextStyle(
                    color: FlareColors.of(c).textSecondary,
                    fontSize: FlareSizes.fontSizeLg,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingLg),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (code != null && code.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(FlareSizes.spacingLg),
                    decoration: BoxDecoration(
                      color: FlareColors.of(c).bgSecondary,
                      borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                    ),
                    child: SelectableText(
                      code,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: FlareSizes.spacingLg),
                  FlareButton(
                    block: true,
                    label: _l.copyCode,
                    icon: 'copy',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (c.mounted) Navigator.pop(c);
                    },
                  ),
                ] else
                  Text(
                    _l.cannotGenerate,
                    style: TextStyle(color: FlareColors.of(c).textTertiary),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Members ────────────────────────────────────────────────────────────────────
  /// Every member, searchable by name. Choosing one opens the member actions
  /// when the host allows any on that member, once the sheet has closed.
  Future<void> _showMembers() async {
    final strings = FlareStrings.of(context);
    final count = _m?.memberCount ?? _m?.members.length ?? 0;
    final chosen = await FlareBottomSheet.show<String>(
      context,
      title: strings.groupDetailMembersTitle(count),
      builder: (c) => ValueListenableBuilder(
        valueListenable: _model,
        builder: (c, m, _) => _GroupMembersSheet(
          model: m,
          onSearchMembers: widget.onSearchMembers,
          onSelect: (member) {
            if (m == null || groupDetailMemberActions(m, member.id).isEmpty) {
              return;
            }
            Navigator.pop(c, member.id);
          },
        ),
      ),
    );
    if (chosen != null && mounted) _onMemberSelect(chosen);
  }

  // ── Member actions ─────────────────────────────────────────────────────────────
  /// A member the host allows nothing on opens no sheet.
  void _onMemberSelect(String id) {
    final m = _m;
    if (m == null || groupDetailMemberActions(m, id).isEmpty) return;
    _memberActions(id);
  }

  Future<void> _memberActions(String id) async {
    await FlareBottomSheet.show<void>(
      context,
      title: _l.memberManage,
      builder: (c) => SingleChildScrollView(
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
        // Labels follow the current model, and each intent carries the state
        // its label names, so the host never re-derives the direction.
        child: ValueListenableBuilder(
          valueListenable: _model,
          builder: (c, m, _) => _memberActionList(c, id, m),
        ),
      ),
    );
  }

  Widget _memberActionList(
    BuildContext c,
    String id,
    FlareGroupDetailModel? m,
  ) {
    // Exactly what the host allows on this member, labelled by its current
    // state (Vue `groupDetailMemberActions`).
    final entries = m == null
        ? const <FlareMemberRoleActionEntry>[]
        : groupDetailMemberActions(m, id);
    final buttons = <Widget>[];
    for (final entry in entries) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: FlareSizes.spacingSm));
      }
      buttons.add(
        FlareButton(
          block: true,
          variant: entry.action == FlareMemberRoleAction.remove
              ? FlareButtonVariant.danger
              : FlareButtonVariant.secondary,
          label: switch (entry.action) {
            FlareMemberRoleAction.promote => _l.setAdmin,
            FlareMemberRoleAction.demote => _l.unsetAdmin,
            FlareMemberRoleAction.mute => _l.mute,
            FlareMemberRoleAction.unmute => _l.unmute,
            FlareMemberRoleAction.transferOwner => _l.transferOwner,
            FlareMemberRoleAction.remove => _l.removeMember,
          },
          onPressed: () {
            Navigator.pop(c);
            switch (entry.action) {
              case FlareMemberRoleAction.promote:
                widget.onPromoteMember?.call(id, true);
              case FlareMemberRoleAction.demote:
                widget.onPromoteMember?.call(id, false);
              case FlareMemberRoleAction.mute:
                widget.onMuteMember?.call(id, true);
              case FlareMemberRoleAction.unmute:
                widget.onMuteMember?.call(id, false);
              case FlareMemberRoleAction.transferOwner:
                _confirmTransfer(id);
              case FlareMemberRoleAction.remove:
                widget.onRemoveMember?.call(id);
            }
          },
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
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
    final ok = await FlareDangerConfirm.show(
      context,
      title: _l.transferOwner,
      description: _l.transferConfirm(name),
      confirmText: _l.confirmTransfer,
      cancelText: _l.cancel,
    );
    if (ok) widget.onTransferOwner?.call(id);
  }

  // ── Invite members ─────────────────────────────────────────────────────────────
  Future<void> _openInvite() async {
    widget.onLoadContacts?.call();
    final m = _m;
    final memberIds = m?.members.map((x) => x.id).toSet() ?? <String>{};
    final options = widget.invitableContacts
        .where((c) => !memberIds.contains(c.id))
        .toList();
    final picked = <String>{};
    final ok = await FlareBottomSheet.show<bool>(
      context,
      title: _l.invite,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => Column(
          children: [
            Expanded(
              child: options.isEmpty
                  ? Center(child: Text(_l.inviteEmpty))
                  : ListView(
                      children: options
                          .map(
                            (ct) => _CheckboxListTileLike(
                              contact: ct,
                              checked: picked.contains(ct.id),
                              onTap: () => setSheet(() {
                                if (picked.contains(ct.id)) {
                                  picked.remove(ct.id);
                                } else {
                                  picked.add(ct.id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(FlareSizes.spacingLg),
              child: FlareButton(
                block: true,
                disabled: picked.isEmpty,
                label: _l.inviteConfirm(picked.length),
                onPressed: () => Navigator.pop(c, true),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true && picked.isNotEmpty)
      widget.onInviteMembers?.call(picked.toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final m = _m;
    if (m == null) {
      if (widget.loading)
        return const Center(child: CircularProgressIndicator());
      return FlareEmptyState(
        icon: 'group',
        title: _l.unavailable,
        description: _l.unavailableHint,
      );
    }
    final name = m.name.isNotEmpty ? m.name : _l.groupFallback;
    final sections = _sections();
    final afterInfo = widget.afterInfo;
    final footer = widget.footer;
    final onOpenChat = widget.onOpenChat;
    FlareSettingsList settings(List<FlareSettingsSection> shown) =>
        FlareSettingsList(
          sections: shown,
          onSelect: _onSelect,
          onToggle: _onToggle,
          shrinkWrap: true,
        );
    return ListView(
      children: [
        // Hero.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FlareSizes.spacingLg,
            FlareSizes.spacingXl,
            FlareSizes.spacingLg,
            FlareSizes.spacingSm,
          ),
          child: Column(
            children: [
              FlareAvatar(
                userId: m.groupId,
                displayName: name,
                avatarUrl: m.avatarUrl,
                size: 72,
              ),
              const SizedBox(height: FlareSizes.spacingSm),
              Text(
                name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSize3xl,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        FlareGroupMemberGrid(
          // A preview: a 500-member group does not draw 500 avatars here.
          members: m.members
              .take(
                _can(FlareGroupManagementEntry.inviteMembers)
                    ? FlareGroupDetail.previewMemberCells - 1
                    : FlareGroupDetail.previewMemberCells,
              )
              .toList(),
          total: m.memberCount,
          ownerId: m.ownerId,
          adminIds: m.adminIds,
          showAdd: _can(FlareGroupManagementEntry.inviteMembers),
          onSelect: _onMemberSelect,
          onAddMember: _openInvite,
        ),

        // The host's slot follows the group information section (the first),
        // inset like the section cards; without it the list stays one piece.
        if (afterInfo == null)
          settings(sections)
        else ...[
          settings(sections.take(1).toList()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingMd,
              0,
              FlareSizes.spacingMd,
              FlareSizes.spacingSm,
            ),
            child: afterInfo,
          ),
          settings(sections.skip(1).toList()),
        ],

        // Bottom actions.
        Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Column(
            children: [
              // Opening the chat is the host's: no handler, no button.
              if (onOpenChat != null) ...[
                FlareButton(
                  block: true,
                  size: FlareControlSize.lg,
                  label: _l.message,
                  icon: 'comment',
                  onPressed: () =>
                      onOpenChat(m.members.map((x) => x.id).toList(), name),
                ),
                const SizedBox(height: FlareSizes.spacingMd),
              ],
              for (final action in widget.extraActions) ...[
                FlareButton(
                  block: true,
                  size: FlareControlSize.lg,
                  variant: action.danger
                      ? FlareButtonVariant.danger
                      : FlareButtonVariant.secondary,
                  label: action.label,
                  onPressed: () => widget.onExtraAction?.call(action.id),
                ),
                const SizedBox(height: FlareSizes.spacingSm),
              ],
              FlareButton(
                block: true,
                size: FlareControlSize.lg,
                variant: FlareButtonVariant.danger,
                label: _can(FlareGroupManagementEntry.dissolve)
                    ? _l.dissolve
                    : _l.leave,
                // Leaving is the host's to confirm: the tap is the intent.
                onPressed: () => widget.onLeave?.call(),
              ),
            ],
          ),
        ),

        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              0,
              FlareSizes.spacingLg,
              FlareSizes.spacingLg,
            ),
            child: footer,
          ),
      ],
    );
  }
}

/// The members sheet of [FlareGroupDetail] (the sheet's title carries the
/// member count): a search field and every member matching it.
class _GroupMembersSheet extends StatefulWidget {
  const _GroupMembersSheet({
    required this.model,
    required this.onSelect,
    this.onSearchMembers,
  });

  final FlareGroupDetailModel? model;
  final ValueChanged<FlareContact> onSelect;
  final Future<List<FlareContact>> Function(String keyword)? onSearchMembers;

  @override
  State<_GroupMembersSheet> createState() => _GroupMembersSheetState();
}

class _GroupMembersSheetState extends State<_GroupMembersSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  var _remoteLoading = false;
  String? _remoteError;
  List<FlareContact>? _remoteMembers;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQuery);
  }

  void _onQuery() {
    final search = widget.onSearchMembers;
    if (search == null) {
      setState(() {});
      return;
    }
    final text = _query.text.trim();
    _debounce?.cancel();
    if (text.isEmpty) {
      _generation++;
      setState(() {
        _remoteLoading = false;
        _remoteError = null;
        _remoteMembers = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runRemoteSearch(text, search);
    });
  }

  Future<void> _runRemoteSearch(
    String text,
    Future<List<FlareContact>> Function(String keyword) search,
  ) async {
    final generation = ++_generation;
    setState(() {
      _remoteLoading = true;
      _remoteError = null;
    });
    try {
      final found = await search(text);
      if (!mounted || generation != _generation) return;
      setState(() => _remoteMembers = found);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _remoteError = e.toString());
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _remoteLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_onQuery);
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final members = widget.model?.members ?? const <FlareContact>[];
    final text = _query.text.trim().toLowerCase();
    final search = widget.onSearchMembers;
    final matching = search != null && text.isNotEmpty
        ? _remoteMembers ?? const <FlareContact>[]
        : text.isEmpty
        ? members
        : [
            for (final member in members)
              if (member.name.toLowerCase().contains(text)) member,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingLg,
            vertical: FlareSizes.spacingSm,
          ),
          child: FlareSearchBar(
            controller: _query,
            placeholder: strings.groupDetailSearchMembers,
            loading: _remoteLoading,
          ),
        ),
        Expanded(
          child: _remoteError != null
              ? Center(
                  child: Text(
                    _remoteError!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FlareSizes.fontSizeLg,
                    ),
                  ),
                )
              : matching.isEmpty && !_remoteLoading
              ? Center(
                  child: Text(
                    strings.groupDetailNoMatchingMembers,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FlareSizes.fontSizeLg,
                    ),
                  ),
                )
              : matching.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : FlareContactList(
                  items: matching,
                  indexed: false,
                  onSelect: widget.onSelect,
                ),
        ),
      ],
    );
  }
}

/// What a [FlareGroupDetail] edit changes, as [FlareGroupDetail.submitEdit]
/// receives it.
enum FlareGroupEditKind { name, announcement, nickname }

/// A brand-styled multi-select row used by the invite picker (avatar + name +
/// [FlareCheckbox]). Private helper for [FlareGroupDetail].
class _CheckboxListTileLike extends StatelessWidget {
  const _CheckboxListTileLike({
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
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg,
          vertical: FlareSizes.spacingSm,
        ),
        child: Row(
          children: [
            FlareAvatar(
              userId: contact.id,
              displayName: contact.name,
              avatarUrl: contact.avatarUrl,
              size: 36,
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Text(
                contact.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IgnorePointer(child: FlareCheckbox(value: checked)),
          ],
        ),
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
    // The component recognizes this legacy const default and resolves the
    // environment string, so a FlareStringsScope still localizes the row.
    this.discoverable = FlareStrings.groupDetailDiscoverableDefault,
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
  final String discoverable;
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
