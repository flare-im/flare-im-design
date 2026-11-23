# 插件体验设计规范：通话、红包、钱包、实名

本文是四类插件体验（音视频通话、红包、钱包、实名认证）的唯一设计来源。Web、Tauri、iOS、Android、Flutter 五个应用的 PC 与手机形态都按本文实现，界面全部放在设计库 `flare-im-design` 的四个包里（`packages/vue-im-ui`、`packages/flutter-im-ui`、`packages/ios-im-ui`、`packages/android-im-ui`），应用只做路由、SDK 回调和数据映射。

- 现状清单与截图：`flare-social-examples/docs/plugin-experience/inventory.md`（截图在同目录 `shots/web/`）。本文的问题编号引用那份清单：G 渲染器通用、W 钱包、R 红包、C 通话、N 实名、P 平台与应用。
- 复用规则：`docs/ui-component-reuse-policy.md`。图标：`docs/ICON-LIBRARY.md`（Vue 用 Lucide，Flutter 与 Compose 用 Material，iOS 用 SF Symbols；只写语义名）。
- 组件契约：`spec/components.json`；token：`tokens/tokens.json`。

本文改进现有视觉语言，不另起一套：颜色、字号、圆角、间距全部来自 token；列表沿用 kit 设置页的列表风（`SettingsList` / `SettingsRow`）；按钮、标签、空态、面板全部用 kit 现有组件。确实缺的 token 和组件在第 9、10 节列出，由设计库补齐。

---

## 0. 读法

### 0.1 token 写法

本文用 `tokens.json` 的路径名写尺寸和颜色。各端生成物同名：

| 本文写法 | Vue CSS 变量 | Flutter / SwiftUI / Compose |
|---|---|---|
| `spacing.lg` | `--flare-size-spacing-lg` | `FlareSizes.spacingLg` |
| `radius.card` | `--flare-size-radius-card` | `FlareSizes.radiusCard` |
| `fontSize.xl` | `--flare-size-font-size-xl` | `FlareSizes.fontSizeXl` |
| `layout.controlHeightLg` | `--flare-size-layout-control-height-lg` | `FlareSizes.controlHeightLg` |
| `component.sheetDialogWidth` | `--flare-size-component-sheet-dialog-width` | `FlareSizes.componentSheetDialogWidth`（`component.*` 一律带 `component` 前缀） |
| `color.text.secondary` | `--flare-color-text-secondary` | `FlareColors.textSecondary`（Flutter `FlareColors.of(context).textSecondary`） |
| `textRole.title` | `--flare-text-role-title-*` | `FlareTextRoles.title` |

常用值：`spacing` 2xs 6 / sm 8 / md 12 / lg 16 / xl 20 / 2xl 24；`radius` md 8 / lg 10 / card 12 / xl 14 / full；`fontSize` sm 12 / md 13 / lg 14 / xl 15 / 2xl 16 / 3xl 18 / 4xl 20 / 5xl 24；控件高 sm 32 / md 40 / lg 48；触控 `layout.touchTarget` 48、`layout.touchTargetMin` 44。尺寸单位是逻辑像素（CSS px、Flutter 逻辑像素、iOS pt、Android dp）。

数字等宽：金额、时长、倒计时一律开等宽数字（CSS `font-variant-numeric: tabular-nums`；Flutter `FontFeature.tabularFigures()`；SwiftUI `.monospacedDigit()`；Compose `fontFeatureSettings = "tnum"`）。

### 0.2 形态

| 形态 | 判定（窗口宽） | 插件页放在哪 | 表单 / 确认 | 通话 |
|---|---|---|---|---|
| 手机 | < `breakpoints.sm` 600 | 整屏压栈页（`Screen`），底部安全区 | `BottomSheet`（`presentation: sheet`），最高 90% | 全屏 |
| 平板 / 窄窗 | 600–899 | 整屏页，正文限宽 `layout.directoryContentMaxWidth` 880 居中 | 居中对话框 | 浮动窗口 |
| PC | ≥ `breakpoints.md` 900 | 应用壳详情栏，正文限宽 880 | 居中对话框，宽 `component.sheetDialogWidth` 480 | 浮动窗口 |

Tauri 与 Web 同一份页面。Flutter 桌面窗口按窗口宽走同一张表。原生手机端（iOS、Android）只有手机形态；iPad 与 Android 平板按窗口宽走「平板」一行。

### 0.3 本文的「完成」

每个页面列出：版式（PC / 手机）、层级、用到的 kit 组件、图标语义名、文案（zh / en）、交互、状态（加载 / 空 / 错 / 禁用 / 离线 / 进行中）、键盘与读屏。四端实现同一张表；某端做不到的写在第 10 节「平台差异」，其余差异按缺陷处理。

---

## 1. 设计主线

1. **钱的界面安静、确定。** 金额是一屏里最大的字，只出现一次；状态永远是带色的标签，不出现原始枚举值；每个资金动作结束都落到一个结果页，告诉人「成了没有、钱在哪、下一步做什么」。
2. **一屏一个主动作。** 主动作是实心按钮；次要动作是描边或安静按钮；去别处看看的入口是列表行；危险动作单独放最后并要确认。声明的动作永远不画成裸文字链接（例外见 R2.6）。
3. **通话是一个舞台。** 所有通话界面（来电、呼叫、语音、视频、群通话）共用一块深色舞台，浅色主题下也是深色；从语音切到视频不换背景，不闪。
4. **红包有自己的颜色，只在红包里用。** `color.redPacket.*` 只用于红包卡、拆红包、发红包和红包详情；红包流程里的通用插件页（确认、记录）回到中性页面加品牌强调，不出现紫色大块金额。
5. **动作做完，页面就是新的。** 动作成功后发起它的页面自动重读；从下一页返回时上一页重读。用户不需要手动点刷新。

---

## 2. 插件页渲染规则（修复声明式页面，四端同一套）

钱包和实名的所有页面、红包的记录页都是插件清单声明的文档页，由 `FlarePluginPage` + `FlarePluginView` 渲染。下列规则写进 `spec/components.json` 的 `PluginPage.rules` / `PluginView.rules`，并在 `spec/plugin-view-vectors.json` 补向量；四端从同一组向量测。

### R1 页面框架

- 页头沿用 kit `Screen` 现有页头，不改：返回键（图标 `back`，读屏「返回 / Back」）+ 靠起始侧的大标题（`textRole.title` 20/700，PC 与手机相同）。
- 刷新键（图标 `refresh`，读屏「刷新 / Refresh」）只在**数据页**出现：页面含 `rows`、`entries`、`stats`、`hero`、`timeline`、`people`，或带取值路径的 `fields` / `status`。纯表单页、确认页、结果页、发红包页没有刷新键（现状每页都有，问题 G-01）。
- 手机触屏页下拉刷新；指针设备只用页头刷新键。
- 刷新中：页头下沿 2 高的进度细条（`color.primary`），正文保持原样、可滚动，不换成骨架。
- 正文：左右边距 PC `spacing.2xl` 24、手机 `spacing.lg` 16；块与块间距 `spacing.lg` 16；分组（`section`）之间 `spacing.2xl` 24。
- 分组标题（`section.label`）用 `textRole.section`（13/600，`color.text.secondary`），不用品牌色（现状「查看结果」「核对信息」是紫色小字，问题 G-02）。分组说明（section 里的 `note` 且 tone 为 info 时）用 `textRole.caption` 12，`color.text.secondary`，不加底色条。

### R2 动作分组与样式

渲染器按清单已有的字段给每个顶层动作归类，不需要插件新增字段：

| 角色 | 判定 | 画法 |
|---|---|---|
| 主动作 | `style: primary` | 实心按钮（`Button` variant primary） |
| 危险动作 | `style: danger` | 危险按钮或列表危险行，必经 `DangerConfirm` |
| 去向 | `target.kind: page`，无 `form` | 列表行（`SettingsRow`：标签 + `chevron-right`） |
| 命令 | 其余（operation、带 form、native） | 次要按钮（`Button` variant secondary） |

按页面原型放置：

**R2.1 总览页**（含 `hero` 或 `stats`，且去向 ≥ 4 个；如钱包首页、单个钱包页、实名状态页）

```
┌ 页头 ─────────────────────────── 刷新 ┐
│ ┌ 总览卡（hero / stats）────────────┐ │
│ │ 标签 12 secondary                  │ │
│ │ ¥1,000.00   32/700 tabular         │ │
│ │ 次要指标 13 secondary              │ │
│ │ [ 主动作 ][ 主动作 ][ 命令 ][ 命令 ] │ │  ← 快捷动作行
│ └────────────────────────────────────┘ │
│ 数据块（rows / entries …）             │
│ 分组标题「常用」                        │
│ ┌ 列表卡：去向行 … ───────────────────┐ │
│ 危险行（单独一张列表卡，danger 色）     │
└────────────────────────────────────────┘
```

- 快捷动作行放在总览卡内底部，距上方 `spacing.lg`。主动作最多 2 个，实心；命令最多 2 个，次要按钮；超出的主动作和命令按声明顺序进去向列表，以行画，行尾不画 chevron。
- 手机：快捷动作等分整行，高 `layout.controlHeightLg` 48，间距 `spacing.sm`。PC：按钮自然宽、最小宽 `component.actionMinWidth` 120（新 token），高 `layout.controlHeightMd` 40，靠起始侧排列。
- 去向列表：一张 `SettingsList` 卡（`radius.card` 12，`color.bg.primary`），行高手机 52 / PC 48，左侧图标位（清单动作若带 `icon` 语义名则画，否则不留空位），右侧 `chevron-right` 16。**主动作不进列表**；列表行的文字一律 `color.text.primary`（现状「开户」「开始认证」在列表里是紫色字，问题 G-03）。
- 分组：动作可以声明可选字段 `group`（`"common" | "records"`，协议词表新增，旧清单不写）。有 `group` 时按组画两张列表卡，组标题「常用 / Common」「记录与设置 / Records & settings」；没有时整张一组，按声明顺序。渲染器不按文案猜分组。钱包清单给去向补 `group`（10.7）。
- 危险动作在页面最底，单独一张列表卡，一行，文字 `color.error`，居中，无 chevron。

**R2.2 任务页**（含输入、或是确认 / 核对页：动作 ≤ 3 个且有一个主动作；如核对资金明细、确认支付、填写资料、提现）

- 手机：主动作放底部固定动作条：`color.bg.primary` 底、上沿 1 `color.border.secondary`、内边距 `spacing.md` `spacing.lg`、底部加安全区；主按钮整宽高 48。次要命令放主按钮上方，作安静按钮（`Button` appearance text，`color.text.secondary`），同一行最多 2 个。正文底部留出动作条高度。
- PC：动作行跟在正文最后一块之后，距 `spacing.2xl`；主按钮在前，最小宽 `component.actionMinWidth` 120，高 40；次要按钮跟在后面，间距 `spacing.sm`。不做吸底。
- 去向（「查看待确认操作」之类）放在动作条/动作行下方的「更多操作」列表卡里，不和主动作挤在一行（现状「确认并支付 / 取消确认 / 查看待确认操作」同排小按钮，问题 W-12）。

**R2.3 记录页与详情页**（主体是 `rows` 块的记录页：交易记录、充值记录、申请历史、红包记录；以及不属于 R2.1 / R2.2 的其余页面，如交易详情、记录详情）

- 记录行只有一个打开页面的行内动作（page 目标、不带 form、不是 danger）时不画键：整行是一个控件（读屏为按钮），行尾 `chevron-right` 16，点按执行该动作（交易记录、申请历史、红包记录）；多个动作或其它动作照旧画键（`spec/plugin-view-vectors.json` rowTap）。
- 行内动作照旧画在行里。页面级动作：一个主动作放页头右侧（PC 次要按钮 sm；手机页头文字键）；命令在正文后排成次要按钮行；其余去向进页面底部「更多操作」列表卡；危险动作同 R2.1。

**R2.4 消息卡片**（`embedded`，在会话里）

- 卡片脚：主动作实心 sm（高 32）在前，其余命令与去向次要 sm；最多 3 个，第 4 个起进 `more` 菜单。有 `presentation` 的卡（红包卡、通话记录卡）按各自组件，不走这一条。

