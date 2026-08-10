---
title: MessageActionSheet
---

# MessageActionSheet

<p><span class="flare-tag">消息</span></p>

> 消息操作 —— 表情反应、快捷操作（回复 / 转发 / 撤回）、分组操作（多选 / 标记 / 置顶 / 复制 / 编辑 / 删除）。删除为红色。

交互**按端分流**（同一套操作，两种呈现）：

- **桌面**：鼠标悬停气泡即出 <strong>表情反应 · 回复 · 更多</strong> 三个快捷键；其余操作点「更多」展开为下拉菜单。右键也可唤起。
- **移动端**：长按气泡弹出底部 **sheet**（表情条 + 快捷宫格 + 全部操作列表）。

呈现由视口 / 指针能力自动决定（见 `MessageBubble`），你只需喂 `menuConfig` 决定启用哪些操作。表情反应集在两端共用同一份（`MESSAGE_QUICK_REACTIONS`）。

**数据源**：由消息的 menuConfig 驱动（启用哪些操作）；操作经时间线视图 / client 分发。

## 预览

悬停下面任意气泡看桌面三键条；移动端为长按 sheet。

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

<span class="flare-tag">react</span> <span class="flare-tag">reply</span> <span class="flare-tag">forward</span> <span class="flare-tag">recall</span> <span class="flare-tag">multiSelect</span> <span class="flare-tag">mark</span> <span class="flare-tag">pin</span> <span class="flare-tag">copy</span> <span class="flare-tag">edit</span> <span class="flare-tag">delete</span>

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
  @react="onReact"
  @reply="onReply"
  @forward="onForward"
  />
</template>
```

```dart [Flutter]
FlareMessageActionSheet(
  open: open,
  reactions: reactions,
  menuConfig: menuConfig,
  onReact: onReact,
  onReply: onReply,
  onForward: onForward,
);
```

```swift [iOS]
MessageActionSheetView(open: open, reactions: reactions, menuConfig: menuConfig, onReact: onReact, onReply: onReply, onForward: onForward)
```

```kotlin [Android]
MessageActionSheet(
  open = open,
  reactions = reactions,
  menuConfig = menuConfig,
  onReact = onReact,
  onReply = onReply,
  onForward = onForward,
)
```

:::

