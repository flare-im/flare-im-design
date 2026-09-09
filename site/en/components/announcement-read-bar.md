---
title: AnnouncementReadBar
---

# AnnouncementReadBar

<p><span class="flare-tag">General</span></p>

> Announcement read bar — a confirm button while unread, switching to an x/y read count once confirmed. Counts come from the server; never derive them from the truncated unread list.

**Data source**: passed in by you (SDK announcement_read_status)



## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `readCount` | `number` | ✓ | — | Read count (authoritative, from server). |
| `memberCount` | `number` | ✓ | — | Member count (authoritative, from server). |
| `selfRead` | `boolean` | ✓ | — | Whether the viewer confirmed; decides button vs count. |
| `canViewUnread` | `boolean` |  | — | Show the view-unread entry (admins only, typically). |


## States

<span class="flare-tag">unread</span> <span class="flare-tag">read</span>

## Events

<span class="flare-tag">confirm</span> <span class="flare-tag">viewUnread</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareAnnouncementReadBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareAnnouncementReadBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>AnnouncementReadBarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>AnnouncementReadBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareAnnouncementReadBar } from "@flare-im/vue-ui";
</script>
<template>
  <FlareAnnouncementReadBar
  :readCount="readCount"
  :memberCount="memberCount"
  :selfRead="selfRead"
  @confirm="onConfirm"
  @viewUnread="onViewUnread"
  />
</template>
```

```dart [Flutter]
FlareAnnouncementReadBar(
  readCount: readCount,
  memberCount: memberCount,
  selfRead: selfRead,
  onConfirm: onConfirm,
  onViewUnread: onViewUnread,
);
```

```swift [iOS]
AnnouncementReadBarView(readCount: readCount, memberCount: memberCount, selfRead: selfRead, onConfirm: onConfirm, onViewUnread: onViewUnread)
```

```kotlin [Android]
AnnouncementReadBar(
  readCount = readCount,
  memberCount = memberCount,
  selfRead = selfRead,
  onConfirm = onConfirm,
  onViewUnread = onViewUnread,
)
```

:::

