# 组件库精细化打磨设计(2026-09)

面向 flare-im-design「一契约四实现」组件库的一轮打磨,目标不是增加组件数量,而是让现有 135 个组件对任意宿主**通用**、对使用者**简洁**、对市场主流 IM 场景**全面**、对接入者**好用**。本文记录审计结论、决策与分波次工作包;执行进度见各波次末尾的验证段。

## 1. 现状判断

审计覆盖契约一致性、重复与命名、国际化与可访问性、视觉系统、文档与市场对标五个维度,四端门禁在基线 8c0c464 全绿(Vue 395 测试 / 198 SFC,Flutter 312,iOS 154,Android 编译与单测通过)。主要结论:

| 维度 | 核心事实 |
|---|---|
| 契约真实性 | 14 个契约的 Vue 符号写的是文件名而非导出名,宿主照文档 import 会编译失败;Composer 契约 4 个 props 有 3 个不存在,ChatHeader 与 MessageActionSheet 的契约 props 四端 0 命中;validate 只查符号存在,不查 props、不查三端事件、不查反向覆盖。 |
| 事件与回调 | 305 个契约事件里,三端原生回调无契约条目 Flutter 62 / iOS 33 / Compose 38;25 个 Vue emit 未入契约;click/change/submit 三族四端各用平台惯用名;回调统一遗留 4 项仍在(GroupDetail onOpenChat 参数形状、NewFriendRequests onView 缺两端、Flutter ConversationRow onAction、MessageActionSheet 动作 key 三重分歧)。 |
| 文案 | 四端都有根级 strings provider,但组件默认值没有接进去:无法从根部覆盖的中文字面量 Vue 194 / Flutter 363 / iOS 270 / Android 343;契约 193 个文案 props(28%)散在 53 个组件上,9 个臃肿组件文案占比 64%;Vue 并存五种本地化写法。 |
| 可访问性 | Switch/Checkbox 在 iOS/Android 无语义;Button/IconButton/Switch 默认档触控区四端都低于 48(token 已存在未用);iOS 不支持 Dynamic Type;Android 无 reduce-motion;焦点环与减动效全局规则只在示例壳的样式里,库入口拿不到。 |
| 视觉系统 | 暗色缺 15 个语义色,primary 在暗底对比度 2.66:1、linkHover 2.15:1;品牌换色链路断在 focusRing、`--im-*` 第二套变量与暗色 inline 覆盖;shadows/transitions 只发 CSS;Vue 是 ConversationRow/MessageBubble/Avatar 几何的离群端。 |
| 简洁 | PrimaryButton 是 Button 的固定组合;MessageContentView 一实现三导出;4 套弹层机制并存且四端弹层原语均无契约;3 个 emoji 选择器;8 个 `{id,name,avatarUrl}` 近重复模型;四端 0 个 deprecated 标记;Flutter 带 git 依赖不能发布 pub.dev。 |
| 文档与市场 | README 停在 Phase 1 口径(107 组件、spec 规划中);install.md 版本 0.1.0 与 mavenCentral 写法照做必失败;首页 135 与 82 两个数字打架;23 个英文组件页把读者送回中文页;缺 Badge/Tag/Tooltip/Menu/Dialog/Sheet/Progress/Spinner/ListItem 等通用原语契约;消息引用块与已编辑标记只有 Vue 有。 |

## 2. 目标与非目标

目标:

1. 通用:契约与四端实现同名同义,宿主按文档接入即可编译;文案、主题、图标可从根部整体覆盖;视觉组件不持有 SDK 类型与业务规则。
2. 简洁:一件事只有一个组件、一个名字、一个枚举;文案不再逐 prop 平铺;建立退役通道后再删重复。
3. 全面:补齐主流 IM 通用原语与场景缺口中属于 UI 库职责的部分;SDK 没有的能力(线程、收藏、定时发送)继续不建 UI。
4. 好用:文档站按「每端一条接入路径」重排,首页与 README 数字来自契约,组件页统一模板。

非目标:本轮不发布 npm/pub/Maven/SPM 版本;不替换 naive-ui(它是 Vue 端渲染底座,替换属独立项目);不做逐像素截图差异门禁;不做真机矩阵验收。

