---
title: SearchBar
---

# SearchBar

<p><span class="flare-tag">通用</span></p>

> 统一搜索框 —— 会话 / 联系人 / 消息的入口，带清除与提交。

**数据源**：受控输入；结果由产品侧查询（本地视图或服务端）

## 预览

<div class="flare-demo flare-demo--stack">
  <SearchBarDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `modelValue` | `string` |  | — | 双向绑定的查询文本。 |
| `placeholder` | `string` |  | `搜索` | 空输入时的占位提示。 |
| `loading` | `boolean` |  | — | 查询进行中显示转圈。 |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">typing</span> <span class="flare-tag">loading</span>

## Events

<span class="flare-tag">input</span> <span class="flare-tag">submit</span> <span class="flare-tag">clear</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareSearchBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareSearchBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>SearchBarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>SearchBar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

