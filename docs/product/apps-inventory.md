# Social example apps inventory

- Scope: the 5 social example apps under `flare-social-sdk/examples/apps`: web (golden app), iOS (second reference app), Tauri, Flutter and Android (parity apps).
- Date: 2026-09-14. Evidence is a snapshot taken before the compile-blocked files were edited later that day; file:line references follow that snapshot.
- Method: per-app code audits (screens, local components, escape hatches, SDK mapping, actions, overlays, 135-feature grading, UX, tests), real compile runs against the current `flare-im-design` working tree, and a usage census of the 149 catalog components.
- Build status at audit time: web `vue-tsc` 2 errors and a blank page; Tauri `vue-tsc` 5 errors; Flutter `flutter analyze` 7 errors; Android `compileDebugKotlin` 22 errors; iOS `xcodebuild` fails. No app compiles against the current kit.
- After the Round 0 migrations the same day, all five compile against the kit: web and Tauri `vue-tsc` 0 errors, Flutter `flutter analyze` 0 issues with 6/6 tests, Android `compileDebugKotlin` successful, iOS `xcodebuild` successful on the arm64 simulator (see `golden-app.md`).
- The app gate `examples/apps/scripts/check-kit-reference.mjs` still reports 0 violations because it only greps literal visual code.
- Rounds 1 to 3 changed much of what this snapshot records (toast and sheet hosts, rows, menus, search, QR codes). The entries below are not re-graded; current state is in `golden-app.md`, `design-system-friction.md` and `design-system-escape-hatches.md`.

## Legend

| Prefix | Path |
|---|---|
| `web:` | `flare-social-web-app/src/` |
| `ios:` | `flare-social-ios-app/Sources/FlareSocialApp/` |
| `tauri:` | `flare-social-tauri-app/src/` |
| `flutter:` | `flare-social-flutter-app/lib/` |
| `android:` | `flare-social-android-app/app/src/main/kotlin/com/flare/social/app/` |
| `kit-vue:` | `flare-im-design/packages/vue-im-ui/src/` |
| `kit-ios:` | `flare-im-design/packages/ios-im-ui/Sources/FlareIMUI/` |
| `kit-flutter:` | `flare-im-design/packages/flutter-im-ui/lib/` |
| `kit-android:` | `flare-im-design/packages/android-im-ui/src/main/kotlin/com/flare/im/ui/` |
| `sfui:` | `flare-social-sdk/packages/flare-social-vue-ui/src/` |

- App folders without a prefix (for example `flare-social-tauri-app/src-tauri/`) are relative to `flare-social-sdk/examples/apps/`.
- Classes: G = GENERIC_IM_UI (another IM app would reuse it, belongs in the kit), A = APP_BUSINESS (product flow or IA, legit), H = HOST_ADAPTER (SDK or platform glue, legit).
- Features: C / P / M / NS = COMPLETE / PARTIAL / MISSING / NOT_SUPPORTED over the same 135-item checklist. Grades describe code paths as if the compile errors were fixed.
- "(removed)" marks a kit symbol deleted in the 2.0.0-rc.1 working tree that the app still references.
- KVA section n = Vue kit API audit (2026-09-14), section n.

## Summary

| App | Platform | Framework / kit package | LOC | Catalog components used | App-local components G / A / H | Features C / P / M | Built at audit time? | Status |
|---|---|---|---:|---:|---|---|---|---|
| Web (golden) | Browser, Rust core as WASM | Vue 3.5 + Vite 6; `@flare-im/vue-ui` aliased to `kit-vue:` source | 6,248 | 45 | 5 / 9 / 2 (16 UI units) | 50 / 40 / 44 (NS 1) | No: `vue-tsc` 2 errors, blank page | USABLE_PARTIAL |
| iOS (second reference) | iOS 16+ iPhone and iPad | SwiftUI; FlareIMUI (`ios-im-ui` path dependency) | 4,803 | 44 | 4 / 20 / 3 (27 views) | 36 / 48 / 49 (NS 2) | No: `xcodebuild` fails | USABLE_PARTIAL |
| Tauri | Desktop, Tauri 2 WebView | Vue 3.5 + naive-ui + Tauri 2.11; `@flare-im/vue-ui` aliased to `kit-vue:` source | 19,697 | 67 | 11 / 13 / 4 (28 .vue) + 14 G TS helper groups | 52 / 49 / 34 (NS 0) | No: `vue-tsc` 5 errors | USABLE_PARTIAL |
| Flutter | Flutter project, FFI linked on iOS only | Flutter 3.44 / Dart 3.12; `flare_im_ui` 2.0.0-rc.1 (path dependency) | 6,134 | 45 | 2 / 13 / 6 (21 units) | 38 / 31 / 64 (NS 2) | No: `flutter analyze` 7 errors | USABLE_PARTIAL |
| Android | Android 8.0+ (minSdk 26) | Jetpack Compose, material3; `com.flare.im:im-ui-compose` via included build | 4,797 | 44 | 3 / 28 / 4 (35 composables) | 34 / 51 / 48 (NS 2) | No: `compileDebugKotlin` 22 errors | USABLE_PARTIAL |

- LOC comes from the metrics run: `.vue/.ts/.css` under `src/` (web, Tauri), `.dart` under `lib/`, `.swift` under `Sources/`, `.kt` under `app/src/main/kotlin` excluding `ffi/`.
- Catalog components used = components with at least one direct file reference in the usage census.
- App-local components count UI-rendering units by the primary class given in each audit; several A units also contain generic fragments (listed per app).

---

## Web: flare-social-web-app

**App:** `flare-social-web-app`, the golden app.

**Platform:** Browser. The Rust core runs as WASM (`web:social/sdk.ts:11-12`, 12.6 MB `.wasm`); the session token persists in localStorage (`web:social/session.ts:20-32`).

**Framework:** Vue 3.5, vue-router 4, Vite 6, vitest and Playwright. Kit `@flare-im/vue-ui` is aliased to the `kit-vue:` 2.0.0-rc.1 source (`flare-social-web-app/vite.config.ts:10-12, 35-52`) while `flare-social-web-app/package.json:13-14` pins ^1.0.9, which lacks IMAppKit, FormSheet and DangerConfirm. One component, `ReportDialog`, comes from `flare-social-vue-ui` (`web:views/MainView.vue:60`).

**Purpose:** Golden reference for the Vue kit: shows a complete social IM product (auth, chats, contacts, groups, moments, settings) composed from `@flare-im/vue-ui` on the WASM SDK.

**Current Features:**
- Password and code login, register, reset password, session restore on boot (`web:views/AuthView.vue:224-236`; `web:social/session.ts:57-73`).
- Conversation list with unread badges and group sender prefix; private and group chat (`web:social/store.ts:318-357, 424-436`).
- Text, image, video, audio-file and file send; reply and quote via `create_quote`; recall and delete for self (`web:social/sdk.ts:208-212, 294-304`; `web:social/store.ts:481-494, 541-565`).
- In-conversation message search with type and time filters plus jump-to-message; global search over users, groups and messages (`web:components/ConversationSearch.vue:31-53`; `web:host/locateMessage.ts:17-25`; `web:social/directory.ts:811-875`).
- Directory: friends, new-friend requests, sent requests with withdraw, blocklist, add friend with contact-book match, join group (`web:components/ContactsTab.vue:61-71, 117-136`).
- Group governance, 11 of 13 group features complete: members, invite, admin, transfer, mute, announcement with read bar, join policy (`web:social/directory.ts:454-565`).
- Moments feed with composer, audience rules, likes, comments, delete and report (`web:components/MomentsTab.vue:183-303`).
- Settings: theme, locale, notification preferences, storage usage, device sessions with revoke, diagnostics (`web:components/SettingsPanel.vue:381-487`).

**Design System Usage:** 45 of 149 catalog components, plus 2 removed symbols.
- Auth: FlareScreen, FlareSegmentedControl, FlareFormField, FlareInput, FlareCheckbox, FlareButton, FlareStatusBanner (`web:views/AuthView.vue:8-16`).
- Shell: FlareIMAppKit, FlareConversationListContainer, FlareConversationList, FlareConversationRow, FlareIconButton, FlareEmptyState, FlareStatusBanner, FlareToast (`web:views/MainView.vue:14-28`).
- Chat: FlareMessageList, FlareComposer, FlareStatusBanner, FlareEmptyState; ChatHeader (removed) and ComposerEmojiStickerPanel (removed) (`web:components/ChatArea.vue:7-16`).
- Search: FlareSearchPanel in chat; FlareSearchBar and FlareSearchResults in the global overlay.
- Contacts: FlareFriendListContainer, FlareContactList, FlareNewFriendRequests, FlareGroupList, FlareContactMatchList, FlareContactDetail, FlareFormSheet, FlareDangerConfirm.
- Group: FlareGroupDetail, FlareAnnouncementReadBar.
- Moments: FlareMomentsCoverHeader, FlareMomentCard, FlareMomentComposer, FlareMomentAudienceSheet, FlareBottomSheet, FlareFormSheet.
- Me and settings: FlareProfilePanel, FlareProfileEditor, FlareQRCard, FlareSettingsList, FlareRadioGroup, FlareMomentsVisibilityRuleList, FlareNotificationPreferences, FlareStorageUsage, FlareDeviceSessions, FlareBottomSheet (8 sheets).

**App-local Components:**

