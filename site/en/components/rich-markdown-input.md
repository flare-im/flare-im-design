---
title: RichMarkdownInput
---

# RichMarkdownInput

<p><span class="flare-tag">Composer</span></p>

> The rich (RichDoc/Markdown) text field with formatting preview and length limit — used inside Composer.

**Data source**: produces normalized RichDoc / Markdown content for your send logic (optionally normalized by Flare core)

## Preview

<div class="flare-demo flare-demo--stack">
  <RichMarkdownInputDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `disabled` | `boolean` |  | — | Read-only, non-editable state. |
| `formattingPreview` | `boolean` |  | — | Render inline formatting live while typing. |
| `maxLength` | `number` |  | — | Character cap; over-limit blocks input and warns. |
| `placeholder` | `string` |  | — | Empty-field hint text. |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">focused</span> <span class="flare-tag">atLimit</span> <span class="flare-tag">disabled</span>

## Events

<span class="flare-tag">focus</span> <span class="flare-tag">blur</span> <span class="flare-tag">keydown</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>ComposerRichMarkdownInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareRichMarkdownInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>RichMarkdownInputView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>RichMarkdownInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { ComposerRichMarkdownInput } from "flare-core-vue-im-ui";
</script>
<template>
  <ComposerRichMarkdownInput
  :disabled="disabled"
  :formattingPreview="formattingPreview"
  :maxLength="maxLength"
  @focus="onFocus"
  @blur="onBlur"
  @keydown="onKeydown"
  />
</template>
```

```dart [Flutter]
FlareRichMarkdownInput(
  disabled: disabled,
  formattingPreview: formattingPreview,
  maxLength: maxLength,
  onFocus: onFocus,
  onBlur: onBlur,
  onKeydown: onKeydown,
);
```

```swift [iOS]
RichMarkdownInputView(disabled: disabled, formattingPreview: formattingPreview, maxLength: maxLength, onFocus: onFocus, onBlur: onBlur, onKeydown: onKeydown)
```

```kotlin [Android]
RichMarkdownInput(
  disabled = disabled,
  formattingPreview = formattingPreview,
  maxLength = maxLength,
  onFocus = onFocus,
  onBlur = onBlur,
  onKeydown = onKeydown,
)
```

:::

