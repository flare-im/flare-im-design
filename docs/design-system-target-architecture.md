# Flare Cross-Platform Design System Architecture

Status: current 2.0 RC architecture.

## Source of truth

```text
tokens/tokens.json + tokens/themes.json
  -> generated CSS / Dart / Kotlin / Swift theme surfaces

spec/components.json + spec/scenarios/*.json
  -> component catalog / signatures / guides / test scenarios
```

Generated files are outputs, not editing surfaces. Vue PC is a reference implementation, not a contract source.

## Repository ownership

| Path | Responsibility |
|---|---|
| `assets/` | Cross-platform design source and optional shared media assets |
| `tokens/` | Primitive, semantic, component, layout, and motion tokens plus generators |
| `spec/` | Current component, interaction, accessibility, lifecycle, and scenario contracts |
| `packages/` | Four cohesive platform implementations |
| `examples/` | Runnable Vue, Flutter, Compose, and SwiftUI consumers plus gallery manifest |
| `tests/` | Consumer and visual regression fixtures |
| `tooling/` | Generation, validation, docs, visual, and release commands |
| `website/` | Component library documentation and interactive catalog |

The repository does not own product login, transport, SDK management, persistence, diagnostics applications, or business pages.

## Package graph

```text
tokens + spec
  -> packages/vue-im-ui
  -> packages/flutter-im-ui
  -> packages/android-im-ui
  -> packages/ios-im-ui

host applications
  -> one platform package
  -> host adapters, networking, state, persistence, and business policy
```

General UI and IM UI are enforced logical layers inside each real platform package. They are not split into eight mostly empty packages. Current ownership is 39 General UI components and 100 IM UI components.

```text
foundation -> general-ui -> im-ui
```

General UI may consume only foundation semantics. IM UI may consume foundation and General UI. Host applications may compose both. No package imports a product SDK.

## Platform packages

| Platform | Package | Manifest | Public implementation |
|---|---|---|---|
| Vue | `packages/vue-im-ui` | `package.json` | Vue 3 and Naive UI |
| Flutter | `packages/flutter-im-ui` | `pubspec.yaml` | Flutter widgets |
| Android | `packages/android-im-ui` | `build.gradle.kts` | Jetpack Compose |
| Apple | `packages/ios-im-ui` | `Package.swift` | SwiftUI |

The Swift package owns its manifest, sources, and tests. There is no root `Package.swift`. Root `package.json` remains a thin repository-wide workspace and quality-gate orchestrator. Root `jitpack.yml` remains only because JitPack discovers configuration at repository root before delegating to the Android package.

## Theme architecture

```text
brand palette
  -> semantic colors
  -> message and control semantics
  -> components
```

The built-in themes are Violet, Ocean, Forest, Sunset, Rose, and Graphite, each with light and dark mappings. Message outgoing, selected, failed, metadata, status, reply, reaction, composer action, focus, and selection colors resolve through semantic tokens. Components do not consume fixed brand colors.

Custom themes override semantic values through the public Web, Dart, Kotlin, and Swift theme contracts. Runtime brand and light/dark selection is platform-native.

## Component contract

The current contract contains 139 components across General, Form, Layout, Conversation, Message, Composer, Media, Contacts, Call, Profile, and Moments categories. `ConfigProvider` is Web-only because native platforms use environment or composition-local theme propagation. `DesktopWorkbench` is implemented for Vue and Flutter PC; mobile-native platforms use their native navigation composition.

Cross-platform parity means matching semantic behavior, states, events, accessibility outcomes, and theme mapping. It does not require pixel-identical platform chrome.

## Public API policy

Only current package roots and declared export maps are public. Removed directories, aliases, forwarding manifests, token aliases, and callback shims are not retained. Historical changes belong in the changelog and migration guide, not in active source or spec metadata.

## Validation

`npm run generate` rebuilds source-derived artifacts. `npm run check` validates repository scope, signatures, tokens, themes, package boundaries, accessibility, docs, gallery, visual contracts, performance, resources, and the website build. Platform packages and examples then run their native tests and builds before release.
