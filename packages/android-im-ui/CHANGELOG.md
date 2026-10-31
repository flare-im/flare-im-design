## 未发布

- 新增 `flareStoredPreviewText(raw, strings, locale, systemEventText)`：按共享表 `stored`（`spec/message-preview-vectors.json`）读核心存在会话行、引用与搜索结果上的摘要 token，与 Vue、Flutter、SwiftUI 同一规则。`FlareStrings` 新增 `systemEvent*`，没有自带文字的系统消息按事件键取这些文案。宿主不必再自己解 token。

- **失败气泡改为失败面**：失败底色 `messageFailedBackground`、正文 `messageFailedForeground`、1px `messageFailedBorder` 红边，与 Vue、SwiftUI、Flutter 一致。原来是发出底色加红边、白字，失败图标落在紫色底上。新增 `FlareMessageBubbleTone`、`flareMessageBubbleTone`、`FlareMessageBubblePalette`、`flareMessageBubblePalette`（`spec/message-surface-vectors.json` `palette`），`MessageBubble` 与 `MessageContentView` 都按它取色。
- `MessageList`：关闭动画（系统「移除动画」）时，定位到某条消息（点引用或宿主 `scrollToMessage`）不再被拉回最新消息。原来瞬时跳转被当作布局变化处理，正在跟随底部的列表会被重新放回末尾。
- `PluginViewModels` 去掉源码里字面的 BOM 与不换行空格，改用转义（lint `ByteOrderMark` 报错）。

- 批量工具条转发可用性：`MessageBatchToolbar` 新增 `unforwardableIds: Set<String>`（默认空）：逐条转发至少 1 个、合并转发至少 2 个可转发 id，这两个动作只上报可转发 id；有不可转发项时计数下方显示 `messageBatchUnforwardable`（`messageBatchUnforwardableOne` 为英文单数）。新增 `messageBatchActionIds`、`messageBatchUnforwardableCount`、`MessageBatchAction.forwards`，`messageBatchActionsAvailable` 新增可选参数（`spec/message-batch-vectors.json` 的 forward）。

- 通话：新增 `CallRecordCard` 与 `flareCallRecordStatus` / `flareCallRecordAction` 等规则（`FlareCallRecordScope`、`FlareCallRecordState`、`FlareCallEndReason`，`spec/call-record-vectors.json`），`FlareStrings` 新增 `callRecord*`；`CallView` 新增 `onMinimize`（传入才绘制收起按钮）。**破坏性**：`GroupCallView(state:)` 由 `String` 改为 `FlareCallState`。

- `Drawer` 消费 `FlareSheetOwnHeader(back)`（带返回的 `FlareScreen` 自动声明）：隐藏重复页头，Escape / 系统返回先退当前页，忙碌锁定时两者均不分发页面返回。

- 已读名单分页状态、函数式文案的英文、「我」页内置项副标题、合并转发条目文字与抽屉头像：
  - **已读名单分页状态**：新增 `FlareReadReceiptListState`、`rememberFlareReadReceiptListState(key, page)`、`FlareReadReceiptPages` / `FlareReadReceiptMembers` 与取页函数类型 `FlareReadReceiptPageLoader`（按 `spec/read-receipt-list-vectors.json`，与 Vue `useFlareReadReceiptList` 同名同语义）：打开即两栏并发取第一页，任一不可查看为 unavailable、任一失败为 error；按栏翻页、去重、失败标记、换消息时丢弃在途结果都在 Kit。新增重载 `ReadReceiptSheet(list, readCount, unreadCount, …)`。
  - **英文预设**：函数式文案（计数、名字、权限种类）全部有英文与单复数（新 `FlareStringsEnglishFormats.kt`，由生成的 `flareStringsEnglish()` 调用；用例表 `strings/en-formats.json`，测试要求每个函数式字段都有用例）。英文下会话预览「[Forward] 3 messages」、未读分隔「1 new message」等不再是中文。另补 `messageEdited`、`messageReadOnce`、`messageBurnAfterRead`、`messageExpired` 的英文。
  - **「我」页菜单**：`flareMeMenuSections` 的 `summaries` 按项 id 对内置项同样生效（宿主给「我的邀请」的副标题）。
  - **合并转发**：条目 `plainText` 是核心给的可读文字，按正文摘要的读法画（Markdown 转纯文本、表情包键按读者语言）；抽屉头像首字取发送者名字，没有名字画「?」（原来取「未知发送者」的「未」），新增 `flareForwardSenderInitial`。

