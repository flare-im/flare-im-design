# 更新日志

## 2.0.0（未发布，发布阻塞）

这是目标 Stable 版本，不是已发布版本。包元数据继续保留 2.0.0-rc.1，全部发布门禁和必要审核完成前禁止提升版本。

### 设计系统与跨端组件

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
