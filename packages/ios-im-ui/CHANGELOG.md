## 未发布

- 系统消息事件名按社交服务端写的 `SystemContent.event_kind` 补齐：`FlareStrings` 新增 `systemEventGroupProfileUpdated`、`systemEventGroupProfileUpdatedNamed(name)`、`systemEventGroupMemberRolesChanged`、`systemEventGroupMuted`、`systemEventGroupUnmuted`；`flareStoredPreviewText(_:strings:locale:systemEventText:)` 读 `group.profile_updated`（事件参数 `p.display_name` / `p.name` 带名字时读「群名称已改为「…」」）、`group.member_roles_changed`、`group.muted`、`group.unmuted`，群公告改读服务端实际发的 `group.announcement`（原来认的 `group.announcement_updated` 没人发），去掉没人发的 `group.member_removed`（`spec/message-preview-vectors.json` `stored`）。
- 服务端时钟 `FlareServerClock`（`setOffsetMs(_:)`、`offsetMs`、`nowMs()`、纯函数 `now(deviceNowMs:offsetMs:)`，`spec/server-clock-vectors.json`）：宿主交进核心 SDK 的估计（`connection.getServerClock` 的 `offsetMs`）后，插件视图的时钟（时间块倒计时与「已截止」、行、账户明细、红包详情）与 `MyInvitePanelView` 的重新生成冷却按服务端时间算；没交时为本机时钟。
- 群管理入口只跟宿主权限来源的答案走（`spec/group-management-vectors.json`，与 Vue、Flutter、Compose 同一张表）：`FlareGroupDetailModel` 去掉 `canManage`、`isOwner`，改收 `capabilities: FlareGroupCapabilities`（canManageInfo、canManageJoinSettings、canManageJoinRequests、canInvite、canDissolve）与按成员 id 的 `memberActions: [String: FlareMemberActions]`（canRemove、canMute、canChangeRole、canTransferOwner）；新增 `FlareGroupManagementEntry`、`groupManagementEntries(_:)`、`groupDetailMemberActions(model:memberId:)`。`memberRoleActions(role:muted:actions:)` 不再带身份等级规则；`MemberRoleSheetView` 的 `viewerRole` 与 `capabilities` 换成 `actions`，删掉 `FlareMemberRoleCapabilities`；`GroupPermissionMatrixView` 与 `groupPermissionRows` 的 `canManage` 换成 `capabilities`（进群方式看 canManageJoinSettings，四个开关看 canManageInfo，一行都改不了才显示只读提示）。`FlareGroupDetail.previewMembers` 的参数改名 `addTile`。

- 宿主按媒体线上类型传入的 `FlareGenericContent`（`image` / `video` / `audio`）画成「图片暂时无法加载」等（`FlareStrings.mediaUnavailableImage` / `Video` / `Audio`），不再画 `UnknownMessageView`。

- 新增 `flareStoredPreviewText(_:strings:locale:systemEventText:)`：按共享表 `stored`（`spec/message-preview-vectors.json`）读核心存在会话行、引用与搜索结果上的摘要 token，与 Vue、Flutter、Compose 同一规则。`FlareStrings` 新增 `systemEvent*`，没有自带文字的系统消息按事件键取这些文案。宿主不必再自己解 token。

- 打开着的指针菜单在宿主作废快照后自己重新预读：macOS 上，宿主作废了菜单那条消息的快照并重画列表时，菜单里出现的「正在读取…」会请求这条消息，宿主期间重画不会重复请求；新的托管窗口测试锁住这一点（去掉这次请求即失败）。宿主不必再为打开着的菜单自己重读。

- 气泡色板函数、iOS 16 滚动路径的定位、快照与指针菜单：
  - 新增 `FlareMessageBubbleTone`、`flareMessageBubbleTone(isSelf:status:)`、`FlareMessageBubblePalette`、`flareMessageBubblePalette(_:colors:)`（`spec/message-surface-vectors.json` `palette`），`MessageBubbleView` 按它画底色与红边。外观不变。
  - `MessageListView` 的 iOS 16 滚动路径：定位到某条消息时清掉绑定的可见位置，与新路径一致。系统保留绑定位置时（macOS 14 / iOS 17 起），被定位行的标记一改动内容，列表就会被拉回末尾。
  - 指针菜单打开期间，宿主带着新快照重画列表，菜单就地更新：「正在读取…」换成条目，核心不再允许的动作移除。macOS 上补了托管窗口测试锁住。
  - 视觉快照固定按 2x 渲染，与显示器缩放无关；同时固定「减弱动态效果」为关、排版语言为 en-US（宿主开着减弱动态时，发送中的转圈会画成时钟；系统偏好语言决定「·」取哪种字形，按 en-US 排版时 zh-Hans 与 en-US 系统画得一样）。两张基线按 b0cee27 的回执五态、实心失败图标、内联元信息重建。