**R2.5 状态与禁用**

- 进行中：被点的按钮显示转圈并锁定；同页其他动作禁用（不隐藏）。
- 某动作不可用但声明了原因（`disabledReason`）时：按钮禁用，按钮下方 `textRole.caption` 写原因。
- 删除旧的 `actionLayout: inline`（文字键成排换行）在页面里的用法：`FlarePluginPage` 不再默认 inline，四端按上面三种原型选择版式（现状只有 Vue 在页面里按「≥ 4 个去向」切 list，原生三端全部落到 inline 文字链接，这就是 iOS 钱包「一排文字链接」的根因，问题 P-01）。

**R2.6 允许的文字键**只有：卡片脚的「查看详情」键（R5）、说明文字里的行内链接、表单面板头部的「取消」。

### R3 状态值：一定有标签和色调

- 清单里凡是枚举（状态、类型、原因），取值都必须有 `values` 标签表；有好坏之分的（状态）还要有色调。现状缺表的：钱包 `flare.wallet.page.openings` 的 `/status` 列、红包 `flare.redpacket.page.sent` / `received` 的 `/status` 列（Web 应用在 `src/components/chat/redPacketPage.ts` 里自己补了翻译，属于应用代修插件，问题 R-07）；钱包结果页 `/state` 只映射了 completed / pending / rejected / unknown，向量里出现的 `prepared` 原样漏出（问题 W-10，截图 `wallet-result`）。
- **取值没在表里时**：渲染器画「未知状态 / Unknown status」+ neutral 色调，开发构建打印一次告警（插件 id、页面、路径、原值）；**不画原值**。只对声明了 `values` 的字段这样做；没有 `values` 的自由文本照常显示。
- **画法**：
  - `status` 块、`rows` 的状态列、`fields` 里带 `values` 且带色调的字段 → `Tag`（tone 映射：success / warning / danger / info / neutral；`brand` 当 info）。
  - 同一行里状态标签放在金额下方（记录行）；消息卡片里的 `status` 块留在正文第一行，卡片头不重复画（R5 版式与 `cardHeader` 向量，四端一致）。
- **协议补充**：`fields` 与 `rows.columns` 的 `values` 允许写 `{ "label": "已完成", "tone": "success" }`（现在只有字符串），核心解析后带 `tone` 给 kit。`spec/plugin-ui-vocabulary.json` 加这一形状；旧的字符串形态 tone 视为 neutral。
- **单号与凭据**：`format: reference` 的字段（资金单、原业务单、付款凭证、外部单号）不进主明细，收进折叠组「单号与凭据 / References」，每行尾部 `copy` 键（读屏「复制 单号」）。现状交易详情、记录详情把 `expense-order`、`upload:payment-proof-fixture` 这类机器值和金额平铺在一起（问题 G-09）；清单需要给这些字段标 `format: reference`。
- **清单门禁**：插件清单校验（`plugin-ui-vocabulary` 校验脚本）对路径末段是 `status` / `state` / `kind` / `type` / `reason` / `reasonCode` 的字段与列，要求有 `values`。

### R4 动作之后刷新

- **kit 负责**：`PluginPage` 在一个动作**成功结算**（operation 成功且没有发出消息卡）后发出 `refresh({ reason: "action" })`，宿主照拉一次（与下拉刷新同一路径，静默刷新，R1）。表单错误（formErrors）、被拒、取消不触发。
- **宿主负责**：
  1. 动作的结果是下一页（`continuation.page` 或 host target page）时压栈下一页；**下一页出栈回到本页时，本页刷新一次**（`refresh({ reason: "return" })`）。
  2. 结果页的「完成」键（R7）把流程弹回到发起页（压栈前记下的那一页），并刷新它。
  3. 发出消息卡的动作照旧关闭页面回到会话。
- iOS 应用现状：`PluginPageScreen.swift` 只在「被拒」或「成功且没发卡」时置 `changed`，压了下一页就不刷新，出栈时也只清 `next`；所以开户后首页不变（问题 P-02）。Android、Flutter、Web 应用按同一条核对。
- `spec/plugin-refresh-vectors.json` 增加 `afterAction`、`afterReturn` 两组向量。

### R5 卡片头

```
[图标 20] [标题 ……………………………… flex 1，单行省略] [查看详情 ›] [⋯]
```

- 标题占满剩余宽度（Vue/Flutter 已是；Compose `weight(1f)` 已是；**iOS 标题缺 `.frame(maxWidth: .infinity, alignment: .leading)`，且有两个 `Spacer`，详情键被挤到中间**，`PluginView.swift:415-436`，问题 P-03）。
- 详情键：`fontSize.md` 13，`color.text.secondary`，后接 `chevron-right` 16，整体触控区 ≥ 44；与标题间距 `spacing.sm`；与 `more` 键间距 `spacing.xs`。
- `more` 键：`IconButton` sm（30），图标 `more`，读屏「更多操作 / More actions」。
- 有脚部动作时详情键移到脚部末端（现规则不变）。

### R6 表单

**放在哪**

| 条件 | 手机 | PC |
|---|---|---|
| ≤ 4 个字段，且无 file / document / image / members | `BottomSheet` 表单（`FormSheet`） | 居中对话框，宽 480 |
| 其余，或页面本身只声明一个表单（现「页内表单」规则） | 整页表单，底部固定动作条 | 详情栏内页内表单，表单列宽 `component.formColumnWidth` 560（新 token），靠起始侧（现状撑满 880，问题 G-14） |

**字段**

- 标签在上：`fontSize.md` 13 / 500，`color.text.primary`；必填在标签后加 `*`（`color.error`），读屏读「必填 / required」。
- 输入框高：手机 48，PC 40；圆角 `radius.lg` 10；底色 `color.bg.secondary`，聚焦描边 `color.border.selected` + `color.focusRing`。
- 计数器（`0/100`）只在字段有 `maxLength` **且** ≤ 200 **且** 用户已输入时显示，位置在输入框下方右侧 `textRole.caption`。现状空字段就显示「0/100」「2/2」，噪音（问题 G-06）。
- 帮助文字在输入框下方 `textRole.caption` `color.text.secondary`。
- 错误：输入框描边 `color.error`；下方一行 `error` 图标 16 + 文案 `textRole.caption` `color.errorText`。读屏把错误挂到字段的描述上（`aria-describedby` / `accessibilityHint` / `semantics.error`）。
- 字段间距 `spacing.lg` 16；分组之间 `spacing.2xl`。
- `select` 选项 ≤ 4 个用分段选择卡（`RadioGroup` 卡片式：每项一张 48 高的卡，选中描边 `color.border.selected` + 勾 `check`）；手机竖排、PC 横排等分。> 4 个用 `Select`（手机弹 `BottomSheet` 列表，PC 下拉）。
- `select` **没有可选项**：画禁用的 `Select`，占位「暂无可选项 / No options available」，下方帮助文字说明原因（清单的 `emptyText`，没有则「暂时无法选择，请稍后再试」）；表单提交键禁用。现状画成一个未选中的单选框写着「暂无可用选项」（问题 G-07 / W-05，截图 `wallet-open-account-form`）。
- 国家 / 地区代码这类代码字段（`maxLength: 2` 的 ISO 代码）由清单改成 `select`（选项来自宿主的地区表，显示「中国大陆 CN」）；渲染器不猜。实名清单 `countryCode` 要改（问题 N-03）。

**提交**

- 提交键文案用动作 label；表单面板底部「取消 + 提交」等分（现状保留）；整页表单用 R2.2 的动作条。
- 点提交：先本地校验；有错 → 焦点移到第一个错字段并滚到可见，面板顶部不另起错误条。服务器返回字段错 → 同样处理。表单级错误 → 提交键上方 `StatusBanner` danger。
- 进行中：提交键转圈；所有字段只读；面板不能下滑关闭、Esc 无效（钱相关、实名相关一律如此）。
- 上传中（file / document）：提交键禁用，键下方写「正在上传 2/3 / Uploading 2/3」。

**块绑定的输入不画成字段（R6.1）**

- 被某个块的 `inputName` 引用的输入（`protected-media` 的 `materialId`、`choices` 的 `selection`）只由那个块填值，永远不画成字段；只依赖这类输入的动作是块动作（如「查看证件」由证件缩略图触发），不进页面动作区，也不触发「页内表单」规则。
- 现状实名状态页在没有证件时把 `materialId` 画成了一个「材料」文本框加一个「查看证件」大按钮（问题 G-11 / N-01，截图 `realname-entry`）。

### R7 结果页

资金动作、实名提交、红包发送失败后的「结果」都用同一个结果版式。新增块 `result`（协议词表加一种块，核心解析）：

```json
{ "kind": "result", "statePath": "/state",
  "values": { "completed": { "label": "转账成功", "tone": "success" },
              "pending":   { "label": "处理中",   "tone": "info" },
              "rejected":  { "label": "未成功",   "tone": "danger" },
              "unknown":   { "label": "结果待确认", "tone": "warning" } },
  "amountPath": "/amount", "descriptionPath": "/message" }
```

版式（手机 / PC 相同，PC 内容列宽 `component.formColumnWidth` 560 居中）：

```
        ( 图标 56，tone 底色圆 )        ← success: success / info: clock / danger: error / warning: warning
           转账成功                     ← textRole.title 20/700，居中
           ¥99.00                       ← component.amountHeroFontSize 32/700 tabular，居中（有 amountPath 时）
     说明一行 14 secondary，居中，最多 3 行
  ┌ 明细（DescriptionList，两栏 label/value）┐
  └──────────────────────────────────────────┘
  [            完成（主）            ]     ← 手机吸底整宽；PC 居中，宽 240
  [      查看详情 / 查看原单（次要）     ]
```

- 图标圆：直径 `component.resultIconSize` 56；底色 = tone 色 10% 透明度（`opacity.tintWeak`），图标 32、tone 色。
- 明细用 `DescriptionList`（label 左、value 右对齐；手机单栏，PC 单栏）。金额值带币种符号（R10）。
- 「完成」：主按钮。行为见 R4.2（弹回发起页并刷新）；没有发起页时关闭页面。读屏：页面出现时把标题和说明作为一次礼貌播报（`aria-live=polite` / `UIAccessibility.post(.announcement)` / `liveRegion`）。
- 状态为 `pending` 时页面每 3 秒静默刷新一次（复用 `refreshMs` 机制），最多 60 秒；变为终态后停止并播报。
- 现状结果页只是两行字段，状态原样显示 `prepared`，没有图标、金额、完成键（问题 G-10 / W-10）。

### R8 加载、空、错、离线、不可用

| 状态 | 画法 | 文案 zh / en |
|---|---|---|
| 首次加载 | 300 ms 内不画任何东西；之后按原型画骨架（`Skeleton`：总览页 = 一张 160 高的卡 + 3 行列表；记录页 = 6 行；任务页 = 4 个字段） | 读屏「正在加载 / Loading」 |
| 刷新 | R1 进度细条 | — |
| 空（数据块无数据） | 块内：`EmptyState` 紧凑型（图标 32，标题 14/600，说明 13），图标用该页语义（钱包 `wallet`、记录 `clock`、红包 `red-packet`、实名 `admin`）；页面有创建类主动作时空态下方放这个主动作（实心） | 清单 `emptyText`；缺省「暂无记录 / Nothing here yet」 |
| 读取失败 | 整页 `EmptyState`：图标 `error`，标题「没有读到内容」，说明为宿主给的错误（脱敏），按钮「重试」 | 没有读到内容 / Couldn't load this page；重试 / Retry |
| 离线 | 页头下方 `StatusBanner` warning「网络不可用，显示的是上次读取的内容 / You're offline. Showing what was loaded last.」；所有动作禁用，主按钮下方 caption 写「联网后可用 / Available when you're online」 | — |
| 插件不可用 | 现状保留（`EmptyState` + 原因文案，仅目录不可达时有重试） | — |
| 动作失败 | 页面顶部 `StatusBanner` danger，带关闭键；文案用宿主给的可读原因，不用通用句「插件操作未完成，请检查权限及当前业务状态」（问题 G-13） | — |

