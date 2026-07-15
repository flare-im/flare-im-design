# 对标飞书/主流 IM —— 补齐缺失高价值组件

## 立意（frontend-design）
延续「考究的紫」token 体系。对标飞书/微信/Telegram/Slack,补库里缺的**通用 IM 基元**——这些是每个 IM 都有、但当前库没有的小而高频组件。每个:走 token、SFC scoped、进 barrel、配 demo + doc、i18n、浏览器验证。

## Status: 首批 5 个新组件 + 6 个组件四端拉平（vue/flutter/ios/android 全编译）+ 文档补齐

## 四端产出（本轮:继续优化完善补充更多更齐全组件生产 vue\flutter\ios\android 并完善文档）
把新建的 6 个组件(GroupCallView + 上批 5 个 ProfileCard/GroupMemberGrid/TypingIndicator/UnreadDivider/ScrollToLatest)从 Vue-only 移植到三套原生实现,达成四端奇偶(parity):
- **模型层**:三端契约同步加字段——`FlareContact`/`Contact` 补 remark/region/phone/tags;新增 `FlareCallParticipant`/`CallParticipant`(id/name/avatar/muted/cameraOff/speaking/isSelf)。
  - flutter `models/directory_data.dart`、ios `Models/DirectoryModels.swift`、android `ContactModels.kt`。
- **Flutter**(6 widget,`flutter analyze`=No issues found):flare_typing_indicator(StatefulWidget+AnimationController 跳点)、flare_unread_divider、flare_scroll_to_latest、flare_profile_card、flare_group_member_grid、flare_group_call_view(参与者网格,复用 FlareCallControls);exports 进 `flare_im_ui.dart`。
- **iOS**(`Components/ExtraViews.swift`,`swift build`=Build complete):6 个 SwiftUI View——TypingIndicatorView(@State + .repeatForever)、UnreadDividerView、ScrollToLatestView、ProfileCardView、GroupMemberGridView(LazyVGrid)、GroupCallView(LazyVGrid + 复用 CallControlsView)。
- **Android**(`ExtraComponents.kt`,`compileReleaseKotlin`=BUILD SUCCESSFUL):6 composable——TypingIndicator(rememberInfiniteTransition,需 `import androidx.compose.runtime.getValue`)、UnreadDivider、ScrollToLatest、ProfileCard、GroupMemberGrid(LazyVerticalGrid)、GroupCallView。
- **spec**:6 组件 `platforms` 补全四端 symbol(Vue `Flare<Name>` / Flutter `Flare<Name>` / iOS `<Name>View` / Compose `<Name>`,GroupCallView 例外 iOS/Compose 均为 `GroupCallView`)。
- **文档**:10 个 doc 页(5 组件×中英)补「各端实现」平台网格;typing-indicator 页浏览器验证=4 变体动画 + 4 端平台卡片正常渲染。



## inventory agent 校正（避免误报"已有"）
已有别重做:正在输入(头部 ChatHeaderIdentity)、日期分割线(TimeStamp+MessageList)、新消息浮标(MessageList 内置)、引用展示(QuoteView)、语音条(AudioView)、图片九宫格+查看器、已读双勾(1:1)、投票/任务/日程/公告/名片/小程序卡片。
**真缺口(agent 排序)**:①迷你资料卡 ②群成员网格/群设置 ③未读分割线 ④群已读回执 ⑤@选择器面板 ⑥多选批量条(App 有未导出) ⑦reaction 汇总(有但简陋) ⑧搜索结果 ⑨骨架屏 ⑩快捷短语。

