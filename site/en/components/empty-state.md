---
title: EmptyState
---

# EmptyState

<p><span class="flare-tag">General</span></p>

> Empty-state placeholder — icon + title + description + optional action; for empty inbox/search/contacts.

**Data source**: presentational only

## Preview

<div class="flare-demo flare-demo--stack">
  <EmptyStateDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `title` | `string` | ✔ | — | Primary line explaining the emptiness. |
| `description` | `string` |  | — | Secondary help text. |
| `actionText` | `string` |  | — | Label for the optional call-to-action button. |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">action</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareEmptyState</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareEmptyState</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>EmptyStateView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>EmptyState</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareEmptyState } from "@flare-im/vue-ui";
</script>
<template>
  <FlareEmptyState
  :title="title"
  :description="description"
  :actionText="actionText"
  @action="onAction"
  />
</template>
```

```dart [Flutter]
FlareEmptyState(
  title: title,
  description: description,
  actionText: actionText,
  onAction: onAction,
);
```

```swift [iOS]
EmptyStateView(title: title, description: description, actionText: actionText, onAction: onAction)
```

```kotlin [Android]
EmptyState(
  title = title,
  description = description,
  actionText = actionText,
  onAction = onAction,
)
```

:::

