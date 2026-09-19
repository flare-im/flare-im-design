# Recipe: Build the Group Member Panel

Group details: name, announcement, your nickname and notification settings, members and their roles, join requests, invites, leaving the group. The kit's `GroupDetail` owns the whole surface; the app supplies the model and performs each intent. This recipe follows the golden reference app (`flare-social-web-app/src/components/GroupDetailPanel.vue`).

## Components

| Region | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Page with back | `FlareScreen` (`back`) | `FlareScreen` (`onBack`) | `FlareScreen` | `FlareScreen` (`onBack`, registers system back) |
| Group detail and management | `FlareGroupDetail` | `FlareGroupDetail` | `FlareGroupDetail` | `FlareGroupDetail` |
| Announcement read state | `FlareAnnouncementReadBar` | `FlareAnnouncementReadBar` | `AnnouncementReadBarView` | `AnnouncementReadBar` |
| Destructive confirmation | `useFlareConfirm` (the app confirms remove and leave) | inside `FlareGroupDetail` for leave and transfer; `FlareDangerConfirm.show` for remove | inside `FlareGroupDetail` through `FlareFeedback` | inside `FlareGroupDetail` for leave |
| Member picker and rows with an action | `FlareContactList` with `selectable` / `#trailing` | `FlareContactList` (`selectable`, `trailingBuilder`) | `ContactListView` (`selectable`, `trailing`) | `ContactList` (`selectable`, `trailing`) |

## Composition (Vue)

```vue
<script setup lang="ts">
import { FlareGroupDetail, FlareScreen, useFlareConfirm, type FlareGroupDetailModel } from "@flare-im/vue-ui";

const confirm = useFlareConfirm();

function onRemoveMember(memberId: string) {
  void confirm({
    title: "移出成员",
    description: "被移出的成员不再接收这个群的消息。",
    target: model.value?.members.find((member) => member.id === memberId)?.name ?? "",
    confirmText: "移出",
    action: () => removeGroupMember(props.groupId, memberId),
  });
}
// The owner dissolves; everyone else leaves. Both are irreversible for the viewer.
function onLeave() {
  const owner = Boolean(model.value?.isOwner);
  void confirm({
    title: owner ? "解散群聊" : "退出群聊",
    description: owner ? "解散后所有成员都会被移出，群聊无法恢复。" : "退出后不再接收这个群的消息。",
    target: model.value?.name ?? "",
    confirmText: owner ? "解散" : "退出",
    action: async () => {
      if (owner) await dissolveGroup(props.groupId);
      else await leaveGroup(props.groupId);
      emit("left");
    },
  });
}
</script>

<template>
  <FlareScreen back surface="canvas" @back="emit('back')">
    <FlareGroupDetail
      :model="model"
      :loading="loadingGroupDetail"
      :join-requests="groupJoinRequests"
      :invite-code="groupInviteLink?.inviteCode"
      :invitable-contacts="invitable"
      @back="emit('back')"
      @open-chat="onOpenChat"
      @update-name="updateGroupInfo(props.groupId, { name: $event })"
      @update-announcement="updateGroupAnnouncement(props.groupId, $event)"
      @toggle-mute-all="setGroupMuteAll(props.groupId, $event)"
      @promote-member="(userId: string, admin: boolean) => setGroupMemberAdmin(props.groupId, userId, admin)"
      @mute-member="(userId: string, muted: boolean) => setGroupMemberMuted(props.groupId, userId, muted)"
      @transfer-owner="transferGroupOwner(props.groupId, $event)"
      @remove-member="onRemoveMember"
      @invite-members="inviteGroupMembers(props.groupId, $event)"
      @leave="onLeave"
    />
  </FlareScreen>
</template>
```

The reference app builds the model from its directory store: members are `FlareContact` rows (`id`, `name`), with `ownerId`, `adminIds`, `mutedIds`, `canManage` and `isOwner`.

`promoteMember` and `muteMember` carry the state the viewer asked for, the one the member sheet's button named (`admin` true sets admin, false revokes it). Write that state; don't recompute the direction from your own copy of the member list, which may have changed since the sheet opened.

## The model is the permission source

`FlareGroupDetailModel` carries the viewer's role (`canManage`, `isOwner`, `ownerId`, `adminIds`) and each member's state (`mutedIds`). The kit gates the management sections on those fields, so the app must fill them from the server, not assume them. The viewer's own settings (`myNickname`, `myMuted`, `myPinned`) are always editable.

## Presentation by width

| Width | Presentation |
|---|---|
| Desktop and wide desktop | Third pane beside the conversation (IMAppKit `#detail`, `hasDetail`) |
| Phone | Full page (IMAppKit `activePane: "detail"`); bottom navigation hidden |
| Android | System back closes the page, because the kit `FlareScreen` and `FlareGroupDetail` register back |

## States

| State | Behaviour |
|---|---|
| Loading | `loading` shows the detail skeleton; Vue shows a loading state while there is no model yet |
| Large groups | The grid previews 20 members and its title counts the whole group from `total`; the 群成员 row opens a searchable list of every loaded member, and picking one opens the same member actions as the grid (four kits) |
| Viewer cannot manage | Name and announcement are values, not editable rows; editable rows carry a chevron |
| Long announcement | Wraps under its label (up to three lines) instead of squeezing the label |
| Write fails | Show the failure as a danger toast and reload; don't swallow it (the Tauri app did until Round 3) |
| Remove, leave, dissolve | Confirmed first, with busy, error and retry: by the app on Vue, inside `GroupDetail` on the native kits |
| Transfer ownership | The kit asks for confirmation inside its member sheet before it emits `transferOwner` (a second confirmation surface; see FR-022) |
| Join requests | Loaded on demand (`load-join-requests`), approved or rejected per request |

## Known gaps

- Member search has no SDK op (SDK gap S4 in `docs/product/product-refinement-audit.md`), so the member list filters the members the app loaded and large groups cannot be searched server-side.
- A member's group pin and notification mode can disagree with the conversation row's pin and mute (S11); read and write them through the group settings in group details.
- `MemberPanel`, `MemberRoleSheet` and `GroupPermissionMatrix` duplicate parts of `GroupDetail` and are marked MERGE in `docs/components/component-catalog.md`. Use `GroupDetail`.
