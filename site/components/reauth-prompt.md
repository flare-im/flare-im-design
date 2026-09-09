---
title: ReauthPrompt 重新认证提示
---

# ReauthPrompt 重新认证提示

会话失效时的重新认证面板：说明原因（会话过期 / 被其它设备踢下线 / 凭证失效 / 账号被停用），锁定重复提交，保留上一次失败原因，并把动作派发给宿主。登录业务与容器（全屏遮罩或对话框）由宿主实现，组件不自带遮罩。

<div class="flare-demo flare-demo--stack"><ReauthPromptDemo /></div>

<ComponentApi name="ReauthPrompt" />

## 状态与恢复规则

| 情况 | 展示与操作 |
|---|---|
| sessionExpired | 时钟图标 + 过期文案；主按钮“重新登录” |
| kicked | 设备图标 + 下线文案；`detail` 显示被踢设备与时间 |
| credentialInvalid | 锁图标 + 凭证失效文案；主按钮“重新登录” |
| accountDisabled | 禁止图标 + 停用文案；不显示“重新登录”，只保留退出/切换账号 |
| busy | 全部按钮禁用；主按钮显示进度指示与 `busyText` 可访问文本 |
| failure | `error` 以危险色状态条保留在面板内，不清空；按钮恢复可用以便重试 |

`reauthActions(reason, {hasReauth, hasLogout, busy})` 决定按钮可见性与可用性：`reauthenticate` 需要宿主回调且 reason 不是 accountDisabled；`logout` 需要宿主回调；busy 时全部禁用。四端同一份规则并各自有单测覆盖每个 reason × busy。

键盘：Enter 触发主按钮（busy 或无主按钮时不触发）；Escape 被吞掉，不关闭。Web 端在面板内阻止 Escape 冒泡，使宿主对话框不会因此关闭；原生端 SwiftUI 使用 `interactiveDismissDisabled`，Compose 消费 Escape 键事件，系统返回键由宿主容器禁用（Dialog 用 `dismissOnBackPress = false`）。

## 宿主接入

宿主在发起重新认证**之前同步设置 busy**，成功后关闭容器并恢复会话；失败时清除 busy 并把面向用户的原因写入 `error`。组件不自动重试、不做网络请求。`accountLabel` 用于让用户确认正在重新登录的账号；被踢下线时用 `detail` 给出设备名与时间。没传回调的按钮不显示（Vue 未绑定事件 / 原生回调为 nil）。

“退出登录”与“切换账号”共用 `logout` 动作，用 `logoutText` 改文案；具体清理本地数据、跳转登录页由宿主执行。

::: code-group

```vue [Vue / Tauri]
<FlareReauthPrompt reason="kicked" :busy="busy" :error="error" :detail="kickDetail"
  :account-label="account" @reauthenticate="reauth" @logout="logout" />
```

```dart [Flutter]
FlareReauthPrompt(reason: FlareReauthReason.kicked, busy: busy, error: error,
  detail: kickDetail, accountLabel: account, onReauthenticate: reauth, onLogout: logout)
```

```swift [SwiftUI]
ReauthPromptView(reason: .kicked, detail: kickDetail, busy: busy, error: error,
    accountLabel: account, onReauthenticate: reauth, onLogout: logout)
```

```kotlin [Compose]
ReauthPrompt(reason = FlareReauthReason.Kicked, detail = kickDetail, busy = busy, error = error,
    accountLabel = account, onReauthenticate = ::reauth, onLogout = ::logout)
```

:::

## 布局、规模与可访问性

面板最大宽 400 逻辑单位，居中；可放入全屏遮罩或对话框，宿主负责滚动与安全区。按钮至少 48 逻辑单位，主次按钮以填充色与描边区分，不依赖颜色传达状态：每个 reason 都有图标与文字。标题为可访问标题，原因文案作为描述；错误区为实时区域。长的 `detail`/`error` 换行，`accountLabel` 超长省略。示例使用本地状态，不能代替 SDK 真实登录或真机读屏验收。