- 已读名单分页、渲染上下文的发送者、红包已退回与币种小数位、「我」页菜单、图标回落、合并转发记录与复数（契约与向量四端共用）：
  - **已读名单**：`ReadReceiptSheet` 新增 `readCount` / `unreadCount`（标签数字只取摘要人数，不取名单长度；不传时用纯文案 `readReceiptRead` / `readReceiptUnread`）、`state: FlareReadReceiptState`（Ready / Loading / Error / Unavailable）、两栏各自分页（`readHasMore` / `unreadHasMore`、`loadingMore` / `loadMoreFailed: FlareReadReceiptColumn?`、`onLoadMore(column)`）、`onRetry`、`initialTab`、`modifier`；名单改为懒列表，行、标签与关闭键命中区不小于 `touchTarget`。宽度随容器（不在 Kit 浮层里时自画卡片、最宽 320）；放进 `BottomSheet` 时不画卡片外壳并调用 `FlareSheetOwnHeader()`，`fill` 模式下面板不再画第二遍标题、名单占满剩余高度。新增纯函数 `flareReadReceiptPresentation`（`spec/read-receipt-vectors.json`）。
  - **渲染上下文**：`FlareContentContext` 新增 `senderId`；`senderName` 去空白、空串为 null。`MessageContentView` 新增 `senderId`，`MessageBubble` 传入。
  - **红包**：`FlareRedPacketOpenState` 新增 `Refunded`（`packetRefundedNotice`「红包已退回」，按 `canViewDetails` 给详情键）；`RedPacketComposer` 新增 `currencyExponent`（默认 2）：金额最多保留这么多位小数（0 位时不收小数点、数字键盘），占位按小数位写，币种小数位变少时裁掉多余小数。新增 `flareRedPacketAmountMinor`、`flareRedPacketExponent`。
  - **「我」页菜单**：新增 `flareMeMenuSections(menu, labels, summaries, strings)`、`FlareMeMenu`（`parse(json)` 读社交 SDK 的结果）、`FlareMeMenuItem`、`FlareMeMenuBuiltin`；文案 `meMenuMoments` / `Reports` / `Invite` / `Settings` / `PluginFallback`。
  - **图标**：注册表追加 `wallet`（`Icons.Outlined.AccountBalanceWallet`，109 个）。不认识的图标名改画 `plugin` 字形（原为问号），日志按名字告警一次；新增 `flareIconNameOrFallback` 与 `FLARE_ICON_FALLBACK`。
  - **合并转发记录**：新增内容模型 `FlareForwardContent` / `FlareForwardItem` / `FlareForwardMode`（类型 `forward`，card 表面）与纯函数 `flareForwardRecordView`；`MessageContentView` 画聊天记录卡片（标题、「共 N 条消息」、前三条「发送者: 摘要」、「还有 N 条消息…」、「点击查看详情」），点卡打开 Kit `Drawer` 列出全部消息，单条非合并时直接画那一条；会话预览读作「[转发] N 条消息」。文案 `forwardRecord*`。
  - **复数**：新增 `flarePluralIsOne`、`flarePluralForm`、`flarePlural`（按 `spec/plural-vectors.json` 的 CLDR 规则表），计数文案新增单数字段 `pluginViewVotesOne`、`storageUsageFileCountOne`、`myInviteCountOnlyOne`、`forwardRecordTotalOne`、`forwardRecordMoreOne`；投票票数、分组组头、存储文件数、邀请人数按 Kit locale 取形态。
  - **插件卡片**：标题行占满卡片、标题取剩余宽度，⋯ 键贴行尾（原来两处 weight 平分空间，⋯ 停在行中间）。choices 页脚不再画 total，只有多选上限提示与「已结束」。
  - 测试：新增 `ReadReceiptVectorsTest`、`MeMenuVectorsTest`、`ForwardRecordVectorsTest`、`PluralVectorsTest`，`RedPacketComponentsTest` 读 openSheetRefunded、amountInputExponent、amountMinor、amountPlaceholder。

