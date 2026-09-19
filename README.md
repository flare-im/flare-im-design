# Flare UI

Cross-platform UI system for Vue, Flutter, Android Compose, and SwiftUI.

Flare UI provides generated design tokens, framework-neutral component and interaction contracts, General UI, IM UI, reusable workspace patterns, examples, documentation, visual regression, and release tooling. Components are controlled UI: applications provide data and capabilities, then handle emitted intent. No product account, persistence, transport, or business workflow is required.

[中文](README.zh-CN.md) · [Documentation](website/) · [Component Catalog](spec/component-catalog.json) · [Public API](PUBLIC_API.md) · [Compatibility](COMPATIBILITY.md)

## Packages

| Platform | Package | Implementation |
|---|---|---|
| Vue 3 | `@flare-im/vue-ui` | `packages/vue-im-ui/` |
| Flutter | `flare_im_ui` | `packages/flutter-im-ui/` |
| Android Compose | `com.flare.im:im-ui-compose` | `packages/android-im-ui/` |
| SwiftUI | `FlareIMUI` | `packages/ios-im-ui/` |

Each platform owns one cohesive package. General UI and IM UI remain logical dependency layers enforced by `spec/component-layers.json` and `tooling/check-package-boundaries.mjs`; there are no empty theoretical packages or forwarding facades.

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

- `tokens/` and `spec/` are the source of truth.
- Platform packages implement the contracts; they do not redefine them.
- Vue PC is the interactive reference implementation, not the source of truth.
- Foundation → General UI → IM UI is the only dependency direction.
- Product-specific applications, authentication products, SDK management, and operational diagnostics are outside this repository's scope.

See [Repository Scope](docs/repository-scope.md), [Repository Inventory](docs/repository-inventory.md), and [Component Layer Map](docs/component-layer-map.md).

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

Flutter, Compose, and SwiftPM installation, minimum versions, theme setup, and first-component examples are in the [platform installation guide](website/guide/install.md) and [COMPATIBILITY.md](COMPATIBILITY.md).

## Find Things

| Task | Location |
|---|---|
| Change colors, spacing, type, radius, motion, or breakpoints | `tokens/tokens.json` |
| Change a public component/state/event contract | `spec/components.json` |
| Inspect component status, support, docs, examples, and source paths | `spec/component-catalog.json` |
| Implement Vue / Flutter / Compose / SwiftUI | the matching `*-im-ui/` package |
| Compose workspaces | `examples/gallery/`, `website/patterns/`, and `docs/composition-patterns.md` |
| Add or update examples | shared scenarios, then `examples/{vue,flutter,compose,swiftui}` |
| Run documentation | `website/` |
| Validate changes | `npm run check` |
| Prepare a release | `docs/release-checklist.md` and `tooling/check-kit-distribution.mjs` |

## Development

```bash
npm run generate
npm run check
npm --prefix website run dev
```

`npm run generate` updates contract-derived catalog/docs metadata and token outputs. `npm run check` validates source contracts, generated files, package boundaries, public exports, documentation/example coverage, links, website build, visual baselines, and distribution readiness.

## Documentation

- [Getting Started](website/guide/getting-started.md)
- [Foundations and Token Explorer](website/foundations/index.md)
- [General UI](website/general/index.md)
- [IM UI Guide](website/im/index.md)
- [Patterns](website/patterns/index.md)
- [Platform Guides](website/platforms/index.md)
- [Recipes](website/recipes/index.md)
- [Accessibility](website/accessibility/index.md)
- [Testing and Quality Gates](docs/testing-and-quality-gates.md)

## Contributing And Release

Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing a public component. During the RC phase, `spec/components.json` and explicit package exports define the current contract; breaking changes must update every implementation, test, example, and document in the same change.

License: [Apache-2.0](LICENSE).
