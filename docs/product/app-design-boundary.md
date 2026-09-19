# App and Design System Boundary

Date: 2026-09-14, with Round 5 additions on 2026-09-15. Scope: this kit (Vue, Flutter, SwiftUI, Compose) and the five flare-social reference apps. Evidence: the friction log (`design-system-friction.md`), the golden app record (`golden-app.md`), the Round 5 product audit (`product-refinement-audit.md`) and the fixes made in Rounds 0 to 5 of the reference-app program.

## 1. The rule

Apps own data, orchestration, routes and product decisions. The kit owns every reusable IM surface, the interaction model of those surfaces (which controls exist, how they confirm and give feedback), the overlays they open, and the tokens they draw with. The core SDK owns product-neutral IM behaviour. Nothing crosses these lines in either direction.

## 2. Ownership

| Concern | Owner | What it looks like | Evidence from the program |
|---|---|---|---|
| IM behaviour: send, sync, ordering, message action rules, reaction snapshots | Core SDK | Ops such as `message.action_availability`, `message.add_reaction`, `conversation.set_pinned` | The Android app now asks the core which actions a message allows instead of hard-coding "recall on my messages". |
| Mapping core JSON to kit models | App, once per app | One mapper per app: status, identity, content, reactions | Tauri mapped proto status 4 (failed) to "read"; the native apps showed every message as sent and read media from keys the core never emits. All fixed in the mapper, not in components. |
| Routes, navigation state, deep links | App | Route state in the shell, web router | Android route state stays in `FlareSocialApp.kt`; the kit only honours system back for the surfaces it draws. |
| Page composition | App | Which kit components a screen places, and in what layout | `ChatArea.vue` composes header, timeline and composer; it holds no generic markup. |
| Generic IM UI: rows, bubbles, timeline, composer, header, member rows, sheets, menus | Kit | Components with props, events and slots | Web conversation rows now come from `FlareConversationList`; no app renders its own row. |
| Interaction model: which controls appear | Kit | A control whose intent nobody handles is not offered | Vue `MessageList` masks menu, toolbar and reaction pills by the host's listeners; native callbacks are nullable and a null callback draws no control. |
| Feedback: confirm, toast, busy, retry | Kit | `useFlareConfirm`, `useFlareToast`, rendered by `FlareUiProvider`; `FlareToast.show` and `FlareDangerConfirm.show` on Flutter; `FlareFeedback` on iOS; `FlareToastHost` and `DangerConfirm` on Compose | Web and Tauri deleted their toast hosts; in Round 3 Flutter, iOS and Android deleted theirs when each kit gained a presenter. |
| Overlay presentation: sheet, dialog, drawer | Kit decides, app may ask for a drawer | `presentation` on `FlareBottomSheet` and `FlareFormSheet`, from the platform's `bottomSheet` capability | Tauri's desktop forms were bottom sheets at 1440 px; they are dialogs now, and its settings, privacy, search and profile panels are drawers. |
| Lifecycle projection: recalled, edited, failed | Kit renders, app maps | The app sets the lifecycle; the kit decides what a recalled row looks like | Native bubbles ignored `mutation = recalled`, and the core keeps recalled content, so three apps showed recalled text. The kit now draws the notice. |
| Platform capability: back, pickers, share, safe area | Kit contract, host adapter | `spec/platform-contract.json`, `flarePlatform()` | Compose screens now route system back to their back control when the host declares `nativeBack`. |
| Copy | Kit for generic affordances, app for product actions | Kit strings for "你撤回了一条消息"; app text for "删除会话" confirmation | Recalled notice strings live in each kit's string table; confirmation copy stays in the app that knows the consequence. |
| Visual values | Kit tokens only | Colours, spacing, radius, type, motion | `scripts/check-kit-reference.mjs` counts visual literals in all five apps; every count is 0. |

## 3. The decision test

When an app needs UI the kit does not offer, ask: would another complete IM app need the same thing?

- **Yes:** it belongs in the kit. The app workaround is deleted in the same change, and the consumer gate keeps the app compiling against the new API.
- **No:** it stays in the app, built only from kit primitives and tokens.

Decisions taken with this test:

| Need | Test result | Where it went |
|---|---|---|
| Confirm before a destructive step, with busy and retry | Every IM app | Kit presenter (`useFlareConfirm`); web and Tauri helpers deleted |
| Transient toast with a bounded queue | Every IM app | Kit presenter (`useFlareToast`) |
| One message identity for every intent | Every IM app | `resolveMessageId` and `findMessage` on `@flare-im/vue-ui/contracts` |
| Tap a reaction to toggle your own | Every IM app | Reaction pills in the kit bubble on all four platforms, interactive only when the host handles reactions |
| Recalled message notice | Every IM app, defined by the lifecycle spec | Kit bubble on Compose, SwiftUI and Flutter |
| Mapping flare-proto status codes to a receipt | Every Flare app, but the kit must not know SDK codes | App mapper today; recorded as an SDK gap (the core should project it once) |
| Moments feed, friend requests, reports | Social product features | App composition over kit components (`FlareMomentCard`, `FlareMomentComposer`, form sheets) |
| Archive action on conversation rows | Only apps with an archived view | App passes the `capabilities` it supports; web leaves archive out |
| Report a message | A social product action, but every IM app adds actions of its own | Kit extension point (`actions` on `FlareMessageList`, placed before Delete and gated per message); the app supplies Report and who may see it |
| Conversation action names | Every IM app | One `FlareConversationAction` vocabulary in the kit; Tauri's two translation maps were deleted |
| Scannable personal QR code | Every IM app that adds friends by code | Kit encodes and renders the code; the app fetches the token; without a token the kit shows an unavailable state, never a look-alike |
| Numeric join policy codes | Every Flare app, but they are SDK codes | App mappers own the numbers; the kit takes `FlareGroupJoinPolicy` (open, approval, invite) and shows an unknown policy as not set (Round 4) |
| New, more and context menus | Every IM app | Kit `ActionMenu` over the shared action descriptor; the Tauri menu sheet, the Android overflow menu and the iOS toolbar menu were deleted (Round 4) |
| A group report entry and the announcement read status | Every IM app with groups | App content in the kit's group detail slots (`after-info`, `footer`); the kit places it, the app owns the report flow |
| Connection state copy and the way back after a kick or an expired session | Every IM app | Kit connection notice (`connectionNotice`, `flareConnectionNotice`, `FlareConnectionNotice.resolve`) gives copy, tone and recovery; kicked and expired always offer 重新登录; the app logs the core's technical reason instead of showing it (Round 5) |
| A text prompt (remark, group name, nickname) that stays open when the save fails | Every IM app | Kit prompt and confirm presenters (Flutter `FlareDialog.prompt`, SwiftUI `FlareFeedback.prompt`, Compose `FlareDialogState`, Vue `useFlareConfirm` and `FlareFormSheet`); the apps' hand-built single-input dialogs moved to them (FR-092, Round 5) |
| Platform back closes the innermost open layer | Every IM app | Kit layers claim the platform back while open (`useFlareNativeBack`); the web host opts in with `createWebPlatformAdapter({ historyBack: true })`; routes stay in the app (Round 5) |
| Which contact, profile and moments controls exist | Every IM app, but the relationship is app data | The kit draws an intent only when the host handles it; the app decides the relationship by the handlers it binds, so a stranger gets no friend-only actions and no app has call buttons without calls (Round 5) |
| A person's public handle | Every IM app | Kit `flareId` on contact and profile models; the app passes the handle the user chose and never the account id (Round 5) |
| Mentions | Every IM app | The kit inserts `@display name`, keeps the picker keyboard model and highlights mention spans; the core resolves names to users. The core dropping name mentions is SDK gap S14, patched in neither the kit nor the apps (Round 5) |
| Reading width on wide panes | Every IM app | `FlareScreen` `readable` with the `--flare-component-screen-reading-width` token (Round 5) |
| Rich-text send request, pinned-message list, presence lookups | Core contract | Apps normalise rich text through `rich_doc_v2.normalize_from_markdown` (S19); the pinned bar shows the pinned messages the app has (S20); failed web presence lookups show nothing (S21). No kit workaround (Round 5) |

## 4. What an app must not do

1. Import kit internals. Apps use the published entries only (`@flare-im/vue-ui`, `/components`, `/composables`, `/contracts`, `/theme`, `/i18n`, `/utils`, `/icon-glyphs`, `/style.css`; `package:flare_im_ui/flare_im_ui.dart`; `FlareIMUI`; `com.flare.im.ui`). Gate: `check-kit-reference.mjs` (`deepKitImport`, `privateKitImport`).
2. Write visual literals. Gate: the same script (`styleVisualLiteral`, `colorLiteral`, `material3Visual`).
3. Re-implement a kit surface: rows, bubbles, menus, sheets, confirm, toast. Found by review and the consumption census in `app-component-consumption.md`.
4. Style kit internals with `:deep` or kit class selectors. Counted by the metrics in `design-quality-report.md`.
5. Offer a control it does not handle. It passes only the intents it wires; the kit hides the rest.
6. Show internal information: account ids, endpoints, tokens, sequence numbers or raw error strings. Product copy says what failed; the technical reason goes to the log (X22, Round 5).
7. Report success or an empty list when an operation failed. A failed load shows the kit error state with retry; a failed write keeps its dialog open with the error (X7, Round 5).
8. Count a feature as complete because the test fixture core answers it. The web fixture proves wiring only; server behaviour needs a real SDK path and, for signed-in flows, external validation.

## 5. What the kit must not do

1. Import or depend on any SDK package. Components take plain data and emit intents.
2. Encode SDK codes (proto status numbers, op names) or product business rules.
3. Add an API that exists for one app. "Another IM app" is the bar for every addition.
4. Render a control whose intent has no handler, or a clickable element that is not a real control: a name, avatar, comment row or cover is plain content unless the host handles it (Round 5).
5. Remove or rename a public symbol without the consumer gate: `tooling/check-reference-app-consumers.mjs` runs in `npm run check`, and the `social-*` compile gates run in `npm run release:check`.

## 6. When the boundary is unclear

1. Log the friction with its app task, workaround and root cause (`design-system-friction.md`).
2. Classify it as APP, DESIGN_SYSTEM, SDK, PLATFORM, TEST or DESIGN.
3. For kit-shaped problems, fix the kit, delete the app workaround in the same change, and validate in isolation (unit, component and visual tests) and in the golden app.
4. For SDK-shaped problems, record the gap and keep the app workaround as small and as named as possible; do not move it into the kit.