## 已实现（5 个,全部 export + demo + 注册 + 中英 doc + spec 条目 + i18n + 浏览器/DOM 验证）
- **FlareProfileCard**(profile/)—— 迷你资料卡(缺口①):头像+在线态+签名+Flare ID·地区+标签 + 发消息渐变/语音/视频线性图标。**截图验证漂亮**。
- **FlareGroupMemberGrid**(contacts/)—— 群成员网格(缺口②):5 列头像 + 群主(橙)/管理员(灰)角标 + 虚线加成员格 + "N 名成员"。**截图验证漂亮**。
- **FlareTypingIndicator**(messages/)—— 时间线打字气泡 + inline 两 variant;三点跳动;单人/群多人文案(缺口:头部有但无独立组件)。
- **FlareUnreadDivider**(messages/)—— "N 条新消息"分割线(缺口③)。
- **FlareScrollToLatest**(messages/)—— 回底浮标 + 未读徽标(MessageList 内置已有,此为可复用基元)。
- 配套:契约 `FlareContact` 已有 region/tags(前轮加);i18n 新增 `typing/timeline/group` 命名空间(中英);spec 补 6 条(含前轮漏的 GroupCallView)。
- 验证:vue-tsc 净 + **114 kit SFC 全编译 0 失败** + 5 demo 编译 + 14/14 测试。

## 第二批 7 缺口全部落实（2026-07-15,继续把高价值缺口全部落实）
Vue 全流程 + 四端拉平。7 组件:
- **FlareReactionSummary**(messages)—— 表情回应汇总 pill,可点 toggle + 加表情;契约 `FlareReactionGroup`(emoji/count/reactedBySelf/users)。
- **FlareReadReceiptSheet**(messages)—— 群已读回执,FilterTabs 已读/未读 + 头像列表 + EmptyState。
- **FlareMessageBatchToolbar**(messages)—— 从 App message-enhancements 提炼进 kit(自带 `batch.*` i18n,不依赖 App 的 `enhance.*`)。
- **FlareMentionPicker**(composer)—— @可搜索选择器 + @所有人;契约 `FlareMentionCandidate`。
- **FlareQuickPhrases**(composer)—— 快捷短语分组面板;契约 `FlareQuickPhrase`/`FlareQuickPhraseGroup`。
- **FlareSearchResults**(general)—— 搜索结果分组 + 关键词高亮 + 查看全部;契约 `search.ts`(`FlareSearchResultItem/Group/Kind`)。
- **FlareSkeleton**(general)—— 骨架屏 conversation/message/profile/text 4 变体 + shimmer + reduced-motion。
- 验证:vue-tsc 净 + 14/14 测试 + 浏览器逐页(pills/tabs/@所有人/5 键/4 高亮/3 变体/2 tab)+ 重启后侧栏 68 项含全 7 新组件 + 0 console 错误。

## 原生四端拉平（DONE,3 并行 agent + 独立复验全绿）
7 组件全部移植 flutter/ios/android,三端独立编译通过:
- **模型契约**三端同步:ReactionGroup / MentionCandidate / QuickPhrase(+Group) / SearchResultKind+Item+Group(+ enum)。落 flutter `directory_data.dart`、ios `DirectoryModels.swift`、android `ContactModels.kt`。
- **Flutter**:7 个 `flare_*.dart`(reaction_summary/read_receipt_sheet/message_batch_toolbar/mention_picker/quick_phrases/search_results/skeleton)+ barrel;`flutter analyze` = No issues found(修 `BlendMode.srcATop` 大小写)。
- **iOS**:新文件 `Components/ExtraViews2.swift` 7 View(ReactionSummaryView/ReadReceiptSheetView/MessageBatchToolbarView/MentionPickerView/QuickPhrasesView/SearchResultsView/SkeletonView + SkeletonVariant);`swift build` = Build complete。
- **Android**:新文件 `ExtraComponents2.kt` 7 composable + SkeletonVariant + 私有 helper;`compileReleaseKotlin`(JDK17)= BUILD SUCCESSFUL(用 `Icons.AutoMirrored.Outlined.LibraryBooks` 清 deprecation)。
- **spec** `platforms` 建组件时已写全四端 symbol(Vue `Flare<Name>` / Flutter `Flare<Name>` / iOS `<Name>View` / Compose `<Name>`),与 agent 实际命名一致。
- 独立复验(非仅信 agent):android BUILD SUCCESSFUL、flutter No issues found、ios build complete。

## 全部完成 ✅
第二批 7 缺口 = Vue 全流程 + 四端拉平 + 中英文档,全绿。库现有 66 组件(spec),四端奇偶。

