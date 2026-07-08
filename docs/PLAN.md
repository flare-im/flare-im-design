# Flare IM UI Kit — 落地 PLAN

> 设计见 [`IM_UI_KIT_DESIGN.md`](./IM_UI_KIT_DESIGN.md)。本文件是可执行计划 + 进度真源，跨会话续跑读它。

## Goal
把 IM UI 演进为「一套契约 + 各端原生实现」的组件体系：**L4 core 视图（已有）→ L3 tokens → L2 组件契约 → L1 各端包**。
「完成」的可检验定义：① `flare-im-design-tokens` 独立包，一份中立 JSON 源 → 生成 web CSS（+ 预留各端），Vue 包消费它、typecheck 过；
② `flare-im-ui-spec` 组件契约（首批 4 组件）落文档 + 类型；③ 三套 Vue 收敛为一套 canonical 包（去冗余）；④ 从原生 app 抽 Flutter/iOS/Compose 组件包。

## Constraints & decisions
- **no-compat（flare-im-spec 硬约束）**：不并存新旧路径。收敛 Vue = 合并进 `flare-core-vue-im-ui` 并**删除** `@flare/shared-im-ui` 两份拷贝。tokens 是 **move**（源移出 Vue 包），不是 copy。
- **不做未指定的抽象**：L3 generator **只先做 web（CSS/TS）**——Vue 是唯一现有消费者；Dart/Swift/Compose 生成器等各自 UI 包落地时再加。
- 层归属：tokens/spec/各端 UI 包 → `packages/**`；行为 → core（已有可观察视图）；屏幕/产品流 → examples/social。
- 现状：token 管线**已存在但埋在 Vue 包**（`design-system/theme/generated/flare-design-tokens.{ts,css}`，紫色主色 `#7C3AED`）；消费者=`styles/index.css` + `theme/im-theme.ts`。无独立 JSON 源与生成器。
- 三套 Vue：`@flare/shared-im-ui`（examples + flare-social 拷贝，同一份）+ `flare-core-vue-im-ui`（packages，更成熟）。~80% 重叠。
- 各端原生 UI 现**内联在各 example app**（flutter/ios/android），Track 2 = 抽成 packages。

## 家目录
**根级 `flare-im-design/`**（用户指定，非 `flare-im-core-client-sdk/packages/`）：`docs/`(DESIGN+PLAN)、`tokens/`(L3 包)、`README.md`；后续 `spec/`(L2)、`packages/`(L1)。

## Status: IN PROGRESS
Current focus: **Phase 4 Flutter 端全部 18 组件完成**——`flutter-im-ui` analyze 0 + test 45/45，spec validate 双端符号齐（见 Phase 4）。**下一步：iOS `FlareIMUI`(SwiftUI)+Swift 生成器 / 或 Android Compose 包 / 或让 flutter app 换依赖 flare_im_ui 删本地重复 token。** Vue 包已迁入 `flare-im-design/vue-im-ui`（Phase 6）；3 个 npm 包发布 prep+dry-run 过，等你 `npm login`+`npm publish`（[PUBLISHING.md](./PUBLISHING.md)）。

### Phase 6 — Vue 组件库统一迁入 flare-im-design ✅ 完成 + 四端验证（2026-07-07）
- [x] **move** `flare-im-core-client-sdk/packages/flare-core-vue-im-ui` → `flare-im-design/vue-im-ui`（no-compat：旧目录已删，无残留）
- [x] 四端消费方重接线：node_modules 符号链接重指、tsconfig `paths`、共享 vite factory `flareCoreWebAppVite.js` 的 `vueImUiRoot`（改为 `path.resolve(repoRoot, "flare-im-design/vue-im-ui/src")`）
- [x] **tauri 关键修**：其 `node_modules/flare-core-typescript-sdk` 原是**实拷贝**（非符号链接）故吃不到 factory 修复 → 换成符号链接（与 web/electron/uni 一致）
- [x] 两个断言源码路径的测试重指到 monorepo 根（tauri transport-selector 6/6、uni parity 5/5 全绿）
- [x] **构建验证**：web `vite build ✓`、tauri `vite build ✓`、electron `vue-tsc 0 error`（vite 仅卡在无关的未装 `wa-sqlite` 依赖，与本次迁移无关）、uni 自定义 vite 走 tsconfig+符号链接

## Steps

