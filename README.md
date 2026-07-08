# Flare IM Design — 跨端 IM UI Kit

一套「类 Ant Design」的 IM UI 组件体系，覆盖 **web / Flutter / Android / iOS**。
不是"一份渲染代码跑四端"（Vue/Flutter/SwiftUI/Compose 物理不可共享），而是 **Material Design 式**：
**一套契约 + 一套设计系统 + core 行为，各端各自原生实现**。

## 分层

```
L4  行为/数据 = core 可观察视图 (Rust, 已有)   ← flare-im-core-sdk client.views
L3  设计 tokens (平台中立单一真源)             → tokens/  ✅ 本仓
L2  组件契约 spec ("类 Ant 组件 API")          → spec/    (规划中)
L1  各端组件包 (薄原生实现)                     → packages/(规划中，从各端 app 抽取)
```

## 目录

| 路径 | 内容 | 状态 |
|---|---|---|
| [`docs/DESIGN.md`](docs/DESIGN.md) | 完整架构设计（方向/层归属/硬路径/权衡/风险） | ✅ |
| [`docs/PLAN.md`](docs/PLAN.md) | 可执行落地计划 + 进度真源 | ✅ |
| [`tokens/`](tokens/) | **L3** `flare-im-design-tokens` 包：中立 JSON 源 + 生成器（web CSS/TS，各端预留） | ✅ Phase 1 |
| `spec/` | **L2** 组件契约（首批 4 组件 MessageBubble/ConversationList/Composer/Avatar） | 规划 |
| `packages/` | **L1** 各端组件包（Vue 已在 flare-im-core-client-sdk；Flutter/iOS/Compose 待抽取） | 规划 |

## L3 tokens — 一份值，各端主题

```bash
cd tokens && node build.mjs   # tokens.json → dist/tokens.css + dist/tokens.ts
```

`tokens/tokens.json` 是**唯一视觉真源**。生成 web 的 CSS 变量（`--flare-color-*` 等，含 `:root` 与
`[data-flare-theme="dark"]`）与 typed token 对象。改一个值，消费方全更新。
消费方 `flare-core-vue-im-ui` 通过 `file:` 依赖 `flare-im-design-tokens` 消费（`@import "flare-im-design-tokens/tokens.css"`
+ `import { flareDesignTokens }`）。Dart/Swift/Compose 生成器在对应 L1 组件包落地时再加（不做无消费者的抽象）。

> 可视化组件目录（各端依赖 + 用法示例）见设计交付的 Artifact "Flare IM UI Kit"。
