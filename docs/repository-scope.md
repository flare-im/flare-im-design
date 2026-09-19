# Repository Scope

`flare-im-design` owns a public, cross-platform UI system. It does not own a Flare product.

## In Scope

- Design tokens and generated platform token surfaces.
- UI specifications, interaction contracts, capabilities, accessibility contracts, and shared scenarios.
- General UI and IM UI public components.
- App shell, adaptive layout, desktop workbench, conversation, chat, thread, search, and settings patterns.
- Native Vue, Flutter, Android Compose, and SwiftUI implementations.
- Examples, gallery, documentation website, visual regression, contract tests, packaging fixtures, release tooling, migration, and compatibility.
- `artifacts/` — gitignored release evidence output (release:check results, live / native / package evidence, candidate id, sign-off). It records evidence *about* a candidate, so it is excluded from the candidate fingerprint and from the repository inventory, and may exist on disk without being part of the repository.

## Out Of Scope

- Product account registration/login, friend/group business rules, operational admin pages, or product dashboards.
- SDK business management or transport/domain semantics.
- Product-specific diagnostics applications and unrelated backend mocks.
- Abandoned prototypes, one-off audit apps, temporary screenshots, debug artifacts, and unrelated experiments.
- Product workflows that cannot be expressed as a reusable component, contract, pattern, or example.

## Review Required

- A public component that needs product-specific state or a required SDK dependency.
- A package move that changes current import coordinates.
- A new platform-only semantic with a cross-platform name.
- A generated file with unclear ownership.
- Historical evidence whose release or legal value is uncertain.

## Ownership Model

```text
Foundation
    ↓
General UI
    ↓
IM UI
    ↓
Flare Product
```

`tokens/` and `spec/` are the source of truth. Platform packages are implementation layers. Vue PC is the interactive reference, never an alternative source. Package paths stay unchanged through 2.x; logical boundaries are enforced by gates now, while any physical package split is evaluated for the next major release.

## Top-level Architecture

| Path | Responsibility |
|---|---|
| `tokens/` | Token source, generation, and published output |
| `spec/` | Component, interaction, accessibility, scenario, catalog, and compatibility contracts |
| `packages/vue-im-ui/` | Vue native implementation and interactive reference |
| `packages/flutter-im-ui/` | Flutter mobile/desktop implementation |
| `packages/android-im-ui/` | Android Compose implementation |
| `packages/ios-im-ui/` | SwiftUI implementation |
| `examples/gallery/` | Scenario-driven cross-platform gallery manifest |
| `website/` | VitePress documentation, catalog, live demos, and search |
| `tests/visual/` | Checked-in visual baselines and comparison tooling |
| `tests/consumers/` | Outside-in package build fixtures |
| `docs/` | Maintainer architecture, migration, testing, and release documents |
| `tooling/` | Generation, validation, packaging, and release gates |

This structure favors stable package coordinates and explicit responsibility over a cosmetic big-bang move into new `packages/` or `tooling/` roots.
