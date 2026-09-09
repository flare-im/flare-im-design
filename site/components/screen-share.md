---
title: ScreenShare 屏幕共享
---

# ScreenShare 屏幕共享

通话中的屏幕共享控制与状态面板。屏幕采集、共享源枚举、编码与推流全部由宿主 / RTC 插件负责；组件只展示宿主上报的状态，并把「开始共享」「停止共享」「取消请求」派发给宿主执行。

<div class="flare-demo flare-demo--stack"><ScreenShareDemo /></div>

<ComponentApi name="ScreenShare" />

## 状态与恢复规则

每个状态同时有图标、文字和语气色，不只靠颜色区分；`requesting` 额外显示不确定进度条，`sharing` 的状态区底色与描边加重，表示正在进行中。

| 状态 | 含义 | 语气 | 图标 | 可用动作 |
|---|---|---|---|---|
| idle | 未在共享，可以发起 | neutral | devices | start |
| requesting | 已请求，等待系统 / 插件回应 | warning + 进度 | refresh | cancel |
| sharing | 自己正在共享 | success（强调进行中） | video | stop |
| viewing | 正在观看别人共享 | info | eye | 无 |
| unavailable | 运行环境或插件不支持 | neutral | block | 无 |
| busy | 沿用当前状态 | 沿用 | 沿用 | 全部禁用（按钮保留位置） |

可见动作由纯函数 `screenShareActions(state, { hasStart, hasStop, hasCancel, busy })` 决定，返回 `{ start, stop, cancel, enabled }`：`start` 只在 idle 出现，`stop` 只在 sharing 出现，`cancel` 只在 requesting 出现，`enabled` 在 `busy` 时为 false。组件用 `busy=false` 计算按钮是否存在、用 `enabled` 决定禁用，因此处理中按钮不会跳动消失。

`viewing` 不提供 `stop`：观看方停不了别人的共享，只展示 `presenterName` 与可选 `detail`。`unavailable` 不提供任何动作，只用 `detail` 说明原因，不显示点了无效的按钮。`sourceLabel` 只在 sharing 显示，`presenterName` 只在 viewing 显示。

## 权限被拒不由本组件处理

屏幕录制权限属于 `PermissionPrompt` 的 `screen` 种类。用户拒绝或系统限制时，宿主渲染 `PermissionPrompt(kind: "screen", state: "denied")`（`restricted` / `unavailable` 同理），由它说明需要的权限并把 `openSettings` 交回宿主；**不要**在 ScreenShare 里再造一套拒绝面板——一个意图只留一条路径。ScreenShare 的 `unavailable` 说明的是运行环境或插件根本不具备屏幕共享能力（例如浏览器无采集 API），与「有能力但被拒绝」是两件事。

## 宿主接入

`state` 由宿主的 RTC 会话状态映射得到：点击共享后同步置 `busy` 并派发 `start`，插件回调进入采集选择界面后置 `requesting`，采集流建立后置 `sharing` 并回填 `sourceLabel`（如「整个屏幕」「Chrome 窗口」）；收到远端共享轨道时置 `viewing` 并回填 `presenterName`。`detail` 用于宿主补充说明，例如码率受限提示或不支持的原因，不放错误码。组件无网络副作用、无定时重试、不枚举共享源。

Vue 用 `@start` / `@stop` / `@cancel` 事件，并显式传 `has-start` / `has-stop` / `has-cancel` 表示宿主具备该能力（默认 false 隐藏按钮）；Flutter / SwiftUI / Compose 用 `onStart` / `onStop` / `onCancel` 回调，没传就不显示对应按钮。

::: code-group

```vue [Vue / Tauri]
<FlareScreenShare :state="share.state" :source-label="share.sourceLabel" :presenter-name="share.presenter"
  :detail="share.detail" :busy="busy" has-start has-stop has-cancel
  @start="startShare" @stop="stopShare" @cancel="cancelShare" />
```

```dart [Flutter]
FlareScreenShare(state: share.state, sourceLabel: share.sourceLabel, presenterName: share.presenter,
  detail: share.detail, busy: busy,
  onStart: startShare, onStop: stopShare, onCancel: cancelShare)
```

```swift [SwiftUI]
ScreenShareView(state: share.state, sourceLabel: share.sourceLabel, presenterName: share.presenter,
    detail: share.detail, busy: busy,
    onStart: startShare, onStop: stopShare, onCancel: cancelShare)
```

```kotlin [Compose]
ScreenShare(state = share.state, sourceLabel = share.sourceLabel, presenterName = share.presenter,
    detail = share.detail, busy = busy,
    onStart = ::startShare, onStop = ::stopShare, onCancel = ::cancelShare)
```

:::

## 布局、规模与可访问性

面板自身不滚动，适合放在通话控制栏旁、通话详情弹层或设置区的滚动容器里，宽度自适应；没有列表，不会引入无界滚动。共享源名称、共享者昵称和说明文案都会换行，超长内容不撑破容器，RTL 布局不破。按钮至少 48 逻辑单位并保留位置，键盘 Tab / Enter 可操作；状态区是 polite 实时区域，从 requesting 切到 sharing 会被读屏播报，`requesting` 的进度条带可访问名称。示例使用本地状态，不能代替真实 RTC 插件与真机权限验收。