## 第三批 5 组件(2026-07-15,"继续处理并完善并丰富组件")
盘点 agent 交叉对标飞书/微信/Telegram/Slack(108 kit SFC / 66 spec),产出真缺口。本轮落地 5 个 MUST-HAVE:
- **FlareForwardPicker**(conversation)—— 转发选择器:搜索 + 多选(圆形勾选)+ 底部计数发送;从 App `ForwardModal.vue` 提炼(App 版耦合 naive NModal/SDK,kit 版纯展示,契约 `FlareForwardTarget`)。**浏览器实测选择交互「已选 2 个」**。
- **FlareToast**(general)—— 轻提示:info/success/error/warning/loading 五态,图标按态着色,loading 旋转,可带 action;导出 `FlareToastVariant`。
- **FlareCallDock**(call)—— 通话浮窗:最小化悬浮胶囊,深色渐变 + 头像绿呼吸环 + 时长 + 静音/挂断(红旋转)/展开;配对 CallView 的 minimize emit。**截图验证漂亮**。
- **FlareAnnouncementBanner**(messages)—— 群公告横幅:喇叭 tile + 作者 + 长文一行收起可展开 + 可关闭。
- **FlareDatePill**(messages)—— 悬浮日期:时间线分日胶囊(backdrop-blur),floating 吸顶。
- Vue 验证:vue-tsc 净(修 FlareCallMode 是 audio|video 非 voice)+ 14/14 + 5 页浏览器 + 侧栏 5 新项 + 0 错误。spec 71 组件。
- 原生四端拉平 **DONE**:Flutter(`flare_*.dart` 5,analyze 净)、iOS(`ExtraViews3.swift` 5 View,swift build 净)、Android(`ExtraComponents3.kt` 5 composable,compileReleaseKotlin 净)。模型三端加 ForwardTarget。**Android agent 中途撞 400 content-filter(误报,非代码问题)→ 我手写 ExtraComponents3.kt 补齐并编译过**。三端独立复验全绿。库现 71 组件全四端奇偶。

## 第四批 4 组件(2026-07-15,"继续")—— A 类新组件继续清
- **FlareRedPacketCard**(messages)—— 红包:红金渐变 + 金印 + 领取态(领后显金额),浏览器实测点击开启「已领取 · ¥8.88」。
- **FlareSlashCommandMenu**(composer)—— /指令菜单:命令(等宽)+ 用法 hint + 说明,可过滤;契约 `FlareSlashCommand`。
- **FlareTranslationView**(messages)—— 内联翻译:译文 + 署名 + 展开原文 + 翻译中态,实测 toggle 展开原文。
- **FlareQRCard**(profile)—— 二维码名片:头像+名+QR 框;宿主传 qrImageUrl 显图,缺省画确定性装饰点阵(非可扫,种子取名字 charcode)。**截图验证漂亮**。
- **坑**:config.mts 的 slug 是 `name.replace(/([a-z0-9])([A-Z])/g,'$1-$2').toLowerCase()` —— `QRCard`→`qrcard`(无连字符,无 lowercase-before-uppercase 边界),我先建成 `qr-card.md` 侧栏 404,改名 `qrcard.md` 修好。`FlareCallMode`=audio|video(批次2已记)。
- Vue:vue-tsc 净 + 14/14 + 4 页浏览器(红包开启/翻译展开交互)+ 侧栏 4 新项。spec 75 组件。
- 原生四端拉平 **DONE**:Flutter/iOS agent + **Android 我手写 ExtraComponents4.kt**(避开上次 content-filter 误报;修 IntrinsicSize/fillMaxHeight 漏 import;QR 用 coil AsyncImage + Canvas 画装饰矩阵)。三端独立复验全绿。**库现 75 组件全四端奇偶。**