- 批量工具条转发可用性、合并转发条目色板、富文本前景、消息菜单预读：
  - `MessageBatchToolbarView` 新增 `unforwardableIds: Set<String>`（默认空）：逐条转发至少 1 个、合并转发至少 2 个可转发 id，这两个动作只上报可转发 id；有不可转发项时计数下方显示 `messageBatchUnforwardable`（`messageBatchUnforwardableOne` 为英文单数）。新增 `messageBatchActionIds`、`messageBatchUnforwardableCount`、`MessageBatchAction.forwards`，`messageBatchActionsAvailable` 新增可选参数（`spec/message-batch-vectors.json` 的 forward）。
  - 合并转发的条目（单条内联与抽屉里每一行）按别人的消息画，不再继承本人气泡的白色前景；`RichTextMessageView` 读所在表面给的前景（失败消息的失败底色、转发记录的中性色板），与 `TextMessageView` 一致。
  - 消息菜单：行的快照到达时即结清预读记录，快照之后失效时会再次读取；指针菜单的「正在读取…」与长按一样每次都发起读取，不再被去重吞掉（`FlareMessageMenuPrefetcher.ask`）。

- 通话：新增 `CallRecordCardView` 与 `FlareCallRecordRules`（`FlareCallRecordScope`、`FlareCallRecordState`、`FlareCallEndReason`，`spec/call-record-vectors.json`），`FlareStrings` 新增 `callRecord*`；`CallView` 新增 `onMinimize`（传入才绘制收起按钮）。

- 抽屉优先使用内部 `FlareScreen` 的返回：Escape 与辅助功能返回逐页退回，栈底才关闭；自带返回页头时不重复画抽屉页头，忙碌锁定与遮罩关闭保持一致。

- 已读名单分页状态与函数式文案的英文（`spec/read-receipt-list-vectors.json`、`strings/en-formats.json`）：
  - 新增 `FlareReadReceiptListState`（`ObservableObject`：`pages`、`open(_:)`、`loadMore(_:)`、`retry()`）、`FlareReadReceiptPages`、`FlareReadReceiptMembers`、`FlareReadReceiptPageLoader`（宿主给一个取页函数 `(column, cursor?) -> members?`，nil 为不可查看，抛错为失败）：打开时两栏并发取第一页，任一 nil 为 unavailable、任一失败为 error；按栏翻页去重并换游标，nil 结束该栏，失败标记该栏、再次请求时清掉；换 key 或关闭时丢弃在途结果。宿主持有一个 `@StateObject`，用 `.flareReadReceiptList(_:key:page:)` 绑定打开的消息（换 key 重读，始终用最新的取页函数），用 `ReadReceiptSheetView(list:readCount:unreadCount:…)` 画。
  - `FlareStrings.english` 覆盖全部函数式字段（计数按英文单复数、月份英文名、无名字的引用写法），`strings/build.mjs` 的 iOS 模板在生成的字段后调用 `englishFormats()`。
