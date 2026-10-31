# 消息列表的两端：往旧、往新与回到最新

消息列表画的是宿主交来的一段**窗口**。窗口有两端：时间线上方是往旧的一端；窗口脱离最新（围绕某条消息打开，例如定位到一条搜索结果）时，时间线下方还有往新的一端。两端按同一条规则画、同一条规则自动请求；脱离最新的窗口另有一个「回到最新」键。四端读同一份 `spec/message-list-paging-vectors.json`。

新参数都有缺省值。缺省时（`hasNewer` 为 false、没有往新与回到最新的回调）列表与原来完全相同：不画往新一端、从不请求往新，浮动键只有原来的「下方有 N 条新消息」。

## 参数

| 含义 | Vue `FlareMessageList` | Compose `MessageList` | SwiftUI `MessageListView` | Flutter `FlareMessageList` |
| --- | --- | --- | --- | --- |
| 窗口之上还有更早的 | `hasOlder` | `hasOlder` | `hasOlder` | `hasOlder` |
| 正在读更早的一页 | `loadingOlder` | `loadingOlder` | `loadingOlder` | `loadingOlder` |
| 上一页更早的失败了 | `olderError` | `olderError` | `olderError` | `olderError` |
| 读更早的一页 | 事件 `load-older` | `onLoadOlder` | `onLoadOlder` | `onLoadOlder` |
| 窗口之下还有更新的（脱离最新） | `hasNewer` | `hasNewer` | `hasNewer` | `hasNewer` |
| 正在读更新的一页 | `loadingNewer` | `loadingNewer` | `loadingNewer` | `loadingNewer` |
| 上一页更新的失败了 | `newerError` | `newerError` | `newerError` | `newerError` |
| 读更新的一页 | 事件 `load-newer` | `onLoadNewer` | `onLoadNewer` | `onLoadNewer` |
| 把窗口换成最新的 | 事件 `jump-to-latest` | `onJumpToLatest` | `onJumpToLatest` | `onJumpToLatest` |

`hasNewer` 对应核心时间线视图的 `hasNewer`（为 false 当且仅当 `attachedToLatest`），所以 Kit 不另收 `attachedToLatest`。

## 一端画什么（`edges`）

| 状态 | 画什么 |
| --- | --- |
| 正在加载 | 只有转圈。上一次的错误在重试期间不再显示 |
| 不在加载、有错误 | 错误文字；还有更多且宿主接这个意图时，加一个重试按钮 |
| 不在加载、没有错误、还有更多、宿主接这个意图 | 加载按钮 |
| 其余 | 什么都不画 |

- 错误为 null、空串或全空白都算没有错误。
- 「宿主接这个意图」：Vue 监听了对应事件，原生端传了对应回调。没有监听的一端不画按钮，也不自动请求。
- 按钮文字：往旧沿用 `loadOlderText` / `messageListLoadOlder`；往新是 `messageListLoadNewer`（加载更新的消息 / Load newer messages），Vue 为 `chat.loadNewer`，加载中的文字是 `chat.loadingNewer`。
- Vue 到达历史起点时短暂出现的「没有更多消息了」提示不在这张表里，规则不变。

改前三个原生端在「正在加载且有错误」时同时画错误与转圈，Vue 只画转圈；现在四端都只画转圈。

## 什么时候自动请求（`requests`）

一端在下列条件同时成立时请求下一页：

- 读者到这一边的距离不超过 `autoRequest`：往旧 160、往新 160 个逻辑像素（CSS px、dp、pt），含等于；
- 还有更多；
- 不在加载；
- 没有错误（失败后只有重试按钮会请求）；
- 宿主接这个意图。

`fromTop` 是第一行的顶部高出视口顶部多少，`fromBottom` 是时间线末尾低于视口底部多少。两端可以在同一次滚动里都请求（窗口短于一屏时）。每一端在加载状态结束之前最多请求一次。

什么时候判断，按各端的滚动机制：

| 端 | 判断时机 |
| --- | --- |
| Vue | 每次 `scroll` 事件 |
| Flutter | 拖动中的每次滚动更新（与原来往旧的判断相同） |
| Compose | 读者每次移动（列表第一行的键或偏移变了）；窗口第一次布局不算 |
| SwiftUI | 第一行或末尾的位置每次变化；窗口第一次报告位置不算 |

改前 Vue 在距顶 72 px 时才请求更早，Flutter 是 160；Compose 与 SwiftUI 只有按钮。现在四端都在 160 以内自动请求，按钮仍在。

## 回到最新（`jumpToLatest`）

| 窗口 | 宿主接 `jumpToLatest` | 浮动键 | 点击 |
| --- | --- | --- | --- |
| 脱离最新 | 是 | 显示，不带计数 | 发出 `jumpToLatest` |
| 脱离最新 | 否 | 不显示 | — |
| 接在最新、下方来了 N 条新消息（读者已上滑） | — | 显示，计数 N | 滚到底 |
| 接在最新、下方没有新消息 | — | 不显示 | — |

