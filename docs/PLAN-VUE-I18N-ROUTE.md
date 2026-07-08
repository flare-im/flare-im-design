# Vue 胶水/示例层去中文 → 路由到 i18n

## Goal
`vue-im-ui` 的 `src/app` / `src/composables` / `src/utils` 里硬编码的中文（340 个不同字面量，18 文件）**全部路由到既有 i18n**（`flareMessages` zh+en 树 + `useFlareI18n`/新 runtime 访问器），达成非注释中文=0（`src/shared/i18n/messages.ts` 的 zh locale 除外——那是词典本身）。vue-tsc + vitest 全绿。语言自称名（`简体中文`/`English`）保留。

## Constraints & decisions
- **纯 TS 模块无 Vue inject 上下文** → 需 standalone 访问器：`resolveFlareMessage(locale, key, params)`（纯查表+插值，zh 回退）+ 模块级 `translateFlare(key, params)`（读 runtime locale，由 provider.setLocale 同步）。`useFlareI18n.t` 复用同一 resolver（去重）。
- messagePreview.ts / markdownToPlainText / emojiPackLabel 等**已线程 `locale` 字符串参数** → 这些用 `resolveFlareMessage(locale, key)`（locale 显式，不走全局）。
- useFlareCoreClient.ts / messageTypeRegistry.ts 等**拿不到 locale** → 用 `translateFlare(key)`（全局 runtime locale）。
- 新 i18n key 命名空间：`preview.*`（消息预览）、`sync.*`（同步进度）、`composeType.*`（messageTypeRegistry）、`workbench.*`（demo app）等。zh+en 都补。
- 存储序列化 key（`im.preview.*` 的 `payload.k`）**不是** i18n key，勿混用命名空间。
- `*.test.ts`（smoke.test.ts 40 处）不在包内（files 排除），且中文是测试数据/断言 → **不动**（除非断言依赖被改默认，届时再改）。
- 语言选择器自称名 `简体中文`/`English` 保留。

## Status: IN PROGRESS (checkpoint 1 committed: plumbing + utils + composables)
Current focus: message-enhancements（messageTypeRegistry）+ demo app 组件

## Steps
- [x] **plumbing ✅**：messages.ts 加 `resolveFlareMessage(locale,key,params)` + 模块级 runtime locale(`setFlareRuntimeLocale`/`currentFlareRuntimeLocale`/`translateFlare`)；useFlareI18n 复用 resolver + provider.setLocale/init 同步 runtime；i18n barrel 导出。vue-tsc 绿。
- [x] **utils 层 ✅**（已线程 locale → resolveFlareMessage；无 locale → translateFlare）：`messagePreview.ts`(34,+`preview.*` 32 键含 named/count 变体) + `markdown.ts`(1,`preview.imageNamed`) + `buildMessageMenuOptions.ts`(删中文 fallback 字典→`translateFlare(messageMenu.*)`) + `conversationTitle.ts`(1,`title.groupMembers`/`memberSeparator`)。vue-tsc 绿。
- [x] **composables 层 ✅**：`useFlareCoreClient.ts`(58→`translateFlare`，补 `notify.sent.*`/`sync.*`/`call.*`/`error.*`/`transport.*`；regex 启发式去中文备选) + `useViewport.ts`(dev 错误改英文字面量)。vue-tsc 绿。
- [ ] **message-enhancements**：`messageTypeRegistry.ts`(67) + `messageOperations.ts`(5) + 4 个 modal .vue → translateFlare/t。补 `composeType.*`/`availability.*` keys；620 复用 messageMenu.pin/unpin。
- [ ] **demo app 组件**：FlareWorkbenchLayout(42)/FlareChatWorkspace(40)/FlareSdkLabPanel(12)/FlareConversationsPanel(4)/FlareHomeSyncScreen(4) → useFlareI18n().t。补 `workbench.*` keys。语言自称名(`简体中文`/`English`)保留。
- [ ] **收尾**：全域 han 复扫=0（除 messages.ts zh locale + 语言自称名 + 测试）；vue-tsc + vitest 绿；commit + force main/dev。

## Notes / open questions
- 340 distinct 分布：messageTypeRegistry 67 / useFlareCoreClient 58 / WorkbenchLayout 42 / smoke.test 40(skip) / ChatWorkspace 40 / messagePreview 34 / buildMessageMenuOptions 16 / SdkLabPanel 12 …
- Flutter/iOS/Compose 无此胶水层（已 0 中文），本项 Vue-only。
- 之前已完成：四端**组件库**(src/components)去中文（commit 692f290）。