- 已读名单、发送者、红包金额位数与退回、「我」页菜单、合并转发、复数、消息菜单同源（`spec/read-receipt-vectors.json`、`me-menu-vectors.json`、`message-forward-vectors.json`、`plural-vectors.json`、`red-packet-vectors.json` 新段、`plugin-view-vectors.json` rules.choices / menuActions）：
  - `ReadReceiptSheetView`：新增 `readCount` / `unreadCount`（标签数字只取摘要人数，缺省时标签不带数字，不再取列表长度）、`state`（`FlareReadReceiptState`：ready / loading / error / unavailable）、`readHasMore` / `unreadHasMore`、`loadingMore` / `loadMoreFailed`（`FlareReadReceiptColumn`）、`initialTab`、`onLoadMore(column)`、`onRetry`。两栏各自分页：末尾是「加载更多」键、加载中的转圈（不可点）或「加载失败，点按重试」键；error 显示「名单读取失败」与重试键，unavailable 只有提示，两者都不画标签。宽度随容器：单独放时是最宽 320 的卡片外壳（名单区最高 320），在 Kit 底部面板或对话框里不画外壳、占满并声明自带标题（`flareSheetOwnHeader`），名单区占满剩余高度。纯函数 `FlareReadReceiptLayout.of`。
  - 新环境值 `flareInOverlaySurface`：`BottomSheetView` 与 `ModalView` 的内容里为真。
  - `FlareContentContext` 新增 `senderId`；`senderName` 去首尾空白、空串为 nil，不回落到 id。`MessageContentView` 新增 `senderId`，`MessageBubbleView` 传入消息的 `senderId`。
  - `FlareRedPacketOpenState` 新增 `refunded`（在 expired 之后）：不画「開」，「查看详情」由 `canViewDetails` 决定，文案「红包已退回」（宿主 `message` 仍可覆盖）。
  - `RedPacketComposerView` 新增 `currencyExponent`（默认 2，夹在 0...6）：金额框最多留这么多位小数（0 时不收小数点），占位为对应位数的零（"0" / "0.00" / "0.000"），0 位时用纯数字键盘。新增 `flareRedPacketAmountMinor(_:exponent:)`：输入框文本换成最小单位整数字符串，整数运算。
  - 新增 `flareMeMenuSections(_:labels:summaries:strings:)` 与 `FlareMeMenu` / `FlareMeMenuItem` / `FlareMeMenuItemKind`（解码社交 SDK `features.meMenu` 的 JSON，`FlareMeMenu.parse`）：设置以外的项按 SDK 顺序成第一组，设置单独成组在最后；内置项用 Kit 文案（可按 id 覆盖），插件项用标题（空时「插件」）；`summaries[id]` 去空白后作副标题（插件项的摘要，或宿主给内置页的说明）；图标经回落。
  - 图标：注册表在 `locate` 之后新增 `wallet`（`wallet.bifold`，iOS 18 / macOS 15 以下画 `creditcard`），共 109 个。新增 `flareIconNameOrFallback(_:)`：注册表名原样，空名为 nil（不画），其他名字回落 `plugin` 字形，调试构建按名字告警一次；`IconView`、设置行、「+」面板、菜单与标题动作都经它，不再画问号。
  - 合并转发：新增 `FlareForwardContent`（`title`、`mode`：`FlareForwardMode` unspecified / single / merged、`items`）与 `FlareForwardItem`（`senderName`、`sentAtMs`、`plainText`、`content`），表面为 card，由 `MessageContentView` 画成 `FlareForwardMessageView`：没有条目一行「暂无转发内容」，一条且非合并时直接画那一条，其余是记录卡片（标题、「共 N 条消息」、前 3 条「发送者: 摘要」、「还有 N 条消息…」、「点击查看详情」，整卡一个按钮），点开 Kit 侧边抽屉列出每一条（首字头像、发送者、时间、摘要、非文本内容）；多选时不可点。纯函数 `flareForwardRecordView`、`flareForwardSender`、`flareForwardSenderInitial`（名字首字大写，无名为「?」）、`flareForwardSummary`（`plainText` 按文本摘要读：去空白、Markdown 转纯文本、表情包键按语言）；`flareMessagePreviewText` 认识它；`FlareTimeFormat.dateTime`（同一天只有时钟，否则月日加时钟）。
  - 复数：新增 `flarePluralIsOne(_:locale:)`、`flarePlural(_:one:other:locale:)`、`flarePluralFamily(localeIdentifier:)` 与 `FlarePluralFamily`（按 CLDR 规则表，pt-PT 单列）；投票的「N 票」、组头、邀请人数、存储文件数、合并转发的条数按环境 locale 选单复数。`FlareStrings` 新增单数字段 pluginViewVotesOne / myInviteCountOnlyOne / storageUsageFileCountOne / forwardRecordTotalOne / forwardRecordMoreOne。
  - 投票：choices 页脚不再画 total（它只是百分比的分母，分不清人数还是票数），只剩「最多选 n 项」与「已结束」；「N 票」只用于选项。⋯ 键贴卡片标题行行尾（短标题、空标题也一样），新增像素级测试。
  - 消息菜单（破坏性）：`MessageListView` 删除 `contextMenu` 与 `FlareMessageContextMenu`，新增 `menu: FlareMessageMenuSource`（`availability` 同步快照、`prefetch`、`hiddenActions`、按消息求值的 `extraActions`、`perform`）：长按面板（Kit 自己用 `flareBottomSheet` 打开 `MessageActionSheetView`，表情交给 `onReact`）与指针设备的右键菜单用同一个条目函数 `messageMenuEntries(_:strings:hidden:extra:content:)`；快照还没有时右键菜单只有一条不可点的「正在读取…」，长按先请求、拿到快照再开；行进入视口时批量 `prefetch`。传了 `menu` 时不再调用 `onMessageLongPress`。`FlareMessageMenuSource.pointerIdiom` 公开。
  - `FlareStrings` 新增 readReceiptRead / readReceiptUnread / readReceiptLoadFailed / readReceiptUnavailable / readReceiptLoadMore / readReceiptLoadMoreFailed、packetRefundedNotice、meMenuMoments / meMenuReports / meMenuInvite / meMenuSettings / meMenuPluginFallback、forwardRecordTitle / Total / More / ViewDetails / UnknownSender / Empty / CountSuffix / CardLabel、messageMenuLoading，英文预设已生成。
