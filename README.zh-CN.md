# Flare UI

面向 Vue、Flutter、Android Compose 与 SwiftUI 的跨端 UI System。

Flare UI 提供生成式 Design Tokens、框架无关组件/交互契约、General UI、IM UI、工作区 Patterns、Examples、Documentation Website、Visual Regression 与 Release Tooling。组件只接收受控状态并发出意图；产品继续拥有数据、权限、持久化、网络和业务副作用。

[English](README.md) · [Documentation](website/) · [Component Catalog](spec/component-catalog.json) · [Public API](PUBLIC_API.md) · [Compatibility](COMPATIBILITY.md)

## Packages

| 平台 | Package | 实现 |
|---|---|---|
| Vue 3 | `@flare-im/vue-ui` | `packages/vue-im-ui/` |
| Flutter | `flare_im_ui` | `packages/flutter-im-ui/` |
| Android Compose | `com.flare.im:im-ui-compose` | `packages/android-im-ui/` |
| SwiftUI | `FlareIMUI` | `packages/ios-im-ui/` |

每个平台只拥有一个高内聚 package。General UI 与 IM UI 作为逻辑依赖层，由 `spec/component-layers.json` 和 `tooling/check-package-boundaries.mjs` 强制；不创建空包，也不保留转发 facade。

## Architecture

```text
tokens/tokens.json
        ↓ generate
spec/components.json + interaction/accessibility/scenario contracts
        ↓ validate
Vue / Flutter / Compose / SwiftUI native implementations
        ↓ consume
gallery + website + visual regression + consumer fixtures
```

- `tokens/` 与 `spec/` 是 Source of Truth。
- 四端 package 是实现层，不重新定义契约。
- Vue PC 是可交互 reference implementation，不是 Source of Truth。
- 依赖方向只有 Foundation → General UI → IM UI。
- 产品账号、业务鉴权、SDK 管理、运营后台和产品工作流不属于本仓库。

详见 [Repository Scope](docs/repository-scope.md)、[Repository Inventory](docs/repository-inventory.md) 与 [Component Layer Map](docs/component-layer-map.md)。

## Install

```bash
npm install @flare-im/vue-ui vue naive-ui
```

```vue
<script setup>
import { FlareButton, FlareConversationRow, FlareMessageBubble, FlareComposer } from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";
</script>
```

Flutter、Compose 与 SwiftPM 的安装、最低版本、主题和首个组件示例见[平台安装指南](website/guide/install.md)与 [COMPATIBILITY.md](COMPATIBILITY.md)。

## 10 秒找到职责

| 任务 | 位置 |
|---|---|
| 修改颜色、间距、字号、圆角、Motion、Breakpoints | `tokens/tokens.json` |
| 修改公共组件/状态/事件契约 | `spec/components.json` |
| 查询 status、platform、docs、example 和 source path | `spec/component-catalog.json` |
| 实现 Vue / Flutter / Compose / SwiftUI | 对应 `*-im-ui/` package |
| 组合工作区 | `examples/gallery/`、`website/patterns/`、`docs/composition-patterns.md` |
| 增加场景 | 共享 scenarios，再投影到 `examples/{vue,flutter,compose,swiftui}` |
| 运行官网 | `website/` |
| 校验 | `npm run check` |
| 发布 | `docs/release-checklist.md` 与 `tooling/check-kit-distribution.mjs` |

## Development

```bash
npm run generate
npm run check
npm --prefix website run dev
```

`npm run generate` 更新契约派生的 Catalog、文档元数据和 Tokens。`npm run check` 校验 Source Contracts、生成漂移、Package Boundaries、Public Exports、Docs/Example Coverage、Links、Website Build、Visual Baselines 与 Distribution Readiness。

## Documentation

- [Getting Started](website/guide/getting-started.md)
- [Foundations 与 Token Explorer](website/foundations/index.md)
- [General UI](website/general/index.md)
- [IM UI Guide](website/im/index.md)
- [Patterns](website/patterns/index.md)
- [Platform Guides](website/platforms/index.md)
- [Recipes](website/recipes/index.md)
- [Accessibility](website/accessibility/index.md)
- [Testing 与 Quality Gates](docs/testing-and-quality-gates.md)

修改公共组件前先读 [CONTRIBUTING.md](CONTRIBUTING.md)。RC 阶段以 `spec/components.json` 和明确 package exports 为当前契约；breaking change 必须在同一变更中同步四端实现、测试、示例与文档。

License: [Apache-2.0](LICENSE)。
