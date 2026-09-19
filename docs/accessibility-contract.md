# Accessibility Contract

Status: Phase 4 baseline. Accessibility metadata in `spec/components.json` is authoritative and validated by `spec/validate.mjs`.

## Required metadata

Every component that exposes an event is interactive and declares `role`, `labelRequired`, `focusable`, `keyboardBehavior`, `touchTarget`, `reducedMotionBehavior`, and `screenReaderSemantics`. The empty `spec/accessibility-baseline.json` is a ratchet: new omissions fail validation and resolved debt cannot be silently reintroduced.

## Target size

A finger hits an area, not a border box, so the rule is about the **hit area**, not the drawn control:

- On a coarse pointer every interactive target has a hit area of at least **44 by 44** logical pixels (`--flare-size-layout-touch-target-min`). The floor is applied once, in `design-system/styles/accessibility.css`, under `@media (pointer: coarse)`; a control that is deliberately smaller on desktop scopes its own height to `@media (pointer: fine)`.
- `--flare-size-layout-touch-target` (48) stays the size of the primary touch rows the layout is built on — list rows, sheet actions, the composer's own keys. It is the design target, not the floor.
- A text field is tapped through the box that focuses it, so the field's wrapper is what has to clear the floor.
- The `touchTarget` block each component carries in `spec/components.json` records that 48 design target. The 44 floor is the enforced minimum and is checked by test, not declared per component.

Until 2026-09-13 this section claimed a flat 48 by 48 minimum. Nothing measured it and 39 targets on the phone layouts were below it, several of them 13 to 18 pixels. The rule above is the one that is enforced: `website/tests/accessibility-touch-targets.spec.ts` probes the corners of the 44 by 44 square centred on every interactive element across the mobile previews and fails on anything a tap would miss. A number that is checked on every run is worth more than a larger number that was never true.

Labels are localized human-readable text. Raw format IDs, icon names, enum values, and protocol values are not acceptable labels. Decorative icons are hidden from assistive technology; status is conveyed by text or semantics in addition to color.

## Focus indicator

键盘焦点的指示物必须**自己**达到 WCAG 2.4.11 的 3:1 —— 它是唯一的可见线索，不能靠旁边的东西凑。

- 焦点轮廓 / 边框一律用 **`--flare-color-border-selected`**（原生三端 `colors.borderSelected`）。
- **`--flare-color-focus-ring` 是柔光，不是环。** 它是 35–40% 透明度的品牌色，只能做 `box-shadow`（外发光），而且必须紧挨着一个实色环；单独做 `outline` 是不合格的。
- 两个例外，都记在门禁里：覆盖在任意媒体之上的控件（图片查看器、通话 chrome）用 `white`；跟随语义色的表面（状态横幅、投票气泡）用 `currentColor`——它就是该处的正文色，本来就要过 4.5:1。

为什么是 `border-selected` 而不是 `primary`：逐主题实测 7 套主题 × 明暗 14 组，对各自的 `bg.primary` 算对比度。

| 取色 | 最低 | 最高 | 3:1 |
|---|---|---|---|
| `border-selected` | 3.30（forest 浅色） | 9.02（forest 深色） | 14/14 通过 |
| `primary` | 1.80（ocean 深色） | 7.58（graphite 浅色） | 7 个浅色过，**7 个深色全不过** |
| `focus-ring` | 1.47（forest 浅色） | 2.97（forest 深色） | **14 组全不过** |

2026-09-13 之前四端共有 43 处焦点轮廓取的是后两者（Vue 51 条声明、原生 10 处）。axe 扫不出焦点指示的对比度，所以 P0-7 的 191 个面全绿也没暴露它。现在由 `tooling/check-accessibility.mjs` 守着：Vue 侧校验每一条 `outline` 的取色，原生侧校验任何带 `focused` 的取色行，两侧都做过反向验证。

## Platform contract

| Platform | Focus and keyboard | Screen reader | Reduced motion |
|---|---|---|---|
| Vue | Native elements first; `focus-visible`; Enter/Space and Escape where applicable | ARIA names, roles, values, live regions | `prefers-reduced-motion` removes non-essential animation |
| Flutter | Public `FocusNode` where hosts coordinate focus; traversal follows visual order; `Shortcuts`/`Actions` for desktop | `Semantics` uses localized labels and button/toggle/value state | `MediaQuery.disableAnimations` yields static progress or zero-duration transitions |
| Compose | Material controls first; custom click targets provide role, `onClickLabel`, selected state, and focus semantics | Content descriptions are localized; decorative icons use null descriptions | Custom motion is removed or resolved immediately when reduced motion applies |
| SwiftUI | Native controls first; focus returns after overlays and sheets | Localized labels, values, traits, grouped content, and VoiceOver announcements where state changes demand it | `accessibilityReduceMotion` disables non-essential animation |

## Ownership

The component library owns roles, hit targets, state semantics, and default traversal. The host owns product wording, route-level focus restoration, and privacy-sensitive announcements. Native system dialogs, text entry, and platform assistive behavior remain native.

## Validation

`node spec/validate.mjs` validates contract completeness and the accessibility ratchet. `node tooling/check-accessibility.mjs` holds the source-level rules: every naive icon in the Vue package declares `aria-hidden` or `aria-label` (an `<i role="img">` without a name is an axe `role-img-alt` violation on every screen that shows it), and the four icon implementations stay decorative by default.

Two Playwright suites carry the measured half, both run by `npm run release:check`:

| Suite | What it proves |
|---|---|
| `website/tests/accessibility-axe.spec.ts` | axe-core over every catalog component's embedded preview (desktop + mobile) and the reference application: zero Critical, zero Serious. Reports land in `website/test-results/axe-*.json`. |
| `website/tests/accessibility-touch-targets.spec.ts` | the 44 by 44 hit area above, probed on every mobile preview. |

Component previews are fragments, not documents, so the sweep switches off the page-level rules (`region`, `landmark-one-main`, `document-title`, `html-has-lang`, `page-has-heading-one`, `bypass`) — those belong to the host page. The reference-application pass runs them all.

Platform tests cover high-risk primitives and desktop focus paths. Source scans in the quality-gate phase prevent raw labels and missing reduced-motion policies from expanding.
