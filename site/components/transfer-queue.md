---
title: TransferQueue 传输队列
---

# TransferQueue 传输队列

把现有 TransferProgress 组合为任务队列。每项保留独立进度、失败原因、可用操作和处理中状态。适用于消息附件面板、传输侧栏和文件中心的任务页签。

<div class="flare-demo flare-demo--stack"><TransferQueueDemo /></div>

<ComponentApi name="TransferQueue" />

## 状态与恢复规则

| 情况 | 展示与操作 |
|---|---|
| 首次加载 | 等待指示，不显示空队列 |
| 刷新中或刷新失败 | 保留现有任务；错误区域可重新加载 |
| 无任务 | 显示 emptyText |
| 部分任务失败 | 每项显示原因，仅重试可恢复的失败项 |
| busy | 禁用该项操作，并从批量重试候选中排除 |
| 已取消 | 可逐项重试；不包含在“重试失败任务”中 |
| 已完成 | 只提供宿主允许的打开操作 |

批量回调返回当前快照中 `failed && !busy && retry 标签非空` 的任务 ID。它不直接修改状态、不自动取消任务、不删除文件。失败和取消是不同意图，不能合并。队列数量只表示传入窗口的任务数，不是全账号历史总量。

## 宿主接入

每个任务传入唯一、稳定的 `id`，以及 `name/state/statusText/progress/actionLabels/busy`。任务 ID 不用文件名或数组下标代替。权限拒绝、过期地址、磁盘不足等原因由宿主映射为文案；没有可恢复能力时省略操作标签。

Vue 使用 `action({id, action})`、`retryFailed(ids)`、`reload()`；Flutter/SwiftUI/Compose 使用 `onAction(id, action)`、`onRetryFailed(ids)`、`onReload()`。原生未传回调时隐藏相应操作。Web 接入方必须为提供的操作标签绑定事件处理。

宿主在执行命令**之前同步设置 busy**，避免重复提交。每个任务独立结束 busy 和更新结果；保留成功项，失败项继续提供恢复操作。网络调度、并发限制、幂等、断点续传、URL 刷新与取消都属于 SDK。组件卸载不终止后台传输。

```ts
async function retryFailed(ids: string[]) {
  const candidates = new Set(retryableTransferIds(items.value));
  const selected = ids.filter(id => candidates.has(id));
  items.value = items.value.map(item => selected.includes(item.id)
    ? { ...item, busy: true } : item);
  // SDK 适配器逐项处理，限制并发，并发布最新状态；禁止 Promise.all 失败后把所有项标失败。
  await adapter.retryTasks(selected);
}
```

上例只示意 UI 提交边界，适配器必须保证每项成功/失败后结束 busy；切换账号时使旧订阅与响应失效，并重新创建队列。不能把上一账号缓存任务带到下一账号。

::: code-group

```vue [Vue / Tauri]
<FlareTransferQueue :items="items" :loading="loading" :error="error"
  @action="handleAction" @retry-failed="retryFailed" @reload="reload" />
```

```dart [Flutter]
SizedBox(height: 480, child: FlareTransferQueue(items: items,
  onAction: handleAction, onRetryFailed: retryFailed, onReload: reload))
```

```swift [SwiftUI]
TransferQueueView(items: items, onAction: handleAction,
    onRetryFailed: retryFailed, onReload: reload).frame(height: 480)
```

```kotlin [Compose]
Box(Modifier.height(480.dp)) {
    TransferQueue(items = items, onAction = ::handleAction,
        onRetryFailed = ::retryFailed, onReload = ::reload)
}
```

:::

## 布局、规模与可访问性

原生队列需要有界高度，内部使用懒列表；不要放在无界高度的纵向滚动容器中。Web 内部滚动区最高 60vh，支持键盘聚焦。宿主按活动任务窗口分页提供数据，建议窗口不超过 50 项；此组件没有全量历史检索或自动分页功能。

长文件名与失败文案换行，按钮至少 48 逻辑单位，移动端操作区可换行。批量按钮随可恢复项变化，任务进度使用原有 TransferProgress 的读屏语义。示例使用本地状态，不能代替 SDK 真实传输、原生后台生命周期或真机读屏验收。
