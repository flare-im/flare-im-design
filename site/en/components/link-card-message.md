---
title: LinkCardMessage
---

# LinkCardMessage

<p><span class="flare-tag">Message</span></p>

> Link card — thumbnail + title + domain.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <LinkCardMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | Link title. |
| `domain` | `string` |  | — | Domain shown with a link glyph. |


## States

_None_

## Events

<span class="flare-tag">open</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareLinkCardMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareLinkCardMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>LinkCardMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>LinkCardMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareLinkCardMessage } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareLinkCardMessage
  :title="title"
  :domain="domain"
  @open="onOpen"
  />
</template>
```

```dart [Flutter]
FlareLinkCardMessage(
  title: title,
  domain: domain,
  onOpen: onOpen,
);
```

```swift [iOS]
LinkCardMessageView(title: title, domain: domain, onOpen: onOpen)
```

```kotlin [Android]
LinkCardMessage(
  title = title,
  domain = domain,
  onOpen = onOpen,
)
```

:::