## 3. 决策

### 3.1 命名约定(成文)

| 端 | 组件符号 | 说明 |
|---|---|---|
| Vue | `Flare<Name>` | 契约 `platforms.vue.symbol` 必须等于 `components/index.ts` 的导出名 |
| Flutter | `Flare<Name>` | 类名 |
| SwiftUI | `<Name>View` | 契约名本身以 View 结尾的不再叠加 |
| Compose | `<Name>` | 可组合函数名 |

后期加入的 15 个背离本端约定的 iOS/Compose 符号(BrandLogo、Screen、SettingsRow、Composer 三件、VoiceHoldButton、EmojiStickerPicker、Emoji/Sticker 消息三件、GroupDetail)统一补本端约定名,旧名保留为 deprecated 别名一个版本。

### 3.2 事件与参数

- 契约事件名统一 camelCase;Vue 模板按 kebab 派生,原生按 `on` + PascalCase 派生。契约里的 17 个 kebab 事件改写。
- click / change / submit 三族保留平台惯用名,不强改:契约新增 `eventAliases` 表(click → Flutter onPressed/onTap、iOS action、Compose onClick;change → onChanged/onChange;submit → onSubmitted/onSubmit),validate 按别名表核实存在性。
- 多参数回调统一为位置参数,顺序等于契约声明顺序;稳定 ID 是第一参数。GroupDetail `openChat` 的 Vue 侧改为 `(userIds, name)`。
- 「是否有插槽/回调」类布尔(hasDetail、hasStart、hasReconnect 等 9 处)从 props 移到契约 `slots` 字段;Vue 侧继续用 props 探测但不再出现在契约 props。
- 表单控件的 `v-model` 用契约 `model: { prop, event }` 元字段描述,不再把 `v-model` 当 prop 名。
- 动作项统一字段 `id`,附件动作 key 用无前缀词(image/camera/file/location/card/vote/task/schedule),写进契约 `composerActions` 枚举,四端从同一表取。

### 3.3 术语表

契约新增 `lexicon`:presence(Vue 补 `presence` prop,`status/showStatus` 降级为 deprecated)、conversationType(契约名;原生 `conversationKind` 记为别名,下个主版本统一)、conversationKey(Composer 契约改用此名)、avatarUrl(iOS `avatarURL` 记别名)、无障碍名称映射(ariaLabel / semanticLabel / accessibilityLabel / contentDescription)、`shape: circle|square`(原生 `square: Bool` 记别名)。validate 对术语表做同义词门禁。

### 3.4 语气与状态枚举

`FlareTone = info | success | warning | danger | neutral`,prop 名统一 `tone`;`variant` 只描述形态(Button、Skeleton)。Toast 的 `variant` 保留并映射到 tone(error → danger),ConversationDetails 的 `connectionTone` 改为 `tone` 并使用 FlareTone,不再透传 naive-ui 枚举。

### 3.5 文案机制

每端一个 strings provider 是组件默认文案的唯一来源;props 只做覆盖。范式取自 iOS DangerConfirmView:`confirmText: String? = nil` + `confirmText ?? strings.confirmAction`。

- Vue:`withDefaults` 不再写中文;默认值 `computed(() => props.x ?? t('key'))`。TimePicker/CalendarBody 的手写三元与 MessageEmojiPickerPanel/SearchBar/VoiceHoldButton 的硬编码英文一并改走 `t()`。
- Flutter:删除 flare_composer 的私有 `_label(zh, en)`;`Flare*Labels` 类默认值从 `FlareStrings.of(context)` 取。
- Android:PermissionPrompt 的 28 条 when 分支迁进 FlareStrings.kt(Flutter 已有目标形状);Composer.kt 的读屏名改真实文案。
- 契约:每条文案 prop 补 `default: "$strings.<key>"`。
- 门禁:四端组件目录除 strings 文件外禁止中文字面量,阈值从当前值按波次下降到 0。
- `FlareLocale` 改为开放字符串,允许宿主注册任意 locale。

### 3.6 视觉系统

