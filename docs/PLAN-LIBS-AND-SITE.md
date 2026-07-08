# Flare IM UI Kit — 组件库补齐 (iOS/Android) + Ant-Design 式官网

> 主 PLAN 见 [PLAN.md](./PLAN.md)。本文件是本次战役（Track A 补齐原生组件库 + Track B 官网）的进度真源，跨会话续跑读它。

## Goal
「完成」的可检验定义：
1. **四端组件库齐全**：Vue ✅ + Flutter ✅ 已完成；新增 **iOS `FlareIMUI`(SwiftUI)** 与 **Android `flare-im-ui-compose`(Compose)**，各含 spec 全 18 组件 + 该端 tokens 生成器；`swift build`/`swift test` 与 `gradle :flare-im-ui-compose:compile*/test` 全绿；spec `validate.mjs` 扩到校验 iOS+Compose 符号，四端全存在。
2. **Ant-Design 式官网**：`flare-im-design/site`（VitePress）可 `build` 成功；含 首页/hero、设计（tokens 色板/间距/字号）、18 个组件文档页（每页：说明 + **真实 Vue 组件 live demo** + props/events API 表(取自 spec) + 四端代码用法 tabs），入门/安装（四端）。

## Constraints & decisions
- **no-compat**：不并存新旧路径；原生包抽取后（后续步骤）app 换依赖并删本地重复 token。
- **单一源**：tokens.json → 各端生成物 vendored 进各自包（web CSS/TS、Dart、Swift、Kotlin）。Swift/Compose 生成器加进 `tokens/build.mjs`（消费者落地才加，符合既定策略）。
- **纯展示 + 中立模型**：原生组件 props-in/callbacks-out，富内容/i18n/媒体管线上浮 app。Flutter 版是各端的参考实现（同名 symbol、同 props 语义）。
- **各端 idiom**：Swift enum、Kotlin enum/sealed、SwiftUI `@Binding`/闭包、Compose lambda。string-union → 各端 enum。
- **官网技术选型 = VitePress**（Vue 原生，可直接 import `flare-core-vue-im-ui` 真组件做 live demo；ant.design 是 React/dumi，我们组件核心是 Vue 故用 VitePress 更真）。API 表数据取 `spec/components.json`，代码 tab 取各端 README/用法。
- 工具链已确认在本机：swift / xcodegen / dart / flutter / node22 / npm。
- iOS 抽取源 = `flare-im-core-client-sdk/examples/flare-core-ios-app/Sources/FlareImApp`（有 Package.swift + project.yml）。Android 源 = `.../flare-core-android-app/app/src/main/kotlin`（build.gradle.kts，Compose）。
- 符号映射见 spec：iOS 包 `FlareIMUI` symbol=`AvatarView/…`；Compose 包 `com.flare.im:im-ui-compose` symbol=`Avatar/…`。

## Phase G — 组件美化：柔和 pastel 身份系统（已完成 ✅，2026-07-08，/frontend-design，参照 flare-core-flutter-app）
诊断：现状头像用**饱和实色 + 白字**（`#7C3AED`/`#22C55E`/`#F59E0B`…），读起来"生硬/通用"；参照 app（`flare_im_design.dart` `avatarPastelForKey`）用**柔和 pastel 对（浅底 + 深字，按 key 哈希）**——这是 Feishu/Linear/Notion 的高级感来源，也是单一最高杠杆的美化点。
- [x] **G-1 signature = pastel 身份系统 ✅**：6 组 pastel 对（blue `#DBEAFE/#1D4ED8`、purple `#E9D5FF/#6D28D9`、pink `#FBCFE8/#BE185D`、green `#D1FAE5/#047857`、amber `#FEF3C7/#B45309`、slate `#E5E7EB/#374151`），浅底 + 深字 + weight 600（原 700）。
- [x] **G-2 落到四端 shipped 组件 ✅**（不只 demo）：Vue `FlareAvatar.vue`(palette→pastel pairs, 去 `color:#fff`) + Flutter `flare_avatar.dart`(`_seedColor`→`_seedTint` 返 `(bg,fg)` record) + iOS `AvatarView.swift`(`seedColor`→`seedTint(bg:fg:)`, sRGB pastel) + Compose `Avatar.kt`(`seedColor`→`seedTint: Pair<Color,Color>`，连带 `CallView.kt`/`IncomingCall.kt` 三处共享调用点全改 bg+fg)。**vue-tsc / flutter analyze0+test57 / swift build+test13(改 `testSeedTintIsDeterministic`) / compileDebugKotlin+testDebugUnitTest(改 `seedTintDeterministic`) 全绿**。
- [x] **G-3 站点 demo 全量接入 ✅**：新建 `site/.vitepress/theme/demos/tint.js`（`tint(key)→{bg,fg}` + `initials()`，同 6 对 pastel）；重构 **16 个头像 demo** 用 `tint()`（AvatarDemo/ConversationRow/ConversationList/ContactList/ContactItem/ContactDetail/GroupList/NewFriendRequests/StartConversationDialog/MessageBubble/MessageList/ChatHeader/ConversationDetails/IncomingCall/CallView/HomeShowcase），删各自硬编码色 + `color:#fff`；人名/群名/room 统一按 name 键（HomeShowcase 修 rail 原按 id→改按 name，与 header/thread 一致）。**保留** Profile 自己头像为 brand-primary（"这是你"的主题化强调，刻意区分，非遗漏）；presence 点保持语义色（success/error/warning）在 pastel 上更跳。
- [x] **G-4 demo 舞台去"方格纸" ✅**：`.flare-demo` 背景由密集 divider 网格 → app 的极浅 `chatCanvas` 味（`color-mix(brand 4%, bg)` 底 + 22px 间距 6% 文字色微点，暗色 brand 8%），radius 12→14，更"静"。
- **验证**：Claude_Preview 实测——ContactList/Avatar/HomeShowcase 头像全变柔和 pastel（HF 琥珀/IC 粉/K 蓝/TF 紫 + 深字）；**暗色模式** pastel 浅片 + 深字在暗底仍清晰（头像自成一体）；vitepress build 绿。四端 shipped 组件 + 全站 demo 身份语言统一为 app 的 pastel。
- [x] **G-5 会话列表信号收尾 ✅**（续，对齐 app）：①**shipped `FlareConversationRow` 未读徽标红→品牌紫**——查证参照 app 每行徽标是 `conversationListUnreadBadgeBg #7C3AED`（紫），且 Flutter/iOS/Compose 三端 shipped + 我们全部 demo 都已是紫，**唯独 Vue shipped 用 `--error`（红）**是孤例/off-brand；改 `im-theme.ts` `--im-conv-unread-bg: error→primary` + 组件 CSS fallback `var(--error)→var(--primary,#7c3aed)`。vue-tsc 绿。②**置顶态渲染**——ConversationRow/ConversationList demo 原 `pinned:true` 是死标志，现补渲染**紫色圆角 pin 标记**（复刻 shipped 组件：28px/radius8/`primary 22%` 描边/`color-mix(primary 10%, surface)` 底/紫字），置顶行右留白 40px。③demo 头像键统一按**人名/群名**（ConversationRow/List 原按 id→改 title，Ivy/Henry 全站同色）。**实测**：ConversationList 现全信号词汇（置顶紫标记 + 免打扰铃 + 草稿 + pastel 头像 + 紫徽标）；pin 标记明暗双测（亮=浅紫底、暗=深紫底，均紫字清晰）；无横向溢出；build 绿。
- 决策/遗留：草稿 / @我 accent 三端 shipped + demo 现用 `error`（红），参照 app 用 `#EA580C`（橙）——**内部一致但与 app 略异**，改需加"draft/accent"语义 token 走四端管线，本轮不做（避免 over-reach），留后续。call 挂断 / 拒接的红（`#EF4444`）是语义色（通用挂断约定，app 亦红），保留。

