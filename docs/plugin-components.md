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
| 通用插件卡片（v1 字段与动作，v2 展示块） | `FlarePluginView` | `PluginView` | `PluginView` | `FlarePluginView` |
| 插件表单 | `FlarePluginForm` | `PluginFormView` | `PluginForm` | `FlarePluginForm` |
| 插件详情（查看全部） | `FlarePluginDetailSheet` | `PluginDetailSheetView` | `PluginDetailSheet` | `FlarePluginDetailSheet` |
| 加载/错误/权限说明 | `FlareStatusBanner` | `StatusBannerView` | `StatusBanner` | `FlareStatusBanner` |
| 页面与表单 | `FlareScreen`、`FlareSchemaForm` | Kit Screen/Drawer/Form 组件 | Kit Screen/Drawer/Form 组件 | Kit Screen/Drawer/Form 组件 |

红包 Vue 面板由可选业务 SDK 拥有，组合 Kit 表单、按钮、状态条、钱包字段和红包卡片。Web/Tauri 复用同一面板。原生聊天插件视图组合通用 Kit 卡片与页面，不在应用复制视觉控件。

## 红包组件合同

五个组件只画，不算钱、不请求网络、不判断资格：金额、时间、名字由宿主格式化后传入，领取结果和「手气最佳」来自插件服务端。四端 props 与回调以 `spec/components.json` 为准，签名门禁逐端比对；共享规则表在 `spec/red-packet-vectors.json`（卡片状态行与可点规则、变淡、表单行与金额标签、金额与个数的输入过滤），四端测试读同一份。颜色来自 `colors.redPacket.*`（start / middle / end / gold / goldDeep / onSurface，变淡用的 fadedMixTarget / fadedInk 另有深色值），尺寸来自 `sizes.component.redPacket*`（卡片宽 248、信封宽 300、信封最小高 440、「開」直径 96、大字金额 44、详情头图高 72、变淡比例 redPacketFadedMix 0.4）。

### 卡片 `RedPacketCard`

红包第五版（`docs/design/red-packet-v5-roles-and-wallet.md` §1）：`blessing`、`kind`（`lucky` / `normal` / `exclusive`）、`recipientName?`、`state`（`unopened` / `viewable` / `claimed` / `finished` / `expired` / `refunded`）、`statusLabel?`、`busy`、`disabled`；回调 `open` / `onOpen`。**卡片永不显示金额**，包括本人领到的。

- 状态由插件公开层（`status`）与本人层（`claimedByMe`、`tapAction`）得出：`flareRedPacketCardState`（vectors → `cardState`）。本人已领 → claimed；completed → finished；expired → expired；refunded → refunded；进行中且 `tapAction` 为 open（或本人层还没到）→ unopened「领取红包」；进行中但发送人或非指定人（`tapAction` 为 details / notEligible）→ viewable「查看红包」。
- 类型角标在品牌行：拼手气「拼手气」、专属「专属」，普通不标；专属红包在角标后写「给 某某」（`recipientName`，宿主从 IM 目录取；vectors → `cardBadge`）。发送人取 IM 消息的发送者，不取载荷。
- `unopened`、`viewable` 是饱和的橙红色；claimed / finished / expired / refunded 变淡（vectors → `faded`）：卡面五个色各自在 sRGB 里向 `fadedMixTarget` 混合 `redPacketFadedMix`（0.4），文字改用 `fadedInk`，每一档对比度 ≥ 4.5。不用滤镜，不降透明度。
- 除 `busy`、`disabled` 外都可点击，点后由宿主按本人层 `tapAction` 决定去向（开红包浮层、详情或「仅 某某 可领取」）。`busy`、`disabled` 保持未领取的外观，只换状态行（「处理中…」「暂不可用」）。
- 状态行优先级（vectors → `card`）：忙碌、`statusLabel`、再按 state。`statusLabel` 是纯文本，不授予权限。
- 卡片就是消息的 card 表面（`spec/message-surface-vectors.json`），时间线不再在外面套气泡。
- 左侧是四端同一几何的小信封：宽 30、高为宽的 1.3 倍、圆角为宽的 0.18；封盖高为整高的 0.42，弧线比两侧下垂封盖高的 0.3；红色封印直径为宽的 0.36，圆心在弧线最低点。配色为 gold→goldDeep 的信封身、goldDeep 封盖、end 封印，变淡时同样混合。宽度最多 248，服从父约束；交互区至少 48。

