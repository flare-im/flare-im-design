## 未发布

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
