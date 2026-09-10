# Flare IM 输入面板设计提案 · V4

## V4 当前调整

- 打开“更多”时暂时隐藏正文、格式栏、引用和附件预览，不卸载编辑器。有草稿时显示一行可点击的摘要；无草稿时不占摘要高度。
- 关闭面板或点击草稿摘要恢复正文、原展开状态和光标；输入内容与格式保持不变。从更多切到其他编辑面板也恢复正文。
- 更多面板最大高度收至 206px；即使从展开编辑进入，也先让聊天记录恢复正常可用高度。
- 富文本栏参照用户截图，图标 14px、格式文字 12px，桌面行高 32px；触屏保留 44px 热区，可横向滚动且隐藏轨道。
- 增加段落样式、下划线、引用和链接快捷入口，延续无方块的选中态。
- 浏览器已验证：更多打开时正文 display:none，草稿不变；点击摘要后正文与格式栏恢复，焦点回到消息编辑器。

## V3 当前设计（取代下文 V1/V2 的尺寸与选中态）

- 底部七工具使用等宽网格，不使用发送前的弹性留白；图标光学尺寸统一 20 × 20、24 单位 SVG 网格、1.65 线宽。字体 @、Aa 改为同一套 SVG 的 @ 与 T，避免平台字体造成视觉大小不一致。
- 常态、鼠标悬停和选中态均无方块背景；选中仅变品牌色。加号在打开面板后变为 ×。键盘导航仍保留可见焦点环。
- 富文本按钮命中高度仍为 44，图形 18、格式文字 14。当前格式用颜色和微小短标记提示，取消填充背景；更多格式也使用无底色线性图标。
- 正文调整为 14px，普通行高 1.7、展开行高 1.85，标题 15px；编辑轨道继续隐藏。视觉收紧不缩小点击区域。
- 标准手机保留六个常用入口与发送。工具容器宽低于 308 时将 @ 收入更多；低于 264 时进一步收纳音频，仍保证所有功能可达。

### V3 可操作流程

| 入口 | 交互 |
|---|---|
| 表情 | 打开/关闭、连续插入、表情/贴纸页签；直接发演示贴纸时保留文字草稿 |
| @ | 搜索成员、无匹配提示、选择后在原选区插入提及、关闭不修改草稿 |
| 语音 | 开始 → 计时 → 停止 → 预览 → 重录/模拟发送，取消或切换面板停止计时；另保留本地音频选择 |
| 图片 | 示例图片多选或本地相册 → 确认添加 → 草稿缩略图 → 移除/发送；消息区显示图片预览 |
| 富文本 | 常用格式、更多格式、当前格式提示、展开收起不丢内容 |

语音录制是有明确标签的流程模拟，不启动麦克风、不产生真实声音；图片仅保存在本地页面，不上传。已手动验证成员搜索无结果与插入、图片选择/移除、语音开始/停止/发送及草稿保留。浏览器测量七个图标均为 20px、中心点等间距、按钮背景均透明；富文本背景透明、文字 14px。JavaScript 语法检查通过。

本轮细化使用独立的 `refinement.css` / `refinement.js`，随原型首页自动加载；不修改生产四端组件。

本轮交付为可运行、可交互的 Web 模型。没有替换 Vue、iOS、Android 或 Flutter 的生产组件。四个平台按钮演示统一布局在不同容器宽度和外壳下的表现，不代表四套原生运行结果。

## 从截图发现的问题

1. **书写、布局控制、发送处于同一竞争层级。** 普通态右侧排列展开与发送，编辑框不得不让出两列宽度；展开时，这两列继续占位，形成一块巨大但狭窄的编辑区。扩大了高度，却没有有效提升书写体验。
2. **发送缺乏可识别的主操作形状。** 仅用浅紫色纸飞机表达不可发送状态，与旁边的展开图标过于接近。发送需要固定位置与可靠的点击区域。V2 按反馈保留飞机图形，以颜色和禁用语义区分状态，不依赖大色块或文字标签。
3. **富文本切换改变了整个操作地图。** 普通态展开入口在右侧，富文本态收起入口却在左下角；键盘、字号、加粗、列表、代码和链接挤在同一行，次要编辑操作与关键动作没有分组。
4. **展开态缺少上下文。** 一个几乎铺满屏幕的白框没有告诉用户正在给谁写、如何回到对话，也缺少稳定的底部操作基线。
5. **占位内容承担了错误的信息任务。** 长会话 ID 占据整行，却对写消息没有帮助。收件人应位于会话标题或展开头部，输入提示只需要“发消息…”。

## 设计选择与自我校正

考虑过“输入框、展开、发送同一行”的紧凑方案。它虽然少占一行，但正好延续了截图中的结构矛盾，特别不适合 360 宽和富文本场景，因此舍弃。

