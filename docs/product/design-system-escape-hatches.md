# Design System Escape Hatches

Date: 2026-09-14, measured after Round 4 of the reference-app program. Scope: the five flare-social reference apps and this kit.

An escape hatch is any place an app reaches around the kit's public contract to get a result it needs. Examples: styling kit internals, reading kit markup, casting past a type, owning a presenter the kit should own, or putting product UI in a system dialog. A hatch is evidence of a kit gap or an app defect. Every hatch listed here has an owner and, where the kit is at fault, a friction entry in `design-system-friction.md`.

Using the kit's published extension points is not an escape hatch. Those come first.

## 1. Sanctioned extension points

| Need | Extension point | Where the reference apps use it |
|---|---|---|
| Put app content inside a kit composite | Vue slots on composites: `FlareConversationListContainer` `#search` / `#status`, `FlareComposer` `#media-panel`, `FlareIMAppKit` `#primary` / `#detail` / `#overlay` | Web `ConversationPane.vue` (search tools, refresh banner), `ChatArea.vue` (emoji and sticker picker), `MainView.vue` (panes, global search, report dialog) |
| Show one pane at a time on phone | `activePane` on IMAppKit (all four kits) | Web `MainView.vue`, kit `examples/vue` |
| Offer only the actions the app performs | Vue listener mask on `FlareMessageList`; nullable callbacks on native lists and bubbles; `hiddenActions` plus the core's availability on `MessageActionSheet`; `capabilities` on `ConversationHeader` and `FlareConversationList` | Web `ChatArea.vue` and `ConversationPane.vue`, Tauri `SessionList.vue`; Android `ChatScreen.kt`, iOS `ChatView.swift`, Flutter `chat_screen.dart` |
| Add a product action to the message menu | Vue `actions` (`MessageMenuExtension`) with `@action` on `FlareMessageList` | Web `ChatArea.vue` (Report on other people's messages) |
| Put app rows inside the timeline | `FlareMessageList` `#header`, `#footer`, `#empty` and `#unread-divider` | Tauri `ChatPanel.vue` (typing row in `#footer`), web `ChatArea.vue` (loading and empty states) |
| Confirm a destructive step, show feedback | `useFlareConfirm` / `useFlareToast` (Vue, rendered by `FlareUiProvider`); `FlareDangerConfirm.show` and `FlareToast.show` (Flutter); `FlareFeedback` under `flareFeedbackHost` (iOS); `FlareToastHost` / `LocalFlareToast` and `DangerConfirm` (Compose) | All five apps; no app owns a toast host |
| Offer a small menu of actions (new, more, context) | `FlareActionMenu` (Vue), `FlareActionMenu` and `.show` (Flutter), `ActionMenuView` (iOS), `ActionMenu` (Compose), all drawing `FlareActionItem` | Tauri `SessionList.vue`; iOS `MainShell.swift`; Android contacts, contact details and group details |
| Put app content inside group details | `FlareGroupDetail` `after-info` / `afterInfo` and `footer` | Announcement read bar in web, Tauri, Flutter, iOS and Android; the report entry in web, Tauri, iOS and Android |
| Present a kit sheet or dialog | Vue `presentation` on `FlareBottomSheet` / `FlareFormSheet`; `FlareBottomSheet.show` and `FlareDialog.show` (Flutter); `flareBottomSheet(item:)` (iOS); `BottomSheet` (Compose) | Tauri drawers; Flutter (10 sheets, 7 dialogs); iOS (7 kit sheets); Android message sheet, audience and profile editor |
| Imperative scroll, focus or insert | Exposed handles: `FlareMessageList.scrollToMessage` / `scrollToBottom`, `FlareComposer.insertAtCursor` / `focus` / `resetInput` | Web `ChatArea.vue` (locate a search hit, insert emoji), Tauri `ChatPanel.vue` |
| Keep composer text under app control | Controlled value: Vue `v-model`, Flutter `controller` (and `onSend` returning whether the text was sent), iOS text binding, Compose `value` / `onValueChange` | Web `ChatArea.vue` (restores rich-send failures), Android `ChatScreen.kt` (draft per conversation) |
| Resolve media from app storage | `FlareUiProvider` `media-resolver` | Tauri `App.vue` |
| Native capabilities: back, pickers, share, safe area | Platform adapter (`FlarePlatformProvider`, `flarePlatform()`) and `spec/platform-contract.json` | Compose screens honour system back through the adapter's `nativeBack` capability |
| Locale and product copy | Vue i18n provider; `FlareStrings` overrides on Flutter, iOS and Compose | Every app's locale setting |
| New message types | Content registry on four kits | No reference app registers a custom type yet |
| Position a kit component in the app layout | Token-only layout glue (flex, grid, gap, padding from `--flare-size-*`) | Every Vue app; counted separately in section 2 |

## 2. Hatches still in the apps

Before counts are each app's committed HEAD (the state before this program's edits); after counts are the working trees after Round 4, from the same scans (`app-metrics`, plus the named searches).

