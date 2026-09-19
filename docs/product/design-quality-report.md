# Design Quality Report

Date: 2026-09-16, end of Round 5 of the reference-app program. Scope: this kit on four platforms and the five flare-social reference apps.

This report measures quality from three angles:

- **Gates:** does the kit hold its own contracts?
- **Consumers:** do real apps compose the kit rather than work around it?
- **Product review:** is the result a good IM product?

Round 5 added a fourth question, which the first three had been answering by proxy: **is the feature matrix true?** It was re-graded from the source of all five apps and both layers rather than from the previous round's notes, and the re-grade found defects the earlier passes had missed — media that never opened on Tauri, timelines that opened at the oldest message on two native kits, a group mute that wrote a field the server ignores. Those are in section 9.

## 1. Kit gates

| Gate | Result | Command |
|---|---|---|
| Design-system gates | **39 of 39 pass at Round 6** (which added `check-ui-reuse`, rotted outside every npm script until then); the list has grown since — 47 at Round 13 | `npm run check` |
| Spec validation and signature drift | 150 contracts; vue 150, flutter 147, ios 148, compose 148 implemented; **0 missing props, 0 missing events, 0 extra events on all four platforms**, with an empty `signature-baseline.json` | `node spec/validate.mjs`, `node spec/signature-report.mjs --json` |
| Public component exports | 593 platform component surfaces reachable | `node tooling/check-public-exports.mjs` |
| Dead components, strict | Vue 303/303 source files reachable; Flutter 162/162, iOS 152/152, Compose 157/157 public components live; 161/161 website demos live | `node tooling/check-dead-components.mjs --strict` |
| Duplicate components, strict | 20/20 register entries closed; 150 distinct Vue sources for 150 catalog components | `node tooling/check-duplicate-components.mjs --strict` |
| Accessibility contract | 133 interactive contracts, 196 icon tags named or hidden, 76 focus outlines on a solid 3:1 token, 11 native focus rings on `borderSelected`, 10 hover transforms that keep the box still | `node tooling/check-accessibility.mjs` |
| Reference app consumers | Web 234, Tauri 279, Android 272 kit imports resolve; Flutter 241 identifiers resolve; iOS 19 files free of 15 removed symbols | `node tooling/check-reference-app-consumers.mjs` |
| Icon registry parity and bypass ratchet | 105 names in the same order on four platforms, each with a glyph (Round 9 added six of the fifteen nominations); kit-internal glyph references vue **148** (from 149), flutter **175** (from 221), ios **76** (from 116), compose **170** (from 182) | `node tooling/check-icon-registry.mjs` |
| App kit-reference ratchet | Every count 0 on all five apps, including `platformGlyph` **0 / 0 / 0** on Flutter, iOS and Android (from 60 / 48 / 32) | `node examples/apps/scripts/check-kit-reference.mjs` |
| Hard-coded CJK literals in kit sources | Vue 2, Flutter 222, iOS 5, Compose 112 — all at baseline, none raised by this round's new strings | `node tooling/check-hardcoded-strings.mjs` |
| Hard-coded visual literals equal to a token | Down and re-baselined: Vue 1210 → 1206, Flutter 313 → 308, iOS 427 → 409, Compose 787 → 773 | `node tooling/check-hardcoded-visuals.mjs` |
| Security boundary | 4 URL gates × 18 vectors, 3 raw-HTML sites, 2 self-navigating components, 1 scripted navigation site | `node tooling/check-security-boundary.mjs` |
| Website interaction, visual and accessibility suites | **146 of 146 pass**, including axe on every component preview in **both themes on both viewports, each overlay opened and scanned again** — 406 scans (310 desktop, 96 mobile), 0 critical and 0 serious — axe on the reference application, and touch targets | `npm run test:website` |
| Vue unit and component tests | **987 pass** (Round 8); `vue-tsc` 0 errors; 193 SFCs compile | `npm --prefix packages/vue-im-ui test` |
| Flutter kit | **1207 tests pass** (Round 8); `flutter analyze` 0 issues (always `--no-pub`; the three lock files are unchanged) | `packages/flutter-im-ui` |
| SwiftUI kit | **513 tests pass** (Round 8) | `swift test` in `packages/ios-im-ui` |
| Compose kit | **378 unit tests pass** (Round 8) in both the debug and release variants; instrumented tests compile and have never run (no emulator on this machine), so the one assertion about where a located row lands is an external step, not a result | `./gradlew test` in `packages/android-im-ui` |

Two notes on how to read a green suite. First, the website suite is load-sensitive: a run alongside a Gradle build reported 9 failures (three axe scans, five screenshots, one behaviour test) and every one of them passed alone, with the full suite green minutes later on an idle machine. Second, the kit gates do not run the apps' own unit tests, which is how the web app's suite could sit at 25 failures while every gate stayed green (section 9). Both traps are written down in `docs/testing-and-quality-gates.md`.

## 2. Reference apps