- 暗色补齐 15 个语义色;亮色 success/warning/error 拆为填充色与 `*Text` 文本色,全部达到 WCAG AA。`tokens/build.mjs --check` 增加对比度断言与暗色完备性断言。
- 新增 token:spacing.2xs、radius.bubble/bubbleTail、iconSize、layout.controlHeight/controlPadX、layout.bubbleMaxWidth、opacity、zIndex、breakpoints。
- shadows/transitions 生成 Dart/Swift/Kotlin;composer 组阴影并入 shadows 并删除;Kotlin fontSize 生成 TextUnit。
- 换色链路:deriveFlareTheme 补 focusRing/bgHover/aurora/pinned/important 与暗色方案;applyFlareTheme 写进 `[data-flare-theme]` 作用域;im-theme.ts 全部改为引用 `--flare-color-*`;vue-ui 的 `applyFlareTheme(isDark, variant)` 更名 `applyFlareColorScheme`(旧名 deprecated);Flutter 加 `FlareColors.copyWith` + `FlareTheme` InheritedWidget;iOS 加 `\.flareColors` EnvironmentKey。
- Vue 离群几何对齐三原生:ConversationRow 字号/行高、MessageBubble 圆角/尾角/内边距、Avatar 默认 44 与在线点比例。
- 新门禁 check-hardcoded-visuals:字面值精确等于 token 值即报错,豁免 0/1、Previews、demo、示例壳。

### 3.7 可访问性

- Switch/Checkbox 四端补语义,label 必填,照 IconButton 契约。
- Button/IconButton/Switch 的固定高改为最小高 = touchTarget,视觉尺寸不变。
- focus-visible 与 prefers-reduced-motion 全局规则迁入库入口样式;Android 加 LocalReduceMotion;iOS StatusBanner 的 reduceMotion 模式推广。
- iOS 字号全部 `relativeTo: .body`;Android fontSize token 改 TextUnit。
- Vue 所有弹层统一走 FlareBottomSheet 原语(唯一有焦点陷阱的实现)。

### 3.8 简洁

- 建立 deprecated 通道(Vue JSDoc、Dart `@Deprecated`、Kotlin `@Deprecated`、Swift `@available(deprecated)`),所有合并先标记再删。
- 合并:PrimaryButton → Button(加 loadingLabel);MessageContentView 三导出 → 一;app 层 MessageBatchToolbar 删(事件并进 kit 版);iOS ContactDetailView 删;StickerPicker 降为 EmojiStickerPanel preset;StartConversation Sheet/Dialog 合并为自适应一个;MemberPanel/DeviceSessions 降为 SceneList preset 并导出 SceneList;SearchPanel 改为组合 SearchBar/FilterTabs/SearchDateRangeFilter。
- 模型:`FlareIdentity { id, name, avatarUrl? }`,9 个近重复模型继承;Avatar 接受 `id/name`。
- 依赖:删 @vicons/ionicons5;vue-router 改 optional peer;ConversationDetails 去 `@flare-im/sdk` 类型依赖;Flutter extended_text_field 改 pub 版本 ^17;录音回放用音频播放器替换 video_player;录音留在 kit 内是四端一致决定,写进契约。

### 3.9 全面(市场缺口,只做 UI 库职责)

| 优先级 | 项 | 做法 |
|---|---|---|
| P0 | Sheet / Dialog 契约 | 以 Vue FlareBottomSheet、iOS FormSheetView、Flutter FlareDialog、Compose FormDialog 为基础统一为 `Sheet`(移动面板)与 `Dialog`(桌面居中)两条契约;补缺端 |
| P0 | Badge | 未读数/红点/状态点原语,Flutter 已有 FlareUnreadBadge 可提升 |
| P0 | Menu(桌面右键/长按菜单) | Vue MessageMenu 提升为契约;三端 ContextMenu 包装 |
| P0 | 消息引用块、已编辑标记 | 三端补 MessageBubble 的 quote 与 edited;契约加 `edited` 状态 |
| P1 | Tag、Tooltip、Progress、Spinner、ListItem、Divider | 通用原语 |
| P1 | Screen、SettingsRow、BrandLogo、InlineVoiceComposer、EmojiStickerPicker | 四端已有实现,补契约与缺端 |
| P1 | @提及高亮、通知中心、文件预览降级、会话分组 | 场景组件 |
| 不做 | 线程、收藏、定时发送 | 需 SDK 能力;文档写明原因 |

