---
title: ConversationWorkspace 会话工作区
---

# ConversationWorkspace 会话工作区

把会话列表、消息时间线、会话详情三栏组合起来，并在一处统一每栏的加载、空、失败三种状态，接入方不必在每个 app 里各写一遍空白卡片。它自己不拥有任何数据、不发请求、不做定时重试；三栏内容仍由宿主用槽传入，分栏与断点仍由 ResponsiveLayout 负责。

<div class="flare-demo flare-demo--stack"><ConversationWorkspaceDemo /></div>

<ComponentApi name="ConversationWorkspace" />

## 状态与恢复规则

| 情况 | 展示与操作 |
|---|---|
| `ready` | 渲染宿主传入的该栏内容 |
| `loading` | 该栏渲染骨架（列表行 / 消息气泡 / 详情卡片）并带读屏文案，绝不渲染成空列表 |
| `empty` | 渲染 EmptyState，标题取 `message`，缺省用该栏的 `*EmptyText` |
| `failure` | 渲染错误语气的 StatusBanner，文案取 `message`，缺省用该栏的 `*FailureText` |
| `failure` 且有 `actionLabel` 与 `retry` 回调 | 错误条内附恢复按钮，点击回调 `retry(pane)` |
| `failure` 但缺 `actionLabel` 或缺回调 | 只显示原因，不显示点了无效的按钮 |
| 状态缺失或非法值 | 降级为 `ready` 渲染宿主内容，不抛异常、不显示空白 |
| 全局 `banner` | 渲染在三栏之上；`message` 为空或纯空白则不渲染 |

三栏状态互相独立：聊天栏失败不会把已经加载好的列表栏也变成失败，部分失败保留成功项。全局 banner 与栏内状态可以同时存在，例如离线 banner + 列表仍可读缓存。窄屏返回顺序（详情 → 聊天 → 列表）与断点分栏（720 双栏 / 1100 三栏、按字号缩放）仍在 ResponsiveLayout，本组件不重复实现，只把 `activePane`/`hasDetail`/`listWidth`/`detailWidth`/`hideMobileBar`/`backLabel` 原样透传。

## 宿主接入

详情栏在**没有内容但状态非 ready 时依然渲染**：宿主还没拿到详情正是加载/失败面板存在的意义，所以原生端不需要为此塞一个占位组件。三端都是「detail 槽非空 **或** detailState 非 ready」才建这一栏。

每栏状态是一个 `{ status, message?, actionLabel? }` 快照，由宿主从 SDK 的加载结果映射而来。`message` 是面向用户的原因（“网络中断”“该会话已被管理员关闭”），不是错误码；没有可恢复能力时省略 `actionLabel`，组件就只讲原因。`retry` 只是意图上报，重试调度、退避、幂等、账号切换后作废旧订阅都属于宿主与 SDK。

Vue 使用 `@pane-change`、`@retry`、`@banner-action`；Flutter / SwiftUI / Compose 使用 `onPaneChange`、`onRetry(pane)`、`onBannerAction`。原生端未传回调时不显示相应按钮。

```ts
const chatState = computed(() => {
  if (timeline.error.value) return { status: "failure", message: timeline.error.value, actionLabel: "重试" };
  if (timeline.loading.value && !timeline.messages.value.length) return { status: "loading" };
  if (!current.value) return { status: "empty", message: "选择一个会话开始聊天" };
  return { status: "ready" };
});
```

刷新失败时保留已有内容：只有首屏没有任何数据才用 `loading`/`failure` 顶掉整栏，已经有内容的栏保持 `ready`，把刷新失败放到全局 `banner` 或该栏内部的局部提示里。

::: code-group

```vue [Vue / Tauri]
<FlareConversationWorkspace has-detail :active-pane="pane" :list-state="listState"
  :chat-state="chatState" :detail-state="detailState" :banner="banner"
  @pane-change="pane = $event" @retry="onRetry" @banner-action="reconnect">
  <template #list><ConversationList /></template>
  <template #chat><MessageList /></template>
  <template #detail><ConversationDetails /></template>
</FlareConversationWorkspace>
```

```dart [Flutter]
FlareConversationWorkspace(
  list: const ConversationListPane(), chat: const TimelinePane(),
  detail: const DetailPane(), activePane: pane, onPaneChange: setPane,
  listState: listState, chatState: chatState, detailState: detailState,
  banner: banner, onRetry: onRetry, onBannerAction: reconnect)
```

```swift [SwiftUI]
ConversationWorkspaceView(activePane: pane, onPaneChange: setPane,
    listState: listState, chatState: chatState, detailState: detailState,
    banner: banner, onRetry: onRetry, onBannerAction: reconnect,
    list: AnyView(ConversationListPane()), chat: AnyView(TimelinePane()),
    detail: AnyView(DetailPane()))
```

```kotlin [Compose]
ConversationWorkspace(
    list = { ConversationListPane() }, chat = { TimelinePane() },
    detail = { DetailPane() }, activePane = pane, onPaneChange = ::setPane,
    listState = listState, chatState = chatState, detailState = detailState,
    banner = banner, onRetry = ::onRetry, onBannerAction = ::reconnect)
```

:::

## 布局、规模与可访问性

工作区自身占满宿主容器：顶部是可选的全局提示条，下面整块交给 ResponsiveLayout。栏内容的滚动、虚拟化、分页仍由各栏组件负责，本组件只在非 `ready` 时替换该栏，不给内容加额外滚动层；原生端的列表仍用 LazyColumn / ListView.builder / List，不要塞进无界纵向滚动。

骨架带读屏文案（`listLoadingText` / `chatLoadingText` / `detailLoadingText`），加载中会被朗读为“正在加载…”，而不是一个安静的空列表。失败区用 `role="alert"` / 原生等价语义播报，状态不只靠颜色：错误条同时有语气色、圆点与文字。恢复按钮触控区不小于 48 逻辑单位，长原因文案换行不截断，RTL 下不破版。演示只用本地状态，不能代替真机读屏与真实 SDK 加载时序的验收。
