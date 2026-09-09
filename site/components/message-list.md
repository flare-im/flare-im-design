---
title: MessageList 消息时间线
---

# MessageList 消息时间线

展示从旧到新排列的消息、气泡分组、媒体状态与历史加载。宿主提供稳定消息身份及有界时间线窗口，负责 SDK 分页、去重、ACK 合并和失败重发。

<div class="flare-demo flare-demo--stack"><MessageListDemo /></div>

<ComponentApi name="MessageList" />

API 表是统一语义清单；各端入口参数以对应示例和源码为准，不能把 Web 事件名直接复制给原生组件。

## 历史加载与恢复实验室

<div class="flare-demo flare-demo--stack"><TimelineRecoveryDemo /></div>

加载失败保留已读内容，并提供显式重试。宿主接到加载回调时立即设置 `loadingOlder=true`，完成时设为 false，并更新 `hasOlder` 或 `olderError`；即使响应为空也必须结束 loading。组件在此期间阻止重复回调，不能用定时器猜测加载是否完成。

`hasOlder` 原生默认 false；Flutter 原来仅传 onLoadOlder 的接入需要同时设置此参数。`conversationId` 用于切换会话时清理阅读位置与请求锁；宿主也需要使旧会话响应失效。

## 四端接入

::: code-group

```vue [Vue / Tauri]
<FlareMessageList
  :messages="messages" :current-user-id="currentUserId"
  :conversation-id="conversationId"
  :has-older="hasOlder" :loading-older="loadingOlder"
  :older-error="olderError" load-older-text="加载历史"
  @load-older="loadOlder" @resend="resend"
/>
```

```dart [Flutter]
FlareMessageList(
  messages: messages, currentUserId: currentUserId,
  conversationId: conversationId,
  hasOlder: hasOlder, loadingOlder: loadingOlder,
  olderError: olderError, loadOlderText: '加载历史',
  onLoadOlder: loadOlder, onResend: resend,
)
```

```swift [SwiftUI]
MessageListView(
    messages: messages, currentUserId: currentUserId,
    loadingOlder: loadingOlder, onResend: resend,
    hasOlder: hasOlder, olderError: olderError,
    loadOlderText: "加载历史", onLoadOlder: loadOlder,
    conversationId: conversationId
)
```

```kotlin [Compose]
MessageList(
    messages = messages, currentUserId = currentUserId,
    loadingOlder = loadingOlder, onResend = ::resend,
    hasOlder = hasOlder, olderError = olderError,
    loadOlderText = "加载历史", onLoadOlder = ::loadOlder,
    conversationId = conversationId,
)
```

:::

## 阅读位置与性能边界

- Vue 按可见消息 ID 和相对偏移恢复前插位置，用户手动滚动或切换会话会取消旧恢复；Flutter 用稳定键及双向 sliver 保持可见锚点。
- Compose 使用稳定消息 key 的 LazyColumn；SwiftUI 17+ 使用滚动位置绑定，旧系统以可见行位置恢复。原生滚动偏移仍需真机验收。
- Web/Flutter 可在接近顶部时触发历史加载；四端都提供显式按钮，Compose/SwiftUI 当前以按钮作为加载入口。
- 保留 SDK 提供的稳定消息身份；乐观消息变为服务端消息时不要重新生成一个不相关的 UI ID。
- 图片尺寸晚到、字体变化、整段窗口被移除、搜索跳转到未加载消息需要宿主协调，不能只靠组件保证位置。
- 不承诺固定 60fps。原生使用懒列表，Web 的渲染策略依赖窗口大小；长历史须由 SDK 有界分页提供，不能把全部历史一次传入。

本地测试覆盖历史前插、并发追加、分页防重和失败恢复。SDK 往返及真实 Android/iOS 设备验收独立记录。