### 开红包浮层 `RedPacketOpenSheet`

`senderName`、`senderAvatar?`、`blessing`、`kindLabel?`、`state`（`ready` / `opening` / `finished` / `expired` / `refunded` / `notEligible` / `error`）、`message?`、`canViewDetails?`（默认真）；回调 `open`、`viewDetails`、`close`。Vue 另有可见性 `open`（与 FlareModal 一致），`@open` 是点了「開」。

- 居中红色信封：弧形封盖上是发送人头像、「X的红包」、种类和大字祝福语，金色「開」压在封盖接缝上，关闭键在信封下方（仍在焦点陷阱内）。
- `opening` 时「開」绕 Y 轴翻转循环且不可重复点；系统减少动态效果时不翻转，「開」换成进度文案。
- `finished` 显示「手慢了，红包派完了」，`expired` 显示「红包已过期」，`refunded`（领取被拒 `PACKET_REFUNDED`，或公开层 status 为 refunded）显示「红包已退回」；三者在 `canViewDetails`（本人层）为真时给「查看领取详情」（vectors → `openSheetRefunded`）。`notEligible` 显示宿主的 `message`（如「仅 某某 可领取」），**永远不给**详情入口：服务端对非指定人不返回金额和记录（vectors → `openSheet`）。`error` 保留「開」供重试。
- 遮罩点击、关闭键、Escape 和平台返回键都触发 `close`。

### 红包详情 `RedPacketDetail`

`senderName`、`senderAvatar?`、`details`（插件 details 对当前查看者的结果：`viewerRole`、`status`、`kind`、`greeting`、`currency`、`currencyExponent`、服务端给出的 `totalMinor` / `claimedMinor` / `refundedMinor` / `myAmountMinor`、份数、时间、`claimsListed`）、`designatedName?`、`claims`（`{id, name, avatar?, amountMinor, claimedAtMs, best}`）、`title?`；回调 `back` / `onBack`（可选）。

- 按 `viewerRole` 画服务端给的字段（vectors → `detail`，`flareRedPacketDetailTexts`）：有 `myAmountMinor` 时大字金额加「已存入钱包」；可领未领者在已领完时显示「手慢了，红包派完了」，已过期 / 已退回时显示「红包已过期」；非指定人显示「仅 某某 可领取」。摘要行：发送人有总额时「已领取 a/b 个，共 x/y」或「b 个红包共 y，n 秒被抢光」，其他人只有「已领取 a/b 个」。`claimsListed` 为真才画领取记录。发送人的说明：进行中「未领取部分将于 HH:mm 退回」，过期 / 退回「已退回 ¥x · 时间」。**没有的金额绝不显示**。
- 金额从最小单位字符串按 `currencyExponent` 用整数运算格式化（`flareRedPacketMoney`，vectors → `amount`），符号按币种表；时间当天写 HH:mm，否则用插件视图的日期格式。
- 普通页面，不是浮层：宿主放进导航栈，外面套 Kit 的 Screen 容器。传了 `onBack` 时组件自己画红色标题栏。

### 发红包表单 `RedPacketComposer`

`kinds`、`kind`、`amount`、`count`、`greeting`（后四个双向绑定：Vue `v-model:kind` 等，原生为值 + `onKindChange` / `onAmountChange` / `onCountChange` / `onGreetingChange`）、`recipient` 插槽（原生为同名参数）、`total`、`error?`、`busy`、`locked`、`submitLabel?`；回调 `submit`。

- 种类用 Kit 分段控件切换，`kinds` 只有一项时不显示分段；`kind` 不在 `kinds` 中时取第一项。金额标签随种类变化：拼手气「总金额」、群聊普通红包「单个金额」、专属「金额」。个数只在群聊的拼手气和普通红包显示；专属显示「发给谁」和宿主的成员选择器。
- `kinds` 恰为 `[normal]` 表示单聊：不显示分段和「红包个数」，金额标签为「金额」（vectors → `composer`）。
- 只做格式限制：金额只收数字和最多 `currencyExponent`（默认 2，取插件 limits 的币种小数位）位小数，0 位时不收小数点、用数字键盘；占位按小数位写（「0」「0.00」「0.000」）；个数只收数字（最多三位），过滤后的文字回写输入框。换成小数位更少的币种时裁掉已输入的多余小数。范围、余额和 `total` 由宿主计算，金额换成最小单位用 `flareRedPacketAmountMinor(text, exponent)`（整数运算，不经浮点；vectors → `amountInputExponent`、`amountMinor`、`amountPlaceholder`）。
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

