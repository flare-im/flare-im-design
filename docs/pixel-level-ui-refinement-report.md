# Pixel-Level UI Refinement

日期：2026-09-11。范围：`packages/vue-im-ui`、官网预览与回归，以及真实消费者 `flare-core-web-app`。

本报告只记录本轮实际修改与验证，不把工作区既有改动、原生编译或模拟视口等同于本轮四端真机视觉验收。

## 1. Composer Surface Root Cause

问题来自多套布局和绘制规则叠加，不是单纯半径过小：

- 原有通用 Composer 样式同时作用于 studio 版本；输入行的伪元素产生左侧焦点竖线。
- Naive Input 的背景、内部 border/state-border 与外层编辑器重复绘制。
- 工具栏继承旧的绝对定位与位移，多行、回复、附件出现时可能脱离容器。
- 应用 `chat-composer-stack` 再叠加背景、边框、阴影与模糊，形成另一层视觉边缘。
- 回复、提示与输入框分别绘制边界，导致同一个编辑区像多个面板拼接。

修复位置是组件库的 `EnhancedComposer.vue`、`composer-studio.css`；消费者删除覆盖，不再修饰库内部节点。

## 2. Surface Ownership

| 层级 | 职责 | 外边框／背景／圆角 |
| --- | --- | --- |
| Composer root | 安全区、弹出面板定位、外部布局 | 仅工作区底色，不重复编辑器边框 |
| `.composer-field` | 编辑器主 Surface | 唯一背景、1px border、radius、完整细边框焦点态 |
| Context / status / uploads | 状态与附件内容 | 区域透明；附件缩略项是独立重复项 |
| `.composer-editor-area` | 排列格式、输入与工具栏 | 透明、无外边框 |
| Textarea / rich editor | 文本与 caret、自动增长 | 透明，无额外输入框边界 |
| Toolbar | 按钮排列与 inset divider | 透明，无独立外圆角 |
| Drag hint | 同一 field 内的提示 | 内缩 1px、继承曲率、不再增加大边框 |
| Voice mode | 替换文本编辑器 | 文本 field 隐藏，仅录音 Surface 可见 |
| Emoji / More panel | 独立弹层 | 拥有自己的合法 Surface |

## 3. Border Fix

主 field 四边统一 1px；保留 `border-box`。内部 Naive border/state-border 和 textarea 背景不再覆盖外边界。工具栏回归正常布局流，去掉继承的绝对定位与 transform。主 field 不用 `overflow:hidden` 遮掩问题。

## 4. Radius Fix

编辑器使用现有 `--flare-size-radius-lg`，未引入按角拆分的新 Token。拖入提示使用外半径减去边框厚度；弹层与重复附件项遵循各自 Surface 的语义半径。Input、Textarea、Select 和 BottomSheet 补齐收缩与 border-box 约束。

## 5. Focus Fix

删除 `.composer-input-row::before` 的局部焦点装饰。focus-within 在 field 上以品牌色突出原有 1px 边框，不再叠加 3px 外光圈；内部按钮使用内缩焦点轮廓。SearchBar 保留完整容器焦点环；FilterTabs、Select 选项和操作弹条使用 inset focus，避免滚动／裁切父层截断。禁用编辑器不会留下活动焦点装饰。

## 6. Input / Toolbar Integration

格式栏、输入区、状态、回复与底部按钮都放入同一个 field。分隔线左右 inset，不触碰圆角。桌面单行可同行排列；多行、有 context 或窄容器时工具栏自然换到下一行。保留富文本、表情、@、语音、图片、More、发送和展开能力。

## 7. Icon Alignment

工具栏主图标统一引用 20px icon Token；发送图标采用 `(1px, -1px)` 的光学补偿，语音／图片仅作 0.5px 纵向补偿。常规桌面按钮为紧凑固定尺寸，H5 主操作区为 44px；粗指针下附件移除／重试、回复关闭及格式按钮也使用 44px 命中区域。保留各图标可访问名称。

## 8. Auto-Grow

默认单行桌面 field 约 48px，不接受父 flex 拉伸。行高 24px，普通输入到 144px 后内部滚动；展开模式有独立视口上限。真实消费者测试输入 14 行并断言内部滚动和高度上限，草稿没有被发送或清空作为测试捷径。

## 9. Responsive

