## 未发布

- 输入栏：`FlareComposerCapabilities` 新增 `availableToolIds`（`FlareComposerToolId`：`emoji` / `mention` / `voice` / `image` / `richText` / `attachments`，`attachments` 即「+」按钮），不传时全部显示，传了只显示列出的工具，语义与 Flutter 一致；收回某个工具时同时关掉它打开的面板，草稿保留，`richMode` 也不再呈现。新增 `composerToolAvailable`、`FLARE_COMPOSER_TOOL_IDS`（`./contracts`）。
- 「+」面板默认集改为内置功能 image、video、file、voice、card、poll（图标 image / video / file / mic / card / poll），去掉 location 与 contact；`FlareComposer` 与 `FlareComposerActionPanel` 共用 `FLARE_DEFAULT_COMPOSER_ACTION_IDS` / `FLARE_COMPOSER_ACTION_ICONS`。**破坏性**：`FlareComposerAction.label` 改为可选，不传时按 id 取 Kit 文案（`labelComposerActions`、`FLARE_COMPOSER_ACTION_LABEL_KEYS`，新增 `composer.poll`）；新增可选 `kind`（`FlareComposerActionKind`：feature / plugin）。
- 图标 `plugin`（注册表最后一项，共 107 个，Lucide `Puzzle`）：「+」面板里图标名不在注册表里的项画它（`resolveComposerActionIcon`）。
- 新增 `FlareFilterBar`、`FlareDescriptionList`、`FlareCodeBlock`、`FlareTag` 与类型 `FlareDescriptionItem` / `FlareDescriptionLabelPlacement` / `FlareDescriptionValue`（`./components`）、`FlareConfirmReason` / `FlareConfirmInput` 与 `confirmReasonBytes`（`./contracts`）：控制台查询栏、详情描述列表、原始报文代码块与状态标签；`FlareDataTablePagination.total` 可省略并新增 `hasNext`（游标分页）；`FlareDangerConfirm` / `useFlareConfirm` 新增 `reason` 与 `confirmPhrase`，`confirm` 上报 `{ reason }` 并交给 `action`；`FlareConfirmRequest` 新增 `id`；`FlareStatusBanner` 新增 `title`、`dismissible` 与 `dismiss` 事件；`FlareNavigationItem.href` 让导航项成为链接（修饰键点击交给浏览器，href 过新增的 `safeNavigationHref`）。详见仓库根 CHANGELOG。
- 新增 `FlareDataTable`、`FlarePermissionTree` 与类型 `FlareDataTableColumn` / `FlareDataTablePagination` / `FlareDataTableSort` / `FlarePermissionNode`（`./components`）：控制台数据表格（排序 / 分页只上报意图、跨页三态多选与批量工具条、列设置、窄容器堆叠）与三态权限树（只接叶子权限码、搜索保留祖先、WAI-ARIA 树键盘）。详见仓库根 CHANGELOG。
- 新增 `FlareMetricTile`、`FlareChartCard` 与类型 `FlareChartPoint`（`./components`）：仪表盘指标卡与柱状 / 折线图卡片，纯 SVG、只用 token，数值同时以文字提供。详见仓库根 CHANGELOG。
- 图片、视频、文件保存后，下载键变成「在文件夹中显示」；宿主发现文件被删后传回 idle，键回到下载。收发两侧的消息时间都在右侧。详见仓库根 CHANGELOG。
- 新增 `useMessageMediaSaves`（宿主只接 save / isSaved / reveal）；`FlareFileMessage` 新增 `reveal` 事件，`VideoPlayerModal` 新增 `saved` + `reveal`；`MessageMediaDownloadUiState` 从 `./contracts` 导出。
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
