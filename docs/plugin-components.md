# 插件 UI 组件复用

插件只提交数据与动作 ID。SDK 持有授权目录、参数绑定、会话隔离和业务分发；应用组合页面、回调与平台 Bridge；Kit 负责呈现及无障碍交互。不要把钱包、网络、权限判断或插件脚本放进组件库。

## 四端组件

| 用途 | Vue / Web / Tauri | SwiftUI | Compose | Flutter |
|---|---|---|---|---|
| 红包卡片 | `FlareRedPacketCard` | `RedPacketCardView` | `RedPacketCard` | `FlareRedPacketCard` |
| 开红包浮层 | `FlareRedPacketOpenSheet` | `RedPacketOpenSheet` | `RedPacketOpenSheet` | `FlareRedPacketOpenSheet` |
| 红包详情 | `FlareRedPacketDetail` | `RedPacketDetailView` | `RedPacketDetail` | `FlareRedPacketDetail` |
| 发红包表单 | `FlareRedPacketComposer` | `RedPacketComposerView` | `RedPacketComposer` | `FlareRedPacketComposer` |
| 支付确认 | `FlareRedPacketPayConfirm` | `RedPacketPayConfirmView` | `RedPacketPayConfirm` | `FlareRedPacketPayConfirm` |
| 通用插件结果/字段/动作 | `FlarePluginView` | `PluginView` | `PluginView` | `FlarePluginView` |
| 加载/错误/权限说明 | `FlareStatusBanner` | `StatusBannerView` | `StatusBanner` | `FlareStatusBanner` |
| 页面与表单 | `FlareScreen`、`FlareSchemaForm` | Kit Screen/Drawer/Form 组件 | Kit Screen/Drawer/Form 组件 | Kit Screen/Drawer/Form 组件 |

红包 Vue 面板由可选业务 SDK 拥有，组合 Kit 表单、按钮、状态条、钱包字段和红包卡片。Web/Tauri 复用同一面板。原生聊天插件视图组合通用 Kit 卡片与页面，不在应用复制视觉控件。

## 红包组件合同

五个组件只画，不算钱、不请求网络、不判断资格：金额、时间、名字由宿主格式化后传入，领取结果和「手气最佳」来自插件服务端。四端 props 与回调以 `spec/components.json` 为准，签名门禁逐端比对；共享规则表在 `spec/red-packet-vectors.json`（卡片状态行与可点规则、变淡、表单行与金额标签、金额与个数的输入过滤），四端测试读同一份。颜色来自 `colors.redPacket.*`（start / middle / end / gold / goldDeep / onSurface，变淡用的 fadedMixTarget / fadedInk 另有深色值），尺寸来自 `sizes.component.redPacket*`（卡片宽 248、信封宽 300、信封最小高 440、「開」直径 96、大字金额 44、详情头图高 72、变淡比例 redPacketFadedMix 0.4）。

### 卡片 `RedPacketCard`

`blessing`、`kindLabel?`、`state`（`unopened` / `claimed` / `finished` / `expired`）、`amount?`、`statusLabel?`、`busy`、`disabled`；回调 `open` / `onOpen`。

