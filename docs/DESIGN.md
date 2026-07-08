# Flare IM UI Kit — 跨端「类 Ant Design」IM 组件库设计

> 目标：把现有三套 Vue IM UI 整合，并演进为一套**类 Ant Design、跨 web / Flutter / Android / iOS** 的 IM UI 组件体系。
> 结论先行：**能整合，但不是"一套渲染代码跑四端"**——那在 Vue/Flutter/SwiftUI/Compose 之间物理上做不到（Ant Design 本身也只是 React）。
> 正确形态 = **一套设计系统(tokens) + 一套组件契约(spec) + core 可观察视图(behavior)，各端薄薄地原生实现**。这正是 Flare 已经走了一半的路。

---

## 0. 现状勘察（三套 Vue + 已有原生端）

| 代号 | 包 | 位置 | 规模 | 特点 |
|---|---|---|---|---|
| **A** | `@flare/shared-im-ui` | `examples/shared-im-ui` | 66 .vue | 聊天为主 + `sdk-host`/`events`/`session` 接线；社交向增强（pinned 面板/tabs） |
| **A'** | `@flare/shared-im-ui`（副本） | `flare-social/.../examples/apps/shared-im-ui` | 66 .vue | **A 的拷贝**（迁移复制），同名同构 |
| **B** | `flare-core-vue-im-ui` | `flare-im-core-client-sdk/packages/` | 69 .vue | **更成熟的"真实包"**：有 `design-system/`（tokens/theme/provider）、更全消息类型(Vote/Task/Schedule/MiniProgram/Announcement)、命名规范(Flare 前缀) |

三者组件集 ~80% 重叠（MessageBubble/MessageList/ChatConversationHeader/EnhancedComposer/ConversationList/Avatar/MessageStatus/PinnedMessageBar/TimeStamp/ImagePreviewModal/VideoPlayerModal/MarkdownPreview…），是**同一 IM UI 的并行演化**。**三者都是 Vue = 只覆盖 web（及 electron/tauri/uni 同为 Vue 宿主）**。

已有原生端（都在消费 core 可观察视图，**各自原生 UI，非共享代码**）：
- Flutter：`flare-core-flutter-app` 123 dart，**原生 widgets**（`lib/interface/widgets/message/views`，无 webview）
- iOS：`flare-core-ios-app` 53 swift，**原生 SwiftUI**
- Android：`flare-core-android-app` 48 kt + `flare-core-android-sdk/.../api/views`（**Kotlin 侧已绑定 core 视图**）
- 另有 arkts/cangjie/rn/electron/tauri/uni/web 共 10 个 runtime

**核心事实**：行为/数据已经沉在 Rust core 的**可观察视图**（`flare-im-core-sdk/src/client/api/view.rs`：`OpenConversationListViewRequest`/`OpenTimelineViewRequest`/`ConversationListView`…），各端 SDK（TS/Kotlin/Dart/Swift）已绑定。**Flare 缺的不是"行为跨端"，而是"UI 层没有统一的设计系统 + 组件契约 + 去重的实现"。**

---

## 1. 架构方向（Architectural direction）

把"IM UI 组件库"拆成**四层契约 + N 个薄实现**，对齐 Material Design 的做法（一套 spec，web/Flutter/Android/iOS 各有实现），而不是 Ant Design 的做法（单框架）：

```
┌─────────────────────────────────────────────────────────────┐
│  L4  行为/数据契约 = core 可观察视图 (Rust, 已存在)            │  ← 会话列表/时间线/消息状态/未读/typing/presence
│      client.views → 各端 SDK 绑定 (TS/Kotlin/Dart/Swift)      │     乐观态、排序、收敛都在这
├─────────────────────────────────────────────────────────────┤
│  L3  设计 tokens (平台中立, 单一真源)                          │  ← 色板/间距/字号/圆角/动效/阴影/暗色
│      flare-im-design-tokens → 生成 CSS vars/Dart/Swift/Compose│     Style Dictionary 产物
├─────────────────────────────────────────────────────────────┤
│  L2  组件契约 spec (平台中立, "类 Ant 组件 API")              │  ← 组件目录 + props/slots/states/events
│      flare-im-ui-spec (schema + 文档 + 视觉基准)              │     驱动各端实现 & 一致性校验
├─────────────────────────────────────────────────────────────┤
│  L1  各端组件包 (薄原生实现, 消费 L4+L3, 遵循 L2)              │
│      Vue: flare-core-vue-im-ui   Flutter: flare_im_ui         │
│      SwiftUI: FlareIMUI          Compose: flare-im-ui-compose │
└─────────────────────────────────────────────────────────────┘
```

