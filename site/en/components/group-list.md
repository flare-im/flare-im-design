---
title: GroupList
---

# GroupList

<p><span class="flare-tag">Contacts</span></p>

> My groups — group avatar, name, member count.

**Data source**: groups view

## Preview

<div class="flare-demo flare-demo--stack">
  <GroupListDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `items` | [`GroupSummary[]`](/en/reference/data-types#group-summary) | ✔ | — | Group summaries to list. |


## States

<span class="flare-tag">empty</span>

## Events

<span class="flare-tag">select</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareGroupList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareGroupList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>GroupListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>GroupList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareGroupList } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareGroupList
  :items="items"
  @select="onSelect"
  />
</template>
```

```dart [Flutter]
FlareGroupList(
  items: items,
  onSelect: onSelect,
);
```

```swift [iOS]
GroupListView(items: items, onSelect: onSelect)
```

```kotlin [Android]
GroupList(
  items = items,
  onSelect = onSelect,
)
```

:::

