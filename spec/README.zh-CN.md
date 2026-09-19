# @flare-im/ui-spec — L2 组件契约

[English](README.md) · 中文

框架中立的 IM 组件契约：**一个组件 = 一份契约（props / states / events + 宿主持有的数据源），各端原生实现**。
是「类 Ant Design 组件 API」中立化的部分——各端 L1 包按此实现，一致性靠本 spec 锁定。

## 安装

```bash
npm install @flare-im/ui-spec
```

契约本身是一份 JSON，可直接读取：

```js
import components from "@flare-im/ui-spec/components.json" with { type: "json" };

console.log(components.length); // 组件数量
```

自己实现某一端的组件库时，用它作为唯一事实来源校验 props/events 是否齐全 ——
四端实现不一致的问题，就是靠这份契约锁住的。

## 契约格式（每个组件）
| 字段 | 含义 |
|---|---|
| `name` | 组件名（各端符号见 `platforms`） |
| `summary` | 一句话职责 |
| `dataSource` | 四端组件消费的宿主展示数据 |
| `props[]` | `{ name, type, required?, default?, desc? }` |
| `states[]` | 可能的状态（如 pending/sent/read/failed） |
| `events[]` | 回调/事件名——契约层统一 camelCase；Vue 派生 kebab（`@toggle-select`），原生派生 `on` + Pascal（`onToggleSelect`） |
| `model` | `{ prop, event }`——表单控件的 v-model 对（`modelValue` / `update:modelValue`）；原生端以受控 value / Binding 表达 |
| `props[].platforms` | 可选；限定某 prop 只存在于部分端（如 Vue 专属的插槽探测开关） |
| `eventPlatforms` | 可选 `{ 事件: [端] }`；限定某事件只存在于部分端（如逐动作的消息事件是 Vue 专属，原生端只给 `messageLongPress` 由宿主建菜单） |
| `platformAliases` | 可选 `{ 端: { props: {…}, events: {…} } }`——组件级的平台惯用名（如 `edit` → `onEditRemark`） |
| `platforms` | `vue / flutter / ios / compose` → `{ package, symbol }`（各端依赖与符号）。Vue 符号必须是 `components/index.ts` 的导出名 |

所有组件共用的顶层表：

| 字段 | 含义 |
|---|---|
| `lexicon` | 契约术语 → 各端合法别名（`conversationType` → `conversationKind`、`ariaLabel` → `semanticLabel` / `accessibilityLabel` / `contentDescription` 等） |
| `eventAliases` | 契约事件 → 各端惯用回调（默认派生之外）：`click` → `onPressed` / `action` / `onClick`，`change` → `onChanged`，`submit` → `onSubmitted` |
| `composerActions` | 四端 MessageActionSheet 共用的附件动作 id 表（`image`、`camera`、`file`、`location`、`card`、`vote`、`task`、`schedule`…） |

<!-- CATALOG:START -->
## 组件目录

**111 个组件 / 11 个类目**（源见 [`components.json`](./components.json)；
props/events 从 `@flare-im/vue-ui` 源码抽取校准）。

> 本段由 `gen-readme-catalog.mjs` 从契约生成，不要手改 —— 手写目录会随契约增长而腐烂。

- **Message（消息）** — 31 个
  `AnnouncementBanner` · `ChatHeader` · `ContactMessage` · `DatePill` · `EmojiMessage` · `FileMessage` · `ImageGrid` · `ImageMessage` · `LinkCardMessage` · `LocationMessage` · `MessageActionSheet` · `MessageBatchToolbar` · `MessageBubble` · `MessageContentView` · `MessageList` · `PinnedMessageBar` · `ReactionSummary` · `ReadReceiptSheet` · `RedPacketCard` · `ScrollToLatest` · `StickerMessage` · `SystemMessage` · `TaskMessage` · `TextMessage` · `TranslationView` · `TypingIndicator` · `UnreadDivider` · `VideoMessage` · `VoiceMessage` · `VoicePlayer` · `VoteMessage`
