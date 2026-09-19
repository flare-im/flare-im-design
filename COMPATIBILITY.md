# Compatibility

## 2.0.0-rc.1 family

| Artifact | Version | Minimum runtime | Compatible contract |
|---|---|---|---|
| `@flare-im/ui-spec` | 2.0.0-rc.1 | Node 20 for validation | UI contract 2.0.0-rc.1 |
| `@flare-im/tokens` | 2.0.0-rc.1 | Modern CSS variables / generated native constants | UI contract 2.0.0-rc.1 |
| `@flare-im/vue-ui` | 2.0.0-rc.1 | Vue 3.5, Naive UI 2.44; Chrome 111, Edge 111, Firefox 113, Safari 16.2 | Spec/tokens 2.0.0-rc.1 |
| `flare_im_ui` | 2.0.0-rc.1 | Flutter >=3.10.0 declared; Dart >=3.10.1 is the effective SDK constraint | Spec/tokens 2.0.0-rc.1 |
| `com.flare.im:im-ui-compose` | 2.0.0-rc.1 | Android 26; compile SDK 35; test/lint target SDK 35; Java bytecode 17; Kotlin 2.2.20; Compose BOM 2024.12.01 | Spec/tokens 2.0.0-rc.1 |
| `FlareIMUI` | 2.0.0-rc.1 source artifact | iOS 16 / macOS 13, Swift 5.9 | Spec/tokens 2.0.0-rc.1 |

The web floor is what the styles need, not a wish: the kit paints with `color-mix()` (214 declarations), lays boxes out with `aspect-ratio`, and asks components about their own box with container queries, none of it guarded by `@supports`. A browser below the floor drops those declarations silently — a border or a background simply disappears — so the floor is checked against the CSS by `node tooling/check-browser-baseline.mjs` (in `npm run check`). Features whose absence changes nothing a person needs (`backdrop-filter`, `scrollbar-width`) are written with their own fallback and are not part of the floor.

All RC artifacts must be produced from the same commit. The Swift package is the self-contained `packages/ios-im-ui` artifact; the monorepo root is intentionally not a SwiftPM package. Platform-native media viewers may differ only where the component contract registers a semantic difference.