采用独立的书写区与操作行。唯一有意强调的视觉变化是：长文展开后，输入底座成为带轻圆角顶边的书写面板。其余保持 Flare 的克制白灰界面，只让紫色指向当前格式与发送动作。

```
普通：                       展开：
┌───────────────────────┐   ┌───────────────────────┐
│ 对话记录              │   │ 少量对话上下文        │
├───────────────────────┤   ╭───────────────────────╮
│ [格式栏，按需出现]     │   │ 写消息 · 林小满  收起 │
│ [发消息…          ↗]  │   │ [格式栏，按需出现]    │
│ ☺  @  ♩  Aa  ＋  发送 │   │                       │
└─────安全区 / 键盘─────┘   │ 全宽、可滚动书写区    │
                            │                       │
                            │ ☺  @  ♩  Aa  ＋  发送 │
                            └─────安全区 / 键盘─────┘
```

## 共用设计 token

| 角色 | 值 | 用法 |
|---|---|---|
| brand.primary | #7053D6 | 可发送的飞机图标、选中的格式操作 |
| brand.primarySoft | #EEE9FB | 已选工具背景、发出消息 |
| text.primary | #262735 | 正文与主要标签 |
| text.secondary | #757888 | 次级标签、工具图标 |
| bg.app | #F5F6FA | 对话底色、普通输入底色 |
| bg.surface | #FFFFFF | 编辑面板、接收消息 |

分隔线 #E5E6ED，辅助错误/警告颜色由语义 token 独立提供，不混用品牌色。正文 PingFang SC / Microsoft YaHei / system-ui，15px、约 25px 行高；展开时约 28.5px 行高；辅助字 11–12px。展示页仅在 Flare 标识使用 Georgia，不将展示字体带入聊天产品。生产跨端若要求字形完全一致，应使用同一份有授权的 CJK 字体；默认系统字体只能保证层级与指标一致。

尺寸以逻辑单位表达：Web px、iOS pt、Android dp、Flutter logical px。基础网格 4，面板横向内边距 12，输入内边距 14，输入圆角 16，发送图标 24、透明命中区 44，展开面板顶部圆角 22；可交互控件至少 44 × 44。Android 可将命中区域扩至 48dp，同时保持 44dp 视觉图形。

## 信息层级与组件契约

`Conversation → Timeline + ComposerDock → ExpandedHeader / FormatToolbar / DraftEditor / StatusNotice / ActionBar / AuxiliaryPanel`。

编辑器是唯一草稿所有者。展开、格式工具、表情、附件只是同一草稿的不同视图，不重新创建草稿。

| 状态轴 | 值 | 规则 |
|---|---|---|
| layout | compact / expanded | 只改变可用编辑空间 |
| formatToolbarVisible | true / false | 只改变工具是否可见；隐藏不剥离格式 |
| auxiliaryPanel | none / emoji / mention / voice / attach | 同时最多一个，保留输入选区 |
| draft | doc + selection + conversationId | 使用结构化文档和会话归属持久化 |
| transport | idle / typing / sending / failed / offline / disabled | 对齐已有 FlareComposerState；重连由连接状态提供 |
| capability | available / permissionDenied / capabilityUnavailable | 能力问题不阻断普通文字输入 |

事件建议统一为 draftChange、requestExpand、requestCollapse、toggleFormatToolbar、requestSend、retryMessage、requestCapability。生产发送需按 clientMsgId 对原消息就地更新；本模型以局部 DOM 演示发送、失败及重试，不连接 SDK。

## 行为规则与异常状态

- 空白：短占位提示，发送禁用但保持同一形状和位置。只有空格不能发送。
- 聚焦：轻描边提示，不改变尺寸。普通态随内容增长至约 5 行，之后在编辑区域内滚动。
- 多行：发送仍在操作行；手动展开，不因行数突然切换模式。
- 富文本：Aa 显示/隐藏格式栏。格式工具位于正文上方，发送与辅助工具在正文下方。常用栏提供加粗、斜体、删除线、有序/无序列表；更多格式提供正文、标题、引用、代码块、行内代码、链接、清除格式。
- 展开：保留草稿和格式，上方显示收件人与“收起”；底部操作行保持固定顺序。收起不是取消编辑。展示部分对话作为上下文，不以模态对话框阻断聊天。
- 发送：空白时禁用，发送中短暂显示“发送中”，防止重复提交；成功清空草稿并回到普通高度。正式版应使用 SDK 乐观发送后立即允许编辑下一条，而非沿用演示中的 550ms 编辑锁定。
- 失败：消息下显示“重试 / 删除”，重试更新同一条消息，不生成重复气泡。演示未持久化已发和失败消息。
- 离线、重连：保留可编辑草稿，显示明确说明，禁用发送；不假装成功。本模型不自动恢复网络。
- 权限拒绝：提示麦克风权限问题，文字发送可继续；不主动触发系统权限弹窗。
- 能力不可用：附件入口给出原因，不影响其他编辑操作。
- 禁言/只读：保留草稿，编辑和发送不可用，显示原因。
- 附件/语音：V2 支持本地选择图片、视频、音频、文件并显示文件名预览条，可移除，可与文字一起模拟发送。实际文件不上传、不持久化，刷新后需重新选择；录音、缩略图和上传进度未接入。