组件同时使用视口与容器约束：窄工作区不能仅因桌面 viewport 就强制同排布局。真实消费者覆盖 1440、1024、768、390 宽度，检查文档无横向溢出、工具栏在 field 内、编辑器在视口内。

Web App Header 改为直接使用 `FlareConversationHeader` 的自适应操作分配。桌面保留常用入口；窄屏只保留首要操作，其余进入库的 More 菜单。SDK 信令、消息搜索、构造器、详情及多选回调继续由应用处理。

## 10. Dark Mode

主 Surface、边框、divider、focus、附件进度全部来自语义 Token。去掉消息气泡的额外白色 inset 高光与叠加阴影。附件弹窗使用库 Button / Textarea，避免混用不同的按钮前景色。应用旧的浅／深两套颜色别名改为引用组件库当前主题。

原生缩放截图复核又发现回复引用标题／摘要继承旧浅色硬编码，已改为库 text.primary / text.secondary，并对两种主题的实际计算颜色增加断言。

官网覆盖桌面／H5 的 Composer、表单、附件弹窗和 Sheet 明暗截图；六个品牌主题及三组深色品牌消息链回归仍保留。

## 11. H5

保留 `safe-area-inset-bottom`，编辑器自身圆角不由安全区层覆盖。输入、按钮与附件在 390px 下不横向溢出。增加 390×420 的缩短可视区域模拟检查。实际 iOS／Android 系统键盘、输入法候选区及真机浏览器 chrome 属于剩余人工验证项，不能由 Chromium 视口模拟代替。

## 12. Global Surface Audit

| 组件 | 结果／本轮处理 |
| --- | --- |
| Button / IconButton | 保留库尺寸与焦点规则；检查明暗边缘、固定布局，无应用内部覆盖 |
| Input / Search | `min-width:0`、border-box、透明内输入、完整焦点环 |
| Textarea | 字数计数移出绝对覆盖层，放入自然流，不覆盖末行 |
| Select | 窄父级可收缩，选项 border-box、长文案可换行、内缩焦点环 |
| Menu / Popover | 首尾 hover 在曲率内；操作条统一语义色，键盘焦点可见 |
| Dialog / Drawer / BottomSheet | 统一 Surface 背景与上缘半径，保留安全区和焦点恢复 |
| ConversationItem / Header | 库承担选中态、身份与操作布局；应用改为直接消费 |
| MessageBubble | 移除冗余内阴影；失败尾部跟随同一背景变量 |
| File / Voice | 保留 canonical 内容视图；embedded voice 不再另画内部卡片边框 |
| Image / Video / ImagePreview | 图片和 overlay 由同一媒体层裁切；H5 解码与视口测试 |
| Composer | 单一 owner、正常流工具栏、context 与输入完整整合 |

## 13. Dialog / Menu

将消费者附件预览迁入 `FlareMediaComposerPreviewModal`。应用仅传入文件的可展示信息和回调；文件上传、File 对象与 SDK 仍属于宿主。弹窗使用库控件、共享中英文文案、视口高度上限和内部滚动。loading 时禁止重复提交、取消、遮罩及 Escape 关闭；空选择不能提交。

Select 桌面下拉与 H5 Sheet 均验证最后一个选项的焦点，Sheet 验证 Escape 关闭与焦点返回。截图覆盖弹窗、表单、底部面板在两种宽度／两种主题下的边缘。

## 14. Message Bubble

继续直接使用库 MessageList / MessageMeta / MessageStatus / 内容组件。普通气泡仅保留语义边框和单层轻阴影；气泡 body 与 tail 使用同一填充变量，失败态也同步。Sticker / emoji 的 chromeless 路径不新增透明边框。发送／已读／时间的颜色不在 Web App 另写样式。

## 15. Media

附件预览提供图像／视频 contain、文件信息、图组、说明输入和发送回调。图库缩略图与索引／标题共用裁切层。Composer 上传项具备 thumbnail、progress、remove、retry；进度颜色修复为各浏览器独立伪元素规则，避免无效选择器组合退回绿色 UA 样式。drag/drop 复用应用现有媒体预览和发送流程。

## 16. Web App Override Cleanup

