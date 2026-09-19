# Public API 2.0（2.0.0-rc.1 · P0-3 边界收口，P0-13 复核）

真源：`spec/components.json`（150 个组件 × 四端 symbol）、`spec/public-api-exceptions.json`、`PUBLIC_API.md`。门禁：`node tooling/check-public-api.mjs --strict`（release-check 的 `api-check`）+ `check-public-exports`（四端 symbol 可达）+ `check-package-exports`（9 个入口，无通配）。

## 1. 规则

1. `@flare-im/vue-ui/components` 只导出 catalog 里登记的 Vue symbol；每个 catalog symbol 也必须从这里可达（facade 不得落后于契约）。
2. 非组件导出各归其入口：hooks → `./composables`（含 P0-5 的 `provideFlareVoiceRecorder` / `useVoiceRecorder` / `useFileDrop` / `useMarkdownShortcuts`），纯函数 / 类型 → `./contracts` / `./utils`，图标名表作为 FlareIcon 的伴随导出留在 `./components`（登记在 `companionExports`）。
3. 待合并的公开导出登记在 `pendingMerge`（重复对 id + 目标 + 清零步骤）；`--strict` 下门禁一直红到清零，不允许别名 / deprecated 过渡。
4. 产品代码（工作台外壳、登录页、诊断台）不是 kit API，住在 `flare-im-core-client-sdk/examples/shared/vue-reference`。

## 2. 本轮处置（原 29 个未登记导出）

| 处置 | 导出 | 结果 |
|---|---|---|
| 登记进 catalog | FlareUiProvider（顶替 FlareConfigProvider 成为 ConfigProvider 的 Vue symbol，吸收 size / density / overlayContainer / useFlareConfig）、FlareScreen（Screen，vue+flutter+ios）、FlareBottomSheet（BottomSheet，vue）、FlareFormSheet（FormSheet，vue+ios；iOS FormSheetView 回调 onCancel→onClose 对齐事件 close）、FlareSettingsRow（SettingsRow，四端）、FlareBrandLogo（BrandLogo，四端，此前 Vue 未导出而三端公开） | 6 个新 / 改登记，docs 页 + demo 齐 |
| 内部化（去导出，文件保留） | FlareGlyph、FlareBusinessDetailBlock、FlareTask/Schedule/Vote/Announcement/MiniProgramMessageView、FlareMessageContentRenderer、FlareMessageDoubleCheckIcon | 0 外部消费者；MessageContentView 是唯一分发点 |
| 删除 | FlareContentView（别名）、FlareMessageTimeline（别名，站点 demo 改 FlareMessageList）、FlareStickerPicker.vue（零使用）、FlareThemeProvider.vue（零使用，theming 指南改 FlareUiProvider）、FlareConfigProvider.vue（并入 FlareUiProvider） | 无别名 |
| 迁到示例（产品代码） | FlareAuthScreen → AuthScreen、FlareDiagnosticsConsole → DeveloperConsole、FlareWorkbenchShell → WorkbenchShell（+ workbenchShell.ts、kit-auth.css、kit-workbench-shell.css、品牌图；kit 的 workbench.css 只保留 ConversationDetails 共用规则） | 示例 typecheck / vitest 绿 |
| hooks 移到 `./composables` | provideFlareConfig / useFlareConfig、provideFlareOverlayContainer / useFlareOverlayContainer、provideFlareMessageRenderers / useFlareMessageRenderers | 根入口 `@flare-im/vue-ui` 仍聚合导出 |
| 伴随导出（保留） | flareIcons、flareIconNames、FlareIconName | 登记在 companionExports |
| P0-4 合并（原 pendingMerge） | FlareChatHeader + FlareChatHeaderIdentity → FlareConversationHeader；FlareComposerEmojiStickerPanel → FlareEmojiStickerPicker（登记）；FlareStartConversationSheet → FlareStartConversationDialog（bottomSheet 能力决定呈现）；FlareMessagePreviewModal → 参考 app；FlareMediaComposerPreviewModal → FlareComposerMediaPreview（登记）；FlareConversationListPanel → 参考 app | 7 个全部清零（migration/2.0-rc-to-2.0.md §1b） |

