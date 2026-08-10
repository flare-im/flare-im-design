---
title: EmptyState
---

# EmptyState

<p><span class="flare-tag">通用</span></p>

> 空状态占位 —— 图标 + 标题 + 说明 + 可选操作，用于空会话 / 空搜索 / 空联系人。

**数据源**：纯展示

## 预览

<div class="flare-demo flare-demo--stack">
  <EmptyStateDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `title` | `string` | ✓ | — | 说明空状态的主标题。 |
| `description` | `string` |  | — | 次级说明文字。 |
| `actionText` | `string` |  | — | 可选行动按钮的文案。 |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">action</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareEmptyState</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareEmptyState</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>EmptyStateView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>EmptyState</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareEmptyState } from "@flare-im/vue-ui";
</script>
<template>
  <FlareEmptyState
  :title="title"
  :description="description"
  :actionText="actionText"
  @action="onAction"
  />
</template>
```

```dart [Flutter]
FlareEmptyState(
  title: title,
  description: description,
  actionText: actionText,
  onAction: onAction,
);
```

```swift [iOS]
EmptyStateView(title: title, description: description, actionText: actionText, onAction: onAction)
```

```kotlin [Android]
EmptyState(
  title = title,
  description = description,
  actionText = actionText,
  onAction = onAction,
)
```

:::