## 通用插件卡片 v2

投票、接龙、任务、日程、群公告不写客户端代码：核心 SDK 把插件的 UiDocument 和两层状态解析成 ResolvedPluginView，Kit 只渲染这个形状，不读路径、不求值。四端接口以 `spec/components.json` 的 PluginView、PluginForm、PluginDetailSheet 为准，渲染事实以 `spec/plugin-view-vectors.json` 为准（views、optimistic、time、countdown、form），四端测试读同一份。

- **卡片**：外壳与 Kit 业务卡片一致，宽度 `sizes.component.richCardWidth`（服从父约束）、圆角 lg、细边框、卡片阴影；标题行有图标位（`icon`，Kit 图标名）。外壳就是消息的 card 表面：时间线不在外面再套气泡，引用回复画在外壳的 `quote` 插槽里（Vue）。`embedded` 去掉外壳和标题行，详情面板、插件页面和控制台管理页用它。`available` 为假时只显示标题；embedded 没有标题行，就把标题显示为一行次要文字，仍说明它是什么。
- **⋯ 菜单 `menuActions`**：插件把动作标成 `placement: "menu"`（结束投票、取消投票）时，它们在 `view.menuActions` 里，卡片标题行末尾出现 Kit ⋯ 键（读屏名「更多操作」；标题行占满卡片内宽，标题取剩余宽度，⋯ 贴在行尾），用 Kit ActionMenu 列出，danger 用危险色；选中后与按钮相同：先确认、再表单、再 `action(id, {})`。`busy` 或 `busyActionId` 时禁用。embedded 没有标题行，这些动作作为按钮排在 `actions` 之后。规则见 `rules.menuActions`。
- **不可用原因 `unavailableReason`**：disabled「插件已停用」、not_installed「插件未安装」、no_permission「没有使用该插件的权限」、unsupported_platform「该插件不支持此设备」、incompatible_version「请更新应用后查看」、catalog_unreachable「暂时无法加载，请稍后再试」、unbound_copy「副本，仅供查看」。不可用时标题下加一行原因，宿主传了信封的 `displayName` 时写成「投票 · 插件已停用」。unbound_copy（转发或伪造的副本）仍可读：核心 SDK 已去掉动作、菜单、输入、详情与选项提交，卡片只读，末尾一行「副本，仅供查看」。规则见 `rules.unavailableReason` 与 `unavailableReasons`。
- **块**：
  - text：按 `maxLines` 截断，溢出时显示「展开」。
  - fields：键值对。
  - choices：单选点一项立即提交；多选勾选后点提交键，键名取块持有的动作 label。显示结果时每项有票数条、百分比和「{count} 票」（英文按复数写「1 vote」），选中项打勾；`closed` 时只读，底部显示「已结束」。块的 `total` 只是百分比的分母（可能是人数，也可能是票数之和），Kit 不画它：「N 票」只用于选项，参与人数由插件自己的行给出（投票第二版 §6）。
    - 多选上限 `maxSelections`（只在多选，1..=选项数）：草稿选满后，草稿以外的选项变灰、`aria-disabled`、点击无效；已选的仍可取消，取消后其余恢复。提交键除了「非空且与已选不同」，还要求不超过上限：插件把上限调低后，已有的选择只能减到上限以内才能提交。可选时页脚以「最多选 {n} 项」开头。单选、没有该字段时不限。卡片、详情面板、插件页面一致。规则见 `rules.maxSelections`，步骤见 `maxSelections`。
  - entries：带序号；`more` 时显示「查看全部（total）」，触发 `openDetail`。`grouped` 时是一个扁平列表：带 `group` 的条目前插一行组头「选项 · N 票 · P%」（缺的段省略），组内从 1 编号，`numbered: false` 不编号；`viewerId`（宿主传入的当前用户）那一行带「我」。规则见 `rules.entriesGrouped` 与 `entryGroupHeaders`。
    - 徽标 `badge {text, tone}`：插件 `valueLabels` 把条目里的枚举值（如账单行的类型）映射成文字与语义色，核心 SDK 已翻译，未映射的值原样、neutral。Kit 用 Tag 画，顺序为序号、头像、名字、「我」、徽标、正文；未知 tone 按 neutral。没有徽标不留空位。规则见 `rules.badge`。
  - people：每组一行，头像叠加计数，颜色用 tone 对应的 *Text 令牌。
  - status：徽标。
  - progress：进度条加「value/total」。
  - time：按设备时区，用 `pluginViewDateTimeFormat` 格式化；`countdown` 时剩余不到 1 小时每秒刷新，否则每分钟刷新，到点显示「已截止」。
  - divider、note。
  - rows：插件页面上四端都画成列表（见下文「插件页面」）；Vue 的 PluginView 另有 `rowsLayout: "table"`（默认），给控制台管理列表用 Kit DataTable，有行动作、点行打开详情、「加载更多」和空态，行的徽标画在第一格里。两种画法都按 key 去重，只保留第一次出现的行。
