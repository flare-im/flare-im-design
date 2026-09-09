---
title: MessageActionSheet
---

# MessageActionSheet

<p><span class="flare-tag">消息</span></p>

> 消息长按操作面板 —— 表情条、快捷操作（回复 / 转发 / 撤回）、分组操作（多选 / 标记 / 置顶 / 复制 / 编辑 / 删除）。删除为红色。

**数据源**：由消息的 menuConfig 驱动（启用哪些操作）；操作经时间线视图 / client 分发

## 预览

<div class="flare-demo flare-demo--stack">
  <MessageActionSheetDemo />
</div>


## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `open` | `boolean` | ✓ | — | 面板是否展开。 |
| `reactions` | `string[]` |  | — | 表情条里的表情（末尾按钮展开完整选择器）。 |
| `menuConfig` | `MessageMenuConfig` |  | — | 该消息启用哪些操作；未启用的隐藏。 |
| `canRecall` | `boolean` |  | — | 是否显示撤回（仅己方近期消息）。 |


## States

<span class="flare-tag">reactionStrip</span> <span class="flare-tag">quickActions</span> <span class="flare-tag">emojiExpanded</span>

## Events

<span class="flare-tag">build</span>

> [!TIP]
> 四端都收敛成单个 action 分发,不存在 per-op 事件:Vue emit build(op),Flutter/iOS/Compose 是 onAction(FlareComposerAction)。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageActionSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageActionSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageActionSheetView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageActionSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageActionSheet } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMessageActionSheet
  :open="open"
  :reactions="reactions"
  :menuConfig="menuConfig"
  @build="onBuild"
  />
</template>
```

```dart [Flutter]
FlareMessageActionSheet(
  open: open,
  reactions: reactions,
  menuConfig: menuConfig,
  onBuild: onBuild,
);
```

```swift [iOS]
MessageActionSheetView(open: open, reactions: reactions, menuConfig: menuConfig, onBuild: onBuild)
```

```kotlin [Android]
MessageActionSheet(
  open = open,
  reactions = reactions,
  menuConfig = menuConfig,
  onBuild = onBuild,
)
```

:::