| Component | LOC | Renders | Class | Should migrate? |
|---|---:|---|---|---|
| `web:components/ChatArea.vue` | 299 | Chat pane: header, locate banner, in-chat search toggle, timeline, composer, reply and edit state, file picker | G | YES: the reply/edit state machine and locate-with-paging belong in FlareChatWorkspace or FlareConversationWorkspace plus FlareConversationHeader |
| `web:views/MainView.vue` | 414 | Shell, nav config, list and chat and detail pane switching, connection banners, list rendered twice, toast host | A (G fragments) | YES for fragments: pane switching and banner mapping go to FlareConversationWorkspace, the toast host to a kit presenter; nav config stays |
| `web:components/ConversationSearch.vue` | 73 | In-chat message search, filter and range tables, result mapping | G | YES: default filter and range tables belong in FlareSearchPanel |
| `web:components/GlobalSearch.vue` | 86 | Search overlay: bar, cancel, 300 ms debounce, results | G | YES: generic search screen; debounce belongs in FlareSearchBar |
| `web:components/CreateGroupDialog.vue` | 110 | Group name plus one FlareCheckbox per contact | G | YES: multi-select member picker is FlareStartConversationDialog |
| `sfui:components/ReportDialog.vue` (imported) | 118 | Hand-rolled modal with raw buttons, radios, textarea and invalid tokens | G chrome, A reasons | YES: rebuild on FlareFormSheet, FlareRadioGroup and FlareTextarea; reasons stay app-owned |
| `web:views/AuthView.vue` | 385 | Password and code login, register, reset, gateway URL | A (G fragments) | NO: login is out of kit scope; the resend countdown and password reveal are kit candidates |
| `web:components/ContactsTab.vue` | 321 | Directory home, 8 sub-pages, confirms | A | NO: page IA; the sent-requests workaround needs a kit outgoing-requests list |
| `web:components/AddFriendPanel.vue` | 202 | User search, send-request sheet, contact-book match | A | NO: social flow |
| `web:components/JoinGroupPanel.vue` | 118 | Group search and join sheet | A | NO: social flow |
| `web:components/ContactDetailPanel.vue` | 131 | FlareContactDetail binding, edit sheet, report link | A | NO: wiring; the report entry needs a kit slot |
| `web:components/GroupDetailPanel.vue` | 183 | FlareGroupDetail model mapping and intents | H | NO: SDK mapping |
| `web:components/MomentsTab.vue` | 319 | Feed, composer, audience, comments, delete, report | A (G fragments) | NO: product feature; the comment input sheet is generic |
| `web:components/MeTab.vue` | 196 | Profile, editor, QR, my reports, settings entry | A | NO: page composition |
| `web:components/SettingsPanel.vue` | 501 | Settings rows and 8 sheets including diagnostics | A (G fragments) | NO: settings IA; the diagnostics composition fills a kit gap |
| `web:App.vue` | 16 | FlareUiProvider and RouterView | H | NO: bootstrap |
| `web:host/locateMessage.ts` | 25 | Jump to message: scroll, else page older, repeat | G (logic) | YES: FlareMessageList only exposes `scrollToMessage` |
| `web:social/store.ts` | 765 | IM state, SDK to kit mapping, send, toast timer | H (G fragments) | Partly: toast timer, title and preview fallbacks are generic presentation policy |

**App-local Styles:**
- Metrics: 33 files, 6,248 LOC, 15 `.vue`; 14 style blocks with 220 style lines; `:deep` 0; `!important` 2; kit class selectors 0; inline or bound style 0; DOM queries 0; unsafe casts 1; raw HTML elements in templates 38.
- Global `!important` animation kill for every element, which also freezes kit spinners (`web:app.css:25-30`).
- Selector on the naive-ui provider root to force full height (`web:app.css:21-23`).
- Reaches into the FlareInput root to lay out the code row (`web:views/AuthView.vue:373-376`).
- `as unknown as MessageContent` hides flattened core content; kit availability reads only `content.data.text`, so Copy is likely hidden (`web:social/store.ts:208`; `kit-vue:utils/messageActionAvailability.ts:64-71`).
- DOM attribute write on every SDK event, a leftover perf probe (`web:social/store.ts:438-441`).
- Hidden native file inputs clicked programmatically (`web:components/ChatArea.vue:259-265`; `web:components/MeTab.vue:126-132`).
- Imported ReportDialog: 32 style lines, 16 hex or rgba literals, z-index 60, tokens that do not exist in `tokens.css` (`sfui:components/ReportDialog.vue:88-117`); invisible to the gate.

**Missing Features:**
1. Conversation actions (pin, mute, archive, delete, mark unread): the kit row menu shows 8 items but none is wired (`web:views/MainView.vue:274, 298`; `web:social/store.ts:187-196`).
2. Forward, merge forward, multi-select, message pin, save and download (`web:components/ChatArea.vue:103-104`).
3. Mention sending and mention unread (`web:social/sdk.ts:209`; `web:social/store.ts:187-196`).
4. Typing, presence and drafts: `message.typing`, `presence.*` and `conversation.update_draft` unused; the draft clears on switch (`web:components/ChatArea.vue:178-185`).
5. Delivered state, read receipts and failed-send retry (`web:host/messageStatus.ts:14-34`; resend has no handler at `web:components/ChatArea.vue:102, 216-221`).
6. Media gallery, file preview, download and upload progress (`web:social/store.ts:515-528`).
7. Multiple images plus location, contact card, link card and poll composer actions (`web:components/ChatArea.vue:112-115, 172`).
8. Paste image and drag and drop: `fileDropEnabled` defaults to false (`kit-vue:components/composer/EnhancedComposer.vue:142`).

**UX Problems:**
1. Blank page: the router statically imports the chat pane, so the login page dies with the missing exports (`web:router.ts:2-3`; `web:components/ChatArea.vue:8, 10`).
2. Reaction and edit send ops the core does not know; errors go to `lastError`, which is never rendered (`web:social/sdk.ts:214-215, 226-227`; `web:social/store.ts:536-538`).
3. The emoji and sticker panel can never open because `media-panel-open` is never passed (`web:components/ChatArea.vue:224-246`; `kit-vue:components/composer/EnhancedComposer.vue:821`).
4. Destructive actions without confirmation: block or remove friend, leave or dissolve group, recall, delete, logout (`web:components/ContactDetailPanel.vue:83-90`; `web:components/GroupDetailPanel.vue:119-123`; `web:views/MainView.vue:200-212`).
5. Sticky toasts: direct assignments skip the 3.6 s timer and FlareToast has no close button (`web:social/report.ts:43`; `web:social/directory.ts:784`; `web:views/MainView.vue:204`).
6. Global search opens the wrong target: a group hit passes a groupId as conversationId, message hits share keys and never jump (`web:views/MainView.vue:194-197`; `web:social/directory.ts:855`).
7. Silent failures: directory writes swallow errors and a list error renders as the empty state (`web:social/directory.ts:432-442`; `web:social/store.ts:348-353`).
8. Tablet (768 px): the detail pane lands in a grid without a detail area, and Reply and Forward are missing from the tablet dropdown (`web:views/MainView.vue:151-152`; `kit-vue:composables/chat/useMessageMenuInteraction.ts:45-54`).

**Design System Gaps:**
1. STILL_PRESENT: FlareToast is display-only, with no presenter, queue, timeout or emitted `close` (`kit-vue:components/general/FlareToast.vue:30-33, 52-65`); workaround `web:social/store.ts:82-98`.
2. STILL_PRESENT: no desktop dialog, drawer or menu; FlareFormSheet is always a bottom sheet (`kit-vue:components/general/FlareFormSheet.vue:15`); all settings forms are sheets (`web:components/SettingsPanel.vue:385-486`).
3. RESOLVED_IN_KIT_NOT_ADOPTED: FlareConversationHeader has an identity action and a header action model (`kit-vue:shared/contracts/conversation-header.ts:17-60`); the app still uses ChatHeader (removed) (`web:components/ChatArea.vue:8`).
4. RESOLVED_IN_KIT_NOT_ADOPTED: FlareEmojiStickerPicker replaces the removed composer panel (`kit-vue:components/index.ts:40`); the app still imports ComposerEmojiStickerPanel (removed) (`web:components/ChatArea.vue:10`).
5. STILL_PRESENT: the FlareIMAppKit mobile branch drops the `primary`, `detail` and toast slots (`kit-vue:components/layout/FlareIMAppKit.vue:37-49`), forcing a second copy of the list (`web:views/MainView.vue:261-304`).
6. STILL_PRESENT: no trailing slot or multi-select on contact lists and no outgoing requests in FlareNewFriendRequests (`kit-vue:components/contacts/FlareNewFriendRequests.vue:7-12`); workarounds `web:components/ContactsTab.vue:117-136` and `web:components/CreateGroupDialog.vue:83-89`.
7. STILL_PRESENT: the message action model is closed; `pinSelf` defaults on and the tablet dropdown omits Reply and Forward (`kit-vue:shared/config/messageMenu.ts:55-71`; `kit-vue:utils/buildMessageMenuOptions.ts:51, 185-202, 247`).
8. RESOLVED_IN_KIT_NOT_ADOPTED: FlareBrandLogo, FormField `controlId` and Input `autocomplete` exist (`kit-vue:components/index.ts:132`; `kit-vue:components/form/FlareFormField.vue:7`); auth still uses a text brand placeholder and unassociated labels (`web:views/AuthView.vue:267-268, 277-334`).

**Status:** USABLE_PARTIAL
- Broad, real-SDK surface built almost entirely from kit components: 50 of 135 features complete, groups 11 of 13, plus contacts, moments, settings and search.
- Chat depth is weak: broken reaction and edit, dead row and message menus, no forward, mention, typing, drafts or download; vitest 10 of 11 and 4 of 6 Playwright specs stale.
- At audit time, did not compile against the kit (fixed in Round 0): `vue-tsc` 2 errors (TS2305 at `web:components/ChatArea.vue:8, 10`), and the dev server throws a SyntaxError that leaves a blank page.