## Phase K — 消息体交互模型：事件回调 + 自定义图标（进行中，2026-07-08）
用户看 FileMessage 页问："可自定义图标吗？下载是不是要给文件地址？其他也要处理。" 设计判断：这些组件是**解耦展示型**（不碰 URL），正确模型 = **抛交互事件**、宿主用自己的 URL/handler 处理；图标经 **slot** 自定义。
- [x] **Vue shipped 6 组件加交互 ✅**：`FlareFileMessage`(events `open`/`download` + `#icon` slot，下载图标改 button `@click.stop`) / `FlareImageMessage`(`click`) / `FlareVideoMessage`(`play`) / `FlareLinkCardMessage`(`open`) / `FlareContactMessage`(`open`) / `FlareLocationMessage`(`open`)，可点处加 `cursor:pointer`。**vue-tsc 绿**。
- [x] **spec 更新为契约 ✅**：6 组件补 events；FileMessage 加 `icon`(type `slot`) prop + notes 说明"download/open 宿主处理、组件不碰 URL、图标可自定义"。validate 51/9 绿。
- [x] **站点 demo 演示 ✅**：site FlareFileMessage 加同款 events + icon slot；FileMessageDemo 展示 2 卡（默认 folder / **`#icon` 插槽换视频图标**）+ 点下载/点卡片回显。regen + build 绿；Claude_Preview 实测：自定义图标渲染、download 点击回显、open 回显、控制台净；FileMessage 页 Props 现含 `icon(slot)`、Events `open/download`、用法 `@open/@download`。
- [x] **props/events 全面丰富（消息体，Vue + 契约）✅**（"属性应外部 props 传入，全面检查"）：审计 51 组件发现消息体最薄。**spec + Vue shipped 13 体全补**：VoiceMessage(+`playing` prop + `play` event) / VoteMessage(+`total` + `select(option,index)` event，选项改 button) / TaskMessage(+`toggle` event，勾选框可点) / Sticker/Emoji(+`click`) / ContactMessage(+`avatarUrl` 有图走图·无图 pastel、+`subtitle` 覆盖硬编码「Flare ID:」行) / LinkCardMessage(+`thumb`[原 Vue 有但 spec 漏]、+`description`) / ImageMessage·VideoMessage(+`alt` 无障碍) / LocationMessage(+`mapImage` 静态地图图) / TextMessage(+`selectable` + `linkClick(href)` event，链接改 data-href 委派)。**vue-tsc 绿 + 10 render 测试过**；regen 47→仍 51、build 绿；实测 ContactMessage 页 props=name/flareId/avatarUrl/subtitle、VoteMessage event=select、VoiceMessage event=play、控制台净、无溢出。
- [x] **组件通用化（去项目/语言绑定，Vue + 契约）✅**（"要通用一点，任何项目都能用"）：审计发现 shipped 组件内嵌了**中文默认文案 + Flare 品牌词**。改为中性英文默认 + 全部文案走 props：VoiceHoldButton 默认 `Hold to talk`/`Release to send`（原中文）；ComposerActionPanel `defaultActions` 标签改英文（Image/Camera/…）；ComposerReplyStrip 硬编码「回复」→ 新 `label` prop（默认 `Reply`）、aria `Cancel reply`；ComposerSendButton aria → `label` prop（默认 `Send`）；FileMessage/TaskMessage aria 改英文（Download/Toggle done）；**ContactMessage 去掉品牌专属 `flareId` + 硬编码「Flare ID:」→ 通用 `subtitle`**（自由副标题）。spec 同步（删 flareId、加 2 个 label prop、subtitle 描述通用化）；site demo 对齐（ContactMessage demo/wrapper/MessageContentView 用 subtitle；ProfilePanel/ContactDetail 样例 `Flare ID:`→`@handle`）。**vue-tsc + 10 render 测试 + validate 51/9 + build 全绿**；实测 ContactMessage props=name/avatarUrl/subtitle（无 flareId）、demo 显 @ivy_chen、控制台净。shipped 组件复查**已无硬编码中文/Flare 词**（`Flare` 前缀仅作库命名空间，保留）。
- [x] **Flutter shipped 三合一补齐 ✅**（"按推荐推进"，1/3 native）：`flare_message_bodies.dart` 整文件重写——13 体全加**交互回调**(onTap/onOpen/onDownload/onPlay/onSelect(opt,idx)/onToggle) + **丰富 props**(image/video/avatar/thumb/mapImage 改 URL 走 `Image.network`+errorBuilder 占位、alt→Semantics、voice playing、vote total、linkcard description、text `selectable`+`onLinkTap`[StatefulWidget+TapGestureRecognizer 带 dispose]) + **ContactMessage 去 flareId→subtitle**。composer 部件**通用化**：`flare_voice_hold_button.dart` 默认改英文(Hold to talk / Release to send·slide up to cancel / +cancelLabel)、`flare_composer_parts.dart` ReplyStrip 加 `label`(默认 Reply)、`flare_message_action_sheet.dart` defaultActions 标签改英文(Image/Camera/…/Poll)。**flutter analyze 0 + test 65/65**（修 3 个断言旧中文/flareId 的测试）。复查 Flutter shipped 已无硬编码中文/Flare 词。
- [x] **iOS shipped 补齐 ✅**（3/4 native）：`MessageBodyViews.swift` 整文件重写——13 体全加**交互闭包**(onTap/onOpen/onDownload/onPlay/onSelect(opt,idx)/onToggle) + **丰富 props**(image/video/avatar/thumb/mapImage 改 URL 走 SwiftUI `AsyncImage`+占位、alt→accessibilityLabel、voice playing、vote total、linkcard description、text `selectable`[`textSelection`]+`onLinkTap`[`AttributedString` 增量 linkify + `OpenURLAction` 拦截]) + **ContactMessageView 去 flareId→subtitle**。踩坑：`textSelection(cond ? .enabled : .disabled)` 两态类型不同 → 抽 `textSelectableIf(_:)` @ViewBuilder。composer 部件**通用化**：`ComposerParts.swift` VoiceHoldButton 默认改英文 + `DragGesture` 实现上滑取消(cancelLabel/cancelThreshold/onCancel)、ReplyStrip 加 `label`(默认 Reply)。**swift build 绿 + test 14/14**（修 `testStandaloneMessageBodiesConstruct` flareId→subtitle）。
- [x] **Compose shipped 补齐 ✅**（4/4 native，收官）：`MessageBodies.kt` 整文件重写——同上交互 lambda + 丰富 props；URL 图走 **Coil `AsyncImage`**（`build.gradle.kts` 加 `io.coil-kt:coil-compose:2.7.0`，mavenCentral 已在），抽 `NetImage(url,placeholder)` helper + `Modifier.onClickIf(action?)` 扩展；text `selectable`→`SelectionContainer`、`onLinkTap`→`buildAnnotatedString`+`LinkAnnotation.Url`(BOM 2024.12=foundation1.7 有)；FileMessage `icon` 改 `@Composable` slot；**ContactMessage flareId→subtitle**。composer 通用化：VoiceHoldButton 默认英文 + `awaitEachGesture` 干净上滑取消、ReplyStrip 加 `label`、send/close aria 中文→英文。**compileDebugKotlin + testDebugUnitTest 绿**。**四端(Vue/Flutter/iOS/Compose)交互模型 + 丰富 props/events + 通用英文默认全齐**；validate 51/9 四端符号绿。
- [x] **全组件去中文默认（四端 shipped 组件库）✅**（"需要,并继续"）：对四端**可复用组件库**(`vue-im-ui/src/components`、`flutter-im-ui/lib/src/components`、`ios-im-ui/Sources`、`android-im-ui/src/main`)做系统化去中文。方法：审计出 232 个不同的用户可见中文字面量（421 处）→ 建**单一翻译词典** + 脚本做**分隔符定界的整字面量精确替换**（`"zh"→"en"`、`'zh'`、`` `zh` ``；长优先；插值 token `${}`/`\()`/`$x` 原样保留；子串与嵌套引号天然安全）；Vue 模板**文本节点**(标签间可见文字，非引号)另用 Vue-only 片段词典二次扫。**结果四端组件源非注释中文 = 0**。语言自称名等无需改（组件库本无）。**验证四端全绿**：vue-tsc / flutter analyze0+test 65（修 10 个断言旧中文默认的测试：免打扰→Mute、删除会话、确定→OK、词→words、草稿、暂无会话、还没有消息、接受→Accept、4 名成员→4 members、邀请你语音通话）/ swift build+test 14（iOS 测试的中文皆为自传 props，无需改）/ compileDebugKotlin+testDebugUnitTest。95+27 文件改。
- **遗留（Vue-only，须走 i18n 而非硬翻）**：`vue-im-ui` 的**非组件层**仍有中文——`src/shared/i18n/messages.ts`(419) 是 **zh locale 词典本身，正确，勿动**；`src/app`(339,demo 工作台)/`src/composables`(68,SDK 接线)/`src/utils`(71) 是导出的**示例/胶水层**（含消息预览"发送了一张图片"、同步进度"准备同步"、messageTypeRegistry 标签/校验名、workbench 主题名等）。这些**应路由到既有 i18n**（包已导出 `./i18n` + `useFlareI18n`），是真重构而非翻译脚本可解；且语言选择器里的 `简体中文` 等自称名必须留。Flutter/iOS/Compose 三端包**无对应胶水层**（其 src 全域已 0 中文），故本项 **Vue 独有**。待用户确认是否推进。

