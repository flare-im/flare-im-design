---
title: GroupList
---

# GroupList

<p><span class="flare-tag">通讯录</span></p>

> 我的群组 —— 群头像、名称、成员数。

**数据源**：群组视图

## 预览

<div class="flare-demo flare-demo--stack">
  <GroupListDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `items` | [`GroupSummary[]`](/reference/data-types#group-summary) | ✔ | — | 要列出的群摘要。 |
| `emptyText` | `string` |  | — | 无群组时的空态标题。默认 "No groups yet"。 |


## States

<span class="flare-tag">empty</span>

## Events

<span class="flare-tag">select</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareGroupList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareGroupList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>GroupListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>GroupList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareGroupList } from "@flare-im/vue-ui";
</script>
<template>
  <FlareGroupList
  :items="items"
  :emptyText="emptyText"
  @select="onSelect"
  />
</template>
```

```dart [Flutter]
FlareGroupList(
  items: items,
  emptyText: emptyText,
  onSelect: onSelect,
);
```

```swift [iOS]
GroupListView(items: items, emptyText: emptyText, onSelect: onSelect)
```

```kotlin [Android]
GroupList(
  items = items,
  emptyText = emptyText,
  onSelect = onSelect,
)
```

:::