"类 Ant Design"体现在 **L2 组件契约 + L3 tokens + 组件目录/文档站**（可发布的 catalog、可主题化、props 一致）；跨端体现在 **L1 各端各自原生实现同一 L2/L3/L4**。**没有"一份 UI 代码四端跑"，因为那要么牺牲质量（Flutter-web/RN），要么牺牲原生顺滑（webview），都过不了飞书级的线。**

---

## 2. 层归属（Layer ownership，按 flare-im-spec 落位）

| 资产 | 层 | 理由 |
|---|---|---|
| 会话列表/时间线/消息状态/未读/typing/presence **视图模型** | **core (Rust)** | 产品中立、每端一致 → 沉 core（已完成，可观察视图） |
| 设计 tokens（色/距/字/角/动效/暗色） | **packages**（`flare-im-design-tokens`） | 跨所有端复用的中立数据；生成各端主题 |
| 组件契约 spec（目录 + props/states/events + 视觉基准） | **packages/sdk-spec 级** | 跨端一致性契约，像 sdk-spec 之于 API |
| 各端组件包（Vue/Flutter/SwiftUI/Compose） | **packages** | "被 ≥1 example app 复用" → 沉 packages（`flare-core-vue-im-ui` 已在此层，正确） |
| 屏幕/路由/产品流/主题实例化 | **examples/social** | 只有产品组合留在 app |

**no-compat 硬约束的直接后果**：A / A' / B 是**冗余并行路径**，spec 禁止并存 → **必须合并为一套 Vue 包并删除其余两份**（见 Track 1）。

---

## 3. 两条推进轨道

### Track 1 — 立即：三套 Vue → 一套 canonical Vue IM UI（web 实现）
- **归并到 `flare-core-vue-im-ui`（packages/，层正确）**，删除 `@flare/shared-im-ui` 的两份拷贝（A/A'）。
- 并入策略：以 B 为骨架（design-system + 全消息类型 + 命名规范），吸收 A 的**接线层**（`sdk-host`/`events`/`session`/`hub` — 这些其实该进 `packages` 的**非 UI 复用基建**，不是组件）与社交向组件（pinned 面板/会话 tabs）。
- 接线层（event hub / sdk-host / session 编排）**从 UI 包剥离**成独立 `packages/*`（复用基建），Vue 包只留组件 + composables。
- 产出：web/electron/tauri/uni 四个 Vue 宿主统一消费一套 `flare-core-vue-im-ui`。
- 顺带把本轮修的三个真 bug（send-ack 信封拆包、response 信封拆包、事件 hub）固化进 canonical 包，避免再分叉。

### Track 2 — 演进：把"IM Kit"形式化为设计系统 + 契约 + 各端包
1. **`flare-im-design-tokens`**：平台中立 tokens（Style Dictionary JSON）→ 生成 `CSS vars` / `Dart ThemeExtension` / `Swift tokens` / `Compose Theme`。单一视觉真源；暗色/品牌换肤靠覆盖 token。
2. **`flare-im-ui-spec`**：组件目录 + 每个组件的 props/slots/states/events（框架中立 schema + 文档站 + 视觉基准截图）。首批组件：
   `ConversationList` · `ConversationRow` · `MessageList`(虚拟化) · `MessageBubble`(+ 按内容类型分发的 `*View`) · `Composer`(rich/plain/formatBar) · `Avatar` · `PresenceDot` · `TypingIndicator` · `ReadReceipt/MessageStatus` · `PinnedBar` · `MessageActions/ContextMenu` · `MediaPreview`(image/video) · 各业务卡片(Vote/Task/Schedule/Card…)。
3. **各端组件包**（薄实现，消费 L4 视图 + L3 tokens，遵循 L2）：
   - Vue（Track 1 的 canonical 包）
   - Flutter `flare_im_ui`（把现有 flutter-app 的 `widgets/message/views` 抽成可复用包）
   - SwiftUI `FlareIMUI`（抽 ios-app）
   - Compose `flare-im-ui-compose`（抽 android-app，已有 `api/views` 绑定）
   > 各端从"app 里内联的 UI"**抽取为 packages 组件库** = 正是 spec 里"被多 app 复用就沉 packages"的落位。

---

