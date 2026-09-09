---
title: AnnouncementReadBar
---

# AnnouncementReadBar

<p><span class="flare-tag">通用</span></p>

> 群公告已读条 —— 未确认时显示确认按钮，已确认后转为「x/y 已读」。计数取自服务端权威值，不由未读名单长度反推（名单是截断的）。

**数据源**：由你传入（SDK announcement_read_status）



## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `readCount` | `number` | ✓ | — | 已读人数（服务端权威计数）。 |
| `memberCount` | `number` | ✓ | — | 成员总数（服务端权威计数）。 |
| `selfRead` | `boolean` | ✓ | — | 当前用户是否已确认，决定显示确认按钮还是计数。 |
| `canViewUnread` | `boolean` |  | — | 是否显示「查看未读」入口（一般仅管理员）。 |


## States

<span class="flare-tag">unread</span> <span class="flare-tag">read</span>

## Events

<span class="flare-tag">confirm</span> <span class="flare-tag">viewUnread</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareAnnouncementReadBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareAnnouncementReadBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>AnnouncementReadBarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>AnnouncementReadBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