| App | Build and tests | Kit-reference gate |
|---|---|---|
| Web (golden) | `vue-tsc` 0 errors; **77 unit tests**; **55 application-visual specs** against the in-memory fixture core, including 12 screenshot baselines and 3 performance probes | naive-ui 0, deep kit imports 0, vendor glyph imports 0, visual literals 0 |
| Tauri (desktop parity) | `vue-tsc` 0 errors; `vite build` succeeds | naive-ui 0, deep kit imports 0, vendor glyph imports 0, visual literals 0 |
| Flutter (parity) | `flutter analyze` 0 issues; **93 tests** | Material visual widgets 0, colour literals 0, legacy theme 0, **platform glyphs 0** |
| iOS (second reference) | `swift build` and an iOS Simulator `xcodebuild` succeed; **16 pure-rule harness checks** | bespoke primitives 0, colour literals 0, **platform glyphs 0** |
| Android (parity) | `:app:compileDebugKotlin` succeeds with its JVM-harness tests | Material 3 visual widgets 0, colour literals 0, **platform glyphs 0** |

Not verified: a signed-in session in any app. Signing in needs credentials, which this program does not enter, so every runtime claim about the apps comes from code, unit tests, kit tests, simulator builds, or browser harnesses that run the same app against a fixture core. The steps that need a real backend, a device or a person are listed, with pass criteria, in the final report's External Validation Steps.

## 3. Consumption

Census over the five social apps (`app-component-consumption.md`, Round 5 update):

| Measure | Count |
|---|---:|
| Catalog components | 150 |
| Referenced by at least one social app | 78 |
| Referenced by all five | 34 |
| Tauri | 65 |
| Web | 50 |
| Flutter | 50 |
| iOS | 47 |
| Android | 45 |

Round 5 did not chase this number: a kit component with no consumer is not a defect, and inventing a consumer to raise the count would be. What Round 5 did change is how the apps reach the kit. Every public icon field on the three native kits now takes a semantic name, so no app names a platform glyph any more, and the two ratchets make that irreversible without a visible baseline change.

Style hatches: web `:deep` 0 and `!important` 2, Tauri `:deep` 4 and `!important` 0, with no selector reaching into kit internals (`design-system-escape-hatches.md` section 3c).

## 4. Product review of the golden app

Scores from the frontend-design audit (1 to 10). Round 1 is the live sign-in flow plus the kit reference composition; Rounds 2 to 4 re-scored dimensions where code and harness evidence changed. Round 5 is the first round scored against **the app running at every width** — the audit pass (PASS 1) and the end-of-round score both come from `tests/app-visual`, where an in-memory fixture core replaces the wasm social core at its module boundary, `src/` is untouched, and nothing signs in.

| Dimension | Round 1 | Round 2 | Round 3 | Round 4 | R5 audit | R5 end |
|---|---:|---:|---:|---:|---:|---:|
| Product fit | 5 | 6 | 7 | 7 | 7 | 8 |
| Task clarity | 6 | 7 | 8 | 8 | 7 | 8 |
| Information architecture | 6 | 7 | 7 | 7 | 6 | 8 |
| Hierarchy | 7 | 7 | 8 | 8 | 7 | 8 |
| Layout | 5 | 7 | 7 | 7 | 6 | 8 |
| Typography | 7 | 7 | 7 | 7 | 7 | 7 |
| Color | 7 | 7 | 7 | 7 | 7 | 8 |
| Spacing and density | 7 | 7 | 7 | 7 | 6 | 7 |
| Component consistency | 6 | 8 | 8 | 8 | 7 | 8 |
| State completeness | 4 | 6 | 7 | 7 | 6 | 8 |
| Responsive behavior | 5 | 7 | 8 | 8 | 5 | 8 |
| Accessibility | 6 | 7 | 8 | 9 | 7 | 9 |
| Product character | 6 | 6 | 6 | 6 | 6 | 7 |
| Anti-template restraint | 8 | 8 | 8 | 8 | 7 | 9 |
| Implementation consistency | 5 | 6 | 7 | 8 | 7 | 9 |

The audit column is lower than Round 4 on six dimensions, which is the point of scoring the running app: harness pages had been hiding a squeezed chat between 600 and 767 px, a full-screen search takeover on desktop, and settings rows that looked like buttons. Per-dimension evidence is in `golden-app.md`.

Performance on the running app, against the fixture core's scale scenario (1,000 conversations, 5,000 messages):

| Probe | Measured | Budget |
|---|---:|---:|
| 120 incoming messages, first event until the last is on screen in the open 5,000-message timeline | 2.0 s | 8 s |
| Typing 14 characters while 40 messages arrive | 213 ms | 4 s |
| Global search over 1,000 conversations | 16 to 47 ms | 3 s |
| Website `@perf` budget: mounting 5,000 messages | 704 ms | 6 s |

These were re-measured on 2026-09-16 (Round 6) after two defects in the scene itself: the deep conversation's 5,000 messages were shadowed by a one-message seed, so the probes ran against a shallow timeline, and the burst was sent to a conversation that was not open — the assertion passed on the conversation row's preview text. With the scene fixed the burst measures about 2.0 s instead of 317 ms; it is the same code, measured honestly for the first time.

The budgets are loose on purpose: they catch a pathological regression (the kind that turned a 1.1 s timeline mount into 7.2 s), not milliseconds on a shared machine.

