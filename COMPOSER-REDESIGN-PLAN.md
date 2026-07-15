# Composer 重设计 —— 对齐飞书、PC/移动自适应、可配置、组件化

## Goal（可检查的完成定义）
flare-im-design 的 Composer(Vue kit 主组件 `EnhancedComposer.vue` = `FlareComposer`) 做到：
1. **加号(+)菜单可自定义** —— 主组件暴露 `attachActions` prop，租户传自己的动作列表；不传则用现有默认。
2. **飞书式展开/收起** —— 展开态有明确的头部(标题+收起键)与底部条，不再只是"输入框加高"；PC/移动都成立。
3. **PC / 移动自适应** —— 桌面紧凑单行 + 右侧工具栏；移动堆叠 + 触摸友好；修掉桌面端 hint 与按钮重叠的 bug。
4. **富文本 / 表情 / 贴纸 组件化** —— 富文本核心 `ComposerRichMarkdownInput` 导出为 `FlareComposerRichInput`；表情+贴纸面板已导出，补一个 `FlareStickerPicker` 薄封装(纯贴纸)。
5. demo 站 composer 文档更新：记 `attachActions`、展开/收起、可复用子组件，并加"自定义加号菜单"示例。
6. 浏览器实测 PC + 移动两个视口，截图为证。

## Constraints & decisions
- 一律**新增可选参数 + 现有行为为默认** → 零破坏(5 个 example app + demo 站)。
- **不重写** 2000 行成熟 CSS，做外科式增强；改 `tokens.json` 源而非手改生成物。
- Vue 主组件是本轮深做对象(覆盖 web + uni + tauri 的"PC/app 自适应")；原生三端的 expand 作为后续，先在文档/spec 记设计。
- Vue 走它自带 i18n(`t()`)，不塞 label props。
- 验证只能看 Vue(demo 站已在 5199 跑起来)。

## Status: DONE（Vue kit 深做完成并浏览器验证；原生三端 expand 列为后续）
Current focus: —

## Steps
- [x] 摸清四端 Composer 现状 + demo 站 + tokens（探查 agent 报告）
- [x] 启动 demo 站，PC/移动截图基线（发现桌面 hint 重叠 bug）
- [x] **A. 可配置加号菜单** —— `EnhancedComposer` 加 `attachActions?: FlareComposerAttachAction[]` + 导出 `FlareComposerAttachAction/ActionTone/MentionCandidate` 类型；`moreActions` = 传入 || 默认。验证：自定义 demo 菜单只渲染租户 4 项（图片/文件/位置/红包）。
- [x] B. 飞书式展开：绝对定位头部（标题 + 「▾ 收起」胶囊 + 分隔线），field 留 46px 顶 padding、不碰既有 grid；移除装饰 `::after`；height 320→440。PC + 移动都验证。
- [x] C. 修桌面 hint 重叠：桌面仅多行/展开显示 hint 且移左下（`:has()`）；紧凑单行不再撞右侧工具栏。
- [x] D. 组件化导出：`FlareComposerRichInput`(富文本核心) + `FlareStickerPicker`(给面板加对称 `stickerOnly` prop) + 类型；更新 barrel。
- [x] E. 浏览器实测 PC + 移动（默认 / 展开 / 自定义菜单 / 移动堆叠），全过。
- [x] F. 更新 composer.md + 注册 `ComposerCustomMenuDemo`。
- [x] G. vue-tsc 净 + 108 SFC 全量编译 0 失败 + 14/14 测试。

## 追加：预览内嵌 PC/App 切换（可交互）
诉求：组件预览里能自由切换 PC / App 两种样式并各自展示，且可交互。
难点：composer 响应式是 `@media(min-width:900px)`（**视口**驱动），桌面视口下压窄容器不会变移动样式。
方案（零改 CSS）：用 **iframe** —— iframe 有自己的视口宽度，宽 iframe→桌面样式、窄(390)→移动样式。
- `site/.vitepress/theme/demos/ComposerChatFrame.vue`：真实可交互聊天窗（kit ChatHeader + MessageList + 接线的 Composer）。打字发送→真气泡；表情→`[key]` 内联进下一条；贴纸→真实贴纸气泡（`content.sticker.{packageId,stickerId,url}`，StickerView 消费）；`+`→租户菜单。
- `site/embed/composer-frame.md`：`layout:false` 全屏铺满页，`FlareUiProvider` 包 ChatFrame（frame 用 `height:100dvh` 撑满 iframe）。
- `site/.vitepress/theme/demos/ComposerResponsivePreview.vue`：PC/App 分段开关 + iframe；PC=720 窗口卡片、App=390 手机壳。composer.md 预览换成它。
- 均注册进 `theme/index.ts`。
验证：PC 预览=桌面 composer（右侧工具栏），打字→回车/点发送→新气泡上屏；App 预览 iframe innerWidth 370 → `.composer-field` 变 `flex column`（移动堆叠）；移动视口直开内嵌页=完整移动聊天 App。无 console 错误。
注意坑：**先建 .vue 文件再在 index.ts 引用**（我反了，短暂 500；建好即恢复）。

