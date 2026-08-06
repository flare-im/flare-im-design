# @flare-im/ui-spec — L2 组件契约

[English](README.md) · 中文

框架中立的 IM 组件契约：**一个组件 = 一份契约（props / states / events + 数据源 core view），各端原生实现**。
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
| `dataSource` | 数据来自哪个 **core 可观察视图**（L4）——所有端消费同一个 |
| `props[]` | `{ name, type, required?, default?, desc? }` |
| `states[]` | 可能的状态（如 pending/sent/read/failed） |
| `events[]` | 回调/事件名 |
| `platforms` | `vue / flutter / ios / compose` → `{ package, symbol }`（各端依赖与符号） |

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

## 校验（防漂移，仿 sdk-spec 双向覆盖）
```bash
node validate.mjs
```
检查：① 每个组件契约字段完整；② 四端都有 package+symbol；③ **Vue 参考符号（如 `MessageBubble.vue`）确实存在于
`@flare-im/vue-ui`**——spec 与参考实现对不上就报错。各端 L1 包落地后，扩展校验为「该端符号存在且 props 覆盖」。

## 关系
- **L4** 数据/行为：`flare-im-core-sdk` client.views（已有）——`dataSource` 指向它。
- **L3** tokens：[`../tokens`](../tokens)——组件视觉走 `--flare-*`。
- **L1** 各端包：Vue 已在 `@flare-im/vue-ui`；Flutter/iOS/Compose 待从各端 app 抽取（Phase 4）。