## 3. 依赖契约

- `@flare-im/vue-ui` 的 peer `vue` 从 `^3.5.0` 收紧为 `^3.5.42`：kit 的图标运行时 `@lucide/vue` 1.44 要求 `vue ^3.5.42`，更低版本在渲染任一带图标的组件时抛 `useLucideProps(...) is undefined`。web / tauri 示例已升到 3.5.42。

## 4. 现状（2026-09-14 复核，参考应用 Round 4 之后）

- `./components`：150 个组件导出 = 150 个 catalog symbol + 0 个 pendingMerge，`api-check --strict` 绿；2 个伴随导出（`flareIcons` / `flareIconNames` / `FlareIconName` 中的值与类型）。
- `check-public-exports`：593 个平台组件表面可达；`check-doc-code`：686 个 Vue 公开导出作为文档真源（2026-09-14 补上 `safeExternalUrl` 等 3 个此前漏导出的 `./contracts` 符号）。
- 原生包的非 catalog 宿主 API（Flutter sliver 列表 / `FlareDialog` / `ComposerInlineTextField`，Compose `FlarePlatformProvider`）登记在 `nativeCompanions`，`check:dead-components` 视其为存活。
- `spec/duplication-register.json` 20 条全部关闭（P0-8 收掉最后的 D15 / D17 / N2），`check:duplicate-components --strict` 绿。

## 5. P0-3 之后新增的公开面

收口之后又加了东西。Round 4 的 `ActionMenu` 是唯一的新组件，其余是已有组件的 props / 插槽 / 事件，或 `./contracts` / `./composables` / `./utils` 下的函数与类型：