### Web (golden reference)

| Hatch | Before | After | Class and priority | Note |
|---|---:|---:|---|---|
| Styles on kit internals (`:deep`, kit class selectors) | 0 | 0 | none | |
| `!important` | 2 | 2 | none | Both are in the reduced-motion reset in `app.css`; that is an accessibility rule, not a hatch. |
| Unsafe casts | 1 | 1 | APP P2 | `social/store.ts` casts core content to the SDK content type for the kit; the SDK type is looser than the core JSON. |
| App-owned toast host and timer | 1 | 0 | fixed (Round 1) | Replaced by `useFlareToast`. |
| Destructive steps without confirmation | 8 | 0 | fixed (Round 1) | Recall, delete, clear, block, remove friend, leave, dissolve and remove member now confirm through `useFlareConfirm`. |
| Menu flag table to hide unhandled actions | 14 flags | 0 | fixed (Round 1) | Replaced by the listener mask. |
| Duplicated pane markup for phone | 2 blocks | 0 | fixed (Round 2) | Replaced by `activePane`. |
| Report dialog from a non-kit UI package (`flare-social-vue-ui`) | 1 | 0 | fixed (Round 2) | `ReportSheet.vue` composes `FlareFormSheet`, `FlareRadioGroup` and `FlareTextarea` (FR-068). |
| Direct `FlareDangerConfirm` with screen-held state | 2 files | 0 | fixed (Round 2) | Contacts (cancel request, unblock) and moments (delete) now use `useFlareConfirm`; their store calls throw so failures show in the dialog. |
| Checkbox rows rebuilt for the create-group picker | 1 | 0 | fixed (Round 3) | Selectable `FlareContactList` (FR-029). |
| A button standing in for the inbox search field | 1 | 0 | fixed (Round 3) | `FlareSearchBar` read-only entry (FR-027). |

### Tauri (desktop parity)

| Hatch | Before | After | Class and priority | Note |
|---|---:|---:|---|---|
| `:deep` on kit roots | 5 | 4 | DESIGN_SYSTEM P2 | The timeline rule is gone: `.message-list-root` now fills its pane (FR-006). Left: two rules make `.flare-screen__body` a flex column in the address book, one makes `.im-conv-list` fill the session list, and one is the app root. |
| DOM queries | 9 | 9 | APP P2 | One reads a row id through `closest()` in `SessionList.vue`; the rest are the app's own rich-text and markdown utilities. |
| Unsafe casts | 14 | 13 | APP P2 | The blanket message cast became an explicit mapper (FR-007); the rest cast SDK rows in mapper and search preview code. |
| Per-panel toast hosts | 10 | 0 | fixed (Round 2) | 94 call sites moved to `useFlareToast`. |
| App-owned confirm composable and dialogs | 6 dialogs | 0 | fixed (Round 2) | 13 sites moved to `useFlareConfirm`. |
| Local message identity helpers | 2 | 0 | fixed (Round 0) | Replaced by `resolveMessageId` / `findMessage`. |
| Second conversation menu (own long-press handler and action sheet) and two action id maps | 3 | 0 | fixed (Round 3) | The kit row presents its one menu from `capabilities` (FR-016). |
| Checkbox wrappers around rows for batch management | 1 | 0 | fixed (Round 3) | `selectable` on `FlareConversationList` (FR-018). |
| Member-management writes that swallowed errors | 12 | 0 | fixed (Round 3) | Failures show a danger toast; removing a member and leaving are confirmed (Appendix A 14). |
| A bottom sheet with a settings list standing in for the new menu | 1 | 0 | fixed (Round 4) | `FlareActionMenu` on the add button (FR-024). |
| Writes to the viewer's own mute and pin settings that swallowed errors | 2 | 0 | fixed (Round 4) | A danger toast says the switch did not change (Appendix A 16). |