## 追加：App 版式微调（用户反馈）
PC 单行样式为基准（保持不变）。App(移动)两处改动，均只影响 base 层、PC 由 `@media(min-width:900px)` 覆盖不受影响：
1. **展开(⤢)挪进上面的输入框**：模板在 `.composer-input-row` 内加 `.composer-field-expand`（尾随输入、跟随行对齐：单行居中/多行靠上）；base 隐藏工具栏的 `.composer-expand` 并把工具栏 grid 8→7 槽；`@media(min-width:900px)` 里反向覆盖（field-expand `display:none`、toolbar expand `display:inline-flex`）；`.composer--input-expanded` 时 field-expand 隐藏（头部收起接管）。
2. **收紧间距**：`.composer` padding `8px→6px`/底 `14→8`、gap `6→4`；`.composer-field` gap `8→4`（离工具栏更近）；工具栏 min-height `44→40`、padding `4→2`。
验证：移动 innerWidth 370 → field-expand `flex`、toolbar-expand `none`、7 图标、点 field-expand 进大编辑窗（头部收起）；PC innerWidth 1280 → field-expand `none`、toolbar-expand `flex`、8 图标单行。vue-tsc 净 + SFC 编译 + 14/14。

## 追加：三处修复（用户反馈）
1. **PC 预览显示成 App 样式** —— 根因:composer 桌面布局 `@media(min-width:900px)` 视口触发,PC 卡片 iframe 只有 ~680px(文档列 <900)→ 仍移动样式。修:`ComposerResponsivePreview.vue` PC 用**逻辑宽 1024 的 iframe + `transform: scale`**(ResizeObserver 动态算比例)缩放适配 → iframe 视口 1024≥900 触发桌面单行。验证:iframe innerWidth 1024、`.composer-field` display `block`、toolbar-expand 显示、field-expand 隐藏。
2. **表情面板位置(PC 上/App 下)** —— `ComposerChatFrame.vue` 用 flex `order` 分流:默认(PC)panel order1 在 composer(order2)上方;`@media(max-width:899px)`(App)panel order3 到 composer 下方。实测 PC 面板在输入框上、App 在下。
3. **消息操作组件 PC/App 交互** —— 分析:行为**本已实现并按端分流**(`MessageBubbleHoverToolbar`=PC 悬停 3 键[表情反应/回复/更多],更多→dropdown;`MessageContextMenuSheet`=移动长按 bottom sheet;由 `useMessageMenuInteraction` 的 profile 分流)。真问题=**doc/demo 错位**:`MessageActionSheetDemo` 展示的是 composer 的"建消息"面板(File/Video/Location…,emit build),而非消息操作。修:
   - `MessageActionSheetDemo.vue` 改渲染**真实 `FlareMessageBubble`**(桌面悬停出 3 键条)+ 说明"桌面悬停/移动长按"。
   - `MessageBubble.vue` 的 PC 悬停表情源从硬编码 6 个 → 复用 `MESSAGE_QUICK_REACTIONS`(与移动端 sheet 共用一份,消除不一致)。
   - doc(中/英 message-action-sheet.md + index.md)改为准确描述"按端分流:桌面悬停 3 键 / 移动长按 sheet"。
   - 遗留(未做,记设计):PC 悬停无"更多表情"完整选择器入口;`composer/MessageActionSheet.vue` 命名与"消息操作"冲突(实为 composer 建消息面板,workbench 用);`MessageHoverToolbarConfig` 定义但零消费。
验证:vue-tsc 净 + MessageBubble SFC 编译 + 14/14;无 console 错误;DOM 确证 PC iframe 桌面布局 / 表情面板位置 / `.im-floating-bar` 在 DOM(viewportAttr pc)。

