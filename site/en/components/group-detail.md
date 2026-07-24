---
title: GroupDetail
---

# GroupDetail

<p><span class="flare-tag">Contacts</span></p>

> Group detail/management — info / my settings / management / permissions + member grid + member actions + join approval + invite link.

**Data source**: a group's `FlareGroupDetailModel` + join requests / invite code; the component only emits intents — the host performs `social.group.*` writes and refreshes the model.

## Preview

<div class="flare-demo flare-demo--stack">
  <GroupDetailDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `model` | `FlareGroupDetailModel` | ✔ | — | Group detail/management model (info, members, roles, my-in-group state, join mode, permission flags…). |
| `joinRequests` | `FlareGroupJoinRequestView[]` | — | `[]` | Pending join requests to approve/reject. |
| `inviteCode` | `string` | — | — | Group invite code to share. |
| `invitableContacts` | `Contact[]` | — | `[]` | Friends that can be invited into the group. |

## States

<span class="flare-tag">default</span> <span class="flare-tag">canManage</span>

## Events

<span class="flare-tag">back</span> <span class="flare-tag">openChat</span> <span class="flare-tag">updateName</span> <span class="flare-tag">updateAnnouncement</span> <span class="flare-tag">updateMyNickname</span> <span class="flare-tag">setJoinPolicy</span> <span class="flare-tag">toggleMuteAll</span> <span class="flare-tag">setFlag</span> <span class="flare-tag">toggleMyMuted</span> <span class="flare-tag">toggleMyPinned</span> <span class="flare-tag">loadJoinRequests</span> <span class="flare-tag">respondRequest</span> <span class="flare-tag">ensureInviteLink</span> <span class="flare-tag">promoteMember</span> <span class="flare-tag">muteMember</span> <span class="flare-tag">transferOwner</span> <span class="flare-tag">removeMember</span> <span class="flare-tag">loadContacts</span> <span class="flare-tag">inviteMembers</span> <span class="flare-tag">leave</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>

## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareGroupDetail } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareGroupDetail
    :model="model"
    :join-requests="joinRequests"
    :invite-code="inviteCode"
    :invitable-contacts="invitable"
    @update-name="onUpdateName"
    @set-join-policy="onSetJoinPolicy"
    @respond-request="onRespondRequest"
    @leave="onLeave"
  />
</template>
```

```dart [Flutter]
FlareGroupDetail(
  model: model,
  joinRequests: joinRequests,
  inviteCode: inviteCode,
  invitableContacts: invitable,
  onUpdateName: onUpdateName,
  onSetJoinPolicy: onSetJoinPolicy,
  onRespondRequest: onRespondRequest,
  onLeave: onLeave,
);
```

```swift [iOS]
FlareGroupDetail(
  model: model,
  joinRequests: joinRequests,
  inviteCode: inviteCode,
  invitableContacts: invitable,
  onUpdateName: onUpdateName,
  onSetJoinPolicy: onSetJoinPolicy,
  onRespondRequest: onRespondRequest,
  onLeave: onLeave
)
```

```kotlin [Android]
FlareGroupDetail(
  model = model,
  joinRequests = joinRequests,
  inviteCode = inviteCode,
  invitableContacts = invitable,
  onUpdateName = onUpdateName,
  onSetJoinPolicy = onSetJoinPolicy,
  onRespondRequest = onRespondRequest,
  onLeave = onLeave,
)
```

:::