### Flutter (parity)

| Hatch | Before | After | Class and priority | Note |
|---|---:|---:|---|---|
| App-owned route presenters (`presentDialog`, `presentSheet`) | 18 sites | 0 | fixed (Round 3) | `FlareBottomSheet.show` and `FlareDialog.show`; `presentation.dart` is deleted (FR-025). |
| App-owned toast host (`showFlareToast`) | 18 sites | 0 | fixed (Round 3) | `FlareToast.show` (FR-021). |
| Composer text restored by the app after a failed send | 1 | 0 | fixed (Round 3) | `onSend` returns whether the text was sent (FR-015). |
| Pending friend requests written into signatures | 1 | 0 | fixed (Round 3) | Request `direction` (FR-030). |
| Hand-made message action availability | 1 | 0 | fixed (Round 2) | Core `message.action_availability`. |
| Destructive message steps without confirmation | 2 | 0 | fixed (Round 2) | `FlareDangerConfirm.show`. |
| `TextStyle` literals, theme override, gesture detector | 6, 1, 1 | 6, 1, 1 | APP P2 | Inside auth and profile screens. |

### iOS (second reference)

| Hatch | Before | After | Class and priority | Note |
|---|---:|---:|---|---|
| Product UI in `confirmationDialog` | 8 | 0 | fixed (Round 4) | Destructive steps confirm through `FlareFeedback.confirm` (FR-022, Round 3); the moments history range, theme and language pickers are kit sheets with radio groups (Round 4). |
| Hand-written system `Menu` in the toolbar | 1 | 0 | fixed (Round 4) | `ActionMenuView` (FR-024). |
| `.sheet` hosting app screens | 16 | 9 | sanctioned | Kit sheets moved to `flareBottomSheet(item:)` (7 sites, FR-010); the remaining system sheets host whole app screens (moment composer and comments, create group, profile editor, QR code twice, search, emoji picker, the moments privacy contact picker). |
| Toast hosted in the root view with timers in the session | 1 | 0 | fixed (Round 3) | `FlareFeedback` under `flareFeedbackHost` (FR-021). |
| Contact and group rows wrapped in stacks to add a trailing button | 4 | 0 | fixed (Round 3) | `ContactItemView` trailing content (FR-029). |

### Android (parity)

| Hatch | Before | After | Class and priority | Note |
|---|---:|---:|---|---|
| Raw `Dialog` around the kit message sheet | 1 | 0 | fixed (Round 3) | `BottomSheet` (FR-025). |
| Platform `Toast.makeText` | 1 | 0 | fixed (Round 3) | `FlareToastHost` and `LocalFlareToast` (FR-021). |
| Clickable overlays over kit components (inbox search field, group detail header) | 2 | 0 | fixed (Round 3) | SearchBar entry mode (FR-027) and `FlareGroupDetail` `headerActions` (FR-028). |
| Row-built `ContactActionRow` | 3 screens | 0 | fixed (Round 3) | Kit contact rows with trailing content (FR-029). |
| Material `DropdownMenu` overflow menu | 3 screens | 0 | fixed (Round 4) | Kit `ActionMenu` on contacts, contact details and group details; the app's `OverflowMenu` and `OverflowEntry` are deleted (FR-024). |
| Hand-made availability and quick-reaction list | 2 | 0 | fixed (Round 2) | Core availability and the kit default reactions. |
| System back not handled | app-wide | 0 | fixed (Round 2) | Kit screens register back (FR-005). |

