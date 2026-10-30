## 未发布

- 打开着的指针菜单跟随快照、气泡色板函数、金样按平台分目录：
  - `FlareActionMenu.show` 新增 `updates`（`ValueListenable<List<FlareActionItem>>`）：菜单打开期间，每来一组新条目就原地替换。菜单不关闭、锚定的一边不动，键盘焦点留在仍存在的那一项上；可见条目为空时按关闭处理。不传时与原来一样，只读打开那一刻的条目。
  - `FlareMessageList` 的指针菜单打开期间，宿主带着新快照重建列表，菜单就地更新：「正在读取…」换成条目，核心不再允许的动作移除，宿主停用的条目置灰。
  - 新增 `FlareMessageBubbleTone`、`flareMessageBubbleTone`、`FlareMessageBubblePalette`、`flareMessageBubblePalette`（`spec/message-surface-vectors.json` `palette`），气泡按它取底色、前景与边。外观不变。
  - 金样按 `Platform.operatingSystem` 分目录（`test/goldens/baselines/macos/`、`linux/`），Linux 那套由 CI 镜像生成；误入库的 `test/goldens/failures/` 已删除并忽略。

- 批量工具条转发可用性、合并转发条目色板、失败气泡前景：
  - `FlareMessageBatchToolbar` 新增 `unforwardableIds`（`Set<String>`，默认空）：逐条转发至少 1 个、合并转发至少 2 个可转发 id，这两个动作只上报可转发 id；有不可转发项时计数下方显示 `messageBatchUnforwardable`（`messageBatchUnforwardableOne` 为英文单数，`FlareStrings.messageBatchUnforwardableCount`）。新增 `messageBatchActionIds`、`messageBatchUnforwardableCount`、`FlareMessageBatchAction.forwards`，`messageBatchActionsAvailable` 新增可选参数（`spec/message-batch-vectors.json` 的 forward）。
  - 合并转发只有一条时内联画的条目按别人的消息画，不再用本人气泡的白色前景（`spec/message-forward-vectors.json` rules.palette）。
  - 气泡把自己的前景同时给到两侧的 `messageOutgoingForeground` / `messageIncomingForeground`：失败消息的文本与富文本改用失败前景，不再是失败浅底上的白字。

