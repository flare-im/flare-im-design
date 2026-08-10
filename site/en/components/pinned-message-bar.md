---
title: PinnedMessageBar
---

# PinnedMessageBar

<p><span class="flare-tag">Message</span></p>

> Sticky bar showing pinned messages above the thread; tap to focus the pinned message.

**Data source**: pinned messages from the timeline view

## Preview

<div class="flare-demo flare-demo--stack">
  <PinnedBarDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `items` | [`PinnedMessageItem[]`](/en/reference/data-types#pinned-message-item) | ✓ | — | Pinned messages; if several, the bar cycles through them. |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">single</span> <span class="flare-tag">many</span>

## Events

<span class="flare-tag">focus</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlarePinnedMessageBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlarePinnedMessageBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>PinnedMessageBarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>PinnedMessageBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlarePinnedMessageBar } from "@flare-im/vue-ui";
</script>
<template>
  <FlarePinnedMessageBar
  :items="items"
  @focus="onFocus"
  />
</template>
```

```dart [Flutter]
FlarePinnedMessageBar(
  items: items,
  onFocus: onFocus,
);
```

```swift [iOS]
PinnedMessageBarView(items: items, onFocus: onFocus)
```

```kotlin [Android]
PinnedMessageBar(
  items = items,
  onFocus = onFocus,
)
```

:::

