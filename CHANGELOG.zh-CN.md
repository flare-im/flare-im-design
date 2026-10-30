# 更新日志

## 2.0.0（未发布，发布阻塞）

这是目标 Stable 版本，不是已发布版本。包元数据继续保留 2.0.0-rc.1，全部发布门禁和必要审核完成前禁止提升版本。

### 设计系统与跨端组件

- **通话记录卡片与通话页一致性**（契约与四端 Kit）。新增 `CallRecordCard`（Vue / Flutter `FlareCallRecordCard`、SwiftUI `CallRecordCardView`、Compose `CallRecordCard`）：媒体图标、一行按查看者视角的状态、媒体名称，以及「加入」（进行中的群通话，`canJoin`）或「回拨」（已结束的单聊，`canCallBack`）；`disabled` 去掉操作，`busy` 显示处理中。规则是新的共享向量 `spec/call-record-vectors.json`（状态、被叫未接的危险色、操作、mm:ss / h:mm:ss 时长），四端共跑；中英文案（Vue `callRecord.*`，原生 `FlareStrings` 的 `callRecord*` 与 `strings/en.json`）。1:1 `CallView` 在 Flutter、SwiftUI、Compose 上支持最小化（`onMinimize`，宿主传入才绘制）。**破坏性**：Flutter `FlareGroupCallView.state` 与 Compose `GroupCallView(state:)` 改为 `FlareCallState` 枚举，不再接受字符串。
- **已读名单分页状态、函数式文案的英文、「我」页内置项副标题与合并转发条目文字**（契约、Vue 与 Compose；SwiftUI 与 Flutter 按同一份表跟进）。`spec/read-receipt-list-vectors.json`：已读名单不带界面的分页状态——打开即两栏各取第一页，按栏翻页，整张名单的状态，换消息时丢弃在途结果（Vue `useFlareReadReceiptList`、Compose `rememberFlareReadReceiptListState`；宿主只给一个取页函数）。`strings/en-formats.json`：FlareStrings 每个函数式字段在给定参数下的中英文（含单复数），Compose 英文预设已全部覆盖。`flareMeMenuSections` 按项 id 给内置项副标题，与插件项相同（`spec/me-menu-vectors.json` builtin-summaries）。合并转发条目的 `plainText` 是核心给的可读文字，按正文摘要的读法画；抽屉里没有名字的发送者头像画「?」（`spec/message-forward-vectors.json` senderInitials）。
- **已读名单分页、渲染器拿到发送者、红包已退回、币种小数位、「我」页菜单、合并转发记录与复数**（契约、Vue 与 Compose；SwiftUI 与 Flutter 按同一份向量跟进）。`spec/read-receipt-vectors.json`：ReadReceiptSheet 标签数字只取宿主传的摘要人数（`readCount` / `unreadCount`），不取已取到的名单长度；整张名单的 `state`（读取中、失败可 `retry`、不可查看）；两栏各自分页（`readHasMore` / `unreadHasMore`、`loadingMore`、`loadMoreFailed`、`loadMore(column)`）；宽度随容器，放进 Kit 面板时不画外壳并声明自带标题，fill 模式下标题不重复。自定义渲染器拿到 `senderId` 与 `senderName`。RedPacketOpenSheet 新增 `refunded`；RedPacketComposer 新增 `currencyExponent`（0 / 2 / 3 位小数，`flareRedPacketAmountMinor` 用整数运算换算最小单位）。`flareMeMenuSections(menu, labels, summaries)` 把社交 SDK 的 `features.meMenu` 变成设置分组（`spec/me-menu-vectors.json`）。图标注册表追加 `wallet`（109 个），不认识的图标名四端都画 `plugin` 字形，不再画问号（`flareIconNameOrFallback`）。Compose 画合并转发记录（`FlareForwardContent`，`spec/message-forward-vectors.json`，形态同 Vue ForwardView）。计数文案按 CLDR 复数取形态（`spec/plural-vectors.json`：Vue 消息值 `{one, other}` 由 `Intl.PluralRules` 选，原生 `<field>One` 字段按共享规则表选），英文写「1 vote」。choices 块不再画 total（它只是百分比的分母），「N 票」只用于选项。Compose 插件卡片的 ⋯ 键贴在标题行尾。Vue 导出 `useFlareContentSelection`。不兼容改动：Vue `flarePluginEntryGroupHeader` 的第二个参数改为 `(count) => string`。
- **消息表面、元信息位置、回执与分组成为共享契约；插件卡片脱离气泡；红包第五版与插件页面宿主**（契约与四端 Kit；Flutter 另有 `reply` 与桌面右键 `contextMenu(message, position)`，Compose 有 `avatarTap`，SwiftUI 的 MessageList 接收 `contextMenu` 菜单模型）。新增 `spec/message-surface-vectors.json`、`spec/message-meta-placement-vectors.json`、`spec/message-receipt-vectors.json`、`spec/message-grouping-vectors.json`，扩充 `spec/plugin-view-vectors.json`（⋯ 菜单、分组名单、七种不可用原因、只读副本）与 `spec/red-packet-vectors.json`（卡片不显示金额、角标与「给 某某」、已退回、浮层入口、按 `currencyExponent` 格式化金额、按 `viewerRole` 的详情）。新组件 `PluginPage`。不兼容改动（无别名）：渲染器登记 `bare` 改为 `surface`，`MessageStatusState` 删除 delivered 与 retrying，`FlareRedPacketCard` 删除 `amount` / `kindLabel`，`FlareRedPacketDetail` 改收 `details`。
- **插件页面读取数据并发出页面动作；徽标与多选上限**（契约与 Vue；原生三端按同一份向量跟进）。
  - `spec/plugin-view-vectors.json` 新增徽标、多选上限与插件页面的规则，以及 `maxSelections`、`pageViews`、`pageActions`、`pagePaging`、`pageFilters` 五段。
  - `PluginPage` 接收 `page: {pluginId, page}` 与带 `data` 的视图。页面里执行的每个动作都发出页面动作请求 `{page, data?, row?, selection?, formValues?}`，宿主原样交给 `invokePageAction`。
  - 页面上的 rows 四端都画成列表：徽标与第一格、其余单元格、动作键。同一个 key 只画一次，rows 随页面分页。
  - rows 块的 select 筛选画成 FilterTabs，`filters` 由宿主持有，选择时发出 `filter(values)`。
  - 不可用的页面显示原因，并保留宿主标题。
  - entries 与 rows 带 `badge {text, tone}`，用 Kit 标签画。
  - 带 `maxSelections` 的多选在草稿选满后禁用其余选项，并显示「最多选 {n} 项」。
  - 不兼容改动：删除 `PluginPage.openDetail`，因为页面视图没有详情。
  - 四端都已实现。刷新结束也会忘掉已请求的游标；只有发起动作的那一行转圈。
  - FilterTabs 四端新增 `enabled`；filled 胶囊保持画出来的尺寸，命中区补到 `layout.touchTarget`。Vue 越过胶囊而行不变高，原生给每个胶囊一个触达区大小的格子。