- **动作**：
  - `style` 为 danger 用危险键，primary 用主键，其余为次要键。
  - 有 `confirm` 先弹 Kit DangerConfirm；有 `form` 在 Kit 底部面板里打开 PluginForm。
  - 回调是 `action(actionId, {selection?, formValues?, row?})`，`row` 只出现在行动作上。
  - 状态：`busyActionId` 让对应按钮转圈、其他控件等待；`error` 显示在卡片底部。
- **查看详情**：`view.detail` 为真、但没有 entries 块在显示「查看全部」时（投票、日程、任务、公告这类没有 entries 或 entries 没超出的卡片），卡片在动作区下方画一个整宽的 quiet 文字按钮「查看详情」（`pluginViewDetail`，Vue 为 `pluginView.detail`，size sm），点击发出不带 row 的 `openDetail`，与「查看全部」相同。
  - 不显示的情况：视图不可用、`embedded`（详情面板、管理页、面板里的前言）、有 rows 块（管理页从行打开详情）、宿主没处理 `openDetail`（原生没传 `onOpenDetail`，Vue 没监听）。
  - `busy` 或 `busyActionId` 时禁用。规则与样例见向量的 `rules.detailKey` 和 `detailKey`。
- **乐观选中**：提交后 Kit 立刻标记选中，新的 view 到达即结算，`error` 变为非空就撤回。
- **结算信号 `settleToken`**：宿主每完成一次动作加 1，先设好这次结果的 `error` / `formErrors` 再加。每次变化都结算：
  - 没有错误：已提交的表单面板关闭，乐观选中保留到新视图到达。
  - 有 `error`：撤回乐观选中，打开的表单留着并显示它。错误在变化那一刻读取，文案和上次相同也会撤回。
  - 有 `formErrors`：表单留着显示错误，表单携带的选中一并撤回。
  - `busyActionId` 离开该动作仍作为兜底；宿主在同一帧里设上又清掉 `busyActionId` 时，只能靠 `settleToken`。
  - 宿主约定：调用期间设 `busyActionId`，开始新一次调用时清掉 `error`，结果出来后加 `settleToken`。规则见 `spec/plugin-view-vectors.json` 的 `rules.settle`。
- **内边距 `inset`**：说明视图放在哪里。
  - `sheet`：直接放进 Kit BottomSheet，上 md、左右 lg、下 xl，与 PluginForm 一致，不用再包一层（如 composer 面板里的插件视图）。
  - `sheetTop`：放在面板顶部、下面还有内容，上 md、左右 lg、下不留。「+」插件入口里 PluginForm 上方的前言用它，前言和表单之间只剩表单自己的 md，不再是 xl + md。
  - 作用于视图画出的一切、任何状态：embedded 的内容（可用或不可用、有没有 error），以及宿主留在面板里的卡片外壳（加在外壳外面，外壳自己的 md 内边距不变）。规则见向量的 `rules.inset` 和 `insets`。