- `unopened` 是饱和的橙红色；其余三种变淡，状态行显示「已领取（· 金额）」「已被领完」「已过期」。
- 变淡（vectors → `faded`）：卡面五个色各自在 sRGB 里向 `fadedMixTarget` 混合 `redPacketFadedMix`（0.4）。目标色浅色为 #FFFFFF，深色为偏红深底 #2A1513，所以色相不变，深色页上也不会发亮。文字改用 `fadedInk`（浅色 #5C140E、深色 #FBE3DE），每一档对比度 ≥ 4.5；白字在浅色变淡面上不到 3:1。不用滤镜，不降透明度。
- `finished`、`expired` 仍可点击，用来查看领取详情。只有 `busy`、`disabled` 和原生端缺少回调时不可交互；这两种保持未领取的外观和白字，只换状态行（「处理中…」「暂不可用」），不变暗、不变灰，`disabled` 也不应伪装成已领完。
- 状态行优先级：忙碌、`statusLabel`、已领取金额、已领取、已被领完、已过期、暂不可用、点击领取。`statusLabel` 是纯文本（如单聊发送人的「待领取」），不授予权限。
- 左侧是四端同一几何的小信封：宽 30、高为宽的 1.3 倍、圆角为宽的 0.18；封盖高为整高的 0.42，弧线比两侧下垂封盖高的 0.3；红色封印直径为宽的 0.36，圆心在弧线最低点。配色为 gold→goldDeep 的信封身、goldDeep 封盖、end 封印，变淡时同样混合。Vue 用内联 SVG，Flutter 用 CustomPainter，不用位图。
- 宽度最多 248，服从父约束；交互区至少 48；`kindLabel` 在底部品牌行左侧，品牌名靠右。

### 开红包浮层 `RedPacketOpenSheet`

`senderName`、`senderAvatar?`、`blessing`、`kindLabel?`、`state`（`ready` / `opening` / `finished` / `expired` / `notEligible` / `error`）、`message?`；回调 `open`、`viewDetails`、`close`。Vue 另有可见性 `open`（与 FlareModal 一致），`@open` 是点了「開」。

- 居中红色信封：弧形封盖上是发送人头像、「X的红包」、种类和大字祝福语，金色「開」压在封盖接缝上，关闭键在信封下方（仍在焦点陷阱内）。
- `opening` 时「開」绕 Y 轴翻转循环且不可重复点；系统减少动态效果时不翻转，「開」换成进度文案。
- `finished` 显示「手慢了，红包派完了」，`expired` 显示「该红包已超过 24 小时」，`notEligible` 显示宿主的 `message`（如「仅 TA 可领取」）；三者都有「查看领取详情」。`message` 也可替换前两者的默认文案。`error` 保留「開」供重试，并显示 `message` 或「领取失败，请重试」。
- `notEligible` 的提示和 `error` 的说明用正文行高（`lineHeight.normal`），最多 3 行，超出省略。
- 遮罩点击、关闭键、Escape 和平台返回键都触发 `close`。Flutter 组件自绘遮罩，可放进 Stack，也可用 `FlareRedPacketOpenSheet.show` 推一条路由；没有 `onClose` 时这些操作直接出栈。

### 红包详情 `RedPacketDetail`

`senderName`、`senderAvatar?`、`blessing`、`kindLabel?`（如「拼」）、`amount?`（大字）、`amountNote?`（如「已存入钱包」）、`summary`、`claims`（`{id, name, avatar?, time, amount, best}`）、`note?`、`title?`；回调 `back` / `onBack`（可选）。

- 普通页面，不是浮层：宿主放进导航栈，外面套 Kit 的 Screen 容器（滚动归 Screen）。
- 传了 `onBack`（Vue 监听 `back`）时，组件自己画红色标题栏：`redPacket.end` 底、浅色返回键和标题（`title`，默认「红包详情」，文案键 `packetDetailTitle`），延伸进状态栏或安全区，下方弧形头图从同一红色开始，连成一片；宿主这时隐藏自己的导航栏。不传时行为不变。
- 列表行显示头像、名字、时间、金额；`best` 的行在金额下带金色星标和「手气最佳」。`claims` 为空时显示「暂无人领取」。

### 发红包表单 `RedPacketComposer`

`kinds`、`kind`、`amount`、`count`、`greeting`（后四个双向绑定：Vue `v-model:kind` 等，原生为值 + `onKindChange` / `onAmountChange` / `onCountChange` / `onGreetingChange`）、`recipient` 插槽（原生为同名参数）、`total`、`error?`、`busy`、`locked`、`submitLabel?`；回调 `submit`。

