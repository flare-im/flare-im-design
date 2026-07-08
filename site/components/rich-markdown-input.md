---
title: RichMarkdownInput
---

# RichMarkdownInput

<p><span class="flare-tag">输入</span></p>

> 富文本（RichDoc/Markdown）编辑域，带格式预览与字数限制 —— Composer 内部使用。

**数据源**：产出规范化的 RichDoc/Markdown 内容（由 core 归一化）

## 预览

<div class="flare-demo flare-demo--stack">
  <RichMarkdownInputDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `disabled` | `boolean` |  | — | 只读、不可编辑态。 |
| `formattingPreview` | `boolean` |  | — | 输入时实时渲染内联格式。 |
| `maxLength` | `number` |  | — | 字数上限；超限拦截输入并告警。 |
| `placeholder` | `string` |  | — | 空输入时的占位提示。 |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">focused</span> <span class="flare-tag">atLimit</span> <span class="flare-tag">disabled</span>

## Events

<span class="flare-tag">focus</span> <span class="flare-tag">blur</span> <span class="flare-tag">keydown</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>ComposerRichMarkdownInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareRichMarkdownInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>RichMarkdownInputView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>RichMarkdownInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

