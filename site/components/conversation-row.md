---
title: ConversationRow
---

# ConversationRow

<p><span class="flare-tag">会话</span></p>

> 单个会话行 —— 头像、标题、末条 / 草稿预览、未读角标、时间、免打扰 / 置顶标记。

**数据源**：会话列表视图里的一条 ConversationRow

## 预览

<div class="flare-demo">
  <ConversationRowDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `item` | `ConversationRow` | ✔ | — | 该行数据（标题、预览、未读、时间、标记）。 |
| `active` | `boolean` |  | — | 渲染选中 / 打开态。 |
| `draftPreview` | `string` |  | — | 未发送的草稿文本；替代末条消息显示。 |


## States

<span class="flare-tag">unread</span> <span class="flare-tag">muted</span> <span class="flare-tag">pinned</span> <span class="flare-tag">active</span>

## Events

<span class="flare-tag">select</span> <span class="flare-tag">action</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConversationRow</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareConversationRow</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ConversationRowView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ConversationRow</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareConversationRow } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareConversationRow
  :item="item"
  :active="active"
  :draftPreview="draftPreview"
  @select="onSelect"
  @action="onAction"
  />
</template>
```

```dart [Flutter]
FlareConversationRow(
  item: item,
  active: active,
  draftPreview: draftPreview,
  onSelect: onSelect,
  onAction: onAction,
);
```

```swift [iOS]
ConversationRowView(item: item, active: active, draftPreview: draftPreview, onSelect: onSelect, onAction: onAction)
```

```kotlin [Android]
ConversationRow(
  item = item,
  active = active,
  draftPreview = draftPreview,
  onSelect = onSelect,
  onAction = onAction,
)
```

:::