- 插件页面的数据与动作、行级徽标、多选上限（spec/plugin-view-vectors.json rules.page、pageRows、pagePaging、pageFilters、badge、maxSelections）：
  - **破坏性**：`FlarePluginPage` 新增必填 `page: PluginPageRef`，`view` 改为 `PluginPageViewModel`（视图 + `data`，`fromJson` / `fromMap` 读核心 SDK 的 pluginPage 结果），`onAction` 改为 `(String, PluginPageActionPayload)`（page、data、row、selection、formValues，即页面动作请求，`toJson()` 原样交给核心）；删除 `onOpenDetail`（页面没有详情）。新增 `filters` 与 `onFilter`。
  - 页面状态四种：首次加载、无视图失败（加载停止后才显示，带重试）、不可用（Kit 空态写原因文案，没有原因用 `pluginViewEmpty`，只有 `catalog_unreachable` 带重试；不画刷新、筛选、加载更多与动作）、已加载（刷新失败时顶部危险横幅）。页面改为懒列表：横幅、筛选、视图各部分（同一张主色面板）、加载更多都是列表项，长明细不再一次性组合全部行。
  - 筛选：rows 块列出的 select 输入（不列为全部输入）各画一行 `FilterTabs`，「全部」在前；选中项由宿主的 `filters` 决定，选另一项发出 `onFilter`（宿主其他筛选值保留），选当前项不发；刷新或加载更多时禁用。
  - rows 块：`PluginViewModel` 读 `rows`（`PluginRowsBlock`、`PluginRow`、`PluginRowCell`、`PluginRowsColumn`、`PluginRowsFormat`、`PluginRowAction`），四端画成列表：徽标 + 第一格、其余单元格（时间列按 `time` 格式、空格跳过）以 「 · 」相连、行末动作键；同一 key 只画第一行（在数据层去重，懒列表 key 不会重复）；无行时 `emptyText`，否则 `pluginViewEmpty`。行动作经确认与表单后发出 `PluginActionPayload.row`（`PluginActionRow(key, input)`），只有被点的那一行的键转圈。
  - 徽标：新增 `PluginBadge(text, tone)`，`PluginEntry.badge`、`PluginRow.badge`；按 Kit 标签画（tone 的 `*Text` 字色、6% 底色、caption 字号、单行），未知 tone 按 neutral；条目顺序为编号、头像、名字、「我」、徽标、正文。
  - 多选上限：`PluginChoicesBlock.maxSelections` 与 `cap`；选满后草稿以外的选项禁用（`flareDimmed` 半透明，不可点），已选可取消，上限调低后只能减到上限内才能提交，单选不受影响；页脚以「最多选 n 项」开头；卡片、详情与页面一致。
  - `FilterTabs` 新增 `enabled`（禁用时半透明、不接受点击）与 `label`（标签列表的读屏名）；每个标签是 Tab 角色并读出选中状态。胶囊保持原尺寸，放在至少 `FlareSizes.touchTarget` 见方、居中的格子里接收点击，按压反馈仍画在胶囊上；行的版面因此增高到触达区。
  - 页面刷新结束（`refreshing` 由真变假）也释放已请求的游标，刷新回第一页后同一游标可以再请求（rules.pagePaging）。
  - `PluginActionPayload` 新增 `row`；查看详情键在带 rows 块的视图上不画。
  - `FlareStrings` 新增 `pluginViewMaxSelections`、`pluginViewAll`、`pluginViewEmpty`（中文默认，键名与 `strings/en.json` 一致）。
  - 测试：新增 `PluginPageVectorsTest`（pageViews、pageActions、pagePaging、pageFilters、filterInputs），`PluginViewVectorsTest` 读 entries-badges、poll-max-selections 三例与 maxSelections 段；androidTest 新增 `PluginPageInteractionTest`。