脱离最新时读者下方的行是读进来的历史，不是新消息，所以不计数。浮动键沿用 `ScrollToLatest`，读屏名称为「回到最新」（Vue `timeline.backToLatest`，原生 `scrollToLatest`）。Vue 在往新一端出现时把浮动键抬到它上面。

## 阅读位置

- **往旧翻页**：沿用原来的前插保持位置。
- **往新翻页**：读进脱离最新的窗口的一页，长在读者下方，读者留在正在读的行上——即使这一页以读者自己的消息结尾。之后的新消息从这一页的最后一行起算。判断依据是「窗口此前脱离最新，且这次只在末尾追加了行」：核心不会往脱离最新的窗口里追加实时消息，在脱离最新的窗口里发消息时，核心先把视图换成最新窗口。宿主即使先清掉 `hasNewer`、下一次才交来这一页，也按往新翻页处理。
- **脱离最新的窗口底部不跟随**：那里不会来新消息。`atBottomChange`（Vue）仍然报告窗口的底部。
- **回到最新**：读者点了回到最新之后，宿主交来的下一个接在最新的窗口（`hasNewer` 变为 false）打开在最新一条，不管旧窗口停在哪里。
- 行键沿用 `resolveMessageId`（`clientMsgId || serverId`），与核心视图的 `rowKey` 相同，发送确认前后不变。

## 定位：围绕目标打开

定位编排多了一种形式，给能「围绕某条消息打开窗口」的宿主（核心时间线视图的 `view.timeline.open` 带 `anchor`）。原来逐页往上翻的 `flareLocateMessage` / `FlareLocate.run` 保留，五个 app 切到时间线视图之后再删。

| 端 | 函数 |
| --- | --- |
| Vue | `flareLocateMessageAround({ anchor, showInList, openAround, settle, isCurrent })`（`./utils`），`FlareLocateAnchor` |
| Compose | `flareLocateMessageAround(anchor, showInList, openAround, settle, isCurrent)`，`FlareLocateAnchor` |
| SwiftUI | `FlareLocate.runAround(anchor:showInList:openAround:settle:isCurrent:)`，`FlareLocateAnchor` |
| Flutter | `flareLocateMessageAround(anchor:, showInList:, openAround:, settle:, isCurrent:)`，`FlareLocateAnchor` |

流程（`spec/locate-orchestration-vectors.json` 的 `around`）：

1. 用 `anchor.messageId` 问列表；列表已经有这条，就直接显示，不打开任何窗口。
2. 调一次宿主的 `openAround(anchor)`。它回答锚点键（核心快照的 `anchorKey`，即列表画这条消息用的行键），或者什么都不回答（null、空串、全空白：不在历史里，或打开失败）。
3. 让列表画一遍（`settle`），再用锚点键问列表，最多 6 次。
4. 每次问之前、打开之前、打开之后、每次 `settle` 之前都检查 `isCurrent`；读者离开会话就静默结束（`cancelled`）。

结局是 `shown` / `notInHistory` / `cancelled`。列表自己滚到这一行并标记（`spec/locate-highlight-vectors.json`）；只有 `notInHistory` 需要宿主说一句话，措辞由宿主决定。`anchor.seq` 原样交给宿主，核心找不到本地行时用它。

## 宿主接线

```ts
import { flareLocateMessageAround } from "@flare-im/vue-ui/utils";

// 定位：先问列表，再围绕目标打开，列表滚过去并标记。
const outcome = await flareLocateMessageAround({
  anchor: { messageId: id, seq },
  showInList: (key) => list.value?.scrollToMessage(key) ?? false,
  openAround: async (anchor) => (await views.open({ conversationId, anchor })).anchorKey ?? null,
  settle: () => nextTick(),
  isCurrent: () => activeConversationId.value === conversationId,
});
```

```vue
<FlareMessageList
  :messages="view.rows"
  :has-older="view.hasOlder"
  :loading-older="loadingOlder"
  :older-error="olderError"
  :has-newer="view.hasNewer"
  :loading-newer="loadingNewer"
  :newer-error="newerError"
  @load-older="views.loadOlder(view.viewId)"
  @load-newer="views.loadNewer(view.viewId)"
  @jump-to-latest="views.jumpToLatest(view.viewId)"
/>
```

原生端同理：把视图状态的 `hasOlder` / `hasNewer` 交给列表，`onLoadOlder` / `onLoadNewer` / `onJumpToLatest` 转给视图的 `load_older` / `load_newer` / `jump_to_latest`，定位时用 `openAround` 调带 `anchor` 的 `open`，把快照里的 `anchorKey` 交回。