## 第五批 4 组件(2026-07-15,"继续下一步")—— B 类完善 + A 类收尾
- **FlareImageGrid**(messages)—— 自适应图片九宫格:cols n≤1→1/n=4→2(2×2)/n≤3→n/否则 3,单图放大,超 max 末格 +N。**实测 1/3/2/3 列 + 9 格 +3**,把「九宫格自适应」做成干净独立基元(不动纠缠的 ImageGroupView,零回归)。契约 `FlareGridImage`。
- **FlareVoiceRecordingBar**(composer)—— 语音录制条:红点闪 + 计时 + 28 波形 + 取消/发送,松开取消态(实测 28 bar + 「松开取消」)。
- **FlarePollComposer**(composer)—— 投票创建器:问题 + 增删选项 + 多选 + 发起(实测加选项 2→3、空态禁用)。
- **FlareChatWallpaperPicker**(conversation)—— 聊天背景:4 列色板(纯色/渐变/图)+ 选中态(实测选中态迁移)。契约 `FlareWallpaperOption`。
- Vue:vue-tsc 净 + 14/14 + 4 页浏览器交互 + 17 图全 load + 侧栏 4 新项 + 0 错误。spec **79 组件**。
- 原生四端拉平 **DONE**:Flutter/iOS agent + **Android 我手写 ExtraComponents5.kt**(hex→Color 解析、Canvas 无需、coil AsyncImage、修 Check import)。三端独立复验全绿。**库现 79 组件全四端奇偶。**

## 第六批 3 富组件深化(2026-07-15,"继续深化")—— 语音/表情/贴纸
不改纠缠在消息分发树里的旧展示态,而是建**独立富基元**(零回归),对齐飞书级:
- **FlareVoicePlayer**(messages)—— 真播放器:播放/暂停 + **可点选进度波形**(32 bar 填充到 progress)+ 计时(播放显 elapsed)+ 倍速 pill + 转文字展开 + 未播红点 + outbound。实测 32bar/13 填充/1.5×/未播点/outbound。
- **FlareEmojiPicker**(composer)—— 完整表情选择器:搜索(跨类去重)+ 分类导航(最近 tab + 各类符号)+ 6 档肤色(append modifier)。实测搜索/导航/6 肤色。
- **FlareStickerPanel**(composer)—— 分类贴纸面板:包导航(最近 + 封面)+ 4 列网格。实测包切换。契约 `FlareEmojiCategory/FlareStickerItem/FlareStickerPack`。
- Vue:vue-tsc 净(修 railPacks 联合类型标注 `FlareStickerPack[]`)+ 14/14 + 3 页浏览器交互 + 侧栏 3 新项 + 0 错误。spec **82 组件**。
- 原生四端拉平 **DONE**:Flutter/iOS agent + **Android 我手写 ExtraComponents6.kt**(VoicePlayer 用 `detectTapGestures` size.width 做 seek、EmojiPicker 8 列分块 + 肤色、修 `Icons.Outlined.Description`)。三端独立复验全绿(Flutter 含 example)。
- **⚠️ Flutter 命名碰撞(已解)**:emoji_sticker 目录的 manifest 版 `FlareStickerPack` 与新契约同名;agent 用 `export ... hide FlareStickerPack` 让新的跨端契约版占 barrel,旧目录版仅内部直接 import 可达;example 未用旧版、analyze 净、pre-release 无兼容负担 → 接受。**库现 82 组件全四端奇偶。**

## 完善文档站(2026-07-15,"继续并完善网站")
组件总览页与首页计数**已烂**(硬编码 53 / 51,漏掉后加的 29 个)。做成**自更新**:
- 新建 `site/.vitepress/theme/demos/ComponentGallery.vue` —— 直接 `import spec from "../../../../spec/components.json"`,按 categories 分组渲染(统计卡 + 分类计数 chip + 卡片[名→链接/摘要/四端徽标]),`useRoute().path` 判 /en/ 做中英 + categoryLabels 本地化,slug 用与 config.mts 同一正则 → 链接永远对(QRCard→qrcard 等)。注册进 theme。
- `components/index.md` + `en/components/index.md` 正文换成 `<ComponentGallery />`,删硬编码列表 → 永不再烂。
- 首页 `index.md` + `en/index.md` 计数 51→82(feature 标题 + flare-stats)。
- 验证:浏览器 82 卡/9 组/统计 82·9·4、中英 label 与 /en/ 链接、卡片点击导航达、0 console 错误;**`vitepress build` 生产构建通过**(JSON import + useRoute SSR 均安全)。

