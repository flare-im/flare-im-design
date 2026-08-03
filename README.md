# Flare IM Design — 跨端 IM UI Kit

> ## ℹ️ 这是通信基础设施，不是开箱即用的 IM 产品
>
> 说在前面，免得你 clone 完才发现登不上去：**开源部分不含账号体系**
> （没有注册登录、好友关系、群角色/审批/禁言、朋友圈）。
>
> 但它自带完整且可插拔的鉴权契约，两条路都在开源侧：
>
> - **`CoreJwtTokenValidator`** —— 本地验 JWT。手签一个 token 就能跑起来做
>   demo / POC，**不需要任何用户体系**。
> - **`HttpHookTokenValidator`** —— 把 token POST 到你自己的接口，
>   **这是接入自有用户体系的入口**。
>
> 业务规则同理：`flare-im-core/crates/flare-im-hooks` 提供 8 个扩展点
> （PreSend / PostSend / Delivery / Recall / MessageRead / MessageReaction /
> ConversationLifecycle / ConversationMember）。
>
> 要上生产，你需要自行实现用户体系并按上述契约接入 —— 与 Sendbird /
> Twilio Conversations 的「自带身份」模型一致，区别是 Flare 可自托管、
> 协议与核心可审计。
>
> 边界详情见 [GOVERNANCE.md](GOVERNANCE.md)。


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