---

## iOS: flare-social-ios-app

**App:** `flare-social-ios-app`, the second reference app.

**Platform:** iOS 16+ on iPhone and iPad; a macOS 13 target exists only for the `swift build` quick gate. Only a simulator FFI slice is linked (`flare-social-ios-app/project.yml:39-43`).

**Framework:** SwiftUI with SwiftPM tools 5.9 and xcodegen. Kit FlareIMUI through a path dependency on `flare-im-design/packages/ios-im-ui` (`flare-social-ios-app/Package.swift:15`); the published fallback `from: "1.0.9"` has no IMAppKitView or FormSheetView (`flare-social-ios-app/Package.swift:11-14`). SDK: FlareSocialAppleSDK over the C ABI.

**Purpose:** Second reference app: the native expression of the same social IM product, proving the kit contract outside the web.

**Current Features:**
- Password, code login, register and reset (`ios:AuthView.swift:395-434`; `ios:SocialSession.swift:79-204`).
- Shell on IMAppKitView with keep-alive tabs; Messages uses a split view on iPad (`ios:MainShell.swift:16-58`; `ios:ConversationsView.swift:17-83`).
- Text, emoji, single image, voice (kit hold-to-talk), demo location, card and poll; forward through ForwardPickerView; delete; add-only quick reactions (`ios:ChatView.swift:31-35, 69-88, 108-119, 140-158`).
- Grouped, debounced global search (`ios:SearchView.swift:7-71`; `ios:SocialSession.swift:1081-1136`).
- Directory: contacts, requests, sent requests with withdraw, blocked list, add friend, join group, create group through StartConversationView (`ios:MainShell.swift:73-221`; `ios:GroupViews.swift:10-64`).
- Group governance: members, invite, remove, admin, transfer, mute member, announcement with read bar (`ios:GroupViews.swift:73-233`).
- Moments feed with composer, audience, comments, delete and report (`ios:MomentsView.swift:9-272`).
- Settings: persisted theme, diagnostics, QR, login sessions with revoke, moments privacy, my reports (`ios:SettingsViews.swift:36-460`; `ios:ReportViews.swift:84-166`).

**Design System Usage:** 44 of 149 catalog components, plus ChatHeaderView (removed).
- Auth: FlareScreen (brand surface), FlareBrandLogo, SegmentedControlView, FormFieldView, InputView, IconButtonView, ButtonView, StatusBannerView.
- Root and shell: IMAppKitView, StatusBannerView, ToastView.
- Messages and search: ConversationListContainerView, ConversationListView, EmptyStateView, SearchBarView, SearchResultsView.
- Chat: MessageListView, ComposerView, FlareEmojiStickerPicker, ForwardPickerView; ChatHeaderView (removed).
- Directory: ContactListView, GroupListView, NewFriendRequestsView, ContactItemView, FlareContactDetail, ContactMatchListView, StartConversationView, FormSheetView.
- Group: FlareGroupDetail, AnnouncementReadBarView.
- Moments: MomentsCoverHeaderView, MomentCardView, MomentComposerView, MomentAudienceSheetView, FormSheetView.
- Settings and report: ProfilePanelView, SettingsListView, QRCardView, DeviceSessionsView, ProfileEditorView, MomentsVisibilityRuleListView, RadioGroupView, TextareaView.

**App-local Components:**

| Component | LOC | Renders | Class | Should migrate? |
|---|---:|---|---|---|
| ConnectionBanner `ios:FlareSocialRootView.swift:47-101` | 55 | Connection and send-error banners, notice and login-alert toasts; timers live in the session | G | YES: kit toast presenter with queue and duration, plus an IMAppKitView toast slot |
| SentRequestsSection `ios:MainShell.swift:166-187` | 22 | Sent-requests header, contact row, trailing withdraw button | G | YES: ContactItemView trailing slot or an outgoing-requests list |
| BlockedListScreen `ios:MainShell.swift:190-221` | 32 | Blocked rows with a remove button | G | YES: same trailing-slot gap |
| MomentCommentSheet `ios:MomentsView.swift:219-272` | 54 | Moment card plus an HStack comment input bar | G | YES: CommentThreadView needs an input |
| ChatView `ios:ChatView.swift:8-188` | 181 | Chat composition, long-press menu on a confirmation dialog, 4 quick reactions | A (G menu) | YES for the menu: MessageActionSheetView with availability and shared quick reactions |
| AddFriendScreen `ios:FriendActionViews.swift:130-238` | 109 | User search rows built from HStack, contact-book match | A (G rows) | Rows YES (trailing slot); flow NO |
| JoinGroupScreen `ios:FriendActionViews.swift:241-304` | 64 | Group search results shown as contact rows | A (G rows) | Rows YES (group row with action); flow NO |
| MainShell `ios:MainShell.swift:8-59` | 52 | IMAppKitView plus ZStack keep-alive tab roots | H | Partly: persistent tab roots belong in IMAppKitView |
| ConversationsView `ios:ConversationsView.swift:7-146` | 140 | NavigationStack or split view routing, search sheet | H | NO: native navigation |
| AuthView `ios:AuthView.swift:12-435` | 424 | Auth flows, brand rail and lockup with SwiftUI fonts | A | NO: login flow; heading styles need a kit text primitive |
| ContactDetailScreen `ios:FriendActionViews.swift:7-127` | 121 | Detail binding, edit sheets, system confirms | A | NO: wiring; confirms should use DangerConfirmView |
| GroupDetailView `ios:GroupViews.swift:73-233` | 161 | FlareGroupDetail binding and report footer | A | NO: model mapping and intents |
| MomentsView and MomentComposerSheet `ios:MomentsView.swift:9-213` | 200 | Feed, report row, composer with inline audience panel | A | NO: product feature |
| Settings family `ios:SettingsViews.swift:36-460` | 411 | Settings, diagnostics, QR, sessions, profile editor, moments privacy | A | NO: settings IA; pickers should be FormSheetView with RadioGroupView |
| ReportSheet and MyReportsView `ios:ReportViews.swift:19-166` | 145 | Report form and report list | A | NO: moderation flow; a shared kit report composite would help |
| SocialSession `ios:SocialSession.swift` | 1,663 | SDK wiring, about 733 LOC of mapping, toast timers | H | Partly: toast timers are generic; shared mapping belongs in SDK view models |
| VoiceRecorder `ios:VoiceRecorder.swift` | 99 | Nothing (0 references) | H | NO: delete, the kit records voice |

**App-local Styles:**
- Metrics: 16 files, 4,803 LOC; padding literals 0; frame literals 0; `.background` 11; `.foregroundColor` or `.foregroundStyle` 8; `.font` 8; system dialogs and sheets 26 (8 confirmation dialogs, 2 alerts, 16 sheets); HStack, VStack and ZStack 40.
- Message menu on a system confirmation dialog (`ios:ChatView.swift:105`).
- Block friend, delete friend, delete moment and revoke device confirmed through system dialogs (`ios:FriendActionViews.swift:104, 111`; `ios:MomentsView.swift:89`; `ios:SettingsViews.swift:313`).
- SwiftUI text styles and colors instead of kit typography (`ios:AuthView.swift:134-157`; `ios:FriendActionViews.swift:184, 188`; `ios:MainShell.swift:175`).
- App-painted grounds because pages are not FlareScreen (`ios:SearchView.swift:41`; `ios:MomentsView.swift:74, 175`).
- Animation literal `.easeOut(duration: 0.2)` instead of FlareMotion (`ios:FlareSocialRootView.swift:98-99`).
- Keep-alive tab roots through opacity and zIndex (`ios:MainShell.swift:51-58`).
- Icon-only toolbar buttons without accessibility labels (`ios:ConversationsView.swift:110, 114`; `ios:MomentsView.swift:81`).

**Missing Features:**
1. Message lifecycle: status is hard-coded to sent; no sending, read, recalled or per-message failed state (`ios:SocialSession.swift:850`).
2. Reply, quote, mention and copy; reactions are add-only and never rendered (`ios:ChatView.swift:140-158`).
3. Conversation actions (pin, mute, archive, delete) from the list (`ios:ConversationsView.swift:108-117`).
4. Image preview, gallery, video, file preview, download and upload progress: `onMediaAction` is not wired (`kit-ios:Components/MessageBubbleView.swift:180`).
5. Received image, voice and file content: keys do not match the core JSON (`ios:SocialSession.swift:888-898`).
6. Drafts, typing and presence: the `ComposerView(text:)` binding and `presence.*` ops are unused, and contact rows pass `showPresence: false` (`ios:MainShell.swift:180`).
7. History pagination (latest 50 only) and moments pagination (`ios:MomentsView.swift:37-44`).
8. Group avatar edit, admin permissions and a 3-state notify mode (`ios:SocialSession.swift:1292-1296`).

**UX Problems:**
1. Add friend only finds existing friends: it calls `search_contacts`, a search within friends (`ios:FriendActionViews.swift:226-233`; `ios:SocialSession.swift:1088`).
2. Join-group results always show 0 members (`ios:FriendActionViews.swift:266, 297`).
3. One `rawMessages` map is shared by every mounted chat, so a reload can mark the wrong read seq or break forward lookups (`ios:SocialSession.swift:748, 761, 1416, 1448`).
4. Toasts and banners are stacked in layout, so the whole shell jumps when they appear (`ios:FlareSocialRootView.swift:20-23`).
5. Errors are swallowed: image send, all group writes; the profile editor dismisses even on failure (`ios:ChatView.swift:86`; `ios:SocialSession.swift:1227-1346`; `ios:SettingsViews.swift:381-387`).
6. The English language option only sets the SwiftUI locale; kit strings stay Chinese (`ios:SettingsViews.swift:113-115`; `kit-ios:Tokens/FlareStrings.swift:501`).
7. Group details cannot be opened from the chat header (`ios:ChatView.swift:40-45`).
8. Kicked or expired banners offer no re-login, and the connection state starts as connected before any event (`ios:FlareSocialRootView.swift:66-69`; `ios:SocialSession.swift:52`).