### 3.10 好用(文档)

- install.md 版本与安装方式改为与 1.0.14 一致;README 三处数字与状态、英文段翻译、增加 5 分钟接入与文档站链接;首页数字从契约读取。
- 英文站补 cross-device 与 im-component-system,23 个英文页去掉指回中文页的结尾。
- guide 新增:what-is-this、platforms/{vue,flutter,ios,android}、choosing-components、state-contract、i18n、accessibility、with-flare-core、upgrading、roadmap。
- 组件页统一模板:预览 → ComponentApi → 状态表 → 四端接入 → 可访问性 → 相关组件;56 页手写 Props 表改为 ComponentApi;ComponentApi 说明列可读。
- 内部验收记录移出公开站。

## 4. 分波次工作包

| 波次 | 内容 | 门禁 |
|---|---|---|
| 0 契约真实性 | 3.1 符号修正、3.2 事件/参数、3.3 术语表、validate 升级(props 四端存在性、事件反向、三端事件、反向覆盖、命名正则)、回调统一遗留 4 项、Vue 契约漂移 6 组件 | validate 反向验证会红;四端门禁 |
| 1 文案 | 3.5 全部;门禁脚本与阈值 | 中文字面量计数下降;四端门禁 |
| 2 视觉 | 3.6 全部 | 对比度门禁;tokens --check;截图矩阵 |
| 3 可访问性 | 3.7 全部 | 四端门禁;浏览器脚本 |
| 4 简洁 | 3.8 全部 | 分发/导出检查;pub publish --dry-run |
| 5 全面 | 3.9 P0 → P1 | 契约/覆盖矩阵/文档站 |
| 6 好用 | 3.10 全部 | 站点构建;链接检查 |

每波次结束:四端门禁 + spec/coverage/README/tokens/分发/导出检查 + 提交。

## 5. 验收记录

按波次追加,只记实际验证过的事实。

### 波次 0 契约真实性(2026-09-10)

- 契约:14 个 Vue 符号改为 `components/index.ts` 导出名;17 个 kebab 事件改 camelCase;14 个表单控件补 `model` 字段;新增顶层 `lexicon`、`eventAliases`、`composerActions`;prop 级 `platforms`、组件级 `eventPlatforms` / `platformAliases` / `deprecatedCallbacks` 把「Vue 专属」「原生专属」「平台惯用名」写成显式事实。Composer、ChatHeader、MessageActionSheet 契约按四端实现重写。
- 门禁:`spec/signatures.mjs` 提取四端公共签名(Vue defineProps/defineEmits/defineModel、Flutter 构造参数、SwiftUI public init、Compose 函数参数),validate 对 135 组件 × 4 端逐项比对 props 与事件,含反向(实现有回调而契约没记)。历史差异只剩 `signature-baseline.json` 里 3 项(ConversationDetails/Toast 三原生缺 `tone`,Compose PrimaryButton 签名不同,均归后续波次),基线只允许缩小。反向验证:给 Button 契约加一个不存在的 prop 与事件,validate 报 9 条错误。
- 实现:Vue ChatHeader 补 title/subtitle/presence/avatar 与 search/call/details;MessageActionSheet 四端统一 `id` 与 14 项动作表(旧 `build`/`key`/`create_*` 保留 deprecated);Avatar 补 `presence` 与 id/name 别名;ConversationDetails 改 `tone: FlareTone` 并去掉 SDK 类型依赖;GroupDetail `openChat` 四端同为位置参数;Flutter ConversationRow `onLongPress`;iOS/Compose NewFriendRequests `onView`、MessageBubble/MessageList 多选、Toast `onClose`、MessageStatus `onResend`;Compose Avatar `avatarUrl`,动作标签改取 strings。
- 验证:Vue typecheck、423 测试、198 SFC;Flutter analyze(3 个既有 info)、324 测试;iOS build、164 XCTest;Android compileDebugKotlin + 单测通过;spec/coverage/README 目录/tokens/分发/导出/token 兜底检查通过。