- 通话：新增 `FlareCallRecordCard` 与 `models/call_record.dart`（`FlareCallRecordScope`、`FlareCallRecordState`、`FlareCallEndReason`、`flareCallRecordStatus` 等，`spec/call-record-vectors.json`），`FlareStrings` 新增 `callRecord*`；`FlareCallView` 新增 `onMinimize`（传入才绘制收起按钮）。**破坏性**：`FlareGroupCallView.state` 由 `String` 改为 `FlareCallState`。
- 第八轮：消息表面与元信息、回执投影、红包第五版、插件协议 v2（docs/design/message-surface-and-meta.md、red-packet-v5-roles-and-wallet.md、poll-v2-permissions-anonymity.md §6、plugin-platform-v2-trust-lifecycle-admin.md §4）：
  - 新增 `models/message_surface.dart`：`FlareMessageSurface`（bubble / bareMedia / card / centered）与 `flareMessageSurface`、`flareMessageContentKey`、`flareMessageSurfaceInputOf`；`FlareMessageMetaPlacement` 与 `flareMessageMetaPlacement`；`FlareMessageReadSummary`、`flareMessageReceiptPresentation`、`flareMessageAccessibilityLabel`。规则读 `spec/message-surface-vectors.json`、`message-meta-placement-vectors.json`、`message-receipt-vectors.json`。
  - **破坏性**：`FlareContentScope.bareTypes` 与 `FlareContentRegistry.register(bare:)` 删除，改为 `surfaces` / `register(surface:)`，只为 Kit 不认识的内容键登记 `card` 或 `bareMedia`；custom 与全部插件卡片默认就是 card。builder 查找先完整键（`custom:<subtype>`）再 `custom`。
  - card 表面的消息不画任何气泡底、边框、内边距和尾角：`FlarePluginView`、`FlareRedPacketCard`、位置卡自己的外壳就是表面，名片、链接卡、旧投票、任务、日程、小程序、公告等内置卡片体放进新的 `FlareMessageCardShell`；引用回复经 `FlareCardQuote` 画在外壳内部顶部。卡片上的文字用中性色板，不再用发送方气泡色。
  - 元信息位置：文本跟在最后一行行尾（放不下时降为气泡内右下一行），其他气泡在气泡内右下，bareMedia 与 card 在表面下方尾侧、默认色板（`messageMetaForeground`），失败时显示「发送失败，重试」文字键。`FlareMessageMeta` 新增 `placement`、`readSummary`、`readTint`、`onReadReceiptOpen`。
  - **破坏性**：`FlareMessageDeliveryStatus` 只剩五态（去掉 `delivered`、`retrying`），生命周期投影里的送达显示为单勾。`FlareMessageData` 新增 `readSummary`（群聊本人消息「N 人未读 / 全部已读」，可点）与 `isDeleted`。失败气泡有红边与失败底色；重试图标、「发送失败，重试」与已读摘要的命中区不小于 `layout.touchTarget`（新组件 `FlareHitSlop` / `FlareHitSlopRegion`：不改布局，从所在消息行借位置；不抢其他控件的点按）。
  - **破坏性**：分组改为按表面：`flareMessageGroupPosition(items, index, breaksBefore:)`、`flareMessageRowPresentation(item:, …)` 读 `FlareTimelineItem`；新增 `flareTimelineRows` / `flareTimelineLayout` / `flareTimelineDateLabel`，`FlareMessageRowPresentation.tail`。撤回、删除、系统提示和 card 与其他表面的切换都断组，只有气泡画尾角（`spec/message-grouping-vectors.json`）。日期胶囊改用 `bgTertiary`，与时间线画布（`bgSecondary`）有色差。
  - `FlareMessageBubble`：新增 `surface`、`locale`、`onReply`、`onReadReceiptOpen`、`onContextMenu`；deleted 画居中「消息已删除」；气泡最大宽按窗格宽（行实际拿到的宽度）计算；桌面指针设备右键打开消息菜单（`onContextMenu`，没有时走 `onLongPress`），悬停显示表情、回复、更多工具条；多选态内容不响应，点整行切换选中；整行是一个读屏单元（发送者、内容摘要、时间、状态或已读摘要），自定义动作为回复、打开菜单、重试与已读详情。`FlareMessageList` 同步新增 `onReply`（缺省用 `onSwipeReply`）、`onReadReceiptOpen`、`onContextMenu`。
  - `FlareMessageContentView` 新增 `surface`、`failed`、`selectionMode`；`FlareContentContext` 新增 `selectionMode`、`surface`。图片：没有地址时显示加载中占位，加载失败显示失败占位，点按重试（`FlareImageMessage.failedKey`）；视频没有地址时不可播放。一条只有一个表情的富文本按表情处理（bareMedia）。
  - 插件视图：`FlarePluginViewModel.menuActions`（标题行末尾 ⋯ 键打开 Kit 动作菜单，embedded 时作为动作键排在后面）、`unavailableReason`（七种原因文案，前缀 `displayName`；`unbound_copy` 只读并以「副本，仅供查看」收尾）、entries 分组（`FlarePluginEntryGroup`，组头「选项 · N 票 · P%」）与 `viewerId` 的「我」标识。`FlarePluginView` 新增 `displayName`、`viewerId`，`FlarePluginDetailSheet` 新增 `viewerId`。新增纯函数 `flarePluginReasonLine`、`flarePluginUnavailableReasonText`、`flarePluginEntryGroupHeader`、`flarePluginReadOnly`。
  - 新增 `FlarePluginPage`：插件 page 贡献的全屏页面宿主（页头、返回、触屏下拉刷新、指针设备页头刷新键、同一游标只请求一次的加载更多），视图由内嵌 `FlarePluginView` 绘制。
  - `FlarePluginPage` 接页面数据与动作，**破坏性**：新增必填 `page: FlarePluginPageRef`，`view` 改为 `FlarePluginPageViewModel`（带 `data`），`onAction` 改为 `(actionId, FlarePluginPageActionPayload)`（`{page, data?, row?, selection?, formValues?}`，即 invokePageAction 的请求），删除 `onOpenDetail`。新增 `filters` 与 `onFilter(values)`：rows 块列出的 select 输入画成 `FlareFilterTabs`（「全部」在前，刷新或加载更多时禁用），宿主持有筛选值。不可用页面显示原因空态，只有 `catalog_unreachable` 带重试；有视图时刷新失败显示危险横幅。状态判断见 `flarePluginPageState`。规则读 `spec/plugin-view-vectors.json` 的 pageViews、pageActions、pagePaging、pageFilters。
  - 插件视图：解析 rows 块（`FlarePluginRowsBlock`），在页面上画成列表：同一 key 只画一次，徽标与第一格、其余单元格以「 · 」连接，行动作键带 `row: {key, input}`，确认与表单照常；没有行时显示 emptyText，否则「暂无数据」。entries 与 rows 的 `badge`（`FlarePluginBadge`）画成 Kit 标签，未知 tone 按 neutral。choices 的 `maxSelections`：选满后其余选项禁用，已选可取消，上限被调低时只能减，页脚以「最多选 n 项」开头；卡片、详情、页面一致。`FlarePluginActionPayload` 新增 `row`。新增纯函数 `flarePluginBadgeTone`、`flarePluginChoiceCap`、`flarePluginChoiceCapped`、`flarePluginWithinCap`、`flarePluginChoiceCapHint`、`flarePluginFilterInputs`、`flarePluginRowsOnce`、`flarePluginRowLines`、`flarePluginPageFilters`、`flarePluginPageFilterValues`、`flarePluginPagePayload`、`flarePluginPageUnavailableText`。`flarePluginShowsDetailKey` 对带 rows 块的视图不再给详情键。
  - `FlareFilterTabs` 新增 `enabled`（默认 true）：为假时整行降到禁用透明度、点按无效；每个标签带 button / selected / enabled 读屏语义。filled 胶囊保持原尺寸，放在至少 `FlareSizes.touchTarget` 见方、居中的格子里接收点击，行的版面因此增高到触达区；quiet 条保持紧凑高度。
  - `FlarePluginPage` 刷新结束（`refreshing` 由真变假）也释放已请求的游标，刷新回第一页后同一游标可以再请求（rules.pagePaging）；`FlarePluginPageCursor` 新增 `release()`。
  - `FlareStrings` 新增 `pluginViewMaxSelections`（「最多选 {n} 项」）、`pluginViewAll`（「全部」）、`pluginViewEmpty`（「暂无数据」）。
  - 红包第五版，**破坏性**：删除 `FlareRedPacketState`，改为 `FlareRedPacketCardState`（unopened、viewable、claimed、finished、expired、refunded）与 `flareRedPacketCardState(status, claimedByMe, tapAction)`；`FlareRedPacketCard` 删除 `kindLabel`、`amount`，新增 `kind`（拼手气、专属角标）与 `recipientName`（「给 某某」），卡片从不显示金额。`FlareRedPacketOpenSheet` 新增 `canViewDetails`（notEligible 永不给详情键）。`FlareRedPacketDetail` 改为按 `details: FlareRedPacketDetailsView`（viewerRole 裁剪后的结果）渲染，新增 `designatedName`、`nowMs`；`FlareRedPacketClaim` 改为 `amountMinor` + `claimedAtMs`。金额由 `flareRedPacketMoney(minor, exponent, currency)` 用整数字符串运算格式化。规则读 `spec/red-packet-vectors.json`。
  - `FlareStrings`：新增 `messageReadSummaryUnread`、`messageReadSummaryAllRead`、`messageSendFailedRetry`、`messageDeleted`、`packetView`、`packetRefunded`、`packetBadgeLucky`、`packetBadgeExclusive`、`packetForRecipient`、`packetNotEligibleName`、`packetDeposited`、`packetSummarySender`、`packetSummaryCompleted`、`packetSummaryCount`、`packetRefundAt`、`packetRefundedNote`、`packetDuration*`、`pluginViewMore`、`pluginViewMe`、`pluginViewUnavailable*`、`pluginPageRefresh`；`packetTapToClaim` 改为「领取红包」，`packetExpiredNotice` 改为「红包已过期」，删除 `packetClaimed`。
  - **破坏性** `FlareReadReceiptSheet`：两栏各自分页与三态（`spec/read-receipt-vectors.json`）。新增 `readCount` / `unreadCount`（标签数字只取宿主的摘要人数，缺省不带数字，永不取列表长度）、`state`（`FlareReadReceiptState` ready / loading / error / unavailable）、`readHasMore` / `unreadHasMore`、`loadingMore` / `loadMoreFailed`（`FlareReadReceiptColumn`）、`initialTab`、`onLoadMore(column)`、`onRetry`。名单末尾按栏画转圈（不可点）、「加载失败，点按重试」或「加载更多」；切换标签不发事件。宽度随容器：单独放置时画卡片外壳、最宽 320、名单区最高 320；在 Kit 面板里不画外壳、占满面宽，并实现 `FlareSheetOwnHeader`（用 `FlareBottomSheet.show(fill: true)` 打开，标题只画一次）。删除 `title`、`readTabText`、`unreadTabText`、`readEmptyText`、`unreadEmptyText`，文案全部来自 `FlareStrings`（标题 `readReceipt`，标签 `readTab` / `unreadTab` 或无数字时 `readReceiptRead` / `readReceiptUnread`，空态 `noReadersYet` / `everyoneHasRead`）。纯函数 `flareReadReceiptLayout`。
  - 新增已读名单的分页状态持有者 `FlareReadReceiptListState`（`ChangeNotifier`，与 Vue `useFlareReadReceiptList`、Compose `FlareReadReceiptListState` 同义，`spec/read-receipt-list-vectors.json`）：宿主只给一个取页函数 `FlareReadReceiptPageLoader(column, cursor)`（名字由宿主取，没有名单时返回 null，其他失败抛错）；`open(key)` 同时读两栏第一页（任一为 null → unavailable，任一失败 → error），`loadMore(column)` 只在 ready、该栏有下一页且没在读时取下一页（已列出的人只留一次），`retry()` 重读两栏第一页，换 key 或关闭时丢掉在途的结果。模型 `FlareReadReceiptPages`、`FlareReadReceiptMembers`。`FlareReadReceiptSheet.list(list:, readCount:, unreadCount:, …)` 直接画持有者的名单，加载更多与重试交给它，标签数字仍取宿主的摘要。
  - `flareStringsEnglish` 补齐全部函数式文案（计数、名字、年月等 49 个字段）的英文：手写在 `tokens/flare_strings_english_formats.dart`（生成文件的 part），`strings/build.mjs` 把其中每个 `_<field>English` 接进生成的预设；计数按英文复数（1 取 one），`yearMonth` 用英文月名，`newMessages(0)` 为 "New messages"，`quotedMessage` 无名字时 "Quoted: …"。用例表 `strings/en-formats.json` 的共有字段加 flutter，Flutter 独有的字段（`ratingStars`、`permission*Description`、`quotedMessage`、`groupDetail*`、`conversationBatchToolbar*`、`storageUsageFileCount`）补了用例；测试要求每个函数式字段都有中英不同的用例。
  - `FlareContentContext` 新增 `senderId`；`senderName` 去首尾空白、空串为 null，不回落到 id。`FlareMessageContentView` 新增 `senderId`，`FlareMessageBubble` 传入消息的 `senderId`。
  - `FlareRedPacketOpenState` 新增 `refunded`（排在 `expired` 之后）：不画「開」，详情键由 `canViewDetails` 决定，默认文案 `packetRefundedNotice`「红包已退回」，宿主 `message` 可覆盖。
  - `FlareRedPacketComposer` 新增 `currencyExponent`（默认 2，取整后夹在 0..6）：金额最多保留这么多位小数（0 时只收整数、纯数字键盘），占位为 `flareRedPacketAmountPlaceholder`（「0」/「0.00」/「0.000」）。`flareRedPacketAmount(raw, [exponent])`、`FlareRedPacketAmountFormatter(exponent:)`；新增 `flareRedPacketAmountMinor(text, exponent)`，用整数字符串运算把输入换成最小单位，不是金额时为 null；`flareRedPacketExponent`。
  - 新增「我」页菜单映射 `flareMeMenuSections(menu, labels:, summaries:, strings:)` 与 `FlareMeMenu` / `FlareMeMenuItem`（`fromJson` 读社交 SDK 的 `features.meMenu`）：除设置外按 SDK 顺序成第一组，设置单独成组在最后；内置项文案 `meMenuMoments` / `Reports` / `Invite` / `Settings`，插件项标题为空时 `meMenuPluginFallback`；`summaries[id]` 去空白后作副标题，插件项是它的摘要，内置项是宿主给自己页面的说明（`spec/me-menu-vectors.json`）。
  - 图标注册表在 `locate` 之后新增 `wallet`（`Icons.account_balance_wallet_outlined`），共 109 个。新增 `flareIconNameOrFallback(name)`：去空白，注册表里的名字原样，空名为 null（不画），其他名字画 `plugin` 字形，调试构建对每个名字告警一次；`FlareIcon`、设置行与 me 菜单都经它，未知名字不再画问号。
  - 新增合并转发记录：`FlareForwardContent`（`title`、`mode`：`FlareForwardMode` unspecified / single / merged、`items`）与 `FlareForwardItem`（`senderName`、`sentAtMs`、`plainText`、`content`），表面为 card，`FlareMessageContentView` 画成 `FlareForwardMessage`：没有条目时一行「暂无转发内容」，一条且不是 merged 时直接画那一条，其余画记录卡片（标题、「共 N 条消息」、前 3 条「发送者: 摘要」、「还有 N 条消息…」、「点击查看详情」，读屏名「标题，副标题」），点卡片在 Kit 侧边抽屉里列出全部条目（首字头像、发送者、时间、摘要，非文本内容再嵌一份渲染）；多选时不可点。纯函数 `flareForwardRecordView`、`flareForwardSender`、`flareForwardSenderInitial`（名字首字大写，无名为「?」）、`flareForwardPreviewLine`（`plainText` 按文本摘要读：去空白、Markdown 转纯文本、表情包键按语言）、`flareForwardItemContent`；一行摘要按条数（`spec/message-forward-vectors.json`）。`FlareTimeFormat.dateTime`：同一天只写时钟，否则月日加时钟。
  - 复数：新增 `flarePluralIsOne(count, locale)`（按 CLDR 基数规则表：无 one、n = 1、n ∈ {0, 1}、n % 10 = 1 且 n % 100 ≠ 11）、`flarePlural(count, one, other, locale)` 与 `flareCopyLocaleOf(context)`；`FlareStrings` 的 `pluginViewVotesCount`、`myInviteCountOnlyCount`、`forwardRecordTotalCount`、`forwardRecordMoreCount` 按 locale 选 `…One` 形态（`spec/plural-vectors.json`）。投票选项的票数、分组组头与邀请人数改走复数选择；`flarePluginEntryGroupHeader` 新增 `locale`。
  - 投票卡片页脚不再画 choices 的 `total`（它只是百分比的分母，Kit 分不出人数还是票数）：页脚为「最多选 n 项」与「已结束」，每个选项的「N 票」不变。
  - **破坏性** `FlareMessageList`：删除 `onContextMenu`，新增 `menu: FlareMessageMenuSource`（`availability(message)` 同步读宿主的可用性快照、`prefetch(ids)`、`hiddenActions`、按消息求值的 `extraActions(message)`（如举报只给别人的消息）、`perform(message, actionId)`）。长按面板与指针设备右键菜单用同一份条目（新增 `messageMenuEntries`，`FlareMessageActionSheet` 也改用它）；行进入视口时合并调用一次 `prefetch`；没有快照时右键菜单只有一条不可点的「正在读取…」并预读，长按等宿主读到快照后再打开面板；面板里的表情回应交给 `onReact`。`FlareMessageMenuSource.pointerIdiom(context)` 公开指针菜单的判断，`flareMessagePointerMenuItems` 公开条目到菜单项的映射。
  - `FlareStrings` 新增 `readReceiptRead`、`readReceiptUnread`、`readReceiptLoadFailed`、`readReceiptUnavailable`、`readReceiptLoadMore`、`readReceiptLoadMoreFailed`、`packetRefundedNotice`、`meMenuMoments`、`meMenuReports`、`meMenuInvite`、`meMenuSettings`、`meMenuPluginFallback`、`forwardRecordTitle`、`forwardRecordTotal`（`…One`）、`forwardRecordMore`（`…One`）、`forwardRecordViewDetails`、`forwardRecordUnknownSender`、`forwardRecordEmpty`、`forwardRecordCountSuffix`、`forwardRecordCardLabel`、`pluginViewVotesOne`、`myInviteCountOnlyOne`、`messageMenuLoading`；删除已不用的 `readReceiptSheetReadEmpty`、`readReceiptSheetUnreadEmpty`（空态改用 `noReadersYet` / `everyoneHasRead`，与另三端同文案）。

