---
title: RelationActionBar 关系操作条
---

# RelationActionBar 关系操作条

联系人详情页底部的关系操作条。关系状态由宿主给，组件只负责一件事：把「当前是什么关系」加上「宿主能承接哪些能力」，算成一组有序按钮。共享纯函数 `relationActions(relation, capabilities)` 决定集合、顺序、主次与危险标记，四端得到完全一致的结果；组件只发出意图，不改关系、不发请求、不自动重试。

<div class="flare-demo flare-demo--stack"><RelationActionBarDemo /></div>

<ComponentApi name="RelationActionBar" />

## 状态与恢复规则

| relation | 展示（按顺序） |
|---|---|
| `none` | add（主态）、block |
| `pendingOut` | 「等待对方验证」禁用主态 + block；**不给 add**，避免重复发申请 |
| `pendingIn` | accept（主态）、reject、block |
| `friends` | message（主态）、remove（危险）、block（危险） |
| `blocked` | unblock（主态）；其余全部不显示，被拉黑状态下不给发消息、不给加好友 |

| 情况 | 展示与恢复 |
|---|---|
| 能力缺省或 false | 对应按钮不显示，而不是显示一个点不动的禁用按钮 |
| 一个能力都没有 | 显示 emptyText，操作条不会空白 |
| `busy` | 全部按钮禁用，只有被触发的那一项显示进度并把「处理中」追加进读屏名称 |
| `error` | 顶部错误语气条常驻，图标 + 文字 + 可关闭；组件不自动清空，宿主也不必清 |
| 危险动作 | remove 与 block 单独一组、置于尾部、用 error token；处理中同样锁定 |

`pendingOut` 的等待提示与能力开关无关：它报告状态，不提供命令。`action` 事件只携带 `{ action }`，动作枚举固定为 `add | accept | reject | remove | block | unblock | message`；`dismissError` 只表示用户想收起这条提示，宿主自行决定是否保留原因。关系翻转由宿主在 SDK 确认后写回 `relation`，组件永远不自己推进状态。

## 宿主接入

宿主在发命令**之前同步置 busy**，命令返回后写 `relation` 或写 `error`，两者都不该由组件推断。删除好友、加入黑名单这类动作通常再经过一次 DangerConfirm，由宿主编排——本组件只发意图，不是确认弹层。

::: code-group

```vue [Vue / Tauri]
<FlareRelationActionBar
  :relation="relation" :capabilities="caps" :busy="busy" :error="error"
  @action="({ action }) => run(action)" @dismiss-error="error = ''" />
```

```dart [Flutter]
FlareRelationActionBar(
  relation: relation,
  capabilities: caps,
  busy: busy,
  error: error,
  onAction: run,
  onDismissError: () => setState(() => error = null),
);
```

```swift [SwiftUI]
RelationActionBarView(relation: relation, capabilities: caps, busy: busy, error: error,
                      onAction: run, onDismissError: { error = nil })
```

```kotlin [Compose]
RelationActionBar(
    relation = relation,
    capabilities = caps,
    busy = busy,
    error = error,
    onAction = ::run,
    onDismissError = { error = null },
)
```

:::

原生端未传 `onAction` 时所有按钮按禁用渲染，未传 `onDismissError` 时错误条不显示关闭入口；Vue 接入方必须监听 `action`。所有文案通过 props 传入并带默认值，宿主按语言替换。

## 布局、规模与可访问性

操作条最多 3 个按钮，横向排列并在窄屏换行，不需要内部滚动；危险分组用一条分隔线与主动作隔开，并靠向尾部。宿主把它固定在详情页底部安全区之上即可，不要放进无界纵向滚动里。

每个按钮最小 48×48 逻辑单位，文案单行不换行、超长省略；错误文案换行不截断。状态不只靠颜色：主态有填充背景 + 图标，危险动作有独立分组 + 图标 + error 色，等待态有时钟图标 + 文字。错误条是 `role="alert"` / live region，出现时读屏立即播报；按钮进度态把「处理中」拼进读屏名称。桌面端 Tab 在按钮间移动、Enter 触发，焦点环可见。示例使用本地状态，不能替代 SDK 与真机读屏验收。
