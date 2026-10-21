## 未发布

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