- 第七轮 Kit 小缺口（app 接线反馈）：
  - `FlareBottomSheet.show` 新增 `listenable`：每次通知都重新运行 `builder`，内容里随宿主状态变化的参数（如选择器的 `sending`）随之更新，宿主不必再自己包 `ValueListenableBuilder`；fill 模式下每次重建都重新判断内容是否 `FlareSheetOwnHeader`，Modal 形态同样生效。同一个 notifier 传给 `busy` 即可在发送期间锁住面板。
  - `FlareContactDetail` 新增 `primaryActionBusy`：主按钮以转圈代替图标、不接受点击 / 按键 / 焦点，读作不可用的按钮，颜色不变；其他操作照常。
  - `FlareContactPicker` 新增 `sending`（与 `FlareLocationPicker.sending` 同义）：单选时被点的那一行高亮转圈（semantics selected），多选时确认键转圈；各行与确认键不接受点击，取消、搜索和标签照常。清掉后单选忘掉那一行，多选保留已选供重发。
  - 新增 `flareLocationWebMapUrl(content, provider:)`（宿主自己打开地点时的网页地图地址：参数优先、其次内容的 provider；缺坐标、超范围或线上的 0, 0 返回 null）和 `flareLocationProviderFrom(value)`（`chat.location` 配置值转服务商，未知回落 osm）。规则见 `spec/location-vectors.json` 的 `webMapUrl`、`providerFrom`。**app 自带的同名 `flareLocationProviderFrom` 要删掉**，否则同时导入时名字冲突。