## 四端一致性与自适应约束

四端一致的是结构、操作顺序、视觉 token、状态含义、焦点与草稿规则；系统键盘、字体渲染与安全区遵守各宿主平台。

| 场景 | 约束 |
|---|---|
| 手机 320–430 | 单列聊天，发送固定在右下角；工具容器低于 300 时将 @ 收入加号菜单，低于 264 时进一步收纳音频，避免压缩点击热区 |
| 平板 600–1024 | 可双栏会话列表与聊天；编辑器占聊天列，不随整个屏幕无限拉宽 |
| 桌面 1024–1440 | 侧栏 + 聊天工作区，展开仅增长聊天列内的编辑区；保留会话上下文 |
| 宽桌面 1440+ | 聊天正文及编辑器共享阅读宽度，额外空间给会话详情；不把单个输入行拉到全屏 |

演示页面自身在手机收敛为直接交互模型，桌面展示平台和场景控制。平板及桌面生产聊天壳体未在本轮实现。

iOS 使用键盘避让与 safeAreaInset；Android 由 IME/window insets 驱动，避免父子容器重复扣除；Flutter 用 viewInsets.bottom 并统一 SafeArea 所有权；H5 使用 visualViewport 的可视高度与 env(safe-area-inset-bottom)，验证 WebView resize/pan 策略。真实键盘出现后只计算一次底部占位，不叠加 home indicator 与键盘安全区。Web 模型键盘按钮只用于验证固定占位下的空间分配。

## 无障碍与验证边界

图标按钮有中文名称、可见焦点，Aa 有 aria-pressed，输入有 textbox 与 multiline 语义，状态有 live region。纯图标不承担不可解释的关键退出动作；“收起”和“发送”使用文字。移动端 Enter 换行，桌面 Ctrl/⌘ + Enter 发送；中文输入法合成中不发送。遵守 reduced-motion。长文本自动折行，格式栏允许横向滚动；本模型不提供完整多语言词条。

必须在正式实现阶段分别验证 VoiceOver、TalkBack、动态字号 200%、原生中文 IME、真实安全区和横竖屏。这里只能验证 Web 模型，不把模拟器外壳当成原生兼容性证据。生产富文本应使用共享 RichDoc schema，使用可靠编辑器替代此演示使用的浏览器 execCommand。

## 运行

在本目录执行 `python3 -m http.server 4178 --bind 127.0.0.1`，打开 http://127.0.0.1:4178。

原型无需构建和外部资源；示例联系人及内容为虚构。刷新保留此浏览器中的草稿；点击左侧场景按钮会替换演示草稿。

## 本轮已验证

- 在桌面浏览器目视检查普通输入、富文本展开及键盘占位组合。
- 操作验证展开/收起后多行草稿保留，离线发送禁用，模拟失败后重试更新原消息为已发送。
- 在 320 × 740 浏览器视口检查展开态：页面 clientWidth 与 scrollWidth 均为 305（扣除滚动条），无横向页面溢出；发送按钮高 44，位于编辑面板边界内。极窄容器中的 @ 已收纳至加号菜单。
- 静态改动通过 git diff --check。尚未执行四端原生设备或真实软键盘测试。


## V2：以 Flutter 示例为依据的功能映射

已阅读的依据为 `flare-im-core-client-sdk/examples/flare-core-flutter-app/lib/interface/widgets/composer/` 下的 `message_composer.dart`、`composer_sheets.dart`、`composer_models.dart` 和 `rich_text_composer_formatter.dart`。CodeGraph 对该示例检索没有结果，因此直接核对源文件。