- 删除应用侧附件预览组件及其视觉样式，改为库导出。
- 删除输入／按钮／选择器的全局 radius `!important`、搜索抽屉 deep/global 覆盖、Composer 背景／阴影／边框补丁。
- 消息搜索使用库 SearchBar、FilterTabs、SearchResults、EmptyState、StatusBanner，仍调用原 SDK 搜索和定位逻辑。
- 消息／Pin 标签、空会话、连接及同步提示使用库控件。
- 消息参数表单与转发标题改用库 Input / Textarea / Checkbox，不再保留自绘输入框 CSS。
- 应用 `chat.css` 仅保留布局、滚动区域、原生隐藏文件 input 和业务列表排列。
- 应用没有 `:deep` / `::v-deep` 或消息、Composer 的内部视觉覆盖；剩余 `!important` 仅用于全局 reduced-motion。
- 保留的 inline style 仅为设置弹窗 max-width 与实际测量的 Composer 占位高度，不影响控件 border/radius/background/font/icon。
- SDK Lab 诊断信息与业务数据排列仍由应用组合；没有将 SDK 业务迁入设计库。

## 17. Visual Regression

测试入口：

- `website/tests/visual-regression.spec.ts`：10 个 Composer 状态基线、完整焦点与边框断言、DPR 1/1.25/1.5/2，以及 90/100/110/125% CSS layout zoom 几何检查。
- `website/tests/native-zoom.spec.ts`：隔离 Chromium 原生 90/100/110/125% tab zoom，两种主题共 8 张截图；检查实际 zoom、devicePixelRatio、完整 focus、边框和横向溢出。测试扩展不安装到用户浏览器，不随组件库发布。
- `website/tests/surface-integrity.spec.ts`：12 个表单／附件弹窗／Sheet 基线，4 组主题与宽度交互检查。
- `EnhancedComposer.test.ts`：19 项能力／状态／语音生命周期／拖入边界测试。
- `FlareMediaComposerPreviewModal.test.ts`：4 项发送、取消、loading、空数据测试。
- 消费者 `tests/e2e/pixel-surface.spec.ts`：隔离账号的真实服务器双向收发、已读、搜索定位、四宽度截图、缩短 viewport、auto-grow、标题菜单、文件拖入与取消。

真实服务测试通过已有开发代理访问服务器 HTTP 网关，WS 使用服务器入口。测试账号以 `pw-pixel-` 开头，不使用当前用户账号发送消息，也不改变服务器配置。失败的首次本机默认地址与跨域尝试不计为通过；最终代理路径的完整回归以实际结果为准。

