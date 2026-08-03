---
title: StartConversationDialog
---

# StartConversationDialog

<p><span class="flare-tag">Conversation</span></p>

> New-conversation entry — pick a contact or create a group.

**Data source**: contacts/directory from the product; confirm creates/opens a conversation via the client

## Preview

<div class="flare-demo flare-demo--stack">
  <StartConversationDialogDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `busy` | `boolean` |  | — | Disables confirm and shows a spinner while creating. |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">busy</span>

## Events

<span class="flare-tag">confirm</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareStartConversationDialog</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareStartConversationSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>StartConversationView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>StartConversationDialog</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareStartConversationDialog } from "@flare-im/vue-ui";
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