- 插件页面的数据与动作、行级徽标、多选上限（`spec/plugin-view-vectors.json` rules.page / pageRows / pagePaging / pageFilters / badge / maxSelections）：
  - `FlarePluginPage`：新增必填 `page`（`PluginPageRef`），`view` 改为 `PluginPageViewModel`（核心 SDK `pluginPage` 的结果：视图加 `data`，视图字段可直接读），新增 `filters` 与 `onFilter`；`onAction` 改为 `(String, PluginPageActionPayload)`，载荷即 `invokePageAction` 的请求（page、data、row、selection、formValues）。删除 `onOpenDetail`（页面没有详情）。状态加 unavailable：Kit 空态显示原因文案，只有 catalog_unreachable 带重试，不画刷新、筛选、加载更多和动作；有视图时的 `error` 画成视图上方的危险横幅。筛选：rows 块列出的 select 输入（不列时为全部输入）各是一行 `FilterTabsView`，「全部」在前，选中项来自宿主的 `filters`，选另一项发出改好的值（保留宿主的其他筛选值），刷新或加载更多时禁用。加载更多在刷新结束时也释放已请求的游标。
  - `PluginViewModel` 的 rows 块现在解码（`PluginBlock.rows`、`PluginRowsBlock`、`PluginRow`、`PluginRowCell`、`PluginRowAction`、`PluginRowsColumn`），四端一致画成列表：徽标与第一格、其余单元格以「 · 」连接（时间列按设备时区）、行末紧凑动作键（确认与表单照常，载荷带 `row`），同一 key 只画第一次；没有行时显示 emptyText，否则「暂无数据」。同一动作的多个行键只有发起的那一行转圈。带 rows 块的视图不画「查看详情」键。
  - 徽标：entries 条目与 rows 行的 `badge`（`PluginBadge`），Kit 标签样式（语义色文字、6% 底色、caption 字号、单行），顺序为名字 → 我 → 徽标 → 正文；未知 tone 按 neutral。
  - 多选上限：`PluginChoicesBlock.maxSelections` 与 `cap`；选满后其余选项禁用（已选的仍可取消），上限调低后只能减选，提交须在上限内，可选时页脚以「最多选 n 项」开头；卡片、详情、页面一致。
  - `PluginActionPayload` 新增 `row`（`PluginRowRef`）。`FilterTabsView` 选中项带 `isSelected` 读屏特征。
  - `FilterTabsView` 新增 `enabled`（默认 true）：为假时整行降到禁用透明度、每个标签禁用；`FlarePluginPage` 的筛选改用它。胶囊保持原尺寸，放在至少 `FlareSizes.touchTarget` 见方、居中的格子里接收点击（矩形 contentShape），行的版面因此增高到触达区。
  - `FlareStrings` 新增 pluginViewMaxSelections / pluginViewAll / pluginViewEmpty。
