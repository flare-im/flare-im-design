---
title: TransferProgress 附件传输
---

# TransferProgress 附件传输

文件上传、下载、语音和视频附件共用同一状态契约。组件只呈现宿主 SDK 的状态；不会自行启动网络任务，也不会从进度推断传输成功。

## 交互状态实验室

<div class="flare-demo flare-demo--stack"><TransferProgressDemo /></div>

<ComponentApi name="TransferProgress" />

## 状态与可用操作

| 状态 | 允许操作 |
|---|---|
| queued | cancel |
| transferring | pause、cancel |
| paused | resume、cancel |
| failed | retry |
| completed | open |
| cancelled | retry |

允许操作还必须出现在宿主传入的 `actionLabels` 中。SDK 不支持暂停时不传 `pause`；没有文件打开能力时不传 `open`。本地化标签为空时不显示操作。原生组件还要求提供回调。

`progress` 为真实比例，`null` 表示未知；0 是已知零进度。非法非有限数字视为未知，越界数字限制到 0–1。只有 `completed` 显示完整进度。未知进度仅在 transferring 状态显示等待指示。失败原因由 `statusText` 提供，避免显示裸 SDK JSON 或敏感内部路径。

`busy` 由宿主在提交操作前同步设为 true，完成后重置。组件禁用按钮，SDK 仍需负责幂等和重复命令保护。切换状态不会丢失传输任务，组件卸载也不会取消后台传输。

::: code-group

```vue [Vue]
<FlareTransferProgress name="report.pdf" state="failed"
  status-text="网络中断，可重新尝试" :action-labels="{ retry: '重试' }"
  :busy="operationPending" @action="handleTransferAction" />
```

```dart [Flutter]
FlareTransferProgress(
  name: 'report.pdf', state: FlareTransferState.failed,
  statusText: '网络中断，可重新尝试', busy: operationPending,
  actionLabels: {FlareTransferAction.retry: '重试'},
  onAction: handleTransferAction,
)
```

```swift [SwiftUI]
TransferProgressView(name: "report.pdf", state: .failed,
    statusText: "网络中断，可重新尝试", actionLabels: [.retry: "重试"],
    busy: operationPending, onAction: handleTransferAction)
```

```kotlin [Compose]
TransferProgress(name = "report.pdf", state = FlareTransferState.Failed,
    statusText = "网络中断，可重新尝试",
    actionLabels = mapOf(FlareTransferAction.Retry to "重试"),
    busy = operationPending, onAction = ::handleTransferAction)
```

:::

## 组合位置

- 气泡内部：作为上传附件预览的状态区域，不重复显示文件名与操作栏。
- 文件中心：每个传输任务一项，由宿主虚拟列表承载。
- 消息失败与文件失败分别处理：上传完成不代表消息已经发送成功。
- URL 过期需要宿主重新获取授权地址，不能直接把过期 URL 当作网络失败循环重试。

## 可访问性

按钮至少 48 逻辑单位；长文件名和状态文案换行；读屏可获取状态和进度。错误通过文案表达，不能只依赖红色。大字号时按钮可以换行或纵向排列。