离线由宿主传入新属性 `offline: boolean`（四端 `PluginPage` 新增）。

### R9 动作可见性

- 同一页面同一时刻可见的动作，不允许出现两个同名动作（同 label）。核心已按 `hiddenWhen` 解析；渲染器再做一道兜底：同名动作只画第一个，开发构建告警。（截图 `realname-documents` 在没有数据时画出 4 个「提交审核」，是 fixture 没带数据的结果，但兜底仍要有。）

### R10 金额

- 金额统一格式：币种符号前缀（`¥ $ € £ JP¥ HK$`，沿用 `capability-ui.ts` 的 `CURRENCY_PREFIX`；不认识的币种写「100.00 XYZ」），千分位，按币种小数位，等宽数字。不在大金额后写「CNY」（现状红包确认页「26.64 CNY」、红包详情「2.96 CNY」，问题 R-04）。
- 总览大额：`component.amountHeroFontSize` 32/700（手机、PC 同），`color.text.primary`，**不用品牌紫**（现状 hero tone brand 画紫字紫底，问题 G-04）。卡内次额：`fontSize.3xl` 18/600。
- 列表金额：`fontSize.2xl` 16/600 右对齐；收入 `color.successText` 带「+」，支出 `color.text.primary` 带「−」（U+2212）。
- 隐藏余额：金额替换为「••••」（4 个 U+2022），读屏「余额已隐藏 / Balance hidden」；切换键图标 `eye` / `eye-off`，读屏「隐藏余额 / 显示余额」，`aria-pressed`。

### R11 键盘与读屏（插件页通用）

- 页标题是一级标题；分组标题是二级标题。
- Tab 顺序：页头返回 → 主动作 → 数据块 → 列表行 → 危险行。整页表单：字段 → 提交。
- Enter 提交单行输入所在的表单（textarea 里不提交）；Esc 关闭面板（进行中无效）；面板关闭后焦点回到打开它的控件。
- 列表行是一个按钮，读屏读「标签，按钮」；带状态的读「标签，状态 已完成，按钮」。
- 金额读法：「余额 1000 元 / Balance 1,000.00 yuan」由读屏自然读出，组件给 `aria-label` 拼好币种名（`¥` 不交给读屏猜）。
- 所有纯图标键有名字（ICON-LIBRARY「纯图标控件」）。

### R12 总览账户版式（账户外观的推导）

- Vue 现在把钱包类文档推导成账户外观（`account/account.ts` 的 `flareAccountDocument`：有一个带「可遮挡金额 hero」的分组 + 恰好一个 rows 块），但只在宿主传 `appearance: "account"` 时才推导；Web 应用按 `pluginId === 'flare.wallet'` 传（`pluginHost.ts:97`），iOS 应用从不传。
- 改为：`PluginPage` 的 `appearance` 缺省时**按结构自动推导**（同一条规则写进 `spec/plugin-view-vectors.json` 的 `rules.accountDerivation`，四端各实现一次），宿主不再按插件 id 选外观；显式传 `document` 可关闭。

---

## 3. 通话

组件：`FlareCallSurface`（窗口 / 全屏承载）、`FlareCallView`（1:1）、`FlareGroupCallView`、`FlareIncomingCall`、`FlareCallControls`、`FlareCallDock`、`FlareCallDevicePicker`、`FlareCallRecordCard`、`FlareScreenShare`。

### 3.0 舞台与 token（新增，见第 9 节）

- 所有通话界面用深色舞台 `color.call.stage`，顶部 40% 叠一层 `color.call.stageTint` 的纵向渐变（到透明）；浅色、深色主题相同。现状 Vue 与 Flutter 的语音通话是白底、iOS 与 Compose 是深底、来电是紫色渐变，四端不一致（问题 C-01）。
- 舞台上文字：主 `color.call.onStage`，次 `color.call.onStageSecondary`；控件底 `color.call.control`，悬停 / 按下 `color.call.controlHover`；开启态控件底 `color.call.controlActive`、图标 `color.call.onControlActive`。
- 挂断 / 拒接 `color.call.hangup`（按下 `color.call.hangupPressed`），接听 `color.call.accept`（按下 `color.call.acceptPressed`），说话光环 `color.call.speaking`。去掉各端写死的 `#ff5a5f`、`#EF4444`、`#22C55E`、`#34d17f`、`#22232b`、`0xFF111318`（清单 C-02）。

### 3.1 窗口尺寸

| 场景 | PC / 平板 | 手机 |
|---|---|---|
| 1:1 语音 | 浮动窗口 `component.callWindowAudioWidth` 400 × `callWindowAudioHeight` 560（现状 480×480 白色方窗，问题 C-14） | 全屏 |
| 1:1 视频、群通话 | `callWindowVideoWidth` 720 × `callWindowVideoHeight` 540 | 全屏 |
| 展开 | 视口 − 2×`spacing.xl`，高 90vh | — |

- 窗口：`radius.xl` 14，`shadows.xl`，可拖动标题区（顶部 48 高）。Esc 不挂断（只在展开态退出展开）。
- 手机是真正的全屏：不留遮罩边、不画圆角，舞台铺到状态栏与底部安全区之下（Web 现状在 375 宽上是四周留灰边的卡片，问题 C-15；`FlareCallSurface` 在 < `breakpoints.sm` 时改为全屏）。
- 顶栏（手机在状态栏下）：左 `collapse` 最小化键（读屏「最小化 / Minimize」）；中间对端名 + 状态（只在视频已接通时出现在顶栏，其余放舞台中央）；右侧 PC 有 `expand` / `collapse` 展开键，端到端加密时有 `lock` 16 + 「端到端加密 / End-to-end encrypted」caption（Vue 现为英文硬编码，需进 i18n，问题 C-09）。

### 3.2 来电 `FlareIncomingCall`

**手机（全屏）**

```
            （顶部 22%）
          头像 96（圆）
          周屿          24/600 onStage
     邀请你语音通话      15 onStageSecondary
            ……
   ( 拒接 64 红 )        ( 接听 64 绿 )      ← 两键中心在 1/4 与 3/4 宽处，距底 64 + 安全区
      拒接 12               接听 12
```

- 视频来电：接听键图标 `video`，另加第三个小键「语音接听 / Answer audio」（`IconButton` md，图标 `phone`）在两键中间上方 24。
- 振铃动画：头像外圈 2 宽的 `color.call.onStage` 20% 光环，1.6 s 呼吸；`prefers-reduced-motion` 时静止。

**PC（非模态横幅，新增 `presentation: "banner"`）**

- 右上角，距窗口边 `spacing.lg`，宽 `component.callIncomingBannerWidth` 360，高 88，`radius.xl`，舞台底色，`shadows.lg`，层级 `zIndex.toast` 之下、`zIndex.modal` 之上。
- 内容：头像 48 · 名字 15/600 + 「邀请你视频通话」13 · 右侧拒接 40 红圈、接听 40 绿圈（间距 `spacing.sm`）。
- 不挡住当前操作；接听后打开 3.1 的窗口。快捷键：窗口在前台时 Enter 接听不响应（防误触），用户必须点击或 Tab 到键再按 Space / Enter。
- 现状 PC 来电是居中模态（问题 C-03）。

**文案**：接听 / Answer；拒接 / Decline；邀请你语音通话 / Invites you to a voice call；邀请你视频通话 / Invites you to a video call；语音接听 / Answer with audio。

**读屏**：出现时播报「周屿 邀请你语音通话」；两键有名字；来电期间焦点进入横幅 / 全屏界面的接听键。

**焦点环**：圆形键的焦点环跟随圆角（2 宽 `color.focusRing`，外扩 3），不画方框（现状拒接键是圆键套方形焦点框，问题 C-12）。通话里所有圆键同此。

### 3.3 呼叫中 / 已接通 / 重连 / 失败 / 结束（`FlareCallView`）

舞台中央（语音，及视频未出画面时）：

```
          头像 96（PC 窗口 80）
          周屿               24/600（PC 20/600）
          状态行             15 onStageSecondary，tabular
```

| state | 状态行 zh / en | 控件 | 其他 |
|---|---|---|---|
| calling | 正在呼叫… / Calling… ；视频「等待对方接受邀请… / Waiting for them to accept…」 | 麦克风、扬声器 / 设备、（视频）摄像头、挂断 | 头像呼吸光环 |
| ringing | 对方响铃中… / Ringing… | 同上 | 同上 |
| connected | 时长 `03:24`（mm:ss，> 1 h 为 h:mm:ss） | 全部 | 对端静音时状态行后加 `mic-off` 14 + 「对方已静音」；对端说话时头像 `color.call.speaking` 3 宽光环 |
| reconnecting | 网络不稳定，正在重连… / Reconnecting… | 全部保留，可用 | 状态行前 8 圆点 `color.warning`，脉冲；视频画面保持最后一帧并压暗 40% |
| failed | 宿主给的原因（如「对方暂时无法接听」）；缺省「通话连接失败 / Call failed」 | 控件条换成两键：「关闭」（次要）与「重拨」（主，`phone` / `video`），手机等分整宽、PC 各宽 160，放在原控件条位置 | 现状「关闭」挂在左上状态行下、控件条仍在（问题 C-10） |
| ended（新增，问题 C-11） | 通话已结束 · 03:24 / Call ended · 03:24 | 全部禁用 | 1.5 s 后自动关闭；读屏播报 |

视频已接通：远端画面铺满舞台（`object-fit: cover`）；本地预览右上角 `component.callPreviewWidth` 112 宽、9:16，`radius.lg`，距边 `spacing.lg`，可拖动并吸附四角；点击预览互换大小画面。顶栏 4 秒无操作自动淡出（指针移动 / 轻点恢复），reduced-motion 时不淡出。

**控件条 `FlareCallControls`**

- 圆键直径 `component.callControlSize` 56，图标 24，标签 12 在键下 `spacing.xs`；键间距手机 `spacing.lg`、PC `spacing.2xl`；控件条距底 `spacing.2xl` + 安全区。
- 顺序：麦克风（`mic` / `mic-off`）、扬声器或设备（`speaker` / `speaker-off`；PC 是设备键，见 3.6）、摄像头（`video` / `camera-off`，视频时）、翻转（`switch-camera`，手机视频时）、切到视频（`video`，语音且允许时）、加人（`person-add`，群）、挂断（`end-call`，红）。
- 手机 > 4 个开关键：开关键一行，挂断单独一行居中、直径 `component.callHangupSize` 64。PC 一行，挂断最后、前面多一个 `spacing.2xl` 间隔。
- 开关键是开关语义（`role=switch` / `aria-checked`；SwiftUI `.accessibilityAddTraits(.isToggle)`；Compose `Role.Switch`），读屏「麦克风，已关闭」。
- `disabled`（宿主还没建好媒体会话）：除挂断外全部禁用、按 `opacity.disabled`（0.5）透明。Flutter、iOS、Compose 补这个属性（C-04）。

**键盘（PC）**：M 切麦克风，V 切摄像头，Ctrl/⌘+Shift+H 挂断（不用单键挂断防误触）；快捷键写在键的 tooltip 里。

### 3.4 群通话 `FlareGroupCallView`

- 宫格：1 人全屏；2 人左右；3 人上 2 下 1（下排居中，不留空格，现状 2×2 空一格像缺人，问题 C-13）；4 人 2×2；5–6 人 PC 3×2、手机 2×3；7–9 人 3×3；> 9 不支持（`maxGroupParticipants` 9）。
- 格子：间距手机 `spacing.xs` 4、PC `spacing.sm` 8；`radius.card` 12；底色 `color.call.tile`；视频画面 cover。
- 关摄像头的格子：头像 `component.callTileAvatar` 56 居中。
- 名牌：格子左下 `spacing.sm`，`color.call.chip` 底、`radius.sm`、`fontSize.sm` 12 onStage，内边距 2/6；静音时名牌前 `mic-off` 12；本地格子名牌写「我 / You」。
- 说话：格子内描边 2 `color.call.speaking`。
- 点格子：放大为主画面（其余排成底部横条，格子高 96），再点还原（Vue 有 `selectParticipant`，三端补，C-05）。
- 顶部：群名 15/600 + 「6 人 · 08:41」13 secondary。
- 有人在呼叫中未接：格子内头像 + 「呼叫中… / Calling…」12，头像 50% 透明。
- 状态 / 恢复：`statusDetail`、`recover` 与 1:1 相同（Flutter、iOS、Compose 补，C-05）。

