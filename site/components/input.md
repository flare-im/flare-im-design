---
title: Input
---

# Input

<p><span class="flare-tag">通用</span></p>

> 通用文本输入框 —— 单 / 多行、字数限制、可清除、禁用 / 只读，撑起表单与搜索。

**数据源**：受控值；产品决定校验与提交

## 预览

<div class="flare-demo flare-demo--stack">
  <InputDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `modelValue` | `string` | ✓ | — | 双向绑定的值。 |
| `placeholder` | `string` |  | — | 空输入时的占位提示。 |
| `multiline` | `boolean` |  | — | 变为多行文本域而非单行。 |
| `maxLength` | `number` |  | — | 字数上限；显示计数。 |
| `disabled` | `boolean` |  | — | 不可编辑、置灰态。 |
| `clearable` | `boolean` |  | — | 非空时显示清除（×）按钮。 |


## States

<span class="flare-tag">empty</span> <span class="flare-tag">focused</span> <span class="flare-tag">atLimit</span> <span class="flare-tag">disabled</span>

## Events

<span class="flare-tag">input</span> <span class="flare-tag">submit</span> <span class="flare-tag">focus</span> <span class="flare-tag">blur</span> <span class="flare-tag">clear</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareInput</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>InputView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>Input</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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


## 示例

### 多行 + 字数限制

通用输入框：单/多行、maxLength 计数、clearable 一键清除。

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
