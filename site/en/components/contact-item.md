---
title: ContactItem
---

# ContactItem

<p><span class="flare-tag">Contacts</span></p>

> A contact row — avatar, name, signature/department, presence.

**Data source**: one Contact

## Preview

<div class="flare-demo flare-demo--stack">
  <ContactItemDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `item` | [`Contact`](/en/reference/data-types#contact) | ✔ | — | The contact's data. |
| `showPresence` | `boolean` |  | — | Render the presence dot. |


## States

<span class="flare-tag">online</span> <span class="flare-tag">offline</span>

## Events

<span class="flare-tag">select</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactItem</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactItem</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactItemView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactItem</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareContactItem } from "@flare-im/vue-ui";
</script>
<template>
  <FlareContactItem
  :item="item"
  :showPresence="showPresence"
  @select="onSelect"
  />
</template>
```

```dart [Flutter]
FlareContactItem(
  item: item,
  showPresence: showPresence,
  onSelect: onSelect,
);
```

```swift [iOS]
ContactItemView(item: item, showPresence: showPresence, onSelect: onSelect)
```

```kotlin [Android]
ContactItem(
  item = item,
  showPresence = showPresence,
  onSelect = onSelect,
)
```

:::