- 第六轮验收修复（插件卡片详情入口、inset）：
  - `FlarePluginView` 卡片级「查看详情」：`view.detail` 为真、没有 entries 块在显示「查看全部」、可用、非 embedded，并且传了 `onOpenDetail` 时，在动作区下方画整宽的 quiet 文字按钮（size sm，`pluginViewDetail`，key `FlarePluginView.detailKey`），点击回调 `onOpenDetail`；`busy` / `busyActionId` 时禁用。新增纯函数 `flarePluginShowsDetailKey`。
  - `FlarePluginViewInset` 新增 `sheetTop`（上 md、左右 lg、下不留），用于 PluginForm 上方的前言。新增 `flarePluginViewInsetPadding(inset)`。
  - `inset` 现在作用于所有状态：embedded 的内容（含不可用态），以及宿主留在面板里的卡片外壳（外壳之外）。不可用的 embedded 视图把标题显示为一行次要文字。
  - `FlareStrings` 新增 `pluginViewDetail`（「查看详情」/ "View details"）。
- 插件卡片结算信号：`FlarePluginView` 新增 `settleToken`（int，宿主每完成一次动作加 1，并且先设好这次结果的 `error` / `formErrors`）。每次变化都结算：
  - 没有错误：关闭已提交的表单面板，乐观选中保留到新视图到达。
  - 有 `error`：撤回乐观选中，表单留着并显示它。
  - 有 `formErrors`：表单留着，表单携带的选中一并撤回。
  - `busyActionId` 离开该动作仍作为兜底；宿主在同一帧里设上又清掉 `busyActionId` 时，只能靠 `settleToken` 结算。
  - 带表单的 choices 动作现在把选中和表单值一起提交（`{selection, formValues}`），与 Vue 一致。
