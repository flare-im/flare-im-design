---
title: SettingsList
---

# SettingsList

<p><span class="flare-tag">个人中心</span></p>

> 设置列表 —— 分组的开关 / 跳转 / 选择项，通用设置容器。

**数据源**：产品定义的设置项分组

## 预览

<div class="flare-demo flare-demo--stack">
  <SettingsListDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `sections` | [`SettingsSection[]`](/reference/data-types#settings-section) | ✓ | — | 要渲染的分组设置行。 |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">toggle</span> <span class="flare-tag">select</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareSettingsList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareSettingsList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>SettingsListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>SettingsList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareSettingsList } from "@flare-im/vue-ui";
</script>
<template>
  <FlareSettingsList
  :sections="sections"
  @toggle="onToggle"
  @select="onSelect"
  />
</template>
```

```dart [Flutter]
FlareSettingsList(
  sections: sections,
  onToggle: onToggle,
  onSelect: onSelect,
);
```

```swift [iOS]
SettingsListView(sections: sections, onToggle: onToggle, onSelect: onSelect)
```

```kotlin [Android]
SettingsList(
  sections = sections,
  onToggle = onToggle,
  onSelect = onSelect,
)
```

:::

