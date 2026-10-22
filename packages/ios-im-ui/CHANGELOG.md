## 未发布

- 第六轮验收修复：
  - `PluginView` 卡片级「查看详情」：`view.detail` 为真、没有 entries 块在显示「查看全部」、可用、非 embedded，并且传了 `onOpenDetail` 时，在动作区下方画整宽的 quiet 文字按钮（size sm，`pluginViewDetail`），点击调用 `onOpenDetail`；`busy` / `busyActionId` 时禁用。
  - `PluginViewInset` 新增 `sheetTop`（上 md、左右 lg、下不留），用于 PluginForm 上方的前言。`inset` 现在作用于所有状态：embedded 的内容（含不可用态）和宿主留在面板里的卡片外壳（外壳之外）。不可用的 embedded 视图把标题显示为一行次要文字。
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