- **用户**：people 和 entries 只有 userId，名字和头像经宿主的 `resolveUser(userId)` 取得，可同步也可异步；取不到时显示首字母头像，名字取 userId 的末 4 位。
- **表单 PluginForm**：
  - 控件：text、textarea 带计数；number；toggle；select 为单选列表；datetime（Vue 用 Kit 的 DatePicker 和 TimePicker，原生用平台选择器）；options 为可增删的行，条数受 min、max 约束；members 用 ContactPicker，候选成员由宿主经 `members` 传入，`max` 为 1 时单选。
  - 校验：客户端只查必填和长度（按 Unicode 码点）；最终以核心 SDK `validate_form` 返回的 `errors` 为准，显示在对应输入下方，直到该输入被修改。
  - 卡片动作的表单在结算（`settleToken` 变化，或兜底的 `busyActionId` 清空）且没有 `formErrors` 和 `error` 时关闭。
- **详情 PluginDetailSheet**：
  - Vue 支持可选的 `footer` 插槽，用于宿主已有授权动作的审核区；仅详情成功加载后显示。组件不请求权限、不声明审核操作，也不执行资金业务。控制台在宿主中核对原行参数、当前版本与角色权限，再复用已有命令和理由确认。
  - Kit 底部面板，分 loading（转圈）、error（宿主文案加重试）和 embedded PluginView 三种状态；标题取视图标题，没有视图时取卡片标题。
  - 详情里的动作：`busyActionId`、`actionError`（作为视图的 error）、`formErrors`、`members`、`settleToken` 原样交给内嵌视图，转圈、出错、收表单和结算都在面板内。
  - 宿主要把这些和卡片自己的 busy、error 分开，详情里的失败不落到面板下面的卡片上。已有的 `error` 仍表示加载失败。
  - 分页：视图带非空的 `nextCursor` 时，内嵌视图下方显示一行整宽的「加载更多」。
    - 点击发出 `loadMore(cursor)`，宿主取下一页，把合并好的视图传回。合并由核心 SDK 做，Kit 不合并。
    - `loadingMore` 为真，或 Kit 记下的已请求游标仍等于当前 `nextCursor` 时，按钮转圈并禁用，同一页不会被请求两次。
    - 以下情况允许重试：`loadingMore` 由真变假、`settleToken` 变化、`actionError` 变为非空。
    - 规则与样例见向量的 `detailPaging`。
- **管理页筛选（Vue）**：rows 块的 `filters` 列出筛选栏要显示的输入，不带时为全部输入；其余输入归行动作的表单。控制台用 `flarePluginFilterInputs(view)` 取筛选输入，也可以从 `@flare-im/vue-ui/admin` 导入。

## 自定义内容渲染器

插件卡片通过 Kit 的内容渲染器注册进消息列表，四端同一套语义：

- **表面**：消息画在哪种表面上由 Kit 按内容类型决定（`spec/message-surface-vectors.json`）：一切 custom / 插件内容（含红包、投票、`custom:flare.plugin.message.v1`）默认是 card —— 渲染器自己的外壳就是表面，消息列表不套气泡底、边框和内边距，保留头像、昵称、时间（在卡片下方）、多选和长按菜单。宿主只在注册 Kit 不认识的内容类型时登记表面：Vue 的注册值可以是组件本身或 `{ component, surface: "card" | "bareMedia" }`。旧的 `bare` 选项已删除，四端同一套 `surface` 登记：Flutter 与 Compose 是 `FlareContentScope(surfaces: {...})`（键为 `contentType:subtype` 或内容类型），SwiftUI 是 `flareContentRenderers(_:surfaces:)`。
- **多选**：行处于多选时渲染器收到 `selectionMode: true`（Vue 另经 `useFlareContentSelection()` 注入），其控件必须不响应，点整行切换选中。
- **消息标识**：渲染器拿到 `messageId`（服务端 ID，没有时用 clientMsgId）和 `conversationId`（可空，消息列表会补上自己的会话）。Vue 是渲染组件的 props，Flutter / Compose 是 `FlareContentContext` 的字段，SwiftUI 是渲染闭包的上下文参数。宿主不必再把它们塞进 payloadJson。
- **单色图标**：「+」面板、菜单等用图标名 `red-packet`（四端注册表最后一项）。Vue 为 Kit 自绘 SVG，Flutter 为 Kit 图标字体 `FlareKitIcons`，Compose 为 Kit 自绘的 `ImageVector`，SwiftUI 由 `IconView`、按钮、「+」面板、菜单和消息操作面板画 Kit 自绘图形（SF Symbols 没有红包；直接写 `Image(systemName:)` 的地方退为 `envelope`），都跟随 tint 着色。