- 第八轮：消息表面、元信息、回执与插件第二版（docs/design/message-surface-and-meta.md、red-packet-v5-roles-and-wallet.md §1–§3、poll-v2-permissions-anonymity.md §6、plugin-platform-v2-trust-lifecycle-admin.md §4）：
  - 表面：新增 `FlareMessageSurface`（bubble / bareMedia / card / centered）、`FlareMessageSurfaceInput` 与纯函数 `flareMessageSurface(_:)`、`FlareMessageData.surface(registry:)`。插件卡片、红包、位置、名片、链接卡、旧投票、任务、日程、公告、小程序、合并转发、话题都是 card：`MessageBubbleView` 不再画底色、边框、内边距和尾角，卡片外壳就是表面；Kit 自己的卡片内容画在 Kit 卡片外壳里（radius lg、主背景、发丝线、宽 ≤ `componentRichCardWidth`），引用条画在外壳内顶部（`FlareMessageCardQuoteSlot`，`PluginView` 已放）。`MessageBubbleView` 新增 `surface`。
  - 宿主登记：删除 `flareContentRenderers(_:bare:)` 与 `flareBareContentTypes`，改为 `flareContentRenderers(_:surfaces:)`（`FlareMessageRegisteredSurface`：card / bareMedia，键为 `type:subtype` 或 `type`）；`FlareGenericContent` 新增 `subtype`，渲染器与表面都先查 `type:subtype`。自定义内容默认就是 card，不用登记。
  - 元信息：新增 `FlareMessageMetaPlacement`（inline / bubbleFooter / below / none）、`flareMessageMetaPlacement`、`flareMessageMetaTone`、`flareMessageRetryForm`。文本时间跟在最后一行行尾（放不下时自然换到单独一行）；卡片与裸媒体在下方 spacing xs、尾侧、默认色板；失败时下方是「发送失败，重试」文字键。`MessageMetaView` 新增 `placement`、`tone`、`readSummary`、`conversationKind`、`onReadReceiptOpen`，删除 `tint`；时间文字改用 `messageMetaForeground`。
  - 回执：`FlareMessageDeliveryStatus` 只剩五态（删除 delivered、retrying）；生命周期的 delivered 投影为 sent。新增 `FlareMessageReadSummary`、`flareMessageReceiptPresentation`、`flareMessageAccessibilityLabel`；`FlareMessageData` 新增 `readSummary` 与 `receiptStatus`、`isDeleted`。群聊己方消息显示「N 人未读 / 全部已读」，`MessageBubbleView` / `MessageListView` 新增 `onReadReceiptOpen`。失败重发热区 44pt（`MessageStatusView` 改为按钮，布局仍是 12pt 图标）；失败气泡改用失败面（底色、前景、红边），失败图标不再落在紫色面上。
  - 分组：`MessageRowPresentation` 新增 `tail`；新增 `FlareMessageGroupingItem`、`FlareMessageGroupingOptions`、`flareTimelineRows`、`flareTimelineDateLabel`。卡片与非卡片互相断组，卡片不画尾角，删除提示居中「消息已删除」。
  - 交互与无障碍：内容新增 `selectionMode`（`MessageContentView`、`FlareContentContext`），多选时内容整体不响应、点整行切换选中；`MessageListView` 新增 `contextMenu`（`FlareMessageContextMenu`，macOS 与 iPad 指针下用同一份菜单条目画右键菜单）；消息行合并为一个读屏单元（发送者、内容摘要、时间、状态），自定义动作回复、菜单、重试；日期胶囊、系统提示、昵称字号随动态字体；图片加载失败显示「图片加载失败 · 重试」，点按重载。
  - 插件视图：`PluginViewModel` 新增 `menuActions`、`unavailableReason`（`PluginUnavailableReason` 七种）；entries 支持 `grouped` 与条目 `group`（组头「标签 · N 票 · P%」，`numbered: false` 不编号）。`PluginView` 新增 `displayName`、`viewerId`：标题行末 ⋯ 打开菜单动作（embedded 时作为按键排在动作之后），不可用时显示「名称 · 原因」，`unbound_copy` 只读并以「副本，仅供查看」收尾，本人条目带「我」。外壳描边不再吃点击。`PluginDetailSheetView` 新增 `viewerId`。
  - 新组件 `FlarePluginPage`：插件 page 贡献的全屏页面宿主（FlareScreen、返回、触屏下拉刷新 / 指针设备页头刷新键、内嵌 PluginView、按游标加载更多）。
  - 红包第五版：`FlareRedPacketState` 改为 `FlareRedPacketCardState`（unopened / viewable / claimed / finished / expired / refunded，`flareRedPacketCardState(status:claimedByMe:tapAction:)`）；`RedPacketCardView` 删除 `kindLabel`、`amount`，新增 `kind`、`recipientName`，卡片不显示任何金额。`RedPacketOpenSheet` 新增 `canViewDetails`，notEligible 不再给详情。`RedPacketDetailView` 改为 `details`（`FlareRedPacketDetailsView`，按 viewerRole 裁剪）+ `designatedName` + `claims`（`FlareRedPacketClaim` 改为 `amountMinor`、`claimedAtMs`）；金额按 `currencyExponent` 从最小单位整数格式化（`FlareRedPacketMoney`）。
  - 删除与契约不一致的死代码 `resolveMessageActions`、`FlareMessageAction`、`FlareMessageActionGroup`、`FlareMessageActionPresentation`（`resolveMessageMode` 是 interaction-contracts 的必备符号，保留）。
  - `FlareStrings` 新增 messageReadSummaryUnread / messageReadSummaryAllRead / messageSendFailedRetry / messageDeleted、pluginViewMore / pluginViewMe / pluginViewUnavailable*（七个）/ pluginPageRefresh、packetView / packetRefunded / packetBadgeLucky / packetBadgeExclusive / packetForRecipient / packetNotEligibleName / packetDeposited / packetSummarySender / packetSummaryCompleted / packetSummaryCount / packetRefundAt / packetRefundedNote / packetDuration*；删除 packetClaimed；packetTapToClaim 改「领取红包」、packetExpiredNotice 改「红包已过期」。