### Phase 1 — L3 tokens 独立包 ✅ 完成 + 验证（2026-07-07）
- [x] **建包 `flare-im-design/tokens/`**（name `flare-im-design-tokens`）：`tokens.json`（中立源 colors/composer/dark/shadows/sizes/transitions）、`build.mjs`（JSON→`dist/tokens.css` `:root`+`[data-flare-theme=dark]` + `dist/tokens.ts` `flareDesignTokens as const`）、`package.json`(exports+types)、README
- [x] 跑 `build.mjs`（65 light + 15 dark vars）；**value diff vs 旧 CSS = 完全一致**（防漂移）
- [x] 接线：Vue `styles/index.css`→`@import "flare-im-design-tokens/tokens.css"`、`theme/im-theme.ts`→`import { flareDesignTokens } from "flare-im-design-tokens"`；file: 依赖 + node_modules 符号链接；**删除** Vue 内两份 generated（no-compat，无残留 ref）
- [x] 验证：`flare-core-vue-im-ui` **vue-tsc = 0 error**
- [x] **端到端构建验证**：`flare-core-web-app`（B 消费方）`vite build` **✓ built in 8.72s** —— 裸 `@import "flare-im-design-tokens/tokens.css"` 经 B 的 node_modules 符号链接**成功解析**、生产构建通过（vue-tsc 不查 CSS，这步才证明接线在真实构建里成立）

### Phase 2 — L2 组件契约 spec ✅ 完成 + 验证 + **全量扩充**（2026-07-07）
- [x] 建 `flare-im-design/spec/`（name `flare-im-ui-spec`）：`components.json` + `validate.mjs`（防漂移，仿 sdk-spec 双向覆盖）+ README
- [x] **扩到全量目录 v0.2.0：18 组件 / 5 类**（General/Conversation/Message/Composer/Media）+ 内容类型注册表（17 种），props/events **从 flare-core-vue-im-ui 源码抽取校准**
- [x] `node validate.mjs` **过**：18 组件契约完整 + 四端 package/symbol 齐 + **每个 Vue 参考符号确实存在**于 flare-core-vue-im-ui

### Phase 3 — 三套 Vue 收敛为一（大、破坏性、逐 app 验证）
- [x] **收敛 map 就绪** → [`VUE-CONVERGENCE.md`](./VUE-CONVERGENCE.md)
- [x] **A/A′ 收敛为 bit-identical**（2026-07-07）：diff 发现两份仅 `events/createImEventHub.ts` 一处差异=本轮 send-ack 信封修复只在 A′。把修复 port 到 A（`examples/shared-im-ui`）→ `diff -rq` 空=完全一致、dedup-ready。**顺带修好 A 的两个消费方 `examples/flare-base-tauri` + `examples/flare-core-tauri`（它们也有同 send-ack bug）**
- [x] **确认 canonical B 无此 bug**：B 用 `useFlareSessionBridge`（非 createImEventHub），`onMessageSendAck` 正确读 `payload.ack`（第 215 行）——core 示例收发正常印证
- [ ] 剥离接线层（`sdk-host`/`events`/`session`/`hub`）→ `packages/flare-im-client-runtime`；examples/shared-im-ui + flare-social app 改依赖，**重建两处验证**（注：flare-social app 深耦合 @flare/shared-im-ui 20+ 子路径，剥离需 re-export 保持 app import 稳定）
- [ ] A 独有组件（pinned 套件/tabs/composer·bubble 拆件/BusinessSystemCard）并入 B
- [ ] flare-social-tauri-app import→B + runtime；**yarn tauri build + computer-use 重测收发消息**（复用本轮脚本）
- [ ] core 示例 web/electron/tauri/uni 逐个 build 验证
- [ ] **删除**两份 `@flare/shared-im-ui`（no-compat）；新增组件对齐 spec
> ⚠️ 未在本轮执行破坏性 re-point/删除：会动到刚修好并 computer-use 验证过的 flare-social 消息收发，必须逐步重建+重测，不可一把梭。已做成 turnkey 清单，按步验证推进。

### Phase 5 — npm 发布 ✅ prep + dry-run 验证（2026-07-07；实发待用户 auth）
- [x] **3 包 publish-ready**：`flare-im-design-tokens`(3.8kB) / `flare-im-ui-spec`(6.5kB) / `flare-core-vue-im-ui`(237kB) —— 补 license/files/exports/publishConfig；tokens 生成器加发 .js/.d.ts；Vue 包去 private、deps 提升(@vicons/markdown-it/tokens^0.1.0)、源码发布
- [x] **裁包**：Vue 包原 70MB(贴纸/表情 webp 67MB)→ `files` 负模式 `!src/assets/**/*.webp` 排除、留 manifest → **237kB/171 文件**、0 webp
- [x] **`npm pack --dry-run` 三包全验证**；`vue-tsc` 全程 0 error
- [x] runbook [PUBLISHING.md](./PUBLISHING.md)：发布顺序(tokens→spec→vue)、scope 决策、消费用法
- [ ] **实发**（用户执行）：`npm login`（我不碰凭证）+ 按顺序 `npm publish`；确认包名可用/是否加 @scope

