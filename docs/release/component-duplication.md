# Component Duplication Audit（2.0.0-rc.1）

## 1. 命名模式扫描

扫描 catalog 名 + Vue 公开导出 + Vue 组件文件名，模式：Desktop*/Mobile*/Legacy*/Old*/New*/Base*/Common*/Simple*/Basic*/Lite*/Mini*/Compact*/*2。

| 命中 | 判定 | 说明 |
|---|---|---|
| DesktopAppShell / MobileAppShell | 保留 | 不是样式差异：桌面（侧栏/命令/快捷键）与手机（底部导航/安全区）是两种外壳契约，共享 AppLayout；不合并。 |
| DesktopWorkbench | MERGE → DesktopAppShell（DONE 2026-09-12） | 同为桌面外壳，Compose/iOS 未实现，零消费。 |
| NewFriendRequests | 保留 | 『New』是业务语义（新的朋友），不是版本后缀。 |
| FlareMiniProgramMessageView | DEPRECATE | 业务消息视图，经 registry 接入。 |
| headerroom / roomheader2 / mobileHeaderNew / chatheader2 | 未命中 | 仓库里不存在这些名字；实际重复是 FlareChatHeader vs ConversationHeader（下表）。 |

## 2. 语义重复（同一职责多份实现）

| # | 重复对 | 差异只是 | 证据 | 决定 |
|---|---|---|---|---|
| D1 | messages/standalone/Flare*Message.vue（15，catalog）↔ messages/MessagesView/views/*View.vue（20，时间线实际用）↔ messages/business/*View.vue（5，未登记导出） | 完整度（FileView 8.9K vs FlareFileMessage 1.7K）与是否接媒体/上传 | inventory：standalone 15 个 example 零使用、10–55 行；ContentView.vue 只 import views/*；findings-message F-11 | 一类型一份：views 为实现体，公开名 Flare*Message，MessageContentView 唯一分发；业务类型进 registry。**已闭合（P0-1a，2026-09-12）**：13 个契约体类型的时间线 views 全部改为 adapter（解析 ContentElem、媒体 URL 解析与下载状态留在 view，渲染交给 standalone Flare*Message）；File/Image/Video/Sticker/Emoji/Task 契约体补 Vue 注册扩展 props（state/embedded/maxWidth/maxHeight/badge/loading/loadSrc 等，spec 标 platforms:[vue]）；business Task/Vote 视图同样接契约体；无契约体的 Forward/ImageGroup/Quote/RichText/Notification/Placeholder/InfoCard/Schedule/Announcement/MiniProgram 为单实现，保留。证据：ContentView.test.ts 13 例、vitest 423/423、check:sfc 204、Playwright 145/145、hardcoded-visuals vue 1494→1364 已锁基线、plans/audit-2026-09-12/patch-P01a-message-bodies.patch |
| D2 | VoiceMessage ↔ VoicePlayer | 波形根数/时长格式/半径/播放钮样式 | findings-message F-11；两者都有四端实现 | VoiceMessage = VoicePlayer compact 变体 |
| D3 | TimeStamp ↔ DatePill | 有无胶囊/描边/阴影 | TimeStamp 10 行仅 MessageList 内部；DatePill 四端 | 删 TimeStamp |
| D4 | MessageList 内 .message-list-scroll-bottom ↔ ScrollToLatest | 计数文案 vs 紫圆箭头 | message-workspace.css:189-231；ScrollToLatest 零消费 | MessageList 用 ScrollToLatest |
| D5 | PrimaryButton ↔ Button(variant=primary) | 无 | 原生列表『加载更多』用 PrimaryButton（findings-layout F20） | 合并进 Button |
| D6 | FlareChatHeader(+Identity) ↔ ConversationHeader | 头部布局与身份块拆法 | 两者都从 components/index.ts 导出，ChatHeader 未登记但 example 用 | 合并进 ConversationHeader |
| D7 | FlareStartConversationSheet ↔ StartConversationDialog | sheet vs NModal | 同一流程两皮，Dialog 直接依赖 naive-ui NModal | 合并，呈现由 Platform capability（bottomSheet）决定 |
| D8 | composer/MessageActionSheet.vue（附件九宫格）↔ ComposerActionPanel | 名字 | 两者都 resolveComposerActions；契约里 MessageActionSheet 本应是长按面板（P0） | 九宫格并入 ComposerActionPanel；MessageContextMenuSheet 登记为 MessageActionSheet。**已闭合（P0-1b，2026-09-12）**：四端 MessageActionSheet 现在都是消息长按面板（Vue messages/MessageActionSheet.vue、Flutter FlareMessageActionSheet、Compose MessageActionSheet、iOS MessageActionSheetView：表情条 + primary/organize/destructive 分组，事件 action/react），附件九宫格只剩 ComposerActionPanel（Vue 默认标签走 i18n、role=group），Flutter/Compose/iOS 的 FlareComposerAction 类型随九宫格迁入 composer 文件；契约 props/events/eventPlatforms 重写，spec/validate 回调对齐（onReact）；catalog sourcePaths 由符号定位自动指向新文件。证据：vitest 97（composer+messages）、flutter 441、compose 31 XML 无失败、swift 185、Playwright 145、spec validate OK |
| D9 | ConversationListContainer ↔ FlareConversationListPanel | Panel 多 header/search/filters/status | Panel 组合 Container，web 示例用 Panel | 一个公开 ConversationListPanel |
| D10 | ContactsWorkspace…SavedMessagesWorkspace（7）↔ WorkspaceFrame | 名字 | components/index.ts:259-265 别名；原生一行转发 | 一个 WorkspaceFrame |
| D11 | MasterDetailLayout / ThreePaneLayout ↔ AdaptiveWorkbench | 栅格列数 | 19/23 行片段，零消费 | 内部化（Round 10 起 AdaptiveWorkbench 本身也已退役，见 D18） |
| D12 | AppShell ↔ MobileAppShell + DesktopAppShell | 几何、角标、可达性都不同 | findings-layout F13 | 弃用 AppShell |
| D13 | MessagePreviewModal / MediaComposerPreviewModal / ImagePreviewModal / VideoPlayerModal | 入口（时间线/composer）与媒体类型 | 四个模态、两套外壳 | 收敛为一个 MediaPreview + composer 预览 |
| D14 | EmojiPicker + StickerPanel ↔ FlareComposerEmojiStickerPanel | 是否合体 | demo/example 用未登记的合体件 | 三合一并登记 |
| D15 | ConversationWorkspace（ResponsiveLayout 族）↔ AppLayout 族的 7 Workspace | 断点 720/1100 vs 600/900/1500；状态渲染完整 vs 缺失 | findings-layout F3/F7 | 抽共享 WorkspacePane/PaneBackBar，断点单源（Wave A3 已统一 mode） |
| D16 | Vue Composer 内联 send/reply/voice ↔ ComposerSendButton / ComposerReplyStrip / VoiceHoldButton | 无 | Composer 不使用三个契约子件（kit 内部引用 0） | Composer 消费子件，子件内部化 |
| D17 | SceneList（MemberPanel/DeviceSessions/MediaCenter/StorageUsage/NotificationPreferences 的行）↔ ContactItem / SettingsRow | 有无头像与副标题、按钮皮 | findings-conv F17 | 用 kit 行组件重做 |
| D18 | AdaptiveWorkbench ↔ AppLayout | 不量盒子、不走分栏规则、不报告呈现、没有 `activePane` | Round 9 FR-140：同一组区域、同一套词汇，四端零消费 | 删除，AppLayout 是唯一的窗格组合件（Round 10） |

## 3. Desktop/Mobile 复制业务逻辑检查

- 会话/消息/成员菜单：桌面 ContextMenu 与手机 BottomSheet 已消费同一套 action 数据（ConversationActionSheet、MessageContextMenuSheet、MemberRoleSheet），未发现两份 action 定义。
- Composer：Vue 桌面为 3 键圆角卡、原生为 6–7 键平铺带（findings-composer）——呈现差异，不是逻辑复制；但 Vue 桌面附件动作走 composer/MessageActionSheet.vue、手机走 ComposerActionPanel 是同一份 resolveComposerActions 的两个壳（D8）。
- 断点：AppLayout 族与 ResponsiveLayout 族两套（D15）。

## 4. 过度拆分（片段）

inventory 里 Vue < 70 行且 example 零使用的 46 个中，属于真正片段并已给出动作的：TimeStamp（删）、MasterDetail/ThreePane（内部化）、ComposerSendButton/ReplyStrip/VoiceHoldButton（内部化）、MemberPanel 等 5 个 SceneList 包装（重做或弃用）、standalone 消息体 15 个（合并）。其余小组件（Switch、Icon、Skeleton、TopicChip…）是原语，行数少是正常的。

## 5. 巨型组件

| 组件 | 规模 | 混杂职责 | 动作 |
|---|---|---|---|
| Composer | vue 1361 / props 27 / bool 12 → 878（2026-09-13 P0-5） | 编辑、附件动作、语音、上传进度、@、草稿、发送态 | SPLIT 已做：Composer 只编排；录音经 `provideFlareVoiceRecorder` 适配器（`useVoiceRecorder` 状态机 + 单测）；文件拖入 `useFileDrop`；Markdown 快捷键 `useMarkdownShortcuts`；回复/编辑条 = ComposerReplyStrip、发送键 = ComposerSendButton、@ = MentionPicker、九宫格 = ComposerActionPanel；上传条 / 格式条 / 语音面板为私有部件。公开 props / events 不变，20 条交互测试与 IME 测试保留 |
| MessageList | vue 888 / props 16 | 虚拟化 + 自绘回底/时间芯片 + 分页 | REFACTOR：消费 ScrollToLatest/DatePill/UnreadDivider，补 loading/empty |
| MessageBubble | vue 677 | 气泡 + 反应 span + 上传条 + 置顶标 + 撤回 + 工具栏两份模板 | REFACTOR：ReactionSummary、MessageBubbleCore 单处渲染 |
| RichMarkdownInput | vue 1112 | 单一（编辑器） | KEEP |
| GroupPermissionMatrix | props 25 | API 失控 | REFACTOR：config 对象 |

## 6. 处置进度（2026-09-12）

真源 `spec/duplication-register.json`，门禁 `node tooling/check-duplicate-components.mjs`（release-check `duplicate-components --strict`：任一条目未 DONE 即红）与 `node tooling/check-dead-components.mjs`（release-check `dead-components --strict`）。迁移说明见 `docs/release/migration/2.0-rc-to-2.0.md`。

| 条目 | 决定 | 状态 |
|---|---|---|
| D1 消息体三份 | MERGE → 一类型一份 | DONE（P0-1a） |
| D2 VoiceMessage ↔ VoicePlayer | KEEP（消息体 vs 播放器，职责不同；flutter app 用 VoicePlayer） | DONE |
| D3 TimeStamp ↔ DatePill | REMOVE → DatePill | DONE（四端） |
| D4 MessageList 内联按钮 ↔ ScrollToLatest | REFACTOR → MessageList 组合 ScrollToLatest | DONE |
| D5 PrimaryButton ↔ Button | MERGE → Button(size=lg, block) | DONE（四端 + 消费者改写） |
| D6 ChatHeader ↔ ConversationHeader | MERGE → ConversationHeader | DONE（四端；Vue Identity 一并删除） |
| D7 StartConversationSheet ↔ Dialog | MERGE → Dialog（呈现随 bottomSheet 能力） | DONE |
| D8 九宫格 ↔ ComposerActionPanel | MERGE | DONE（P0-1b） |
| D9 ConversationListPanel ↔ Container | MERGE → Container（面板搬到参考 workbench；iOS 泛型容器删除） | DONE |
| D10 7 个 Workspace 别名 | MERGE → WorkspaceFrame | DONE（四端；catalog −6） |
| D11 MasterDetail / ThreePane | INTERNALIZE → AdaptiveWorkbench 私有栅格 | DONE（四端；宿主工作台随 D18 退役） |
| D12 AppShell | REMOVE → MobileAppShell / DesktopAppShell | DONE（四端） |
| D13 预览模态 ×4 | SPLIT（媒体查看器不变；MessagePreviewModal 归产品；composer 预览登记为 ComposerMediaPreview） | DONE |
| D14 EmojiSticker 合体件 | REFACTOR（合体件登记为 EmojiStickerPicker 四端；EmojiPicker / StickerPanel 保留） | DONE |
| D15 两套断点 / 窗格状态 | REFACTOR | DEFERRED → P0-8 |
| D16 Composer 内联 vs 子件 | SPLIT → Composer 组合 ReplyStrip / SendButton / MentionPicker / ActionPanel | DONE（P0-5；VoiceHoldButton 仍是原生按住说话部件） |
| D17 SceneList 行 | REFACTOR | DEFERRED → P0-8 |
| D18 AdaptiveWorkbench ↔ AppLayout | REMOVE → AppLayout | DONE（四端，Round 10 B4 / FR-140） |
| N1 DesktopWorkbench ↔ DesktopAppShell | MERGE → DesktopAppShell | DONE（Vue + Flutter；命令集 7 个） |
| N2 useViewport ↔ useFlareAdaptive | MERGE | DEFERRED → P0-8（随 D15） |
| K1 QRCard / RedPacketCard / FriendListContainer | KEEP | DONE（flare-social 五端在用） |

组件计数 159 → 147（第一波，−13 +WorkspaceFrame）→ 149（第二波 +EmojiStickerPicker +ComposerMediaPreview）。dead-components 门禁首轮结果：Vue 285/285 源文件可达；Flutter / iOS / Compose 各删除或私有化 3–4 个零消费者符号；网站 5 个孤儿 demo 删除；第二波后只余 Flutter `ComposerInlineTextField` 挂在 D16（P0-5）。

