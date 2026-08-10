---
title: TextMessage
---

# TextMessage

<p><span class="flare-tag">消息</span></p>

> 文本消息体 —— 自动识别链接；self 切换为己方品牌气泡。

**数据源**：产品直接喂 props —— 解耦的展示型消息体（无 SDK / 媒体耦合）。分发器 MessageContentView 由 message.content 构建它们。

## 预览

<div class="flare-demo">
  <TextMessageDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `text` | `string` | ✓ | — | 要渲染的文本。 |
| `self` | `boolean` |  | — | 渲染发送方（品牌紫）一侧。 |
| `selectable` | `boolean` |  | — | 允许文本被选中 / 复制。 |


## States

_无_

## Events

<span class="flare-tag">linkClick</span>

> [!TIP]
> 解耦的展示型组件 —— 由你直接喂 props。实时、SDK 驱动的消息请交给 [MessageContentView](/components/message-content-view) 按 `content.type` 自动分派。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareTextMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareTextMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>TextMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>TextMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareTextMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareTextMessage
  :text="text"
  :self="self"
  :selectable="selectable"
  @linkClick="onLinkClick"
  />
</template>
```

```dart [Flutter]
FlareTextMessage(
  text: text,
  self: self,
  selectable: selectable,
  onLinkClick: onLinkClick,
);
```

```swift [iOS]
TextMessageView(text: text, self: self, selectable: selectable, onLinkClick: onLinkClick)
```

```kotlin [Android]
TextMessage(
  text = text,
  self = self,
  selectable = selectable,
  onLinkClick = onLinkClick,
)
```

:::