### Phase 4 — Track 2：各端组件包（最大、分期）
> **补齐 iOS/Android + Ant-Design 式官网**的专项战役计划见 [PLAN-LIBS-AND-SITE.md](./PLAN-LIBS-AND-SITE.md)（进度真源）。
- [x] **tokens 的 Dart 生成器**（2026-07-07）：`build.mjs` 扩 Dart target → 直接 emit 进
  `flutter-im-ui/lib/src/tokens/flare_tokens.dart`（pub 不能消费 npm 包，故生成物 vendored 进 Flutter 包，单一源仍是 tokens.json）。
  `FlareColors`（30 色 × light/dark，dark=light 合并 override；`#hex`/`rgba` 全转 const `Color(0xAARRGGBB)`；`FlareColors.of(Brightness)`）+ `FlareSizes`（27 尺寸 const double）。
- [x] **Flutter 首批组件**（2026-07-07）：建 `flare-im-design/flutter-im-ui`（`flare_im_ui`）。首批 3 个 General 纯展示组件对齐 spec：
  `FlareAvatar`/`FlareTimeStamp`/`FlareMessageStatus`（props-in/callbacks-out，颜色走 `FlareColors.of`，无 riverpod/无 app 耦合）。
  **`flutter analyze` 0 issues + `flutter test` 8/8 绿**。README 带各组件使用示例。
- [x] **Flutter 全 18 组件完成**（2026-07-07）：`flutter-im-ui` 落全部 spec 组件——
  General（Avatar/TimeStamp/MessageStatus）+ Conversation（Row/List/Details/StartSheet）+
  Message（Bubble/List/ContentView/ChatHeader/PinnedBar）+ Composer（Composer/RichMarkdownInput/ActionSheet）+
  Media（ImagePreview/VideoPlayer/MarkdownPreview）。**纯展示 + 中立数据模型**（MessageData/MessageContent 开放注册表
  FlareContentRegistry/PinnedMessage/ConversationSummary/ContactOption）；富内容/i18n/媒体管线上浮到 app。
  自带**依赖轻**实现：手写 Markdown 渲染器、图片预览 InteractiveViewer、视频给 `playerBuilder` 注入点（不引 video 插件）。
  **`flutter analyze` 0 issues + `flutter test` 45/45**。**spec `validate.mjs` 扩 Flutter 符号校验**（并修好 move 后 vueRoot 失效路径）→ 18 组件 Vue+Flutter 双端符号均存在。README 补全表 + 聊天屏用法。
- [ ] flutter app 改依赖 `flare_im_ui` 并删本地 `flare_im_design.dart`/`flare_theme_tokens.dart` 重复 token（no-compat，破坏性、需 sim 重测）
- [x] **iOS `FlareIMUI`（SwiftUI）全 18 完成** + Swift tokens 生成器（`swift build`+`test 12/12`；见 [PLAN-LIBS-AND-SITE.md](./PLAN-LIBS-AND-SITE.md)）
- [x] **Android `flare-im-ui-compose`（Compose）全 18 完成** + Kotlin tokens 生成器（`compileDebugKotlin`+`testDebugUnitTest` 绿）
- [x] spec `validate.mjs` 加 Flutter+iOS+Compose 符号存在性校验（**18 组件 × 四端符号全绿**；并修好 move 后失效的 vueRoot 路径）
- [x] **Ant-Design 式官网 `flare-im-design/site`（VitePress）**：18 组件页由 components.json 生成 + live demo + tokens 页 + 四端 code tab；`vitepress build` 成功
- [ ] （可选破坏性）各端 app 换依赖对应 L1 包并删本地重复 token（no-compat，需各端重测）
- [ ] 各端 golden/视觉基准锁一致性

## Notes / open questions
- token 现值（light）：primary `#7C3AED`、success `#22C55E`、warning `#F59E0B`、error `#EF4444`、bg-primary `#FFFFFF`、text-primary `#111318`、bubble-self `#7C3AED`、bubble-other `#ECE5FF`… 暗色块见 generated CSS 尾部。
- 生成 CSS 文件头须保留 `/* GENERATED. Do not edit by hand. */`。
- workspace 依赖解析方式待确认（pnpm/yarn workspace vs file:）——接线前 check monorepo 根 package.json/workspace 配置。
- 生成器 emit 的 TS token 对象须与现有 `flareDesignTokens` 形状兼容（`im-theme.ts` 依赖其 `.colors/.dark/.composer` 等字段）——否则 im-theme.ts 也要改。
- Phase 3/4 体量大、跨 app/跨语言，按阶段单独验证；本轮先落 Phase 1（+尽量 Phase 2 骨架）。