- `FlareAuthShell`（四端）与 `FlareSchemaForm`（Vue）补上契约（`spec/components.json` 的 AuthShell、SchemaForm），并有文档页与预览；两者早已导出，五个 flare-social 应用的登录页都在用 `FlareAuthShell`，API 不变。删除 Flutter `FlareStaticAssetImage`：`FlareStaticImage` 接管选择器卡片与行内表情后它就没有使用者，冻结素材首帧改用 `FlareStaticImage(image: AssetImage(path, package: …))`。Flutter 位置消息的默认地图链接经平台模块（`flareTargetPlatform`）取平台，Compose 浮层窗口的状态栏调用移进 `FlarePlatform.kt`，组件不再自己读平台或 API 级别。
- 新增 `FlareFilterBar`（查询条件栏）、`FlareDescriptionList`（描述列表）、`FlareCodeBlock`（代码块）与 `FlareTag`（标签），`FlareDataTable` 支持游标分页，`FlareDangerConfirm` 支持审计原因与输入确认，`FlareStatusBanner` 支持可关闭的通知（仅 Vue，原生端 N/A：没有原生 App 提供管理控制台，契约 `notes` 里写明）。补齐控制台剩余的 kit 缺口（SaaS v4 R5-3）：查询栏、详情抽屉、原始报文、状态列、Core 游标检索与需审计的写操作都能用 kit 组合。查询条件栏把带标签的字段放进按自身宽度换行的网格，查询 / 重置在最后一行末尾，不常用的字段收进「更多条件」并在键上写出其中几项已填（`moreActiveCount`、`v-model:expanded`）；单行文本框里回车上报 `search`，自己处理回车的控件（展开的组合框、输入法组字、多行文本框、按钮）保留它；它是具名 `search` 地标而不是 `<form>`，`actions` 里宿主的键不会误提交。描述列表是真正的 `<dl>`，1–4 列按自身宽度收拢（标签在旁或在上），空值显示「未设置」（屏幕上是横线，0 是值），可用 `item-<key>` 自绘某一行，标识符可复制（`copy(key, copied)`）。代码块把报文或代码原样放进限高、具名、可聚焦的滚动框，带复制键（`copy(copied)`），不做语法高亮。标签沿用 `FlareTone` 语义色调，文字色写在该色调 6% 的底上，单测按浏览器实际绘制的整数通道值计算，各品牌明暗模式都 ≥4.5:1（最低 4.64:1；8% 时浅色警告标签实绘只有 4.49:1，由 axe 扫描发现）。`FlareDataTablePagination.total` 改为可选：不传即游标分页 —— 只显示页码，上一页 / 下一页每次一页，下一页由新增的 `hasNext` 决定，`aria-rowcount="-1"`。`FlareDangerConfirm` 与 `useFlareConfirm` 新增 `reason`（`FlareConfirmReason`：label、placeholder、hint、`maxLength`、按 UTF-8 计的 `maxBytes`、`optional`）与 `confirmPhrase`；两者满足前确认键不可用，`confirm` 上报 `{ reason }`（`FlareConfirmInput`），呈现器把它交给 `action`，失败时保留已输入内容；每个确认请求带 `id`，被替换的对话框从空白开始。`FlareStatusBanner` 新增 `title`（正文上方加粗的主题）与 `dismissible`（48 px 关闭键，名称取组件库的「关闭」，上报 `dismiss`），控制台按级别显示的平台公告即可用状态条；不传时渲染不变。`FlareNavigationItem` 新增 `href`：`FlareAdaptiveNavigation` 把它画成真正的链接，普通点击仍上报 `navigate`（并拦下默认跳转），Cmd / Ctrl / Shift 或中键点击交给浏览器，控制台保留「在新标签页打开」；禁用项仍是按钮；`href` 先过新增的 `safeNavigationHref`（`./contracts`：同源路径、`#…`、`?…` 原样保留，其余必须是 `safeExternalUrl` 接受的显式 http/https，`//host`、`/\host` 与裸词一律拒绝并退回按钮），并登记在 `spec/security-boundary.json` 的自跳转组件里。新增组件令牌 `--flare-component-description-list-label-width`、`--flare-component-filter-bar-field-min-width`、`--flare-component-code-block-max-height`；Vue 词条 `filterBar.*`、`descriptionList.*`、`codeBlock.*`、`dataTable.pageOnly` / `rangeOpen`、`dangerConfirm.reasonTooLong` / `phraseLabel`。新组件都有文档页与在线 demo，DangerConfirm demo 增加了审计确认。
- 新增 `FlareDataTable`（数据表格）与 `FlarePermissionTree`（权限树）（仅 Vue，原生端 N/A：没有原生 App 提供管理控制台，契约 `notes` 里写明）。表格把宿主的行放进真正的 `<table>`（显式 table 角色）并只上报意图：可排序表头依次升序、降序、回到宿主顺序（`update:sort`）；上下页与每页条数发 `update:pagination`；表头三态复选框选中本页并保留其他页的 key（`selectedKeys`），选中不为空时出现批量工具条，它是一个上下文层（Escape、平台返回与组件库返回控件都会清空），宿主的动作放 `batch` 插槽；列设置（指针设备上是浮层、手机上是底部面板）把 `visibleColumns` 交给宿主持久化，且不会隐藏最后一列；单元格用 `cell-<key>` 插槽、`row-actions` 加操作列、`toolbar` 是栏的前部、`empty` 替换空态；`density` 分舒适 / 紧凑，`stickyHeader` 把表头钉在表格自己的滚动盒里。容器窄于 600px 时行堆叠成带标签的行，表头留给辅助技术，排序移到菜单。权限树只接叶子权限码（`checkedCodes`），父节点推导为全选 / 半选 / 未选；切换分组会勾选或清空其未禁用的叶子（`disabledCodes` 保持原样）；搜索保留匹配项的祖先（强制展开）与后代；是单一 tab 停留点的 WAI-ARIA 树（方向键遍历与折叠，空格 / 回车切换），`readonly` 显示仅可查看提示，一千个节点每次变化仍只遍历一次。新增类型 `FlareDataTableColumn`、`FlareDataTablePagination`、`FlareDataTableSort`、`FlarePermissionNode`；新增组件令牌 `--flare-component-data-table-row-height` / `-row-height-compact` / `-max-height` 与 `--flare-component-permission-tree-row-height`；Vue 词条 `dataTable.*` / `permissionTree.*`。两者都有文档页与在线 demo。
- 新增 `FlareMetricTile`（指标卡）与 `FlareChartCard`（图表卡片）（仅 Vue，原生端 N/A：没有原生 App 提供数据看板，契约 `notes` 里写明）。纯 SVG、只用组件库 token，不依赖图表库；空数据、单点、全零、缺数据（`null` 画成缺口或横线，不是 0）都写进契约；图表是 `role="img"`，名称是数值摘要，每个读数另有只给读屏的数据表；序列用各语气的文字色，因为填充色在暗色卡片上对比度只有 1.80–2.66:1。
- 图片、视频、文件下载后，下载键变成「在文件夹中显示」（四端）：保存状态 idle / failed → 下载键，downloading → 进度，已保存 → 文件夹键；宿主发现文件被删后传回 idle，键回到下载，再下载又是文件夹。文件卡片右侧固定这个键，图片预览、图库与视频播放器右上角的键跟随列表实时状态。Vue 宿主用 `useMessageMediaSaves` 接整条流程。
- 收发两侧的消息时间都显示在右侧（四端）：媒体下方贴右边缘，气泡内在右下角；正文仍在发送方一侧。
- 原生视频消息：时长未知时不再显示「00:00」，播放键改为半透明圆盘，默认 240×135。
- **浮层收为三件套：BottomSheet、Modal、Drawer**（四端）。短任务用 BottomSheet，`presentation` 默认 `auto`：手机形态是底部面板，其它形态把同一份内容交给新组件 **Modal**，打开时判定一次；长驻的次级内容（详情、设置栈、资料编辑）宽布局用新组件 **Drawer**、手机上是页面；全局搜索手机上是整页、其它形态是定高的 Modal。符号：Vue `FlareModal` / `FlareDrawer`（及 `FlareDrawerPlacement`）、Flutter `FlareModal` / `FlareDrawer`（`show`、`showAdaptive`）、iOS `ModalView` + `.flareModal` / `DrawerView` + `.flareDrawer`、Compose `Modal` / `Drawer`。形态判据由 kit 给出：Flutter `flareCapabilitiesOf(context)`、iOS `EnvironmentValues.flareCompactOverlays`、Compose `flareCompactOverlays()`。每个浮层都是有名称的模态对话框（标题 → `label` → 新增的 `drawerLabel` / `modalLabel` 兜底），忙碌时锁住关闭，遮罩用新令牌 `colors.scrim`。
- **破坏性（枚举）：`FlareSheetPresentation` 删除 `dialog` 与 `drawer`**（四端），只剩 `auto | sheet`。居中框用 Modal，侧边面板用 Drawer。Vue 的 `.flare-sheet--dialog` / `--drawer` 样式删除；三种面都是 `role="dialog"`，带 `data-flare-presentation` 与共用遮罩类 `flare-overlay-scrim`。
- **破坏性：Flutter 公开的对话框类并入 `FlareModal`**（无别名）：`actions` → `footer`、`content` → `child`、`maxWidth` → `width`、`title` 改为字符串、`contentScrollable` → `scrollable`；原 `show` → `FlareModal.show(framed:)`，原 `prompt` → `FlareBottomSheet.prompt`。`FlareBottomSheet.show` 新增 `titleHidden`、`dismissible`、`busy`、`maxHeight`，默认 auto（宽度 600 及以上是 Modal）；`FlareDangerConfirm.show` 遵循 auto，按钮文案取 FlareStrings；`FlareSearchPanel` 新增 `autofocus` 与 `layout`。
- iOS `flareBottomSheet` 新增 `isPresented:` 重载与 `titleHidden`、`presentation`、`dismissible`、`size`（`.fitted` / `.large`）、`maxHeight`；`FlareLayerDismissDisabledKey` / `.flareLayerDismissDisabled(_:)` 在忙碌时锁住浮层；`FlareFeedback` 的确认与提示输入、`FormSheetView` 遵循 auto，不再固定 medium 档位；`FlareGroupDetailView` 的子步骤改为 kit 面板，不再用系统 alert 与 confirmationDialog。Modal 与 Drawer 在 iOS 16.4+ 是透明全屏覆盖层加 kit 遮罩，更低版本与 macOS 回退为系统面板。
- Compose `BottomSheet` 新增 `titleHidden`、`maxHeight`、`presentation`（默认 Auto），内容拿到有界约束并自己负责滚动；`FormDialog` 新增 `presentation`；`DangerConfirm` 改由 `BottomSheet(Auto)` 承载，不再是 Material3 `AlertDialog`；浮层窗口关闭窗口 dim、改画 `colors.scrim`；toast 画在最上层浮层窗口里；`CommandPalette` 宽度按令牌夹紧；`FlareGroupDetail` 的 Material3 面板与 alert 改为 kit 浮层。
- Vue 浮层焦点：初始焦点跳过标头控件（`data-flare-overlay-chrome`）落在内容里，焦点在面外时正向 Tab 拉回面内，关闭与卸载时焦点还给打开它的元素。底部面板的离场动画恢复播放，减少动态效果时遮罩也不淡入淡出，顶部圆角改为 `radius-2xl`、最大宽度改为气泡最大宽度令牌；命令面板背景改读 `colors.scrim`；合并转发查看器改用 `FlareDrawer`；`responsive.css` 里按窗口改写 sheet-width / sheet-height 的两处死代码删除（`--flare-component-sheet-dialog-width` 仍生效，现由 FlareModal 读取）。

