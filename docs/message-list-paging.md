# 消息列表的两端：往旧、往新与回到最新

消息列表画的是宿主交来的一段**窗口**。窗口有两端：时间线上方是往旧的一端；窗口脱离最新（围绕某条消息打开，例如定位到一条搜索结果）时，时间线下方还有往新的一端。两端按同一条规则画、同一条规则自动请求；脱离最新的窗口另有一个「回到最新」键。列表还告诉宿主读者是否在窗口底部，宿主据此标已读。四端读同一份 `spec/message-list-paging-vectors.json`。

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
| 宿主给窗口起的名字 | `windowId` | `windowId` | `windowId` | `windowId` |
| 读者是否在窗口底部 | 事件 `atBottomChange` | `onAtBottomChange` | `onAtBottomChange` | `onAtBottomChange` |

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
| Vue | 每次 `scroll` 事件；整体替换后，读者用滚轮、触摸、指针或按键移动列表之前不算 |
| Flutter | 拖动中的每次滚动更新（与原来往旧的判断相同） |
| Compose | 读者每次移动（列表第一行的键或偏移变了）；窗口第一次布局不算；整体替换后，读者拖动之前不算 |
| SwiftUI | 第一行或末尾的位置每次变化；窗口第一次报告位置不算；整体替换后，读者移动之前不算（iOS 18 / macOS 15 读滚动阶段，更早的系统读拖动手势） |

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
- **脱离最新的窗口底部不跟随**：那里不会来新消息。「读者是否在底部」（见下文）仍然报告窗口的底部。
- **回到最新**：读者点了回到最新之后，宿主交来的下一个接在最新的窗口（`hasNewer` 变为 false）打开在最新一条，不管旧窗口停在哪里。
- 行键沿用 `resolveMessageId`（`clientMsgId || serverId`），与核心视图的 `rowKey` 相同，发送确认前后不变。

## 整体替换窗口（`windows`）

宿主有时不是在窗口两端加行，而是整个换掉窗口：围绕一条消息打开、回到最新、在脱离最新的窗口里发消息后核心换成最新窗口。一次变化满足下面任一条，就是整体替换（前后两个窗口都要有行）：

- 宿主给窗口起了名字（`windowId`，即核心时间线视图的 `viewId`；null 或空串算没有名字），并且从一个名字换成了另一个名字；
- 读者点了回到最新，宿主交来的窗口接在最新（`hasNewer` 为 false）；
- 新窗口里没有一行在旧窗口里出现过。

第一个窗口（之前没有行）是打开，不算替换；窗口被清空是从头开始，也不算。行有重叠、名字也没换，就是同一个窗口的变化：翻页、新消息、编辑、删除，或者核心对仍在窗口里的行发来的快照。

整体替换之后：

- 新窗口在最新一行打开；脱离最新的窗口底部仍然不跟随；
- 读者在旧窗口里的位置一概不用：为旧窗口记下的前插锚点作废，下方计数清零；
- 读者自己移动列表之前，列表不自动请求往旧或往新。替换本身引起的滚动不算读者移动——浏览器可能把滚动位置留在 0，也可能留在新窗口的末尾（Chromium 在点了引用、被聚焦的引用随旧行一起移除时会这样：焦点修正重算样式，时间线是尺寸容器，重算时在旧行已删、新行未插的瞬间做了一次布局，滚动位置被夹到 0）；列表自己摆放窗口、定位落在边缘附近也不算。读者移动的判断见上一节的表。

## 定位接管阅读位置（`locateAfterReplace`）

列表滚到定位的那一行之后，这一行就是读者的位置，直到读者自己移动列表：

- 定位之前记下的前插锚点作废，否则它会把读者拉回已经离开的行；
- 读者移动之前落下来的一页（例如定位前已经发出的往旧请求），以定位的那一行为锚点，让它留在中间，即使定位的滚动还没结束；
- 列表自己的动作不把读者从这一行带走：Vue 的列表高度变化（往新一端出现、状态条出现或消失）不再把靠近底部的读者拉到底，Compose 与 SwiftUI 在定位滚动途中落下的一页会把这一行放回中间，Flutter 以这一行为轴心并在这一帧之后把它放回中间。