**Design System Gaps:**
1. STILL_PRESENT: ToastView is presentational only and IMAppKitView has no toast slot (`kit-ios:Components/ToastView.swift:24-27`; `kit-ios:Application/ApplicationComposition.swift:562-588`).
2. RESOLVED_IN_KIT_NOT_ADOPTED: MessageActionSheetView with availability and quick reactions (`kit-ios:Components/MessageActionSheetView.swift:110-136`); the app uses a confirmation dialog (`ios:ChatView.swift:105-107`).
3. RESOLVED_IN_KIT_NOT_ADOPTED: ConversationHeaderView with identity action and capability-aware actions (`kit-ios:Components/ConversationHeaderView.swift:146-176`); the app calls ChatHeaderView (removed) (`ios:ChatView.swift:40`).
4. RESOLVED_IN_KIT_NOT_ADOPTED: DangerConfirmView exists (`kit-ios:Components/ScenePanels.swift:110-115`); the app confirms through system dialogs (`ios:FriendActionViews.swift:104, 111`).
5. STILL_PRESENT: ContactItemView has no trailing action slot (`kit-ios:Components/ContactViews.swift:11`); workaround rows at `ios:MainShell.swift:178-183`.
6. STILL_PRESENT: FlareMessageData has no reactions, reply or quote, mentions or thread id (`kit-ios:Models/MessageData.swift:5-43`).
7. STILL_PRESENT: no semantic heading, section or caption primitive, only font-size tokens (`kit-ios:Tokens/FlareTokens.swift:1047-1054`); workaround `ios:AuthView.swift:134-157`.
8. RESOLVED_IN_KIT_NOT_ADOPTED: ProfileEditorView `onPickAvatar` and MomentComposerView image entry (`kit-ios:Components/ProfileViews.swift:133-134`); the app wires neither (`ios:SettingsViews.swift:367-389`; `ios:MomentsView.swift:148-149`).

**Status:** USABLE_PARTIAL
- Auth, shell, directory, group governance, moments, settings, devices, reports and text chat are wired through kit views with token-clean spacing (0 padding or frame literals).
- The message lifecycle, rich media, conversation actions and drafts are missing, and the message menu, toasts, action rows and comment bar are still app-owned; there is no test target.
- At audit time, did not compile against the kit (fixed in Round 0): `xcodebuild` fails on the FormSheetView `onCancel:` label, now `onClose:` (first error `ios:ReportViews.swift:39`; other call sites `ios:FriendActionViews.swift:71, 88` and `ios:MomentsView.swift:183`), and on ChatHeaderView (removed) (`ios:ChatView.swift:40`).

---

## Tauri: flare-social-tauri-app

**App:** `flare-social-tauri-app` (package `flare-base-tauri`, product name "Flare Base"), a parity app.

**Platform:** Desktop through the Tauri 2 WebView; window minimum width 960, so the kit's mobile and tablet branches are unreachable (`flare-social-tauri-app/src-tauri/tauri.conf.json:17-30`).

**Framework:** Vue 3.5, vue-router 4, naive-ui 2.44, Vite 6; Rust `flare-sdk-tauri` over IPC. Kit `@flare-im/vue-ui` is aliased to the `kit-vue:` source whenever the sibling repo exists (`flare-social-tauri-app/vite.config.ts:69-88`); the published pin ^1.0.9 lacks 22 of the symbols the app uses.

**Purpose:** Parity app: the desktop build of the social IM product on the Vue kit, exercising the richest chat surface (batch actions, forward, receipts, pinned bar, previews).

**Current Features:**
- Password, code, register and reset flows with endpoint config and cold-start restore (`tauri:views/Auth.vue:365-468`; `tauri:utils/sessionRestore.ts:66-98`).
- Conversation list with local search, pin, mute, archive, delete, batch mode and unread badges (`tauri:components/chat/SessionList.vue:93-104`; `tauri:components/chat/ChatPanel.vue:1048-1134`).
- Chat extras: typing, pinned message bar, announcement banner, 1:1 read receipt sheet, forward picker with merge, multi-select, image, video and markdown previews (`tauri:components/chat/ChatPanel.vue:260-278, 1466-1511, 1576-1607, 1840-1860`).
- Group and 1:1 chat settings panes (`tauri:components/chat/GroupChatSettingsPanel.vue:191-239`; `tauri:components/chat/ContactChatSettingsPanel.vue:131-178`).
- Directory: friends, incoming and outgoing requests with cancel, blocked list, add friend with contact matching, group create, join and search (`tauri:components/contacts/ContactsPanel.vue:303-310`; `tauri:components/groups/GroupsPanel.vue:309-313`).
- Group governance, 12 of 13 group features complete (`tauri:components/GroupDetailPanel.vue:277-366`).
- Moments, privacy settings (complete), devices, notifications, storage, my profile and my reports (`tauri:components/settings/PrivacySettingsDrawer.vue:208-251`).
- Global search with filters and a date range (`tauri:components/search/GlobalSearchDrawer.vue:165-200, 259-283`).

**Design System Usage:** 67 of 149 catalog components, the widest of the five; 72 Flare symbols are imported, 5 of them removed.
- Auth: FlareScreen, FlareSegmentedControl, FlareFormField, FlareInput, FlareButton, FlareStatusBanner, FlareSettingsList, FlareEmptyState (as brand), FlareToast.
- Shell: FlareIMAppKit, FlareDangerConfirm, FlareToast.
- Chat workspace: FlareConversationWorkspace, FlareMessageList, FlareComposer, FlareTypingIndicator, FlarePinnedMessageBar, FlareAnnouncementBanner, FlareMessageBatchToolbar, FlareForwardPicker, FlareReadReceiptSheet, FlareImagePreview, FlareVideoPreview, FlareMarkdownPreview; ChatHeader (removed), ChatHeaderIdentity (removed), ComposerEmojiStickerPanel (removed).
- Conversation list: FlareConversationListContainer, FlareConversationList, FlareConversationRow, FlareConversationBatchToolbar, FlareConversationActionSheet, FlareSearchBar, FlareCheckbox.
- Chat settings: FlareSettingsRow, FlareSettingsList, FlareGroupMemberGrid, FlareSkeleton, FlareProfileCard.
- Address book: FlareFilterTabs, FlareFriendListContainer, FlareContactList, FlareNewFriendRequests, FlareContactMatchList, FlareRelationActionBar, FlareGroupList, FlareContactDetail, FlareGroupDetail; ContactsWorkspace (removed), GroupWorkspace (removed).
- Moments, settings and search: FlareMomentCard, FlareMomentComposer, FlareMomentAudienceSheet, FlareProfilePanel, FlareProfileEditor, FlareQRCard, FlareDeviceSessions, FlareNotificationPreferences, FlareStorageUsage, FlareSwitch, FlareSelect, FlareRadioGroup, FlareSearchPanel, FlareSearchDateRangeFilter.

**App-local Components:**

| Component | LOC | Renders | Class | Should migrate? |
|---|---:|---|---|---|
| `tauri:components/chat/ChatPanel.vue` | 1,921 | Whole conversation workspace controller: panes, typing timers, receipts, multi-select, forward, previews, composer state, overlays | G | YES: selection, reply and edit state, typing expiry, forward targets, preview resolution and receipts move to a kit chat controller; header to FlareConversationHeader |
| `tauri:components/chat/SessionList.vue` | 348 | List container, local search, new menu, checkbox rows, mobile long-press sheet | G | YES: row selection mode and one conversation action vocabulary; the row already emits `longPress` |
| `tauri:components/chat/GroupChatSettingsPanel.vue` | 307 | Group chat info pane | G | YES: kit chat-info pane; the kit only has a devtools-style details view (`kit-vue:components/shell/ConversationDetails.vue:10-41`) |
| `tauri:components/chat/ContactChatSettingsPanel.vue` | 244 | 1:1 chat info pane | G | YES: same kit chat-info pane |
| `tauri:components/search/GlobalSearchDrawer.vue` | 288 | Global search: filters, date range, grouping, mapping, routing | G | YES: search workspace assembly |
| `tauri:components/chat/ChatInConversationSearch.vue` | 117 | In-chat search sheet, result mapping, zh-CN time format | G | YES: in-conversation search scene |
| `tauri:components/chat/ChatPeerProfilePopover.vue` | 109 | Peer profile sheet, presence banner, remark form | G | YES: kit peer profile sheet |
| `tauri:components/chat/ChatSettingsMembersSection.vue` | 53 | Member count row and grid; roles inferred by regex on labels | G | YES: FlareGroupMemberGrid role model |
| `tauri:components/common/UserAvatar.vue` | 45 | FlareAvatar wrapper resolving avatar keys | G | YES: the provider media resolver already covers it |
| `tauri:components/common/EmptyState.vue`, `PageHeader.vue` | 31 | Pass-through wrappers with no importer | G | Delete |
| `tauri:utils/panelToast.ts` | 49 | Per-panel toast state and timer, instantiated for 10 hosts | G | YES: kit toast presenter |
| `tauri:host/chat/composables/useDangerConfirm.ts` | 43 | Promise-based confirm, 4 hosts | G | YES: kit confirm presenter |
| `tauri:host/chat/utils/kitMessage.ts`, `messageIdentity.ts`, `messageMutations.ts` | 230 | SDK message to MessageLike, sort, optimistic merge | G | YES: a single kit adapter and identity helper; today stale `seq`, wrong status numbers, reversed id precedence |
| `tauri:host/chat/utils/` preview, emoji, markdown and media helpers | about 1,900 | Same exported names as kit utils; `emoji-locales.json` is byte-identical to the kit asset | G | YES: import `@flare-im/vue-ui/utils` |
| `tauri:views/Auth.vue` | 648 | Login flows and endpoint config | A | NO: login is out of kit scope |
| `tauri:views/Main.vue` | 404 | Shell, nav config, toast and confirm hosting, logout | A (G fragments) | NO for IA; toast and confirm hosting move to kit presenters |
| `tauri:components/contacts/ContactsPanel.vue` | 673 | Friends, requests, blocked, add-friend sheet, toast host | A (G fragments) | NO: relation flows |
| `tauri:components/groups/GroupsPanel.vue` | 444 | Group directory, create, join, search, hand-built member-picker row | A (G fragments) | NO for flows; the picker row goes to FlareStartConversationDialog |
| `tauri:components/GroupDetailPanel.vue` | 429 | SDK to FlareGroupDetailModel and intents; 13 swallowed errors | H | NO: SDK mapping |
| `tauri:components/moments/MomentsTab.vue` | 358 | Moments feed and sheets | A | NO: product feature |
| `tauri:components/settings/AppSettingsDrawer.vue`, `PrivacySettingsDrawer.vue`, `MyReportsSheet.vue`; `tauri:components/user/UserProfileDrawer.vue` | 962 | App settings, privacy, my reports, my profile | A | NO: settings IA |
| `tauri:components/common/ReportDialog.vue` | 89 | Report form on FlareFormSheet and FlareRadioGroup | A | NO: moderation reasons are app-owned |
| `tauri:host/i18n/` including `ImLocaleProvider.vue` | 1,607 | Parallel i18n system serving about 14 keys | H | NO, but shrink it |

