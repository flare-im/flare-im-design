---
title: ContactList
---

# ContactList

<p><span class="flare-tag">通讯录</span></p>

> 通讯录 —— 按拼音 / 字母 A–Z 分组的联系人列表，带侧边索引条与快速跳转。

**数据源**：联系人 / 好友数组（你的数据）；分组与 A–Z 索引在展示层完成

## 预览

<div class="flare-demo flare-demo--stack">
  <ContactListDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `items` | [`Contact[]`](/reference/data-types#contact) | ✔ | — | 要分组渲染的联系人。 |
| `indexed` | `boolean` |  | `true` | 显示 A–Z 侧边索引条。 |
| `loading` | `boolean` |  | — | 首屏骨架 / 转圈。 |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">indexed</span>

## Events

<span class="flare-tag">select</span> <span class="flare-tag">longPress</span>

> [!TIP]
> 虚拟化 + 分组吸顶 header；侧边 A–Z 索引跳转。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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


## 示例

### 通讯录（A-Z 索引）

按拼音/字母分组，侧边索引条点击跳转；空列表自动显示占位。

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