## 3. Kit changes that removed hatches

| Kit change | Hatches it removed |
|---|---|
| `useFlareConfirm` / `useFlareToast` rendered by `FlareUiProvider` | Web toast host and eight unconfirmed destructive steps; Tauri ten toast hosts and six app-owned confirm dialogs |
| Listener mask on `FlareMessageList` and the hover toolbar | Web 14-flag menu table; the kit example's own flag table |
| `resolveMessageId` / `findMessage` | Tauri's local identity helpers; web id matching |
| `activePane` on Vue and Flutter IMAppKit | Duplicated list and detail markup in the web app and the kit example |
| Quick reactions default set | Android's own reaction list |
| Host reaction list gated by `canReact` | Reaction strips on pending and recalled messages |
| `FlareDangerConfirm.show` (Flutter) | Unconfirmed recall and delete in the Flutter chat |
| Compose system back | Back closing the Android app from any sub-screen |
| Native toast presenters (Flutter `FlareToast.show`, iOS `FlareFeedback`, Compose `FlareToastHost`) | Flutter's toast helper (18 sites), the iOS root toast views and session timers, Android's platform toasts |
| Native sheet and dialog presenters (Flutter `FlareBottomSheet.show` / `FlareDialog.show`, iOS `flareBottomSheet`, Compose `BottomSheet`) | Flutter's transparent route presenters, iOS system sheets around kit views, Android's raw `Dialog` |
| `capabilities` and `selectable` on the Vue conversation list | Tauri's second menu, its action maps and its checkbox wrappers; web's per-row action lists |
| SearchBar entry mode, contact `trailing` and request `direction` on four kits | Android's search overlay, iOS and Android hand-built contact rows, pending requests written into signatures in five apps |
| MessageList slots and a timeline that fills its pane | Tauri's typing-row growth fix |
| `ActionMenu` on four kits, used by the kits' own row, header and message menus (Round 4) | Tauri's menu sheet, Android's overflow menu, the iOS toolbar menu, and the naive-ui dropdowns inside the Vue kit |
| `FlareGroupJoinPolicy` and the group detail slots (Round 4) | Web's join policy cast; read bars and report entries placed outside the component in five apps |
| Semantic icon names in Tauri and web; the app gate counts glyph-library imports (Round 5) | Tauri's 16 vendor glyph imports through the kit's glyph shim; web's invalid `"bell"` icon name |

## 3b. Round 5 measurements (2026-09-15)

A second measurement, of behaviour rather than drawn elements. The kit-reference gate reads zero on every count, and those zeros hold. Most of the remaining friction sits where the gate does not look: behaviour left to hosts, data the kit models cannot carry, and native data adapters (FR-102).

| Metric | Web | Tauri | Flutter | iOS | Android |
|---|---|---|---|---|---|
| Style lines in components and app CSS | 197 | 158 | n/a | n/a | n/a |
| Selectors reaching into kit or naive-ui internals / `:deep` / `!important` | 1 / 0 / 2 | 3 / 4 / 0 | n/a | n/a | n/a |
| Literal typography in native app code | n/a | n/a | 6 `TextStyle` | 7 `.font`, 2 `.fontWeight` | 0 literals, 11 token font sizes composed by hand |
| DOM or view-hierarchy hacks | 4 | 25 (15 dead) | 13 | 6 | 10 |
| Private or deep kit imports | 0 | 0 | 0 | 0 | 0 |
| Wrapper components (thin + bound), lines | 3 bound (420) | 5 + 4 (1,004) | 5 + 3 (791) | 2 + 3 (502) | 4 + 3 (467) |
| Glue code, lines (named SDK-to-kit mapping units) | 2,933 (34) | 11,829 (20, plus 3 whole files) | 2,818 (10) | 2,069 (14) | 2,404 (15) |
| Kit usages with more than 5 boolean props / show-hide-enable props | 0 / 4 | 0 / 4 | 0 / 2 | 0 / 7 | 0 / 7 |
| App-owned generic IM behaviour (duplicates + borderline), lines | 13 + 1 (679) | 16 + 1 (2,922) | 15 (1,149) | 16 + 1 (728) | 15 + 1 (886) |
| System UI a kit component already covers, not a platform idiom | n/a | n/a | 1 | 6 | 12 |