## Phase J — 每种消息拆成独立组件（已完成 ✅，2026-07-08）
用户："最好将每个消息单独做成一个组件这样更灵活"。查证：Vue 包内部**已有** per-type views(TextView/ImageView/VideoView/FileView/LocationView/CardView/LinkCardView/StickerView/VoteMessageView…)，但 props 耦合内部 `content: ContentElem`、未公开 → 不是"重建"而是"暴露 + 清爽 API"问题。
- [x] **13 个独立组件（清爽 props，自成一体，自由组合）✅**：`site/.vitepress/theme/demos/messages/` 建 `FlareTextMessage`(text/self, 自动 linkify) / `FlareImageMessage`(src/w/h) / `FlareVideoMessage`(poster/duration) / `FlareVoiceMessage`(seconds) / `FlareFileMessage`(name/size/ext) / `FlareLocationMessage`(title/address) / `FlareContactMessage`(name/flareId, pastel 头像) / `FlareLinkCardMessage`(title/domain/thumb) / `FlareVoteMessage`(title/options[{text,pct}]) / `FlareTaskMessage`(title/meta/done, 完成划线) / `FlareStickerMessage`(emoji/src) / `FlareEmojiMessage`(emoji) / `FlareSystemMessage`(text)——各自 SFC，props 简洁可直接用。
- [x] **MessageContentView demo 改为组合这 13 个 ✅**：每项以其**组件标签**(`<FlareFileMessage>` 等)作标签，直观证明"每种消息=独立组件、可单独用"；示例区加策展例「每个类型都是独立组件」(四端：单独用任一 body 或交给 dispatcher 按 content.type 分派)。
- **验证**：13 组件全渲染、示例区 2 例、移动 375px + 暗色无横向溢出、控制台净、vitepress build 绿。
- [x] **Vue shipped 公开导出 13 个独立组件 ✅**（"继续"）：查证内部 views(FileView 等)**深度耦合 SDK/媒体管线**(useMediaResolver/download state/ContentElem)——不可 standalone 复用，包装它们脆弱。故建**解耦的展示层**：`vue-im-ui/src/components/messages/standalone/` 13 个清爽 props SFC（`--im-*` 变量 + token 值 fallback 保证无主题也渲染）+ `MsgIcon.vue`(内联 SVG，零 naive-ui 依赖)；barrel 导出 `FlareTextMessage/…/FlareSystemMessage`（与既有 SDK 驱动的 `Flare*MessageView` 不撞名）。**定位**：解耦展示层（产品喂简单 props 自由组合）vs `FlareMessageContentView` 分发器（SDK 驱动 batteries-included），两条路各司其职、非冗余。**验证**：`vue-tsc` 绿（含 barrel index.ts）；新增 `renderToString` 测试 10/10 过（各类型挂载+输出断言，媒体类型无需 SDK 即渲染）；全套 14 测试全过（2 个 SDK 缺失导致的 collection 失败是**预存环境问题**非本次引入，其导入 `flare-core-typescript-sdk`）。视觉等价于已验证的 site demo（同标记）。
- [x] **Flutter/iOS/Compose 四端齐平 ✅**（"需要"）：三端各落 13 个解耦独立组件（同解耦展示层定位，复用各端 pastel/initials helper 免重复）：
  - **Flutter** `flare_message_bodies.dart`（`FlareTextMessage`…`FlareSystemMessage` + `FlareVoteOption`，StatelessWidget，FlareColors.of/FlareSizes/Material outlined 图标）+ barrel 导出；**analyze 0 + test 65/65**（+8）。
  - **iOS** `MessageBodyViews.swift`（`TextMessageView`…`SystemMessageView` + `FlareVoteOption`，`…View` 命名随 iOS 惯例，复用 `AvatarView.seedTint/initials`，SF Symbols）；**swift build + test 14/14**。
  - **Compose** `MessageBodies.kt`（`TextMessage`…`SystemMessage` + `FlareVoteOption`，裸命名随 Compose 惯例，复用 `seedTint/initials`，`Icons.Outlined.*`）；**compileDebugKotlin + testDebugUnitTest 绿**。
  - 命名随各端惯例（Vue/Flutter=`Flare*Message`，iOS=`*MessageView`，Compose=`*Message`）；修 site 策展例 ios/compose 代码为真实名。重跑 pack-downloads 刷新 4 下载包；site regen + build 绿。
