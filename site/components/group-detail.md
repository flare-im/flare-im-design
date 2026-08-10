---
title: GroupDetail
---

# GroupDetail

<p><span class="flare-tag">通讯录</span></p>

> 群详情 / 管理 —— 群信息 / 我在本群 / 群管理 / 群权限 + 成员网格 + 成员操作 + 入群审批 + 邀请链接。

**数据源**：群的 `FlareGroupDetailModel` + 入群申请 / 邀请码；组件只发意图，宿主执行 `social.group.*` 写入并刷新 model。

## 预览

<div class="flare-demo flare-demo--stack">
  <GroupDetailDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `model` | `FlareGroupDetailModel` | ✓ | — | 群详情 / 管理数据模型（群信息、成员、角色、我在本群态、进群方式、权限位…）。 |
| `joinRequests` | `FlareGroupJoinRequestView[]` | — | `[]` | 待处理的入群申请。 |
| `inviteCode` | `string` | — | — | 可分享的群邀请码。 |
| `invitableContacts` | `Contact[]` | — | `[]` | 可邀请入群的好友。 |

## States

<span class="flare-tag">default</span> <span class="flare-tag">canManage</span>

## Events

<span class="flare-tag">back</span> <span class="flare-tag">openChat</span> <span class="flare-tag">updateName</span> <span class="flare-tag">updateAnnouncement</span> <span class="flare-tag">updateMyNickname</span> <span class="flare-tag">setJoinPolicy</span> <span class="flare-tag">toggleMuteAll</span> <span class="flare-tag">setFlag</span> <span class="flare-tag">toggleMyMuted</span> <span class="flare-tag">toggleMyPinned</span> <span class="flare-tag">loadJoinRequests</span> <span class="flare-tag">respondRequest</span> <span class="flare-tag">ensureInviteLink</span> <span class="flare-tag">promoteMember</span> <span class="flare-tag">muteMember</span> <span class="flare-tag">transferOwner</span> <span class="flare-tag">removeMember</span> <span class="flare-tag">loadContacts</span> <span class="flare-tag">inviteMembers</span> <span class="flare-tag">leave</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareGroupDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>

## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareGroupDetail } from "@flare-im/vue-ui";
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