## 插件页面 `PluginPage`

插件的 `page` 贡献（钱包、明细等）用 Kit 的通用页面宿主渲染（`docs/design/red-packet-v5-roles-and-wallet.md` §3.2），五个 app 不再自写钱包页。四端都是 `FlarePluginPage`，按 `spec/components.json` 的 PluginPage 契约实现；渲染事实见 `spec/plugin-view-vectors.json` 的 `rules.page`、`pageRows`、`pagePaging`、`pageFilters` 与 `pageViews`、`pageActions`、`pagePaging`、`pageFilters` 四段。

- **数据来源**：宿主用核心 SDK 读页面（TS `PluginUiSession.page(pluginId, page, {args, filters, page, refresh})`，bindings `capability.plugin_page`），把结果原样作为 `view` 传入。它是详情同形的视图加 `data`（页面解析所依据的数据）。宿主同时传 `page: {pluginId, page}`。
- **页头**：标题取 `view.title`，没有时取宿主的 `title`。不可用的页面标题为空，所以保留宿主标题。返回键与平台返回一致。
- **状态**：
  - 首次加载转圈。
  - 首次失败：宿主文案加重试键（`retry`）。
  - 刷新失败：视图上方显示危险色横幅。
  - 不可用（`view.available` 为假）：Kit 空态显示原因文案（disabled「插件已停用」等七种，没有原因时「暂无数据」）。只有 catalog_unreachable 带重试键；不画刷新、筛选、加载更多和动作。
- **动作**：页面里执行的每个动作都发出 `action(id, {page, data?, row?, selection?, formValues?})`，在确认与表单之后。这里的动作包括视图动作、作为按钮排列的菜单动作、choices 提交和行动作。这个载荷就是 `invokePageAction` 的请求，宿主原样转交即可。`data` 取 `view.data`，视图没有时省略；`row` 是行动作所在行的 `{key, input}`。结果由宿主处理：page 目标用结果的 payload 作为参数打开下一页，表单错误经 `formErrors` 回到表单。`busyActionId`、`actionError`、`formErrors`、`members`、`settleToken` 与详情面板相同。
- **行（rows）**：页面上画成列表，四端一致，不画表格，也不画列标题。
  - 每行一项：第一行是徽标加第一格；第二行是其余单元格，按列顺序排列，time 列按设备时区格式化，空格跳过，以「 · 」连接，一格不剩时省略。
  - 行动作是行尾的紧凑按钮，style、confirm、form 照常生效。动作执行中只有发起的那一行转圈，同一动作 id 的其余行禁用但不转。
  - 同一个 key 只画第一次出现的行，因为列表的 key 必须唯一。
  - 没有行时显示 `emptyText`，没有时显示「暂无数据」。
  - 页面上的 rows 随页面分页，没有自己的「加载更多」。
- **分页**：`view.nextCursor` 非空时视图下方有整宽的「加载更多」，同一游标只请求一次，规则同详情面板；另外刷新结束（`refreshing` 由真变假）也会忘掉已请求的游标，因为刷新回第一页可能拿到同一个游标。宿主请求下一页时把当前视图作为 `previous` 传给 SDK，然后把合并好的视图传回：新页的 rows 与 entries 接在后面，已显示的行 key 丢弃，`data` 保持第一页的。Kit 不合并。
- **筛选**：页面带 rows 块时，rows 块 `filters` 列出的输入（不列时为全部输入）里，kind 为 select 的每个画成一行 Kit FilterTabs：「全部」在前，其后是选项，读屏名取输入的 label；其他类型的输入不做页面筛选。
  - 选中项由宿主的 `filters` 决定。值不是选项之一时视为「全部」。
  - 选中另一项时发出 `filter(values)`：值是宿主的 filters 改动这一项之后的结果，选「全部」时去掉这一项。宿主据此重读第一页，期间设 `refreshing`。
  - 点已选中的项不发出。刷新或加载更多期间筛选禁用（FilterTabs 的 `enabled`）。
  - FilterTabs 的胶囊保持画出来的高度（约 30），命中区在周围补到 `layout.touchTarget`。
