---
title: ConversationBatchToolbar 会话批量操作条
---

# ConversationBatchToolbar 会话批量操作条

会话列表多选模式下的批量操作条：显示已选数量、可用批量动作、处理中状态，以及**部分失败摘要与逐项恢复入口**。与 MessageBatchToolbar 同一条形视觉（计数 + 动作 + 取消），差别在于它多一条结果条，用来兑现「保留成功项、失败项逐项恢复」这条全局状态规范。

<div class="flare-demo flare-demo--stack"><ConversationBatchToolbarDemo /></div>

<ComponentApi name="ConversationBatchToolbar" />

## 状态与恢复规则

| 情况 | 展示与操作 |
|---|---|
| 未选中任何会话 | 动作全部禁用，显示 emptyText |
| 已选中 | 显示「已选 N」与能力允许的动作 |
| 超过 maxSelection | 动作禁用，显示 maxSelectionText（{n} 替换为上限） |
| busy | 全部禁用；被触发的动作显示进度并带可访问文案 |
| 上一次部分失败 | 同时显示「成功 N 项」与「N 项失败」，可展开逐项 title + reason |
| 展开失败详情 | 有界滚动区；「重试失败项」只提交去重后的失败 ID |
| 上一次全部成功 | 只显示成功摘要，可关闭；不弹全局成功提示 |

动作可见性由纯函数 `batchActionsAvailable(selectedIds, capabilities, busy, maxSelection)` 决定：能力缺省或 false 的动作直接不出现；选中为空、busy、超上限都返回空列表。结果摘要由 `summarizeBatchResult(result)` 计算，`retryIds` 按失败顺序去重，是 `retryFailed` 的载荷。动作顺序四端固定为 `markRead → mute → archive → delete`，delete 永远置底并用错误语气色 + 图标呈现。

**删除不在组件内二次确认。** 组件只派发 `action({ action: 'delete', ids })`，宿主必须用 DangerConfirm 承接确认与 busy；把确认放进工具栏会让同一意图有两套确认路径。

## 宿主接入

`selectedIds` 传稳定会话 ID，不用数组下标或标题代替。宿主在发命令**之前同步置位 busy**，命令结束后写入 `result` 并解除 busy：成功项从选中集合移除、失败项保留在选中集合里，用户才能直接重试。权限不足、会话已删除、网络失败等原因由宿主映射成 `reason` 文案，组件不认识错误码。

并发限制、幂等、账号隔离属于 SDK 适配层。切换账号时必须清空选中集合与 `result`，不能把上一账号的批量结果带过去。

Vue 用 `action({ action, ids })`、`retryFailed(ids)`、`clearSelection()`、`dismissResult()`；Flutter / SwiftUI / Compose 用 `onAction(action, ids)`、`onRetryFailed(ids)`、`onClearSelection()`、`onDismissResult()`，未传回调即不显示对应入口。

```ts
async function runBatch({ action, ids }: { action: ConversationBatchAction; ids: string[] }) {
  if (action === "delete" && !(await confirmDelete(ids))) return;
  busy.value = true;
  const outcome = await adapter.runConversationBatch(action, ids); // 逐项结束，不用 Promise.all 一败俱败
  result.value = outcome;
  selected.value = outcome.failed.map((f) => f.id);
  busy.value = false;
}
```

::: code-group

```vue [Vue / Tauri]
<FlareConversationBatchToolbar :selected-ids="selected" :capabilities="caps" :busy="busy" :result="result"
  @action="runBatch" @retry-failed="retryFailed" @clear-selection="selected = []" @dismiss-result="result = null" />
```

```dart [Flutter]
FlareConversationBatchToolbar(selectedIds: selected, capabilities: caps, busy: busy, result: result,
  onAction: runBatch, onRetryFailed: retryFailed, onClearSelection: clearSelection, onDismissResult: dismissResult)
```

```swift [SwiftUI]
ConversationBatchToolbarView(selectedIds: selected, capabilities: caps, busy: busy, result: result,
    onAction: runBatch, onRetryFailed: retryFailed, onClearSelection: clearSelection, onDismissResult: dismissResult)
```

```kotlin [Compose]
ConversationBatchToolbar(selectedIds = selected, capabilities = caps, busy = busy, result = result,
    onAction = ::runBatch, onRetryFailed = ::retryFailed, onClearSelection = ::clearSelection, onDismissResult = ::dismissResult)
```

:::

## 布局、规模与可访问性

320 宽度下动作换行而不是被挤出屏幕，按钮至少 48 逻辑单位。失败详情区有界滚动（原生用懒列表），长会话标题与长原因文案换行。计数与结果摘要是 polite 实时区域，批量结束会被读屏播报；展开/收起按钮带 `aria-expanded`。删除按钮除颜色外还有图标与独立分组，不只靠颜色表达危险。示例使用本地状态，不能代替 SDK 真实批量、并发限制与真机读屏验收。