- [x] **13 个消息视图提升为 spec 独立组件条目 ✅**（用户："这里拆解显示各种消息视图"，指侧栏 消息 组）：spec 加 13 条（Message 类，插在 MessageContentView 后）——各带双语 summary/dataSource/props(双语描述) + 四端符号（vue=`FlareTextMessage`… / flutter 同 / ios=`TextMessageView`… / compose=`TextMessage`…，validate 递归 find/grep 全部解析通过）；建 13 个 demo 包装（`demos/messages/demos/*Demo.vue` 渲染 site 标准组件带样例 props）+ theme 注册 + 生成器 demoOf 映射。**组件数 34→47**，改 4 处文档计数 + 首页 stats（34→47，过计数门禁）。`node validate.mjs` **47/9 绿**（四端符号全验），regen 47×2 页 + build 绿；Claude_Preview 实测侧栏 消息 组现列出 MessageBubble/List/ChatHeader/PinnedMessageBar/MessageContentView **+ TextMessage…SystemMessage(13) +** MessageActionSheet；FileMessage/VoteMessage 页预览+props+四端网格(真实各端名)+用法全出，无横向溢出，控制台净。
- **遗留（可选）**：Flutter/iOS/Compose 也可各加对应的 render/construct 测试断言这 13 个（Vue 已有 10 render 测试；三端目前靠 compile + 既有 construct 测试覆盖）。
- [x] **Composer 部件补齐四端 → 4 部件全拆解 ✅**（"按规划和推荐继续"）：把原 **Flutter 独有**的 `ComposerSendButton`(active + send) / `ComposerReplyStrip`(senderName/summary + cancel) 补到 **Vue/iOS/Compose**（`ComposerIconButton` 因 icon 是各端异构的 slot/IconData/systemName/ImageVector，**不成清爽中立契约，刻意跳过**）。Vue 新建 2 SFC(用 `--flare-color-*` 随同族 parts 惯例 + 内联 SVG)+ barrel；iOS 追加 2 struct 到 ComposerParts.swift(SF Symbols)；Compose 追加 2 composable 到 ComposerParts.kt(`Icons.AutoMirrored.Filled.Send`/`Rounded.Close`)。**vue-tsc / swift build / compileDebugKotlin / flutter analyze 四端全绿**（踩坑：Compose FontWeight 重复 import + 漏 `layout.width` import + 去掉 no-op border）。提升 2 者为 spec 独立组件（Composer 类，插在 ActionPanel 后）+ 2 demo(送按钮双态点击 / 回复条取消) + 注册 + demoOf；**Composer notes 更新为列全 4 部件**、2 新部件回链 Composer。**组件数 49→51**，改 5 处计数。validate 51/9 绿、build 绿；实测侧栏 输入 组现列 Composer + 4 部件 + RichMarkdownInput，送按钮 active 点击回显、回复条 cancel 生效、Composer TIP 4 链接全出、控制台净、无溢出。
- [x] **Composer 拆解同样串联 ✅**（"继续"）：查证四端**都存在**的 composer 部件只有 2 个 → **VoiceHoldButton**（label/recordingLabel + start/end/cancel）+ **ComposerActionPanel**（actions/columns + action），其余(IconButton/SendButton/ReplyStrip)仅 Flutter 有，不够四端。把这 2 个提升为 spec 独立组件（Composer 类，插在 Composer 后，四端符号皆 `FlareVoiceHoldButton`/`FlareComposerActionPanel`，validate 全解析）；建 2 个 site demo(VoiceHoldButtonDemo 按住/上滑取消交互 + ComposerActionPanelDemo 8 宫格) + 注册 + demoOf；**双向 notes**：Composer→列出 2 部件、2 部件→回链 Composer。**组件数 47→49**，改 5 处计数。validate 49/9 绿、build 绿；实测侧栏 输入 组现列 Composer/VoiceHoldButton/ComposerActionPanel/RichMarkdownInput，VoiceHoldButton 页按住交互回调正常(end·语音已发送)、ActionPanel 8 tile、TIP 回链有效、控制台净。
- [x] **文档完善：拆解故事双向串联 + 投票示例 ✅**（"继续完善文档"）：诊断=13 新页与分发器**互不链接**、架构关系不可导航。①**13 个消息体各加 `notes`(TIP)** 回链 [MessageContentView] 并说明"解耦展示型、实时数据交给分发器按 content.type"；②**MessageContentView `notes`** 反向**一行列出并链接全部 13 个**（保留注册表说明）——双语、locale 正确路径(zh `/components/` · en `/en/components/`)。③给 `VoteMessage` 加策展例（唯一非平凡 API：`FlareVoteOption[]` 的 { text, pct } 各端构造）。validate 47/9 绿、regen 47×2 + build 绿；实测分发器 TIP 13 链接全可点(3 行环绕)、body 页 TIP 回链有效、vote 页示例四端出、控制台净、无死链(VitePress 死链检查过)。

## Phase I — 全类型消息展示 + 打包分发（已完成 ✅，2026-07-08）
用户：①各种消息展示做成一个组件 ②flutter 上传仓库、安卓 / iOS 提供可直接引用的包、官网提供下载链接 + 引用说明。
- [x] **I-1 MessageContentView 全类型展示 ✅**：demo 从 5 型扩到**13 型**（text 带链接 / image / video[播放叠层+时长角标] / audio[波形] / file[卡片] / location[地图区+地址] / card[pastel 头像名片] / linkCard[缩略图+标题+域名] / vote[进度条选项] / task[紫勾+截止] / sticker[裸大图] / emoji[裸大] / notification[居中 pill]），全部按 app 白卡/画布/pastel 语言；实测 13 项无横向溢出、控制台净。
- [x] **I-2 包元数据可分发化 ✅**：Android `build.gradle.kts` 加 `maven-publish` + `group=com.flare.im`/`version=0.1.0` + `singleVariant("release")+withSourcesJar` + `afterEvaluate` publication（坐标 `com.flare.im:im-ui-compose:0.1.0`）——`compileDebugKotlin` 绿 + `publish` 任务已注册；Vue `package.json` 补 homepage/repository(directory)/bugs；Flutter/iOS 元数据已具备（pubspec repository / Package.swift SPM）。
- [x] **I-3 官网下载 + 引用说明 ✅**：`site/scripts/pack-downloads.sh`（vue=`npm pack`；flutter/ios/android=tar 排除 build/.gradle/.dart_tool/.build）产 4 个源码包到 `site/public/downloads/`；新增双语 `guide/install.md` + `en/guide/install.md`（下载表 4 链接 + 每端三法：仓库/Git·SPM/下载包 code-group + 用法 + **维护者发布命令**明确标注需自备凭据）；nav+sidebar 两语加「安装」；`config.mts` 加 `ignoreDeadLinks:[/^\/downloads\//]`（静态资产非页面）。**vitepress build 绿**，dist/downloads 4 包就位，实测下载链接 200（vue tgz 245KB）、en 页 4 链接、控制台净。
- **边界（须用户自备凭据/outward-facing，我未执行）**：npm publish / dart pub publish / git push+tag / `./gradlew publish` 到远端——install 页已给逐条命令；「flutter 上传仓库」因本目录非 git 仓库且推远端需鉴权，由用户执行（或授权具体步骤）。Vue 包 registry 安装还依赖 `flare-im-design-tokens`+peer sdk 也发布/link，已在 install 页注明。

## Phase H — MessageActionSheet 对齐 flutter 长按菜单（已完成 ✅，2026-07-08）
用户："MessageActionSheet 要参照 flutter 现在的样式"。参照源 = app `message_long_press_menu.dart`（Feishu 式分层 sheet）。
- **发现语义冲突**：demo（新旧都）是「消息长按菜单」，但 shipped `composer/MessageActionSheet.vue` + spec 实际是「输入框附件/加号面板」（image/file/vote）。**AskUserQuestion 确认 → 用户选「消息长按菜单」**。
- [x] **demo 重做为 flutter 长按菜单 ✅**：**灰画布**(`bg-tertiary`)上浮**白卡**(radius10, 6px gap)——①表情条(6 emoji + 末尾灰 more chip)②**脱开的快捷行**(回复/转发/撤回 三张独立卡, 竖排 icon22+label11)③分组列表卡(多选·标记 / 置顶消息·仅自己置顶 / 复制·编辑 / 删除红)，行内**发丝分割线用伪元素 inset 42px**(不移行内容)。DemoIcon 加 7 图标(reply/forward/undo/flag/checklist/copy/pinTop)。
- [x] **spec 改为长按菜单语义（契约即真源，实现须跟上）✅**：summary/dataSource 重写；props= open/reactions/menuConfig/canRecall（双语）；events= react/reply/forward/recall/multiSelect/mark/pin/copy/edit/delete；states= reactionStrip/quickActions/emojiExpanded；**category `Composer`→`Message`**（长按菜单属消息域）。validate 绿(双语完整)、regen 34×2 页、vitepress build 绿。
- **验证**：Claude_Preview 实测明暗双测——卡片浮于画布、分割线 inset、删除红、点击回显生效、无横向溢出；页面 summary/props/events/demo 现全一致。
- **遗留（须跟上契约）**：4 端 shipped `MessageActionSheet` 现仍是**附件构建器**，需重构为长按菜单以匹配新 spec；附件构建职责由 `ComposerActionPanel`(+下方功能区) 承接。这是较大的四端重构，单独一轮做。