| 新增 | 入口 | 来自 |
|---|---|---|
| `provideFlareVoiceRecorder` / `useVoiceRecorder` / `useFileDrop` / `useMarkdownShortcuts` | `./composables` | P0-5 Composer 拆分 |
| `paneEmptyActionVisible`、`WorkspacePaneState.description` | `./contracts` | P0-8 四端状态 |
| `FLARE_BREAKPOINT_TABLET_MIN`（`FLARE_BREAKPOINT_IPAD_MAX` 由 1023 改为 899） | `./contracts` | P0-8 断点合一 |
| `safeExternalUrl` / `isSafeExternalUrl` / `FLARE_SAFE_URL_PROTOCOLS` | `./contracts` | P0-11 安全边界 |
| `FlareIcon.ariaLabel`、`FlareTextarea` 的 id / name / aria / invalid | 组件 props | P0-7 可达性 |
| `resolveMessageId` / `findMessage`（消息意图的唯一身份规则） | `./contracts` | 参考应用 Round 1：消息 id 两套规则导致 Tauri 回复 / 撤回失效 |
| `useFlareConfirm` / `useFlareToast`、`FLARE_TOAST_LIMIT` 及 `FlareConfirm` / `FlareConfirmOptions` / `FlareShowToast` / `FlareToastOptions` 类型（由 FlareUiProvider 呈现） | `./composables` | 参考应用 Round 1：五端各自造 toast 宿主与确认弹层 |
| ~~`FlareIMAppKit.activePane`（Vue、Flutter；iOS / Compose 已有）~~ Round 9（B2–B4）删除：目的地拥有自己的窗格 | 组件 props | 参考应用 Round 2：手机端丢弃 primary / detail 插槽，应用重复声明列表与详情 |
| 原生 `FlareMessageData.reactions` / `isRecalled`，`MessageList` / `MessageBubble` 的 `onReact`，`FlareStrings.messageRecalledSelf` / `messageRecalledPeer` / `messageRecalledGroupOther`（Flutter、iOS、Compose） | 原生组件与模型 | 参考应用 Round 2：原生气泡不渲染撤回（撤回内容仍可读）与表情回应 |
| Flutter `FlareDangerConfirm.show`（busy / error / retry） | Flutter 组件静态方法 | 参考应用 Round 2：示例门禁禁止应用调用 showDialog，破坏性操作无确认 |
| Compose `FlareGroupDetail.onBack` 改为可空（为空不显示返回）；`FlareScreen` / `ConversationHeader` / `FlareGroupDetail` 承接系统返回 | Compose 组件参数与行为 | 参考应用 Round 2：Android 系统返回直接退出应用 |
| `formatMessageTime` / `formatConversationTime` / `formatRelativeTime` | `./utils` | 参考应用 Round 3：五端各写一份只认中文的时间格式化 |
| `MessageMenuExtension`（消息菜单里的宿主操作，配合 FlareMessageList 的 actions 属性与 action 事件） | `./utils` | 参考应用 Round 3：举报、翻译等宿主操作进不了消息菜单 |
| `FlareSearchResultTarget`（FlareSearchResultItem 的 target 字段） | `./contracts` | 参考应用 Round 3：全局消息搜索结果无法定位到消息 |
| `FlareConversationAction` 改为 camelCase 统一 id 并迁入会话动作契约（原 ConversationActionId 类型删除） | `./contracts` | 参考应用 Round 3：会话行与会话动作面板两套 id |
| `FlareSheetPresentation`（`FlareBottomSheet` / `FlareFormSheet` 的 `presentation`） | 组件类型 | 参考应用 Round 3：桌面端表单与次级面板一律是底部面板 |
| `actionMenuEntries`、`FlareActionMenuEntry`、`FlareActionMenuPresentation`；`FlareActionItem` / `FlareActionIntent` 迁入操作菜单契约并新增 pressed、danger | `./contracts` | 参考应用 Round 4：四端各自造「新建 / 更多」菜单，组件库内的下拉选项没有菜单语义 |
| `buildMessageMenuItems`（原 buildMessageMenuDropdownOptions，返回操作描述） | `./utils` | 参考应用 Round 4：消息下拉菜单改由 FlareActionMenu 绘制 |
| `FlareGroupJoinPolicy`、`groupJoinPolicies`（删除 GROUP_JOIN_INVITE / GROUP_JOIN_APPROVAL / GROUP_JOIN_OPEN 与 isGroupJoinPolicy） | `./contracts` | 参考应用 Round 4：组件库模型里写着 SDK 的进群方式数字 |
| Vue 组件：`FlareActionMenu`（`items`、`label`、`open`、`x` / `y`、`placement`、`presentation`、`trigger`；`select`、`update:open`）；`FlareGroupDetail` 的 `after-info` / `footer` 插槽；`FlareGroupDetailModel.joinPolicy`、`GroupPermissionSettings.joinPolicy` 可为空 | 组件、props、插槽 | 参考应用 Round 4：应用在组件外摆放已读条与举报入口，Tauri 用底部面板拼菜单 |
| 原生：Flutter `FlareActionItem`、`FlareActionMenu`（含 `show`）、`FlareActionMenuPresentation`、`FlareStrings.conversationHeaderAddActions` / `conversationHeaderMoreActions`；iOS `FlareActionItem`、`ActionMenuView`；Compose `FlareActionItem`、`ActionMenu`、`FlareStrings.actionMenuLabel`；三端 `FlareGroupJoinPolicy`、GroupDetail `afterInfo` / `footer`、权限行 `joinPolicyValue` / `policyValue`（删除数字常量与 `intValue`）；Compose `onOpenChat` / `onSetJoinPolicy` 可空 | 原生组件与模型 | 参考应用 Round 4：Android 溢出菜单、iOS 工具栏菜单与设置选择器由应用自造 |
| Vue 组件：`FlareMessageList.unreadFromId` 与 header / footer / empty / unread-divider 插槽、`actions`、`copy`；`FlareConversationRow` / `FlareConversationList` 的 `capabilities`、`selectable`、`selected(Ids)`、`toggleSelect`；`FlareSearchBar.readOnly` 与 `activate`；`FlareContactList` / `FlareContactItem` 的 `selectable`、`trailing` 插槽、`toggleSelect`；`FlareNewFriendRequests.withdraw`；`FlareQRCard.qrPayload`；`FlareCheckbox.ariaLabel`；`FlareConversationIdentity.action` 与动作的 `pressed` | 组件 props / 事件 | 参考应用 Round 3：剩余 P1 摩擦 |
| `connectionNotice`、`FlareConnectionNotice` / `FlareConnectionPhase` / `FlareConnectionRecovery` 类型；`timelineDateLabel`（替代已删除的 timelineSeparatorLabel） | `./utils` | 参考应用 Round 5：五端各写一份连接横幅文案与恢复动作；时间线分隔只在首条与跨天 |
| `useFlareNativeBack`、`FlareWebPlatformAdapterOptions`（`createWebPlatformAdapter({ historyBack })`） | `./composables` | 参考应用 Round 5：手机浏览器返回键直接离开应用，平台契约的 onNativeBack 无人消费 |
| Vue 组件：`FlareUiProvider.assetBaseUrl`；`FlareSearchPanel.autofocus`、`FlareSearchBar.autofocus`；`FlareGroupMemberGrid.total`；`FlareScreen.readable` | 组件 props | 参考应用 Round 5：子路径部署表情面板空白、搜索吞首个按键、大群成员格计数、桌面整页过宽 |
| 原生：Flutter `flareConnectionNotice` 与 `FlareConnectionPhase` / `FlareConnectionRecovery` / `FlareConnectionNotice`、`FlareDialog.prompt`、`FlareGroupDetail.submitEdit` 与 `FlareGroupEditKind`、`FlareGroupMemberGrid.total`、`flareCompareContactNames`、MessageList / MessageBubble / MessageContentView 的 `onOpenFile`（删除 `FlareMediaController.open`）；iOS `FlareConnectionNotice.resolve` 与 `FlareConnectionPhase` / `FlareConnectionRecovery`、`FlarePromptOptions` 与 `FlareFeedback.prompt(_:)`、`ComposerView(mentionCandidates:)`、`GroupMemberGridView(total:)`；Compose `FlareDialogState`、`rememberFlareDialogState()`、`LocalFlareDialog`、`FlareConfirmOptions` / `FlarePromptOptions`、`FlareToastHost(dialogs =)`、`flareConnectionNotice` 与同名类型、`Composer(mentionCandidates, mentionEveryone)`、`MentionPicker(framed, autofocus)`、`GroupMemberGrid(total)`、`FlareGroupDetail(submitEdit)` 与 `FlareGroupDetailEditKind`；三端 `FlareStrings` 的 connection、会话头默认动作、在线状态与群成员面板字段 | 原生组件、模型与呈现器 | 参考应用 Round 5 Batch 2b：连接提示、单值输入框、群详情与提及选人器的四端对齐 |
| `resolvePaneMode` / `paneModeMinWidth` 与 `FlarePaneMetrics`、`FlareWorkspacePaneMode`、`FlareWorkspaceDetailPresentation`、`FlareLayoutChange`（`./contracts`，Round 9 取代 `workspaceDualPaneMinWidth` / `workspaceTriplePaneMinWidth`）；`FlareResponsiveLayout` / `FlareConversationWorkspace` 的 `layoutChange` 事件；`FlareAppLayout` 的 `layoutChange` 事件（`FlareIMAppKit` 的同名事件 Round 9 B2–B4 删除，窗格由目的地里的 `AppLayout` 报告）；`FlareSettingKind` 增加 `"action"`（`"value"` 变为只读行）；`FlareGroupDetailModel.myMuted` / `myPinned` 可为 `null`；组件令牌 `--flare-component-sheet-dialog-width` | `./contracts`、组件事件与令牌 | 参考应用 Round 5 复评：600–751px 聊天只剩 210px、只读设置行被读成按钮、读失败的开关谎报「关」、桌面搜索整屏接管 |
| 原生：MessageList / MessageBubble / MessageContentView 的 `onOpenLink`（Flutter / iOS / Compose，Flutter 原 `onLinkTap` 改名）；`GroupDetail` 的 `searchMembers` / `onSearchMembers`（四端登记） | 原生组件事件 | 参考应用 Round 5 复评：气泡里的文本链接点了没反应；群成员搜索回调此前未登记 |
| 原生：`FlareReplyTarget.messageId`、`FlareMessageData.replyTo`、`onLocateMessage`；Flutter `FlareToast.show`、`FlareBottomSheet(.show)`、`FlareDialog.show`、`FlareTimeFormat`；iOS `FlareFeedback`（toast / confirm）、`flareFeedbackHost`、`BottomSheetView` + `flareBottomSheet`、`FlareTimeFormat`；Compose `FlareToastHost` / `FlareToastState` / `LocalFlareToast`、`BottomSheet`、`FlareTimeFormat`、`Composer.value` / `onValueChange`；四端 SearchBar `readOnly` / `onActivate`、联系人选择与尾部内容、好友申请方向与撤回、二维码 `qrPayload`、会话头身份区 `action` / `pressed`、GroupDetail 成员意图携带目标状态 | 原生组件、模型与呈现器 | 参考应用 Round 3：原生端 toast / 确认 / 面板由应用自造 |
| Round 9 壳层契约 v2：`FlareIMAppKit` 的 `destination` 作用域插槽（`{ id, active }`）、`useFlareDestinationDepth`；Flutter `FlareIMAppKit.destinationBuilder`、`FlareShellScope`、`FlareDestinationDepth`；iOS `IMAppKitView(destination:)`、`.flareDestinationDepth(_:)`、`flareDestinationActive`、`flareDestinationPresentation`；Compose `IMAppKit(destination)`、`FlareDestinationDepth(active)`。删除：IMAppKit 的 `responsiveMode`、`primary`、`detail`、`hasDetail`、`activePane`、`paneMode`、`detailMode`、`hideMobileNavigation`、`onLayoutChange`；`AppLayout` / `WorkspaceFrame` 的 `responsiveMode` | 组件插槽、参数、composable 与修饰符 | 参考应用 Round 9（FR-095）：五个 app 各自量窗口、各自常驻页签、各自推导手机底栏 |
| Round 9 富文本：`RichTextMessage`（Vue `FlareRichTextMessage`、Flutter `FlareRichTextMessage`、iOS `RichTextMessageView`、Compose `RichTextMessage`；`docJson`、`plainText`、`title`、`self`、`selectable`，事件 `linkClick`）；原生 `FlareRichTextContent`（`richText`）；原生 `FlareStrings.messageSpoilerReveal`、Vue `message.spoilerReveal` | 组件、原生内容类型、词条 | 参考应用 Round 9（FR-141）：原生富文本降成纯文本，Vue 画发送方的 Markdown 原文 |
| Round 9 图组与图库：`ImageGroupMessage`（Vue `FlareImageGroupMessage` 与类型 `FlareImageGroupItem`、Flutter `FlareImageGroupMessage`、iOS `ImageGroupMessageView`、Compose `ImageGroupMessage`；`images`、`description`、`self`，事件 `open`）；原生 `FlareImageGroupContent`（`imageGroup`）；预览 `galleryIndex` / `galleryCount` 与 `previous` / `next`（Vue `FlareImagePreview`，原生 `onPrevious` / `onNext`）；Flutter `FlareImagePreview.presentGallery`；Flutter / iOS / Compose `FlareImageGalleryItem`、`flareImageGalleryItems`、`flareImageGalleryStart`；图组与图库词条 | 组件、原生内容类型与函数、词条 | 参考应用 Round 9（FR-142）：原生没有图组、预览一次一张、五个 app 一次只发一张 |
| Round 10 时间线下载：Flutter / Compose `MessageList`、`MessageBubble` 的 `onMediaDownload(message, content)` 与 `MessageContentView` 的 `onMediaDownload(content)`（与 iOS 同语义：时间线里的图走会话图库、按屏上那张图所属的消息回调）；契约 `mediaDownload` 的平台范围补 flutter / compose | 组件事件 | 参考应用 Round 9（FR-144）：四端里只有两端的预览有下载键 |
| Round 10 删除（无别名）：`AdaptiveWorkbench` 四端（`FlareAdaptiveWorkbench`、`AdaptiveWorkbenchView`、`AdaptiveWorkbench`），改用 `AppLayout`（插槽 `navigation` / `primary` / `content` / `detail` / `overlay` / `floating` / `command`，栏数由共享分栏规则决定） | 组件 | 参考应用 Round 9（FR-140）：同一组区域两套组件，其中一套不量盒子、不走分栏规则、无消费者 |
| Round 10 Vue 图标属性：kit 画出的每个图标 SVG 带 `data-flare-glyph`（Lucide 字形名） | 渲染输出 | 参考应用 Round 9（FR-136）：像素容差比一个图标还大，换了图标截图看不出来 |
| Round 9 投票 / 任务意图：`MessageList`、`MessageBubble`、`MessageContentView` 的 `vote`、`taskToggle`（Vue 事件；原生 `onVote` / `onTaskToggle`） | 组件事件 | 参考应用 Round 9（FR-143）：时间线里的投票与任务只读，宿主接不到意图 |