- **General（通用）** — 17 个
  `AnnouncementReadBar` · `Avatar` · `Button` · `EmptyState` · `FilterTabs` · `Icon` · `IconButton` · `Input` · `MessageStatus` · `PrimaryButton` · `SearchBar` · `SearchResults` · `SegmentedControl` · `Skeleton` · `StatusBanner` · `TimeStamp` · `Toast`
- **Composer（输入）** — 13 个
  `Composer` · `ComposerActionPanel` · `ComposerReplyStrip` · `ComposerSendButton` · `EmojiPicker` · `MentionPicker` · `PollComposer` · `QuickPhrases` · `RichMarkdownInput` · `SlashCommandMenu` · `StickerPanel` · `VoiceHoldButton` · `VoiceRecordingBar`
- **Form（表单）** — 11 个
  `Checkbox` · `DatePicker` · `FormField` · `RadioGroup` · `Rating` · `Select` · `Slider` · `Stepper` · `Switch` · `Textarea` · `TimePicker`
- **Contacts（通讯录）** — 8 个
  `ContactDetail` · `ContactItem` · `ContactList` · `ContactMatchList` · `GroupDetail` · `GroupList` · `GroupMemberGrid` · `NewFriendRequests`
- **Moments（圈子）** — 8 个
  `CommentThread` · `MomentActionPopover` · `MomentAudienceSheet` · `MomentCard` · `MomentComposer` · `MomentsCoverHeader` · `MomentsVisibilityRuleList` · `TopicChip`
- **Conversation（会话）** — 6 个
  `ChatWallpaperPicker` · `ConversationDetails` · `ConversationList` · `ConversationRow` · `ForwardPicker` · `StartConversationDialog`
- **Call（音视频通话）** — 5 个
  `CallControls` · `CallDock` · `CallView` · `GroupCallView` · `IncomingCall`
- **Profile（个人中心）** — 5 个
  `ProfileCard` · `ProfileEditor` · `ProfilePanel` · `QRCard` · `SettingsList`
- **Layout（布局）** — 4 个
  `AppShell` · `ConfigProvider` · `ResponsiveLayout` · `ScreenHeader`
- **Media（媒体）** — 3 个
  `ImagePreviewModal` · `MarkdownPreview` · `VideoPlayerModal`

<!-- CATALOG:END -->

**内容类型注册表**（`contentTypes.registered`）：`MessageBubble`/`MessageContentView` 按 content-type 分发到各渲染器
（text/image/video/audio/file/location/card/linkCard/sticker/emoji/vote/task/schedule/announcement/miniProgram/notification/placeholder），产品可注册新类型。

## 校验与防漂移
```bash
node validate.mjs
```
检查：① 每个组件契约字段完整、双语，prop/事件名 camelCase；② 声明的端都有 package+symbol 且符号真实存在（Vue 取 `components/index.ts` 导出；Flutter 类；SwiftUI struct；Compose 函数）；③ **签名**：契约声明的每个 prop 与事件都要能在各端公共签名里找到（按 `lexicon`、`eventAliases`、`platformAliases`、`props[].platforms`、`eventPlatforms` 解释），原生端每个 `onXxx` 回调都要在契约里。历史差异记在 `signature-baseline.json`，且必须同时在组件的 `signatureDifferences` 显式登记，只允许缩小：出现新差异就红，未登记基线就红，差异消失但基线没更新也红。

```bash
node signature-report.mjs                       # 各端差异总数
node signature-report.mjs --component MessageList   # 单组件详情
node signature-report.mjs --baseline            # 差异缩小后重写基线
```

## 关系
- **L4** 宿主数据/行为：适配、状态、网络和持久化均留在组件库之外。
- **L3** tokens：[`../tokens`](../tokens)——组件视觉走 `--flare-*`。
- **L1** 各端包：Vue 已在 `@flare-im/vue-ui`；Flutter/iOS/Compose 待从各端 app 抽取（Phase 4）。