- `FlarePluginView` 新增 `inset`（`FlarePluginViewInset.none` / `sheet`）：embedded 加 sheet 时按底部面板留白（上 md、左右 lg、下 xl，与 `FlarePluginForm` 一致）。
- `FlarePluginDetailSheet` 新增 `actionError`、`formErrors`、`members`、`settleToken`，原样交给内嵌 PluginView。已有的 `error` 仍表示加载失败。
- `FlarePluginDetailSheet` 支持 detail 分页：
  - 视图带 `nextCursor` 时，在内嵌视图下方显示「加载更多」（复用 `myInviteLoadMore`），点击回调 `onLoadMore(cursor)`。新增 `loadingMore`。
  - 已请求的页在游标换掉之前不会再请求；`loadingMore` 由真变假、`settleToken` 变化或 `actionError` 变为非空后允许重试。
  - `FlarePluginDetailSheet` 改为 StatefulWidget。
  - `FlarePluginViewModel` 新增 `nextCursor` 与 `nextPageCursor`（空白视为最后一页）。
- `FlareBottomSheet` 与 `FlareBottomSheet.show` 新增 `fill`：定高模式，面板占满上限，内容撑满剩余高度，交给 Modal 时就是 Modal 的 fill。
  - 新增标记接口 `FlareSheetOwnHeader`：fill 时，内容（或 `show` 的 builder 返回的组件）实现了它，面板就只把 title 当可及名称，不画第二个标题。
  - `FlareLocationPicker`、`FlareContactPicker` 已实现该接口；`FlarePluginForm` 的成员选择改用 fill。
