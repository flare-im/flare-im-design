---
title: ComposerActionPanel
---

# ComposerActionPanel

<p><span class="flare-tag">输入</span></p>

> 下方功能区 —— 附件动作网格（图片 / 文件 / 名片 / 投票 / …），Composer「＋」展开的面板。

**数据源**：纯展示 —— 传入 `actions` 列表，选择经 `action` 回调带回所选项

## 预览

<div class="flare-demo">
  <ComposerActionPanelDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `actions` | `FlareComposerActionItem[]` |  | — | 动作项（图标 + 文案 + key）；内置一套默认项。 |
| `columns` | `number` |  | `4` | 网格列数。 |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">action</span>

> [!TIP]
> 属于 [Composer](/components/composer) 的部件 —— 可单独使用，自拼输入栏。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareComposerActionPanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

