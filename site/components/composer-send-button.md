---
title: ComposerSendButton
---

# ComposerSendButton

<p><span class="flare-tag">输入</span></p>

> 发送按钮 —— active 时品牌紫、否则禁用。可自由组合的 Composer 部件。

**数据源**：纯展示 —— 传入 `active`，仅 active 时经 `send` 回调发出

## 预览

<div class="flare-demo">
  <ComposerSendButtonDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `active` | `boolean` | ✓ | — | 有内容可发时为可点 / 紫色。 |
| `label` | `string` |  | `Send` | 无障碍标签。 |


## States

<span class="flare-tag">disabled</span> <span class="flare-tag">active</span>

## Events

<span class="flare-tag">send</span>

> [!TIP]
> 属于 [Composer](/components/composer) 的部件 —— 可单独使用，自拼输入栏。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareComposerSendButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareComposerSendButton } from "@flare-im/vue-ui";
</script>
<template>
  <FlareComposerSendButton
  :active="active"
  :label="label"
  @send="onSend"
  />
</template>
```

```dart [Flutter]
FlareComposerSendButton(
  active: active,
  label: label,
  onSend: onSend,
);
```

```swift [iOS]
FlareComposerSendButton(active: active, label: label, onSend: onSend)
```

```kotlin [Android]
FlareComposerSendButton(
  active = active,
  label = label,
  onSend = onSend,
)
```

:::