## Phase F — 组件细化 + 文档完善 + 中英双语（已完成 ✅，2026-07-08）
目标：①**细化**——115 个 prop 原**零描述**，补齐"每个 prop 干什么/默认/坑"。②**完善文档**——summary/dataSource 语言统一（原 16 中 / 18 英混杂）。③**中英双语**——spec 文案变 `{en,zh}` 单源，生成器按 locale 产两套页，VitePress `locales`（根=中文 / `/en/`=英文）。
- [x] **F-1 spec 双语 schema + 内容 ✅**：`summary`/`dataSource`/`notes` → `{en,zh}`；**115 个 prop 全部补 `description:{en,zh}`**（原零描述）。经一次性 `spec/migrate-i18n.mjs`（内联 CONTENT 全量作者化 + **覆盖校验**：缺任一组件/prop/语言即 exit 1）产出双语 `components.json`；顺带把 9 个 category 的中英标签 `categoryLabels` 挂上 spec 供生成器/config 消费。
- [x] **F-2 生成器 locale 化 ✅**：`gen-components.mjs` 加 `pick(field,loc)`（`{en,zh}`→取对应，字符串→两语通用）+ `UI[loc]` 字典（Props/States/Events/各端实现/用法/预览/示例/数据源/规划中/总览…）；循环两 locale 产 `components/*.md`(zh 根) + `en/components/*.md` + 各自 index；**prop 表加"说明/Description"列**；`dataSource` 冒号按语言（zh 全角`：`/en 半角`: `）。策展示例 10 段 title/description 双语化（node 精确替换 24 串）。
- [x] **F-3 VitePress i18n ✅**：`config.mts` 重写为 `locales`（root=简体中文 `zh-CN` / `en`=English `en-US`，各带 nav/sidebar/outline label/docFooter/footer/description）；语言切换器实测把 `/en/components/avatar` 正确映射到 `/components/avatar`（同组件对语言页）。
- [x] **F-4 英文 guide + 首页 ✅**：`en/index.md`（英文 hero + stats + `<HomeShowcase/>`）+ `en/guide/{getting-started,tokens,theming,spec}.md` 四篇全译；**`HomeShowcase.vue` locale 化**（`useData().lang` 驱动 `T` 计算属性：主题/搜索/在线/占位/caption/会话名/线程消息中英两套），英文首页旗舰演示实测全英文且主题切换保留；顺带修 zh `guide/spec.md` 陈旧示例（字符串 summary→双语形态、18→34 计数、validate 描述补双语+计数校验）。
- [x] **F-5 validate + build + 实测 ✅**：validate 加**双语完整性校验**（summary/dataSource/notes 必 `{en,zh}`、**每 prop 必有 en+zh 描述**）+ E-7 计数门禁扩到英文两页（`34 components · 9 categories` / `all 34 components`）。`node validate.mjs` 绿（34/9）；`vitepress build` 绿（**dist：中英各 35 组件页 + 4 英文 guide**）；Claude_Preview 实测：英文 Avatar 页（nav/Data source/Props Description 列全英）、语言切换器映射、英文首页 + showcase 全英、中文页零回归、控制台 0 warn。**门禁验挂**：改坏英文计数→exit 1；删一个 prop 描述→`prop "userId" missing bilingual description`+exit 1；还原→exit 0。
- 遗留（低优先）：35 个组件页的 **live demo 内样本文案仍中文**（如 composer/searchbar 的「发送消息…」「搜索」），属示例样本数据非文档正文；仅旗舰 HomeShowcase 已 locale 化。策展示例**代码片段里的少量中文注释**（如 composer 的 `// 需要时展开：`）同理未译。二者可后续做（各端 demo 抽 locale 字典）。

## Status: DONE ✅ —— Phase C 全部完成
Track A/B（原始 18 组件四端 + 官网）✅ + **Phase C 全 ✅**：C-1 改名 / C-2 主题系统 / C-3 spec+16 / C-4 四端实现全 34 / C-5 自适应四端 / planned→stable / C-6 站点每组件详细示例，均已落地验证。
**成果**：四端各 34 组件（Android/Vue/iOS/Flutter，全部 build+test 绿）、tokens 生成器四端 + runtime 主题系统 + Vue Provider、自适应四端、spec validate 34×四端符号全绿、官网 34 组件页（prop-aware 四端用法 + 策展示例 + live demo + 主题 playground）build 绿。
剩留给用户：npm 实发、官网托管、（可选）各端 app 换依赖删本地重复 token。