**App-local Styles:**
- Metrics: 155 files, 19,697 LOC, 28 `.vue`; 20 style blocks with 220 style lines; `:deep` 5; `!important` 0; kit class selectors 2; inline or bound style 0; DOM queries 9; unsafe casts 14; raw HTML elements in templates 50.
- `:deep` on the MessageList root so the timeline grows (`tauri:components/chat/ChatPanel.vue:1897-1900`).
- `:deep` on the conversation list root after wrapping it for long-press (`tauri:components/chat/SessionList.vue:334-337`).
- `:deep` on the FlareScreen body and on every router child (`tauri:components/addressbook/AddressBookPanel.vue:101-102`; `tauri:App.vue:98-102`).
- DOM traversal with `closest` and a data attribute to find the long-pressed row (`tauri:components/chat/SessionList.vue:179-188, 262`).
- Spread cast to MessageLike that hid three contract bugs (`tauri:host/chat/utils/kitMessage.ts:46`).
- Toast positioning CSS duplicated 8 times (`tauri:components/contacts/ContactsPanel.vue:672`; `tauri:views/Main.vue:393-403`).
- FlareCheckbox given an `ariaLabel` prop that does not exist (`tauri:components/chat/SessionList.vue:266`); custom 860 px breakpoint (`tauri:views/Auth.vue:642`).

**Missing Features:**
1. Theme and dark mode: `theme-mode="light"` is hard-coded (`tauri:App.vue:78`).
2. Session expiration: the token-expired event has no subscriber (`tauri:host/events/createImEventHub.ts:392-396`).
3. Multiple images and location, contact card, link card, poll, topic, mini app, schedule and task composer actions (`tauri:components/chat/ChatPanel.vue:1147-1151, 1170`).
4. Mention picker: `mentionCandidates` is never passed (`kit-vue:components/composer/EnhancedComposer.vue:108`).
5. Media gallery, file preview, upload progress and retry (`tauri:flare-sdk/api/media.ts:137-139`).
6. Message translate, report and save: not in the closed kit action union (`kit-vue:shared/config/messageMenu.ts:3-18`).
7. Group avatar and member search (`tauri:flare-sdk/api/social.ts:343`).
8. Paste image and drag and drop (`kit-vue:components/composer/EnhancedComposer.vue:142`).

**UX Problems:**
1. Timeline order is effectively random and load-older never loads: the app sorts on `seq` and `timestamp`, which the core no longer sends (`tauri:host/types/message.ts:254-298`; `tauri:host/chat/utils/messageIdentity.ts:32-46`; `tauri:components/chat/ChatPanel.vue:886-887`).
2. Failed sends render as read with no resend: the app maps status 4 to read, but 4 is FAILED in the proto (`tauri:host/chat/utils/kitMessage.ts:15-31`; `tauri:host/chat/utils/messageMutations.ts:106-114`).
3. Reply, react, forward, preview and download silently do nothing: the app looks up `serverId` first while the kit emits `clientMsgId` first (`tauri:host/chat/utils/kitMessage.ts:60-66`; `kit-vue:components/messages/MessageList.vue:118-120`).
4. 11 IPC commands have no route, so rich-text send, call buttons and initial presence always fail (`tauri:flare-sdk/api/richDocV2.ts:36-80`; `tauri:flare-sdk/api/call.ts:13`; `tauri:flare-sdk/api/presence.ts:13`).
5. Up to 10 toast hosts overlap at the same fixed position, each with its own status live region (`tauri:utils/panelToast.ts:23-49`).
6. Contact block and remove run without confirmation and swallow errors; group writes swallow 13 errors (`tauri:components/ContactDetailPanel.vue:97-106`; `tauri:components/GroupDetailPanel.vue:291-366`).
7. A desktop app where every secondary surface (settings, search, profile, forward, receipts) is a bottom sheet (`tauri:components/settings/AppSettingsDrawer.vue:251`; `tauri:components/search/GlobalSearchDrawer.vue:259`).
8. Mixed language: about 770 hard-coded Chinese literals stay while the kit switches to en-US for English locales (`tauri:App.vue:27`).

**Design System Gaps:**
1. STILL_PRESENT: no toast presenter or queue, and FlareIMAppKit has no toast slot (`kit-vue:components/general/FlareToast.vue:19-29`; `kit-vue:components/layout/FlareIMAppKit.vue:45-48`).
2. STILL_PRESENT: no desktop dialog, drawer, popover or menu; 26 sheet instances stand in (`kit-vue:components/general/FlareBottomSheet.vue:15-25`).
3. STILL_PRESENT: MessageLike is SDK-shaped and events carry an ambiguous bare id, with no canonical adapter (`kit-vue:shared/contracts/messageRow.ts:5-35`; KVA section 10, items 2 and 3).
4. STILL_PRESENT: FlareConversationRow has no selection state or slots, and two conversation action vocabularies need two maps (`kit-vue:shared/contracts/conversation.ts:57-68`; `kit-vue:shared/contracts/conversation-actions.ts:6-15`; `tauri:components/chat/SessionList.vue:156-219`).
5. RESOLVED_IN_KIT_NOT_ADOPTED: FlareConversationHeader identity action and action model (`kit-vue:shared/contracts/conversation-header.ts:17-80`); the app wraps ChatHeaderIdentity (removed) in a role=button div (`tauri:components/chat/ChatPanel.vue:1656-1668`).
6. RESOLVED_IN_KIT_NOT_ADOPTED: FlareWorkspaceFrame replaces ContactsWorkspace (removed) and GroupWorkspace (removed) with the same props (`kit-vue:components/layout/FlareWorkspaceFrame.vue:19-32`; `tauri:components/contacts/ContactsPanel.vue:12`; `tauri:components/groups/GroupsPanel.vue:17`).
7. RESOLVED_IN_KIT_NOT_ADOPTED: FlareEmojiStickerPicker replaces ComposerEmojiStickerPanel (removed) (`kit-vue:components/index.ts:40`); the slot still needs `media-panel-open`, which the app never passes (`tauri:components/chat/ChatPanel.vue:1769-1779`).
8. RESOLVED_IN_KIT_NOT_ADOPTED: kit utils such as `getContentDecodedPreview` and `listMessageMediaDownloadSources` (`kit-vue:utils/messagePreview.ts:9`; `kit-vue:utils/messageMedia.ts:111, 177`) are re-implemented in about 1,900 LOC of app helpers.

**Status:** USABLE_PARTIAL
- Widest kit usage (67 components) and real IPC wiring: 52 of 135 features complete, groups 12 of 13, privacy complete.
- Core chat is broken by the app-owned message adapter and 11 unrouted IPC commands; 11 generic `.vue` files (3,463 LOC), 10 toast hosts and 6 confirm hosts remain; there are no tests.
- At audit time, did not compile against the kit (fixed in Round 0): `vue-tsc` 5 errors for 5 removed exports (`tauri:components/chat/ChatPanel.vue:7, 8, 10`; `tauri:components/contacts/ContactsPanel.vue:12`; `tauri:components/groups/GroupsPanel.vue:17`), so `npm run build` fails.

---

## Flutter: flare-social-flutter-app

**App:** `flare-social-flutter-app` (Dart package `flare_base_flutter`), a parity app.

**Platform:** Flutter multi-platform project; only iOS links the FFI library (`flare-social-flutter-app/ios/Flutter/Debug.xcconfig:6`). Android, macOS, Linux and Windows have no linkage, and the web target cannot use dart:ffi.