## 追加：全组件分端预览（用户反馈"检查所有组件"）
派 agent 审计 53 个组件文档,判据=有无 `useViewport`/`useAdaptive`/profile 分端逻辑 + 有无设备 `@media`(排除 @media-action 事件属性/prefers-reduced-motion)。
**确定需要分端**(已全部补预览):
- Composer(已做)、MessageActionSheet/消息操作(已做:PC 悬停气泡 + 移动静态 sheet)。
- **AppShell**:侧边导航栏(>599) vs 底部 tab(≤599)。
- **ResponsiveLayout**:三栏(≥900,需 `has-detail`) / 双栏 / 单栏(<600)。
- **StartConversationDialog**:PC 居中弹窗(`FlareStartConversationDialog` n-modal) vs 移动底部 sheet(`FlareStartConversationSheet`,两个独立组件)。
**不需要**(无 @media 无分端逻辑,两端一致):通话(CallView/CallControls/IncomingCall 只有 audio/video prop)、Avatar/Input/SearchBar/FilterTabs/EmptyState/StatusBanner/TimeStamp/MessageStatus、各列表/联系人/资料、所有消息内容视图、各 composer parts、各 modal。**可能但从简**(纯 cosmetic reflow 或 host 施加):MessageList/ChatHeader/ImageMessage/VoteMessage(尺寸微调)、ConversationRow(hover 菜单 vs 触摸常显)、ConversationDetails(host 的 drawer 位置)。

机制:把 composer 的 iframe 预览**抽成通用 `ResponsivePreview.vue`**(props: `embed` URL / pcHint / appHint / pc-app 尺寸;PC 用 1024 逻辑宽 iframe + ResizeObserver `transform:scale`,App 用手机壳)。每个分端组件配一个满屏 embed 帧(`site/embed/<c>-frame.md` + `<C>Frame.vue`),都注册进 theme/index.ts。
验证(浏览器逐一实测):AppShell 侧栏/底栏、ResponsiveLayout 三栏/单栏、StartConversation 弹窗/sheet、MessageActionSheet 悬停条/sheet。kit vue-tsc 净 + 7 个新 demo SFC 全编译 + 无 server/console 错误。

## 追加：收口两处真缺口
1. **PC 悬停补完整表情选择器**（闭合最后一处 PC/App 不一致）：`MessageBubbleHoverToolbar.vue` 的表情选择器从 `n-dropdown`(6 固定项) → **`n-popover`:一行快捷表情 + 「更多」展开 `MessageEmojiPickerPanel`**(17 扩展表情,与移动端 sheet 同一套)。实测:popover 开=6 快捷+更多,点更多=17 扩展。
2. **视口兜底**（真健壮性 bug）：`useViewport.ts` / `useAdaptiveMode.ts` 的 `readWidth()` 在挂载瞬态/iframe 未定尺寸时 `window.innerWidth` 读到 **0** → 误判 mobile 并**卡住**直到 resize(demo 站悬停条曾因此不渲染)。改为 `window.innerWidth || document.documentElement.clientWidth || 桌面断点`。实测:新载入即 viewport=pc/desktop、悬停条挂载即渲染。
验证:vue-tsc 净 + hover toolbar SFC 编译 + 14/14。

## 后续（未做，记设计）
- 原生三端 expand + 格式条 + 内置 emoji/贴纸面板：原生已支持可配置 `actions`（比 Vue 早），但都无 expand/格式条/贴纸 picker。三端并行、无法浏览器验证，本轮不做；设计照搬 Vue（展开=大编辑窗 + 头部收起；贴纸=独立 picker）。

## Notes
- 主组件样式在 `design-system/styles/chat/messages.css`(659+ 行 composer 段, ~289 条规则) + `responsive.css`，非 SFC scoped。
- 桌面布局 `@media(min-width:900px)`：`.composer-field` 是圆角面板，toolbar 右侧栏 `--im-composer-toolbar-width:268px`；`.composer--input-expanded .composer-field` 已是 `grid-template-rows:40px 1fr 44px` 的 300-420px 大窗。
- hint bug：`.composer-input-hint` 绝对定位 right:16 bottom:3，紧凑单行桌面态与 +/send 按钮重叠 → 单行态隐藏、仅多行/展开显示。
- 加号默认 12 项在 `EnhancedComposer.vue:164-177`(computed 硬编码)。
- 富文本核心 `ComposerRichMarkdownInput.vue` expose `applyFormat/applyHeadingLevel/focus/insertAtCursor`。