## Phase E — site 更新优化（已完成 ✅，2026-07-08）
目标：官网 **34/34 组件均有 live demo**，且 demo 图标语言与四端 D-4 简洁 outlined 语汇一致（原状：18/34 有 demo，12 个 demo 用 emoji 当 UI 图标）。
- [x] **E-1 demo 图标语言统一 ✅**：新建 `demos/DemoIcon.vue`（**48 个内联 outlined SVG**，viewBox24 / stroke=currentColor / 1.6 / round，对齐 Material Symbols Outlined 观感，零运行时依赖）；12 个既有 demo 里**当 UI chrome 用的 emoji**（🔍📞🎙️🎥🖼️⚙️▦✕↑📌🔕📭…）全换成 `<DemoIcon>`。**保留消息正文里的 emoji**（🎨👍 是真实内容而非图标）。踩坑：MessageBubbleDemo 曾误加重复 `.meta` 规则（选择器叠加），已合并成单条。
- [x] **E-2 补齐 16 个缺失 demo → 34/34 ✅**：MessageList(日期分隔/未读线/加载更早/多选勾选) / MessageContentView(text·image·voice·file·system 五型) / ConversationDetails(连接态 pill 三档+统计) / StartConversationDialog(搜索+多选+busy) / RichMarkdownInput(格式工具条+实时预览+字数) / MessageActionSheet(表情行+9宫格) / ImagePreviewModal(缩放 clamp+下载进度) / VideoPlayerModal(播放+进度条+onUnmounted 清 timer) / ContactItem(四档 presence) / ContactDetail / NewFriendRequests(接受·拒绝·已添加) / GroupList / ProfileEditor(头像相机角标+字数+busy) / SettingsList(switch·value·nav 三型) / AppShell(手机底栏 vs 平板 Rail 并置) / ResponsiveLayout(h5·ipad·pc 三档可切)。模态类以「已打开」静态态框内展示，不做真 overlay。
- [x] **E-3 Composer parts 自由组合 live demo ✅**（Phase D 遗留）：`ComposerPartsDemo.vue` 展示 `FlareVoiceHoldButton`(pointer 按住/上滑取消) + `FlareComposerActionPanel` + `FlareComposerSendButton` 自拼；生成器加 `partsDemoOf` map → composer 页多出 `### 自由组合（用 parts 自己拼）` 小节。
- [x] **E-4 接线 + 验证 ✅**：`theme/index.ts` 改为 `demos` 对象批量注册（36 个）；`gen-components.mjs` `demoOf` 补 16 + `stackDemos` 扩容 → 重生成 **34/34 页均含 `## 预览`**；`vitepress build` 绿。**Claude_Preview 实测**：多选勾选 / switch 开关 / v-html Markdown 预览 / 语音按住·上滑取消双分支 / 视频播放进度 / 图片缩放 clamp+下载进度 / 三档断点切换 / 暗色 token 联动（`data-flare-theme=dark`，卡片 #1A1D23）全部通过；控制台 0 warn/error；17 个新页面移动端 375px **无横向溢出**。
- [x] **E-6 首页重做 ✅**：①**修陈旧事实**——hero features 写着「18 个组件 · 5 大类」，实际 34/9（`getting-started.md` 也有一处 18）。②**emoji feature 图标（🧩🎨🦀⚡🔌📐）换成内联 outlined SVG**（VitePress `VPFeature.vue:42` 对 string icon 走 `v-html`，可直接内联；构建产物验明 6 个 `<svg>` 原样未转义）。③**新增 signature `HomeShowcase.vue`**——用 tokens 渲染的**完整 IM 界面**（窗口 chrome + 会话列表 + ChatHeader + 白卡/紫气泡线程 + composer），配 6 个预设主题 chip **实时换肤**（`applyFlareTheme(preset, stage)` 只作用子树，实测 hero 按钮不跟着变）。④stats 条（34 组件 / 9 分类 / 4 端 / 1 份 tokens，tabular-nums）。**Claude_Preview 实测**：Ocean 切换 → 气泡/发送键/角标/选中态全变蓝；暗色 + 375px 无横向溢出、rail 自动隐藏。修了一个真问题：移动端 canvas 定高把**最新一条消息**拦腰截断 → 改 `justify-content:flex-end`（贴底，裁最旧而非最新，符合真实 IM）+ 移动端 panes 420px。
- [x] **E-7 计数漂移门禁 ✅**：首页宣称「validate 防漂移」，但 34/9 这些数字是手写的、本轮就漂了两处。`spec/validate.mjs` 加**文档计数校验**（对 `site/index.md` 的 `N 个组件 · M 大类` 与 `getting-started.md` 的 `全部 N 个组件` 做断言，N/M 取自 spec）。**验证门禁真的会挂**：故意改成 33 → `✗ spec invalid (1)` 且 **exit code 1**；还原 → exit 0。（首次验证时 `$?` 读的是 `head` 的退出码，重测才确认。）
- [x] **E-5（实测中发现的真 bug）全站移动端横向滚动 ✅**：`custom.css` 的 `.vp-doc table { display: table }` **覆盖了 VitePress 默认的 `display:block; overflow-x:auto`**，导致 34 页的 Props 宽表在 <720px 把整个 body 顶出横滚（实测 docScrollW 496 > 375）。加 `@media (max-width:720px)` 恢复表格自身滚动（`display:block; width:max-content; max-width:100%; overflow-x:auto`）；桌面端仍 `display:table` 全宽（688=容器宽，无回归）。另修 MessageContentViewDemo `.file{min-width:220px}` 不可收缩 → 改 `flex:1 1 auto; min-width:0` + 文件名 ellipsis。