**Framework:** Flutter 3.44 and Dart 3.12 with Material. Kit `flare_im_ui` 2.0.0-rc.1 through a path dependency on `flare-im-design/packages/flutter-im-ui` (`flare-social-flutter-app/pubspec.yaml:44-48`); social SDK through the untracked `flare_social_flutter_sdk` package (`flare-social-flutter-app/pubspec.yaml:40-43`).

**Purpose:** Parity app: the Flutter expression of the social IM product; strongest on group management, thinnest on chat.

**Current Features:**
- Password login and register with a persisted gateway snapshot and an autologin hook (`flutter:screens/auth_screen.dart:36-138`).
- Responsive shell: bottom navigation on mobile, rail plus a chat split on wider screens, Chats tab only (`flutter:screens/base_shell.dart:296-318, 441-460`).
- Conversation list with unread, pinned and muted flags and sender prefix; event-driven reloads (uncommitted) (`flutter:sdk/im_client.dart:41-124`; `flutter:screens/base_shell.dart:64-70`).
- Messages: text, kit emoji and sticker panel, image, voice, rich text; forward to several targets; recall and delete; a fixed thumbs-up reaction (`flutter:screens/chat_screen.dart:88-139, 141-181, 254-297`).
- Directory: contacts, incoming and sent requests, add friend with address-book match, join group (`flutter:screens/social_action_screens.dart:213-670`).
- Group governance, 12 of 13 group features complete: members, invite, admin, transfer, mute, announcement read bar, join approvals (`flutter:screens/social_action_screens.dart:673-1013`).
- Moments on an MVVM view model with audience rules (`flutter:viewmodels/moments_view_model.dart:14-200`).
- Profile center: nickname and signature edit, QR token, privacy toggle, moments hide and mute lists (`flutter:screens/profile_center_screen.dart:12-607`).

**Design System Usage:** 45 of 149 catalog components, plus ChatHeader (removed), Surface (removed, Flutter) and the uncatalogued FlareDialog.
- Auth: FlareScreen, FlareSegmentedControl, FlareFormField, FlareInput, FlareCheckbox, FlareButton, FlareStatusBanner, FlareBrandLogo, FlareTopicChip; Surface (removed, Flutter).
- Shell and Chats tab: FlareIMAppKit, FlareConversationListContainer, FlareScreenHeader, FlareConversationList, FlareAvatar, FlareStatusBanner, FlareEmptyState.
- Chat: FlareMessageList, FlareComposer, FlareMessageActionSheet (old API), FlareForwardPicker; ChatHeader (removed).
- Contacts and requests: FlareFriendListContainer, FlareContactList, FlareSettingsList, FlareSearchBar, FlareContactMatchList, FlareFilterTabs, FlareNewFriendRequests, FlareDangerConfirm, FlareContactDetail, FlareGroupList, FlareDialog.
- Group: FlareGroupDetail, FlareAnnouncementReadBar.
- Moments: FlareMomentsCoverHeader, FlareMomentCard, FlareMomentComposer, FlareMomentAudienceSheet, FlareSkeleton.
- Profile center: FlareProfilePanel, FlareProfileEditor, FlareDeviceSessions, FlareStorageUsage, FlareMomentsVisibilityRuleList, FlareQRCard.

**App-local Components:**

| Component | LOC | Renders | Class | Should migrate? |
|---|---:|---|---|---|
| showFlareToast `flutter:host/presentation.dart:38-71` | 34 | Toast in a root OverlayEntry, fixed 3 s, no queue, 17 call sites | G | YES: kit toast host with queue and live region |
| `_promptText` `flutter:screens/moments_screen.dart:302-334` | 33 | One-line prompt dialog, third copy of the pattern | G | YES: FlareDialog prompt helper |
| presentDialog and presentSheet `flutter:host/presentation.dart:7-34` | 28 | DialogRoute and ModalBottomSheetRoute presenters, 7 and 11 call sites | H (belongs in kit) | YES: kit dialog and sheet presenters |
| flareMaterialTheme `flutter:host/material_theme.dart:9-23` | 15 | Material ThemeData from kit tokens | H (belongs in kit) | YES: a kit Material theme bridge |
| ChatScreen `flutter:screens/chat_screen.dart` | 289 | Chat page with app-owned message action list, forward sheet sizing, scroll to bottom | A (G fragments) | YES for the action list: `FlareMessageActionSheet.show` with availability; page composition NO |
| ContactDetailScreen `flutter:screens/social_action_screens.dart:11-210` | 200 | Detail binding plus `_editText` and `_confirm` dialogs | A (G fragments) | Dialogs YES (prompt helper, FlareDangerConfirm); binding NO |
| BaseShell `flutter:screens/base_shell.dart:19-741` | 723 | Shell, 4 tab panes, sync banner, avatar button, split placeholder, name-only create-group dialog | A (G fragments) | Pieces YES: banner to the workspace banner, avatar to a header leading slot, create group to FlareStartConversationSheet; tabs NO |
| AuthScreen and brand widgets `flutter:screens/auth_screen.dart` | 424 | Login form; brand lockup, rail and spec chips with raw TextStyle | A | NO: login flow; brand typography needs kit text roles |
| Directory and group screens `flutter:screens/social_action_screens.dart:213-1013` | 795 | Add friend, join group, requests, group detail binding | A | NO: social flows; the sent-requests list is a kit gap |
| MomentsScreen and `_MomentComposerSheet` `flutter:screens/moments_screen.dart:13-299` | 283 | Feed; composer sheet with an inline audience panel | A / H | NO: product feature; the audience sheet should become a kit overlay |
| ProfileCenterScreen and `_ProfileEditorSheet` `flutter:screens/profile_center_screen.dart:12-607` | 593 | Profile panel and 7 sheets with stubbed devices and storage | A / H | NO: settings IA |
| IM mappers `flutter:sdk/im_client.dart` | 463 | Row and message mapping plus display strings: time labels, system events, emoji labels | H (G formatting) | Partly: time and system-event wording to kit strings or the SDK |
| MomentsViewModel `flutter:viewmodels/moments_view_model.dart` | 187 | Moments view model | A | NO: the mapping model to copy |

**App-local Styles:**
- Metrics: 13 files, 6,134 LOC; Container, DecoratedBox or ClipRRect 0; EdgeInsets numeric literals 0 by the metric regex (the audit found one symmetric 24 at `flutter:screens/moments_screen.dart:266`); TextStyle literals 6; GestureDetector 1; InkWell 0; ThemeData 1; private kit imports 0; SizedBox literals 0; Material imports 10.
- 10 Scaffolds because FlareScreen is not a Material surface (`flutter:app.dart:71`; `flutter:screens/base_shell.dart:316`; `flutter:screens/chat_screen.dart:227`).
- 6 TextStyle and 4 FontWeight in the auth brand widgets (`flutter:screens/auth_screen.dart:210-219, 355-406`).
- GestureDetector avatar button with a 32 px target (`flutter:screens/base_shell.dart:337-349`).
- `withValues(alpha: 0)` for a transparent sheet background, which sidesteps the gate's color rule (`flutter:host/presentation.dart:30`).
- DialogRoute, ModalBottomSheetRoute and OverlayEntry hosts avoid the gate's dialog ban (`flutter:host/presentation.dart:10, 24, 46-69`).
- Forward picker sized to 70% of the screen height (`flutter:screens/chat_screen.dart:161`); 6 RefreshIndicators and 3 ListView empty-state wrappers (`flutter:screens/base_shell.dart:425, 506, 509`); 50 `Icons` uses.

**Missing Features:**
1. Search: 0 of 5 (conversation, message, member, global, result navigation); the container search slot is unused (`flutter:screens/base_shell.dart:404-438`).
2. Media: 0 of 9 complete; `onMediaAction` is not passed, so no image preview or audio playback (`flutter:screens/chat_screen.dart:238-252`).
3. Message states: sending, read and failed never mapped (`flutter:sdk/im_client.dart:148-162`).
4. Reply, quote, mention and copy (`flutter:screens/chat_screen.dart:92-117`).
5. Conversation actions, drafts, typing and presence; list long-press is not wired (`flutter:screens/base_shell.dart:427-436`).
6. History pagination: latest 50 only, `hasOlder` and `onLoadOlder` unused (`flutter:screens/chat_screen.dart:55-61`).
7. Reconnect handling: connection events are ignored and the banner shows a login-time snapshot (`flutter:screens/base_shell.dart:384-397`).
8. Settings: language, theme brand, real device list and blocklist view (`flutter:screens/profile_center_screen.dart:293-302`; `flutter:app.dart:55-56`).

**UX Problems:**
1. A transient list failure wipes the inbox and closes the open desktop chat (`flutter:sdk/base_social_client.dart:736-738`; `flutter:screens/base_shell.dart:441-451`).
2. Forward reports success when nothing was sent (`flutter:sdk/base_social_client.dart:825-826`; `flutter:screens/chat_screen.dart:165-173`).
3. Typed text is lost when sending fails because the kit composer clears it before the result (`kit-flutter:src/components/flare_composer.dart:230-244`; `flutter:screens/chat_screen.dart:190-201`).
4. Writes appear saved when they failed: reaction, recall, delete and social writes swallow errors (`flutter:sdk/base_social_client.dart:785-819, 966-974`).
5. Create group creates an empty group, and a failed profile load shows fabricated counts (`flutter:screens/base_shell.dart:203`; `flutter:sdk/base_social_client.dart:387-398`).
6. Event storm: every typing, presence or receipt event rereads 50 messages with serial media URL calls and a mark-read (`flutter:screens/chat_screen.dart:55-61`; `flutter:sdk/base_social_client.dart:756-758`).
7. Block and delete friend confirm through a neutral dialog, and message delete is not marked destructive (`flutter:screens/social_action_screens.dart:103-133`; `flutter:screens/chat_screen.dart:110-114`).
8. Mixed Chinese and English copy with no localization delegates, and raw exceptions in toasts (`flutter:app.dart:47-62`; `flutter:screens/base_shell.dart:87, 103`).

