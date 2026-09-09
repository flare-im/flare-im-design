---
title: ConnectionDetails 连接详情
---

# ConnectionDetails 连接详情

连接与会话状态的详情面板。用于 StatusBanner 点开后的“连接详情”，或设置页里的“网络与连接”。宿主提供状态、已格式化的事实（传输协议、服务地址、上次同步）和原因文案；组件只展示，并把重新连接、重新登录、复制诊断信息派发给宿主执行。

<div class="flare-demo flare-demo--stack"><ConnectionDetailsDemo /></div>

<ComponentApi name="ConnectionDetails" />

## 状态与恢复规则

每个状态同时有图标、文字和语气色，不只靠颜色区分；connecting / reconnecting 额外显示不确定进度条。

| 状态 | 语气 | 图标 | 可用动作 |
|---|---|---|---|
| connected | success | success | copyDiagnostics |
| connecting | warning + 进度 | refresh | copyDiagnostics |
| reconnecting | warning + 进度 | refresh | reconnect、copyDiagnostics |
| offline | danger | error | reconnect、copyDiagnostics |
| sessionExpired | danger | lock | reauth、copyDiagnostics |
| kicked | danger | devices | reauth、copyDiagnostics |
| sdkUnready | neutral | info | 无（说明客户端尚未就绪） |
| busy | 沿用当前状态 | 沿用 | 全部禁用（按钮保留位置） |

可用动作由纯函数 `availableConnectionActions(state, { hasReconnect, hasReauth, hasDiagnostics, busy })` 决定：`reconnect` 只在 offline / reconnecting 出现，`reauth` 只在 sessionExpired / kicked 出现，`copyDiagnostics` 只在 `diagnostics` 非空时出现；`sdkUnready` 永远不给动作；`busy` 返回空列表。组件用 `busy=false` 计算可见按钮、用 `busy` 决定禁用，因此处理中按钮不会跳动消失。

诊断信息默认收起，展开后为等宽多行文本，最高 240 逻辑单位内部滚动；复制动作只派发事件，写剪贴板由宿主完成（Web 需要用户手势内调用 Clipboard API）。

## 宿主接入

`state` 由 SDK 连接状态机映射得到；`lastSyncAt` 由宿主按本地化格式化后传入，组件不解析时间。`reason` 是面向用户的原因，不是错误码；错误码、close code、重试次数等放进 `diagnostics`。

Vue 用 `@reconnect` / `@reauth` / `@copy-diagnostics` 事件，并显式传 `has-reconnect` / `has-reauth` 表示宿主具备该能力（默认 false 隐藏按钮）；Flutter / SwiftUI / Compose 用 `onReconnect` / `onReauth` / `onCopyDiagnostics` 回调，没传就不显示对应按钮。宿主在发命令前**同步置位 busy**，命令结束后由状态回流更新 `state` 再解除 busy；组件无定时重试、无网络副作用。

::: code-group

```vue [Vue / Tauri]
<FlareConnectionDetails :state="conn.state" :transport="conn.transport" :endpoint="conn.endpoint"
  :last-sync-at="formatTime(conn.lastSyncAt)" :reason="conn.reason" :diagnostics="conn.diagnostics"
  :busy="busy" has-reconnect has-reauth
  @reconnect="reconnect" @reauth="reauth" @copy-diagnostics="copyDiagnostics" />
```

```dart [Flutter]
FlareConnectionDetails(state: conn.state, transport: conn.transport, endpoint: conn.endpoint,
  lastSyncAt: formatTime(conn.lastSyncAt), reason: conn.reason, diagnostics: conn.diagnostics,
  busy: busy, onReconnect: reconnect, onReauth: reauth, onCopyDiagnostics: copyDiagnostics)
```

```swift [SwiftUI]
ConnectionDetailsView(state: conn.state, transport: conn.transport, endpoint: conn.endpoint,
    lastSyncAt: formatTime(conn.lastSyncAt), reason: conn.reason, diagnostics: conn.diagnostics,
    busy: busy, onReconnect: reconnect, onReauth: reauth, onCopyDiagnostics: copyDiagnostics)
```

```kotlin [Compose]
ConnectionDetails(state = conn.state, transport = conn.transport, endpoint = conn.endpoint,
    lastSyncAt = formatTime(conn.lastSyncAt), reason = conn.reason, diagnostics = conn.diagnostics,
    busy = busy, onReconnect = ::reconnect, onReauth = ::reauth, onCopyDiagnostics = ::copyDiagnostics)
```

:::

## 布局、规模与可访问性

面板本身不滚动，适合放在设置页的滚动容器或弹层里；只有诊断信息区有内部有界滚动。长地址视觉上单行省略（原生用中间省略），但读屏名称是完整地址；地址与诊断文本强制 LTR，RTL 界面不会破坏 URL 阅读方向。原因文案与按钮文案自动换行，按钮至少 48 逻辑单位，键盘 Tab / Enter 可操作，诊断折叠按钮带 `aria-expanded`。状态区是 polite 实时区域，状态切换会被读屏播报。示例使用本地状态，不能代替 SDK 真实连接状态机与真机读屏验收。
