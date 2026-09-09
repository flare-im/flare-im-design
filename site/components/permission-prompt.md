---
title: PermissionPrompt 权限提示
---

# PermissionPrompt 权限提示

系统权限缺失或被拒绝时的统一说明面板。说明需要的权限和它解锁的功能，把"申请权限"和"打开系统设置"交给宿主。供录音（Composer 语音）、通话（麦克风 / 摄像头）、通知（NotificationPreferences）、存储 / 相册、通讯录、位置复用。组件不申请权限、不判断平台，只按宿主给的 `kind` + `state` 展示并派发。

<div class="flare-demo flare-demo--stack"><PermissionPromptDemo /></div>

<ComponentApi name="PermissionPrompt" />

## 状态与恢复规则

| state | 含义 | 可见动作 |
|---|---|---|
| undetermined | 尚未向系统申请 | `request`（宿主传了才显示）+ 可选 `dismiss` |
| denied | 用户拒绝过，只能去系统设置开启 | `openSettings`（宿主传了才显示）+ 可选 `dismiss` |
| restricted | 家长控制 / 企业策略限制，用户自己开不了 | 只有说明 + 可选 `dismiss` |
| unavailable | 设备没有该硬件或运行环境不支持 | 只有说明 + 可选 `dismiss` |
| busy | 宿主正在申请 / 跳转 | 全部动作禁用，主按钮显示处理中 |

每种 `kind` 有对应图标（麦克风、摄像头、通知、存储、相册、通讯录、位置），每种 `state` 有图标 + 文字的状态标签，不只靠颜色区分。`restricted` 与 `unavailable` 不显示任何无效按钮。

纯逻辑四端同名：`permissionActions(state, {hasRequest, hasOpenSettings, hasDismiss, busy})` 返回 `{request, openSettings, dismiss, enabled}`；`defaultPermissionCopy(kind, state, featureLabel?)` 返回 `{title, description, primaryLabel}`。

## 宿主接入

宿主查询平台权限状态并映射为 `state`；`featureLabel` 写这个权限解锁的功能（"发送语音消息"），会嵌入默认说明句；`detail` 放宿主补充（"开启后返回本页即可继续"）。所有文案 props 都有默认值，可整体覆盖。

`request` 只在 undetermined 时派发，宿主调用平台申请 API，**先同步置 busy**，拿到结果后更新 `state`（允许则卸载组件，拒绝则切 denied）。`openSettings` 只在 denied 时派发，宿主打开系统设置页；返回前台后重新查询状态。`dismiss` 可选，宿主决定是否允许关闭。Vue 事件 `request` / `open-settings` / `dismiss`，未绑定的事件对应按钮不渲染；原生 `onRequest` / `onOpenSettings` / `onDismiss` 为 nil 时同样不渲染。

`compact` 用于放在输入区上方的一行式提示；默认为卡片模式，适合设置页与通话前检查。

::: code-group

```vue [Vue / Tauri]
<FlarePermissionPrompt kind="microphone" :state="micState" :busy="busy"
  feature-label="发送语音消息" compact
  @request="requestMic" @open-settings="openSettings" @dismiss="hide" />
```

```dart [Flutter]
FlarePermissionPrompt(kind: FlarePermissionKind.microphone, state: micState,
  busy: busy, featureLabel: '发送语音消息', compact: true,
  onRequest: requestMic, onOpenSettings: openSettings, onDismiss: hide)
```

```swift [SwiftUI]
PermissionPromptView(kind: .microphone, state: micState, featureLabel: "发送语音消息",
    busy: busy, compact: true, onRequest: requestMic, onOpenSettings: openSettings, onDismiss: hide)
```

```kotlin [Compose]
PermissionPrompt(kind = FlarePermissionKind.Microphone, state = micState,
    featureLabel = "发送语音消息", busy = busy, compact = true,
    onRequest = ::requestMic, onOpenSettings = ::openSettings, onDismiss = ::hide)
```

:::

## 布局、规模与可访问性

卡片模式为图标 + 标题 / 状态标签 / 说明 + 动作行；紧凑模式在宽屏为一行三栏，窄屏动作行自动换到下一行。按钮 ≥ 48 逻辑单位，长说明换行。Web 容器是 `role="region"`，`aria-label` 为标题，状态标签 `role="status"`，`aria-busy` 跟随 busy；按下 Escape 派发 `dismiss`（宿主未绑定则无操作）。原生用同一套 token 的圆角 / 间距 / 字号，图标走各自的语义图标库。示例只在本地切换状态，不申请任何系统权限。