### 3.5 最小化悬浮条 `FlareCallDock`

- 胶囊：高 `component.callDockHeight` 56，`radius.full`，舞台底色（现状 Vue 用品牌紫底，问题 C-06），`shadows.lg`，内边距左 `spacing.xs` 右 `spacing.sm`。
- 内容：头像 40（已接通时外圈 2 宽 `color.call.speaking` 呼吸）· 名字 14/600 单行最宽 140 · 状态 12（已接通：时长 tabular；calling/ringing：「等待接听」；reconnecting：黄点 + 「正在重连」；failed：红字「通话中断」）· 麦克风键 36 · 挂断键 36 红。
- 位置：PC 在应用窗口右下，距边 `spacing.2xl`，不压输入框（在输入框上方 `spacing.lg`）；手机在顶部安全区下方、右侧，可拖动，松手吸附左右边。
- 点胶囊主体回到通话（读屏「返回通话 / Return to call」）。
- Flutter、iOS、Compose 补 `state` / `statusDetail`（C-06）；Flutter 改用 `FlareIcon('video'|'phone')`，iOS 改用 `IconView`（现直接写 SF Symbol 名）。

### 3.6 设备选择 `FlareCallDevicePicker`

- 只在能枚举设备的平台出现：Web / Tauri、Flutter 桌面。iOS、Android 手机：扬声器键是开关；外接设备由宿主放系统路由选择键（iOS `AVRoutePickerView`、Android 输出切换），通过控件条的 `devices` 插槽放进来（第 10 节平台差异）。
- PC：点设备键弹出面板，锚定在键上方 `spacing.sm`，宽 280，底 `color.call.popover`（新 token，替代写死的 `#22232b`），`radius.card`，内边距 `spacing.md`。
- 分组：麦克风 / 扬声器 / 摄像头；组标题 `fontSize.sm` 12 onStageSecondary；选项行高 44，名字 14 单行省略，选中项尾部 `check` 16（替换 `✓` 字符，C-07）；单选语义（`role=radio`）。
- 权限：未授权时组上方 `CapabilityBoundary`（现状保留）。设备切换中：该组选项禁用、组标题后小转圈。
- 键盘：上下键在组内移动，Enter 选中，Esc 关闭回到设备键。

### 3.7 群通话选人

- 现有「选择要呼叫的成员」对话框保留（截图 `call-group-invite-picker`）：确定键在未选人时禁用（现状已是）；已选人数写在确定键上「确定（3）/ Call (3)」；超出 8 人（9 含自己）后其余行禁用，顶部 caption「最多 9 人同时通话」。

### 3.8 会话里的通话记录 `FlareCallRecordCard`

四端已对齐（19 个状态向量）。只补两点：图标与文字间距统一 `spacing.sm`；「回拨 / 加入」键高 32、次要样式，忙时转圈（现状保留）。

### 3.9 屏幕共享 `FlareScreenShare`

- 开始 / 停止键图标统一 `screen-share`（Vue 现在用 `devices` / `block`，C-08）；Flutter 的默认文案改走 `FlareStrings`，去掉 `Icons.block`。

---

## 4. 红包

组件：`FlareRedPacketComposer`、`FlareRedPacketCard`、`FlareRedPacketOpenSheet`、`FlareRedPacketDetail`、`RedPacketArch`、`FlarePaymentConfirmation`；新增 `FlareRedPacketReview`（4.3）。

### 4.1 入口

- 输入框「+」面板：红包格子图标 `red-packet`，文字「红包 / Red packet」。面板点开必须立即出现（≤ 100 ms）：宿主在打开会话时预取面板项；插件项还没到时画 `Skeleton` 方块占位，不等待（iOS 现状等约 1 s，根因在应用 `ChatView.swift:660-668` 打开时才异步取菜单，问题 P-04）。
- 面板现状 PC 一屏 12 格、手机一屏 8 格，红包与通话都不在第一屏（问题 R-01）。宿主组面板时把常用项排在第一屏：图片、文件、红包、语音通话、视频通话、位置；其余内置与插件项随后（插件清单的 `order` 只在插件项之间排序）。

### 4.2 发红包 `FlareRedPacketComposer`

**放在哪**：手机整屏页；PC 在会话右侧详情栏（宽 `layout.detailPaneMaxWidth` 420）。

```
┌ 页头：返回 · 发红包 ──────────────────────┐   ← 无刷新键（R1）
│ ▔▔▔ 红包弧（RedPacketArch compact，32 高）▔▔ │   ← 贴页头下沿整宽，不放进卡片里裁切（R-09）
│ [ 普通红包 | 拼手气红包 | 专属红包 ]          │   ← SegmentedControl，accent=redPacket；单聊只有普通时不画
│ ┌ 卡片 radius.card ────────────────────┐ │
│ │ 拼  总金额                     ¥ 0.00 │ │   ← 行高 56；lucky 时标签前「拼」角标
│ │     红包个数                    1 个  │ │
│ └──────────────────────────────────────┘ │
│   本群共 12 人                               │   ← caption，群里才有
│ ┌ 卡片 ─────────────────────────────────┐ │
│ │ 恭喜发财，大吉大利                      │ │   ← 祝福语，占位即默认语，最多 24 字
│ └──────────────────────────────────────┘ │
│                ¥ 26.64                     │   ← component.redPacketAmountFontSize 44（PC 36）
│        [      塞钱进红包      ]             │   ← 红色主键，整宽，高 48，radius.lg
│      未领取的红包将于 24 小时后退回          │   ← caption tertiary
└────────────────────────────────────────────┘
```

- 三种模式的字段：普通「单个金额」「红包个数」（单聊只有「金额」）；拼手气「总金额」「红包个数」；专属「发给谁」（行：头像 24 + 名字 + `chevron-right`，未选为「选择 / Choose」品牌色字）+「金额」。
- 金额行：右侧输入右对齐，`fontSize.3xl` 18/600 tabular，前缀「¥」；数字键盘（手机 decimal）。
- 校验（现有 `errorField` / `focusField`，Flutter、iOS、Compose 补）：字段出错时该行底色 `color.message.failed.background`、行下 caption 写原因，焦点移过去；常见文案：
  - 单个红包金额不能超过 200 元 / Each share can be at most ¥200
  - 红包个数不能超过 100 个 / At most 100 shares
  - 请选择发给谁 / Choose who gets it
  - 拼手气红包每人至少 0.01 元 / Each share must be at least ¥0.01
- 金额范围提示（现状在卡片下方红字「金额范围 0.01–200.00 CNY」，问题 R-02）改为：只在出错时出现；未出错时不显示。
- 主键文案「塞钱进红包 / Put money in」（现「确认红包」）；禁用条件：总额为 0 或有字段错。进行中：转圈 + 全部字段只读。
- 服务失败：卡片上方 `StatusBanner` danger，字段值保留（现状已对）。
- iOS 去掉自绘 `RedPacketActionButton`，用 `ButtonView` + redPacket accent；iOS、Compose 补红包弧（P-05）。

### 4.3 确认与付款

目标流程：发红包 → 塞钱进红包 → **付款确认面板**（`FlarePaymentConfirmation`，引擎给订单）→ 宿主验证身份（支付密码 / 生物识别 / `ReauthSheet`）→ 卡片发到会话 → 发红包页关闭。

- 清单若仍声明一个确认页（`flare.redpacket.page.confirm`），它的视图改用新呈现 `presentation.renderer: "redPacket.review"`，由新组件 `FlareRedPacketReview` 画：红包弧 + 总金额 44 + 「拼手气红包 · 3 个」+ 祝福语 + 红色主键「发红包 / Send」。不再是紫色 hero 的通用插件页（问题 R-03，截图 `rp-confirm`）。

**付款确认面板 `FlarePaymentConfirmation`**

- 手机：`BottomSheet`；PC：对话框宽 400。
- 内容：标题「确认付款 / Confirm payment」15/600 居中；「由 红包 发起 / Requested by Red packet」caption；金额 `component.amountHeroFontSize` 32 居中；明细行（收款方、说明、订单号——订单号默认折叠为「订单号 ›」，点开显示并可复制；四端统一，现状 Flutter 用 ExpansionTile，iOS / Compose 常显，问题 P-06）；倒计时「9:41 内有效」caption（< 60 s 变 `color.warning`）。
- 主键「确认付款 / Pay」，次要「取消 / Cancel」。凭证插槽（支付密码 6 格）在主键上方。
- 错误：主键上方 `StatusBanner` danger（如「支付密码错误，还可以再试 2 次」），面板不关。busy：「正在验证身份… / Verifying…」，所有键锁定，不能关。过期：金额灰显，主键换成「重新发起 / Start again」，说明「付款已过期」。
- 余额不足（新增状态 `insufficient`）：主键禁用，键上方 caption 「余额不足，还差 ¥6.64」+ 次要键「去充值 / Top up」（去向钱包充值页）。

### 4.4 红包卡片 `FlareRedPacketCard`

- 宽 `component.redPacketCardWidth` 248，`radius.card`；上部红色渐变（`redPacket.start → end`）区 72 高：左侧红包图形 36、右侧祝福语 15/600 `redPacket.onSurface` 两行省略、其下状态 12（「领取红包 / 已领取 / 已被领完 / 已过期 / 已退回」）；下部 28 高说明条 `color.bg.primary` 上写品牌名 12 tertiary 与角标（「拼手气」「专属 · 给 周屿」）。
- 已领取 / 领完 / 过期 / 退回：整卡按 `component.redPacketFadedMix` 0.4 淡化，状态文字可读（对比 ≥ 4.5，按 `color.redPacket.fadedInk`）。
- busy：右上角转圈 16，不可点；disabled：淡化 + 状态「暂不可用」。
- 点卡片：未领 → 打开拆红包面板（4.5）；其余 → 红包详情（4.6）。
- 现状四端一致，保留；在 Web 应用的演练数据里点卡片进的是通用插件页（紫色「2.96 CNY」与小紫键「领取红包」，截图 `rp-open`、`rp-after-claim`），真实数据走 `RedPacketPageContent.vue` 的 kit 面板。宿主应保证真实与演练都进 kit 面板（问题 R-05）。

### 4.5 拆红包 `FlareRedPacketOpenSheet`

- 信封：宽 `component.redPacketEnvelopeWidth` 300，最小高 `redPacketEnvelopeMinHeight` 440，`radius.2xl` 18；手机居中模态（遮罩 `color.scrim`），PC 同。
- 布局：右上 `close` 键（36，读屏「关闭 / Close」）；头像 56 + 「苏晚晴的红包 / Red packet from 苏晚晴」15/600；类型 12（「拼手气红包」）；祝福语 20/600 两行；「開」键 `component.redPacketOpenButtonSize` 96 金色（`redPacket.gold → goldDeep`），位于信封 62% 高处；底部「查看领取详情 ›」（只在 `canViewDetails`）。
- 状态：ready（開）；opening（開键 3D 翻转 0.8 s 循环，reduced-motion 时改为转圈）；finished「手慢了，红包派完了 / Too late, all gone」；expired「该红包已超过 24 小时，已过期 / This red packet has expired」；refunded「红包已退回 / Returned to sender」；notEligible 宿主文案（「仅 周屿 可领取」）；error「没有领到，请重试 / Couldn't open it. Try again.」+「重试」键（`reviewOnError` 时为「查看结果」，Flutter、iOS、Compose 补，问题 R-06）。
- 开成功后直接切到红包详情（4.6），不先关闭再打开。
- 键盘：Enter / Space 拆；Esc 关闭（opening 时无效）。读屏：信封是对话框，标题「苏晚晴的红包」。

### 4.6 红包详情 `FlareRedPacketDetail`

