---
title: AppShell
---

# AppShell

<p><span class="flare-tag">Layout</span></p>

> App shell — responsive navigation (mobile bottom tab / tablet-desktop side rail) + content area; the skeleton of the whole IM app.

**Data source**: nav item configuration + current route

## Preview

<div class="flare-demo flare-demo--stack">
  <AppShellDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `items` | [`NavItem[]`](/en/reference/data-types#nav-item) | ✓ | — | Navigation destinations, with icon/label/badge. |
| `activeKey` | `string` | ✓ | — | Currently selected nav key. |


## States

<span class="flare-tag">mobile</span> <span class="flare-tag">tablet</span> <span class="flare-tag">desktop</span>

## Events

<span class="flare-tag">navigate</span>

> [!TIP]
> Breakpoint-adaptive: mobile = bottom nav; tablet/desktop = side rail.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareAppShell</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareAppShell</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>AppShellView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>AppShell</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareAppShell } from "@flare-im/vue-ui";
</script>
<template>
  <FlareAppShell
  :items="items"
  :activeKey="activeKey"
  @navigate="onNavigate"
  />
</template>
```

```dart [Flutter]
FlareAppShell(
  items: items,
  activeKey: activeKey,
  onNavigate: onNavigate,
);
```

```swift [iOS]
AppShellView(items: items, activeKey: activeKey, onNavigate: onNavigate)
```

```kotlin [Android]
AppShell(
  items = items,
  activeKey = activeKey,
  onNavigate = onNavigate,
)
```

:::