`spec/message-list-paging-vectors.json` 的 `locateAfterReplace` 是一次完整的过程：先显示 `before`，可选地由读者往旧请求一页，宿主交来 `after`，再定位到 `locate`，可选地落下一页，最后可选地由读者滚到一端。期望值是这一过程里列表自己发出的全部请求、定位的那一行最后是否在视口内、落地时是否带标记。Vue 用模拟浏览器滚动的组件测试把每个用例跑两遍（替换后滚动位置在 0 和在末尾），Flutter 用组件测试，Compose 与 SwiftUI 用列表保存阅读位置的模型逐条核对，Compose 另有设备上的组件测试。

## 读者是否在底部（`atBottom`）

已读的规则是「窗口接在最新，并且读者在底部」才前进。前一半宿主从时间线视图知道（`attachedToLatest`），后一半由列表回答：Vue 发出 `atBottomChange(atBottom)`，三个原生 Kit 调 `onAtBottomChange(atBottom)`（Compose `(Boolean) -> Unit`，SwiftUI `(Bool) -> Void`，Flutter `ValueChanged<bool>`，缺省都不传）。

- **判定**：时间线末尾低于视口底部的距离（与 `requests` 的 `fromBottom` 相同）不超过 80 个逻辑像素（CSS px、dp、pt），含等于，就算在底部。空列表在底部。
- **什么时候回调**：只在回答变化时回调；每个会话第一次布局之后回调一次，不管回答是什么。换会话从头算。
- **说的是窗口的底部**：脱离最新的窗口也照样回答，宿主自己核对窗口是否接在最新。
- **整体替换与定位**：宿主没经读者要求就整体换掉窗口（`windows`），或者定位接管了阅读位置（`locateAfterReplace`），列表立即回答 false（之前是 true 时），并保持 false，直到下面任一件事发生；之后按最近一次布局回答：
  - 读者自己移动列表；
  - 列表替读者回到最新一行：点了「下方有 N 条新消息」，或者读者自己发的消息追加在末尾；
  - 读者点了回到最新，宿主交来的最新窗口到了；
  - 窗口被清空。

  列表把换来的窗口摆在最新一行、定位落在末尾附近，都不是读者到了底部。替换本身引起的滚动（浏览器可能把滚动位置留在 0 或新窗口的末尾）也不算：替换之后、读者移动之前回答一直是 false。整体替换窗口里最后一行恰好是读者自己的消息，也不算读者发了一条消息。

`spec/message-list-paging-vectors.json` 的 `atBottom`（18 例）是一步一步的过程：`layout`（列表量到的一次布局或滚动）、`replaced`、`jumpedToLatest`、`located`、`readerMoved`、`wentToLatest`、`emptied`、`anotherConversation`，每一步之后列表告诉宿主什么（true、false，或者什么都不说）。四端的列表各用一份同名规则（Vue `FlareMessageListBottomReport`，Compose `MessageListBottomReport`，SwiftUI `FlareMessageListPaging.BottomReport`，Flutter `FlareMessageListBottomReport`）逐条核对，另有组件测试：滚到底回调 true，往上翻回调 false，读者在底部时新消息追加仍是 true（不出现中间的 false），整体替换后回答 false、读者移动后才回到 true，定位到最后一行仍是 false。

各端怎么量、怎么认读者移动：

| 端 | 量的是什么 | 读者移动 | 回调时机 |
| --- | --- | --- | --- |
| Vue | `scrollHeight − scrollTop − clientHeight`，每次 `scroll` 与列表自己滚动之后 | 滚轮、触摸、指针、滚动按键 | 同步发出事件 |
| Compose | 最后一行的底边低于视口底边多少（最后一行不在布局里时为无穷远），每次布局；正在回到末尾的那次布局不算 | 拖动（`DragInteraction.Start`） | 布局之后 |
| SwiftUI | iOS 18 / macOS 15 读滚动视图自己的几何（`onScrollGeometryChange`）；更早的系统读时间线末尾那一行的位置 | iOS 18 / macOS 15 读滚动阶段，更早的系统读拖动手势 | 布局之后 |
| Flutter | 列表自下而上排，`pixels − minScrollExtent`，每次滚动、内容尺寸变化与每一帧之后 | 读者滚动列表（拖动或滚轮，`UserScrollNotification`） | 这一帧之后，按顺序 |

