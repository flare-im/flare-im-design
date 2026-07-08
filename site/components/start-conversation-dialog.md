---
title: StartConversationDialog
---

# StartConversationDialog

<p><span class="flare-tag">会话</span></p>

> 发起会话入口 —— 选联系人或建群。

**数据源**：联系人 / 通讯录由产品提供；确认经 client 创建 / 打开会话

## 预览

<div class="flare-demo flare-demo--stack">
  <StartConversationDialogDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `busy` | `boolean` |  | — | 创建中禁用确认并转圈。 |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">busy</span>

## Events

<span class="flare-tag">confirm</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareStartConversationDialog</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareStartConversationSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>StartConversationView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>StartConversationDialog</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareStartConversationDialog } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareStartConversationDialog
  :busy="busy"
  @confirm="onConfirm"
  />
</template>
```

```dart [Flutter]
FlareStartConversationSheet(
  busy: busy,
  onConfirm: onConfirm,
);
```

```swift [iOS]
StartConversationView(busy: busy, onConfirm: onConfirm)
```

```kotlin [Android]
StartConversationDialog(
  busy = busy,
  onConfirm = onConfirm,
)
```

:::

