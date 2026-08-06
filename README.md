# Flare IM Design — Cross-Platform IM UI Kit

English · [中文](README.zh-CN.md)

> ## ℹ️ This is communication infrastructure, not a turnkey IM product
>
> Up front, so you don't discover it only after cloning and finding you can't
> log in: **the open-source part does not include an account system**
> (no registration/login, friend relationships, group roles/approval/muting, or moments/feed).
>
> But it ships with a complete, pluggable authentication contract, and both
> paths live on the open-source side:
>
> - **`CoreJwtTokenValidator`** — validate JWTs locally. Hand-sign a token and
>   you can get it running for a demo / POC, **without any user system**.
> - **`HttpHookTokenValidator`** — POST the token to your own endpoint;
>   **this is the entry point for integrating your own user system**.
>
> Business rules work the same way: `flare-im-core/crates/flare-im-hooks`
> provides 9 extension points
> (PreSend / PostSend / Delivery / Recall / MessageRead / MessageReaction /
> ConversationLifecycle / ConversationMember / GetConversationParticipants).
>
> To go to production, you implement your own user system and plug it in via
> the contracts above — the same "bring your own identity" model as Sendbird /
> Twilio Conversations, the difference being that Flare can be self-hosted and
> its protocol and core are auditable.
>
> See [GOVERNANCE.md](GOVERNANCE.md) for the boundary details.


An "Ant Design–like" IM UI component system covering **web / Flutter / Android / iOS**.
Not "one rendering codebase running on four platforms" (Vue/Flutter/SwiftUI/Compose
cannot physically share it), but **Material Design–style**:
**one contract + one design system + core behavior, each platform implemented natively.**

## Layering

```
L4  Behavior/data = core observable views (Rust, existing)   ← flare-im-core-sdk client.views
L3  Design tokens (platform-neutral single source of truth)  → tokens/  ✅ this repo
L2  Component contract spec ("Ant-like component API")        → spec/    (planned)
L1  Per-platform component packages (thin native impls)       → packages/(planned, extracted from each platform's app)
```

## Directory

| Path | Contents | Status |
|---|---|---|
| [`docs/DESIGN.md`](docs/DESIGN.md) | Full architecture design (direction/layer ownership/hard paths/trade-offs/risks) | ✅ |
| [`tokens/`](tokens/) | **L3** `@flare-im/tokens` package: neutral JSON source + generators (web CSS/TS, others reserved) | ✅ Phase 1 |
| `spec/` | **L2** Component contracts (first 4 components: MessageBubble/ConversationList/Composer/Avatar) | Planned |
| `packages/` | **L1** Per-platform component packages (Vue already in flare-im-core-client-sdk; Flutter/iOS/Compose to be extracted) | Planned |

## L3 tokens — one set of values, themed per platform

```bash
cd tokens && node build.mjs   # tokens.json → dist/tokens.css + dist/tokens.ts
```

`tokens/tokens.json` is the **single visual source of truth**. It generates the web
CSS variables (`--flare-color-*` etc., including `:root` and
`[data-flare-theme="dark"]`) and the typed token object. Change one value, and all
consumers update. The consumer `@flare-im/vue-ui` consumes `@flare-im/tokens` via a
`file:` dependency (`@import "@flare-im/tokens/tokens.css"`
+ `import { flareDesignTokens }`). The Dart/Swift/Compose generators are added when the
corresponding L1 component package lands (no abstractions without consumers).

> For the visual component catalog (per-platform dependencies + usage examples), see
> the "Flare IM UI Kit" Artifact delivered with the design.

---

## Next steps

| What you want to do | Where to go |
|---|---|
| **Get running in five minutes** | [QUICKSTART](https://github.com/flare-im/flare-im-core-server/blob/main/QUICKSTART.md) — start the services, hand-sign a token, get the APIs working, **no need to build your own user system** |
| Integrate your own user system | Implement `TokenValidator` (`CoreJwtTokenValidator` for local validation / `HttpHookTokenValidator` to call your endpoint) |
| Add your own business rules | The 9 extension points of `flare-im-hooks`: PreSend / PostSend / Delivery / Recall / MessageRead / MessageReaction / ConversationLifecycle / ConversationMember / GetConversationParticipants |
| Build the UI | [`@flare-im/vue-ui`](https://www.npmjs.com/package/@flare-im/vue-ui) — 107 components, a contract consistent across four platforms |
| Report a security issue | [SECURITY.md](SECURITY.md), **please do not open a public issue** |

## When you need an account system and social capabilities

The open-source part is **communication infrastructure**. If what you need is a
ready-made account system, friend relationships, group governance (roles / join
approval / muting), or a moments/feed, these live in the commercial modules —
building this layer yourself usually takes months, and it's all repetitive work
unrelated to communication.

For enterprise scenarios there are also SSO / org structure / audit export / data
residency / SLA support.

Inquiries: `flare1522@163.com`

> For the boundary split and the invariant commitments, see [GOVERNANCE](https://github.com/flare-im/flare-im-core-server/blob/main/GOVERNANCE.md).
> In short: **what has been open-sourced will not be taken back, and the authentication and hooks contracts will always be open source and will never be crippled to coerce payment.**