**Design System Gaps:**
1. STILL_PRESENT: FlareToast is display-only with no host, queue or live region (`kit-flutter:src/components/flare_toast.dart:13-35, 191`); workaround `flutter:host/presentation.dart:38-71`.
2. STILL_PRESENT: no dialog or sheet presenters, and kit docs require showDialog, which the gate bans (`kit-flutter:src/components/flare_dialog.dart:4-5`); workaround `flutter:host/presentation.dart:7-34`.
3. RESOLVED_IN_KIT_NOT_ADOPTED: FlareMessageActionSheet has availability, a reaction strip and `show()` (`kit-flutter:src/components/flare_message_action_sheet.dart:30-259`); the app passes composer actions and fails to compile (`flutter:screens/chat_screen.dart:94-116`).
4. RESOLVED_IN_KIT_NOT_ADOPTED: FlareConversationHeader replaces ChatHeader (removed) (`kit-flutter:src/components/flare_conversation_header.dart:208-222`; `flutter:screens/chat_screen.dart:228`).
5. STILL_PRESENT: no Material theme bridge, and FlareScreen is a DecoratedBox rather than a Material surface (`kit-flutter:src/components/flare_screen.dart:68`); workaround `flutter:host/material_theme.dart:9-23`.
6. STILL_PRESENT: FlareComposer clears text on send with no async result contract (`kit-flutter:src/components/flare_composer.dart:230-244`).
7. RESOLVED_IN_KIT_NOT_ADOPTED: typed poll, task, calendar and link-card contents exist (`kit-flutter:src/models/message_content.dart:136-205`); the app maps them to generic labels (`flutter:sdk/im_client.dart:249-276`).
8. STILL_PRESENT: FlareIMAppKit drops `onCommand`, toast and floating, and FlareAvatar has no `onTap` (`kit-flutter:src/application/application_composition.dart:1048-1073`); workaround `flutter:screens/base_shell.dart:337-349`.

**Status:** USABLE_PARTIAL
- About 70 real social and IM ops back auth, directory, group admin (12 of 13), moments, profile and text, image, voice, sticker and rich send; page composition is almost entirely kit widgets.
- Chat is shallow (no message states, reply, mention, search, media preview or pagination), toast, overlay and action-model code lives in the app, and 5 of 6 tests cannot compile.
- At audit time, did not compile against the kit (fixed in Round 0): `flutter analyze` 7 errors (Surface (removed, Flutter) at `flutter:screens/auth_screen.dart:167`; composer actions where message menu entries are expected at `flutter:screens/chat_screen.dart:94-116`; ChatHeader (removed) at `flutter:screens/chat_screen.dart:228`), and the lockfile lacks the kit's new `flutter_slidable` dependency.

---

## Android: flare-social-android-app

**App:** `flare-social-android-app`, a parity app.

**Platform:** Android 8.0+ (minSdk 26, targetSdk 35), single activity, arm64-v8a by default (`flare-social-android-app/app/build.gradle.kts:9-23`).

**Framework:** Jetpack Compose with Kotlin 2.2.20, AGP 8.7.3, Compose BOM 2024.12.01 and material3; JNA bridge to the C ABI. Kit `com.flare.im:im-ui-compose:1.0.7` (`flare-social-android-app/app/build.gradle.kts:56`) is substituted by an included build of `flare-im-design/packages/android-im-ui` at 2.0.0-rc.1 (`flare-social-android-app/settings.gradle.kts:45-48`).

**Purpose:** Parity app: the Compose expression of the social IM product; its session layer is a declared port of the iOS one (`android:SocialSession.kt:213-219`).

**Current Features:**
- Password, code, register and reset with a wide two-column auth layout (`android:FlareSocialApp.kt:186-352`).
- Shell on IMAppKit with a persistent inbox beside the chat on wide layouts (`android:FlareSocialApp.kt:640-688`).
- Chat: text, emoji, single image, voice, demo location, card and poll; forward; delete; 6 quick reactions; group details from the chat header (`android:ChatScreen.kt:107-113, 120-132, 158-160, 188-194, 213-240`).
- Search screen with a 250 ms debounce (`android:SearchScreen.kt:34-41`).
- Directory: contacts, requests, sent requests, add friend, join group, blocked list, create group through StartConversationDialog (`android:ContactsScreen.kt:42-114`; `android:GroupScreens.kt:41-72`).
- Group governance with a 3-state notify mode, 11 of 13 group features complete (`android:GroupScreens.kt:80-275`).
- Moments with reply-to-comment and DangerConfirm-based delete and report (`android:MomentsScreen.kt:57-258`).
- Settings: profile edit, QR, diagnostics, device sessions, reports, moments privacy (`android:SettingsScreen.kt:74-482`).

**Design System Usage:** 44 of 149 catalog components, plus ChatHeader (removed).
- Root and auth: FlareThemeProvider, StatusBanner, Toast, FlareScreen (brand), FlareBrandLogo, SegmentedControl, FormField, Input, IconButton, Button.
- Shell, messages and search: IMAppKit, EmptyState, FlareScreen, ConversationListContainer, ConversationList, SearchBar, SearchResults.
- Chat: MessageList, Composer, FlareEmojiStickerPicker, EmojiPicker, MessageActionSheet (old signature), ForwardPicker, FlareGroupedCard; ChatHeader (removed).
- Directory: ContactList, GroupList, NewFriendRequests, ContactItem, ContactDetail, ContactMatchList, DangerConfirm, FormDialog, StartConversationDialog.
- Group: FlareGroupDetail, AnnouncementReadBar, FormDialog, RadioGroup.
- Moments: MomentsCoverHeader, MomentCard, MomentComposer, MomentAudienceSheet, FormDialog, DangerConfirm.
- Settings and report: ProfilePanel, SettingsList, ProfileEditor, QRCard, DeviceSessions, MomentsVisibilityRuleList, RadioGroup, Textarea.

**App-local Components:**

| Component | LOC | Renders | Class | Should migrate? |
|---|---:|---|---|---|
| AppToastHost `android:FlareSocialApp.kt:97-108` | 12 | Top toast overlay, single slot, 6 s | G | YES: kit toast presenter and an IMAppKit toast slot |
| OverflowMenu `android:ContactsScreen.kt:125-146` | 22 | More menu on material3 DropdownMenu, reused on 3 screens | G | YES: kit Compose menu primitive |
| ContactActionRow `android:FriendActionScreens.kt:46-56` | 11 | Contact row with a trailing kit Button, used 3 times | G | YES: ContactItem trailing slot |
| ChatScreen `android:ChatScreen.kt:57-242` | 186 | Chat, Dialog-hosted message menu with an app action list, forward route | A (G menu) | YES for the menu: MessageActionSheet with availability and a presenter; page NO |
| ContactsScreen `android:ContactsScreen.kt:42-114` | 73 | Directory tabs and Row-built sent-request rows | A (G rows) | Rows YES (trailing slot, outgoing requests); tabs NO |
| MainShell `android:FlareSocialApp.kt:559-690` | 132 | Boolean route state machine around IMAppKit, no back stack | H | Partly: needs a kit back and navigation contract; routes stay app-owned |
| ThemedRoot `android:FlareSocialApp.kt:148-164` | 17 | Night override, raw Material theme, FlareThemeProvider | H | Remove the raw theme; the kit provider already supplies it |
| ConnectionBanner `android:FlareSocialApp.kt:117-140` | 24 | Connection and send-error banners | H | NO: composition of StatusBanner |
| Auth composables `android:FlareSocialApp.kt:186-545` | about 350 | Auth flows; brand rail, lockup, heading and spec strip with material3 Text; English copy | A | NO: login flow; typography needs a kit text primitive |
| GroupDetailScreen `android:GroupScreens.kt:80-275` | 196 | Kit detail binding, floating overflow over the kit header, notify dialog | A | NO: binding; the kit header needs an actions slot |
| MomentsScreen and MomentComposerScreen `android:MomentsScreen.kt:57-258` | 196 | Feed with a long-press report wrapper; composer | A | NO: product feature |
| MeScreen and 6 sub-screens `android:SettingsScreen.kt:74-482` | 357 | Settings pages as early-return routes | A | NO: settings IA |
| ReportSheet `android:ReportSheet.kt:27-130` | 98 | Report form and labels | A | NO: moderation flow; a shared kit report composite would help |
| SocialSession `android:SocialSession.kt` | 1,677 | SDK wiring, about 745 LOC of mapping, toast slot | H | Partly: shared mapping belongs in SDK view models |
| VoiceRecorder `android:VoiceRecorder.kt` | 76 | Nothing (0 references) | H | NO: delete, the kit records voice |

**App-local Styles:**
- Metrics: 14 files, 4,797 LOC (excluding `ffi/`); visual modifiers 2; dp or sp literals 0; material3 imports 10; Dialog or Popup 1; Row, Column and Box 61.
- 13 material3 Text calls with token sizes and colors (`android:FlareSocialApp.kt:357-412`; `android:ContactsScreen.kt:96, 140`; `android:ReportSheet.kt:105`).
- material3 DropdownMenu overflow menu (`android:ContactsScreen.kt:132-146`).
- Raw Material theme with default light and dark color schemes (`android:FlareSocialApp.kt:160`).
- Compose window Dialog hosting the message menu (`android:ChatScreen.kt:223-240`) and a platform Toast (`android:ChatScreen.kt:147`).
- Tap-through overlay on the SearchBar (`android:ConversationsScreen.kt:60-63`).
- Floating OverflowMenu over the kit group header (`android:GroupScreens.kt:234-246`).
- Long-press pointerInput wrapper on moments (`android:MomentsScreen.kt:123-126`); background and manual insets without IME padding in chat (`android:ChatScreen.kt:152, 173`).

