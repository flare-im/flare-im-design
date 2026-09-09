---
title: ConversationActionSheet 会话操作菜单
---

# ConversationActionSheet 会话操作菜单

单个会话的操作菜单，由长按、右键或“更多”按钮弹出。宿主传入会话快照与可承接的能力，组件用共享的 `conversationActions(conversation, capabilities)` 计算可显示动作，四端得到同一集合、同一顺序、同一分组：常规动作一组，删除单独置底为危险分组。组件不自带弹层定位，只输出菜单内容。

<div class="flare-demo flare-demo--stack"><ConversationActionSheetDemo /></div>

<ComponentApi name="ConversationActionSheet" />

## 状态与规则

| 情况 | 展示与操作 |
|---|---|
| 能力缺省或 false | 对应动作不显示，不出现无效按钮 |
| `pinned` / `muted` / `archived` | 只显示取反的一个：pin 或 unpin、mute 或 unmute、archive 或 unarchive |
| `unreadCount = 0` | 不显示 markRead |
| delete | 单独分组置底，红色文字 + 图标 |
| busy | 全部行禁用，图标与文字降为禁用色；Escape 仍可关闭 |
| 没有任何能力 | 显示 emptyText，菜单不会空白 |

动作枚举固定为 `pin | unpin | mute | unmute | markRead | archive | unarchive | hide | delete`，顺序为置顶、免打扰、标为已读、归档、隐藏、删除。`action` 事件携带 `{ id, action }`，`id` 原样回传宿主给的会话 ID；组件不改快照、不发网络请求，状态翻转由宿主在 SDK 确认后更新快照。

## 宿主接入

宿主在发命令**之前同步置 busy**，避免重复提交；命令结束后更新快照并解除 busy。删除等危险操作通常再经过一次 DangerConfirm，由宿主编排。`close` 事件在用户按 Escape 时触发，宿主负责收起弹层。

::: code-group

```vue [Vue / Tauri]
<FlareBottomSheet :open="open" @close="open = false">
  <FlareConversationActionSheet :conversation="conv" :capabilities="caps" :busy="busy"
    @action="({ id, action }) => run(id, action)" @close="open = false" />
</FlareBottomSheet>
```

```dart [Flutter]
showModalBottomSheet(context: context, builder: (ctx) => FlareConversationActionSheet(
  conversation: conv, capabilities: caps, busy: busy,
  onAction: (id, action) => run(id, action), onClose: () => Navigator.of(ctx).pop()));
```

```swift [SwiftUI]
.sheet(isPresented: $open) {
    ConversationActionSheetView(conversation: conv, capabilities: caps, busy: busy,
        onAction: run, onClose: { open = false })
        .presentationDetents([.medium])
}
// 或 .confirmationDialog(conv.title, isPresented: $open) { sheetView.dialogButtons() }
```

```kotlin [Compose]
ModalBottomSheet(onDismissRequest = { open = false }) {
    ConversationActionSheet(conversation = conv, capabilities = caps, busy = busy,
        onAction = ::run, onClose = { open = false })
}
```

:::

原生端未传 `onAction` 时所有行按禁用渲染；Vue 接入方必须监听 `action`。所有文案通过 props 传入并带默认值，宿主按语言替换。

## 布局、规模与可访问性

菜单最多 6 行，无需内部滚动；宿主弹层负责高度上限与安全区。每行最小高度 48 逻辑单位，图标列 44 与文字垂直居中；长文案换行、超长会话标题省略。`role="menu"` 加会话标题作为读屏名称，每行 `menuitem` 读出完整文案；桌面端 Tab/方向键在可用行间移动，Enter 触发，Escape 关闭并显示 focus-visible 焦点环。状态不只靠颜色：危险动作同时有独立分组和图标。示例使用本地状态，不能替代 SDK 与真机读屏验收。