- 第八轮：消息表面与元信息、回执投影、插件协议 v2、红包第五版（docs/design/message-surface-and-meta.md、red-packet-v5-roles-and-wallet.md §1–§3、poll-v2-permissions-anonymity.md §6、plugin-platform-v2-trust-lifecycle-admin.md §4）：
  - 消息表面：新增 `FlareMessageSurface`（bubble / bareMedia / card / centered）与纯函数 `flareMessageSurface`、`flareMessageContentType`（按 `spec/message-surface-vectors.json`）。`MessageBubble` 新增 `surface`；card 表面不画气泡底色、边框、内边距、尾角和阴影，内容组件的外壳就是表面：插件卡片、红包、位置、名片、链接、旧投票、任务、日程、公告、小程序、合并转发与话题都是卡片，引用画在外壳内顶部（`PluginView` 新增 `quote` 插槽，卡片行自动传入）。**破坏性**：`FlareContentScope` 的 `bareTypes` 换成 `surfaces: Map<String, FlareMessageSurface>`（按 `contentType:subtype`、内容键、类型查找；custom 与插件内容默认就是 card，不必登记）；删除 `isBareMedia`、`messageBubbleChromeless`、`flareContentBare`。`FlareGenericContent` 新增 `subtype`，`custom.<subtype>` 的线上类型名同样识别。
  - 元信息：新增 `FlareMessageMetaPlacement`（inline / bubbleFooter / below / none）、`flareMessageMetaPlacement`、`flareMessageMetaTone`、`flareMessageRetryControl`（按 `spec/message-meta-placement-vectors.json`）。文本气泡的时间与回执跟在最后一行行尾，放不下时降为气泡内单独一行；裸媒体与卡片放在表面下方 `spacing.xs`、靠尾侧、默认色板，失败时显示「发送失败，重试」文字键。失败重试（文字键与气泡内图标）命中区都不小于 `touchTarget`，气泡失败时保留红边。`MessageMeta` 新增 `placement`、`outgoing`、`readSummary`、`onReadReceiptOpen`，去掉 `tint`。
  - 回执：**破坏性**：`FlareMessageDeliveryStatus` 收为五态（去掉 `Delivered`、`Retrying`），`FlareMessageLifecycle.visualStatus` 的已送达投影为 `Sent`。新增 `FlareMessageReadSummary`、`flareMessageReceiptPresentation`、`flareMessageAccessibilityLabel`（按 `spec/message-receipt-vectors.json`）；`FlareMessageData` 新增 `readSummary`，群聊本人消息显示「N 人未读 / 全部已读」，`MessageBubble` / `MessageList` 新增 `onReadReceiptOpen`（消息的核心 id）。减少动态时发送中的转圈静止。
  - 分组：`MessageRowPresentation` 新增 `tail`；新增 `FlareMessageGroupingItem`，分组在居中行（系统、撤回、删除）和卡片与其他表面切换处断开（按 `spec/message-grouping-vectors.json`）；`FlareTimeFormat.timelineDayKind` 与 `FlareTimelineDayKind` 给出日期胶囊的档位。
  - 行为补齐：气泡头像加载 `senderAvatarUrl`，`MessageBubble` / `MessageList` 新增 `onAvatarTap`；气泡最大宽按时间线窗格宽计算（不再按屏宽）；时间不再跟设备：新增 `LocalFlareLocale` 与 `flareLocale()`，**破坏性**：`FlareTimeFormat.messageTime` / `conversationTime` / `timelineDateLabel` 的 `locale` 不再有 `Locale.getDefault()` 默认值，`FlareMessageData.timeLabel` 为空时 Kit 按 Kit locale 写 `sentAtMs` 的时钟；无气泡消息被定位时也画高亮环；图片加载失败显示占位并可点击重试；已删除消息渲染为居中「消息已删除」；地址缺失的图片和视频画加载 / 失败占位而不是「不支持的消息类型」；文件大小单位走 `fileSize*` 文案与 Kit locale 的小数点。
  - 多选：`MessageContentView` 新增 `selectionMode`，`FlareContentContext` 新增 `selectionMode`、`surface`、`quote`；多选时内容里的键、选项、链接和媒体都不响应，点行任意处切换选中。
  - 读屏：消息行合并为一个读屏单元（发送者、内容摘要、时间、状态或已读摘要），带自定义动作：回复（列表有 `onSwipeReply` 时）、打开菜单（`onMessageLongPress`）、失败时重试。
  - 插件视图 v2：`PluginViewModel` 新增 `menuActions`、`unavailableReason`（`PluginUnavailableReason` 七种）；`PluginEntry` 新增 `group`（`PluginEntryGroup`），`PluginEntriesBlock` 新增 `grouped`。`PluginView` 新增 `displayName`、`viewerId`、`quote`：标题行末尾 ⋯ 键打开 Kit `ActionMenu`（内嵌时作为按钮排在动作之后），分组名单插组头「选项 · N 票 · P%」、`numbered: false` 不编号、当前用户行带「我」，不可用原因前置 `displayName`，`unbound_copy` 只读并以一行说明收尾。`PluginDetailSheet` 新增 `viewerId`。
  - 新增 `FlarePluginPage`：插件 `page` 贡献的全屏页面宿主（钱包等），Kit Screen、返回、触屏下拉刷新 / 指针设备刷新键、首次加载与失败重试、内嵌 `PluginView`、按游标「加载更多」。
  - 红包第五版：**破坏性**：`FlareRedPacketState` 换成 `FlareRedPacketCardState`（unopened / viewable / claimed / finished / expired / refunded），由 `flareRedPacketCardState(status, claimedByMe, tapAction)` 从公开层与本人层得出（新增 `FlareRedPacketStatus`、`FlareRedPacketTapAction`）；`RedPacketCard` 去掉 `amount` 与 `kindLabel`，新增 `kind`（拼手气、专属角标）与 `recipientName`（「给 某某」），卡片从不显示金额。`RedPacketOpenSheet` 新增 `canViewDetails`，notEligible 永远不给「查看领取详情」。`RedPacketDetail` 改为按 `details: FlareRedPacketDetailsView`（`FlareRedPacketViewerRole`）与 `designatedName` 绘制，`FlareRedPacketClaim` 改为 `amountMinor`、`claimedAtMs`；新增 `flareRedPacketAmountText`、`flareRedPacketMoney`（最小单位字符串加 `currencyExponent`，整数运算）。
  - `FlareStrings` 新增 34 个字段（中文默认，键名与 `strings/en.json` 一致）；删除 `packetClaimed`；`packetTapToClaim` 改为「领取红包」，`packetExpiredNotice` 改为「红包已过期」。
  - 测试：新增 `MessageSurfaceVectorsTest`、`MessageGroupingVectorsTest`（读四份新向量），`PluginViewVectorsTest`、`RedPacketComponentsTest` 读追加 / 重写段；androidTest 新增 `MessageSurfaceInteractionTest`。