宿主接线：把回答存下来，标已读时用它，删掉自己判断「在不在底部」的写法（迁移说明 §4zb）。

```kotlin
var readerAtBottom by remember(conversation.id) { mutableStateOf(true) }
MessageList(
    messages = rows, currentUserId = me, conversationId = conversation.id, windowId = window?.viewId,
    onAtBottomChange = { readerAtBottom = it },
)
```

```swift
@State private var readerAtBottom = true
MessageListView(messages: rows, currentUserId: me, windowId: window?.viewId,
                onAtBottomChange: { readerAtBottom = $0 }, conversationId: conversation.id)
```

```dart
FlareMessageList(
  messages: rows,
  currentUserId: me,
  windowId: window?.viewId,
  onAtBottomChange: (atBottom) {
    _readerAtBottom = atBottom;
    if (atBottom) _markReadIfVisible();
  },
)
```

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

## 宿主接线：核心时间线视图

列表的输入都来自核心时间线视图（`view.timeline.*`，社交包的 `views` 门面原样转发）。视图的 wire 如下，字段都是 camelCase：

| op | 请求 | 返回 |
| --- | --- | --- |
| `view.timeline.open` | `{ conversationId, messageLimit?, anchor?: { messageId?, seq? } }` | `{ viewId, revision, snapshot }` |
| `view.timeline.load_older` | `{ viewId, messageLimit? }` | `{ viewId, loadedCount, revision }` |
| `view.timeline.load_newer` | `{ viewId, messageLimit? }` | `{ viewId, loadedCount, revision }` |
| `view.timeline.jump_to_latest` | `{ viewId }` | `{ viewId, loadedCount, revision }` |
| `view.timeline.snapshot` | `{ viewId }` | `{ viewId, revision, snapshot }` |
| `view.close` | `{ viewId }` | — |

- 不带 `anchor` 的 `open` 是最新窗口；带 `anchor` 时围绕那条消息打开，`messageId` 是服务端 id 或客户端 id，本地找不到时用 `seq`，两者都找不到时失败为 `sdk.view.anchor_not_found`。`messageLimit` 不传，用核心默认的 40。
- `snapshot` 是 `{ viewType: "timeline", data }`，`data` 为 `{ conversation, messages, hasOlder, hasNewer, attachedToLatest, anchorKey? }`。`messages` 按时间线顺序排列，`anchorKey` 只在围绕某条消息打开时出现，是目标行的行键。
- 三个翻页 op 不返回行：返回值只说这一页在哪个版本里（`revision`）、读进了几行（`loadedCount`；回到最新时是新窗口的行数）。行本身只经 `view.updated` 事件推出。视图已关闭时三者静默返回 `{ loadedCount: 0, revision: 0 }`。

**`view.updated`**：`{ viewId, revision, kind, snapshot?, delta? }`，`revision` 在同一视图里严格递增。

- `kind: "snapshot"`：整体替换窗口，见于回到最新、核心判断增量不划算、行全部换掉或行键重复时。
- `kind: "delta"`：`delta` 为 `{ viewType: "timeline", prepend, append, upsert, remove, reorder?, hasOlder, hasNewer, attachedToLatest, conversation? }`。四个数组总在；`remove` 是行键；`reorder` 只在前四步表达不了顺序时给，列出全部行键；`conversation` 只在会话摘要变了时带。

**应用规则**（`flare-core-sdk/sdk-spec/golden/view/timeline-delta.json`，各端应用器读同一份）：

