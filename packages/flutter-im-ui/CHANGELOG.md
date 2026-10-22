## 未发布

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
  - 红包第五版，**破坏性**：删除 `FlareRedPacketState`，改为 `FlareRedPacketCardState`（unopened、viewable、claimed、finished、expired、refunded）与 `flareRedPacketCardState(status, claimedByMe, tapAction)`；`FlareRedPacketCard` 删除 `kindLabel`、`amount`，新增 `kind`（拼手气、专属角标）与 `recipientName`（「给 某某」），卡片从不显示金额。`FlareRedPacketOpenSheet` 新增 `canViewDetails`（notEligible 永不给详情键）。`FlareRedPacketDetail` 改为按 `details: FlareRedPacketDetailsView`（viewerRole 裁剪后的结果）渲染，新增 `designatedName`、`nowMs`；`FlareRedPacketClaim` 改为 `amountMinor` + `claimedAtMs`。金额由 `flareRedPacketMoney(minor, exponent, currency)` 用整数字符串运算格式化。规则读 `spec/red-packet-vectors.json`。
  - `FlareStrings`：新增 `messageReadSummaryUnread`、`messageReadSummaryAllRead`、`messageSendFailedRetry`、`messageDeleted`、`packetView`、`packetRefunded`、`packetBadgeLucky`、`packetBadgeExclusive`、`packetForRecipient`、`packetNotEligibleName`、`packetDeposited`、`packetSummarySender`、`packetSummaryCompleted`、`packetSummaryCount`、`packetRefundAt`、`packetRefundedNote`、`packetDuration*`、`pluginViewMore`、`pluginViewMe`、`pluginViewUnavailable*`、`pluginPageRefresh`；`packetTapToClaim` 改为「领取红包」，`packetExpiredNotice` 改为「红包已过期」，删除 `packetClaimed`。

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
