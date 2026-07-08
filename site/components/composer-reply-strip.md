---
title: ComposerReplyStrip
---

# ComposerReplyStrip

<p><span class="flare-tag">输入</span></p>

> 回复条 —— 回复时显示在输入框上方：左侧品牌竖条 + 发送者 / 摘要 + 取消。

**数据源**：纯展示 —— 传入 sender + summary，经 `cancel` 回调取消

## 预览

<div class="flare-demo">
  <ComposerReplyStripDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `senderName` | `string` | ✔ | — | 被回复者的名称。 |
| `summary` | `string` | ✔ | — | 被引用消息的一行预览。 |
| `label` | `string` |  | `Reply` | 发送者前的引导文案。 |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">cancel</span>

> [!TIP]
> 属于 [Composer](/components/composer) 的部件 —— 可单独使用，自拼输入栏。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareComposerReplyStrip</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareComposerReplyStrip } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareComposerReplyStrip
  :senderName="senderName"
  :summary="summary"
  :label="label"
  @cancel="onCancel"
  />
</template>
```

```dart [Flutter]
FlareComposerReplyStrip(
  senderName: senderName,
  summary: summary,
  label: label,
  onCancel: onCancel,
);
```

```swift [iOS]
FlareComposerReplyStrip(senderName: senderName, summary: summary, label: label, onCancel: onCancel)
```

```kotlin [Android]
FlareComposerReplyStrip(
  senderName = senderName,
  summary = summary,
  label = label,
  onCancel = onCancel,
)
```

:::