1. `revision` 不大于已应用的版本：丢弃（`stale`），这是快照返回之前就在路上的旧事件。
2. `revision` 不是已应用版本加 1：不应用，调 `view.timeline.snapshot` 取当前快照整体替换（`snapshotRequired`）。
3. 否则依次：删掉 `remove` 里的行；`upsert` 按行键原位替换；`prepend` 放最前、`append` 放最后（都已按时间线顺序）；`reorder` 非空时按它重排；最后取三个状态字段，有 `conversation` 时换掉会话摘要。

行键是 `clientMsgId || serverId || "seq:<conversationId>:<conversationSeq>"`（判空不去空白），与 Kit 的 `resolveMessageId` 相同，所以列表的前插保持位置、定位都不用改。增量里通常不带会话 id，应用器自己记着。

**交给列表的值**：

| Kit 输入 / 意图 | 来自视图 |
| --- | --- |
| `messages` | 应用器按时间线顺序维护的行 |
| `hasOlder` / `hasNewer` | 同名状态字段（`hasNewer` 为 false 当且仅当 `attachedToLatest`） |
| `loadingOlder` / `loadingNewer` | 宿主在调用 `load_older` / `load_newer` 期间置 true，op 返回（或对应 `revision` 的 `view.updated` 应用完）后置 false |
| `olderError` / `newerError` | op 失败时宿主的本地化文案；失败前已在已证实区间里读到的行会先随事件到达 |
| 往旧 / 往新 / 回到最新 | `load_older` / `load_newer` / `jump_to_latest`；在脱离最新的窗口里发消息时，核心自己先把窗口换成最新，宿主不用先调 `jump_to_latest` |
| 定位的 `openAround(anchor)` | 带 `anchor` 的 `open`，返回快照的 `anchorKey`；`anchor_not_found` 或打开失败时返回 null |
| `windowId` | 当前视图的 `viewId`。定位打开新视图时它变了，列表据此知道窗口被整体换掉，即使新旧窗口有共同的行 |

翻页返回的 `revision` 大于已应用的版本时，这一页还没有画到列表里。宿主如果要在 await 之后立刻读到这一页（例如定位编排的 `settle`），先调一次 `snapshot` 换上。

```ts
import { flareLocateMessageAround } from "@flare-im/vue-ui/utils";

// 打开：应用器从 open 的返回 { viewId, revision, snapshot } 起步，之后每条 view.updated 交给它。
const opened = await views.open(conversationId);
const view = TimelineViewState.from(opened);
views.onViewUpdated(async (update) => {
  if (update.viewId !== view.viewId) return;
  if (view.apply(update) === "snapshotRequired") view.replace(await views.snapshot(view.viewId));
});

// 定位：先问列表，再围绕目标打开，列表滚过去并标记。
const outcome = await flareLocateMessageAround({
  anchor: { messageId: id, seq },
  showInList: (key) => list.value?.scrollToMessage(key) ?? false,
  openAround: async (anchor) => {
    const around = await views.open(conversationId, { anchor }).catch(() => null);
    if (!around) return null;
    view.replace(around);
    return around.snapshot.data.anchorKey ?? null;
  },
  settle: () => nextTick(),
  isCurrent: () => activeConversationId.value === conversationId,
});
```

```vue
<FlareMessageList
  :window-id="view.viewId"
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
  @at-bottom-change="setReaderAtBottom"
/>
```

`views` 是社交包的视图门面，`TimelineViewState` 是各端社交包的应用器（各语言按习惯命名），两者都在社交包里，Kit 不依赖它们。原生端同理：把应用器的 `hasOlder` / `hasNewer` 和视图的 `viewId`（`windowId`）交给列表，`onLoadOlder` / `onLoadNewer` / `onJumpToLatest` 转给视图的 `load_older` / `load_newer` / `jump_to_latest`，定位时用 `openAround` 调带 `anchor` 的 `open`，把快照里的 `anchorKey` 交回。标已读读的是 `attachedToLatest` 加上列表回调的「读者在底部」（`atBottomChange` / `onAtBottomChange`）。