## Phase D — 设计打磨 + Composer 组件化（进行中，2026-07-08）
- [x] **D-0 Flutter 设计 pass**（见 [[flare-im-ui-flutter-design-pass]]）：白卡接收气泡+画布+内联时间+3 primitives，analyze0/test55。
- [x] **D-1 气泡语言统一 → iOS + Compose ✅**（Flutter 已做）：received=白卡(bgPrimary)+hairline 描边+whisper 阴影+内联时间、self=紫、radius16、canvas=bgSecondary、正文15/1.45。iOS `swift build`、Compose `compileDebugKotlin` 绿。**Vue 待做**（成熟组件 MessageBubble.vue，谨慎；site demo 已反映新语言）。
- [x] **D-2 Composer 组件化（Flutter）✅**：拆出可自由组合小组件——`FlareVoiceHoldButton`(按住说话/上滑取消)、`FlareComposerIconButton`、`FlareComposerSendButton`、`FlareComposerReplyStrip`、`FlareComposerActionPanel`(下方功能区展开网格，复用 FlareComposerAction)；`FlareComposer` 重建为**完整可直接用**默认装配（voice 模式切换 + `actions` 时 `+` 展开 AnimatedSize 面板 + 无 actions 时 `+`→onAttach 向后兼容）；parts 经 `export` 暴露供自由组合。**analyze 0 + test 57/57**（+2 新：voice 切换 / 面板选择）。
- [x] **D-3 site Composer demo + 示例 ✅**：ComposerDemo 展示语音切换 + 展开下方功能区网格；examples.mjs 加 2 段策展示例（「语音+下方功能区（完整可直接用）」四端 + 「自由组合：用 parts 自己拼」四端）。vitepress build 绿，Claude_Preview 实测（8 宫格展开 / mic→「按住 说话」 / composer 页 3 段 h3 全出）✓。
- 决策：`bubble.other` legacy token 仅剩 vue im-theme.ts 两处未消费 CSS var 定义——删它需 4 端 regen（原生 FlareColors 掉字段）风险>价值，**保留不动**。
- [x] **D-4 图标简化四端 ✅**（依托 flare-core-flutter-app 图标语汇：outlined-first + thin，纯 check/done_all/error_outline 回执，少量 _rounded chrome）：**Flutter**(lib+test perl 批改 57 处：check_rounded→check、done_all_rounded→done_all、error_outline_rounded→error_outline、delete_outline_rounded→delete_outline、push_pin_rounded→push_pin_outlined、videocam(_off)→_outlined、mic(_none_rounded)→mic_none、volume_up(_rounded)→volume_up_outlined、call→call_outlined、arrow_upward_rounded→send_rounded；test 同步；analyze0/test57) + **iOS**(功能性 SF Symbol 去 .fill 13 处：mic/video/phone/phone.down/speaker.wave.2/message/camera/xmark.circle/…；**保留** checkmark.circle.fill、play.circle.fill、pin.fill 语义填充；swift build + test 13/13) + **Compose**(7 文件 Filled→Outlined：CallControls[CallEnd/Cameraswitch/Mic/MicOff/Videocam/VideocamOff/VolumeUp]、ContactDetail[Message/Phone/Videocam]、IncomingCall[Call/CallEnd]、Input+SearchBar[Cancel]、ProfileEditor[PhotoCamera]、ProfilePanel[Star/Collections/Settings/QrCode]；**保留** AutoMirrored.KeyboardArrowRight、Rounded.CheckCircle/PlayCircle/PushPin 语义；compileDebugKotlin + testDebugUnitTest 绿) + **Vue**(composer send `arrow_upward_rounded`→`send_rounded` 已随 D-2 落)。**四端图标语言统一为 flutter-app 的清简 outlined 语汇**。
- [x] **D-2 Composer 组件化四端 ✅**：**Compose**(ComposerParts.kt: `FlareVoiceHoldButton`[detectTapGestures 按住]/`FlareComposerActionPanel`[grid]; `Composer` 加 voice 模式+AnimatedVisibility 面板+enableVoice/actions/onAction/onVoice*; gradle 绿) + **iOS**(ComposerParts.swift: `FlareVoiceHoldButton`[onLongPressGesture pressing]/`FlareComposerActionPanel`; `ComposerView` 加 voice/panel; swift build 绿) + **Vue**(独立 parts `FlareVoiceHoldButton.vue`[pointer 事件]/`FlareComposerActionPanel.vue`, 导出; vue-tsc 0 —— Vue 完整 composer 仍是成熟 EnhancedComposer, 补 parts 供自由组合)。
- [x] **D-1 Vue 气泡白卡 ✅**（专项定位后单行修）：真正来源=`apply-flare-theme.ts` `--im-message-incoming: colors.bubble.other`(#ECE5FF 浅紫)，被 `message-bubble.css` 的 `color-mix(incoming 94%, bg-surface)` 当接收气泡填充 + 已有 border(74% im-border)+shadow+尾角。**改为 `colors.bg.primary`（白/暗色随 surface）→ 接收气泡变白卡**，主题感知、暗色自动。核查 `--im-message-incoming` 仅 2 处消费(text 色不变 + tail-fill)，无假设浅紫的多态规则 → 零回归风险。**vue-tsc 0**。**四端气泡语言全统一**（Vue 圆角 14 vs 原生 16 属各端微调，保留其 focus-ring/group-end 精调不动）。

## Phase C — 扩展与完善（已完成，见下）

### C-1 Android 包改名 `compose-im-ui` → `android-im-ui` ✅
- [x] `mv` 目录；改 `tokens/build.mjs`(Kotlin 输出路径)、`spec/validate.mjs`(composeRoot)、README/getting-started/PLAN 引用；regenerate tokens → **`gradle compileDebugKotlin` 绿 + spec validate 四端绿**。

### C-2 主题系统（可定制/自由组合/引入即用）✅
- [x] **`flare-im-design-tokens/theme`**（新 `tokens/theme.js`+`theme.d.ts`，加进 package exports/files）：`deriveFlareTheme({primary,…})`（HSL 派生 hover/active/气泡/链接/选中）、`applyFlareTheme(overrides, el?)`（作用整页或**子树**，多主题共存）、`flareThemeVars`、6 内置预设 `flarePresets`(violet/ocean/forest/sunset/rose/graphite)。
- [x] **site `guide/theming.md` + `ThemePlayground.vue`**：取色器+预设 chip **实时换肤**（Claude_Preview 实测点 Ocean→全组件秒变蓝，✓）。nav/sidebar 加"主题定制"。`vitepress build` 绿。
- [x] **Vue `FlareThemeProvider` ✅**（`design-system/provider/FlareThemeProvider.vue`：`theme` prop→子树 CSS 变量，`display:contents` 布局透明，可嵌套）；导出 + vue-tsc 0 err。
- [ ] Flutter/iOS/Android 主题下发文档已在 theming.md；各端 `copyWith`/CompositionLocal helper 待补。

### C-3 新组件契约进 spec（v0.3.0，`status:"planned"` + validate 容忍未实现）✅
- [x] spec 加 **16 个新组件 / 4 新类**：Contacts(ContactList/Item/Detail/NewFriendRequests/GroupList)、Profile(ProfilePanel/ProfileEditor/SettingsList)、Call(CallView/IncomingCall/CallControls)、General 补(SearchBar/Input/EmptyState)、Layout(AppShell/ResponsiveLayout)。v0.3.0，**共 34 组件/9 类**。
- [x] `validate.mjs` 加 `status`：planned 只校验契约完整、跳过四端符号；stable 校验四端。**node validate.mjs 绿**（18 stable + 16 planned）。
- [x] 生成器/site 展示 **规划中** 橙徽标 + NOTE；34 页全生成，`vitepress build` 绿。

### C-4 新组件各端实现（最大，分期，逐个 build 门禁）
- [x] **Android(Compose) 首批 6**：CallControls/CallView/IncomingCall(音视频通话) + Input/SearchBar/EmptyState → **`compileDebugKotlin` 绿，Android 现 24 组件**。site 加 8 个 token 化 demo（含 CallView 手机框在通话 UI、ContactList A-Z 索引、ProfilePanel、Incoming），Claude_Preview 实测 CallView/ContactList ✓。
- [x] **Android 续 10 ✅**：Contacts(ContactItem/ContactList[A-Z sticky header+侧索引跳转]/ContactDetail/NewFriendRequests/GroupList) + Profile(ProfilePanel/ProfileEditor/SettingsList) + Layout(AppShell/ResponsiveLayout) + 模型(Contact/FriendRequest/GroupSummary/UserProfile/SettingsSection/NavItem)。**`compileDebugKotlin` + `testDebugUnitTest` 绿。Android 现全 34 组件（16 新全落地）**。踩坑：`item`/`weight` 是 Lazy/Row scope 成员不可 import。
- [x] **Vue 首批 8/16 ✅**（vue-im-ui）：General(FlareSearchBar/FlareInput/FlareEmptyState) + Contacts(FlareContactItem/FlareContactList[A-Z sticky+侧索引]/FlareContactDetail/FlareNewFriendRequests/FlareGroupList) + 契约 `directory.ts`(FlareContact/FriendRequest/GroupSummary/UserProfile/SettingsSection/NavItem)。轻依赖(HTML+token var，复用 FlareAvatar)。**vue-tsc 0 err**。
- [x] **Vue 续 8 ✅**：Profile(FlareProfilePanel/ProfileEditor/SettingsList)、Call(FlareCallView[video slot]/IncomingCall/CallControls)、Layout(FlareAppShell/FlareResponsiveLayout)。**Vue 现全 34 组件（16 新全落地）+ FlareThemeProvider，vue-tsc 0 err**。
- [x] **iOS 新 16 ✅**：General(SearchBarView/InputView/EmptyStateView) + Contacts(ContactItemView/ContactListView[ScrollViewReader+侧索引 scrollTo]/ContactDetailView/NewFriendRequestsView/GroupListView) + Profile(ProfilePanelView/ProfileEditorView/SettingsListView) + Call(CallControlsView/CallView[video:AnyView 注入]/IncomingCallView) + Layout(AppShellView/ResponsiveLayoutView，GeometryReader 断点) + 模型 DirectoryModels。**swift build + test 13/13**。**iOS 现全 34**。踩坑：`onChange(of:)` 两参版需 macOS14，用单参版。
- [x] **Flutter 新 16 ✅**：General(FlareSearchBar/FlareInput/FlareEmptyState) + Contacts(FlareContactItem/FlareContactList[A-Z + GlobalKey+Scrollable.ensureVisible 侧索引]/FlareContactDetail/FlareNewFriendRequests/FlareGroupList) + Profile(FlareProfilePanel/FlareProfileEditor/FlareSettingsList[switch expr on kind]) + Call(FlareCallControls[FlareCallMode]/FlareCallView[videoContent 注入/FlareCallState]/FlareIncomingCall) + Layout(FlareAppShell[NavigationRail/NavigationBar]/FlareResponsiveLayout[LayoutBuilder 三/双/单栏]) + 模型 directory_data。**analyze 0 + test 55/55**。**Flutter 现全 34**。
- [x] **planned→stable ✅**：16 新组件去 `status:"planned"` → validate **34 组件 × 四端符号全绿**（34 stable / 0 planned）。site 重生成（去规划中徽标）+ build 绿。**四端全部 34 组件齐 🎉**

### C-5 自适应（手机/平板/PC）——vue-im-ui + android-im-ui
- [x] **Android ✅**：`AppShell`（≥600dp 侧边 NavigationRail / 否则底部 NavigationBar）+ `ResponsiveLayout`（≥1100dp 三栏 list+chat+detail / ≥680dp 双栏 / 否则单栏按 activePane 切）——用 `BoxWithConstraints` 断点，编译通过。
- [x] **Vue ✅**：`FlareResponsiveLayout`（pc 三栏 list+chat+detail / ipad 双栏 / h5 单栏按 activePane + 返回条，复用断点常量 + resize 监听 reactive width）+ `FlareAppShell`（>599 侧边 rail / 否则底部 bar，带角标）。vue-tsc 0 err。

### C-6 site 每组件详细使用示例 ✅
- [x] 生成器 `usage()` 改为**按 props/events 自动生成四端真实示例**（覆盖全 34），并**从 vue-im-ui barrel 解析真实 Vue 公开导出名**（`MessageList`→`FlareMessageList`、`VideoPlayerModal`→`FlareVideoPreview`），修正 import/tag/各端实现网格。
- [x] 新增 `site/scripts/examples.mjs` 策展多场景示例（title+说明+四端 code-group），为 10 个旗舰组件（MessageList/Composer/ConversationList/ContactList/CallView/ProfilePanel/ResponsiveLayout/Input/Avatar/MessageContentView）补"示例"节；生成器 `extraExamples()` 渲染。`vitepress build` 绿，Claude_Preview 实测 MessageList/ContactList 用法+示例 ✓。

## Notes(Phase C)
- validate 已把错误串里 "compose-im-ui" 文案留旧（低优先，纯提示文案）。
- theme.js 是纯 ESM 运行时（无需 build），site 直接相对 import `../../../../tokens/theme.js`（build 已过）。
- 新组件走 `status:"planned"` 避免 validate 因未实现而红；实现一端标一端。

## Steps

### Track A — 补齐原生组件库

#### A-1 iOS `FlareIMUI` (SwiftUI)
- [x] **tokens Swift 生成器**（+ 顺带 Compose 生成器）：`build.mjs` emit `ios-im-ui/…/FlareTokens.swift`（`FlareColors` struct light/dark + `.of(ColorScheme)`；`FlareSizes` enum CGFloat）与 `android-im-ui/…/FlareTokens.kt`。30 色×2 + 27 尺寸。
- [x] **SwiftPM 包 scaffold**：`ios-im-ui/Package.swift`（FlareIMUI；iOS16 **+ macOS13** 便于 host 验证）
- [x] **General 3**：AvatarView/TimeStampView/MessageStatusView → **`swift build` 过 + `swift test` 5/5**（初版 smoke：initials/seed/token/尺寸/构造）
- [x] **Conversation 4**：ConversationRowView/ConversationListView(List 原生虚拟化)/ConversationDetailsView/StartConversationView + 模型 ConversationRowData/ConversationSummary/ContactOption → **swift build + test 7/7**
- [x] **Message 5**：MessageBubbleView/MessageListView(LazyVStack 惰性)/MessageContentView(+注册表 `FlareContentRegistry`)/ChatHeaderView/PinnedMessageBarView + 模型 MessageContent/MessageData/PinnedMessage → **swift build 过**
- [x] **Composer 3**：ComposerView/RichMarkdownInputView/MessageActionSheetView
- [x] **Media 3**：ImagePreviewView/VideoPlayerView(host 注入 `player: AnyView?`)/MarkdownPreviewView(AttributedString 内联 + 手写块解析)
- [x] smoke 测试 → **`swift test` 12/12**；README 补全。**iOS 18/18 完成 ✅**

#### A-2 Android `flare-im-ui-compose`
- [x] **tokens Compose 生成器**：`build.mjs` emit `android-im-ui/…/FlareTokens.kt`（`FlareColors` data class + `flareColors()`；`FlareSizes` object Dp；font token 用处 `.value.sp`）
- [x] **gradle library module scaffold**：独立项目 `flare-im-design/android-im-ui`（settings/build.gradle.kts AGP8.7.3+Kotlin2.2.20+compose plugin+BOM2024.12.01；**gradle.properties `android.useAndroidX=true`**=踩坑点；复用 android app gradle8.14 wrapper + JDK17 `/opt/homebrew/opt/openjdk@17`；namespace com.flare.im.ui）
- [x] **General 3**：Avatar(image slot 注入)/TimeStamp/MessageStatus → **`./gradlew compileDebugKotlin` BUILD SUCCESSFUL**
- [x] Conversation 4 → Message 5 → Composer 3 → Media 3（@Composable，media 用占位/注入 slot，无 Coil 依赖）
- [x] 每批 `compileDebugKotlin` 门禁通过；**`testDebugUnitTest` 绿**；README 全。**Android 18/18 完成 ✅**（踩坑：`android.useAndroidX=true`、`Modifier.weight` 不可 import、`continue` 不能在 `.also{}` lambda、font token 用 `.value.sp`）

#### A-3 收口 ✅
- [x] spec `validate.mjs` 扩 iOS(`struct/enum XxxView`) + Compose(`fun Xxx`) 符号校验 → **四端全绿**（18 组件 × Vue/Flutter/iOS/Compose 符号均存在）
- [x] 各端 README 全；主 PLAN 链接本文件；记忆更新（下步回填 Phase 4 完成）

### Track B — Ant-Design 式官网 `flare-im-design/site` ✅ 完成
- [x] **B-1 VitePress scaffold**：`site/`（package.json vitepress^1.5+vue；`.vitepress/config.mts` **侧边栏/nav 从 components.json 自动生成**）；`vitepress build` 起得来
- [x] **B-2 首页 hero**：home layout（紫渐变大标题 + tagline + 3 CTA + 6 特性卡：18组件/tokens/core行为/性能/内容注册表/契约真源）
- [x] **B-3 设计页** `guide/tokens.md`：色板/气泡/背景文本/圆角 **直接用真实生成的 CSS 变量** `var(--flare-color-*)`；亮/暗切换（token 主题随 VitePress 明暗同步，见 theme/index.ts MutationObserver 打 `data-flare-theme`）
- [x] **B-4 组件文档框架**：生成器 `scripts/gen-components.mjs`（读 components.json → 每页：category tag + summary + dataSource + 预览 Demo + Props 表 + States/Events + **四端实现网格** + **四端用法 code-group tab**）
- [x] **B-5 18 组件页**：全部生成；**10 个带 token 化 live demo**（Avatar/TimeStamp/MessageStatus/ConversationRow/List/MessageBubble/ChatHeader/PinnedBar/Composer/MarkdownPreview，Composer/Pinned 可交互）
- [x] **B-6 入门页** `guide/getting-started.md`（四端安装 + 最小气泡示例）+ `guide/spec.md`（契约结构 + 内容注册表 + 防漂移校验）
- [x] **B-7** `vitepress build` **成功（2.35s，0 死链）**；Claude_Preview 实测首页/组件页(live demo)/tokens 页/**暗色**全 OK
- [ ] **B-8**（收尾）site README；（实发 GH Pages/静态托管留给用户 `npm run build` → `.vitepress/dist`）

## Notes / open questions
- Swift 颜色：`rgba` 有小数 alpha → SwiftUI `Color(.sRGB, red:g:b:opacity:)`（非 const 限制，Swift 无所谓）。Compose 颜色：`Color(0xAARRGGBB)`（同 Dart 转换，可复用 build.mjs 里的 hx 逻辑）。
- iOS 测试若无 ViewInspector 依赖：退化为「模型/纯函数断言 + View 可构造」冒烟，避免引第三方。
- Compose 单元测试要 Robolectric/compose-test，重；先保证 `compileReleaseKotlin` 通过（等价 Flutter 的 analyze 门禁），单测视情况加。
- 官网 live demo：`flare-core-vue-im-ui` 需要 naive-ui/vue-router peer；VitePress 里装齐即可。个别组件依赖 SDK 运行时的（MessageList/Composer 真实收发）在文档里用假数据/桩，纯展示态即可。
- 体量大、跨 4 语言 + 站点：**每步 build/test 门禁**，逐步提交，不一把梭。
- 主 PLAN.md 的 Phase 4/官网条目在收口步回填。
