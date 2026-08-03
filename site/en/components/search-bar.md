---
title: SearchBar
---

# SearchBar

<p><span class="flare-tag">General</span></p>

> Unified search field — the entry to conversation/contact/message search, with clear and submit.

**Data source**: controlled input; results are queried by the product (local view or server)

## Preview

<div class="flare-demo flare-demo--stack">
  <SearchBarDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `modelValue` | `string` |  | — | Two-way bound query text. |
| `placeholder` | `string` |  | `搜索` | Empty-field hint text. |
| `loading` | `boolean` |  | — | Shows a spinner while a query is running. |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">typing</span> <span class="flare-tag">loading</span>

## Events

<span class="flare-tag">input</span> <span class="flare-tag">submit</span> <span class="flare-tag">clear</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareSearchBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareSearchBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>SearchBarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>SearchBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareSearchBar } from "@flare-im/vue-ui";
</script>
<template>
  <FlareSearchBar
  :modelValue="modelValue"
  :placeholder="placeholder"
  :loading="loading"
  @input="onInput"
  @submit="onSubmit"
  @clear="onClear"
  />
</template>
```

```dart [Flutter]
FlareSearchBar(
  modelValue: modelValue,
  placeholder: placeholder,
  loading: loading,
  onInput: onInput,
  onSubmit: onSubmit,
  onClear: onClear,
);
```

```swift [iOS]
SearchBarView(modelValue: modelValue, placeholder: placeholder, loading: loading, onInput: onInput, onSubmit: onSubmit, onClear: onClear)
```

```kotlin [Android]
SearchBar(
  modelValue = modelValue,
  placeholder = placeholder,
  loading = loading,
  onInput = onInput,
  onSubmit = onSubmit,
  onClear = onClear,
)
```

:::

