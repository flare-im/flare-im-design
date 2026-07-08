---
title: TextMessage
---

# TextMessage

<p><span class="flare-tag">Message</span></p>

> Text message body — linkifies bare URLs; self flips to the brand bubble.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <TextMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `text` | `string` | ✔ | — | The text to render. |
| `self` | `boolean` |  | — | Render the outgoing (brand-purple) side. |
| `selectable` | `boolean` |  | — | Allow the text to be selected/copied. |


## States

_None_

## Events

<span class="flare-tag">linkClick</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareTextMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareTextMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>TextMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>TextMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareTextMessage } from "flare-core-vue-im-ui";
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

