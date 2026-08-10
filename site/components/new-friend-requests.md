---
title: NewFriendRequests
---

# NewFriendRequests

<p><span class="flare-tag">通讯录</span></p>

> 新的朋友 —— 好友申请列表，接受 / 拒绝，带申请附言。

**数据源**：好友申请视图

## 预览

<div class="flare-demo flare-demo--stack">
  <NewFriendRequestsDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `items` | [`FriendRequest[]`](/reference/data-types#friend-request) | ✓ | — | 待处理与已处理的申请列表。 |
| `emptyText` | `string` |  | — | 无好友申请时的空态标题。默认 "No new friend requests"。 |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">pending</span>

## Events

<span class="flare-tag">accept</span> <span class="flare-tag">reject</span> <span class="flare-tag">view</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareNewFriendRequests</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareNewFriendRequests</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>NewFriendRequestsView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>NewFriendRequests</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareNewFriendRequests } from "@flare-im/vue-ui";
</script>
<template>
  <FlareNewFriendRequests
  :items="items"
  :emptyText="emptyText"
  @accept="onAccept"
  @reject="onReject"
  @view="onView"
  />
</template>
```

```dart [Flutter]
FlareNewFriendRequests(
  items: items,
  emptyText: emptyText,
  onAccept: onAccept,
  onReject: onReject,
  onView: onView,
);
```

```swift [iOS]
NewFriendRequestsView(items: items, emptyText: emptyText, onAccept: onAccept, onReject: onReject, onView: onView)
```

```kotlin [Android]
NewFriendRequests(
  items = items,
  emptyText = emptyText,
  onAccept = onAccept,
  onReject = onReject,
  onView = onView,
)
```

:::