- 四端统一为 Vue / Flutter 的版式：中性页头（返回 + 「红包详情」）、页头下红包弧（`RedPacketArch`，非 compact）、发送者头像 56 + 「苏晚晴的红包」、祝福语、我领到的金额 `component.redPacketDetailAmountFontSize` 32（领取者才有）+ 「已存入钱包 ›」（`success` 图标 16，点击去钱包；iOS、Compose 补这一行，现为红色标题栏 + 渐变扇形，问题 P-07）。
- 汇总行：「已领取 2/3 个，共 ¥5.00 / ¥8.88」13 secondary；过期退回时「红包已过期，已退回 ¥4.00」。
- 领取列表：行高 64：头像 40 · 名字 15 + 时间 12 tertiary · 金额 16/600 右；手气最佳在金额下方 `star` 12 + 「手气最佳」12 `color.warning`。
- PC：详情在详情栏或对话框里，内容列限宽 420 居中，红包弧随列宽（现状撑满 1280 窗口，弧和领取列表通栏，问题 R-08）。
- Compose 补 `nowMs`。

### 4.7 红包记录

- 入口「我 → 红包记录」。版式：顶部 `SegmentedControl`「收到的 / 发出的」（替代现在的两个按钮「我收到的红包 / 查看待确认操作」，截图 `redpacket-records-entry`，问题 R-10）；其下汇总卡：「2026 年共收到 / 共发出」+ 金额 32 + 「共 12 个」。
- 记录行（R2.3）：左 红包图形 36 · 标题（收到：发送者名；发出：「拼手气红包」）15 + 时间 12 · 右 金额 16/600 + 状态 `Tag`（未领完 info / 已领完 neutral / 已过期 warning / 已退回 neutral）。
- 空态：图标 `red-packet`，「还没有红包记录 / No red packets yet」。
- 清单补 `/status` 的 `values`（R3），删掉 Web 应用 `redPacketPage.ts` 里的代翻译。
- 机制（协议可选字段，旧清单照旧）：
  - **页签**：`page` 贡献可选 `tabs`（2–4 个 `{page, label}`，本插件的同级页面，每页声明同一组）。解析后的视图带 `tabs: [{page, label, selected}]`；kit 在正文顶部画 `SegmentedControl`（tablist），选中未选的页签发出 `tab(page)`，宿主以该页替换栈顶（参数照旧，不新增返回层级）；加载期间保留上次页签并选中正在加载的页。红包的 `flare.redpacket.page.received` / `sent` 两页即「收到的 / 发出的」，「我 → 红包记录」打开「收到的」。规则与向量：`spec/plugin-view-vectors.json` `rules.pageTabs`、`pageTabs`。
  - **记录行图标**：`rows` 块可选 `icon`（kit 图标名）。有 `icon` 时每行按 5.8 账单行画：36 圆底图标、第二列为标题（收到：发送者，`person` 格显示名字；发出：红包类型）、其余列（时间）在标题下、第一列为行尾金额、状态 `Tag` 在金额下；没有行时空态用该图标与清单的 `emptyText`（「还没有红包记录」）。规则与向量：`rules.rowsIcon`、`rowsIcon`。
  - **汇总卡**：红包服务端在记录查询的第一页写 `summary {amount, count, assetLabel}`（当前出资资产、本自然年，按 UTC 计年），清单用现有 `hero`（「今年共收到 / 今年共发出」+ 金额 32 + 资产）与 `fields`（「红包个数」，`count` 格式）绑定。标签写「今年」而不是「2026 年」：页面数据不带查看者语言与时区，年份数字由插件写入会无法翻译。

---

## 5. 钱包

所有钱包页是 `flare.wallet` 清单的声明式页面。本节规定每页套用的原型（第 2 节）和需要清单配合的地方。

### 5.1 钱包首页（有账户）`flare.wallet.page.home` → 账户外观（R12）

```
手机                                         PC（详情栏，限宽 880）
┌ 钱包                          (eye) ┐    ┌ 钱包                             刷新 ┐
│ ┌ 总览卡（brand 不着色，bg.primary）┐│    │ ┌ 零钱钱包 ──────┐ ┌ 旅行钱包 ─────┐ │
│ │ 零钱钱包 · CNY            正常   ││    │ │ ¥1,000.00       │ │ $88.50        │ │
│ │ ¥1,000.00                       ││    │ │ 正常 · 查看明细›│ │ 正常 · 查看明细›│ │
│ │ [  充值  ][  提现  ]             ││    │ └─────────────────┘ └───────────────┘ │
│ └─────────────────────────────────┘│    │ [充值][提现][收款方式]           (eye) │
│ 其他钱包                            │    │ 常用 ……（列表卡）                     │
│ ┌ 旅行钱包 · USD   $88.50   ›     ┐│    │ 记录与设置 ……（列表卡）               │
│ 常用 / 记录与设置（列表卡）          │    └────────────────────────────────────────┘
└─────────────────────────────────────┘
```

- 手机：只有一个钱包时整卡；多个钱包时默认钱包放总览卡，其余放「其他钱包」列表（行：钱包名 15 + 币种 12 · 余额 16/600 · chevron）。PC：钱包卡两列网格（现状），卡高 ≤ 160（现状测试已守）。
- 钱包名：用 `/instanceKey` 的 `values` 标签（「余额钱包」等），不显示「CNY · cash」这类技术串当标题（现状单个钱包页标题是「CNY · cash」，问题 W-03）；币种与资金类型做副标题。
- 状态 `正常` 用 `Tag` success（当前是加粗黑字，问题 W-04）。
- 「账户信息」折叠行（现状浮在页面上、没有容器，问题 W-06）改为去向列表里的一行「账户信息 ›」，点开是 `DescriptionList` 面板。
- 快捷动作：充值（主）、提现（主），在总览卡内，手机等分整宽 48 高（现状手机标题行挤三个 32 高小键，问题 W-13）；收款方式进列表。
- 「待确认操作」：有 `journal.known=false` 的待确认单时，总览卡上方 `StatusBanner` warning「有资金操作等待确认，请先查看原单，勿重新付款」+ 行内键「查看 / Review」；没有时这一项不出现在列表里（现状常驻一行「查看待确认操作」，问题 W-07）。
- 列表分组（R2.1）：常用 = 交易记录、收款方式；记录与设置 = 充值记录、提现记录、开户进度、支付密码。

### 5.2 钱包首页（无账户）

- 不画余额 hero、不画充值 / 提现（现状没有钱包时仍画「可用余额 900.00」和充值 / 提现键，截图 `wallet-home-empty`，问题 W-01）。
- 整页空态：`EmptyState`，图标 `wallet` 48 在 tone 圆（`color.bg.selected`）里；标题「开通钱包 / Set up your wallet」20/700；说明「开通后可充值、提现、收付款和查看账单 / Top up, withdraw, pay and see your bills once it's set up」；主键「开户 / Open wallet」（手机整宽 48，PC 宽 200）；有开户申请时下方次要键「开户进度 / Application status」。
- 「开户」是 `create` 动作（operation + form），点开表单（R6，≤ 4 字段 → 面板）。

### 5.3 开户表单

- 标题「开户 / Open wallet」+ 说明一行「选择钱包方案并起一个标识，提交后等待审核」。
- 「钱包方案」选择：选项 ≤ 4 用卡片式单选（每卡：方案名 15/600 + 币种与说明 12）；无选项时按 R6 无选项规则（现状画成假单选框，W-05）。
- 「钱包标识」：帮助文字「英文、数字或 _ : - .，最多 128 个字符」放输入框下方，不当占位（占位写示例「personal-wallet」）。
- 提交「开户」→ 结果页（R7：「开户申请已提交 / Application submitted」info + 「审核通过后即可使用」）→ 完成 → 回首页并刷新（R4）。

### 5.4 单个钱包 `flare.wallet.page.wallet`

- 总览原型：总览卡（钱包名、可用余额 32、次级指标「冻结中 ¥0.00 · 账面余额 ¥1,000.00 · 可提现 ¥1,000.00」13 secondary 用 `·` 分隔，手机折两行）；快捷动作：充值、提现（主），转账、收款码（命令）；列表分组：常用 = 兑换、冻结、账单、资金限制；记录与设置 = 充值与提现记录、充值记录、提现记录、收款方式、支付密码、设为默认；危险行「关闭钱包」（确认文案「关闭后余额需先转出，且不能再收款。确定关闭？」）。
- 「收款钱包编号」（qr 分组，默认折叠）保留折叠，展开为 `QRCard` 风格（码 220 + 编号可复制）。
- 现状 16 个动作全在一张列表里，转账 / 兑换与「账单」平级（问题 W-02）。

### 5.5 资金动作表单页：转账、兑换、冻结、充值、提现、收款码设置

- 都是任务原型（R2.2）+ 页内表单（R6 第二行）。
- 表单前一块「从哪个钱包 / From」：钱包选择卡（钱包名 + 可用余额），只有一个钱包时只读显示。
- 金额字段：`money` 输入，右侧显示币种；下方 caption「可用 ¥1,000.00」+ 行内文字键「全部 / Max」（只在提现、转账）。
- 费用与到账（核心回填后）：表单下方 `DescriptionList`：手续费、预计到账；金额变化后 300 ms 防抖更新。
- 主键文案用动作 label（「转账」「兑换」「提现」）；进行中锁定。提交后进入核对页或付款确认（引擎决定）。
- 充值 / 提现「无可用渠道」「钱包已关闭」：整页 `EmptyState`（图标 `info` / `lock`）+ 清单说明，主键不画（现状向量 `no_channel` / `closed` 有说明块，按此版式）。
- 上传凭证（充值线下转账）：`FileUpload`，缩略图 + 进度，提交键按 R6「上传中」规则。

### 5.6 核对与确认：`intent`、`confirm`、`checkout`、`withdrawal_authorization`

- 任务原型。核对卡：标题「资金明细」15/600；`DescriptionList` 两栏（label 左 13 secondary、value 右对齐 14 primary）；金额行（扣款、手续费、到账）带币种符号；「到账」行加粗；有效期三行合并为一行「有效期至 2033-05-18 11:33（剩余 2438 天）」，剩余 < 10 分钟变 `color.warning`（现状三条有效期重复，且 label/value 各占半宽中间大段空白，问题 W-08、G-05）。
- 沙箱提示：`StatusBanner` warning 放卡片上方（现状在卡内，与正文同权重）。
- 动作：「确认并支付」主（R2.2 吸底 / 行首），「取消确认」次要（安静），「查看待确认操作」进更多操作列表（W-12、G-08）。

### 5.7 结果页：`result`、`pay_result`、开户结果

- 全部改用 R7 `result` 块。钱包清单为 `flare.wallet.page.result` 增加 `result` 块：`/state` 取值表补全为向量与服务端实际取值（至少 `prepared`、`completed`、`pending`、`rejected`、`unknown`；`prepared` →「待确认 / Awaiting confirmation」info），标题按动作区分（「转账成功」「兑换成功」「冻结成功」……由清单 `values` 给）。
- 部分支付 / 解冻退回（冻结单的两个后续动作）放在结果页的次要动作位。

### 5.8 记录：交易记录、充值记录、提现记录、充值与提现记录、开户进度

- 记录原型（R2.3）+ `FilterTabs`（全部 / 收入 / 支出 / 内部 —— 现状保留）。
- 按天分组：组标题「今天 / 昨天 / 9月12日」12/600 secondary，sticky。
- 行（高 64）：左 36 圆图标（收入 `arrow-down` success 底，支出 `send` neutral 底，充值 `add`，提现 `download`，内部 `refresh`）· 标题 15（对方或用途）+ 副标题 12（时间 · 钱包名）· 右 金额 16/600（R10 收支色）+ 状态 `Tag`（非「已完成」才显示）。
- 开户进度：行 = 钱包标识 15 + 方案 12 · 右 状态 `Tag`（需清单补 `/status` values：待审核 info / 已通过 success / 未通过 danger）+ 原因（未通过时第二行 caption danger）。
- 空态：图标 `clock`，「暂无记录」；有筛选时「这个筛选下没有记录」+「清除筛选」键。
- 加载更多：列表底部整宽「加载更多」次要键（现状），加载中转圈；到底「没有更多了 / That's everything」caption。

### 5.9 交易详情、记录详情：`history_detail`、`cashflow_detail`