| Flutter 现有行为 | V2 设计处理 |
|---|---|
| 底部六工具：表情、@、语音、图片、Aa、更多 | 保留六入口，加上右侧小飞机；通过极窄屏收纳规则保持触控面积 |
| 表情包插入草稿；贴纸直接调用发送 | 分设表情与贴纸页签；表情可连续插入，贴纸用占位图模拟直接发送，不清空文字草稿 |
| 图片、视频、音频、文件选择 | 保留图片快捷按钮；更多内提供视频、文件和音频，本地文件名预览可删除 |
| 回复 senderName / preview / clear | 输入上方提供低矮回复条；展开收起均保留，取消回复不删除正文 |
| heading、bold、strike、italic、列表、quote、代码、link | 按常用与更多格式分组；均在同一个编辑文档上操作 |
| 关闭富文本时重置 formatting | 设计优化：Aa 只控制格式工具显示，不清除已写格式；生产落地时需明确迁移该行为 |
| 语音工具触发 audio 选择 | 目前设计为选择音频；录音入口明确处于预留状态，不声称当前已有录音能力 |
| 位置、名片、日程、任务、投票业务入口 | 在更多面板保留入口；模型未接入业务，点击给出暂不可用说明 |
| 链接卡片、小程序、话题、通知、公告 coming-soon | 标注待开放；链接卡片与编辑文字中的超链接是不同能力 |
| 会话草稿和输入状态回调 | 生产继续依赖既有会话状态；模型仅保留本浏览器文字草稿 |

### V2 交互细节

- 飞机视觉 24 × 24，触控 44 × 44，无文字标签、无默认背景。可发送紫色、空白浅灰紫；发送中 aria-busy、禁用重复提交。
- 所有文字编辑态隐藏滚动轨道，仍保留触摸、滚轮和键盘滚动能力，不能用 overflow:hidden 裁掉文本。
- 键盘占位与底部辅助面板互斥：打开辅助面板会收起模拟键盘，打开模拟键盘会关闭辅助面板。
- 展开、格式栏、回复条、附件预览属于同一编辑器；回复条及附件预览不占用正文的横向书写空间。
- 行内代码要求先选中文字；链接验证 http/https。演示保存标题、引用、代码等安全文档结构，粘贴外部内容按纯文本处理。

### V2 验证

浏览器实测发送容器宽 44、飞机宽 24，编辑区 scrollbar-width 为 none；引用回复经过展开、标题格式设置、收起后，正文仍为 h3 且回复条保持显示。JavaScript 语法检查通过。原生四端与真实媒体上传仍不在本轮交付范围。


## Voice input mode — revised prototype

Voice now transforms the existing input area instead of opening an extra panel. Desktop measurement: 80px. Mobile controls: 44px. The text draft remains independent. Click microphone to start the simulation; pause, preview/scrub, resume recording, delete with confirmation, or explicitly send. Returning to text pauses recording and marks the microphone with a draft dot. Escape has the same behavior. Timer max: 120 seconds. Playback and recording are simulations with no microphone or audio capture.

Uses the existing Web/mobile layout switch and connectivity/permission simulator. Failed first send keeps the draft; retry succeeds in this prototype. Permission denied leaves a recoverable start state.

Reference: Telegram pause/resume interaction, https://telegram.org/blog/new-saved-messages-and-9-more. The visual treatment is derived from Flare's existing composer, not copied from Telegram or Feishu. Feishu public help was consulted, but no precise current recorder layout could be verified.

Browser verified: desktop pause/resume, return-to-text draft preservation, saved voice marker, mobile paused controls. Production remains unchanged.

### Voice refinement: prioritize the clip

The primary row now contains pause/play, waveform, duration and contextual send. While recording, send is hidden; paused mode reveals send. Keyboard return, continue recording and delete live in a quieter secondary row. This intentionally trades a little height for fewer competing controls and a wider seek area. Mobile keeps 44px touch targets. No change to microphone/transport behavior: still a local interaction simulation.

### Voice minimal pass

Collapsed the secondary row into a compact overflow menu. Main row: return to text, pause/play, waveform and timer, more, conditional send. Normal status stays accessible to screen readers; errors remain visibly inline. Softer 18px glyphs and lower-amplitude waveform reduce visual weight. Desktop measured 58px; mobile verified at 390px with no overflow and 44px controls. Resume and deletion confirmation are reachable from More. Prototype only.

### Explicit start / resume and keyboard exit

Entering voice mode now shows a labeled Start recording action instead of starting automatically. Paused mode keeps labeled Continue recording visible in the main row, separate from playback. The keyboard action immediately stops timers/playback, deletes the voice draft and returns focus to the existing text draft, without confirmation. This supersedes the earlier keyboard-preserves-voice behavior. Browser verified: idle entry, explicit start, pause, visible resume, resume, keyboard exit, reopen at 00:00 with no voice draft and text preserved.


## Voice implementation · bare icons

Primary and resume controls now use transparent backgrounds and no borders, including hover. The shared Vue composer implements this inline flow and the Web app bundles that source. Keyboard exit discards recording; text draft remains. Real browser recording verification uses a synthetic microphone, avoiding personal audio capture.
