# Conversation Workspace And Header Refinement Report

## 1. Previous problems

旧聊天区域使用职责偏窄的 `ChatHeader`，会话身份不够突出，搜索、通话和 More 容易被实现层写死。Header、Timeline、Composer 像三个独立表面，宽屏消息过度分散，稀疏消息留白节奏不稳定。Bubble 自行推断连续关系，群聊头像和发送者名缺少稳定默认值，Reaction 与时间信息的层级也不够一致。Composer 在 PC 上同时常驻提及、语音、图片、富文本、Plus 等入口，削弱了输入与发送主任务。

## 2. ConversationHeader design

新增正式 `ConversationHeader`，仅消费 `ConversationIdentity`、`ConversationHeaderAction[]`、`ConversationHeaderCapabilities` 和配置对象。默认结构固定为 Leading identity、Main title/subtitle、可选上下文与 Actions；Host 可通过定向 slot/builder 替换头像、标题、副标题、动作图标或 trailing，而无需接管整个 Header。旧 `ChatHeader` 保留为兼容包装，不再作为新代码首选。

## 3. Avatar model

Identity 支持 `avatarUrl`、initials fallback、placeholder、presence、无障碍标签和可选 `avatarAction`。头像行为只由 Host 提供的数据与 capability 决定，组件不查询联系人、不导入 SDK 类型。头像动作只有在可用、可见且有处理器时才成为可交互目标。

## 4. Direct conversation behavior

Direct conversation 默认以对方头像、标题和低权重 presence/subtitle 构成身份区。默认动作预设可包含 Search、Audio Call、Video Call 和 More，但最终是否展示由 capability 与 Host 配置过滤。消息时间线默认不重复发送者名称，自身头像默认隐藏。

## 5. Group conversation behavior

Group conversation 支持群头像、成员数量或群描述作为单一副信息层。默认动作以 Search、Members/Details 和 More 为基础；群聊 incoming 消息默认显示发送者名，并在分组首条显示头像。Reference Web App 只启用其真实具备的搜索、详情和 SDK diagnostics，不伪造关系链、加成员或分享能力。

## 6. Header actions

`ConversationHeaderAction` 统一 `id`、`label`、`icon`、`order`、`group/placement`、`visible`、`enabled`、`badge`、`tone`、`intent`、`accessibilityLabel` 与 `disabledReason`。动作解析顺序为默认预设、Host 新增或覆盖、capability/removal/visibility 过滤、稳定排序；组件只抛出 intent，不执行业务。

## 7. Plus menu configuration

Plus 是独立的会话动作入口，不是固定业务按钮。Host 可完整替换默认菜单，也可删除、隐藏、禁用、分组、重排、换图标、换文案或加入任意业务动作。Vue 使用可访问 dropdown，Flutter 使用 `PopupMenuButton`，Compose 使用 `DropdownMenu`，SwiftUI 使用 `Menu`，语义保持一致而呈现遵循平台习惯。

## 8. Default actions

组件库提供 Direct 与 Group 两套默认配置，并将 Add Member、Create Group、Share 等 Plus 动作定义为可过滤默认值。省略高级配置时，`ConversationHeader(identity)` 即可获得完整身份与合理动作；Host 只声明真实 capability，未具备的动作不会显示。

## 9. Custom actions

普通动作与 Plus 动作均接受 Host 自定义项。自定义 `Order`、`Create Task`、`SDK diagnostics` 等 id 对组件库完全透明，点击后原样返回 action/intent。测试覆盖自定义普通动作、自定义 Plus 动作、删除、禁用、隐藏、重排及 capability filtering。

## 10. Overflow strategy

桌面优先展示高频 primary actions，Plus 与 More 保持独立入口；窄于 Header 可用宽度时，低优先级动作进入 More。移动端只保留 1 至 2 个必要动作，其余进入 overflow，头像和标题区域拥有更高收缩优先级。菜单关闭后焦点返回触发按钮。

## 11. MessageTimeline changes

`MessageList` 对外同时导出语义别名 `MessageTimeline`。时间线内容使用 `message.timeline.contentMaxWidth = 920px` 约束宽屏阅读宽度，incoming/outgoing 仍分别靠左和靠右。稀疏消息从顶部自然起排；Timeline 是 Workspace 唯一弹性滚动区，并保留底部 inset、滚动锚定和新消息能力。

## 12. Message grouping

新增跨端 `MessageGroupPosition`：`single`、`first`、`middle`、`last`。分组由 sender、默认五分钟时间间隔、消息类型与 system/notification 边界计算，再把明确结果传给 Bubble。Bubble 不再猜测分组，测试覆盖同发送者、不同发送者、时间间隔、系统边界与 incoming/outgoing。

## 13. Avatar alignment

Incoming 默认保留稳定 leading avatar gutter，`single/first` 显示头像，`middle/last` 隐藏头像但保持同一横向基线。Group sender name 只在分组首条显示；Direct 默认不重复名称。Outgoing 默认不显示自身头像，但 contract 支持 `showSelfAvatar`。Vue 对缺省 Boolean prop 的归一化已通过显式默认值处理，避免头像被意外关闭。

