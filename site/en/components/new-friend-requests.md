---
title: NewFriendRequests
---

# NewFriendRequests

<p><span class="flare-tag">Contacts</span></p>

> New friends — friend-request list with accept/reject and request notes.

**Data source**: friend-request view

## Preview

<div class="flare-demo flare-demo--stack">
  <NewFriendRequestsDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `items` | [`FriendRequest[]`](/en/reference/data-types#friend-request) | ✔ | — | Pending and resolved requests to list. |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">pending</span>

## Events

<span class="flare-tag">accept</span> <span class="flare-tag">reject</span> <span class="flare-tag">view</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareNewFriendRequests</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareNewFriendRequests</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>NewFriendRequestsView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>NewFriendRequests</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareNewFriendRequests } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareNewFriendRequests
  :items="items"
  @accept="onAccept"
  @reject="onReject"
  @view="onView"
  />
</template>
```

```dart [Flutter]
FlareNewFriendRequests(
  items: items,
  onAccept: onAccept,
  onReject: onReject,
  onView: onView,
);
```

```swift [iOS]
NewFriendRequestsView(items: items, onAccept: onAccept, onReject: onReject, onView: onView)
```

```kotlin [Android]
NewFriendRequests(
  items = items,
  onAccept = onAccept,
  onReject = onReject,
  onView = onView,
)
```

:::