**Missing Features:**
1. System back handling: no BackHandler in the app or the kit (`android:FlareSocialApp.kt:559-569`).
2. Message lifecycle: status hard-coded to sent; recalled and read never rendered (`android:SocialSession.kt:1478`).
3. Reply, quote, mention and copy; reactions are add-only and never rendered (`android:ChatScreen.kt:216-222`).
4. Conversation actions from the list: `ConversationList(onLongPress)` is unused (`android:ConversationsScreen.kt:47-52`).
5. Media preview, gallery, video, download and upload progress; uploads are awaited with no progress and fail silently (`android:SocialSession.kt:839`).
6. Received image, voice and file content keys do not match the core JSON (`android:SocialSession.kt:1521-1533`).
7. Drafts (the Compose Composer has no draft parameter), typing, presence and history pagination (`kit-android:Composer.kt:105-135`).
8. Theme persistence and localized string resources (`android:SocialSession.kt:286, 1179-1184`).

**UX Problems:**
1. System back closes the activity from chat, detail and settings sub-screens (`android:FlareSocialApp.kt:592-638`).
2. The chat composer has no IME inset under edge-to-edge (`android:ChatScreen.kt:152, 173`; `android:MainActivity.kt:16`).
3. Contact search results do nothing unless a conversation id equals the user id (`android:FlareSocialApp.kt:631-632`).
4. The auth flow is English while the rest is Chinese, and the spec strip claims a WASM core (`android:FlareSocialApp.kt:302-313, 544`).
5. Logout and device revoke run without confirmation (`android:SettingsScreen.kt:163, 366-374`).
6. Data race: `loadMessages` mutates HashMaps on a background dispatcher while the main thread reads them (`android:SocialSession.kt:755-770`).
7. On wide screens any route replaces the persistent inbox, and the forward route resets chat scroll (`android:FlareSocialApp.kt:659, 669`; `android:ChatScreen.kt:120-132`).
8. The tap-through search overlay has no semantics, and moment report hides behind a long-press gesture (`android:ConversationsScreen.kt:60-63`; `android:MomentsScreen.kt:123-133`).

**Design System Gaps:**
1. STILL_PRESENT: Toast has no presenter or queue and IMAppKit has no toast slot (`kit-android:Toast.kt:49-56`; `kit-android:ApplicationComposition.kt:498-509`).
2. STILL_PRESENT: no Compose menu or bottom-sheet primitive; the kit uses DropdownMenu only internally (`kit-android:ConversationHeader.kt:274`); workaround `android:ContactsScreen.kt:132-146`.
3. STILL_PRESENT: no back or navigation contract for FlareScreen or IMAppKit (0 BackHandler in the kit); workaround state machine `android:FlareSocialApp.kt:559-569`.
4. RESOLVED_IN_KIT_NOT_ADOPTED: MessageActionSheet with availability and a reaction strip (`kit-android:MessageActionSheet.kt:146-176`); the app passes composer actions (`android:ChatScreen.kt:213-240`).
5. RESOLVED_IN_KIT_NOT_ADOPTED: ConversationHeader replaces ChatHeader (removed) (`kit-android:ConversationHeader.kt:137-148`; `android:ChatScreen.kt:153`).
6. RESOLVED_IN_KIT_NOT_ADOPTED: FlareThemeProvider already supplies the Material theme (`kit-android:FlareTokens.kt:808-823`); the app keeps a stale raw theme (`android:FlareSocialApp.kt:160`).
7. STILL_PRESENT: ContactItem has no trailing slot and SearchBar has no read-only or click mode (`kit-android:ContactItem.kt:24-28`; `kit-android:SearchBar.kt:41-47`).
8. STILL_PRESENT: FlareGroupDetail has no header actions or report slot, and CommentThread has no input (`kit-android:FlareGroupDetail.kt:188-224`; `kit-android:MomentComponents.kt:80-84`).

**Status:** USABLE_PARTIAL
- Same well-wired surface as iOS (auth, directory, groups 11 of 13, moments, settings, text chat) plus kit DangerConfirm confirms and a 3-state notify mode.
- The message lifecycle, rich media and actions are incomplete, and there is no system back or chat IME inset; the only test needs a live backend.
- At audit time, did not compile against the kit (fixed in Round 0): `compileDebugKotlin` 22 errors (ChatHeader (removed) at `android:ChatScreen.kt:28, 153`; action list type and `id` at `android:ChatScreen.kt:231, 233`; FormDialog `onDismiss` renamed `onClose` at 9 call sites, for example `android:FriendActionScreens.kt:123, 130`).

---

## Cross-app observations

- App-owned toast presenters exist in all 5 apps, with a dedicated host in 4: `tauri:utils/panelToast.ts:23-49` (10 hosts), `flutter:host/presentation.dart:38-71`, `ios:FlareSocialRootView.swift:47-101` with timers at `ios:SocialSession.swift:296-334`, `android:FlareSocialApp.kt:97-108`; web keeps toast state and a timer in `web:social/store.ts:82-98`. No kit ships a presenter.
- Hand-built message action lists with divergent reactions in 3 apps: iOS 4 reactions on a confirmation dialog (`ios:ChatView.swift:28, 140-158`), Android 6 reactions in a Dialog (`android:ChatScreen.kt:48, 216-222`), Flutter one thumbs-up (`flutter:screens/chat_screen.dart:88-139`). All ignore kit availability and SDK `message.action_availability`; the Vue apps use the kit menu but leave items unwired (`web:components/ChatArea.vue:95-108`).
- Report dialogs are implemented 4 times: a hand-rolled modal (`sfui:components/ReportDialog.vue:53-117`), FormSheet (`tauri:components/common/ReportDialog.vue`), FormSheetView (`ios:ReportViews.swift:19-80`) and FormDialog (`android:ReportSheet.kt:71-123`), with different reason labels and preselection (`ios:ReportViews.swift:25`; `android:ReportSheet.kt:35-63`). Entry points differ too: footer buttons, overflow menus, long-press.
- The same missing contact-row trailing slot and outgoing-requests list produced 5 workarounds: `ios:MainShell.swift:166-221`, `android:FriendActionScreens.kt:46-56`, `tauri:components/groups/GroupsPanel.vue:373-381`, `web:components/ContactsTab.vue:117-136`, `flutter:screens/social_action_screens.dart:573-663`.
- Navigation diverges on every platform: web uses component state with 2 routes and duplicates the list for mobile (`web:views/MainView.vue:261-304`); Tauri nests FlareConversationWorkspace inside a single-pane shell (`tauri:views/Main.vue:329-330`); Flutter splits only the Chats tab and pushes full-screen routes elsewhere (`flutter:screens/base_shell.dart:138-157`); iOS uses NavigationStack with keep-alive tabs (`ios:MainShell.swift:42-58`); Android uses a boolean route state machine with no back stack (`android:FlareSocialApp.kt:559-638`).
- Message status mapping is wrong in all 5 apps: hard-coded sent on iOS and Android (`ios:SocialSession.swift:850`; `android:SocialSession.kt:1478`), never set in Flutter (`flutter:sdk/im_client.dart:148-162`), inverted proto numbers in Tauri (`tauri:host/chat/utils/kitMessage.ts:15-31`), no delivered state on web (`web:host/messageStatus.ts:14-34`). Own-reaction `selected` is mapped nowhere.
- Conversation row fields `mentioned`, `draft`, `pinned` and `muted` are unmapped or faked: web and Flutter never set them (`web:social/store.ts:187-196`; `flutter:sdk/im_client.dart:99-110`), Tauri bakes mention and draft into Chinese preview text (`tauri:host/chat/utils/sessionRow.ts:31, 36`). Vote, task, schedule and link-card messages become generic chips on iOS, Android and Flutter although typed kit contents exist (`ios:SocialSession.swift:899-906`; `flutter:sdk/im_client.dart:249-276`).
- Every app defines its own attach menu and drops kit defaults: 2 icon-less tiles (`web:components/ChatArea.vue:112-115`), 3 icon-less items (`tauri:components/chat/ChatPanel.vue:1147-1151`), one image action (`flutter:screens/chat_screen.dart:288-296`), canned demo payloads on iOS and Android (`ios:ChatView.swift:31-35`; `android:ChatScreen.kt:107-113`). Neither Vue app can open the emoji panel (`tauri:components/chat/ChatPanel.vue:1769-1779`).
- Breaking kit renames without deprecation broke all 5 apps at once: ChatHeader (removed) in every app (`web:components/ChatArea.vue:8`; `tauri:components/chat/ChatPanel.vue:7`; `flutter:screens/chat_screen.dart:228`; `ios:ChatView.swift:40`; `android:ChatScreen.kt:28`) plus the `onCancel` and `onDismiss` to `onClose` renames on iOS and Android, all under the unchanged version 2.0.0-rc.1. The gate has no compile step.
- Destructive actions skip the kit confirm in every app: web block, leave, dissolve, recall, delete and logout (`web:views/MainView.vue:200-212`), Tauri contact block and remove (`tauri:components/ContactDetailPanel.vue:97-106`), iOS system dialogs (`ios:FriendActionViews.swift:104, 111`), Android logout and revoke (`android:SettingsScreen.kt:163, 366-374`), Flutter neutral dialogs (`flutter:screens/social_action_screens.dart:103-133`).