原生缩放采用 [Playwright 官方扩展测试方式](https://playwright.dev/docs/chrome-extensions)，通过 [Chrome tabs.setZoom](https://developer.chrome.com/docs/extensions/reference/api/tabs#method-setZoom) 控制隔离页面；不是用 CSS zoom 或 pinch 模拟冒充浏览器缩放。原生缩放使用整视口截图，避免 locator 截图在该模式下出现坐标裁切偏差。

已完成的门禁：Vue 49 文件／289 测试；Web SDK／消费者 10 文件／41 测试；设计系统 32 项检查（包含 spec、tokens、生成文件、性能合同及官网构建）；Flutter analyze 与 351 测试；Swift 170 测试；Android testDebugUnitTest / lintDebug / assembleDebug；四端独立消费者 fixture；Web App 生产构建和 800KiB bundle budget。

最终非更新模式官网回归：56/56 通过（41.1 秒）；真实服务 Web App Playwright：9/9 通过（19.2 秒）。Vue 类型检查与 204 个 SFC 编译通过；Web App 类型检查、生产构建、bundle budget 通过。四端独立消费者在最终源码上再次全部通过；设计库与 SDK 两个仓库的 `git diff --check` 均通过。

原有 5 张 RC 基线经人工差异复核后更新，差异对应本轮输入区布局、消息元数据与气泡几何调整；没有放宽截图误差阈值。新增 18 张 Composer（含原生缩放）和 12 张核心 Surface 基线已登记在视觉回归清单。回复颜色这种小于原有容差的变化也同步更新基线，并单独执行非更新模式复验。

本地入口：Web App `http://127.0.0.1:1430/#/chat`；Composer 专项预览 `http://127.0.0.1:4175/resources/composer-surface-regression`。两者均已确认 HTTP 200，开发服务保持运行。

截图证据位于 `tests/visual/vue/baselines/`；真实页面证据位于消费者 `test-results/pixel-surface-real-SDK-con-4e998-poser-across-desktop-and-H5-chromium/`。后者是本地测试产物，下一次 Playwright 执行会重建，不作为稳定文档资源提交。

## 18. Remaining Micro P2 / P3

本轮已知的明显 P2（断边、局部 focus、工具栏越界、重复 Surface、计数覆盖、窄屏 Header 拥挤）已处理。保留以下边界，不宣称全环境像素完全相同：

- P3：WebKit、Firefox 和物理 Retina 显示器的抗锯齿差异仍需平台实机复核。
- P3：已补齐 Chromium 原生 tab zoom；WebKit／Firefox 的原生缩放与触屏 pinch zoom 仍待各自环境验证。
- P3：系统软键盘、中文输入法候选窗口、安全区动态变化仍需 iOS／Android 真机走查。
- P3：SDK Lab 的业务诊断信息密度可另作专项优化；本轮不扩展通讯录或关系链功能。

### Design Director 评分

评分为本轮代码与截图复核的主观结果（10 分制），不是机器视觉测量；未覆盖的真实设备项不打满分。

| 项目 | 评分 | 依据 |
| --- | --- | --- |
| Surface Integrity | 9 | 单一编辑器 owner，内部层透明 |
| Border Continuity | 9 | 四边 1px、无伪元素竖线 |
| Radius Consistency | 9 | 语义半径和明确裁切层 |
| Focus Integrity | 9 | 容器完整环、菜单 inset focus |
| Icon Optical Alignment | 9 | 固定尺寸、光学修正和 canonical 图标类型约束 |
| Text Baseline | 9 | 统一行高，计数自然流 |
| Divider Precision | 9 | inset divider 不接触圆角 |
| Composer Geometry | 9 | compact default、正常流 toolbar |
| Composer Auto-grow | 9 | 多行增长与滚动上限断言 |
| Composer Toolbar Alignment | 9 | 子节点边界测试和四视口截图 |
| H5 Composer | 8 | 390px 与缩短 viewport；真机待验 |
| Dark Mode Edge Quality | 9 | 明暗基线、去除 inset 亮边、回复语义色 |
| Browser Zoom Robustness | 9 | 4 档 CSS layout zoom 与 4 档 Chromium 原生缩放 |
| High DPI Quality | 8 | 4 档模拟 DPR；物理屏待验 |
| Message Bubble Geometry | 9 | tail 与 body 同源填充 |
| Dialog/Menu Geometry | 9 | 四组弹层截图与焦点恢复 |
| Media Clipping | 9 | 媒体与 overlay 共用裁切层 |
| Global Micro Consistency | 8 | 核心面板已收敛，其他浏览器待验 |
| Web App Style Ownership | 9 | 通用控件、消息、Header、Composer 库所有 |
| Anti-AI Restraint | 9 | 删除装饰性阴影／渐变，保留 IM 工作界面密度 |

## 2026-09-11 输入框与持续抖动修复

- Composer 焦点态仅突出原有 1px 品牌色边框，去掉 3px 外光圈；展开时取消编辑区和工具栏之间的伪元素分隔线。内部按钮的键盘焦点提示保留。
- 持续抖动根因：ConversationHeader 用 `ResizeObserver.contentRect.width` 判断紧凑模式，而两种模式的横向 padding 不同。在真实 Web App 的 586px 聊天区，头部在 61px / 65px 高度间反复切换，推动整个时间线。改为监听、测量不随内部 padding 变化的 border box；旧浏览器使用外框尺寸回退。
- 气泡悬停的 `translateY(-1px)` 也会产生局部跳动，已去除；消息操作工具栏和新消息入场动效保留。
- 展开输入框不再对已关闭的面板重复发送 `toggle-panel(null)`，避免宿主误触发滚动到底部。已有面板仍正常关闭一次，草稿不变。
- 增加 559/560/576/586/591/600px 断点连续帧测试、明暗/桌面/H5 展开态截图、悬停与键盘焦点几何检查，以及正常动效下长时间线的输入区伸缩检查。原生缩放仍覆盖 90/100/110/125%。
- 真实服务隔离账号验证通过：登录、发送/接收、已读、搜索、富文本、附件预览、四种窗口宽度、展开/收起、浏览历史时保留位置，以及与录屏一致的 1030px 窗口。每种布局状态采样 180 帧，收敛后的几何变化小于 0.1px。
- UI 修复全部在共享 Vue 组件库内，Web App 仅增加回归验证；没有加入应用级视觉覆盖，没有修改 SDK、协议或存储实现。Flutter / Android / iOS 不受此次 Vue 尺寸观察与 CSS 修复影响，未重跑原生设备验证。
