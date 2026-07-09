---
title: ContactList
---

# ContactList

<p><span class="flare-tag">Contacts</span></p>

> The address book — contacts grouped A–Z by pinyin/letter, with a side index bar and quick jump.

**Data source**: an array of contacts/friends (your data); grouping and A–Z index done in the presentation layer

## Preview

<div class="flare-demo flare-demo--stack">
  <ContactListDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `items` | [`Contact[]`](/en/reference/data-types#contact) | ✔ | — | Contacts to group and render. |
| `indexed` | `boolean` |  | `true` | Show the A–Z side index bar. |
| `loading` | `boolean` |  | — | First-load skeleton/spinner. |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">indexed</span>

## Events

<span class="flare-tag">select</span> <span class="flare-tag">longPress</span>

> [!TIP]
> Virtualised + sticky group headers; A–Z side index jumps.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareContactList } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareContactList
  :items="items"
  :indexed="indexed"
  :loading="loading"
  @select="onSelect"
  @longPress="onLongPress"
  />
</template>
```

```dart [Flutter]
FlareContactList(
  items: items,
  indexed: indexed,
  loading: loading,
  onSelect: onSelect,
  onLongPress: onLongPress,
);
```

```swift [iOS]
ContactListView(items: items, indexed: indexed, loading: loading, onSelect: onSelect, onLongPress: onLongPress)
```

```kotlin [Android]
ContactList(
  items = items,
  indexed = indexed,
  loading = loading,
  onSelect = onSelect,
  onLongPress = onLongPress,
)
```

:::


## Examples

### Address book (A–Z index)

Grouped by pinyin/letter with a tappable side index; an empty list shows a placeholder automatically.

::: code-group

```vue [Vue]
<FlareContactList :items="contacts" indexed @select="openContact" />
```

```dart [Flutter]
FlareContactList(items: contacts, indexed: true, onSelect: openContact)
```

```swift [iOS]
ContactListView(items: contacts, indexed: true) { openContact($0) }
```

```kotlin [Android]
ContactList(items = contacts, indexed = true, onSelect = ::openContact)
```

:::
