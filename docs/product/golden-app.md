# Golden Reference Application

Date: 2026-09-14. Scope: the five flare-social example apps under `flare-social/flare-social-sdk/examples/apps` and this kit.

## Decision

| Role | App | Platform / kit package |
|---|---|---|
| Golden reference | `flare-social-web-app` | Browser, Vue 3, `@flare-im/vue-ui`, social core compiled to WASM |
| Second reference | `flare-social-ios-app` | SwiftUI, `FlareIMUI`, C FFI |
| Parity | `flare-social-tauri-app` (desktop, shares the Vue kit), `flare-social-flutter-app`, `flare-social-android-app` | Tauri + Vue, Flutter, Compose |

The kit's release criteria keep their own Golden Reference, `flare-core-web-app` (core IM contract, live SDK gate `web-live-sdk`). That app proves the core contract; this one proves product-shaped composition, social features included. Both are Vue.

## Why the Web app

Selection used three criteria: feature coverage, suitability for complete validation, and real SDK integration. Numbers come from `im-feature-matrix.md` and the audits behind it.

| App | Features C / P / M (of 135) | Automated full validation | SDK path |
|---|---|---|---|
| Web | 50 / 40 / 44 | Any viewport and theme in a browser; Playwright suite in `tests/` | Rust core as WASM |
| Tauri | 51 / 50 / 33 | Desktop runtime only; the frontend calls Tauri IPC directly, so it cannot run in a browser | In-process Rust binding |
| Flutter | 38 / 31 / 64 | Device or desktop build | C ABI, JSON dispatch |
| iOS | 36 / 48 / 49 | iOS Simulator | C FFI |
| Android | 34 / 51 / 48 | Emulator | JNA C FFI |

- **Coverage.** Web is within one complete feature of Tauri, and it is the only candidate whose whole surface (auth, shell, chats, contacts, moments, me, settings) runs in a browser.
- **Validation.** Every responsive width in the program (320 to 1440), both themes, keyboard and axe checks can be driven headlessly without a native toolchain. That is what "Application Context" validation of a kit change needs.
- **SDK.** The same Rust core runs in-page. Known WASM limits are SDK-level and recorded, not worked around: presence subscription is a no-op on web, downloads are URL-only, social caches are memory-only, and there is no `init(sdkConfig)`.
- **Why not Tauri.** Its core loop had three independent P0 mapping defects (fixed on 2026-09-14, see below) and it cannot be exercised outside the desktop runtime. It stays the desktop parity app and inherits every Vue kit change.
- **Why iOS second.** It is native mobile on a different kit implementation (SwiftUI), so it tests the contracts rather than the Vue code, and it can be driven in the simulator.

## Rules

1. A significant kit change is validated in the golden app first: `vue-tsc`, `tooling/check-reference-app-consumers.mjs`, and a browser pass at 390, 768, 1024 and 1440 in light and dark. Parity apps follow.
2. The golden app is a consumer. No kit code checks for it and no kit API exists only for it.
3. Generic IM UI found in the golden app is not left there: it is classified (APP, DESIGN_SYSTEM, SDK, PLATFORM) and, when it is kit-shaped, moved into the kit with the workaround deleted in the same change.

## Round 0 (2026-09-14): build restored and first P0s fixed