- **刷新**：触屏下拉刷新，指针设备页头有刷新键。
- **取数由宿主负责**：`refresh`、`retry`、`loadMore`、`filter` 都是请求，Kit 不调用接口；视图没声明的东西不画，不放占位按钮。页面视图没有详情，所以 PluginPage 没有 `openDetail`。

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

## 控制台插件工作区的紧凑查询

`FlarePluginForm`可显式传入`presentation="filters"`，以同行、自动换行的小尺寸输入和操作呈现原有类型字段；可选枚举使用共享选择器的“全部”项。`cancelLabel`可将原cancel事件标记为“重置”。字段校验、类型、busy锁及submit/cancel事件保持一致，默认表单外观不受影响。

插件rows的table布局保留首列阅读空间，其余长值采用共享DataTable省略与完整title；管理table显式采用共享DataTable的`responsive="scroll"`与固定表头／操作列；窄内容区也保留横向列结构，仅在表格内部滚动，避免一条业务记录展开成大块详情。默认DataTable仍为`responsive="stack"`，其他列表和插件list布局不受影响。详情、游标与操作不变。

## 控制台详情与配置布局

`FlareSchemaForm :columns="2"`只在自身容器至少600px时使用两列，窄容器单列；默认一列。分组、顺序、精确金额字符串、空值、未知JSON键、secret输入和disabled语义仍由原schema契约决定，布局不改变数据。

动态目录选择使用 `selections: Record<string, SchemaSelection>`，键为包含数组下标的绝对 JSON Pointer，例如 `/fundingAssets/0/assetId`。每项提供 `options`、`loading`、`error`、`invalid`、`disabled`、`hasMore` 和可选的 `emptyOptionLabel`。`selectionLabels` 由宿主提供本地化文本。表单复用 `FlareAdminEntitySelect`，不会退回任意文本输入；搜索、分页和重试分别发出 `selection-search(path, text)`、`selection-more(path)`、`selection-retry(path)`。宿主负责权限、目录请求、关联校验和旧请求隔离，组件不访问服务或理解钱包规则。

选择器只接受可用选项，失效的已保存值以禁用项显示；必填字段不提供清空入口；可选字段的空选项移除覆盖值，不保存空字符串 ID。有 `emptyOptionLabel` 时使用选择器内的默认项，不再重复展示字段重置链接。复杂对象和对象数组占满网格行，嵌套表单继承列数、字段顺序与 `groupLabels`，包括对象数组中的分组标题；容器不足 600px 时保持单列。红包配置页通过这些能力展示资金与钱包名称，并由宿主在引用失效或目录不可用时禁止保存。

管理表格的`stickyActions`仅在表格布局时固定操作列；滚动区域具有可访问名称，可用键盘聚焦并横向浏览。改变响应式模式不重建数据行、不触发业务请求、不改写排序或选择状态。

## 管理端插件操作的目录选择与记录编辑

`FlarePluginForm` 的 `selections` 以输入 id 为键复用 `SchemaSelection`，支持单个文本引用与 `options` 数组引用。组件使用 `FlareAdminEntitySelect`；`remote=false` 用于完整且有界的本地目录。`selectionLabels` 由宿主本地化，搜索、重试和续页分别发出 `selection-search`、`selection-retry`、`selection-more`。目录加载、错误、停用或缺失引用会阻止提交，目录响应更新不清除用户已编辑的其他字段，精确金额始终保留字符串。新建的目录数组不使用文本列表的空白占位项。

`FlarePluginView` 通过 `formInitialValues(actionId, row)` 在用户打开某个操作时捕获初值，使用原有类型表单提交，不读取业务服务或解析声明路径。`formSelections`、`selectionLabels` 和选择器事件沿用上述契约。`formChangeActions` 可指定必须有实际修改才允许提交的操作 id；底层 `FlarePluginForm.requireChange` 对比清理后的类型值，默认关闭。

这些是 Vue 宿主的管理端组合能力，不改变插件 wire 的表单类型或其他平台合同。Console 的钱包适配层负责有界目录分页、名称映射、权限撤回和应用切换隔离；钱包服务负责生成草稿编号、记录目标基准版本、双人发布和并发决定，组件不拥有这些业务规则。
