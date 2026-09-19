# Website Productization Report

## Scope

This pass productizes the VitePress website, component preview system, cross-platform usage documentation, and developer experience. It does not change repository layout, token architecture, package boundaries, MessageStatus geometry, broad component design, or IM AppKit architecture.

## IA Audit

| Area | Current | Problem | Target | Reuse | Change |
| --- | --- | --- | --- | --- | --- |
| Top navigation | Guide, foundations, a mixed component menu, patterns, app kit, platforms, version menu | General UI and IM UI were hidden inside one menu; Resources was indirect | Guide, Foundations, Components, IM Components, Patterns, App Kit, Platforms, Resources | Existing routes and bilingual VitePress config | Promoted Components, IM Components, and Resources to direct destinations |
| Sidebar | 17 spec categories and 153 routes | Architecturally accurate but difficult to scan as a product catalog | Foundations, General Components, IM Components, Patterns, App Kit, Platforms | `spec/components.json` and `component-layers.json` | Added presentation-only groups, including Data Display and Group, without changing layer ownership |
| Catalog | Searchable table with category, layer, and platform filters | General and IM landing pages pointed users to a separate all-components table | Scoped, searchable catalogs at both entry points | Existing `ComponentGallery` and generated catalog | Added `general-ui` and `im-ui` scopes |
| Component pages | Bespoke Markdown followed by a duplicated contract appendix | Section order varied, preview coverage was uneven, and API/code/platform details were repeated | One generated product-page contract for every public stable component | Component spec, catalog metadata, curated examples, demos, token explorer | Replaced 306 bilingual pages with canonical routes rendered by `ComponentReference` |
| Preview | 129 dedicated Vue demo files plus several special frames | No shared toolbar; viewport previews used scaling in older helpers; platform preview was disconnected | Toolbar + real-width canvas + shared controls + synchronized platform state | Existing real Vue demos, shared scenarios, platform goldens | Added `ComponentPreview`, preview registry, and four grouped public-API adapters |
| State coverage | State tables and demo-local controls | Documentation state and preview state could drift | State selector sourced from component contract and shared RC scenarios | `spec/components.json`, `spec/scenarios/rc.json` | Unified state options and added concrete MessageStatus, ConversationRow, Composer, and grouped-surface adapters |
| Native previews | Real baselines existed outside the website | Platform support was text-only in component pages | Checked-in Flutter, Compose, and SwiftUI output beside code and notes | Existing golden and visual-regression PNGs | Added build/dev serving under `/flare-preview-baselines/`; no mock screenshots |
| Code | Generated code groups plus curated examples in page Markdown | Platform selection did not synchronize with preview or notes | Vue, Flutter, Compose, SwiftUI tabs with one selected platform | `examples.mjs`, resolved catalog symbols, public package exports | Added synchronized code tabs and clipboard action |
| API and guidance | Generated Props/States/Events plus a second contract section | Duplication and inconsistent hierarchy | Fixed Overview through Related order | Component spec and accessibility contracts | API, interaction, keyboard, accessibility, tokens, and platform notes now render from shared data |
| Responsive behavior | Older dedicated preview helpers scaled iframes | Scaling did not exercise container policies | 390, 768, 1024, and 1280 px real container widths | Existing responsive component implementations | New preview canvas overflows internally and never uses `transform: scale` |
| Search | VitePress local search and catalog aliases | Strong base, but separate landing pages added navigation cost | Search remains global; catalog search is available at the point of entry | Existing local index and generated `searchText` | Preserved global search and embedded scoped catalogs |
| Mobile | Catalog handled filters but wide previews could threaten page width | Product preview controls and native images needed containment | Wrapping toolbar, internal canvas scrolling, no document overflow | Existing responsive VitePress shell | Added mobile toolbar rules and overflow browser tests |

## Product Page Contract

Every stable public component now uses this order:

1. Name, Status, Package, Platforms, Since
2. Overview
3. Preview
4. Examples
5. Variants
6. States
7. Responsive
8. Code
9. API
10. Interaction
11. Keyboard
12. Accessibility
13. Platform Differences
14. Tokens
15. Do / Don't
16. Related

The Markdown route contains only identity and the canonical renderer. This removes page drift while preserving discoverability and VitePress indexing.

## Preview Architecture

```text
spec/components.json + spec/scenarios/rc.json
                    |
                    v
            ComponentPreview
        /          |           \
real Vue demo   controls    platform selector
   |                            |
public API              checked-in native baseline
                                |
                    Flutter / Compose / SwiftUI
```

- Vue previews import actual exports from `@flare-im/vue-ui`.
- Native previews are copied from checked-in platform test output during website build.
- Platform selection drives Preview, Code, and Platform Differences together.
- Theme, light/dark, viewport, density, state, and isolated/context controls remain local to the preview and never reload the page.
- Responsive widths are real CSS widths, not scaled screenshots or scaled iframes.

## Preview Coverage

- 153 stable components are discoverable and bilingual.
- Existing dedicated demos remain the primary live source.
- Application composition, directory/moments, scene panels, and workbench layouts use grouped adapters that render real public components.
- `preview-registry.mjs` is the single mapping used by the website and coverage gate.
- MessageStatus exposes all, pending, sending, sent, delivered, read, failed, and retrying.
- ConversationRow exposes default, selected, unread, mention, muted, pinned, draft, typing, and failed.
- Composer exposes idle, replying, editing, uploading, offline, readOnly, and sendBlocked.

## Developer Experience

- `npm run check:website-productization` verifies canonical pages, section order, live preview coverage, shared controls, public code tabs, navigation groups, real native assets, and the no-scale responsive rule.
- The root design-system check includes website productization as a required gate.
- `website/scripts/gen-components.mjs` now owns canonical routes instead of preserving divergent hand-authored component pages.
- Curated integration examples remain in `website/scripts/examples.mjs` and are selected before generated fallbacks.
- Generated fallback snippets use platform symbols from `component-catalog.json` and the public package imports.

## Migration Notes

1. Add or update the component contract in `spec/components.json`.
2. Add a shared scenario in `spec/scenarios` when the state is behaviorally important.
3. Add a real Vue demo named `<Component>Demo.vue`, or register a grouped adapter in `preview-registry.mjs`.
4. Add or refresh native Gallery/golden output in the owning platform test suite.
5. Add curated multi-platform code only when the generated minimal usage does not teach the integration sufficiently.
6. Run generation, productization checks, website build, and Playwright tests.

## Remaining Boundaries

- The website does not embed Flutter Web; checked-in golden output is faster and avoids a second runtime.
- Native baseline images currently cover representative platform galleries rather than a separate screenshot file for every component. The label makes that scope explicit and never presents a hand-made web mock as native output.
- Density changes preview composition spacing. A cross-platform density token contract would be a separate token-architecture project and is intentionally outside this pass.