- 种类用 Kit 分段控件切换，`kinds` 只有一项时不显示分段；`kind` 不在 `kinds` 中时取第一项。金额标签随种类变化：拼手气「总金额」、群聊普通红包「单个金额」、专属「金额」。个数只在群聊的拼手气和普通红包显示；专属显示「发给谁」和宿主的成员选择器。
- `kinds` 恰为 `[normal]` 表示单聊：不显示分段和「红包个数」，金额标签为「金额」（vectors → `composer`）。
- 只做格式限制：金额只收数字和最多两位小数，个数只收数字（最多三位），过滤后的文字回写输入框。范围、余额和 `total` 由宿主计算。
- 提交按钮是 Kit Button，只把 primary 改为 `redPacket.end`，文案默认「塞钱进红包」。`busy` 锁定所有字段和按钮并在按钮上显示进度。字段里按 Enter 不提交。
- `locked`：原命令结果未知、等待核对。所有输入和种类切换只读（读屏标为只读），提交按钮不可点，但不显示加载动画；宿主通常在表单上方用 StatusBanner 说明原因。
- 种类切换的选中项用 `redPacket.accent`（浅色 #C8291F，深色 #FF7B6B，在深色分段底上 6.2:1），经 Kit 分段控件新增的可选参数 `accent` 传入，其他页面的分段控件不受影响。

### 支付确认 `RedPacketPayConfirm`

`amount`、`methodLabel`（如「钱包（余额 ¥12.00）」）、`insufficient`、`busy`；回调 `confirm`、`cancel`。Vue 另有可见性 `open`。

- 复用 Kit BottomSheet：手机形态是底部面板，其余形态交给 Modal。Flutter 的内容组件配 `FlareRedPacketPayConfirm.show`，标题为「确认付款」。
- 大字金额、支付方式行、确认（红色 Kit Button）和取消。`insufficient` 时确认不可用并显示「余额不足」；`busy` 时两个按钮和遮罩、Escape、返回键都锁定。沙箱钱包，不做支付密码。

### SwiftUI 与 Compose

- 开红包浮层：SwiftUI 的 `RedPacketOpenSheet` 是整层视图（遮罩、信封、下方关闭键），用 `flareRedPacketOpenSheet(isPresented:onDismiss:sheet:)` 呈现（iOS 16.4+ 为透明全屏覆盖，更早的 iOS 与 macOS 为系统 sheet），`onClose` 里由宿主把 `isPresented` 置回 false；也可以自己叠在页面上。Compose 的 `RedPacketOpenSheet` 组合即显示，独立对话窗口，`onClose` 在退出动画后调用（减少动态效果时立即调用）。减少动态效果读 iOS `accessibilityReduceMotion`、Android 动画时长缩放为 0。
- 支付确认：SwiftUI 的 `RedPacketPayConfirmView` 是面板内容，用 `flareBottomSheet(isPresented:title:titleHidden:dismissible:)` 呈现，标题传 `packetPayTitle` 并隐藏（内容自绘标题），`dismissible` 传 `!busy`。Compose 的 `RedPacketPayConfirm` 组合即显示 Kit `BottomSheet`，`busy` 时锁定遮罩与返回键。
- 红色金额按钮：Compose 用 Kit `Button`，在局部主题里把 primary 换成 `redPacket.end`；SwiftUI 的 `ButtonView` 没有改色入口，组件族内部用同尺寸（高 48、圆角 lg、白字）的红色按钮代替，不对外公开。
- 发红包表单：原生 `count` 是整数，0 表示空；`onCountChange` 回传整数。`recipient` 在 SwiftUI 是 `@ViewBuilder` 参数（不需要时用不带它的初始化方法），在 Compose 是可空的 composable 参数。种类切换复用 Kit 分段控件，分段的命中区覆盖整条轨道高度（SwiftUI 44、Compose 48）。
- 测试：iOS `RedPacketComponentsTests`（ViewInspector 状态矩阵，macOS 上另有宿主窗口真实点击），Android JVM `RedPacketComponentsTest` 与设备上的 `RedPacketComponentsInteractionTest`，两端都读 `spec/red-packet-vectors.json`。