| Item | Class | Before | After |
|---|---|---|---|
| App did not compile or boot (removed kit symbols) | TEST, APP | `vue-tsc` 2 errors; blank page | Migrated to ConversationHeader and EmojiStickerPicker; boots to sign-in |
| Kit changes could break reference apps silently | TEST | No gate compiled or scanned the social apps | `check-reference-app-consumers.mjs` in `npm run check`; `social-*` compile gates in `release:check`; reverse-validated on the pre-migration sources (11 breaks reported) |
| Reactions and edits never reached the core | APP (P0) | Wrapper called `message.react` and `message.edit_text`, which do not exist; errors swallowed | `message.add_reaction` / `message.remove_reaction` (toggle on the user's own reaction) and `message.edit_text_by_message_id`, with a failure toast |
| One message had two identities in the kit | DESIGN_SYSTEM (P0) | MessageList used client id first; PinnedMessageBar and previews used server id first | `resolveMessageId` / `findMessage` on `/contracts`, used by every kit derivation; the golden app resolves intents through it |
| Emoji panel never opened | APP | `media-panel-open` never passed | Passed; kit choreography itself is still friction (see friction log) |

## Core IM loop

Status legend: VERIFIED-LIVE (exercised against the running backend), CODE (verified by reading code and type checks), BROKEN, PENDING.

| Step | State | Evidence and remaining gap |
|---|---|---|
| Conversation list | CODE | Rows map title, avatar, time, preview, unread, pinned, muted and draft. Row actions pin, mute, mark read or unread, clear and delete go through the core; clear and delete confirm; a failed refresh keeps the rows with a retry. |
| Open chat | CODE | Header, timeline, composer compose correctly; open marks read with a real `readSeq`. |
| Read messages | CODE | Status mapping follows the proto. Reply/quote, edited and pinned state are dropped by the message mapper; no unread divider or typing row (MessageList has no slots). |
| Compose | CODE | Text, reply, edit, rich text, file and image attach. The two app attach actions replace the kit defaults, hiding voice and rich entries. |
| Send | CODE | Optimistic send through the core. Failed messages show `failed` and retry re-sends the stored message (same client id). |
| Receive | CODE | Event-driven refresh of the active timeline. |
| Reply / reaction / action | CODE | Reply, reactions (toggle), edit, recall and delete work; recall and delete confirm. The menu offers only handled intents, so forward, pin, mark, preview, media and multi-select no longer appear as dead entries. |
| Unread / read | CODE | Unread counts and read receipts in single chats. @me counts are always 0 in the SDK (SDK gap). |
| Live pass | PENDING | Signing in needs a person: the reviewer does not create accounts or enter credentials. Sign in on the dev server with two befriended test accounts to unblock the signed-in pass. |

## First product review

Method: frontend-design AUDIT mode, ground IN-SYSTEM (every value must come from kit tokens and components). Inputs: the live sign-in flow at 375 and 1280; the kit's own reference composition (`examples/vue`, the same components the signed-in shell renders) captured at 390, 768, 834, 1024 and 1440 in light and dark at 2x; and a code review of the golden app's screen composition.

### Scores (1 to 10)

| Dimension | Score | Why |
|---|---:|---|
| Product fit | 5 | Broad social surface, but visible controls in the core loop do nothing. |
| Task clarity | 6 | List to chat is obvious; secondary actions are dead or hidden. |
| Information architecture | 6 | Chats, Contacts, Moments, Me are right; global search overlay renders in flow; detail logic is duplicated per breakpoint. |
| Hierarchy | 7 | Kit rows and bubbles separate title, preview and meta well; message times and dividers are missing. |
| Layout | 5 | Mobile duplicates list and detail markup; 768 px keeps three columns. |
| Typography | 7 | One kit scale throughout; sign-in title sits apart from its form on desktop. |
| Color | 7 | One accent, restrained; unread count uses red on the rail and purple on rows. |
| Spacing and density | 7 | Token-driven spacing; density is declared in the kit but not implemented. |
| Component consistency | 6 | A bespoke report dialog, an app-owned toast host, a form sheet used as a confirm. |
| State completeness | 4 | No retry, no upload progress, sticky toasts, errors swallowed, destructive actions without confirmation. |
| Responsive behavior | 5 | Tablet cannot reply or forward; mobile layout re-implemented in the app. |
| Accessibility | 6 | Kit contract is strong; the report dialog has no focus trap or Escape; attach tiles have no icons. |
| Product character | 6 | Calm and consistent; the sign-in page carries marketing and diagnostics copy. |
| Anti-template restraint | 8 | No gradients, glass or card inflation. |
| Implementation consistency | 5 | Three time formatters, three debounce copies, three text extractors. |

### Findings

Each finding: problem, user impact, evidence, change, keep unchanged, validation. Class and status in brackets.

**P0-1 Conversation context menu offers eight actions and none are wired** [APP, FIXED in code, live check pending]
- Impact: pin, mute, archive, mark unread and delete silently do nothing.
- Evidence: row mapper sets no `actions`; the list has no `action` handler (`MainView.vue` list bindings).
- Change: wire the SDK operations that exist (`set_pinned`, `set_muted`, `set_archived`, mark unread, delete) and pass only wired actions through `item.actions`.
- Keep: row visuals and ordering.
- Validation: right-click and long-press each action in the browser; the row reflects the new state.

**P0-2 Failed messages cannot be retried** [APP, FIXED in code, live check pending]
- Impact: a failed send stays failed with a retry control that does nothing.
- Evidence: menu config enables `resend`; no `resend` handler on the list.
- Change: handle `resend` by re-sending the stored message (the core keeps its client id).
- Keep: failed styling from the kit.
- Validation: send with the gateway stopped, restart, retry.

**P0-3 Reply and forward unreachable on tablets** [DESIGN_SYSTEM, FIXED: also restores desktop forward; unit and browser tests]
- Impact: at 600 to 899 px the menu is a dropdown that omits reply and forward, and there is no hover toolbar.
- Evidence: kit `useMessageMenuInteraction.ts` tablet profile; `buildMessageMenuOptions.ts` dropdown filter.
- Change: include reply and forward in the dropdown whenever the hover toolbar is absent.
- Keep: desktop hover toolbar and phone sheet.
- Validation: kit test for the tablet profile; browser at 768 and 834.

**P0-4 Destructive actions run without confirmation** [APP + DESIGN_SYSTEM, FIXED in code with the kit's `useFlareConfirm`, live check pending]
- Impact: block, remove friend, dissolve group, remove member, recall and delete are one tap from permanent.
- Evidence: contact and group detail handlers call the SDK directly.
- Change: route through the kit's DangerConfirm with the action's target named.
- Keep: action placement.
- Validation: each action shows a confirm; cancel leaves state unchanged.

**P1-1 Copy is hidden for real messages** [DESIGN_SYSTEM, FIXED, unit-tested]
- Evidence: kit action availability reads only `content.data.text`; the core sends flattened content.
- Change: availability uses the same text extractor as the renderer.

**P1-2 Row state not mapped** [APP, PARTIAL] Pinned, muted and draft are mapped now; mention (always 0 in the SDK), typing and send failure are not.

**P1-3 Message mapping drops state** [APP, FIXED in Round 2] The mapper now passes the core's `isEdited`, `replyTo`, `quotePreview`, `textPreview`, `attributes` (pinned), `localState` (upload progress), `timelineKey` and `timelineSortTs`, with no invented timestamps; pending messages order by the core's timeline time and merge with their acknowledged copy by client id. The core key itself switches from client to server id on ack by design (`timeline_key_uses_server_id_after_ack`); that is recorded, not changed. Unit-tested (2 new tests).

**P1-4 Attach actions replace the kit defaults** [APP, FIXED in Round 3] The composer takes `capabilities.availableActionIds` (image, file), so the kit keeps its labels and glyphs; voice is reachable from the toolbar microphone because the app passes a voice handler.

**P1-5 Mobile shell re-implements list and detail** [DESIGN_SYSTEM, FIXED in Round 2] `activePane` on the Vue (and Flutter) IMAppKit renders the phone pane from the same `primary`, content and `detail` slots; the app and the kit example declare each pane once. Kit unit test; complete-app visual specs unchanged.

**P1-6 Global search overlay renders in flow** [DESIGN_SYSTEM, FIXED in Round 2, raised to P0 once proven] The overlay slot wrapper was `display: contents` in both shells; a harness showed global search placed inside the 112 px navigation column on desktop. The overlay region is now a layer over the shell (FR-070).

**P1-7 Toasts can stay forever** [DESIGN_SYSTEM + APP, FIXED] The kit now presents toasts (`useFlareToast`, bounded queue, auto-dismiss); the app's toast state, timer and host were deleted.

**P1-8 Sign-in page** [APP, OPEN] The desktop title is detached from the form column; marketing and diagnostics copy inside the form; English while the rest of the app is Chinese.

**P2 Consistency** [DESIGN, OPEN except times] Unread badge red on the rail and purple on rows; fallback avatars stay light in dark mode; a header "+" menu holding one item; three columns at 768 px. The 12-hour times with a leading zero are fixed in Round 3 (`formatMessageTime`).

## Validation protocol

From the monorepo root:

```bash
node flare-im-design/tooling/check-reference-app-consumers.mjs
npm --prefix flare-social/flare-social-sdk/examples/apps/flare-social-web-app run typecheck
npm --prefix flare-social/flare-social-sdk/examples/apps/flare-social-web-app test
```

Browser pass after sign-in: 390, 768, 1024, 1440 in light and dark; keyboard walk of conversation switch, message menu, composer send and dialog close.

## Round 2 (2026-09-14): native parity, feedback, and the rest of the golden app

Golden app changes in this round, each checked with `vue-tsc` (0 errors), the app's unit tests (13 pass), the kit-reference gate and the kit consumer gate:

| Item | Class | Before | After |
|---|---|---|---|
| Reaction pills | DESIGN_SYSTEM | Static counts; removing your reaction needed the menu | Pills toggle through `@react` (`aria-pressed`), display-only when the host does not handle reactions |
| Quick reactions | DESIGN | Alien, space invader, angry, thumbs up, heart, laughing | Thumbs up, heart, laughing, surprised, sad, celebrate on four kits |
| Phone layout | DESIGN_SYSTEM | List and detail declared twice | `activePane` (P1-5) |
| Message mapping | APP | Edit, reply, attributes and upload state dropped | Passed through (P1-3) |
| In-conversation search | APP (P1) | Jumps passed a server id that the timeline never matches, so every jump failed after paging history | Result ids use `resolveMessageId` (FR-069) |
| Report form | APP (P1) | Bespoke modal from `flare-social-vue-ui` with no focus handling | `ReportSheet.vue` composed from kit form components; harness-checked at 1440 light and 390 dark, including submit gating, payload and Escape (FR-068) |
| Contacts and moments confirmations | APP | Screen-held `FlareDangerConfirm` state; failures closed the dialog silently | `useFlareConfirm` with actions that throw, so failures stay in the dialog with retry |
| Global search placement | DESIGN_SYSTEM (P0) | Overlay content became a grid item inside the navigation column | Overlay layer over the shell; harness-checked at desktop and 390 px (FR-070) |

### Scores after Round 2

Re-scored only where code and harness evidence changed the finding. The live signed-in pass is still pending, so these are not a new live review.

| Dimension | Round 1 | Round 2 | Evidence |
|---|---:|---:|---|
| Product fit | 5 | 6 | Dead controls removed from the core loop; search jump, reaction toggle and group mentions work in code |
| Task clarity | 6 | 7 | Only handled actions are offered; destructive steps say what they do and to what |
| Information architecture | 6 | 7 | Global search opens over the workspace instead of inside the navigation column |
| Layout | 5 | 7 | Phone panes declared once; tablet details open as an overlay instead of breaking the grid |
| Component consistency | 6 | 8 | Report form, toasts and confirmations all come from the kit |
| State completeness | 4 | 6 | Retry, stale rows, confirmations with retry, upload progress mapped; typing, @me and read-by remain SDK-limited |
| Responsive behavior | 5 | 7 | Harness-checked at 390, 768, 1024 and 1440 |
| Accessibility | 6 | 7 | Report form gets kit focus and Escape handling; reaction pills expose pressed state; mention search takes focus |
| Implementation consistency | 5 | 6 | One identity rule across search, timeline and store; formatters still duplicated |

Also in Round 2: typing "@" in a group chat opens the member picker with the group's full roster (FR-013, web); tablet details open as an overlay instead of breaking the grid (FR-020).

Open for the golden app after Round 2: attach actions replacing kit defaults (P1-4, fixed in Round 3), the sign-in page (P1-8), and the live signed-in pass.

## Round 3 (2026-09-14): the remaining P1 friction

Golden app changes, each checked with `vue-tsc` (0 errors), the app's unit tests (13 pass) and the kit-reference gate. The new compositions were also mounted in a temporary browser harness inside the app at 1440 light and 390 dark (harness files deleted afterwards):

| Item | Class | Before | After |
|---|---|---|---|
| Desktop message menu | DESIGN_SYSTEM (P0) | Right-click and hover "More" picks did nothing: the kit listened for an event naive-ui never emits | Picks dispatch; in the harness Forward and Report both reached the app (FR-071) |
| Unread position | DESIGN_SYSTEM | No marker; the first unread message was unknowable | `unreadFromId` from the unread count at open; the divider starts a new sender run; label contrast fixed for dark mode (FR-006) |
| Timeline states | DESIGN_SYSTEM | The load-older strip doubled as first-load loading | `#empty` shows loading or an invitation to write; the strip only pages (FR-006) |
| Start of history | DESIGN_SYSTEM | "没有更多消息了" stayed over the first date separator of every conversation that fits on screen | Shown only after scrolling back through a longer history, then cleared (FR-073) |
| Message menu extras | DESIGN_SYSTEM | Report existed for users, groups and moments, not messages; copy was silent | Report on others' messages through kit `actions`; copy confirms or explains a refusal (FR-009) |
| Conversation actions | DESIGN_SYSTEM | Per-row snake_case action lists | `capabilities` on the list; one camelCase vocabulary (FR-016, FR-017) |
| Inbox search entry | DESIGN_SYSTEM | A secondary button labelled 搜索 | Read-only kit search bar, one button for assistive technology (FR-027) |
| Header | DESIGN_SYSTEM | Details as a separate primary icon | Tapping the avatar or title opens details; search shows as pressed while open (FR-055) |
| Global message search | DESIGN_SYSTEM + APP | Hits used their conversation id and never jumped; group hits opened a non-conversation id | Hits carry `target`; the chat opens at the message; groups open their conversation (FR-026, Appendix A 5) |
| Attachments | APP | Icon-less replacement list | Kit defaults through `capabilities` (P1-4) |
| Contacts | DESIGN_SYSTEM | Rebuilt checkbox rows in create-group; pending state written into signatures; blocked rows opened a destructive confirm on tap | Selectable kit list; outgoing requests with withdraw; a trailing Remove button on blocked rows (FR-029, FR-030) |
| Profile QR code | DESIGN_SYSTEM | A decorative matrix that could not be scanned | A real code from the QR token; checked with the browser's QR detector in light and dark (FR-031) |
| Sign-in labels | DESIGN_SYSTEM | Labels pointed at nothing | FormField wires label, hint and error into the inputs (FR-032) |
| Forms on desktop | DESIGN_SYSTEM | Bottom sheets at 1440 | Centered dialogs on pointer devices, sheets on phones (FR-023) |
| Times | DESIGN_SYSTEM | zh-CN or en-US only; 12-hour times with a leading zero | Locale formatters for rows, bubbles and moments (FR-033) |

### Scores after Round 3

Re-scored from code, unit tests and the harness; still not a live signed-in review.

| Dimension | Round 2 | Round 3 | Evidence |
|---|---:|---:|---|
| Product fit | 6 | 7 | Desktop menu actions work; reports cover messages; search hits and quotes jump; the QR code scans |
| Task clarity | 7 | 8 | Entry points describe themselves: a search field, an identity that opens details, a divider that says where new messages start |
| Hierarchy | 7 | 8 | The unread divider restarts the sender run, so the first unread message carries its avatar |
| State completeness | 6 | 7 | Separate loading and empty timeline states; copy feedback; group write failures surface (Tauri) |
| Responsive behavior | 7 | 8 | Forms and panels are dialogs or drawers on pointer devices and sheets on phones |
| Accessibility | 7 | 8 | Labels name their inputs; checkboxes in lists are named; toggles expose pressed state; divider text meets AA in dark mode |
| Implementation consistency | 6 | 7 | Shared time formatters; one conversation action vocabulary; the Tauri mapper no longer casts |

Unchanged: information architecture 7, layout 7, typography 7, color 7, spacing and density 7, component consistency 8, product character 6, anti-template restraint 8.

Still open for the golden app: the sign-in page (P1-8), the live signed-in pass, @me and typing (SDK), and the app's Playwright smoke spec (`tests/browser/auth-shell.spec.ts`). That spec registers accounts against a live backend, so it was not run here; its add-friend step still targets `.add-friend__row`, markup the kit contact list replaced before Round 0 [TEST].

## Round 4 (2026-09-14): menus and group detail

Checked with `vue-tsc` (0 errors), the app's unit tests (13 pass) and a temporary browser harness inside the app at 1440 light and dark and 390 dark (deleted afterwards).

| Item | Class | Before | After |
|---|---|---|---|
| Conversation row, header and message menus | DESIGN_SYSTEM | naive-ui dropdown options were plain elements: focus never moved into the menu and assistive technology heard no menu | Kit `ActionMenu`: a named menu whose items take focus with the arrow keys, Escape returns focus to the trigger, and phones get a sheet (FR-024) |
| Announcement read bar | DESIGN_SYSTEM | Showed "announcement.readCount" and "announcement.confirmRead" as text and offered "view unread" that did nothing | Localized copy; "view unread" only with a handler (FR-074) |
| Group detail placement | DESIGN_SYSTEM | Read bar above the group hero, report entry below the component | `after-info` and `footer` slots place both where they belong (FR-028) |
| Join policy | DESIGN_SYSTEM + APP | SDK numbers cast into the kit model; an unknown policy read as "允许任何人加入" | A typed policy; an unknown one reads "未设置" (FR-028) |

### Scores after Round 4

| Dimension | Round 3 | Round 4 | Evidence |
|---|---:|---:|---|
| Accessibility | 8 | 9 | Every menu in the golden app is a real menu for the keyboard and screen readers; the read bar speaks words, not message keys |
| Implementation consistency | 7 | 8 | One menu implementation behind every menu; no SDK codes left in the kit's group model |

Other dimensions are unchanged from Round 3.



## Round 5 (2026-09-15): the running app at every width

Round 5 reviews the golden app as it runs, not through harness pages. `tests/app-visual` replaces the wasm social core with an in-memory fixture core at its module boundary, so `src/` is unchanged, nothing signs in and no backend is involved. The fixture serves seven scenarios: default, empty, error, offline, send failure, long content, and 1,000 conversations with 5,000 messages.

- **Review captures.** `review-capture.spec.ts` writes 29 screenshots at 1440, 1280, 1024, 834, 768, 600, 390 and 320 px, light and dark. It runs only when `CAPTURE_DIR` is set.
- **Application tests.** `conversation-list.spec.ts` checks that the last of 1,000 conversations is reachable by keyboard and that rows keep the core's order.
- **Fixture data is for review only.** A feature seen working on the fixture is not recorded as complete.

PASS 1 found one P0 and seventeen P1 issues in the golden app, and the cross-app audit found more. All of them, with scores and the round plan, are in `product-refinement-audit.md`. Fixed during the audit:

| Item | Class | Before | After |
|---|---|---|---|
| Long inbox | DESIGN_SYSTEM | With 200 or more conversations, rows after about #37 could not be reached | Every row reachable by scroll and keyboard (FR-075) |
| Profile avatar | DESIGN_SYSTEM | The avatar picker was a clickable `div` | A named button; labelled fields (FR-076) |
| Row order | DESIGN_SYSTEM | The kit re-sorted pinned conversations first | Host order, which the core already sorts (FR-037) |

### Scores after the Round 5 audit

| Dimension | Round 4 | PASS 1 | Evidence |
|---|---:|---:|---|
| Task clarity | 8 | 7 | Mentions not highlighted; empty inbox without an action; full-screen search on desktop |
| Information architecture | 7 | 6 | Contacts, moments and me are single full-width columns on desktop |
| Hierarchy | 8 | 7 | Separator pills compete with messages |
| Layout | 7 | 6 | 600 to 767 px leaves the chat about 210 px wide |
| Spacing and density | 7 | 6 | Pill inflation |
| Component consistency | 8 | 7 | One concept, several glyphs |
| State completeness | 7 | 6 | Offline composer stays live; failed sends do not reach the row |
| Responsive behavior | 8 | 5 | The 600 to 767 band and the 1,000-row list |
| Accessibility | 9 | 7 | Three hover-toolbar tab stops per message; the avatar picker (fixed) |
| Anti-template restraint | 8 | 7 | Saturated hero on the me tab; gradient cover on moments |
| Implementation consistency | 8 | 7 | Icons bypass the registry |

Unchanged: product fit 7, typography 7, color 7, product character 6. The drop reflects new evidence from the running app at every width, not a regression.

### After Round 5 implementation (2026-09-16)

What the golden app gained, with the evidence behind each line: forward (merged and one message per send), multi-select with the batch toolbar, message pin with the pinned bar, file and image downloads, typing and 1:1 presence, drafts written to the core, a normalised rich-text send, message report, and older history that pages past the local store through `sync.conversation_history_backfill`; load failures show kit error states with retry and failed writes keep their dialog; sign-out, block and remove ask first; the session-end notice offers 重新登录 from every tab; the timeline takes one Tab stop with arrow-key navigation; full pages use a 720 px reading column; a window narrower than list + usable chat shows one pane with a back control; desktop search is a centred palette; settings rows tell information from actions. `product-refinement-audit.md` section 8b lists each change with its test.

| Dimension | Round 4 | PASS 1 | After Round 5 | Evidence for the Round 5 score |
|---|---:|---:|---:|---|
| Product fit | 7 | 7 | 8 | The core loop's actions are wired to real ops (forward, pin, download, drafts, backfill); mentions and the pinned list stay blocked by the SDK (S14, S20) |
| Task clarity | 8 | 7 | 8 | Search is a palette, not a takeover; the empty inbox has one call to action; connection states name their recovery |
| Information architecture | 7 | 6 | 8 | Reading column on 我, 圈子, 设置 and 通讯录; one pane below 752 px; group details reachable from the chat header |
| Hierarchy | 8 | 7 | 8 | Pinned messages are a 75 px bar, notices are quiet chips, the timeline outranks both |
| Layout | 7 | 6 | 8 | The 600 to 767 band no longer squeezes the chat; the composer's expanded tools are desktop-only |
| Typography | 7 | 7 | 7 | Unchanged this round |
| Color | 7 | 7 | 8 | Dark avatar tints, names on `primaryText`, focus ring on a 3:1 token |
| Spacing and density | 7 | 6 | 7 | Pinned bar and notices are compact; settings rows stack long values |
| Component consistency | 8 | 7 | 8 | 99 semantic icon names on four kits; one settings row renderer; kit menus everywhere |
| State completeness | 7 | 6 | 8 | Error, retry, offline, kicked, expired, failed write, unknown setting and end-of-history states are distinct and recover |
| Responsive behavior | 8 | 5 | 8 | 320 to 1440 reviewed; single pane below 752; batch toolbar scrolls on phones |
| Accessibility | 9 | 7 | 9 | One Tab stop in the timeline with arrow keys; every icon-only control named; read-only rows are not buttons; identity and QR are separate controls |
| Product character | 6 | 6 | 7 | The brand marks selection and primary actions only; the identity card replaced the brand banner |
| Anti-template restraint | 8 | 7 | 9 | Two brand-coloured surfaces removed, no new gradients or glows, dead "view details" buttons gone |
| Implementation consistency | 8 | 7 | 9 | Icons through the registry, drafts and history through core ops, no app-local copies of kit UI, dead diagnostics buffer removed |

### Performance on the running app (2026-09-16)

Three probes run against the fixture core's scale scenario (1,000 conversations, 5,000 messages) in `tests/app-visual/performance.spec.ts`, alongside the website's `@perf` budget for mounting 5,000 messages (704 ms against a 6 s budget):

| Probe | Measured | Budget |
|---|---:|---:|
| 120 incoming messages, from the first event until the last one is on screen in the open 5,000-message timeline | 2.0 s | 8 s |
| Typing 14 characters while 40 messages arrive | 213 ms | 4 s |
| Global search over 1,000 conversations | 16 to 47 ms | 3 s |

These were re-measured on 2026-09-16 (Round 6) after two defects in the scene itself: the deep conversation's 5,000 messages were shadowed by a one-message seed, so the probes ran against a shallow timeline, and the burst was sent to a conversation that was not open — the assertion passed on the conversation row's preview text. With the scene fixed the burst measures about 2.0 s instead of 317 ms; it is the same code, measured honestly for the first time.

The budgets are deliberately loose: they exist to catch a pathological regression (the kind that turned a 1.1 s timeline mount into 7.2 s in Round 5), not to track milliseconds on a shared machine. Not measured: media-heavy scrolling with real images, and anything that needs a server.

Not scored here: the four parity apps. Their state is in `im-feature-matrix.md` (Round 5 re-grade) and `product-refinement-audit.md` section 3.

Not verified: everything that needs a backend or a device. The scores above come from the app running on the in-memory fixture core, its unit and application specs, and the twelve application-visual baselines.