Largest payoff if fixed in the kit, with the app code each fix deletes:

| Kit change | Apps | App lines deleted | Entry |
|---|---|---:|---|
| Async prompt presenter on four kits, confirm presenter on Compose | 5 | about 630 | FR-092 |
| Native core wire adapter at parity with Vue | 3 | about 980 | FR-093 |
| Native MessageList owns the message menu; reaction intents carry a direction | 5 | about 250 | FR-094 |
| IMAppKit measures itself, one pane vocabulary, retained tabs, derived back and navigation | 5 | about 160 | FR-095 |
| Connection banner and copy | 5 | about 160 | FR-096 |
| Composer owns the emoji panel and picks files through the platform adapter | 5 | | FR-097, FR-053 |
| Relation-aware rows, group list trailing, search debounce | 5 | | FR-098 |
| Configurable asset root | 2 | | FR-036 |
| Conversation kind, member count, subtitle in models | 5 | | FR-099 |
| Host actions on ContactDetail, the Compose GroupDetail header, MomentCard | 4 | | FR-046 |
| Typed moments audience and history range | 5 | | FR-100 |
| Text roles | 4 | about 70 | FR-051 |
| Theme mode API with persistence | 4 | about 130 | FR-101 |
| Semantic icon names on native kit parameters | 4 | | FR-079 |

## 3c. After the Round 5 implementation (2026-09-16)

Measured again after the round's kit and app changes. The rows below are the ones the round touched; the rest of the 3b table was not re-measured (the friction-metrics audit that produced it is a snapshot, and re-running its full method needs another read-only pass).

| Metric | Before (3b) | After | Evidence |
|---|---|---|---|
| Kit-reference gate counts (all five apps) | 0 on every count | unchanged: 0 | `examples/apps/scripts/check-kit-reference.mjs` PASS |
| Selectors reaching into kit or naive-ui internals (web / Tauri) | 1 / 3 | 0 / 0 | grep over `src/**/*.vue` |
| `:deep` (web / Tauri) | 0 / 4 | 0 / 4 | same |
| `!important` (web / Tauri) | 2 / 0 | 2 / 0 | same |
| Catalog components referenced (web / Tauri / Flutter / iOS / Android) | 45 / 66 / 46 / 43 / 45 | 50 / 65 / 50 / 47 / 45 | symbol map from `spec/components.json` |
| App-owned prompt and confirm dialogs (natives) | Flutter, iOS and Android each kept their own single-input dialogs | replaced by the kit presenters (FR-092) | `product-refinement-audit.md` section 8b |
| App-owned connection copy (five apps) | each app wrote its own phase copy | one kit notice with the copy, tone and recovery (FR-096) | same |
| App-owned diagnostics buffer (web) | an event ring buffer with no consumer | removed | `web:social/store.ts` |

Kit changes that removed hatches this round: the connection notice, the prompt and confirm presenters, the member preview and searchable member list, the settings row kinds (a read-only row is no longer a button), `FlareScreen` `readable`, the platform back composable with the web history adapter, the single-pane rule with `layoutChange`, `FlareContact.flareId`, the semantic icon registry, and the dialog-width component token that lets a host present a search palette.

New seams the kit gained (component tokens, not props): `--flare-component-screen-reading-width`, `--flare-component-sheet-dialog-width`, `--flare-component-avatar-tint-*`.

## 4. Rules

1. A new hatch needs a friction entry and an owner before it merges.
2. Layout glue that places a kit component inside the app's layout is allowed, with tokens only. Styling the inside of a kit component is a hatch.
3. When the kit gains the missing capability, the hatch is deleted in the same change, and the consumer gate keeps every app compiling.
4. System dialogs are for platform decisions (permissions, sharing). Product decisions such as delete, block or theme belong in kit surfaces.