- 第七轮 Kit 小缺口（app 接线反馈）：
  - `ContactDetail` 新增 `primaryActionBusy`（参数末尾）：主按钮以 `CircularProgressIndicator` 代替图标并禁用，禁用色沿用原色；其他操作照常。纯函数 `contactDetailKeyBusy`。
  - `ContactPicker` 新增 `sending`（参数末尾）：单选时被点的那一行高亮转圈（semantics selected），多选时确认键转圈（`Button` loading）；各行与确认键不接受点击（semantics disabled），取消、搜索和标签照常。清掉后单选忘掉那一行，多选保留已选供重发。纯函数 `contactPickerRowPending`；androidTest `ContactSendingInteractionTest`。
  - 新增顶层函数 `flareLocationWebMapUrl(location, provider)`（宿主自己打开地点时的网页地图地址：参数优先、其次内容的 provider；缺坐标、超范围或线上的 0, 0 返回 null）和 `flareLocationProviderFrom(value)`（`chat.location` 配置值转服务商，未知回落 Osm；`FlareLocationProvider.fromWire` 仍是精确、可空的读法）。规则见 `spec/location-vectors.json` 的 `webMapUrl`、`providerFrom`。
- 第六轮验收修复（插件卡片详情入口、inset）：
  - `PluginView` 卡片级「查看详情」：`view.detail` 为真、没有 entries 块在显示「查看全部」、可用、非 embedded，并且传了 `onOpenDetail` 时，在动作区下方画整宽的 Quiet 文字按钮（Sm，`pluginViewDetail`），点击调用 `onOpenDetail`；`busy` / `busyActionId` 时禁用。
  - `PluginViewInset` 新增 `SheetTop`（上 md、左右 lg、下不留），用于 PluginForm 上方的前言。`inset` 现在作用于所有状态：embedded 的内容（含不可用态）和宿主留在面板里的卡片外壳（外壳之外）。不可用的 embedded 视图把标题显示为一行次要文字。
  - `FlareStrings` 新增 `pluginViewDetail`（「查看详情」/ "View details"）。
- 第六轮 Kit 打磨（app 接线反馈）：
  - `PluginView` 新增 `settleToken`（宿主每完成一次动作加 1：没有 error 和 formErrors 时关闭已提交的表单、乐观选中保留到新视图；有 error 撤回选中；有 formErrors 表单留着；`busyActionId` 离开该动作仍作兜底，两者同时到达只结算一次）和 `inset`（`PluginViewInset`：None / Sheet，embedded 时按底部面板留白 md / lg / xl）。宿主信号合成一个值比较，同一帧里设上 error 并结算也能读到。
  - `PluginDetailSheet` 新增 `actionError`（内嵌视图的 error，不落到卡片上）、`formErrors`、`members`、`settleToken`，原样交给内嵌 `PluginView`；视图带 `nextCursor` 时底部画「加载更多」（`myInviteLoadMore`），点了回调 `onLoadMore(cursor)`，`loadingMore` 时转圈，Kit 不合并分页。`PluginViewModel` 新增 `nextCursor`（空白视为最后一页）。
  - `BottomSheet` 新增 `fill`：面板占满上限，内容撑满剩余高度并自己滚动。内容调用 `FlareSheetOwnHeader()` 声明自带标题后，fill 的面板不画可见标题，title 只作可及名称；`LocationPicker`、`ContactPicker` 已声明，并在 fill 面板里让列表撑满。
  - `LocationPicker` 新增 `sending`（发送键转圈、不收第二次点击，状态多一个 `Sending`）和 `ensurePermission`（每次定位前先等它，返回 true 后才开始计 `locateTimeoutMs`，false 或抛错直接 Denied）；**行为变化**：`previewUrl` 的宽高由 dp 改为设备像素（dp × density，限 1–2 倍，四舍五入，`FlareLocationFormat.previewPixels`）。
  - `FriendRequest` 新增 `source`，在验证消息下面单独一行显示。`ContactDetail` 新增 `primaryActionLabel` 与 `onPrimaryAction`：两者都有时排在操作行首位作主键（person-add），「发消息」改为次要键。
  - 「+」面板默认集去掉 poll，为 image、camera、video、file、voice、location、card；投票由插件提供，`PollComposer`、`VoteMessage` 保留。
