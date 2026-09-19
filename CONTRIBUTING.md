# Contributing to Flare UI

Flare UI is a contract-first, cross-platform component library. Optimize for one clear ownership path and minimum cognitive load, not minimum file count.

## Before You Change Code

1. Confirm the capability belongs in this repository using `docs/repository-scope.md`.
2. Reuse an existing component, composition, or pattern before adding a primitive.
3. Decide the layer: Foundation, General UI, IM UI, Pattern, product, or internal.
4. Search public exports, package entries, docs, tests, generated ownership, and consumer fixtures before moving or deleting anything.
5. For a public API change, run `node tooling/check-public-api-drift.mjs` and document the version impact. RC work may intentionally break development-era APIs.

## Adding A Cross-platform Component

A cross-platform component is complete only when it has:

1. A component contract in `spec/components.json`.
2. Interaction/state contracts and typed capabilities.
3. Semantic/component tokens when existing tokens are insufficient.
4. A shared scenario in `spec/scenarios/rc.json` when behavior is stateful.
5. Vue implementation and public export.
6. Flutter implementation and public package export.
7. Compose implementation and public symbol.
8. SwiftUI implementation and public symbol.
9. Accessibility semantics, labels, focus, large text, reduced motion, and touch-target behavior.
10. Focused tests for each implementation.
11. Gallery and tests/visual coverage for complex states.
12. Bilingual component docs and platform code examples.
13. Component Catalog metadata and version status.

Use [the detailed checklist](docs/guides/new-component-checklist.md). A platform-specific component must declare its scope and `not-applicable` platforms instead of pretending parity.

## Source And Generated Files

- Edit `tokens/tokens.json`, then run `node tokens/build.mjs`.
- Edit `spec/components.json` or contract metadata, then run `npm run generate`.
- Do not hand-edit `tokens/dist`, native token files, `spec/component-catalog.json`, `spec/public-export-map.json`, `docs/component-layer-map.md`, or generated website guide pages.
- Keep shared scenario data separate from platform presentation code.

## Dependency Rules

```text
Foundation → General UI → IM UI → Product
```

General UI cannot know Message, Conversation, or IM domain types. IM UI may depend on General UI, but not on a product application or runtime client. Product state, authentication, permissions, persistence, networking, and side effects stay in the host.

## Validation

Run the smallest relevant test first, then broaden according to risk:

```bash
npm run generate
npm run check
npm --prefix website run test:visual
```

Platform-focused commands are documented in `docs/testing-and-quality-gates.md`. Do not weaken a contract or visual baseline to match a regression.

## Rounded Surface Checklist

Before changing an Input, Card, Menu, Dialog, Composer, or media surface, verify:

1. One element owns the outer background, border, radius, and focus treatment.
2. Every edge is one continuous logical pixel with `border-box` geometry.
3. Child backgrounds are transparent at the outer corners and internal dividers are inset.
4. Clipping is required by content, not used to conceal a border defect.
5. Focus rings are complete, visible, and not clipped by an ancestor.
6. Hover and pressed states do not resize, translate, or expose a seam.
7. First and last menu rows respect the owning surface corners.
8. Media, overlays, and status layers share the same clip radius.
9. Light, dark, 200% text, browser zoom, standard DPI, and high DPI remain intact.
10. Desktop and H5 screenshots are reviewed before a visual baseline changes.

## Pull Requests

- Explain the ownership/layer decision and public compatibility impact.
- List contract, token, scenario, platform, accessibility, docs, and test changes.
- Include before/after screenshots for visual changes at desktop and mobile widths.
- Record remaining platform differences as explicit support states, not percentages.
- Keep unrelated refactors and generated churn out of the change.
