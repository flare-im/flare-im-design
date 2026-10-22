## 未发布

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
