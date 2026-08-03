---
title: ContactMessage
---

# ContactMessage

<p><span class="flare-tag">Message</span></p>

> Contact / business card — pastel avatar + name / id.

**Data source**: product-provided props — a decoupled presentational body (no SDK/media coupling). The dispatcher MessageContentView builds these from message.content.

## Preview

<div class="flare-demo">
  <ContactMessageDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `name` | `string` | ✔ | — | Contact name (drives the pastel avatar). |
| `avatarUrl` | `string` |  | — | Avatar image; falls back to a pastel initials chip. |
| `subtitle` | `string` |  | — | Free secondary line (handle, id, department…). |


## States

_None_

## Events

<span class="flare-tag">open</span>

> [!TIP]
> Decoupled & presentational — you pass simple props. For live, SDK-driven messages, let [MessageContentView](/en/components/message-content-view) dispatch by `content.type` instead.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactMessageView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactMessage</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareContactMessage } from "@flare-im/vue-ui";
</script>
<template>
  <FlareContactMessage
  :name="name"
  :avatarUrl="avatarUrl"
  :subtitle="subtitle"
  @open="onOpen"
  />
</template>
```

```dart [Flutter]
FlareContactMessage(
  name: name,
  avatarUrl: avatarUrl,
  subtitle: subtitle,
  onOpen: onOpen,
);
```

```swift [iOS]
ContactMessageView(name: name, avatarUrl: avatarUrl, subtitle: subtitle, onOpen: onOpen)
```

```kotlin [Android]
ContactMessage(
  name = name,
  avatarUrl = avatarUrl,
  subtitle = subtitle,
  onOpen = onOpen,
)
```

:::

