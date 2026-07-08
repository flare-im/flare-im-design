---
title: ConversationList
---

# ConversationList

<p><span class="flare-tag">会话</span></p>

> 会话收件箱 —— 虚拟化的会话行（头像、标题、预览、未读、时间）。

**数据源**：client.views.openConversationList()；一份可观察列表，实时重排并更新未读

## 预览

<div class="flare-demo flare-demo--stack">
  <ConversationListDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `items` | `ConversationRow[]` | ✔ | — | 视图给出的有序会话行。 |
| `activeId` | `string` |  | — | 当前打开的会话，在列表中高亮。 |
| `loading` | `boolean` |  | — | 首屏加载时显示骨架 / 转圈。 |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">unread</span> <span class="flare-tag">muted</span> <span class="flare-tag">pinned</span>

## Events

<span class="flare-tag">select</span> <span class="flare-tag">longPress</span> <span class="flare-tag">loadMore</span>

> [!TIP]
> 必须虚拟化（各端用原生列表）；O(visible)，更新不整表重排。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConversationList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareConversationList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ConversationListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ConversationList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareConversationList } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareConversationList
  :items="items"
  :activeId="activeId"
  :loading="loading"
  @select="onSelect"
  @longPress="onLongPress"
  @loadMore="onLoadMore"
  />
</template>
```

```dart [Flutter]
FlareConversationList(
  items: items,
  activeId: activeId,
  loading: loading,
  onSelect: onSelect,
  onLongPress: onLongPress,
  onLoadMore: onLoadMore,
);
```

```swift [iOS]
ConversationListView(items: items, activeId: activeId, loading: loading, onSelect: onSelect, onLongPress: onLongPress, onLoadMore: onLoadMore)
```

```kotlin [Android]
ConversationList(
  items = items,
  activeId = activeId,
  loading = loading,
  onSelect = onSelect,
  onLongPress = onLongPress,
  onLoadMore = onLoadMore,
)
```

:::


## 示例

### 收件箱

items 来自 client.views.openConversationList()，实时重排与未读更新；活动会话高亮。

::: code-group

```vue [Vue]
<FlareConversationList :items="rows" :active-id="openId" @select="open" @long-press="rowMenu" />
```

```dart [Flutter]
FlareConversationList(items: rows, activeId: openId, onSelect: (r) => open(r.id), onLongPress: rowMenu)
```

```swift [iOS]
ConversationListView(items: rows, activeId: openId) { row in open(row.id) }
```

```kotlin [Android]
ConversationList(items = rows, activeId = openId, onSelect = { open(it.id) })
```

:::