- 结果版式的只读变体：顶部状态图标 + 状态标签 + 金额 32；下方 `DescriptionList` 明细；底部「复制单号」安静键（`copy`）。
- 待处理 / 失败时顶部 `StatusBanner`（info / danger）说明下一步。

### 5.10 支付密码、收款方式、待确认操作、资金限制、私有材料

- 支付密码（设置 / 修改）：任务原型；密码输入用 6 格 PIN 组件（`password` 输入、`maxLength: 6` 且全数字时渲染为 6 格，四端 kit 新增 `pin` 外观），自动聚焦，满 6 位自动进入下一步，错误时清空并抖动（reduced-motion 时不抖）。
- 收款方式：记录原型；每种方式一行（图标位 + 名称 + 账号尾号 + 状态 Tag）；「添加收款方式」主键在页头右侧（手机文字键）/ 页底；「设为默认」「删除」进行尾 `more` 菜单，删除是菜单里的危险项 + 确认（现状「删除」是红色实心小胶囊、「设为默认」是文字，问题 W-09）。
- 待确认操作（recovery、cashflow_recovery）：任务原型；顶部 `StatusBanner` warning 说明「这笔操作结果还不确定，请先处理，避免重复付款」；原单信息 `DescriptionList`；主键「处理原操作 / Resolve」。
- 资金限制（lots）：记录原型；行 = 限制类型 + 金额 + 到期时间。
- 私有材料（无数据时为 `EmptyState`「暂无资料」）。

### 5.11 收款码与扫码付款：`collect`、`collect_setup`、`pay_peer`、`pay_confirm`

- 收款码：`QRCard`（码 `component.qrCodeSize` 220，卡宽 `component.qrCardWidth` 320）+ 金额（已设置时 32）+「设置金额 / Set amount」安静键 +「保存图片 / Save image」次要键（`download`）。
- 向对方付款：任务原型；对方头像 56 + 名字；金额输入 44 居中（R10）；备注；主键「付款 / Pay」→ 付款确认面板（4.3）。
- 结果：R7。

---

## 6. 实名认证

清单 `flare.realname`：`mine`（状态）、`apply`（填写资料）、`documents`（核对并提交）、`history`、`application`。

### 6.1 实名状态页 `mine`（总览原型）

```
┌ 实名认证 ────────────────────────────┐
│ ┌ 状态卡 ─────────────────────────┐ │
│ │ (图标 48 tone 圆)  未实名认证      │ │  ← 20/700
│ │ 完成认证后可使用钱包与红包         │ │  ← 14 secondary
│ │ ○ 填写资料 — ○ 核对资料 — ○ 审核 — ○ 结果 │  ← steps，横排
│ │ [            开始认证            ] │ │
│ └─────────────────────────────────┘ │
│ 认证信息（已认证 / 审核中时）          │
│ 姓名 林*  证件 居民身份证  号码 3301**********1234 │
│ 有效期至 2031-09-14                   │
│ 我的证件（缩略图 3 张，点开查看）       │
│ ┌ 列表卡 ┐ 申请历史 ›                  │
└─────────────────────────────────────┘
```

| `/state` | 图标 / tone | 标题 zh / en | 说明 | 主动作 |
|---|---|---|---|---|
| notSubmitted | `admin` / neutral | 未实名认证 / Not verified | 完成认证后可使用钱包与红包 | 开始认证 |
| draft | `edit` / info | 认证未完成 / In progress | 继续补充材料并提交 | 继续认证 |
| pendingReview | `clock` / info | 审核中 / Under review | 资料已提交，审核结果会在这里更新 | —（提交时间 caption） |
| approved | `success` / success | 已实名认证 / Verified | 有效期至 2031-09-14 | — |
| rejected | `error` / danger | 认证未通过 / Not approved | 原因：证件无法辨认（`reasonCode` 标签） | 重新认证 |
| expired / revoked | `warning` / warning | 认证已失效 / Expired | 需要重新认证 | 重新认证 |

- 状态卡替代现在的 banner + note + fields 三层叠放（同义信息说三遍）。清单的 banner / note 保留给不支持状态卡的老版本；kit 识别 `steps` + `fields(/state)` 的组合时画状态卡（R12 同类的结构推导，写进向量 `rules.statusCard`）。也可以由清单显式声明 `presentation.renderer: "status.card"`——推荐后者，结构推导作为兜底。
- 步骤条：4 步横排（手机每步宽 = (屏宽 − 32) / 4，标签 12 两行内），当前步 `color.primary` 实心圆 16 + 13/600 标签，已完成 `check` 圆，未到 `color.border.primary` 空心圆；步间连线 2。读屏「第 2 步，共 4 步：核对资料，当前步骤」。
- 证件缩略图：`protected-media` 块画成 3 张 16:10 缩略图（高 72，`radius.md`），默认模糊 + `eye` 图标，点开经宿主读取后全屏查看；读屏「证件正面，点按查看」。不画「材料」输入框（R6.1，N-05）。
- 「处理原操作」（journal 未确认）：状态卡上方 `StatusBanner` warning +「处理 / Resolve」键。

### 6.2 填写资料 `apply`（任务原型，整页表单）

- 说明块改为页头下 caption「请填写与证件一致的信息 / Enter your details exactly as on your ID」。
- 字段：姓名（text）；证件类型（3 个选项 → 卡片式单选，手机竖排 3 卡、PC 横排）；证件号码（text，按类型给 `inputmode` 与格式提示：身份证 18 位、护照字母数字）；国家或地区（`select`，默认「中国大陆」，清单改，N-03）。
- 计数器按 R6 规则隐藏（现状「0/100」「0/64」「2/2」常显）。
- 主键「下一步 / Next」吸底（手机）/ 表单末尾（PC，表单列 560）。
- 必填校验文案「请填写姓名 / Enter your name」「请填写证件号码 / Enter your ID number」，而不是通用的「必填」（现状只写「必填」，问题 N-04）。

### 6.3 核对并提交 `documents`（任务原型）

```
┌ 核对并提交 ──────────────────────────┐
│ 步骤条（第 2 步）                      │
│ 认证信息卡：姓名 林* · 居民身份证 · 3301…1234   [修改] │
│ 证件照片                               │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│ │  (camera) │ │  (camera) │ │  (camera) │ │  ← 拍摄位，16:10，手机 2 列 + 1，PC 3 列
│ │ 证件正面  │ │ 证件反面  │ │ 本人手持  │ │
│ └──────────┘ └──────────┘ └──────────┘ │
│ 照片仅用于本次实名认证                   │
│ [            提交审核            ]       │
└───────────────────────────────────────┘
```

- **拍摄位**（新增 kit 组件 `FlareDocumentSlot`，四端）：宽按网格（手机 2 列、PC 3 列，间距 `spacing.md`），高 = 宽 × 10/16、不低于 `component.documentSlotHeight` 112；底 `color.bg.secondary`，1.5 虚线描边 `color.border.primary`，`radius.card`；中间证件示意线框（正面：头像框在右；反面：国徽在左；手持：人形 + 卡片）+ `camera` 24 + 标签 14/600 + 「点击拍摄 / Tap to take a photo」12。
  - 已拍：照片铺满（cover）+ 右上 `success` 徽标 20 + 底部渐变条上「重拍 / Retake」（`refresh` 16）；读屏「证件正面，已拍摄，点按重拍」。
  - 上传中：照片 + 中央进度环 32 + 百分比；失败：红描边 + `error` + 「上传失败，点按重试」。
- 拍摄位就是 `captureFront/Back/Holding` 的 native 动作入口（document 输入的 `into` 绑定），**不再画成一排「证件正面 / 证件反面 / 本人手持证件」按钮**（问题 N-05，截图 `realname-documents`、`realname-capture-front`）。
- 主键「提交审核」：所需拍摄位全部完成前禁用，键下 caption「还差 1 张照片 / 1 more photo needed」。
- 提交 → 结果（R7：「已提交审核 / Submitted for review」info，「通常 1 个工作日内完成」）→ 完成 → 状态页刷新为「审核中」。

### 6.4 拍证件 `FlareDocumentCapture`

- 手机：全屏，`color.media.stage` 底。PC：对话框宽 `component.capturePreviewWidth` 560，摄像头画面 16:10。
- 取景框：ID-1 比例 85.6:54（`component.documentFrameRatio`），宽 = 屏宽 − 2×`spacing.2xl`；框外压暗 `color.media.stageShade`；四角 3 宽 24 长的白色角标；框下方提示 15 onStage：正面「将证件人像面放入框内」、反面「将证件国徽面放入框内」、手持「手持证件，人脸与证件都要清晰」；第二行 13「避免反光和遮挡 / Avoid glare and cover nothing」。
- 底部：左「相册 / Album」（PC「选择文件 / Choose file」，图标 `image`）、中快门 `component.captureShutterSize` 72（白圆 + 4 宽外环，读屏「拍摄 / Take photo」）、右「取消 / Cancel」。
- 手持证件用竖版引导：人脸椭圆（宽 50%）在上、证件框（ID-1 比例，宽 60%）在下偏右（现状是一个竖长矩形，问题 N-09）。
- 相机不可用：取景框内 `camera-off` 32 +「无法使用相机，可从相册选择 / Camera unavailable — choose from album」，快门隐藏（现状保留）。
- 处理中：取景框上转圈 +「正在处理 / Processing」。
- 预览：照片在框内；底部两键等分「重拍 / Retake」（次要）「使用照片 / Use photo」（主）。
- 错误：过大「照片超过 5 MB，请换一张 / Photo is over 5 MB」，格式「只支持 JPG 和 PNG」，失败「没有处理成功，请重拍」；在预览区上方 `StatusBanner` danger，回到取景。
- 键盘（PC）：Space 拍摄，Esc 取消，Enter 使用照片。

### 6.5 能力授权 `FlareCapabilityConsent`

- 第一次拍证件、第一次付款确认、第一次定位前出现。`BottomSheet`（PC 对话框 400）。
- 内容：图标 48 在 tone 圆里（camera / wallet / location / mic / video，缺省 info，现状保留）；标题「「实名认证」想使用相机 / 实名认证 wants to use the camera」17/600；用途一行 14 secondary（清单 purpose）；三键竖排整宽：「始终允许 / Always allow」（主）、「仅本次 / Only this time」（次要）、「不允许 / Don't allow」（安静）。不支持「始终」的能力只出后两键（现状规则）。
- 「我 → 插件权限」列表：每个插件一组，行 = 能力名 + 「始终允许」+ 行尾「收回 / Revoke」危险文字键（确认）；空态图标 `lock`、「还没有始终允许的插件权限」+ 说明「插件第一次使用相机、位置等能力时会先问你 / Plugins ask before using the camera, location and more」。

### 6.6 申请历史 / 申请详情

- 历史：记录原型；行 = 证件类型 15 + 提交时间 12 · 右 状态 `Tag`（已认证 success / 审核中 info / 未通过 danger / 已撤销 neutral / 填写中 neutral）。空态：图标 `admin`，「还没有认证申请 / No applications yet」+ 主键「开始认证」（现状纯文字，问题 N-08）。
- 详情：6.1 状态卡的只读变体（无主动作）+ 时间线（申请、提交、审核三条，`timeline` 块）+ 证件缩略图。

---

## 7. 交互与动效（四类共用）

| 交互 | 时长 / 曲线 | reduced-motion |
|---|---|---|
| 页面压栈 | 平台原生（iOS push、Android 共享轴、Web 200 ms `transitions.normal` 右入） | 淡入 |
| 面板出现 | `transitions.slow` 260 ms 自下而上；遮罩淡入 | 淡入 |
| 按钮按下 | 缩放 0.98 + 底色加深，`transitions.fast` | 只变色 |
| 结果图标 | 出现时缩放 0.6→1，`transitions.spring` | 无 |
| 开红包 | 開键翻转 0.8 s 循环 | 转圈 |
| 来电光环 | 1.6 s 呼吸 | 静止 |
| 刷新细条 | 不定进度 1.2 s 循环 | 静止的半条 |

触感：拆红包成功 `success`；付款成功 `success`；挂断 `light`；按 `spec/haptic-vectors.json` 已有类别。

---

## 8. 文案总表（新增或修改，进四端 i18n）

