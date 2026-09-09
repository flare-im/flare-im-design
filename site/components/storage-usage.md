---
title: StorageUsage 存储空间管理
---

# StorageUsage 存储空间管理

设置页里的「存储空间」段：宿主给出各分类的占用快照与清理能力，组件只展示并派发清理意图。大小、文件数、能否清理全部由宿主测量，组件不发起任何统计、不重试、不自己删数据。没测出来的分类显示「未知」而不是 0 B——百分比与大小未知就说未知，是全仓的状态规范。四端共用同一套纯函数：`formatBytes`、`storageTotals`、`storageShare`、`canClearStorage`。

<div class="flare-demo flare-demo--stack"><StorageUsageDemo /></div>

<ComponentApi name="StorageUsage" />

## 状态与恢复规则

| 情况 | 展示与操作 |
|---|---|
| 默认 | 每行：分类名、大小、可选文件数、占比条、清理按钮；标题下方是总计与设备可用空间 |
| `bytes` 为 `null`/`NaN`/`Infinity`/负数 | 大小显示「未知」，**不画占比条**；清理按钮保留（没统计出来不等于是空的） |
| `bytes` 为 0 | 不显示清理按钮（不显示点了无效的按钮） |
| `clearable` 为 false | 不显示清理按钮；这一行仍然展示占用 |
| `loading` 且尚无分类 | 骨架行 + 「正在统计存储占用」，**不伪装成空列表** |
| `loading` 且已有分类 | 保留已有分类，只在标题下加进度文案 |
| 整体 `error` | 顶部错误条（图标 + 文案 + danger 色），提供「重新统计」与「忽略此错误」；**已统计出的分类继续可见** |
| 某分类 `busy` | 该行显示「清理中」并锁定清理按钮，其余行照常可用 |
| 某分类 `error` | 该行下方显示失败原因，提供「失败重试」与「忽略此错误」；成功清掉的分类保持新值 |
| 分类为空且不在加载、无错误 | 说明原因：「没有可统计的存储分类」 |

总计的口径：宿主给了 `totalBytes` 就以它为准（它能看到分类列表之外的东西）；没给时组件对**已知**分类求和，并在存在未知分类时标注「至少 X」——把部分和当成全部才是撒谎。`deviceFreeBytes` 只在宿主知道时展示。占比条按 `storageShare(bytes, total)` 画，未知或 total ≤ 0 时不画：宽度为 0 的条会被读成「这个分类是空的」。

## 危险动作由宿主二次确认

清理不可逆。按钮用 danger 色 + 垃圾桶图标（不是只靠颜色），但**二次确认不在本组件内**：`clear` 只是意图，宿主用 [DangerConfirm](/components/danger-confirm) 承接，确认后再把该分类的 `busy` 置位并发命令。命令返回后移除 `busy`，成功写回新的 `bytes`，失败写进该分类的 `error`。逐项独立：一个分类失败既不回滚也不隐藏其他分类的结果，也不用一个全局提示盖掉。

## 字节格式化规则（四端一致，有单测）

`formatBytes(bytes, locale?)`：

- `null` / `undefined` / `NaN` / `Infinity` / 负数 → 返回 `null`，由组件套用 `unknownText`（「未知」）；
- `0` → `"0 B"`；小于 1024 → `"N B"`（四舍五入到整字节）；
- 之后每 1024 进一位，依次 KB / MB / GB / TB，保留 1 位小数：`"2.0 KB"`、`"1.5 GB"`；TB 是最后一档，与 iOS `MessageContentView.bytes`、Android `MessageContentView` 的附件格式化同风格。

`locale` 允许宿主把语言透传进来，但数字与单位后缀在所有语言下一致——同一份存储快照在用户的两台设备上不该读出两种写法。

## 宿主接入

::: code-group

```vue [Vue / Tauri]
<FlareStorageUsage
  :categories="categories" :total-bytes="totalBytes"
  :device-free-bytes="deviceFreeBytes" :loading="loading" :error="error"
  @clear="(id) => confirmThenClear(id)"
  @reload="measure"
  @dismiss-error="(id) => clearError(id)" />
```

```dart [Flutter]
FlareStorageUsage(
  categories: categories,
  totalBytes: totalBytes,
  deviceFreeBytes: deviceFreeBytes,
  loading: loading,
  error: error,
  onClear: confirmThenClear,
  onReload: measure,
  onDismissError: clearError,
)
```

```swift [SwiftUI]
StorageUsageView(categories: categories,
                 totalBytes: totalBytes,
                 deviceFreeBytes: deviceFreeBytes,
                 loading: loading,
                 error: error,
                 onClear: { id in confirmThenClear(id) },
                 onReload: measure,
                 onDismissError: clearError)
```

```kotlin [Compose]
StorageUsage(
    categories = categories,
    totalBytes = totalBytes,
    deviceFreeBytes = deviceFreeBytes,
    loading = loading,
    error = error,
    onClear = ::confirmThenClear,
    onReload = ::measure,
    onDismissError = ::clearError,
)
```

:::

原生端没传 `onClear` 就不显示清理按钮，没传 `onReload` 就不显示「重新统计」——不显示点了没反应的按钮。`dismissError` 的载荷是分类 ID，`null` 表示整体统计错误。分类 `id` 必须稳定，所有事件都用它回指。文案全部通过 props 传入并带默认值（`fileCountText` 里的 `{count}` 会被文件数替换），宿主按语言替换。

## 布局、规模与可访问性

分类数量由宿主决定，原生端用有界列表（Compose `LazyColumn` 限高、Flutter `ListView.builder` 收缩包裹且不自带滚动），不放进无界纵向滚动。每行主区最小高度 48 逻辑单位，清理按钮在触控设备上同样不低于 48（桌面指针下 40）。状态不只靠颜色：未知是文字、清理中是「清理中」+ 进度指示、失败是图标 + 原因 + danger 色。骨架对读屏隐藏，另有 `role="status"` 的「正在统计存储占用」；错误区是 `role="alert"`；清理按钮的读屏名称是「清理 + 分类名」，不是光秃秃的「清理」。长分类名换行、超长失败原因按字符换行不撑破布局，RTL 下用逻辑属性排布。示例是本地状态，不能替代 SDK 与真机读屏验收。