- `FlareLocationPicker` 新增：
  - `sending`：发送键转圈并禁用。
  - `ensurePermission`：`Future<bool> Function()`，每次定位前先等它；权限弹框的等待不计入 `locateTimeoutMs`，返回 false 时直接进入 denied。
  - previewUrl 的宽高按新增的 `flareLocationPreviewSize` 计算（设备像素，屏幕倍率限制在 1 到 2 之间，见 `spec/location-vectors.json` 的 `previewSize`）。
- `FlareFriendRequest` 新增 `source`，`FlareNewFriendRequests` 把它画在验证消息下方单独一行。
- `FlareContactDetail` 新增 `primaryActionLabel` 与 `onPrimaryAction`：给陌生人的主操作排在操作行首位，作为主按钮；此时「发消息」改为次要键。它不放进页脚的 `extraActions`。
- 「+」面板默认集（`FlareComposerActionPanel.defaultActions`）去掉 poll，改为 image、camera、video、file、voice、location、card。投票改由插件提供；`FlarePollComposer`、`FlareVoteMessage` 保留。
- 插件卡片 v2：**破坏性**：`FlarePluginView` 改为接收 `view: FlarePluginViewModel`（`FlarePluginViewModel.fromJson` 解析核心 SDK 的 ResolvedPluginView；同一份 JSON 解析出的视图相等），`onAction` 改为 `(actionId, FlarePluginActionPayload)`。新增 `icon`、`busyActionId`、`error`、`embedded`、`resolveUser`、`members`、`formErrors`、`onOpenDetail`，以及块 text、fields、choices、entries、people、status、progress、time、divider、note（rows 只在 Vue），动作的 `style`、`confirm`（`FlareDangerConfirm.show`）与 `form`（Kit 面板里的 `FlarePluginForm`）。
- 新增 `FlarePluginForm`、`FlarePluginDetailSheet`（`show` 在 Kit 面板上呈现）与 `models/plugin_view.dart` 的类型和纯函数（`flarePluginTimeText`、`flarePluginCountdown`、`flarePluginCheckForm`、`flarePluginFormValues`、`flarePluginIssueText`、`flarePluginFallbackName`，时间块读 `flarePluginNowMs`），规则见 `spec/plugin-view-vectors.json`。`FlareStrings` 新增 `pluginView*`、`pluginForm*`、`locationOsmAttribution` 与 `select`、`selectDate`、`selectTime`。
- 位置：provider 为 osm 时，`FlareLocationMessage` 与 `FlareLocationPicker` 在静态图右下角显示 OpenStreetMap 署名（`FlareLocationMapSurface.attribution`），amap 时不显示；`FlareLocationPicker` 新增 `provider`（默认 osm）。
- 位置：新增 `FlareLocationPicker`（选点面板内容，宿主回调 `requestCurrentLocation`、`searchNearby`、`reverseGeocode`、`previewUrl`，`initialLocation` 与 `locateTimeoutMs`；状态 `FlareLocationPickerState`，根节点以 `ValueKey(state)` 标出）。
- **破坏性**：`FlareLocationMessage` 新增 `latitude`、`longitude`、`snapshotUrl`、`provider`，去掉 `mapImage`；没有静态图或加载失败时画地图底纹加中心点。`FlareLocationContent` 新增 `snapshotUrl`、`provider`。`FlareMessageContentView` / `FlareMessageBubble` / `FlareMessageList` 新增 `onLocationOpen`；没有时把按运行平台选出的地图链接（iOS、macOS 为 Apple 地图，Android 为 `geo:`，其余为服务商网页地图，`spec/location-vectors.json`）交给 `onOpenLink`。新增 `flareLocationMapLinks`、`flareLocationCoordinateLabel`、`flareLocationDistanceLabel` 与 `FlareLocationProvider` / `FlareLocationCoordinate` / `FlareLocationAddress` / `FlareLocationPlace`。
- 名片：新增 `FlareContactPicker`（分组标签、搜索、懒加载列表、空态、「（我）」，单选点一行即 `onSelect`，多选由「确定」回传）与 `FlareContactPickerEntry`、`FlareContactPickerGroup`。**破坏性**：`FlareContactMessage.onOpen` 改为 `ValueChanged<String>`，回传新增的 `userId`；没有回调时不画箭头。`FlareCardContent` 新增 `userId`，列表、气泡、分发器新增 `onCardOpen`。
- 「+」面板默认集改为 image、camera、video、file、voice、location、card、poll。图标 `locate`（注册表最后一项，共 108 个，`Icons.my_location_outlined`）。`FlareStrings` 新增 16 个位置与选择联系人字段。
- 「+」面板默认集改为内置功能 image、video、file、voice、card、poll（图标 image / video / file / mic / card / poll），去掉 location 与 contact；`poll` 的文案取 `actionVote`。`FlareComposerAction` 新增可选 `kind`（`FlareComposerActionKind`：feature / plugin）与 `resolvedIcon`。
- 图标 `plugin`（注册表最后一项，共 107 个，`Icons.extension_outlined`）：「+」面板里图标名不在注册表里的项画它（`flareComposerPluginIcon`），不再画兜底问号。
- 图片、视频、文件保存后，下载键变成「在文件夹中显示」；宿主发现文件被删后传回 idle，键回到下载。收发两侧的消息时间都在右侧。详见仓库根 CHANGELOG。
- `FlareFileMessage` 新增 `downloadState` / `onReveal`；`FlareImagePreview` / `FlareVideoPlayer` 新增 `saved` / `onReveal`，`present` 可传实时下载状态；列表、气泡、分发器新增 `onMediaReveal`；`FlareVideoMessage.duration` 可空，未知时长不画角标。

## 2.0.0-rc.1

- **许可证由 MIT 变更为 Apache-2.0。** 已发布的 1.0.5 及更早版本仍按 MIT 授权，
  本次变更仅对之后的版本生效。Apache-2.0 含显式专利授权条款。
- 迁移到自包含的 `packages/flutter-im-ui` 包结构，并移除旧路径兼容层。
- 增加六套品牌主题、亮暗模式和消息语义 Token。
- 将组件数据、命令和生命周期统一为宿主控制的展示契约。

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