默认文案读取 Kit 语言环境。原生英文预设来自 `strings/en.json` 与 `strings/build.mjs`；`appendArgumentKits` 支持把动态金额追加到相应平台的函数字段，不能手改生成预设。Flutter Kit 声明 Material 图标资源；截图测试显式加载字体，避免把缺失字形当成有效视觉证据。

## 自定义内容渲染器

插件卡片通过 Kit 的内容渲染器注册进消息列表，四端同一套语义：

- **无气泡**：注册时标 `bare`，消息列表就像渲染单图那样直接画内容，不套气泡底和内边距，保留头像、昵称、时间、多选和长按菜单；引用或撤回时仍画气泡。Vue 的注册值可以是组件本身或 `{ component, bare: true }`；Flutter 与 Compose 是 `FlareContentScope` 的 `bareTypes`（Flutter 另有 `FlareContentRegistry.register(type, builder, bare: true)`）；SwiftUI 是 `flareContentRenderers(_:bare:)`。Kit 内部原有的「裸媒体」判断同时认这个标记。
- **消息标识**：渲染器拿到 `messageId`（服务端 ID，没有时用 clientMsgId）和 `conversationId`（可空，消息列表会补上自己的会话）。Vue 是渲染组件的 props，Flutter / Compose 是 `FlareContentContext` 的字段，SwiftUI 是渲染闭包的上下文参数。宿主不必再把它们塞进 payloadJson。
- **单色图标**：「+」面板、菜单等用图标名 `red-packet`（四端注册表最后一项）。Vue 为 Kit 自绘 SVG，Flutter 为 Kit 图标字体 `FlareKitIcons`，Compose 为 Kit 自绘的 `ImageVector`，SwiftUI 由 `IconView`、按钮、「+」面板、菜单和消息操作面板画 Kit 自绘图形（SF Symbols 没有红包；直接写 `Image(systemName:)` 的地方退为 `envelope`），都跟随 tint 着色。

## 业务与生命周期

通用 `PluginView` 只渲染 SDK 返回的当前视图；不可用时不显示字段或动作。动作只回传不透明 ID，禁止在 Kit 中解释目标、请求上游或执行动态脚本。

红包面板通过 SDK journal 固定原命令。未知结果锁定输入，重试核对原命令；卡片投递失败只重发原红包。组件卸载后不继续把迟到结果投递到旧会话，SDK 仍保留结果供恢复核对。停用时包括投递重试在内的所有业务按钮均禁用；服务端权限检查仍独立执行。

## 验证入口

工作区根目录：

```sh
python3 scripts/verify-plugin-platform.py --group client --group apps --group native --group ui-kit
python3 scripts/verify-plugin-apple-ui.py
```

`ui-kit` 包含语言生成一致性、硬编码文案棘轮、Apple 实际组件消费者、Flutter 插件/消息合同和 Android Kit 编译/JVM/交互测试源码编译。部分分组的报告在重试时保持原分组，不自动扩展为所有后端构建。

Apple 消费者使用 Kit 原测试文件的符号链接，创建并清理自己的临时项目，只编译依赖库和插件测试，不把依赖包的全部测试拉入。iOS 模拟器用 Xcode 对同一组件测试执行补验。Android 交互源码编译不代表设备执行；需要设备后运行 `connectedDebugAndroidTest`，可以按类筛选 `PluginComponentsInteractionTest`。

浏览器隔离入口：Web 示例目录执行 `node scripts/preview-plugin-kit.mjs`，只监听 `127.0.0.1:5198`，`/mobile` 使用 390px iframe。它组合真实 SDK/Kit 与显式内存沙箱，没有业务 API、真实钱包或支付。最终边界及证据见工作区的插件 UI 验证报告。