## 4. 硬路径（IM 特有，设计必须交代）

- **虚拟化消息列表**：O(visible)、60fps、append 不整表重排。各端用**原生虚拟化**（Vue 虚拟列表 / Flutter Sliver / Compose LazyColumn / SwiftUI LazyVStack），spec 只规定"必须窗口化"与滚动锚定行为。
- **乐观发送 + 状态收敛**：气泡状态(pending→sent→failed→read)全来自 core 视图模型；UI 永不等网络（本轮修的 send-ack 正属此路径——事件信封拆包后 4s 内翻 ✓）。send→本地回显 < 16ms。
- **内容类型可扩展**：`MessageBubble` 委派到**按 content-type 注册的 `*View`**（text/image/video/file/vote/task/card/miniprogram…）；产品可注册新类型（Flare 已有富文本 RichDoc 在 core 归一化）。
- **主题/暗色/换肤**：tokens 驱动 light/dark 与品牌色；各端把 token 映射到原生主题（CSS var / ThemeExtension / Environment / MaterialTheme）。
- **i18n / RTL / a11y**：消息目录(数据)共享，渲染各端；spec 规定 RTL 镜像与可达性(语义角色/焦点序/对比度)基线。
- **冷启首屏**：会话开 < 200ms 出缓存（core 供缓存视图），网络刷新流式补入。

## 5. 性能与顺滑（对齐 flare-im-spec 预算）
- send→回显 <16ms、点击响应 <100ms、会话开 <200ms(缓存)、冷启 <500ms 主线程、稳定 60fps、单任务 UI 线程 <8ms。
- 达成方式：**数据/行为在 core off-thread**，各端组件只做"消费视图 + 原生虚拟化渲染"；乐观态来自 core 视图，不等 ack；媒体解码/缩略全程 off-thread 渐进交付。

## 6. 权衡（Trade-offs，明说放弃了什么）
- **选**：设计系统 + 契约 + core 视图 + 各端原生实现。**放弃**：单一渲染代码库（在飞书级质量下物理不可得）。
- 备选 A「Flutter 全端(含 web)」：一份代码，但 Flutter-web 包体/SEO/文本质量差，且要弃掉 Vue 与其余 6 个 runtime 投资 → 否。
- 备选 B「Vue 套 webview 上原生」：一份 Vue 塞 webview，快；但键盘/滚动/手势的原生顺滑过不了线，且 Flare 原生端已是原生非 webview → 否。
- 备选 C（本方案）：质量与一致性最高；代价 = N 份实现，但 tokens/spec/core 视图把重活抬走后，**各端 UI 很薄**，代价可控。可先做 **Vue(web) + Flutter + 一个原生**，其余按需扩。

## 7. 扩展性与风险
- **可扩展**：内容类型 view 注册表、token 覆盖换肤、插件组件（业务卡片）。
- **风险**：
  1. **N 端漂移** → 缓解：L2 spec 为唯一契约 + 各端视觉基准/golden 测试 + L3 tokens 单一真源。
  2. **三套 Vue 若不真合并**会继续分叉 → Track 1 必须先落，且删干净（no-compat）。
  3. **维护 4 套原生实现是真成本** → 分期：Vue 先行、Flutter 次之、iOS/Android 随 app 抽取；spec/tokens 就绪后各端实现是"填空"。
  4. 接线层(event hub/sdk-host)混在 UI 包里 → 剥离为独立复用基建包，避免 UI 与编排耦合。

---

## 8. 推荐落地顺序（供 PLAN 展开）
1. **Track 1**：合并三套 Vue → `flare-core-vue-im-ui` 单包；剥离接线层为独立 packages；删除两份拷贝。（收敛现状、消除冗余）
2. **L3 tokens**：抽 `flare-im-design-tokens`（从 B 的 design-system 提取）→ 生成 web 主题，反接 canonical Vue 包。
3. **L2 spec**：写 `flare-im-ui-spec`（组件目录 + props/states/events + 视觉基准），以 canonical Vue 包为首个"参考实现"。
4. **Track 2 各端**：按 spec/tokens 从 flutter/ios/android app 抽取组件包（`flare_im_ui`/`FlareIMUI`/`flare-im-ui-compose`）。
5. 文档站（组件 catalog）+ 各端 golden/视觉测试锁一致性。

> 本文件是**分析与设计（交付物=设计文档，指导后续开发）**。是否展开为可执行 PLAN.md 并实施，请明确发起。