- 插件视图 v2：`PluginView` 渲染核心 SDK `ResolvedPluginView` 的展示块——text（`maxLines` 截断加展开）、fields、choices（单选点一项即提交；多选先勾草稿再点提交键，键名取块持有的动作；显示结果时每项一条票数条、百分比和票数，「我选的」打勾；已结束只读）、entries（序号、名字、文本，`more` 时「查看全部（n）」触发 `onOpenDetail`）、people（每组一行头像叠加、标签、计数，按 tone 着色）、status、progress、time（设备时区格式化，倒计时不到 1 小时每秒刷新，否则每分钟）、divider、note；渲染事实按 `spec/plugin-view-vectors.json`。外壳与 Kit 业务卡片一致（`componentRichCardWidth`、圆角 lg、细边框、卡片阴影），标题行带图标位，`embedded` 去掉外壳和标题行。底部动作按 style 用主键、危险键或次要键；有 `confirm` 先弹 `DangerConfirm`，有 `form` 在 Kit 底部面板里收集 `PluginForm`，`busyActionId` 清空且没有 `formErrors`、`error` 时面板关闭。choices 提交后 Kit 先乐观标记，`error` 变为非空（或 `busyActionId` 带着错误清空）时撤回，新 view 到达即结算。`resolveUser`（suspend）解析 people 与 entries 的名字和头像，取不到时显示首字母、名字取 userId 末 4 位。新增模型 `PluginBlock` 及各块类型、`PluginInput`、`PluginInputKind`、`PluginInputChoice`、`PluginFormError`、`PluginFormIssue`、`PluginUser`、`PluginMember`、`PluginActionPayload`、`PluginActionStyle`、`PluginTone`、`PluginTextStyle`，`PluginBlock` 为 sealed interface；`PluginViewAction` 新增 `style`、`confirm`、`form`，`PluginViewModel` 新增 `blocks`、`inputs`、`detail`（`PluginViewModel.fromJson` 读核心的 JSON，v1 卡片照旧，不认识的块、输入和键跳过；`PluginActionPayload.toJson()` 与 `PluginFormError.listFromJson` 供宿主与核心 SDK 往返）。**破坏性**：`PluginView` 的 `onAction` 由 `(String) -> Unit` 改为 `(String, PluginActionPayload) -> Unit`；另新增 `icon`、`busyActionId`、`error`、`embedded`、`resolveUser`、`members`、`formErrors`、`onOpenDetail`。
- 新增 `PluginForm`：text、textarea 带「n/max」计数，number，toggle（`Switch`），select（`RadioGroup`），datetime（Kit 的 `DatePicker` 加 `TimePicker`，设备时区），options（可增删行，条数在 [max(min, 1), max] 内），members（`ContactPicker`，max 为 1 时单选）。客户端只查必填和长度（去首尾空白、按 Unicode 码点），改过的项即时提示、点提交后全部提示；宿主 `errors` 优先显示到该项被修改；`onSubmit` 交出清洗后的值。
- 新增 `PluginDetailSheet`（宿主在面板打开时组合它，内部组合 Kit `BottomSheet`，标题取视图标题、否则取 `title`，关闭回调 `onClose`）：loading 转圈（读屏名 `loading`），error 显示宿主文案加重试键，其余为 embedded `PluginView`。
- 位置：provider 为 osm 且静态图已经显示时，`LocationMessage` 与 `LocationPicker` 在图片右下角画 OpenStreetMap 署名（`locationOsmAttribution`，2xs 次要文字、72% 不透明底、最宽 60%）；手绘底图、地图不可用和 amap 时不画。`LocationPicker` 新增 `provider`（默认 osm）。
- `FlareStrings` 新增 19 个字段（`pluginView*`、`pluginForm*`、`locationOsmAttribution`、`loading`、`selectDate`、`selectTime`），英文预设同步生成。
- 图标 `locate`（注册表最后一项，共 108 个，`Icons.Outlined.MyLocation`）：选点面板「定位到当前位置」键的准星，与地图钉 `location` 区分。
- 位置：新增 `LocationPicker`（选点面板内容：地图加中心点与「定位到当前」键、搜索框、首行为当前位置的地点列表、发送键），定位、逆地址、周边搜索和地图图片都由宿主传入的 suspend 函数完成，Kit 管 Locating / Located / Denied / Searching / NoResults / MapUnavailable 六种状态（`FlareLocationPickerStatus`）；传入 `initialLocation` 时首帧即显示上次位置，否则显示骨架；`locateTimeoutMs`（默认 5000）内没有定位结果按 Denied 处理，宿主用 `suspendCoroutine` 包的定位回调不响应取消也不会拖住面板。新增数据类型 `FlareLocationProvider`、`FlareLocationCoordinate`、`FlareLocationAddress`、`FlareLocationPlace` 与共享规则 `FlareLocationFormat`（默认链接、无地图时的坐标文字、距离，按 `spec/location-vectors.json`；数字一律按 `Locale.ROOT` 书写）。
- **破坏性**：`LocationMessage` 的 `mapImage` 改名为 `snapshotUrl`，新增 `latitude`、`longitude`、`provider`；没有静态图（或加载中、加载失败）时画地图底纹加中心点；宿主不传 `onOpen` 时经 `LocalUriHandler` 打开 `geo:` 链接，没有地图应用接时退到服务商的网页地图，坐标无效且无 `onOpen` 时不可点。`FlareLocationContent` 新增 `latitude`、`longitude`、`snapshotUrl`、`provider`（均可选，原构造方式不变）。
- 名片：新增 `ContactPicker`（分组标签、搜索、懒加载列表、空态，自己的行带「（我）」；单选点一行即回调，多选由「确定」回调，按勾选顺序）与 `FlareContactPickerEntry`、`FlareContactPickerGroup`。**破坏性**：`ContactMessage` 新增 `userId`，`onOpen` 改为 `(String) -> Unit`，回传名片里的用户 ID；`FlareCardContent` 新增 `userId`。
- `MessageList`、`MessageBubble`、`MessageContentView` 新增 `onCardOpen`（消息、用户 ID）与 `onLocationOpen`（消息、位置），优先于 `onMediaAction`；名片没有用户 ID 时 `onCardOpen` 不会让它可点。
- 「+」面板默认集改为 image、camera、video、file、voice、location、card、poll（图标 image / camera / video / file / mic / location / card / poll），camera 用 `actionCamera`，location 用 `actionLocation`。
- `FlareStrings` 新增位置与选择联系人的 16 个字段（`location*`、`contactPicker*`），英文预设同步生成。
- 输入栏：`FlareComposerCapabilities` 新增 `availableToolIds`（`emoji` / `mention` / `voice` / `image` / `richText` / `attachments`，`attachments` 即「+」键），不传时全部可用，语义与 Flutter 一致；收回某个键时同时关掉它打开的面板或模式，草稿保留。
- 「格式」键改为 Kit 自绘的「T」（Lucide `Type` 几何，`FlareRichTextGlyph`），不再是 Material `TextFormat` 的带下划线 A。
- 「+」面板默认集改为 image、video、file、voice、card、poll（图标 image / video / file / mic / card / poll），去掉 location，`contact` 改为 `card`。**破坏性**：`FlareComposerAction.label` 改为可空，不传时按 id 取 Kit 文案（`resolvedLabel(strings)`，新增 `FlareStrings.actionVideo`）；新增可选 `kind`（`FlareComposerActionKind`：Feature / Plugin）。
- 图标 `plugin`（注册表最后一项，共 107 个，`Icons.Outlined.Extension`）：「+」面板里图标名不在注册表里的项（插件项和内置项都算）画它（`resolvedIcon`），不再画兜底问号。
- `Composer` 的「+」面板里点 voice 项时，由 Kit 自己收起面板并切到录音模式，与工具条的语音键用同一个录音器，行为同 Flutter；录音仍经 `onVoiceSend` 交给宿主。没有录音器（未开 `enableVoice`、没有 `onVoiceSend` 或宿主不提供 voice 键）时照旧回调 `onAction`。
- 修复：控件从不可用变为可用时底色消失（如表单填好后「塞钱进红包」只剩白字）。`Modifier.alpha(1f)` 会去掉自己的图层，图层去掉后排在它前面的底色不再绘制；`Button`、`IconButton` 及其余 24 处按状态变暗的控件改用常驻图层 `flareDimmed`。`Button` 的纯色底不再用同色两段渐变。
- 自定义内容渲染器：`FlareContentScope(builders, bareTypes)` 列出的类型不画气泡（保留头像、昵称、时间、多选和长按菜单）；`FlareContentContext` 新增 `messageId`（服务端 ID，没有时用 client ID）与 `conversationId`（来自 `MessageList` 的 `conversationId`）；`MessageContentView` 同名参数可选。
- 图标 `red-packet`（注册表最后一项，共 106 个），Kit 自绘的线性小信封。
- `RedPacketDetail` 新增可选 `title`、`onBack`（自带红色标题栏，系统返回同样回调）；`RedPacketComposer` 新增 `locked`；`SegmentedControl` 新增可选 `accent`。
- 红包组件族：新增 `RedPacketOpenSheet`、`RedPacketDetail`、`RedPacketComposer`、`RedPacketPayConfirm`，四端合同见 `docs/plugin-components.md`。
- **破坏性**：`RedPacketCard` 去掉 `opened` / `finished`，改为 `state`（`FlareRedPacketState`：unopened / claimed / finished / expired）并新增 `kindLabel`；已领完、已过期的卡片仍可点击（查看详情），只有 `busy` / `disabled` 不可点。
- `SegmentedControl` 的命中区覆盖整条轨道高度，轨道高度提到触控目标（48）。
- `Button(block = true)` 的文字与图标在整宽内居中，与 iOS、Web 一致。
- 图片、视频、文件保存后，下载键变成「在文件夹中显示」；宿主发现文件被删后传回 idle，键回到下载。收发两侧的消息时间都在右侧。详见仓库根 CHANGELOG。
- `FileMessage` 新增 `downloadState` / `onReveal`，没有 `onDownload` 时不再画装饰性的下载图标；`ImagePreview` / `VideoPlayer` 新增 `saved` / `onReveal`；列表、气泡、分发器新增 `onMediaReveal`；`VideoMessage.duration` 默认空串（不画角标）。
- `ForwardPicker` 在有界高度的宿主里（`BottomSheet`、`Modal`、`FlareScreen(scroll = false)`）让目标列表让出高度，标题、搜索框与「发送」栏始终完整可见——小屏竖屏、横屏、搜索框弹出键盘时不再丢失发送键；无界宿主里列表仍是 300dp。放在 kit 浮层上时去掉自带的 340dp 卡片与关闭键，由浮层提供表面、遮罩与返回关闭。