- 第七轮 Kit 小缺口（app 接线反馈）：
  - `FlareContactDetail` 新增 `primaryActionBusy`（参数末尾）：主按钮以 `ProgressView` 代替图标并禁用，颜色不变；其他操作照常。
  - `ContactPickerView` 新增 `sending`（在 `title` 之后）：单选时被点的那一行高亮转圈，多选时确认键转圈（`ButtonView` loading）；各行与确认键禁用，取消、搜索和标签照常。清掉后单选忘掉那一行，多选保留已选供重发。纯函数 `ContactPickerView.isPending`。
  - 新增顶层函数 `flareLocationWebMapUrl(_:provider:)`（宿主自己打开地点时的网页地图地址：参数优先、其次内容的 provider；缺坐标、超范围或线上的 0, 0 返回 nil）和 `flareLocationProviderFrom(_:)`（`chat.location` 配置值转服务商，未知回落 osm）。规则见 `spec/location-vectors.json` 的 `webMapUrl`、`providerFrom`。
- 第六轮验收修复：
  - `PluginView` 卡片级「查看详情」：`view.detail` 为真、没有 entries 块在显示「查看全部」、可用、非 embedded，并且传了 `onOpenDetail` 时，在动作区下方画整宽的 quiet 文字按钮（size sm，`pluginViewDetail`），点击调用 `onOpenDetail`；`busy` / `busyActionId` 时禁用。
  - `PluginViewInset` 新增 `sheetTop`（上 md、左右 lg、下不留），用于 PluginForm 上方的前言。`inset` 现在作用于所有状态：embedded 的内容（含不可用态）和宿主留在面板里的卡片外壳（外壳之外）。不可用的 embedded 视图把标题显示为一行次要文字。
  - `DangerConfirmView`（`FlareFeedback.confirm` 的确认面板）内容铺满面板宽度、从左侧内边距开始（原来 ScrollView 把较窄的内容居中，整体右偏）；「取消 / 确认」改为 Kit `ButtonView`（secondary、danger，整宽上下排列，busy 时确认键转圈），不再是无样式的系统按钮。
  - `FlareStrings` 新增 `pluginViewDetail`（「查看详情」/ "View details"）。
- 第六轮 Kit 打磨（app 接线反馈）：
  - `PluginView` 新增 `settleToken`（宿主每完成一次动作加 1：没有 error 和 formErrors 时关闭已提交的表单、乐观选中保留到新视图；有 error 撤回选中；有 formErrors 表单留着；`busyActionId` 离开该动作仍作兜底，两者同时到达只结算一次）和 `inset`（`PluginViewInset`：none / sheet，embedded 时按底部面板留白 md / lg / xl）。宿主信号合成一个值比较，同一次更新里设上 error 并结算也能读到。
  - `PluginDetailSheetView` 新增 `actionError`（内嵌视图的 error，不落到卡片上）、`formErrors`、`members`、`settleToken`，原样交给内嵌 `PluginView`；视图带 `nextCursor` 时底部画「加载更多」（`myInviteLoadMore`），点了回调 `onLoadMore(cursor)`，`loadingMore` 时转圈，Kit 不合并分页。`PluginViewModel` 新增 `nextCursor`（空白视为最后一页）。
  - `BottomSheetView` 与 `flareBottomSheet(isPresented:|item:)` 新增 `fill`：面板占满上限，内容撑满剩余高度并自己滚动。内容用 `.flareSheetOwnHeader()` 声明自带标题后，fill 的面板不画可见标题，title 只作可及名称；`LocationPickerView`、`ContactPickerView` 已声明。
  - `LocationPickerView` 新增 `sending`（发送键转圈、不收第二次点击，状态多一个 `sending`）和 `ensurePermission`（每次定位前先等它，返回 true 后才开始计 `locateTimeoutMs`，false 或抛错直接 denied）；**行为变化**：`previewUrl` 的宽高改为设备像素（点 × 屏幕倍率，限 1–2 倍，四舍五入，`FlareLocationFormat.previewPixels`）。
  - `FriendRequest` 新增 `source`，在验证消息下面单独一行显示。`FlareContactDetail` 新增 `primaryActionLabel` 与 `onPrimaryAction`：两者都有时排在操作行首位作主键（person-add），「发消息」改为次要键。
  - 「+」面板默认集去掉 poll，为 image、camera、video、file、voice、location、card；投票由插件提供，`PollComposerView`、`VoteMessageView` 保留。