| key | zh-CN | en-US |
|---|---|---|
| pluginView.unknownStatus | 未知状态 | Unknown status |
| pluginView.offline | 网络不可用，显示的是上次读取的内容 | You're offline. Showing what was loaded last. |
| pluginView.availableOnline | 联网后可用 | Available when you're online |
| pluginView.loadFailedTitle | 没有读到内容 | Couldn't load this page |
| pluginView.noOptions | 暂无可选项 | No options available |
| pluginView.uploading | 正在上传 {done}/{total} | Uploading {done}/{total} |
| pluginView.groupCommon | 常用 | Common |
| pluginView.groupRecords | 记录与设置 | Records & settings |
| pluginView.moreActions | 更多操作 | More actions |
| pluginView.done | 完成 | Done |
| pluginView.endOfList | 没有更多了 | That's everything |
| amount.hidden | 余额已隐藏 | Balance hidden |
| call.ended | 通话已结束 · {duration} | Call ended · {duration} |
| call.ringingPeer | 对方响铃中… | Ringing… |
| call.reconnectingUnstable | 网络不稳定，正在重连… | Reconnecting… |
| call.answerAudio | 语音接听 | Answer with audio |
| call.encrypted | 端到端加密 | End-to-end encrypted |
| call.redial | 重拨 | Call again |
| call.maxParticipants | 最多 {count} 人同时通话 | Up to {count} people per call |
| redPacket.putMoneyIn | 塞钱进红包 | Put money in |
| redPacket.refundNotice | 未领取的红包将于 24 小时后退回 | Unclaimed money returns after 24 hours |
| redPacket.chooseRecipient | 请选择发给谁 | Choose who gets it |
| payment.insufficient | 余额不足，还差 {amount} | Not enough balance — {amount} short |
| payment.topUp | 去充值 | Top up |
| payment.startAgain | 重新发起 | Start again |
| wallet.setupTitle | 开通钱包 | Set up your wallet |
| wallet.setupBody | 开通后可充值、提现、收付款和查看账单 | Top up, withdraw, pay and see your bills once it's set up |
| realname.photosNeeded | 还差 {count} 张照片 | {count} more photo(s) needed |
| documentCapture.hintFront | 将证件人像面放入框内 | Fit the photo side of your ID in the frame |
| documentCapture.hintBack | 将证件国徽面放入框内 | Fit the back of your ID in the frame |
| documentCapture.hintHolding | 手持证件，人脸与证件都要清晰 | Hold your ID next to your face, both in focus |
| documentCapture.hintGlare | 避免反光和遮挡 | Avoid glare and cover nothing |

插件自己的文案（钱包、实名、红包页里的标签与说明）在清单 `translations` 里维护，不进 kit。

---

## 9. 新增 token（`tokens/tokens.json`，四端同次生成）

```jsonc
"colors": {
  "call": {
    "stage": "#17151D", "stageTint": "#2B2340",
    "onStage": "#FFFFFF", "onStageSecondary": "rgba(255, 255, 255, 0.72)",
    "control": "rgba(255, 255, 255, 0.14)", "controlHover": "rgba(255, 255, 255, 0.22)",
    "controlActive": "#FFFFFF", "onControlActive": "#17131C",
    "hangup": "#DC2626", "hangupPressed": "#B91C1C",
    "accept": "#16A34A", "acceptPressed": "#15803D",
    "speaking": "#34D17F", "tile": "rgba(255, 255, 255, 0.06)",
    "chip": "rgba(0, 0, 0, 0.42)", "popover": "#22232B"
  }
},
// dark.colors.call 与浅色相同（舞台不随主题）
"sizes": { "component": {
  "callControlSize": "56px", "callHangupSize": "64px", "callAvatarSize": "96px", "callAvatarSizeWindow": "80px",
  "callTileAvatar": "56px", "callDockHeight": "56px",
  "callWindowAudioWidth": "400px", "callWindowAudioHeight": "560px",
  "callWindowVideoWidth": "720px", "callWindowVideoHeight": "540px", "callIncomingBannerWidth": "360px",
  "amountHeroFontSize": "32px", "resultIconSize": "56px",
  "documentFrameRatio": "1.586", "captureShutterSize": "72px", "capturePreviewWidth": "560px",
  "documentSlotHeight": "112px", "formColumnWidth": "560px", "actionMinWidth": "120px"
} }
```

对比度：`onStage` 对 `stage` 17.4:1；`onStageSecondary` 对 `stage` 约 11:1；`hangup` 上白色图标 4.8:1；`accept` 上白色图标 3.3:1（非文字图形 ≥ 3:1）。

---

## 10. 各端改动清单

优先级：P0 = 本轮必须（修掉 iOS 现场看到的问题与跨端不一致）；P1 = 本轮完成体验；P2 = 下一轮。

### 10.1 spec（`spec/components.json` 与向量）—— 先做，四端照它测

- P0 `PluginPage.rules.actionLayout`：R2 的角色判定与三种原型；向量 `spec/plugin-view-vectors.json#rules.actionRoles`（输入：动作列表 + 块类型；输出：每个动作的角色与位置）。
- P0 `PluginPage.rules.refresh`：R4；事件 `refresh` 带 `reason`（`pull | key | timer | action | return`）；`spec/plugin-refresh-vectors.json` 加 `afterAction`、`afterReturn`。
- P0 `PluginView.rules.statusValues`：R3 未知取值兜底；`values` 对象形态（label + tone）。
- P0 `PluginView.rules.blockBoundInputs`：R6.1。
- P0 `PluginView.rules.cardHeader`：R5（标题 flex、详情键位置）。
- P0 `PluginPage.rules.accountDerivation`：R12；`appearance` 缺省改为结构推导。
- P1 新块 `result`（R7）进 `spec/plugin-ui-vocabulary.json`（`blocks` 加 `result`），`PluginView` 加状态与向量；动作新增可选字段 `group`（R2.1）与 `icon`（10.7）；`fields` / `columns` 的 `values` 允许 `{label, tone}`（R3）。
- P1 `PluginPage` 新属性 `offline: boolean`（R8）。
- P1 新组件条目：`FlareDocumentSlot`、`FlareRedPacketReview`、`FlareResultView`（`result` 块与独立使用共用）；`FlareCallSurface`（现缺）、`RedPacketArch`（现缺）。
- P1 补漂移：`CallView` 加 `muted`、`cameraOn`、`speakerOn`、`speakerPicker`、`controlsDisabled`、`encrypted`、`ended` 状态；`CallDock` 加 `state`、`statusDetail` 与状态；`CallControls` 加 `disabled`、`speakerPicker`、`showAddMember`；`RedPacketOpenSheet.reviewOnError`；`RedPacketComposer.errorField`/`focusField`；`RedPacketDetail.nowMs`；`IncomingCall.presentation`（`fullscreen | banner`）；`PaymentConfirmation` 加 `insufficient` 状态。
- P1 `docs/ICON-LIBRARY.md` 同步到代码的 111 个名字（`wallet`、`scan`、`flashlight` 已在四端代码里，文档仍写 108）。本文没有新增图标名。

### 10.2 tokens

- P0 第 9 节 `colors.call.*` 与 `sizes.component.*`，`node build.mjs` 生成四端。

### 10.3 Vue（`packages/vue-im-ui`）

- P0 `FlarePluginPage.vue`：用 spec 的 `actionRoles` 替换 `actionLayout` 计算（:199-203）；按原型渲染快捷动作行 / 吸底动作条 / 列表分组 / 危险行；列表行不再继承 primary 的品牌色（`FlarePluginView.vue:1381` 的 `appearance` 分支）。
- P0 R4：动作结算成功后 `emit('refresh', 'action')`。
- P0 R3：状态值 `Tag` 与未知兜底；`fields` 带 tone 时用 `Tag`。
- P0 R6.1：`inlineFormActionId` 计算排除块绑定输入（`FlarePluginPage.vue:187-198`）。
- P0 R6：无选项 `select` 画禁用 `FlareSelect`（现画单选）；计数器显示规则（`PluginFormInput.vue`）。
- P1 R7 `result` 块 / `FlareResultView`；R8 离线横幅与 300 ms 骨架；R1 刷新键只在数据页；分组标题样式。
- P1 R12：`appearance` 缺省推导（把 `flareAccountDocument` 的触发条件从 `appearance === "account"` 改成缺省也推导）。
- P1 通话：`FlareCallView.vue` 语音模式改深色舞台（删 `.flare-call-view--audio` 的浅色变量 :255-264）；`FlareIncomingCall.vue` 去紫色渐变改舞台色并加 `presentation: banner`；`FlareCallControls.vue` 去 `#ff5a5f` 渐变与 popover 写死颜色（:68、:155）；`FlareCallDevicePicker.vue` `✓` 改 `FlareIcon check`；「End-to-end encrypted」进 i18n；`ended` 状态；`FlareCallSurface.vue` 窗口尺寸改用新 token。
- P1 红包：`FlareRedPacketComposer.vue` 弧移出卡片、主键文案、金额范围提示只在出错时显示、退回提示；新增 `FlareRedPacketReview.vue`；`FlarePaymentConfirmation.vue` 加 `insufficient`、订单号折叠。
- P1 `FlareDocumentSlot.vue`（新）；`FlareDocumentCapture.vue` 取景框比例与角标、提示文案。
- P2 `FlareScreenShare.vue` 图标改 `screen-share`；PIN 6 格外观。

### 10.4 Flutter（`packages/flutter-im-ui`）

- P0 `flare_plugin_page.dart`：实现 `actionRoles` 版式（现在从不传 `actionLayout`，默认 inline 文字键，`flare_plugin_view.dart:74`）；R4 `onRefresh(reason)`；R3、R6.1、R6 无选项与计数器。
- P0 R12 账户外观推导（Flutter 现无此规则）。
- P1 R7 `FlareResultView`、R8 离线与骨架（现用平台转圈，改 kit `FlareSkeleton`）、空文档态。
- P1 通话：`flare_call_view.dart` 语音改舞台色；`flare_call_controls.dart` 加 `disabled`、去 `0xFFEF4444`（:179）；`flare_group_call_view.dart` 加 `statusDetail`、`onRecover`、`controlsDisabled`、`encrypted`、`onSelectParticipant`；`flare_call_dock.dart` 加 `state`/`statusDetail`，`Icons.videocam`/`Icons.call`（:117-118）改 `FlareIcon`；`flare_call_device_picker.dart` 颜色走 token；`flare_screen_share.dart` 文案进 `FlareStrings`、去 `Icons.block`（:379）；来电 banner 形态（桌面）。
- P1 红包：`flare_red_packet_composer.dart` 加 `errorField`/`focusField`；`flare_red_packet_open_sheet.dart` 加 `reviewOnError`；`red_packet_arch.dart` 加 `compact`；`FlareRedPacketReview`（新）；`flare_payment_confirmation.dart` 订单号折叠改 kit 样式（去 `ExpansionTile`，:222）、`insufficient`。
- P1 `FlareDocumentSlot`（新）、`flare_document_capture.dart` 取景框。
- P2 PIN 外观。

### 10.5 SwiftUI（`packages/ios-im-ui`）

- P0 `FlarePluginPage.swift:311-315`：按 `actionRoles` 选择版式（现不传 `actionLayout`，`PluginView.swift:146` 默认 inline → `:524-533` 文字外观，即「一排文字链接」）。
- P0 `PluginView.swift:415-436` 卡片头：标题 `.frame(maxWidth: .infinity, alignment: .leading)`，删掉多余 `Spacer`（「查看详情」居中缺陷）。
- P0 R4 `onRefresh(reason:)`；R3（`PluginViewModel.swift:248-249` 未知值改兜底标签）；R6.1；R6 无选项与计数器（`PluginFormView.swift`）。
- P0 R12 账户外观推导。
- P1 R7 / R8（含空文档态）。
- P1 通话：`CallViews.swift` 语音舞台色改 token（:172 写死 sRGB）、说话色（:181）、来电红绿（:273/:275）、加 `controlsDisabled`、`encrypted`、`ended`；`CallControlsView` 加 `disabled`；`devices` 插槽（放系统路由键）；`GroupCallView.swift` 补 `statusDetail`、recover、`selectParticipant`、舞台色（:99-103）；`CallDockView.swift:49` 改 `IconView`，加 `state`/`statusDetail`；新增 `CallSurfaceView`（与 Vue/Flutter 的 `FlareCallSurface` 对应：iPad 浮窗、iPhone 全屏）。
- P1 红包：`RedPacketComposerView.swift` 去 `RedPacketActionButton`（`RedPacketCardView.swift:265`）改 `ButtonView`、加红包弧（新增 `RedPacketArchView`）、`errorField`；`RedPacketOpenSheet.swift` 加 `reviewOnError`；`RedPacketDetailView.swift` 改中性页头 + 弧（删 :122-150 红色标题栏与扇形）、补「已存入」行；新增红包淡化色（Flutter `red_packet_tint` 对应）。
- P1 `FlarePaymentConfirmation.swift` 订单号折叠、`insufficient`；`FlareDocumentSlot`（新）；`FlareDocumentCapture.swift` 取景框。