## 14. MessageMeta

时间、edited、ephemeral、delivery/read/failed/retrying 被收敛到一个低权重 `MessageMeta` cluster。Sent、Delivered、Read 使用稳定单/双勾几何，Read 使用语义色；Failed 保留可访问 retry。已移除 Bubble hover 层重复时间，只保留 separator 的分组时间与消息自己的具体时间两种清晰语义。

## 15. Reaction

Reaction 紧贴所属 Bubble 下缘，并参与消息组间距，而不是漂浮成独立卡片。selected 使用语义背景、边框与文字状态，count 保持次级层级；视觉基线覆盖 incoming group、outgoing 和 attached reaction。

## 16. Composer

Composer 与 Workspace 底部表面通过单一细分隔和一致背景连接。PC 默认 `toolbarPresentation="minimal"`，只常驻 Emoji、Plus 和 Send；图片、文件、语音、位置、联系人等进入配置驱动的 Plus 面板，语音仍可直接进入组件内录制流程。`expanded` 是显式高级预设；富文本按钮仅在 expanded 或当前 rich mode 下出现，输入、回复、编辑、上传和状态区域继续由既有语义组合。

## 17. Responsive

Header 在桌面与移动端使用同一 action model，但按可用宽度改变 presentation。Workspace 在小屏减少 context 横向 padding，并为 Composer 处理 safe area；Bubble 在移动端使用更高可用宽度比例，在桌面保持保守 max width。Reference App 已验证 390、768、1024、1440、1600 像素视口，无页面级横向滚动；非聊天工具页使用单内容区，不渲染空的中间 conversation pane。

## 18. Themes

Header、Timeline、Bubble、MessageMeta、Reaction 和 Composer 全部消费 semantic tokens。主题契约验证 Violet、Ocean、Forest、Sunset、Rose、Graphite 六品牌的 Light/Dark 组合，共 12 套；四端 token 由同一源生成，不在组件内复制品牌色。

## 19. Accessibility

Header identity 是命名区域；头像、Plus、More 和普通动作均提供语义标签、disabled 状态、tooltip 与最小触控目标。Tab 遵循视觉顺序，Enter/Space 激活动作，Escape 关闭菜单并恢复焦点。Timeline 保持消息语义，重复 hover 时间已删除；Composer 的 minimal/expanded 均保持可命名按钮、键盘发送、IME 和焦点恢复。浏览器检查覆盖可访问名称、无正 tabindex、可见焦点、reduced motion 与 forced colors。

## 20. Vue docs

官网新增或完善 `ConversationHeader`、`ChatWorkspace`、`MessageList/MessageTimeline` 与 Composer 页面。ConversationHeader 展示 Basic、Direct、Group、Custom Actions、Custom Plus Menu、Minimal 和 Limited Capabilities；ChatWorkspace 使用真实公共组件展示 Context、Header、Timeline、Composer。Vue Preview 可真实打开菜单和触发自定义动作，Preview registry 由 catalog metadata 与命名规则驱动，不按组件名写死。

## 21. Native usage docs

Flutter、Compose、SwiftUI 文档提供可复制的真实 Usage Code，不伪造 Web 视觉 Preview。三端均实现 ConversationHeader identity/actions/Plus/overflow、ChatWorkspace 顺序、MessageGroupPosition 与 Timeline avatar/sender 规则。Spec 已按各端真实参数名记录 Vue slots、Flutter/Compose `contextBanner` 与 SwiftUI `context`，平台签名漂移为 0。

## 22. Tests

Vue：44 个测试文件、270 项通过。Flutter：351 项通过。Android：Gradle 全部单测与构建通过。Swift：170 项通过。官网：35 项 Playwright 通过。真实 `flare-core-web-app`：40 项单测、生产构建和 bundle budget 通过，10 项 Playwright E2E 通过。设计系统总检查覆盖 spec、签名漂移、token、主题、package boundary、公开导出、accessibility、文档、示例、生成物和消费者 fixture。

## 23. Visual regression

RC fixture 覆盖 Violet Light/Dark、Graphite Light/Dark、large text、六主题 Light 与代表主题 Dark，共 9 项视觉测试。基线包含 Direct Header、Group Header、完整 ChatWorkspace、分组头像、Reaction、MessageMeta 与 minimal Composer。视觉资源页使用无站点外壳专用画布，避免 VitePress 导航遮挡组件；另更新 desktop/mobile reference app 基线并在无更新模式下复跑通过。

## 24. Remaining P2/P3

未保留 P0、P1 或明显 P2。P3 后续包括：在真实 Android/iOS 设备上扩充 ConversationHeader 菜单和动态字体截图矩阵；在下一主版本按迁移数据评估移除 `ChatHeader` 兼容包装；如产品未来提供真实通话、成员管理或关系链 capability，再由 Host 开启相应动作，而不是提前把它们写入示例。