行为变化（非新增符号）：Vue Composer 在词首输入 “@” 且宿主提供了成员名册时打开成员选择器，名册不再截断为 8 人；平板请求三栏时详情以浮层打开；快捷表情默认集改为 👍 ❤️ 😂 😮 😢 🎉（四端）；宿主传入的表情条同样受 `canReact` 约束；IMAppKit 的 `#overlay` 插槽成为覆盖层（不再参与窗格网格）；Vue 气泡的表情药丸在宿主处理 `react` 时可点击切换。

Round 3 的行为变化（非新增符号）：Vue `FlareComposer` 删除 `mediaPanelOpen`（`#media-panel` 在表情 / 贴纸面板打开时显示），语音只在提供发送处理时出现；`FlareConversationRowModel.actions` 与 Vue 行的 `longPress` 删除，没有 `capabilities` 的行没有菜单；`MessageLike.extensions` 删除、`attributes` 可选、置顶只读 `pinned`；`FlareFormField` 不再通过插槽暴露 id，表单控件自动接收；`FlareQRCard.qrImageUrl` 删除；`FlareConversationIdentity.avatarAction` 改名 `action`；`FlareGroupDetail` 的 `promoteMember` / `muteMember` 事件携带目标状态；桌面端的底部面板与表单面板默认呈现为对话框；修复桌面消息下拉菜单点选无效（监听了 naive-ui 不存在的事件）。