### 10.6 Compose（`packages/android-im-ui`）

- P0 `PluginPage.kt:354-370` 按 `actionRoles` 选择版式（默认 inline，`PluginView.kt:141`、:523 文字外观）。
- P0 R4 `onRefresh(reason)`；R3、R6.1、R6 无选项与计数器（`PluginForm.kt`）；R12 账户外观推导。
- P1 R7 / R8（含空文档态）。
- P1 通话：`CallView.kt` 语音舞台色（:118 `0xFF111318`）、自绘头像改 kit `Avatar`（:133-146）、加 `controlsDisabled`、`encrypted`、`ended`；`CallControls.kt` 去 `0xFFEF4444`（:112）、加 `disabled`、`devices` 插槽；`IncomingCall.kt` 红绿改 token（:71-73）、头像改 kit（:48）；`GroupCallView.kt` 补缺项与舞台色（:96）；`CallDock.kt` 加 `state`/`statusDetail`；新增 `CallSurface`。
- P1 红包：`RedPacketComposer.kt` 加弧（新增 `RedPacketArch`）与 `errorField`；`RedPacketOpenSheet.kt` 加 `reviewOnError`；`RedPacketDetail.kt` 改中性页头 + 弧（删 :232-246 扇形）、补 `nowMs`、「已存入」行。
- P1 `FlarePaymentConfirmation.kt` 订单号折叠、`insufficient`；`FlareDocumentSlot`（新）；`FlareDocumentCapture.kt` 取景框。

### 10.7 插件清单（`flare-plugins-commercial`、`flare-plugin-call`）

- P0 钱包：`flare.wallet.page.openings` `/status` 加 `values`（带 tone）；`flare.wallet.page.result` `/state` 补全取值（含 `prepared`）并改用 `result` 块（P1）；首页「待确认操作」动作加 `hiddenWhen`（无待确认单时隐藏）。
- P0 红包：`flare.redpacket.page.sent` / `received` 的 `/status` 加 `values`；确认页改 `presentation.renderer: "redPacket.review"`（P1）。
- P0 实名：`apply.countryCode` 改 `select`（地区表由宿主提供，或清单内置常用地区）；`mine` 改用 `status.card` 呈现（P1）。
- P1 钱包首页、单个钱包页的去向补 `group`（R2.1）：常用 = 交易记录、收款方式、转账、兑换、冻结、收款码、资金限制、账单；记录与设置 = 充值记录、提现记录、充值与提现记录、开户进度、支付密码、设为默认。
- P1 动作可选 `icon` 语义名（钱包列表行图标：交易记录 `clock`、收款方式 `card`、支付密码 `lock`、充值记录 `add`、提现记录 `download`、收款码 `qr`、转账 `send`、兑换 `refresh`、冻结 `lock`、资金限制 `info`、开户进度 `clock`）——只用现有 111 个名字。

### 10.8 应用（`flare-social-examples/apps/*`）

- P0 iOS `PluginPageScreen.swift`：出栈回到本页时刷新（:526 只清 `next`）；动作成功压栈时记下发起页供「完成」弹回；监听 kit 的 `onRefresh(reason)`。
- P0 iOS `ChatView.swift:660-668`：打开会话时预取「+」面板菜单。
- P0 Web `pluginHost.ts:97`：删掉按 `pluginId` 选 `account` 外观（交给 R12）；`chat/redPacketPage.ts` 删红包状态代翻译（交给清单）。
- P1 各端宿主接 `offline`、`refresh(reason)`；Android、Flutter 应用核对 R4 两条（本轮未逐行核对）。

### 10.9 建议分工

| 线 | 内容 | 依赖 |
|---|---|---|
| A（先行，1 人） | spec 规则与向量（10.1）、token（10.2）、清单（10.7 P0） | 无 |
| B Vue | 10.3，兼做 Web/Tauri 应用 10.8 Web 项，产出参考截图 | A |
| C Flutter | 10.4，兼 Flutter 应用宿主 | A |
| D SwiftUI | 10.5，兼 iOS 应用 10.8 两项 | A |
| E Compose | 10.6，兼 Android 应用宿主 | A |

B–E 并行；每条线先做 P0 渲染规则（钱包、实名页立刻变好），再做通话与红包组件。验收：四端对同一组向量通过；按 `inventory.md` 的页面表在各端截 PC / 手机图，和 Web 参考图逐张对照。

---

## 11. 验收清单（每页过一遍）

- [ ] 没有一个声明动作画成裸文字链接（R2.6 例外除外）。
- [ ] 一屏最多一个实心主按钮组（总览卡里 ≤ 2 个并列）。
- [ ] 没有原始枚举值（`completed`、`prepared`、`pending`……）出现在界面上。
- [ ] 动作成功后页面自动是新数据；从下一页返回后上一页是新数据。
- [ ] 金额带币种符号、等宽，hero 不是紫色。
- [ ] 卡片头「查看详情」贴右。
- [ ] 加载 / 空 / 错 / 离线 / 禁用 / 进行中都有画法。
- [ ] 通话界面四端同一块深色舞台，挂断与接听颜色来自 token。
- [ ] 红包从「+」到发出、从卡片到拆开到详情，都是红包版式，没有紫色通用页。
- [ ] 触控 ≥ 44/48；键盘可达；读屏读出状态与金额；reduced-motion 生效。
- [ ] 手机 320 宽无横向滚动；PC 1280×800 首屏能看到主动作。

---

## 12. 审计后的裁决（2026-11-19）

两轮只读审计（四端 kit 与宿主对照本稿）后定下的结论。和前文冲突时，以本节为准。

1. **「完成」回到哪一页（R4.2）**：弹回到栈里离结果页最近、原型是总览或记录的那一页，并以 `return` 刷新它；下面没有这样的页，就关闭插件页栈。四端宿主按 `spec/plugin-refresh-vectors.json` 的 `doneTarget` 实现并测试。
2. **页头标题**：沿用 kit `Screen` 现有页头（手机 24/700）；R1 里的「20/700」作废。
3. **列表行高**：沿用 `SettingsRow` 的标准行高；R2.1 的「手机 52 / PC 48」作废。去向行右侧画 `chevron-right` 16（溢出进列表的主动作与命令行不画 chevron，见 R2.1 与 actionRoles 向量）；危险行文字 `color.error`、居中，并且必经确认（没写 `confirm` 也要确认）。
4. **hero 文字层级**：沿用四端现状（标签 13、副指标 12）；隐藏余额时读屏读「余额已隐藏」，眼睛键带开关语义。
5. **步骤条**：沿用四端现状（节点 20 带序号、当前步空心环、标签 12）；读屏必须读「第 N 步，共 M 步」。
6. **卡片头**：图标 16；more 键为 IconButton sm（30）；详情键 13，与标题间距 8。
7. **间距**：块与块 16，分组之间 24（R1 原文不变，四端都要改到）。
8. **刷新细条**：周期 1.2 s；减弱动效时为静止的半条。
9. **插件表单字段**：输入框手机 48、PC 40（用 kit Input 的大号）；出错时 `color.error` 描边 + error 图标 16 + caption 文字；必填 `*` 读「必填」；单行表单按 Enter 提交；表单级错误用 danger `StatusBanner`。
10. **按钮反馈**：四端基础按钮与 IconButton 按下缩放 0.98 并换成按下色（primaryActive、errorActive，次要类为 bgHover），有指针时悬停换色，减弱动效时只变色；面板在减弱动效下淡入，不瞬现。
11. **红包卡外观**：以 `spec/components.json` 的 RedPacketCard 为准（整卡 `redPacket.end`、白字说明条、图形 30、busy/disabled 保持未拆面）；§4.4 的渐变 + 28 高说明条 + 36 图形 + busy 转圈作废。
12. **拆红包 error**：保留「開」键作重试（契约现状）；§4.5「重试」键作废，`reviewOnError` 时键为「查看结果」。opening 时 Esc、返回、遮罩、关闭键都不关闭。
13. **来电横幅**：不抢焦点（非模态）；全屏来电把焦点放到接听键。
14. **设备选择**：`speakerPicker` 只在 Vue、Flutter（设备面板）；iOS、Compose 走 `devices` 插槽（系统路由键）。
15. **开关键填白**：「偏离常态」时填白（已静音、摄像头关、扬声器开），§3.0「开启态」措辞按此理解。
16. **群通话上限 12**：1–4 人 2×2；5–6 人 PC 3×2、手机 2×3；7–9 人 3×3；10–12 人 PC 4×3、手机 3×4。「N 人已加入」只算已接通的人。
17. **通话状态文案**：悬浮条用短语（`callDockWaiting` 等待接听、`callReconnectingShort` 正在重连、`callInterrupted` 通话中断）；悬浮条与舞台上的错误文字用 `color.call.errorText`（对 stage 对比度够 4.5:1）。对方静音：状态行后 mic-off 14 + 「对方已静音」文字。挂断键下有「挂断」标签。
18. **悬浮条位置**：PC 右下、距边 `spacing.2xl`；手机顶部右侧，可拖动，吸附左右两边（Flutter 现状）。
19. **付款确认**：标题 15/600 居中；取消为次要键；PIN 在 320 宽不溢出（格子随容器收缩，最小 36）；不足 6 位时确认键禁用（四端一致）；`shortfall` 只在大于 0 时生效。
20. **§4.5 的「手慢了」英文、「已过期」中文**：以 `spec/red-packet-vectors.json` 为准。
21. **汇总卡**：写「今年共收到 / 今年共发出」，不写具体年份（插件数据拿不到查看者的语言和时区）。
22. **焦点环颜色**：`color.focusRing`（35% 透明）在通话舞台和填充键上达不到 3:1，通话圆键、按钮类的焦点环统一用 `color.border.selected`，宽 `component.focusRingWidth` 2、外扩 `component.focusRingOffset` 3；输入框类（Input、Textarea、Select）获焦时为 1px `color.border.selected` 边框（达标的那一层）外加 `color.focusRing` 半透明光晕（装饰），四端同 Vue/Flutter。§3 等处写的「color.focusRing」按此理解。
23. **钱包首页 PC 版式（§5.1，四端同）**：按示意，PC 没有总览分组标题行（页头已写「钱包」，「余额钱包」小标题与卡内名重复）；首行钱包卡两列等宽网格（只有一个钱包、或详情栏放不下两张 `layout.primaryPaneMinWidth` 宽的卡时一列），每卡：`wallet` 图标 + 钱包名、余额（`component.amountHeroFontSize`）、一行「状态 `Tag` · 查看明细 ›」（不画余额标签与「资金类型与币种」）；其下一行快捷键（R2.1 PC 版）+ 行尾眼睛键（只有眼睛键时也在行尾）；再下列表卡。手机不变。账户外观由结构推导时（R12）四端都先转成这套钱包版式（Vue `flareAccountDocument`）。
24. **记录行只认 `icon`**：rows 块声明了 `icon` 才按记录行画（rules.rowsIcon）；没有 `icon` 一律按 rules.pageRows 画，渲染器不按「首列是带符号的金额」自认账本。记录行的收入色调仍按值前的「+」；金额用 money 格式时 `+`（收入）与 `-` 都保留在币种前（formats2）。
