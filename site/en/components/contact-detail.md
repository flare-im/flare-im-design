---
title: ContactDetail
---

# ContactDetail

<p><span class="flare-tag">Contacts</span></p>

> Contact card — avatar/name/signature + profile fields + message/voice/video/more actions.

**Data source**: one Contact's detail; actions open a conversation / start a call via the client

## Preview

<div class="flare-demo flare-demo--stack">
  <ContactDetailDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `contact` | [`Contact`](/en/reference/data-types#contact) | ✔ | — | The contact to profile. |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">message</span> <span class="flare-tag">call</span> <span class="flare-tag">video</span> <span class="flare-tag">edit</span> <span class="flare-tag">editDescription</span> <span class="flare-tag">toggleStar</span> <span class="flare-tag">block</span> <span class="flare-tag">remove</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareContactDetail } from "@flare-im/vue-ui";
</script>
<template>
  <FlareContactDetail
  :contact="contact"
  @message="onMessage"
  @call="onCall"
  @video="onVideo"
  />
</template>
```

```dart [Flutter]
FlareContactDetail(
  contact: contact,
  onMessage: onMessage,
  onCall: onCall,
  onVideo: onVideo,
);
```

```swift [iOS]
ContactDetailView(contact: contact, onMessage: onMessage, onCall: onCall, onVideo: onVideo)
```

```kotlin [Android]
ContactDetail(
  contact = contact,
  onMessage = onMessage,
  onCall = onCall,
  onVideo = onVideo,
)
```

:::

