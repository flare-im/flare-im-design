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

## Status: DONE ✅（part1 e8e2870 + part2 852fbe1 + part3 demo UI；全绿）
非注释中文=0（除 messages.ts zh locale + 语言选择器自称名 `简体中文`）。vue-tsc 净、14/14 vitest 过（2 个 collection 失败=`flare-core-typescript-sdk/contract` 子路径解析，stash 验证为既存环境问题，与本改无关）。

## Steps
- [x] **plumbing ✅**：messages.ts 加 `resolveFlareMessage(locale,key,params)` + 模块级 runtime locale(`setFlareRuntimeLocale`/`currentFlareRuntimeLocale`/`translateFlare`)；useFlareI18n 复用 resolver + provider.setLocale/init 同步 runtime；i18n barrel 导出。vue-tsc 绿。
- [x] **utils 层 ✅**（已线程 locale → resolveFlareMessage；无 locale → translateFlare）：`messagePreview.ts`(34,+`preview.*` 32 键含 named/count 变体) + `markdown.ts`(1,`preview.imageNamed`) + `buildMessageMenuOptions.ts`(删中文 fallback 字典→`translateFlare(messageMenu.*)`) + `conversationTitle.ts`(1,`title.groupMembers`/`memberSeparator`)。vue-tsc 绿。
- [x] **composables 层 ✅**：`useFlareCoreClient.ts`(58→`translateFlare`，补 `notify.sent.*`/`sync.*`/`call.*`/`error.*`/`transport.*`；regex 启发式去中文备选) + `useViewport.ts`(dev 错误改英文字面量)。vue-tsc 绿。
- [x] **message-enhancements（非 UI）✅ part2**：`messageTypeRegistry.ts`(67→composeType.*/field/error + availability.* + 620 复用 messageMenu.pin/unpin) + `messageOperations.ts`(5→error.*/forward.*)。vue-tsc 绿。
- [x] **demo-workbench UI ✅ part3**：10 文件全路由。新增 `toast.*`(含 batchAction/batchPartial/batchSuccess 模板)、`workbench.*`(菜单/搜索状态/kind/themeOpt/variantOpt)、`sdklab.*`(tab/placeholder)、`enhance.*`(modal 字段) 四命名空间(zh+en)。未接线的 5 文件补 `const { t } = useFlareI18n()`；模板文本→`{{ t() }}`、静态 attr→`:attr="t()"`、script→`t()`；复用既有键(common.cancel/logout·conversation.*·messageMenu.*·composeType.field.*·sync.failedTitle)。**语言选择器 `简体中文`/`English` 自称名保留**。
- [x] **收尾 ✅**：全域 han 复扫=1（仅 `简体中文` 自称名，符合预期）；vue-tsc 净、14/14 vitest 过（2 collection 失败=`flare-core-typescript-sdk/contract` 子路径解析，stash 验证既存、与本改无关）。

## Notes / open questions
- 340 distinct 分布：messageTypeRegistry 67 / useFlareCoreClient 58 / WorkbenchLayout 42 / smoke.test 40(skip) / ChatWorkspace 40 / messagePreview 34 / buildMessageMenuOptions 16 / SdkLabPanel 12 …
- Flutter/iOS/Compose 无此胶水层（已 0 中文），本项 Vue-only。
- 之前已完成：四端**组件库**(src/components)去中文（commit 692f290）。