Round 4 的行为变化（非新增符号）：Vue 会话行、会话头部与消息下拉菜单改由 `FlareActionMenu` 绘制（具名 `role="menu"`，条目 `menuitem` / `menuitemcheckbox`，不再有 `.n-dropdown` 类名）；`FlareGroupDetail` 的发消息按钮只在宿主处理打开聊天时出现（四端）；Vue `FlareAnnouncementReadBar` 显示文案（此前渲染消息键），「查看未读」要有 `view-unread` 监听；未知进群方式显示「未设置」；iOS 会话头部操作的 `icon` 为组件库语义图标名。迁移见 migration/2.0-rc-to-2.0.md §4o。

组件数量：Round 4 新增 `ActionMenu`（契约 `Menu` 的实现，四端），149 → 150。Round 9 新增 `RichTextMessage` 与 `ImageGroupMessage`（四端），150 → 152。Round 10 删除 `AdaptiveWorkbench`（四端），152 → 151。

## 6. 证据

vitest 515 / check:sfc 191 / vue-tsc 0 / Playwright 143；flutter 500 + analyze 0；compose 164；swift 201；36 项设计系统门禁、43 项 release-check 关口；示例 web typecheck + 50、tauri 5、flutter app 81、android app 20、ios app 59 例执行 0 失败（6 例联调用例按环境变量跳过）+ 模拟器 BUILD SUCCEEDED（P0-6 当轮）。