- 插件视图 v2：`PluginView` 渲染核心 SDK `ResolvedPluginView` 的展示块——text（`maxLines` 截断加展开）、fields、choices（单选点一项即提交；多选先勾草稿再点提交键，键名取块持有的动作；显示结果时每项一条票数条、百分比和票数，「我选的」打勾；已结束只读）、entries（序号、名字、文本，`more` 时「查看全部（n）」触发 `onOpenDetail`）、people（每组一行头像叠加、标签、计数，按 tone 着色）、status、progress、time（设备时区格式化，倒计时不到 1 小时每秒刷新，否则每分钟）、divider、note；渲染事实按 `spec/plugin-view-vectors.json`。外壳与 Kit 业务卡片一致（`componentRichCardWidth`、圆角 lg、细边框、卡片阴影），标题行带图标位，`embedded` 去掉外壳和标题行。底部动作按 style 用主键、危险键或次要键；有 `confirm` 先弹 `DangerConfirmView`，有 `form` 在 Kit 底部面板里收集 `PluginFormView`，`busyActionId` 清空且没有 `formErrors`、`error` 时面板关闭。choices 提交后 Kit 先乐观标记，`error` 变为非空（或 `busyActionId` 带着错误清空）时撤回，新 view 到达即结算。`resolveUser`（async）解析 people 与 entries 的名字和头像，取不到时显示首字母、名字取 userId 末 4 位。新增模型 `PluginBlock` 及各块类型、`PluginInput`、`PluginInputKind`、`PluginInputChoice`、`PluginFormError`、`PluginFormIssue`、`PluginUser`、`PluginMember`、`PluginActionPayload`、`PluginJSONValue`、`PluginActionStyle`、`PluginTone`、`PluginTextStyle`；`PluginViewAction` 新增 `style`、`confirm`、`form`，`PluginViewModel` 新增 `blocks`、`inputs`、`detail`（v1 JSON 照旧解码，不认识的块、输入和键跳过）。**破坏性**：`PluginView` 的 `onAction` 由 `(String) -> Void` 改为 `(String, PluginActionPayload) -> Void`；另新增 `icon`、`busyActionId`、`error`、`embedded`、`resolveUser`、`members`、`formErrors`、`onOpenDetail`。
- 新增 `PluginFormView`：text、textarea 带「n/max」计数，number，toggle（`SwitchView`），select（`RadioGroupView`），datetime（系统日期时间选择），options（可增删行，条数在 [max(min, 1), max] 内），members（`ContactPickerView`，max 为 1 时单选）。客户端只查必填和长度（去首尾空白、按 Unicode 码点），改过的项即时提示、点提交后全部提示；宿主 `errors` 优先显示到该项被修改；`onSubmit` 交出清洗后的值。
- 新增 `PluginDetailSheetView`（宿主放进 `flareBottomSheet(isPresented:title:)`，标题用 `PluginDetailSheetView.heading(view:title:)`）：loading 转圈（读屏名 `loading`），error 显示宿主文案加重试键，其余为 embedded `PluginView`。
- 位置：provider 为 osm 且静态图已经显示时，`LocationMessageView` 与 `LocationPickerView` 在图片右下角画 OpenStreetMap 署名（`locationOsmAttribution`，2xs 次要文字、72% 不透明底、最宽 60%）；手绘底图、地图不可用和 amap 时不画。`LocationPickerView` 新增 `provider`（默认 osm）。
- `FlareStrings` 新增 17 个字段（`pluginView*`、`pluginForm*`、`locationOsmAttribution`、`loading`），英文预设同步生成。
- 图标 `locate`（注册表最后一项，共 108 个，SF `scope`）：选点面板「定位到当前位置」键的准星，与地图钉 `location` 区分。
- 位置：新增 `LocationPickerView`（选点面板内容：地图加中心点与「定位到当前」键、搜索框、首行为当前位置的地点列表、发送键），定位、逆地址、周边搜索和地图图片都由宿主传入的异步函数完成，Kit 管 locating / located / denied / searching / noResults / mapUnavailable 六种状态（`FlareLocationPickerStatus`）；传入 `initialLocation` 时首帧即显示上次位置，否则显示骨架；`locateTimeoutMs`（默认 5000）内没有定位结果按 denied 处理，宿主的定位调用不响应取消也不会拖住面板。新增数据类型 `FlareLocationProvider`、`FlareLocationCoordinate`、`FlareLocationAddress`、`FlareLocationPlace` 与共享规则 `FlareLocationFormat`（默认链接、无地图时的坐标文字、距离，按 `spec/location-vectors.json`）。
- **破坏性**：`LocationMessageView` 的 `mapImage` 改名为 `snapshotUrl`，新增 `latitude`、`longitude`、`provider`；没有静态图（或加载中、加载失败）时画地图底纹加中心点；宿主不传 `onOpen` 时点击打开 Apple 地图（`http://maps.apple.com/?ll=…&q=…`），坐标无效且无 `onOpen` 时不可点。`FlareLocationContent` 新增 `latitude`、`longitude`、`snapshotUrl`、`provider`（均可选，原构造方式不变）。
- 名片：新增 `ContactPickerView`（分组标签、搜索、懒加载列表、空态，自己的行带「（我）」；单选点一行即回调，多选由「确定」回调，按勾选顺序）与 `FlareContactPickerEntry`、`FlareContactPickerGroup`。**破坏性**：`ContactMessageView` 新增 `userId`，`onOpen` 改为 `(String) -> Void`，回传名片里的用户 ID；`FlareCardContent` 新增 `userId`。
- `MessageListView`、`MessageBubbleView`、`MessageContentView` 新增 `onCardOpen`（消息、用户 ID）与 `onLocationOpen`（消息、位置），优先于 `onMediaAction`；名片没有用户 ID 时 `onCardOpen` 不会让它可点。
- 「+」面板默认集改为 image、camera、video、file、voice、location、card、poll（图标 image / camera / video / file / mic / location / card / poll），camera 用 `actionCamera`，location 用 `actionLocation`。
- `FlareStrings` 新增位置与选择联系人的 16 个字段（`location*`、`contactPicker*`），英文预设同步生成。
- 输入栏：`FlareComposerCapabilities` 新增 `availableToolIDs`（`emoji` / `mention` / `voice` / `image` / `richText` / `attachments`，`attachments` 即「+」键），不传时全部可用，语义与 Flutter 一致；收回某个键时同时关掉它打开的面板或模式，草稿保留。
- 「格式」键改为 Kit 自绘的「T」（Lucide `Type` 几何，`rich-text` 进入 Kit 自绘名单），不再用会本地化成「格式」的 SF `textformat`；直接 `Image(systemName:)` 的地方退为 `t.square`。
- 「+」面板默认集改为 image、video、file、voice、card、poll（图标 image / video / file / mic / card / poll），去掉 location，文件图标由 `folder` 改为 `file`；`FlareComposerActionPanel.defaultActionIDs` 列出这六个 id。**破坏性**：`FlareComposerAction.label` 改为可选，不传时按 id 取 Kit 文案（`resolvedLabel(_:)`，新增 `FlareStrings.actionVideo`）；新增可选 `kind`（`FlareComposerActionKind`：feature / plugin）。
- 图标 `plugin`（注册表最后一项，共 107 个，SF `puzzlepiece.extension`）：「+」面板里图标名不在注册表里的项（插件项和内置项都算）画它（`resolvedIcon`），不再画兜底问号。
- `ComposerView` 的「+」面板里点 voice 项时，由 Kit 自己收起面板并切到录音模式，与工具条的语音键用同一个录音器，行为同 Flutter；录音仍经 `onVoiceSend` 交给宿主。没有录音器（未开 `enableVoice`、没有 `onVoiceSend` 或宿主不提供 voice 键）时照旧回调 `onAction`。
- 自定义内容渲染器：`flareContentRenderers(_:bare:)` 列出的类型不画气泡（保留头像、昵称、时间、多选和长按菜单）；`FlareContentContext` 新增 `messageId`（服务端 ID，没有时用 client ID）与 `conversationId`（来自 `MessageListView` 的 `conversationId`）。
- 图标 `red-packet`（注册表最后一项，共 106 个）：`IconView`、按钮、「+」面板、菜单和消息操作面板画 Kit 自绘的线性小信封；直接 `Image(systemName:)` 的地方退为 `envelope`。
- `RedPacketDetailView` 新增可选 `title`、`onBack`（自带红色标题栏）；`RedPacketComposerView` 新增 `locked`；`SegmentedControlView` 新增可选 `accent`。
- 红包组件族：新增 `RedPacketOpenSheet`（`flareRedPacketOpenSheet(isPresented:onDismiss:sheet:)` 呈现）、`RedPacketDetailView`、`RedPacketComposerView`、`RedPacketPayConfirmView`，四端合同见 `docs/plugin-components.md`。
- **破坏性**：`RedPacketCardView` 去掉 `opened` / `finished`，改为 `state`（`FlareRedPacketState`：unopened / claimed / finished / expired）并新增 `kindLabel`；已领完、已过期的卡片仍可点击（查看详情），只有 `busy` / `disabled` 不可点。
- `SegmentedControlView` 的命中区覆盖整条轨道高度，轨道高度提到触控目标（44）。
- 图片、视频、文件保存后，下载键变成「在文件夹中显示」；宿主发现文件被删后传回 idle，键回到下载。收发两侧的消息时间都在右侧。详见仓库根 CHANGELOG。
- `FileMessageView` 新增 `downloadState` / `onReveal`，图标与文案改用 kit 的；`ImagePreviewView` / `VideoPlayerView` 新增 `saved` / `onReveal`；列表、气泡、分发器新增 `onMediaReveal`。
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
