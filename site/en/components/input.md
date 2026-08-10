---
title: Input
---

# Input

<p><span class="flare-tag">General</span></p>

> General text input — single/multi-line, char limit, clearable, disabled/read-only; the backbone of forms and search.

**Data source**: controlled value; the product owns validation and submit

## Preview

<div class="flare-demo flare-demo--stack">
  <InputDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `modelValue` | `string` | ✓ | — | Two-way bound value. |
| `placeholder` | `string` |  | — | Empty-field hint text. |
| `multiline` | `boolean` |  | — | Grow into a textarea instead of a single line. |
| `maxLength` | `number` |  | — | Character cap; shows a counter. |
| `disabled` | `boolean` |  | — | Non-editable, dimmed state. |
| `clearable` | `boolean` |  | — | Show a clear (×) button when non-empty. |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">focused</span> <span class="flare-tag">atLimit</span> <span class="flare-tag">disabled</span>

## Events

<span class="flare-tag">input</span> <span class="flare-tag">submit</span> <span class="flare-tag">focus</span> <span class="flare-tag">blur</span> <span class="flare-tag">clear</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>InputView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>Input</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareInput } from "@flare-im/vue-ui";
</script>
<template>
  <FlareInput
  :modelValue="modelValue"
  :placeholder="placeholder"
  :multiline="multiline"
  @input="onInput"
  @submit="onSubmit"
  @focus="onFocus"
  />
</template>
```

```dart [Flutter]
FlareInput(
  modelValue: modelValue,
  placeholder: placeholder,
  multiline: multiline,
  onInput: onInput,
  onSubmit: onSubmit,
  onFocus: onFocus,
);
```

```swift [iOS]
InputView(modelValue: modelValue, placeholder: placeholder, multiline: multiline, onInput: onInput, onSubmit: onSubmit, onFocus: onFocus)
```

```kotlin [Android]
Input(
  modelValue = modelValue,
  placeholder = placeholder,
  multiline = multiline,
  onInput = onInput,
  onSubmit = onSubmit,
  onFocus = onFocus,
)
```

:::


## Examples

### Multi-line + length limit

A general input: single/multi-line, a maxLength counter, and one-tap clearable.

::: code-group

```vue [Vue]
<FlareInput v-model="text" placeholder="介绍一下自己" multiline :max-length="60" />
```

```dart [Flutter]
FlareInput(controller: controller, placeholder: '介绍一下自己', multiline: true, maxLength: 60)
```

```swift [iOS]
InputView(text: $text, placeholder: "介绍一下自己", multiline: true, maxLength: 60)
```

```kotlin [Android]
Input(value = text, onValueChange = { text = it }, placeholder = "介绍一下自己", multiline = true, maxLength = 60)
```

:::
