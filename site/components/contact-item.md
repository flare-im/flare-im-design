---
title: ContactItem
---

# ContactItem

<p><span class="flare-tag">通讯录</span></p>

> 通讯录行 —— 头像、名称、签名 / 部门、在线状态。

**数据源**：一个 Contact

## 预览

<div class="flare-demo flare-demo--stack">
  <ContactItemDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `item` | [`Contact`](/reference/data-types#contact) | ✔ | — | 该联系人的数据。 |
| `showPresence` | `boolean` |  | — | 渲染在线状态点。 |


## States

<span class="flare-tag">online</span> <span class="flare-tag">offline</span>

## Events

<span class="flare-tag">select</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactItem</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactItem</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactItemView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactItem</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareContactItem } from "flare-core-vue-im-ui";
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