## 5. Cross-platform parity after Round 5

The Round 4 parity table still holds; Round 5 added these rows, each true on all four kits unless the cell says otherwise:

| Contract | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| The timeline opens at the newest message and follows the tail | yes | yes | yes | yes |
| Jump-to-latest with an unread count after scrolling up | yes | yes | yes | yes |
| Copy is offered only where there is text to copy | yes | yes | yes | yes |
| Text links reach the host (`onOpenLink`) | yes | yes | yes | yes |
| A link with no host handler opens through the safe-URL gate | browser anchor (markdown-it `validateLink`) | **no URL launcher** (registered platform gap) | `openURL` | `LocalUriHandler` |
| Public icon fields take a semantic name | yes | yes | yes | yes |
| An unknown icon name draws the fallback and warns once | yes (dev) | yes (debug) | yes (DEBUG) | yes (debug) |
| Settings rows: `navigation`, `toggle`, `action`, read-only `value` | yes | yes | yes | yes |
| A group setting that could not be read renders as "unavailable", not "off" | yes | yes | yes | yes |
| One pane below navigation + list + a usable chat (752) | yes | yes | yes | yes |
| The shell reports the presentation it uses (`layoutChange`) | yes | yes | yes | yes |
| Default navigation labels come from the strings table | yes | yes | yes | yes |
| Inline emoji-pack tokens render in a text body | yes | yes | yes | yes |

Deliberate differences, recorded rather than smoothed over: Flutter draws an inline sticker token as the pack's **first frame** (a line of text can carry dozens of them, and animating each costs far more than it says); `DesktopAppShell` reports a layout only on Vue and Flutter, because the iOS and Compose shells arrange no panes of their own.

## 6. States, responsive behaviour and accessibility

New in Round 5, in the golden app and mirrored where the parity apps have the same screen:

- **History:** older pages load past the local store through `sync.conversation_history_backfill`, stop at the first message, and a failed backfill keeps the history open with a retry instead of claiming the conversation starts there.
- **Connection:** connecting, reconnecting, offline, disconnected, kicked and expired each have their own copy and recovery, above every tab, on five apps.
- **Failed writes:** a failed remark, group name, description or setting keeps its dialog open with the draft and the error.
- **Unknown settings:** a group mute or pin that could not be read renders as 暂时无法读取 rather than a switch that claims "off".
- **Layout:** one pane below 752 px on four kits, with the chat's back control driven by the shell's report rather than an app's width guess.

Responsive behaviour is now reviewed on the running app at 320, 360, 375, 390, 430, 700, 768, 1024 and 1440, in light and dark, with 12 application-visual baselines held to an absolute 120-pixel tolerance in a deterministic scrollbar environment.

Accessibility in Round 5: the timeline takes one Tab stop with arrow-key navigation inside it; a read-only settings row is not a button and reads as one "label, value" element on all four kits; the identity card and the QR button are separate named controls; every icon-only control in the kit is named.

## 7. Friction log status

110 entries (`design-system-friction.md`): 12 P0, 67 P1, 31 P2.

| Status | Count |
|---|---:|
| Fixed | 83 |
| Partial | 3 |
| Open | 22 |
| Re-triaged | 2 |

Every P0 is fixed. The three partials are FR-044 (Chinese contact indexing below Android 10), FR-095 (the rest of the shell contract) and FR-102 (behaviour counters in the gate, deferred with a reason). They and the open entries are named with what remains; the two re-triaged entries are FR-093 (the boundary conflict belongs to the SDK owner, not to a kit workaround) and FR-094 (P2, deferred with a written reason rather than a speculative refactor).

## 8. System changes proposed

Only two this round, both already landed as component tokens rather than kit-class overrides: `--flare-component-sheet-dialog-width` (a host that needs a wider centred panel, such as search, changes the token) and `--flare-component-screen-reading-width` (the reading column on full pages).

Fifteen semantic icon names were nominated by the three native migrations and none was added in Round 5: a name enters the registry on four kits at once and only with a real consumer on each. Round 9 decided the whole set by one rule — a concept gets its own name only if it is drawn today under a name that means something else, and a real screen draws it — and accepted six (`pin-self`, `diagnostics`, `card`, `id`, `join-request`, `storage`) and refused nine; the reasons are in `docs/design/icon-coverage.md`.

## 9. What the re-grade found that the audits had missed

The matrix re-grade (five read-only passes over app and kit sources, one per app) is the reason this round's defect list looks different from Round 4's. Three examples, each a P0 that four earlier audit passes had graded as working:

- **Tauri media never opened.** The app used `media.resolve_access`'s *source kind* as if it were a URL, so every received image, video, voice note and file resolved to a string like `remote`.
- **Two native timelines opened at the oldest loaded message** and did not follow new ones — the single most visible behaviour in a chat app, and both kits had passing tests that asserted widget order rather than what is on screen.
- **Flutter group mute wrote a field the server ignores.** The row sheet and the group detail both looked like they worked.

The lesson recorded for the next round: an audit that reads a screen tells you what it draws, not what it does. Grading a feature means finding the op it calls and the failure it shows.
