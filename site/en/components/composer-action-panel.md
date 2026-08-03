---
title: ComposerActionPanel
---

# ComposerActionPanel

<p><span class="flare-tag">Composer</span></p>

> The attachment action grid (image/file/card/vote/…) — the expandable panel behind the composer's + button.

**Data source**: presentational — an `actions` list in, an `action` callback out with the chosen item

## Preview

<div class="flare-demo">
  <ComposerActionPanelDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `actions` | `FlareComposerActionItem[]` |  | — | Action items (icon + label + key); a sensible default set is provided. |
| `columns` | `number` |  | `4` | Grid columns. |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">action</span>

> [!TIP]
> A part of [Composer](/en/components/composer) — use it standalone to build your own input bar.

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareComposerActionPanel } from "@flare-im/vue-ui";
</script>
<template>
  <FlareComposerActionPanel
  :actions="actions"
  :columns="columns"
  @action="onAction"
  />
</template>
```

```dart [Flutter]
FlareComposerActionPanel(
  actions: actions,
  columns: columns,
  onAction: onAction,
);
```

```swift [iOS]
FlareComposerActionPanel(actions: actions, columns: columns, onAction: onAction)
```

```kotlin [Android]
FlareComposerActionPanel(
  actions = actions,
  columns = columns,
  onAction = onAction,
)
```

:::