- Vue、Flutter、Compose、SwiftUI 通过契约和生成链路共享语义 Token、六套品牌主题及明暗模式。
- 可选 AppKit、Workspace 和响应式布局消费公开组件，不绑定具体 SDK。
- 原生消息分发器统一调用公开消息体；文本、语音、文件内容不再创建第二层气泡。
- Vue 运行时文本与投票复用公开消息体。文本链接使用禁用原始 HTML 的统一 Markdown 渲染器，修复属性拼接注入风险。
- 原生投票、任务、日程、小程序、公告、链接保留类型化字段；未知投票结果不再伪造为 0%。
- Swift 远程贴纸支持 GIF/WebP 解码，并尊重减少动态效果设置。
- Flutter Core 示例移除仅浅色有效的主题别名，读取当前语义主题；删除无调用的旧回复条与任务状态配色。

### 无障碍与响应式

- Swift 消息正文支持动态字体；名片、投票、任务、位置消息不再强制过大的最小宽度。
- 文件打开与下载按钮不再互相嵌套；只读投票不显示可选择的伪操作。
- 保留媒体元信息、输入框表面、H5 图片预览、键盘、主题及多尺寸回归。

### 发布流程

- 新增 release:check，串行执行检查并保留单项日志、部分结果、包内容检查及消费者验证。
- 诊断筛选运行不能认证发布；缺少自动化证据与真正的硬件审核分开记录。
- 补充公开 API 审查表、五端功能矩阵、迁移指南和 Stable 就绪报告。

### 破坏性变更与迁移

- 浮层三件套（2026-09-28）：`FlareSheetPresentation` 的 `dialog` / `drawer` 删除、Flutter 对话框类并入 `FlareModal`、iOS `flareBottomSheet` 签名扩展。逐端迁移见 docs/release/migration/2.0-rc-to-2.0.md §4r。
- 消息内容组件不再负责气泡表面，应通过 MessageBubble 与 MessageMeta 组合。
- VoteOption.pct 改为可选或空值，未知结果不能用零替代。
- 只使用公开包入口和语义主题 Provider。详见 docs/migration-to-2.0.md。

### 已知限制

- 原生残留展示所有权、内置消息完整映射、媒体动作接入、运行时与无障碍证据，以及真机审核仍阻塞 Stable。
- 组件目录与签名覆盖不等于运行时完全一致，禁止据此宣称 Stable。

## 2.0.0-rc.1

- 建立四端生命周期、MessageStatus、MessageMeta、能力、消息内容、动作和表单键盘契约。
- 增加共享场景、视觉门禁、无障碍设备矩阵、性能计划、兼容性矩阵及语义状态 Token。
- 使用分层导出与依赖边界约束 General UI、IM UI 和宿主产品职责。