## 1.0.10

### Android

- `TextMessage` 新增 `trailing` 插槽：气泡内、贴着正文末尾的一小块位置。
  用途是送达状态（单勾=已送达、双勾=已读）—— 状态属于气泡内部。

  为什么要插槽而不是让宿主叠加：叠加也能放对位置，但正文一长就会压住末行文字；
  插槽会为它**留出空间**。文本气泡的绘制在 kit 这一侧，宿主没法自己留。

  纯新增可选参数，既有调用不受影响。

- **许可证由 MIT 变更为 Apache-2.0。** 已发布的 1.0.5 及更早版本仍按 MIT 授权，
  本次变更仅对之后的版本生效。Apache-2.0 含显式专利授权条款。

## 1.0.5

- 修正 README 引入说明：改为从公共仓库/GitHub 引入，不再是 monorepo 本地路径。
- 修正 README 内指向仓库其他目录的相对链接（发布产物中为死链），改为 GitHub 绝对地址。

## 1.0.4

首个公开发布版本。

### 组件文案可覆盖
- 组件不再把界面语言写死：默认文案为中文，宿主可整体覆盖。
- Android 新增 `FlareStrings` 环境值，用 `CompositionLocalProvider` 一处覆盖；
  取值方式与 `flareColors()` 一致，组件内无需逐层传参。
- Flutter 沿用该端既有惯例（构造默认值 / `?? 回退` / `labels`），补齐尚未可覆盖的项。
- 两端日期组件的星期名与年月标题改用各自框架的区域数据，随宿主 locale 自动切换。