## 修复发现的问题(2026-07-15,"修复发现的问题")
自动化排查(spec name→slug vs doc 文件 / 跨端类名重复)找出 2 个真问题,已修:
- **GroupCallView 无独立 doc 页**:spec 有 GroupCallView 条目 → 侧栏 + 新总览 gallery 生成 `/components/group-call-view` 链接但**无文件 → 404**(GroupCallView 之前只嵌在 call-view.md 里)。修:新建 `group-call-view.md`(中英,含 GroupCallViewDemo + 平台网格),把 call-view.md 里重复的嵌入段改成指向它的 `[!TIP]` 交叉链接(去重)。浏览器实测 gallery 卡片 + 侧栏均达、call-view 仍渲染、`vitepress build` 无 dead-link。
- **Flutter `FlareStickerPack` 命名碰撞(彻底修)**:catalog manifest 版重命名 `FlareStickerManifestPack` + 删 barrel `hide` → 只剩一个 `FlareStickerPack`=跨端契约。`flutter analyze` 净、零重复类。
- 排查确认:iOS/Android 的 QuickPhrase/SlashCommand"重复"是 grep 前缀假阳性(QuickPhrase 匹配到 QuickPhraseGroup),非真碰撞;全 82 组件 ×2 doc 页齐全、无孤儿 doc。

## 补齐 29 新组件的 API 文档(2026-07-15,"继续处理")—— spec 驱动
排查发现:53 个老页有手写 Props/Events 表,而这几轮新增的 **29 个组件 doc 页只有预览+平台网格**(spec 的 props/events 数组也空)。补齐(走单一源,不硬编码):
- 建 `site/.vitepress/theme/demos/ComponentApi.vue` —— 按 `name` prop 从 spec 找条目,渲染 **Props 表(名/类型/必填/默认/说明)+ States + Events**,`useRoute` 判 /en/ 做中英表头与描述;无数据的段不渲染。注册进 theme。
- 派 agent 读 29 个 Vue 源(defineProps/withDefaults/defineEmits)产出准确的 props/states/events JSON(type/required/default 严格对源,中英描述取 `/** */` 注释)→ 我校验(VoicePlayer 10 props、Toast variant 默认 "info"、GroupCallView 8 events 均对)→ merge 进 spec 29 条。
- 脚本注入 `<ComponentApi name="X" />` 到 58 页(29×2,预览与平台网格之间,幂等)。
- 验证:浏览器 VoicePlayer 10 行表 + states(playing/unplayed)+ events(toggle/seek/…)、en 英文表头与描述、Toast 默认值 "info" 显示;`vitepress build` 通过。**教训延续:文档数据(计数/清单/props)一律 spec 驱动。** 老 53 页仍是手写表(可用,未来可迁 ComponentApi,非阻塞)。

### 盘点剩余缺口(基本清完,下一轮候选)
把老 53 页手写 Props 表迁到 `<ComponentApi>`(统一机制);Conversation 行滑动操作(手势,分端差异大);A 类:消息编辑历史、群管理面板。

## 旧 Status 存档

## 预判高价值缺口（待 agent 证实"确缺"）
1. **正在输入指示器** `FlareTypingIndicator` —— "对方正在输入…" + 三点跳动;群里 "A、B 正在输入"。极高频。
2. **迷你资料卡** `FlareProfileCard` —— 点头像弹出名片(头像/名/部门/签名/Flare ID + 发消息/语音/视频)。飞书遍地都是。
3. **未读消息分割线** `FlareUnreadDivider` —— 消息列表 "N 条新消息 ——" 分隔。
4. **新消息浮标** `FlareScrollToLatest` —— "↓ N 条新消息" 悬浮回底。
5. **表情回应汇总** `FlareReactionSummary` —— 气泡下 👍3 ❤️2 pill(点看谁)。
6. （可能）骨架屏 / 搜索结果 / 群成员网格 / 多选批量条 / 日期分割线。

## Steps
- [ ] 收 inventory 报告,定"确缺"清单(排除"已有但简陋")。
- [ ] 按价值实现 3-5 个:组件 + barrel + demo + 注册 + doc + i18n。
- [ ] 浏览器逐一验证 + vue-tsc + 全量 SFC 编译 + 测试。
- [ ] 更新计划与记忆。

## Notes
- 复用基元:FlareAvatar、EmptyState、tokens(--flare-color-*/--flare-size-*/--flare-transition-*)、--im-brand-gradient。
- 分端预览机制(ResponsivePreview + embed 帧)已就绪,如新组件分端可复用。
