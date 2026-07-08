---
title: SettingsList
---

# SettingsList

<p><span class="flare-tag">Profile</span></p>

> Settings list — grouped toggles/navigation/choice rows; a general settings container.

**Data source**: product-defined settings sections

## Preview

<div class="flare-demo flare-demo--stack">
  <SettingsListDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `sections` | `SettingsSection[]` | ✔ | — | Grouped settings rows to render. |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">toggle</span> <span class="flare-tag">select</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareSettingsList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareSettingsList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>SettingsListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>SettingsList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareSettingsList } from "flare-core-vue-im-ui";
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

