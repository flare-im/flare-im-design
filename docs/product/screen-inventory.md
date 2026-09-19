# Screen Inventory

Date: 2026-09-15 (Round 5 audit). Scope: every screen, pane, sheet, dialog, menu and full-page state a user can reach in the five flare-social reference apps.

Method: read-only static audits of each app's working tree and the kit components it composes (nothing built or run for this inventory), cross-checked for the web golden app against the running app on the application-visual fixture core (`flare-social-web-app/tests/app-visual`, captures in the Round 5 audit). All five app repos carry uncommitted work from Rounds 0 to 4, so file:line references describe this snapshot and drift as files change. Findings marked "likely" have a certain code path but an unobserved runtime effect.

Ranked problems and the plan that follows from them are in `product-refinement-audit.md`; this document is the evidence base.

## Summary

| | Web (golden) | Tauri | Flutter | iOS (second reference) | Android |
|---|---|---|---|---|---|
| Screens and states inventoried | 67 | 54 | 42 | 46 | 47 |
| Kit components rendered | 45 | 66 | 46 | 43 + presenters | 45 + toast host |
| Navigation | 4 tabs (消息 / 通讯录 / 圈子 / 我); phone bottom bar, rail from 600 | desktop window, min width 960 | 5 tabs (消息 / 通讯录 / 群组 / 圈子 / 设置) | 4 tabs, retained tab roots | 4 tabs, hand-written route state |
| Session restore | ✓ (an offline restore deletes the session) | ✓ | ✓ (a failed restore deletes the session) | ✗ | ✗ |
| Global search | ✓ overlay | ✓ drawer | ✗ | ✓ sheet | ✓ route |
| Received media opens | image preview only | ✓ | ✗ | ✗ | ✗ |
| History paging | ✓ | always "has older" | ✗ | ✗ | ✗ |
| Conversation actions (pin, mute, delete) | ✓ row menu | ✓ row menu + batch | ✗ | ✗ | ✗ |

## Status after Round 5 implementation

The tables below this section are the audit snapshot and keep its file:line references. The summary rows that changed since, verified as recorded in `product-refinement-audit.md` §8b (no signed-in session in any app). Corrected on 2026-09-16 by the matrix re-grade, which read every app column against the code: two rows here had been recorded from the change, not from the result.

| | Web (golden) | Tauri | Flutter | iOS (second reference) | Android |
|---|---|---|---|---|---|
| Session restore | ✓ (a restore whose SDK cannot load keeps the session and retries when online) | ✓ | ✓ | ✗ (SDK gap S8) | ✗ (SDK gap S8) |
| Session end (kicked, expired) | ✓ notice with 重新登录 | ✓ notice with 重新登录 above every tab | ✓ | ✓ | ✓ |
| Global search | ✓ overlay, autofocus, closes on back | ✓ drawer, message hits located | ✗ | ✓ sheet | ✓ route |
| Received media opens | ✓ (image preview downloads when handled) | ✓ after the re-grade fix (the host resolver had been using `media.resolve_access`'s source kind as the address, so nothing loaded) | ✓ kit defaults | ✓ kit defaults | ✓ kit defaults |
| History paging | ✓ with backfill (added after the re-grade: it had read the local store only) | ✓ ends at the first message | ✓ with backfill | ✓ with backfill | ✓ with backfill |
| Conversation actions (pin, mute, delete) | ✓ row menu | ✓ row menu + batch (archive removed) | ✓ kit action sheet | ✓ kit action sheet | ✓ kit action sheet |
| Forward and multi-select | ✓ (Batch 3) | ✓ (forward each fixed) | as before | as before | as before |
| Load failures | error states with 重试 | error states with 重试 | error states with 重试 | error states with 重试 | error states with 重试 |
| Phone back closes layers | ✓ (`historyBack`) | n/a (desktop) | platform | platform | ✓ system back |
| Rich-text send request | ✓ normalised document | ✓ request; the format toggle was unreachable until the re-grade fix (minimal toolbar) | ✓ | ✓ | ✓ |
| Mentions reach recipients | ✗ core drops name mentions (S14) | ✗ (S14) | ✗ (S14) | ✗ (S14) | ✗ (S14) |
| Timeline opens at the newest message | ✓ | ✓ | ✓ (app-side until Batch 6) | fixed in Batch 6 | fixed in Batch 6 |
| One pane below a usable chat width | ✓ (752 px, back in the header) | ✓ same shell | native shells follow with FR-095 | native shells follow with FR-095 | native shells follow with FR-095 |
| Settings rows tell information from actions | ✓ | ✓ | Batch 5 | Batch 5 | Batch 5 |

## Status after Round 9

Verified at build and unit level; nothing here was run signed in (the signed-in steps are in `docs/release/2.0-external-validation.md`). The rows below replace the matching rows of the Round 5 table above.

| | Web (golden) | Tauri | Flutter | iOS (second reference) | Android |
|---|---|---|---|---|---|
| One pane below a usable chat width | ✓ one rule (FR-110) | ✓ | ✓ | ✓ | ✓ |
| Who picks phone, tablet or desktop | the shell measures its own box (FR-095); `host/responsive.ts` deleted | the shell; `utils/responsiveMode.ts` deleted | the shell; the app's `LayoutBuilder` and wrapping `Scaffold` deleted | the shell; `GeometryReader` deleted | the shell; `BoxWithConstraints` mode deleted |
| Tab state across switches | kept by the shell | kept by the shell (`KeepAlive` deleted) | kept by the shell | kept by the shell (`ZStack` roots deleted) | kept by the shell (`SaveableStateHolder`) |
| Phone tab bar hides for a pushed page | from the destination's depth | n/a (desktop) | from the destination's depth | from the destination's depth (`immersive` deleted) | from the destination's depth (the boolean formula deleted) |
| Rich-text messages | the stored document (was the sender's Markdown) | the stored document | ✓ document (was plain text) | ✓ document (was plain text) | ✓ document (was plain text) |
| Albums | nine-tile album with `+N` (was four tiles and an English title) | same | ✓ (was a count) | ✓ (was a count) | ✓ (was a count) |
| Paging through a chat's pictures | ✓ | ✓ | ✓ | ✓ | ✓ |
| Picture picker | several at once, first nine sent, said so | several at once, first nine sent, said so | up to nine (`pickMultiImage`) | up to nine, in order (`PhotosPicker`) | up to nine (`PickMultipleVisualMedia`) |
| Several pictures send as | one album; nothing if an upload fails | one album; nothing if an upload fails | one album; nothing if an upload fails | one album; nothing if an upload fails | one album; nothing if an upload fails |
| Polls and tasks | read-only (no SDK op, S26) | read-only (S26) | read-only (S26) | read-only (S26) | read-only (S26) |

## Legend

| Prefix | Path |
|---|---|
| `W:` | `flare-social/flare-social-sdk/examples/apps/flare-social-web-app/src/` |
| `T:` | `flare-social/flare-social-sdk/examples/apps/flare-social-tauri-app/src/` |
| `K:` | `flare-im-design/packages/vue-im-ui/src/` |
| `SDK:` | `flare-social/flare-social-sdk/packages/flare-social-typescript-sdk/src/` |
| `TB:` | `flare-social/flare-social-sdk/bindings/tauri/src/` |
| `fl/` | `flare-social/flare-social-sdk/examples/apps/flare-social-flutter-app/lib/` |
| `ios/` | `flare-social/flare-social-sdk/examples/apps/flare-social-ios-app/Sources/FlareSocialApp/` |
| `and/` | `flare-social/flare-social-sdk/examples/apps/flare-social-android-app/app/src/main/kotlin/com/flare/social/app/` |
| `kfl/` | `flare-im-design/packages/flutter-im-ui/lib/src/` |
| `kios/` | `flare-im-design/packages/ios-im-ui/Sources/FlareIMUI/` |
| `kand/` | `flare-im-design/packages/android-im-ui/src/main/kotlin/com/flare/im/ui/` |
| `sdkfl/` | `flare-social/flare-social-sdk/packages/flare-social-flutter-sdk/lib/src/` |
| `soc/` | `flare-social/flare-social-sdk/src/` |
| `core/` | `flare-im-core-sdk/` |
| `fcore/` | `flare-core/src/` |

States: L = loading, E = empty, Err = error with retry, Off = offline, Perm = permission, Uns = unsupported; ✓ handled, ✗ missing or wrong, partial, – not applicable. Kit component names drop the `Flare` prefix. In table cells a bare `file:line` shares the prefix of the row's own component. Web `Off: G` = only the shell connection banner covers the state; Tauri `Off: C` = only the chat-tab workspace banner covers it. Kit breakpoints on all four kits: mobile < 600, tablet 600–899, desktop 900–1499, wide ≥ 1500.

## Snapshot metrics

| | Web | Tauri |
|---|---|---|
| Source files (.vue/.ts/.css) | 35 (17 .vue) | 153 (28 .vue) |
| LOC | 6,581 | 19,234 |
| App style lines (non-blank, incl. global css) | 223 | 158 |
| `:deep` / `!important` | 0 / 2 (W:app.css:27-28, reduced-motion kill also stops kit spinners) | 4 lines in 3 files (T:App.vue:98; T:components/addressbook/AddressBookPanel.vue:101-102; T:components/chat/SessionList.vue:246) / 0 |
| Kit components rendered in templates | 45 (44 in `spec/components.json` + UiProvider) | 66 (63 in catalog + UiProvider, ImagePreview, VideoPreview) |
| Screens / panes / sheets / states inventoried | 67 | 54 |

## Web (golden app): flare-social-web-app

### Navigation model

- **Routes.** Only `/` (AuthView) and `/app` (MainView), with guards in both directions (W:router.ts:8-21). Tabs, panes and sub-pages are component refs, not routes (W:views/MainView.vue:61-73, 129-159; W:components/ContactsTab.vue:61-71; W:components/MeTab.vue:31-33).
- **Boot.** The app mounts only after `restoreSessionOnBoot()` finishes, so the page is blank while the WASM core starts (W:main.ts:18-20).
- **Shell.** `FlareIMAppKit` shows 4 nav items: 消息, 通讯录 (friend-request badge), 圈子, 我; 消息 carries the unread badge (W:views/MainView.vue:99-125). Responsive mode comes from `window.innerWidth` through the kit resolver (W:host/responsive.ts:5-14; K:shared/contracts/application.ts:211-219). Breakpoints are 600 / 900 / 1500 (K:shared/contracts/layout.ts:14-19).
  - **Phone (<600).** `FlareMobileAppShell` with a bottom tab bar (K:components/layout/FlareIMAppKit.vue:49-63; K:components/layout/FlareMobileAppShell.vue:18-27). The chat tab shows one pane at a time: list, then chat, then detail (K:components/layout/FlareIMAppKit.vue:41-45; W:views/MainView.vue:148-152). The tab bar hides in chat, in chat details, and on Contacts/Me sub-pages (W:views/MainView.vue:68-73).
  - **Tablet (600-899).** Nav rail, a 320px list and the chat. Chat details always open as a right overlay aside with no scrim (K:components/layout/FlareAppLayout.vue:57, 100, 128, 134-145). At 600px the chat column is only about 208px wide (600 − 72 − 320).
  - **Desktop (900-1499) and wide (≥1500).** Always a rail: FlareIMAppKit hard-codes `presentation="rail"` (K:components/layout/FlareIMAppKit.vue:79). Chats use dual pane, or triple pane when details are open and "fit", otherwise an overlay (W:views/MainView.vue:145-153; K:components/layout/FlareAppLayout.vue:54-69). The fit check assumes a 280/320px sidebar rather than the 72px rail (K:shared/contracts/application.ts:242-257), so the overlay starts about 200px earlier than needed. 通讯录, 圈子 and 我 are a single full-width pane at every width (W:views/MainView.vue:146).
- **Details, overlays, sheets.**
  - The chat header's details action puts GroupDetailPanel or ContactDetailPanel into the `#detail` slot (W:components/ChatArea.vue:143-146; W:views/MainView.vue:134-141, 283-297).
  - Contacts and Me drill down by swapping FlareScreen pages that carry back buttons.
  - Global search and the report form sit in the `#overlay` slot and cover the whole shell (K:components/layout/FlareAppLayout.vue:148; W:views/MainView.vue:300-316).
  - BottomSheet and FormSheet render as bottom sheets on phones (isH5 ≤599) and as centered dialogs of at most 480px elsewhere (K:components/general/FlareBottomSheet.vue:33-36, 190; K:shared/platform/useFlarePlatform.ts:71).
  - Confirms (DangerConfirm) and toasts come from the provider (K:design-system/provider/FlareUiProvider.vue:90-113).
- **Back on phone widths.**
  - Only in-UI back controls exist: the chat header back (W:components/ChatArea.vue:262-263) and FlareScreen back on sub-pages.
  - Browser and system back are not wired. Panes create no history entries, and `/` redirects to `/app` for signed-in users (W:router.ts:20).
  - When opening a chat fails, a phone user lands on a header-less "选择一个会话" pane with the tab bar hidden, which is a dead end (W:views/MainView.vue:68-73, 162-195; W:components/ChatArea.vue:342-348; W:social/store.ts:494-498, 513-515, 528-530).
  - Switching tabs unmounts the tab (v-if chain), which drops sub-page state and the chat draft (W:views/MainView.vue:263-280; W:components/ChatArea.vue:244-251).

### Screens

| Screen | Entry | Form factors | Kit components | App-local + CSS | States | UX / visual issues |
|---|---|---|---|---|---|---|
| W01 Boot / session restore | Page load; restore runs before mount (W:main.ts:18-20; W:social/session.ts:57-73) | Identical everywhere: nothing rendered | none until mount | W:main.ts, W:social/session.ts; W:app.css:1-30 (26 lines) | L ✗ blank page; Err ✓ silent fallback to Auth (session.ts:70-72); Off ✗ any restore error, including offline, deletes the stored session (session.ts:70-72) | No splash or progress while WASM starts (W:social/sdk.ts:99-109). A cold start while offline logs the user out. |
| W02 Auth: password sign-in | Route `/` (W:router.ts:9); default segment (W:views/AuthView.vue:24-28, 269-273) | One centered column, max 440px, at every width (357-363) | Screen(brand), SegmentedControl, FormField, Input, Checkbox, Button, StatusBanner | W:views/AuthView.vue (385 LOC); CSS 352-385 (32 lines) | L ✓ spinner plus "Contacting gateway…" (112, 339); Err ✓ raw message banner, no retry (250-251, 257-261, 337); Off ✗ raw transport text | Auth is English while the rest of the app is Chinese (87-134, 272). Dev/marketing copy in the product: "The same Rust engine…", "87 ops, one contract", "0 network stack" (102, 342-348). Brand is plain text, with a stale "kit has no BrandLogo" comment, though K:components/index.ts:132 exports BrandLogo (267-268). |
| W03 Auth: code sign-in | Segment "Code sign-in" (269-273) | As W02 | As W02 | 285-290 | L ✓ Sending… and countdown (130-134, 170-189); Err ✓ raw | Code is "sent to this account" but the login key is an account name, so it's unclear where the code goes (104, 128). Switching segments resets the countdown (144-151). |
| W04 Auth: create account | Segment "Create account" | As W02 | As W02 | 281-283 | Inline validation ✓ (66-71, 297, 312); Err ✓ raw | No terms/privacy consent step. English copy. |
| W05 Auth: reset password | "Forgot password?" (325-327); "← Back to sign in" (274) | As W02 | As W02 | 208-222 | L ✓; Err ✓ raw; success notice ✓ (221) | Arrow glyph baked into the label (274). |
| W06 Auth: "Advanced · gateway" | Text toggle (329-334) | As W02 | Button, FormField, Input | 329-334 | – | Infrastructure config on the login screen. A corrected URL is ignored after the first attempt because `bootstrap()` memoises the first gateway (W:social/sdk.ts:111-127; AuthView.vue:176, 206). |
| W07 Main shell + global banners | `/app` (W:router.ts:10) | Phone: 4-tab bottom bar. Tablet, desktop and wide: rail (K:components/layout/FlareIMAppKit.vue:49-63, 79) | IMAppKit (MobileAppShell / AppLayout / AdaptiveNavigation), StatusBanner; Toast + DangerConfirm via UiProvider | W:views/MainView.vue (337 LOC); CSS 322-337 (14) | Off ✓ reconnecting / disconnected / kicked / expired (77-94, 228-234); send-failed banner with 关闭 ✓ (235-242); Err ✗ terminal states give no action (89-92) | "…请重新登录" has no re-login button; logout is buried in 我 › 设置 (W:components/SettingsPanel.vue:323). Banner copy stays Chinese in en-US. |
| W08 消息: conversation list | Tab 消息 (MainView.vue:107-111, 258-260) | Desktop/tablet: 320px column. Phone: full page with tab bar | ConversationListContainer, ConversationList, SearchBar (read-only), IconButton, StatusBanner, EmptyState | W:components/ConversationPane.vue (94 LOC); CSS 82-94 (11) | L ✓ skeleton (32-33; K:components/conversation/FlareConversationListContainer.vue:29); E ✓ (74-76); Err ✓ first-load error + 重试 (34, 57), stale-list banner + 重试 (64-66); Off: G | Only top-level tab without a title (57-63 vs ContactsTab.vue:184). "+" (aria 发起聊天) only switches to the Contacts home (61; MainView.vue:182-185); kit StartConversationDialog is unused (K:components/index.ts:43). Empty state has no CTA (75). |
| W09 Row menu + delete / clear confirms | Right-click, Shift+F10 or 500 ms touch long-press (K:components/conversation/FlareConversationRow.vue:39, 119-126, 199-204, 226) | Desktop: anchored menu. Phone: action sheet (FlareConversationRow.vue:291-311) | ConversationRow → ActionMenu / ConversationActionSheet, DangerConfirm, Toast | W:social/store.ts:212-219 (capabilities); ConversationPane.vue:41-53 (confirm copy) | L ✓ confirm busy; Err ✓ toast "操作未完成，请重试" (52) or error inside the dialog (K:composables/useFlareFeedback.ts:96-101) | Pin, mute, read state and delete are reachable only through hidden gestures, with no visible "more" button or swipe hint. Archive is left out on purpose (store.ts:207-211). |
| W10 Chat: nothing selected | Messages tab with no active chat (W:components/ChatArea.vue:342-348) | Desktop/tablet content column. On phone only reachable after a failed open | EmptyState | ChatArea.vue:342-348; CSS 370-372 | E ✓ | Copy "从左侧列表选择…" assumes a wide layout. On phone there's no header or back and the tab bar is hidden, so it's a dead end (MainView.vue:68-73). |
| W11 Chat: conversation view | Row select (ConversationPane.vue:71 → MainView.vue:155-159); contact/group 发消息 (162-177); search hit (188-195) | Desktop: middle column. Phone: full page, back in header (ChatArea.vue:262-263) | ConversationHeader, StatusBanner, MessageList, Composer, EmojiStickerPicker, EmptyState | W:components/ChatArea.vue (373 LOC); CSS 352-373 (20); hidden file input 333-339 | L ✓ "正在加载消息" (291-292), older-page indicator (K:components/messages/MessageList.vue:846-852); E ✓ (293); Err ✗ load failure = raw toast + "还没有消息" (W:social/store.ts:457-461), older-page failure is a toast only and `olderError` is unused (store.ts:85-87; MessageList.vue:58); Off: G + toast "网络未连接,消息未发送" (store.ts:105-112); Perm ✓ mic errors from kit (K:components/composer/EnhancedComposer.vue:270-277) | A failed load looks like an empty chat. The draft is wiped on every conversation switch and on tab change (244-251). Typed text is lost when a plain, reply or edit send fails, because the draft is cleared before the async send (174). No typing indicator or presence. 1:1 header has no subtitle (store.ts:297-311). |
| W12 Chat header actions | Header icons and identity tap (ChatArea.vue:125-146, 257-265) | Compact keeps ≤2 primary actions (129) | ConversationHeader | 125-146 | – | Only search and details: no calls, nothing in overflow. |
| W13 Message menu + 举报 + copy toast | Message context menu / hover toolbar (K:components/messages/MessageList.vue:892-925) | Desktop: hover toolbar + menu. Phone: sheet | MessageList / MessageBubble menu, Toast | ChatArea.vue:195-211 | Err ✓ toasts "回应失败" / "编辑失败" (store.ts:653, 686) | Offers react, reply, copy, edit, recall, delete, resend and 举报 (listeners 281-289). Forward, multi-select, pin, mark and download are hidden because no listener is bound (K:shared/config/messageMenu.ts:117-146), so received files have no download control (K:components/messages/MessageBubble.vue:288-296; K:components/messages/MessagesView/views/FileView.vue:71-72). 举报 is styled destructive next to 删除 (196). |
| W14 Recall / delete confirms | Menu recall / delete (ChatArea.vue:212-229) | Dialog | DangerConfirm | 212-229 | L ✓; Err ✓ raw core message inside the dialog (store.ts:657-675) | Raw error strings reach users. |
| W15 Composer: reply / edit strip | Menu reply / edit (177-187) | All | Composer (reply strip, editing) | 99-100, 160-187, 310-319 | Err ✓ toast | Editing a non-text message silently empties the draft (186). |
| W16 Composer: emoji / sticker panel | Composer toggles (93, 315) | Kit panel under the input | Composer, EmojiStickerPicker | 89-92, 321-330 | Err ✓ sticker send toast (store.ts:622) | – |
| W17 Composer: "+" attach (image / file) | Composer "+" (151, 231-235) | OS file dialog | Composer (ComposerActionPanel) | 231-241, 333-339 (CSS 367-369) | L ✗ no row appears until upload + build finish (W:social/sdk.ts:319-337; store.ts:625-638); Err ✓ generic toast | No optimistic message or progress for big files. Only image + file are offered; video/audio arrive only via mime sniffing. |
| W18 Composer: voice | Mic, via `send-voice-handler` (96-98, 304) | All | Composer (recorder) | 96-98 | Perm ✓ transient kit error; Uns ✓ "recordingUnavailable" (EnhancedComposer.vue:270-277) | Permission denial is a 2.6 s hint with no persistent guidance (EnhancedComposer.vue:262-269). |
| W19 Composer: rich text + @mention picker | Format toggle; "@" in groups (94-95, 114-121, 305-308) | All | Composer (rich input, mention list) | 114-121, 160-175 | Err ✓ rich failure restores draft (170); roster failure → no picker (W:social/directory.ts:446-449) | Mentions go out as plain text: `message.create_text` always sends `mentionAll:false` and no mention ids (W:social/sdk.ts:225-226), so members are likely not notified. Only rich sends restore the draft on failure (inconsistent with W11). |
| W20 In-chat search | Header search toggle (ChatArea.vue:144, 268) | Replaces timeline + composer in the chat column; full page on phone | Screen, SearchPanel (+ StatusBanner for locate) | W:components/ConversationSearch.vue (75 LOC); CSS 70-75 (4); W:host/locateMessage.ts | L ✓ E ✓ Err ✓ kit snapshot (34-54); locate progress / failure banner ✓ (ChatArea.vue:66-86, 267) | Two stacked headers (chat + "搜索聊天记录"). Rows show sender and text only, no time (38-49). Media hits read "[媒体消息]". |
| W21 Image preview | Tap an image bubble (K:components/messages/MessagesView/views/ImageView.vue:76-94) | Modal | ImagePreview (kit-internal) | none | kit | No download or forward from the preview (media actions unbound, W13). |
| W22 Chat details: group | Header details / identity (ChatArea.vue:140-146) → MainView.vue:134-141, 283-290 | Desktop: 300px third column when it "fits", else overlay. Tablet: overlay. Phone: full page with back | Screen, GroupDetail (+ sheets W37-W43), AnnouncementReadBar, Button, DangerConfirm | W:components/GroupDetailPanel.vue (202 LOC); CSS 200-202 (1) | L ✗ blank while loading (K:components/contacts/FlareGroupDetail.vue:288-296); E ✓ "group unavailable", which is also what a load error shows, no retry (W:social/directory.ts:416-418); Err ✗ most writes swallowed (directory.ts:464-474); Perm ✓ manager-only sections (FlareGroupDetail.vue:109-127); Off: G | No title, only a back arrow. Redundant 发消息 inside the chat's own details (GroupDetailPanel.vue:158; FlareGroupDetail.vue:70-71, 322-324). After leaving, the left group's chat stays open with a live composer (MainView.vue:288). Tablet overlay has no scrim or outside-click close (FlareAppLayout.vue:134-145). |
| W23 Chat details: 1:1 contact | Header details (ChatArea.vue:140) → MainView.vue:291-296 | As W22 | Screen, ContactDetail, FormSheet, Input, StatusBanner, Button, DangerConfirm | W:components/ContactDetailPanel.vue (143 LOC); CSS 140-143 (2) | L ✗; E ✗; Err ✓ remark/star (72, 80, 107), ✗ block/remove (see W35); Off: G | Reads a contacts cache that only the Contacts tab loads (ContactDetailPanel.vue:33; W:social/directory.ts:96-107; MainView.vue:215-223). Until Contacts is visited, the name is the raw user id with no avatar. Strangers still get 备注, 星标 and 删除好友. Disabled 语音/视频 buttons (109). 发消息 reopens the same chat. |
| W24 Global search overlay | Tap list search bar (ConversationPane.vue:60) → MainView.vue:300-301 | Covers the whole shell including the rail at every width (K:components/layout/FlareAppLayout.vue:148) | Screen, SearchBar, Button, SearchResults, EmptyState | W:components/GlobalSearch.vue (86 LOC); CSS 70-86 (15); query directory.ts:846-917 | L ✓ bar spinner (52); E ✓ idle (66) + kit no-results (K:components/general/FlareSearchResults.vue:72); Err ✗ every source `.catch(() => [])` plus an outer catch that clears (directory.ts:857-859, 906-908), so outages read as "no results"; Off ✗ | Full takeover on desktop; kit CommandPalette is unused (K:components/index.ts:179). Results capped at 8/8/12 with no "more". Contacts means friends only (searchContacts), whereas Tauri searches all users. On phone, a failed open lands in the W10 trap (MainView.vue:188-195). |
| W25 Report form sheet | 举报 in message menu (ChatArea.vue:196-207), contact detail (ContactDetailPanel.vue:122-130), group footer (GroupDetailPanel.vue:187-195), moment (MomentsTab.vue:211-219) → MainView.vue:303-315 | Phone: sheet. Wider: dialog ≤480px | FormSheet, FormField, RadioGroup, Textarea | W:components/ReportSheet.vue (103 LOC); CSS 95-103 (7); reasons from flare-social-vue-ui (15, 38); W:social/report.ts | L ✓ busy; Err ✓ generic + 429 copy (report.ts:44-47); success toast ✓ (43) | Target label falls back to raw ids (ContactDetailPanel.vue:126; GroupDetailPanel.vue:191). Entry styles differ: menu item, text link under content, footer link. |
| W26 通讯录 home (entries + A-Z friends) | Tab 通讯录 (MainView.vue:112-119, 270-276) | Single full-width column at every width (MainView.vue:146). Phone: page with tab bar | Screen, IconButton, FriendListContainer, SettingsList, ScreenHeader, ContactList | W:components/ContactsTab.vue (302 LOC); CSS 292-302 (9) | L ✓ skeleton only while empty (114); E ✓ but kit literal "No contacts yet" (K:components/contacts/FlareContactList.vue:48); Err ✗ load failure → [] (directory.ts:88-90); Off: G | No list-detail split on wide screens. The entry card and a 24px "好友" large title are pinned above the scroll area (193; K:components/conversation/FlareConversationListContainer.vue:23-26), leaving little list height on phones. The request badge only refreshes on mount or visit (only login alerts are subscribed, directory.ts:813-822). |
| W27 新的好友 (incoming + sent) + withdraw confirm | Row 新的好友 (ContactsTab.vue:137-141, 200-218) | Page; tab bar hidden on phone | Screen, NewFriendRequests, ScreenHeader, DangerConfirm | ContactsTab.vue:116-126, 200-218 | L ✗; E ✓ (210); Err ✗ list → [] (directory.ts:160-162, 195-197), accept/reject failures swallowed (165-174); withdraw ✓ error in dialog (201-208) | No feedback or next step after 接受. The 24px large-title header is reused as the "我发出的申请" section label (215). |
| W28 我的群聊 | Row (ContactsTab.vue:142-144, 221-239) | Page | Screen, Button, GroupList | 221-239 | L ✗ page renders nothing while loading (233-234); E ✓ (236); Err ✗ (directory.ts:347-349) | Blank page on slow networks. 加群 / 建群 are small ghost buttons (230-231). |
| W29 黑名单 + unblock confirm | Row (ContactsTab.vue:145-147, 242-256) | Page | Screen, ContactList (trailing), Button, EmptyState, DangerConfirm | 127-135, 178, 242-256 | L ✗ loading shown as an empty state titled "加载中…" with the block icon (178, 255); E ✓; Err ✗ (directory.ts:290-292); unblock ✓ in dialog (308-315) | Loading looks like an empty list. |
| W30 加好友 page (user search + contact-book match) | person-add icon (ContactsTab.vue:186, 259-261) | Page; the contact-book block is pinned to the bottom (AddFriendPanel.vue:195-201) | Screen, SearchBar, StatusBanner, ContactList, EmptyState, FormField, Input, Button, ContactMatchList | W:components/AddFriendPanel.vue (202 LOC); CSS 179-202 (22) | L ✓ (134-135, 148); E ✓; Err ✓ search error text but no retry button (134-135), match failure → [] (directory.ts:1007-1009); Uns ✓ hint that browsers can't read the address book (142) | Existing friends aren't flagged (no friendship check), so duplicate requests are possible. "已申请" overwrites the signature line (57-59). The bottom block squeezes results on phones. A matched user's 发消息 opens a group-by-user-ids conversation instead of a 1:1 (158 → ContactsTab.vue:260 → MainView.vue:168-176 → W:social/store.ts:502-517). |
| W31 加好友: verification message sheet | Tap a result (AddFriendPanel.vue:67-72, 110-112) | Sheet / dialog | FormSheet, FormField, Input | 162-175 | L ✓ busy; Err ✓ generic "发送失败，请重试。" (85) | Server reasons (already friends, blocked, pending) collapse into one message (directory.ts:253-261). |
| W32 加入群聊 page (group search) | 加群 in 我的群聊 (ContactsTab.vue:230, 264-266) | Page; back returns to 我的群聊 | Screen, SearchBar, StatusBanner, GroupList, EmptyState | W:components/JoinGroupPanel.vue (118 LOC); CSS 102-118 (15) | L ✗ empty state says "未找到群聊" while a search runs (77-82); E ✓; Err ✗ (directory.ts:702-704) | No join-by-invite-code path, though group details generate codes (K:components/contacts/FlareGroupDetail.vue:421-433; SDK:modules/group.ts:75). |
| W33 加入群聊: apply sheet | Tap a result (JoinGroupPanel.vue:35-43) | Sheet / dialog | FormSheet, FormField, Input | 85-98 | L ✓; Err ✓ generic (56) | "已申请加入" also shows for open groups joined instantly (53). No 进入群聊 next step. |
| W34 创建群聊 sheet | 建群 (ContactsTab.vue:231, 287) | Sheet / dialog | FormSheet, FormField, Input, ContactList (selectable), EmptyState | W:components/CreateGroupDialog.vue (108 LOC); CSS 98-108 (9) | L ✗ "暂无好友可邀请。" while contacts load (35, 91); Err ✓ generic (60) | Name and ≥1 member are mandatory (47); Tauri makes members optional. No member search. Opens the new chat automatically (ContactsTab.vue:168-176). |
| W35 Contact detail page (+ remark/description sheet, block/remove confirms) | Friend row (ContactsTab.vue:157-160, 269-275) | Page | Screen, ContactDetail, FormSheet, Input, StatusBanner, Button, DangerConfirm | ContactDetailPanel.vue | Err ✓ edits (72, 80); Err ✗ block/remove confirms always close as success because the store swallows errors (directory.ts:134-142, 297-305) | Disabled 语音/视频 always rendered (109). The "Flare ID" row shows the raw user id (K:components/contacts/FlareContactDetail.vue:62). 举报此人 is a small link below the danger zone (122-130). |
| W36 Group detail page | Group row (ContactsTab.vue:161-164, 278-285) | Page | Screen, GroupDetail, AnnouncementReadBar, Button | GroupDetailPanel.vue | As W22 | The 群成员 row is an inert value row: no full member list, search or profile (FlareGroupDetail.vue:97, 163-186). Taps by non-managers on members, name or announcement do nothing (169, 230-234). Notifications are on/off only; 仅@我 isn't offered (directory.ts:624). |
| W37 Group: edit name / announcement / my nickname | Managers tap 群名称 / 群公告; anyone taps 我的群昵称 (FlareGroupDetail.vue:163-176) | Sheet / dialog | FormSheet, Input | GroupDetailPanel.vue:108-112 | L ✓; Err ✓ thrown message (FlareGroupDetail.vue:156-158) | Members can't read a long announcement beyond the one-line row detail (96). |
| W38 Group: member action sheet (+ remove confirm) | Manager taps a member (FlareGroupDetail.vue:230-234, 343-354) | Sheet / dialog | BottomSheet, Button, DangerConfirm | GroupDetailPanel.vue:135-143, 170-173 | Err ✗ set-admin / mute / transfer / remove failures swallowed (directory.ts:464-474, 495-510) | Sheet title "成员管理" doesn't name the member. Admins can act on other admins. No view-profile or message entry. |
| W39 Group: transfer owner confirm | 转让群主 in W38 (FlareGroupDetail.vue:253-260, 357-365) | Sheet / dialog | BottomSheet, Button | – | Err ✗ swallowed | A bottom sheet with two buttons, while every other destructive confirm uses DangerConfirm. |
| W40 Group: invite members sheet | "+" tile in member grid (FlareGroupDetail.vue:265-269, 368-386) | Sheet / dialog (80vh) | BottomSheet, ContactList (selectable), Button | GroupDetailPanel.vue:95, 114-116 | L ✗ shows "no one to invite" while contacts load (379); Err ✗ swallowed (directory.ts:492-493) | No search in the picker. |
| W41 Group: join policy sheet | 进群方式 (FlareGroupDetail.vue:176-178, 389-397) | Sheet / dialog | BottomSheet, RadioGroup, Button | GroupDetailPanel.vue:162 | Err ✗ swallowed (directory.ts:530-535) | – |
| W42 Group: join requests sheet | 入群申请 (FlareGroupDetail.vue:179-181, 400-418) | Sheet / dialog | BottomSheet, Avatar, Button | GroupDetailPanel.vue:62-66, 167-168 | L ✓ (402); E ✓ (403); Err ✗ list → [] (directory.ts:580-582), respond swallowed (595-597) | – |
| W43 Group: invite link sheet | 邀请链接 (FlareGroupDetail.vue:182-184, 421-433) | Sheet / dialog | BottomSheet, Button | GroupDetailPanel.vue:169 | L ✓ (424); Err ✓ "cannot generate" but the cause is dropped (directory.ts:666-668) | Only a raw code with a copy button, and copy failure is silent (FlareGroupDetail.vue:214-224). No link, QR or share. Web has no screen that redeems the code. |
| W44 Group: announcement read bar | Shown when an announcement exists (GroupDetailPanel.vue:97-106, 178-186) | Inline | AnnouncementReadBar | 178-186 | Err ✗ a failed confirm silently stays unread (directory.ts:1026-1035) | – |
| W45 Group: leave / dissolve confirm | 退出群聊 / 解散群聊 (FlareGroupDetail.vue:325-327) | Dialog | DangerConfirm | GroupDetailPanel.vue:121-134 | Err ✗ store swallows the error; dialog closes and `left` fires (directory.ts:709-727) | – |
| W46 圈子 feed | Tab 圈子 (MainView.vue:120, 278) | Full content width on desktop (kit moments components have no max width). Phone: page with tab bar | Screen, Button, MomentsCoverHeader, StatusBanner, MomentCard, EmptyState | W:components/MomentsTab.vue (308 LOC); CSS 295-308 (12); W:social/useMomentsViewModel.ts | L ✓ neutral "加载中…" banner (228); E ✓ (222-227); Err ✓ banner with no retry (198), like/comment/delete errors reuse it (useMomentsViewModel.ts:75-77); Off: G | Author avatar, name, likers and images look tappable but are unbound (209; K:components/moments/FlareMomentCard.vue:45-54, 93). Tapping my cover avatar opens the composer (194). Signature is hard-coded "记录生活的每一刻" (193). Cover is a URL and is lost on reload (66-67, 72). 举报 is a loose text button under each card (211-219). |
| W47 圈子: publish sheet | 发布 (MomentsTab.vue:185, 116-125) | Sheet / dialog (90vh) | BottomSheet, MomentComposer | 131-141, 233-246 | L ✓ busy; Err ✗ failure goes to the feed banner behind the sheet (useMomentsViewModel.ts:124-127) | Images are hand-typed URLs (71-75, 83-89); no upload. |
| W48 圈子: audience sheet | 谁可以看 in composer (244, 249-262) | Sheet / dialog | BottomSheet, MomentAudienceSheet | 54-65 | L ✗ friend list may still be loading (124) | – |
| W49 圈子: URL / location prompt | Add image, location or cover (69-89) | Sheet / dialog | FormSheet, FormField, Input | 265-276 | – | Hint "示例应用直接填链接" is shown to users (72-73). |
| W50 圈子: comment / reply sheet | 评论, or tap a comment (143-154) | Sheet / dialog | FormSheet, Input | 155-168, 279-290 | Err ✗ sheet closes and text is cleared even when the comment fails (155-164) | No delete for own comments (SDK:modules/moments.ts:65 unused). |
| W51 圈子: delete confirm | Card menu 删除 (170-179) | Dialog | DangerConfirm | – | Err ✗ VM swallows, dialog closes, error lands in the feed banner (useMomentsViewModel.ts:154-163) | – |
| W52 我 (home) | Tab 我 (MainView.vue:121, 280) | Full width on desktop; page on phone | Screen, ProfilePanel | W:components/MeTab.vue (197 LOC); CSS 182-197 (14) | L ✗ profile falls back to raw id or "未登录" (directory.ts:745-755); Err ✗ | 朋友圈 row does nothing (55; no branch in 86-93). `@logout` is bound but ProfilePanel never emits it (113; K:components/profile/FlareProfilePanel.vue:38), so there's no logout here. Header hard-codes "Flare ID:" (FlareProfilePanel.vue:57). |
| W53 编辑资料 | Tap profile header (MeTab.vue:110, 117-133) | Page | Screen, ProfileEditor | 37-48, 95-100; hidden file input 126-132 | L ✓ busy; Err ✗ save and avatar failures swallowed, then it returns home as if saved (95-100; directory.ts:770-772, 785-787) | No success or failure feedback. |
| W54 我的二维码 page | Row or QR badge (MeTab.vue:52, 81-84, 111) | Page | Screen, QRCard, SettingsList | 75-77, 135-153 | L ✗ "QR code unavailable" until loaded (K:components/profile/FlareQRCard.vue:46-66); Err ✗ (directory.ts:835-837) | Shows a truncated raw "二维码令牌" row (75-77, 151). No save or share. Nothing in either app scans it (SDK:modules/relation.ts:188 unused). Subtitle is the signature here but Flare ID in 设置 (SettingsPanel.vue:389). |
| W55 我的举报 page | Row (MeTab.vue:56, 89-92, 155-171) | Page | Screen, SettingsList, EmptyState | 62-73 | L ✗ `myReportsLoading` unused, so it shows empty while loading; Err ✗ → empty (report.ts:61-62) | Rows show raw target ids (67) and are buttons that do nothing (K:components/profile/FlareSettingsRow.vue:25-33). |
| W56 设置 list | 我 › 设置 (MeTab.vue:57, 87, 173-178) | Page; sub-surfaces are sheets (phone) or dialogs | Screen, SettingsList | W:components/SettingsPanel.vue (502 LOC); CSS 491-502 (10) | L ✗ privacy toggle reads "off" until loaded or after a failure (296); Err ✗ | IA: 隐私 holds one toggle while 朋友圈权限/范围 sit under 账号 (288-321). 联调诊断 appears in end-user settings (313-319). 退出登录 has no confirmation (323, 373-375; MainView.vue:197-209). |
| W57 设置: 外观 (inline cycle) | Tap 外观 (276, 340-342) | – | SettingsList | W:host/theme.ts:31-39 | – | A value row with no chevron that cycles 跟随系统 → 浅色 → 深色 per tap. No picker or preview. |
| W58 设置: 语言 (inline flip) | Tap 语言 (277-283, 343-345) | – | SettingsList | – | – | Flips kit strings only. App strings stay Chinese (e.g. MainView.vue:108-121, ConversationPane.vue:42-75) and Auth stays English, so the UI is mixed-language in both locales. |
| W59 设置: 通知 sheet | Tap 通知 (346-348, 436-447) | Sheet / dialog | BottomSheet, NotificationPreferences | W:host/notifications.ts (80 LOC) | Perm ✓ (notifications.ts:28-52); Uns ✓ (47-48) | Preferences are saved but nothing reads them; no Notification or sound anywhere (54-71), so this is a dead setting. The permission button label shows only when state is "loading" (442; 36-37). |
| W60 设置: 存储空间 sheet | Tap row (349-352, 450-465) | Sheet / dialog (86vh) | BottomSheet, StorageUsage | W:host/storage.ts (57 LOC) | L ✓; Err ✓ retry; Uns ✓ (storage.ts:18-21) | Technical category names "IndexedDB / Cache Storage / Service Worker" (34-36). |
| W61 设置: 允许陌生人发消息 toggle | Toggle (288-299, 327-336) | – | SettingsList | – | L ✗; Err ✗ swallowed, switch snaps back silently (332-334) | Only 1 of the SDK's privacy fields is exposed; friend verification and profile/mobile/email visibility exist only in Tauri (T:components/settings/PrivacySettingsDrawer.vue:266-280). |
| W62 设置: 我的二维码 sheet | Tap row (353-356, 385-394) | Sheet / dialog | BottomSheet, QRCard | – | L ✗ / Err ✗ (as W54) | Duplicates W54 with a different subtitle. |
| W63 设置: 朋友圈权限 sheet + friend picker | Tap row (368-372, 408-433) | Sheet, then a second stacked sheet | BottomSheet, MomentsVisibilityRuleList, ContactList, EmptyState | 236-266 | L ✓ lists (417, 424); picker L ✗ "没有可添加的好友" while contacts load (254, 432); Err ✗ add/remove failures ignored (257-266; directory.ts:973-975) | Sheet-on-sheet stacking on phones. |
| W64 设置: 朋友圈范围 sheet | Tap row (364-367, 397-405) | Sheet / dialog | BottomSheet, RadioGroup | 219-234 | Err ✗ closes even when the update fails; radio silently reverts (232; directory.ts:1057-1059) | – |
| W65 设置: 多设备登录 sheet + 下线 confirm | Tap row (357-360, 468-478) | Sheet / dialog; confirm is a FormSheet | BottomSheet, DeviceSessions, StatusBanner, Button, FormSheet | 102-130 | L ✓; E ✓ kit; Err ✓ + retry (directory.ts:801-809; 471); revoke Err ✓ (128); unknown-current-device warning ✓ (470) | Two refresh controls (kit reload + extra 刷新, 472). The 下线 confirm is a FormSheet with a bare `<p>` instead of DangerConfirm (475-478). |
| W66 设置: 联调诊断 sheet | Tap row (361-363, 481-487) | Sheet / dialog (86vh) | BottomSheet, StatusBanner, SettingsList, Button | 134-217 | Off ✓ connection summary (135-151) | Raw keys and payloads (gateway, imWs, userId, event JSON) in end-user UI (159-193). Read-only rows render as buttons. Copy failure is silent (209-211). |
| W67 退出登录 | Settings row (323, 373-375) → MainView.vue:197-209 | – | SettingsList, Toast | MainView.vue:197-209 | Err ✓ toast (200-202) | No confirmation; Tauri confirms (T:views/Main.vue:306-319). |


## Tauri: flare-social-tauri-app

### Navigation model

- **Routes.** `/` (Auth) and `/app` (Main); `/app` requires a stored gateway session (T:router.ts:6-18). No per-pane routes or history.
- **Window.** Default 1280×840, minimum 960×640 (`flare-social-tauri-app/src-tauri/tauri.conf.json:17-20`). The packaged app therefore always resolves to desktop (900-1499) or wideDesktop (≥1500) (T:utils/responsiveMode.ts:5-11; K:shared/contracts/application.ts:211-219). Phone and tablet branches are only reachable in a narrow browser preview, where the SDK isn't even initialised (T:App.vue:52-53).
- **Shell.** `FlareIMAppKit` with `pane-mode="singlePane"` and hidden details, i.e. a rail plus one content region (T:views/Main.vue:323-331).
  - The rail holds 3 tabs (消息, 通讯录, 圈子) and a trailing system group 搜索 / 设置 / 我的资料 / 退出 pinned to the bottom (T:views/Main.vue:199-221; K:components/layout/FlareAdaptiveNavigation.vue:136).
  - System items open drawers or a confirm; the highlighted tab doesn't change (T:views/Main.vue:223-232).
  - Tab contents live in `<KeepAlive>` (T:views/Main.vue:334-362).
- **Chat tab.** `FlareConversationWorkspace` → `FlareResponsiveLayout` measures its own container: a 320px list plus the chat. Chat settings get a 300px third column only when the container holds the list, a usable chat and the detail (320 + 360 + 300 = 980px, the kit's one pane rule since Round 9); otherwise settings replace the chat column (K:components/layout/FlareResponsiveLayout.vue; K:shared/contracts/application.ts `resolvePaneMode`; T:components/chat/ChatPanel.vue:471-475, 1655-1664). The header back button only appears in mobile mode (ChatPanel.vue:1696-1697).
- **Address Book.** `FilterTabs` for 新的联系人 / 我的联系人 / 我的群组 / 黑名单 above a `FlareWorkspaceFrame` (320px list plus a detail pane via FlareAppLayout and viewport mode) (T:components/addressbook/AddressBookPanel.vue:44-49, 76-96; T:components/contacts/ContactsPanel.vue:480-527; T:components/groups/GroupsPanel.vue:312-343). This is a different responsive rule from the chat tab.
- **Moments.** One scrolling FlareScreen (T:components/moments/MomentsTab.vue:212-266).
- **Overlays.**
  - 搜索, 设置, 我的资料 and 通知与隐私 are right-side drawers of at most 420px (`presentation="drawer"`) (T:components/search/GlobalSearchDrawer.vue:259; T:components/settings/AppSettingsDrawer.vue:250; T:components/user/UserProfileDrawer.vue:187; T:components/settings/PrivacySettingsDrawer.vue:261; K:components/general/FlareBottomSheet.vue:194).
  - Every other BottomSheet or FormSheet renders as a centered dialog on desktop (K:components/general/FlareBottomSheet.vue:33-36).
  - Peer profile, in-chat search, forward, read receipts and previews are dialogs over the chat (ChatPanel.vue:1843-1892). The report dialog is mounted once globally (Main.vue:369).
- **Cross-tab jumps.**
  - Contact or group 发消息 → chat tab (Main.vue:282-292).
  - Chat 群管理, 邀请成员 and member taps → Address Book group details (Main.vue:294-299; ChatPanel.vue:1072, 1819).
  - List "+" menu → Address Book sheets (Main.vue:238-243).
  - Accepting a friend request → chat (ContactsPanel.vue:418-421).
- **Back on narrow widths (preview only).**
  - The bottom bar shows all 7 items including 退出, scrolls horizontally and is never hidden, because Main passes no `hide-mobile-navigation` (K:components/layout/FlareAdaptiveNavigation.vue:125-135; Main.vue:323-331).
  - Chat header back closes the conversation (ChatPanel.vue:487-494). Settings panes and contact/group details use FlareScreen back.
  - There is no history integration.

### Screens

| Screen | Entry | Form factors | Kit components | App-local + CSS | States | UX / visual issues |
|---|---|---|---|---|---|---|
| T01 Cold-start restore | Launch with a stored gateway session (T:views/Auth.vue:303-326; T:router.ts:14-18) | Desktop window | StatusBanner (pulse), Toast | T:views/Auth.vue; T:utils/sessionRestore.ts | L ✓ "正在恢复上次登录的会话与消息…" (484-489) + sync % (576); Err ✗ restore failure only logged (321-323); warning toast when IM is down (310-312) | After a failed restore the login form appears with no explanation. Main runs the restore again (T:views/Main.vue:263-276). |
| T02 Auth: 登录 | Route `/` (T:router.ts:9); segment 登录 (Auth.vue:49-54, 492) | Two columns (brand + card) ≥860px, one column below via a custom media query rather than kit breakpoints (595-631) | Screen, EmptyState, SettingsList, SegmentedControl, FormField, Input, Button, StatusBanner, Toast | T:views/Auth.vue (632 LOC); CSS 593-632 (38); T:components/common/SyncProgressBanner.vue (33 LOC) | L ✓ CTA spinner + phase banner (576-586); Err ✓ known codes translated (228-243), others raw; Off ✗ raw | EmptyState and SettingsList are misused as brand block, form heading and marketing list; the feature rows are buttons with chevrons (257-267, 473-481, 490; K:components/profile/FlareSettingsRow.vue:25-45). "用户 ID / 请输入真实用户 ID" asks for an internal id (496-497). Developer toasts: "请启动 flare-im-core（./scripts/start_server.sh）…", "IM 已连接：ws://…" (445-455). No show-password control. |
| T03 Auth: 验证码登录 | Segment (492) | As T02 | As T02 | 337-361, 504-522 | L ✓ sending + countdown (221-225); Err ✓ server cooldown drives the countdown (354-357) | – |
| T04 Auth: 注册 | Segment (492) | As T02 | As T02 | 499-501 | Validation ✓ first error surfaced (153-165, 390-395) | Display name silently defaults to the user id (432). |
| T05 Auth: 找回密码 | "忘记密码？" (548-550); "← 返回登录" (493) | As T02 | As T02 | 364-388 | L ✓; Err ✓; success notice ✓ (382) | – |
| T06 Auth: 服务器设置 | "服务器设置" toggle (553-572) | As T02 | Button, FormField, Input | 60-90 | – | Social gateway and IM WebSocket URLs are editable on the login screen, with infrastructure hints (563-569). |
| T07 Main shell (rail) | `/app` (T:router.ts:10) | Packaged: rail, 3 tabs + 4 system items at the bottom. Narrow preview: 7-item scrolling bottom bar incl. 退出, never hidden (K:components/layout/FlareAdaptiveNavigation.vue:125-136) | IMAppKit, AdaptiveNavigation | T:views/Main.vue (372 LOC); no CSS | Off ✗ no shell-level banner (only the chat tab has one) | Logout sits in primary navigation. Opening 搜索 / 设置 / 我的资料 leaves the previous tab highlighted (223-232). Theme is fixed to light (T:App.vue:78). |
| T08 Logout confirm | Rail 退出 (Main.vue:217, 231) | Dialog | DangerConfirm | 306-319 | L ✓; Err ✓ in dialog | – |
| T09 Global event toasts | Social push events (Main.vue:88-99, 125-173) | Top-center | Toast | 113-173 | – | Join-request toast prints the raw group id "有新的入群申请（群 …）" (170). The new-device alert has no device list to review (136-143). |
| T10 Chat workspace (panes + banner) | Tab 消息 (Main.vue:206, 335-348) | 320px list + chat. Settings as third column only when the workspace is ≥1100px, else it replaces the chat column (K:components/layout/FlareResponsiveLayout.vue:42-67) | ConversationWorkspace, ResponsiveLayout, StatusBanner | T:components/chat/ChatPanel.vue (1911 LOC); CSS 1895-1911 (15) | Off ✓ banner for Disconnected / Connecting (248-253); Err ✗ kicked and token-expired are unhandled: the hub maps kicked to Disconnected and nothing subscribes to either callback (T:host/events/createImEventHub.ts:153-154, 388-396) | After being kicked, the banner promises "IM 未连接，消息将在重新连接后同步". |
| T11 Session list pane | Workspace list slot (ChatPanel.vue:1667-1685) | Left column | ConversationListContainer, ScreenHeader, IconButton, ActionMenu, SearchBar, ConversationList, EmptyState, ConversationBatchToolbar | T:components/chat/SessionList.vue (250 LOC); CSS 238-250 (11, incl. `:deep(.im-conv-list)` 246-249) | L ✓ (112-114); E ✓ with 打开通讯录 (214-221), no-match state with 清空搜索 (205-212); Err ✗ a load failure is only logged and reads "还没有会话" (ChatPanel.vue:733-735); Off: C | The search field is a local title/preview filter (85-96) while global search lives in the rail: two search concepts. Icon-only refresh (180). |
| T12 新建 menu | "+" in list header (SessionList.vue:118-128, 181-183) | Anchored menu | ActionMenu, IconButton | 118-133 | – | 创建群聊 / 添加联系人 leave the chat tab and open sheets in Address Book (Main.vue:238-243). |
| T13 Row menu + clear / delete confirms | Context menu on a row (SessionList.vue:65-73, 147-150) | Menu | ConversationRow menu, DangerConfirm, Toast | ChatPanel.vue:1099-1153 | Err ✓ raw toast (1150-1152); success toasts ✓ | 归档 (toast "会话已完成") removes the conversation, and no archived view exists to get it back (1126-1130; T:host/utils/conversationList.ts:163-164). |
| T14 批量管理 + batch toolbar | 新建 › 批量管理会话 (SessionList.vue:121, 130-133) | Checkbox rows + footer toolbar | ConversationList (selectable), ConversationBatchToolbar, DangerConfirm | SessionList.vue:224-232; ChatPanel.vue:1155-1183 | L ✓ busy; Err ✓ partial-failure count (1177) | Batch archive has the same no-way-back problem. Batch mode is hidden inside the "+" menu. |
| T15 Chat welcome | No active conversation (ChatPanel.vue:1808) | Chat column | EmptyState, SettingsList, Button | T:components/chat/ChatWelcome.vue (50 LOC); CSS 36-50 (13) | E ✓ | Onboarding steps are settings rows that look tappable and do nothing (9-19, 31). Copy says "从左侧列表" (27). |
| T16 Chat view (header, timeline, typing, composer) | List select (SessionList.vue:135-138 → ChatPanel.vue:760-775); contact/group 发消息 (636-650) | Chat column; header back only in mobile mode (1696-1697) | ConversationHeader, MessageList, TypingIndicator, Composer, EmojiStickerPicker | ChatPanel.vue:1689-1806 | L ✓ skeleton on first open (483); E ✗ no empty slot, so new chats show a blank timeline (1732-1764); Err ✓ open-from-another-tab failure pane + 重试 (481-485, 496-504), ✗ when selecting from the list, since `selectSession` rejections are unhandled (760-775, 839-866); older-page errors only logged (888-911); Off: C | `has-older` is hard-coded true, so "load older" never ends (1738). Delivery state is wrong: read receipts write status 4, which is FAILED (617, 940-942; T:host/chat/utils/kitMessage.ts:21-23), and failed acks write 5 = RECALLED, rendered as sent (T:host/chat/utils/messageMutations.ts:87; ChatPanel.vue:1346-1347). The 1:1 subtitle says offline until a presence push arrives, because the initial presence fetch isn't routed (D.4). No @mention picker (1769-1792). |
| T17 Header actions + overflow | Header (ChatPanel.vue:1032-1073) | Compact ≤2 primary (1057) | ConversationHeader, ActionMenu | 1047-1073 | – | 邀请成员 jumps to Address Book (1072; Main.vue:294-299). Identity tap opens the peer sheet for 1:1 but settings for groups (1019-1027). |
| T18 Group chat 消息 / 公告 tabs + 群公告 page | FilterTabs in every group chat (422-425, 1701, 1712-1718) | Chat column | FilterTabs, Screen, AnnouncementBanner, EmptyState, Button | 1712-1718 | E ✓ (1714) | A permanent tab strip costs timeline height. 编辑公告 is shown to every member and just opens settings (1716). |
| T19 Announcement banner + pinned message bar | Group announcement or pinned messages (394-400, 1620-1627, 1703-1710) | Above timeline | AnnouncementBanner, PinnedMessageBar | 794-796, 812-821 | – | Dismissal is in-memory only (174, 794-796). Jumping to a pinned message outside the loaded page just shows a toast (815-818). |
| T20 Message menu (kit) | Context menu / hover toolbar (1732-1760) | Menu / sheet | MessageList / MessageBubble menu, Toast | 1415-1618 | Err ✓ raw toasts (1423-1425, 1481-1483, 1490-1492) | Rich action set (react, reply, edit, recall, delete, pin, mark, forward, multi-select, preview, download), but: 标记 is one-way (T:flare-sdk/api/message.ts:467 unmark unused); messages can't be reported (the target only has a label, T:composables/useReportDialog.ts:64); 打开文件夹 only toasts (1606-1609). |
| T21 Recall / delete confirms | Menu (1450-1474) | Dialog | DangerConfirm, Toast | 1450-1474 | Err ✓ recall error in dialog; delete failures counted (1463-1473) | The delete confirm names the conversation, not the message (1461). |
| T22 Multi-select + batch toolbar | Menu 多选 (1400-1413, 1721-1731) | Toolbar above timeline | MessageBatchToolbar | 1384-1413 | L ✓ busy | – |
| T23 Forward picker | 转发 / batch forward (1510-1521, 1886-1888) | Untitled dialog | BottomSheet, ForwardPicker | 1523-1555 | L ✓; Err ✓ raw toast (1550-1552) | Targets are limited to existing sessions (1523-1533). A mid-way failure gives no per-target result. |
| T24 Read receipt sheet (1:1) | Overflow 已读回执 (1048, 1064-1065, 1630-1638) | Untitled dialog | BottomSheet, ReadReceiptSheet | 1629-1651 | E ✓ toast when nothing to show (1633) | Only covers the latest own message. Not available in groups (1629). |
| T25 Image / video / rich-text preview | Tap media or 预览 (1557-1600) | Modal / dialog (90vh) | ImagePreview, VideoPreview, BottomSheet, MarkdownPreview | 1864-1884 | L ✓ image; Err ✓ image retry (1864-1874); video Err ✗ (1875-1881) | – |
| T26 Composer (reply/edit, emoji/sticker, file/image/video, voice, rich text) | Composer (1767-1805) | Footer | Composer, EmojiStickerPicker | 1188-1361; hidden file input 1768 | Err ✓ toast + draft restored (1351-1357); drafts per conversation ✓ (226-227); L ✗ no upload progress (1226 uses plain upload; progress wrappers T:flare-sdk/api/media.ts:86-93 unused) | Rich-text mode can't send because its commands aren't routed (D.4). A failed attachment send can stay "sending": when `assertSendAckSuccess` throws, the optimistic row is never updated (1270-1277). |
| T27 In-conversation search dialog | Header 搜索 (803-806, 1862) | Dialog (86vh) | BottomSheet, SearchPanel | T:components/chat/ChatInConversationSearch.vue (117 LOC); no CSS | L ✓ E ✓ Err ✓ (67-81) | One "全部消息" filter and no time range (110), versus web's 7 filters + 3 ranges. Meta shows the internal "#seq" (54). zh-CN date format is hard-coded (44). Hits outside loaded history can't be opened (ChatPanel.vue:815-818). |
| T28 Peer profile sheet | 1:1 identity tap (1019-1027, 1843-1860) | Dialog | BottomSheet, ProfileCard, StatusBanner, FormField, Input, Button, SettingsList | T:components/chat/ChatPeerProfilePopover.vue (109 LOC); CSS 101-109 (7) | L ✗ profile fetched silently (ChatPanel.vue:444-459) | The card's 发消息 opens chat settings (86). 语音/视频 hit an unrouted command and end in an error toast, with no call UI (86; ChatPanel.vue:989-1008), contradicting the "calls stay hidden" comment (1029-1031). Presence is shown twice (86-87). Strangers see "添加为联系人后可设置备注" with no add button (95). This is the third place to edit a remark. |
| T29 1:1 chat settings pane | 会话设置 (1054, 1070, 1827-1838) | Third column when it fits, else replaces the chat column | Screen, Skeleton, SettingsRow, FormField, Input, Button, SettingsList, DangerConfirm | T:components/chat/ContactChatSettingsPanel.vue (231 LOC); CSS 216-231 (14); T:components/common/UserAvatar.vue | L ✓ skeleton (192); Err ✗ load failure = toast + blank pane (59-61, 193); toggles revert with a toast ✓ (66-90) | Generic title "设置" (190). Placeholder row "创建群组 · 即将支持" (140). The profile row isn't tappable, so the chat offers no route to profile, block or report (194-198). 清空聊天记录 and 从列表移除 are value rows with no chevron (150-151). |
| T30 Group chat settings pane | 会话设置 / group identity (1022-1024, 1812-1826) | As T29 | Screen, Skeleton, SettingsRow, GroupMemberGrid, SettingsList, FormField, Input, Button, DangerConfirm | T:components/chat/GroupChatSettingsPanel.vue (286 LOC); CSS 275-286 (10); T:components/chat/ChatSettingsMembersSection.vue (53 LOC) | L ✓ skeleton (246); Err ✗ blank on load failure (77-79); Perm ✓ read-only announcement hint (265) | 群管理, member taps and 邀请 all jump to Address Book (123-126; ChatSettingsMembersSection.vue:37-46). 消息免打扰 writes IM conversation mute (111-121) while group details write Social notifyMode (T:components/GroupDetailPanel.vue:326-334), so two switches can disagree. Owners get 退出群组 instead of 解散 (141-154, 201). Announcement is an inline editor here but a sheet in group details (264-269). Roles are inferred by regex on labels (ChatSettingsMembersSection.vue:29-30). |
| T31 Address Book shell (category tabs) | Tab 通讯录 (Main.vue:207, 349-360) | Tabs above a content frame | Screen, FilterTabs | T:components/addressbook/AddressBookPanel.vue (103 LOC); CSS 99-103 (3, `:deep(.flare-screen__body)` 101-102) | – | Category names differ from web: 新的联系人 / 我的联系人 / 我的群组 vs 新的好友 / 好友 / 我的群聊 (44-49). |
| T32 我的联系人 (list + detail frame) | Category (AddressBookPanel.vue:80-87) | WorkspaceFrame: 320px list + detail pane; single pane with back below 600px | WorkspaceFrame, FriendListContainer, ScreenHeader, IconButton, Button, ContactList, EmptyState | T:components/contacts/ContactsPanel.vue (638 LOC); CSS 634-638 (3) | L ✓ (286-289); E ✓ (504-509), placeholder "选择一位联系人" (521-526); Err ✗ raw toast only, no error state (265-267); Off ✗ | The header crams in a privacy-settings gear, refresh and 添加好友 (490-495). Privacy settings don't belong in the contact list. |
| T33 Contact detail pane (+ remark / description sheet) | Tap friend (ContactsPanel.vue:102-104, 513-520) | Detail pane | Screen, ContactDetail, FormSheet, Input, StatusBanner, Button | T:components/ContactDetailPanel.vue (150 LOC); CSS 147-150 (2) | Err ✓ edits (85, 93); Err ✗ 拉黑 and 删除好友 fire with no confirmation and swallow errors (97-106) | One click removes a friend. Disabled 语音/视频 are always shown (122). |
| T34 新的联系人 (requests) + cancel confirm | Category (AddressBookPanel.vue:45, 80-87) | Full-width list | FriendListContainer, ScreenHeader, IconButton, NewFriendRequests, DangerConfirm | ContactsPanel.vue:414-448, 529-552 | L partial: loading is keyed to the contacts list (286-289); E ✓ (544); Err ✓ toasts (424-426) | 同意 immediately switches to the chat tab (418-421). "取消申请" wording vs web "撤回". |
| T35 黑名单 + unblock sheet | Category (AddressBookPanel.vue:48) | List; the action is a separate dialog | FriendListContainer, ContactList, EmptyState, BottomSheet, RelationActionBar | 451-475, 554-564, 616-628 | E ✓ (563); Err ✓ inline in the sheet (471) | Unblock needs a second surface (web: inline 移出 + confirm). Every row is subtitled "已加入黑名单" (307-309). |
| T36 添加好友 sheet | 添加好友 (ContactsPanel.vue:494) or 新建 › 添加联系人 (Main.vue:241) | Dialog ≤480px (88vh) | BottomSheet, FormField, SearchBar, ContactMatchList, Textarea, Button, Input | 320-411, 567-613 | L ✓ (574-575, 589-593); E ✓ kit; Err ✓ toasts with friendly mapping (118-124, 404) | Three add paths stacked in one sheet. The shared 附言 field sits at the bottom yet applies to the result buttons above it (388-406, 603-611). Search is id-only and submit-only (570). Auto-accepted requests jump to chat (393-398). |
| T37 我的群组 (list + detail frame) | Category (AddressBookPanel.vue:47, 88-95) | WorkspaceFrame list + detail | WorkspaceFrame, FriendListContainer, ScreenHeader, IconButton, Button, GroupList, EmptyState | T:components/groups/GroupsPanel.vue (430 LOC); CSS 424-430 (5) | L ✓ (128-131); E ✓ (330, 342); Err ✗ raw toast only (115-117) | Three icon-only header buttons (refresh, search, and join shown as a log-in glyph) plus 创建群 (316-322). |
| T38 Group detail pane (kit GroupDetail + its sheets) | Tap group (GroupsPanel.vue:283-285, 334-341) or chat 群管理 (Main.vue:294-299) | Detail pane; kit sheets as dialogs | Screen, GroupDetail (+ BottomSheet / FormSheet / RadioGroup / ContactList sheets), AnnouncementReadBar, Button, DangerConfirm | T:components/GroupDetailPanel.vue (472 LOC); CSS 470-472 (1) | L ✗ blank while loading (K:components/contacts/FlareGroupDetail.vue:288-296); Err ✗ load failure → "unavailable", no retry (143-145); writes ✓ toast with raw error (268-275, 332, 339, 346) | Same kit gaps as W36-W43: inert 群成员 row, on/off notifications only, invite code with no share. 发消息 closes the pane and switches tabs (GroupsPanel.vue:303-307). |
| T39 创建群组 sheet | 创建群 (GroupsPanel.vue:321) or 新建 › 创建群聊 (Main.vue:242) | Dialog | FormSheet, FormField, Input, Textarea, SearchBar, ContactList, EmptyState | 137-222, 346-385 | L ✓ (366, 376-381); E ✓; Err ✓ raw `String(e)` (218) | Stays in Address Book after creation; web opens the chat. |
| T40 加入群组 sheet (群 ID / 邀请码) | Log-in icon (320) or a public-group result (275-280) | Dialog | FormSheet, SegmentedControl, FormField, Input | 225-259, 388-411 | L ✓; Err ✓ raw (255) | Users must supply raw ids (placeholders "grp_…", "invite_…", 402, 405). |
| T41 搜索公开群 sheet | Search icon (319) | Dialog (80vh) | BottomSheet, SearchBar, GroupList, EmptyState | 262-273, 414-420 | L ✓ (416); E ✗ the idle hint also shows after a search with no results (417-418); Err ✓ toast (268-270) | A result tap opens the join sheet pre-filled with the raw group id (275-280). |
| T42 Group leave / dissolve / remove-member confirms | Kit buttons in T38 (GroupDetailPanel.vue:381-410) | Dialog | DangerConfirm | – | Err ✓ actions throw into the dialog | – |
| T43 圈子 feed | Tab 圈子 (Main.vue:208, 361) | One full-width column (no max width) | Screen, ScreenHeader, Button, MomentsCoverHeader, StatusBanner, MomentCard, Skeleton, EmptyState | T:components/moments/MomentsTab.vue (338 LOC); CSS 328-338 (9); VM T:components/moments/useMomentsViewModel.ts | L ✓ skeleton (254); E ✓ + 发布动态 (255-262); Err ✓ banner + 重试 (232); Off ✗ | Loaded once on mount inside KeepAlive, so it goes stale (139; Main.vue:334). Author, image and liker taps are unbound (235-242). Hard-coded signature (226). Relative times are hard-coded Chinese in the VM (useMomentsViewModel.ts:20-30). |
| T44 发布动态 sheet | 发布 (216, 141-151) | Dialog (88vh) | BottomSheet, MomentComposer | 153-163, 269-282 | L ✓; Err ✗ error lands in the feed banner behind the dialog | Images by URL only (101-124). |
| T45 谁可以看 sheet | Composer visibility (280, 285-298) | Untitled dialog | BottomSheet, MomentAudienceSheet | 59-99 | L ✗ friends load silently (76-99) | No sheet title (285). |
| T46 URL / 位置 prompt | Composer image / location, cover edit (112-124) | Dialog | FormSheet, Input | 301-310 | – | Placeholder "https://…（仅本次会话生效）" (106). |
| T47 评论 / 回复 sheet | 评论, or tap a comment (165-176) | Dialog | FormSheet, Input | 177-190, 313-324 | Err ✗ closes and clears on failure (177-186) | – |
| T48 删除动态 confirm | Card delete (199-208) | Dialog | DangerConfirm | – | Err ✗ VM swallows, dialog closes as success | – |
| T49 搜索 drawer (global) | Rail 搜索 (Main.vue:214, 228, 366) | Right drawer ≤420px, full height (K:components/general/FlareBottomSheet.vue:194) | BottomSheet (drawer), SearchDateRangeFilter, SearchPanel | T:components/search/GlobalSearchDrawer.vue (288 LOC); CSS 286-288 (1) | L ✓ E ✓ Err ✓ (179-199) | 联系人 results are any user (searchUsers, 185) and open chats with strangers. Message hits open the conversation but don't scroll to the message (222-241). The date filter only trims the 40 returned hits (138-151) and sits above the search field (261-281). |
| T50 设置 drawer | Rail 设置 (Main.vue:215, 229, 365) | Right drawer | BottomSheet (drawer), ProfilePanel, StatusBanner, SettingsList, DeviceSessions, NotificationPreferences, StorageUsage | T:components/settings/AppSettingsDrawer.vue (295 LOC); CSS 293-295 (1) | L ✓ / Err ✓ storage (213-231); Perm ✓ notifications (165-193); Uns ✓ (166) | One long drawer mixes profile header, connection status, list, devices, notifications and storage (250-287). 登录设备 shows only this instance (149-158) though the SDK can list and revoke sessions (SDK:modules/user.ts:74-101). 通知与隐私 and 隐私与安全 open the same drawer, which contains no notification settings (106, 113, 125). 关于 Flare IM does nothing (119, 123-128). The QR badge opens the profile editor (252). Notification prefs are stored and never used (160-202). No theme or language settings (T:App.vue:78). |
| T51 通知与隐私 drawer + friend picker | 设置 › 通知与隐私 / 隐私与安全 (AppSettingsDrawer.vue:125, 139-142); contacts gear (ContactsPanel.vue:492) | Right drawer + dialog picker | BottomSheet (drawer), Skeleton, StatusBanner, FormField, RadioGroup, Switch, Select, MomentsVisibilityRuleList, Button, SearchBar, ContactList, EmptyState | T:components/settings/PrivacySettingsDrawer.vue (318 LOC); CSS 315-318 (2) | L ✓ skeleton (263); Err ✓ banner + 重试 (264); rule lists L ✓ (288, 295) | Mixed commit model: form fields need 保存设置, rule-list edits apply instantly (172-184 vs 230-250). The title promises notification settings that aren't there (261). |
| T52 我的举报 sheet | 设置 › 我的举报 (AppSettingsDrawer.vue:114, 127, 290) | Dialog (80vh) | BottomSheet, StatusBanner, Skeleton, SettingsList, EmptyState | T:components/settings/MyReportsSheet.vue (93 LOC); CSS 86-93 (6) | L ✓ E ✓ Err ✓ + 重试 (73-81) | Raw target ids (51). Read-only rows render as buttons. A chat-message skeleton is used for a list (74). |
| T53 我的资料 drawer (+ 头像 URL sheet, 我的二维码 sheet) | Rail 我的资料 (Main.vue:216, 230, 367) or 设置 › 编辑资料 (AppSettingsDrawer.vue:101, 124) | Right drawer + dialogs | BottomSheet (drawer), Skeleton, StatusBanner, FormField, Button, Input, ProfileEditor, FormSheet, QRCard | T:components/user/UserProfileDrawer.vue (238 LOC); CSS 236-238 (1) | L ✓ (189); Err ✓ + 重试 (190); QR L ✓ Err ✓ 重试 (219-230); save Err ✓ toast (174-176) | Avatar only as a pasted URL (74-85, 205-214). Two name fields: 昵称 plus the editor's name (195-199). "用户 ID" is a label-only form field (192). The QR sheet prints the raw token with 复制 token (222-229). |
| T54 举报 dialog | Contact 举报此人 (T:components/ContactDetailPanel.vue:109-115, 136), group 举报群聊 (T:components/GroupDetailPanel.vue:413-419, 464), moment 举报 (T:components/moments/MomentsTab.vue:193-195, 243-251) | Dialog | FormSheet, FormField, RadioGroup, Input | T:components/common/ReportDialog.vue (89 LOC); T:composables/useReportDialog.ts (83 LOC) | L ✓; Err ✓ generic + 429 (54-57); success toast ✓ (Main.vue:369) | The target is rendered as a field hint (75). The reason list is duplicated in the app (useReportDialog.ts:52-59) instead of the shared list web uses (W:components/ReportSheet.vue:15). No message reports. |


## Web and Tauri: consistency

### Web: same concept, different treatment

- **Loading has 5 looks.**
  - Skeleton (W08), EmptyState spinner (W11), neutral StatusBanner "加载中…" (W46), an empty-state titled "加载中…" (W29), and nothing at all (W22, W28, W36).
  - Several lists show "empty" while still loading: W34, W40, W54, W55, W63.
- **Errors have 5 looks.**
  - Banner with 重试, but only on the conversation list (W08).
  - Raw toast (W:social/store.ts:460).
  - Inline form error in sheets (W31, W33, W34).
  - Error inside the confirm dialog, but only when the action throws (W14).
  - Banner without retry (W46).
  - Most directory data and group writes fail silently into empty lists or fake success (W:social/directory.ts).
- **Confirmation is inconsistent.** DangerConfirm guards conversation, message, friend and group destructive actions. Owner transfer uses a kit bottom sheet (K:components/contacts/FlareGroupDetail.vue:357-365). Device sign-out uses a FormSheet (W:components/SettingsPanel.vue:475-478). Logout has none (W67).
- **Success feedback is inconsistent.**
  - Toasts: copy (W:components/ChatArea.vue:209-211), report (W:social/report.ts:43), login alert (W:social/directory.ts:819).
  - Success StatusBanner: add friend and join group (W:components/AddFriendPanel.vue:127; W:components/JoinGroupPanel.vue:73).
  - Silence: accepting a request, saving the profile, the privacy toggle, all group settings.
- **Page headers vary.** Large-title FlareScreen on 通讯录, 圈子, 设置 and sub-pages. No title on 消息 (W08) or on contact/group detail pages (W:components/ContactDetailPanel.vue:106; W:components/GroupDetailPanel.vue:147). FlareScreenHeader (24px bold) is reused as a section label (W:components/ContactsTab.vue:193, 215) while settings sections use small section titles.
- **Search fields come in 3 forms.** A read-only bar that opens an overlay (W08); live debounced search (W:components/GlobalSearch.vue:33-37; W:components/AddFriendPanel.vue:49-54; W:components/JoinGroupPanel.vue:24-28); an explicit criteria panel (W20).
- **Sheet vs page is arbitrary.** Add friend and join group are pages; create group is a sheet. QR is a page under 我 (W54) and a sheet under 设置 (W62). Report history is a page; device list is a sheet.
- **Settings rows blur tappable and read-only.** `kind:"value"` is used both for tappable cycles (外观, 语言) and for read-only data (diagnostics, reports, QR token). All look alike and all are `<button>`s (K:components/profile/FlareSettingsRow.vue:25-45).
- **Report entries take 3 shapes.** Menu item (message), text link under the content (contact, moment), footer link (group).
- **Terminology drifts.** 圈子 (tab) vs 朋友圈 (我 entry, 设置 rows) (W:views/MainView.vue:120; W:components/MeTab.vue:55; W:components/SettingsPanel.vue:304-307). "撤回" means both withdrawing a friend request and recalling a message.
- **Language is mixed.** Auth is English, the app is Chinese, and kit strings follow the locale switch. Some kit components hard-code English: "No contacts yet" (K:components/contacts/FlareContactList.vue:48), back aria "Back" (K:components/layout/FlareScreen.vue:56), "Flare ID:" and default entries "Favorites / Moments / Settings" (K:components/profile/FlareProfilePanel.vue:24-28, 57).

### Tauri: same concept, different treatment

- **Loading.** Skeletons in settings, profile, reports, moments and chat settings. Nothing in group details (T38). A banner in auth. Request-list loading is keyed to the wrong list (T34).
- **Errors.**
  - Raw `e.message` toasts in most panels (T:components/contacts/ContactsPanel.vue:266; T:components/groups/GroupsPanel.vue:116; T:components/chat/ChatPanel.vue:1151).
  - Banner with 重试 in privacy, profile, reports and moments.
  - Silent in the session-list and chat-settings loads.
  - A failure pane only when a chat is opened from another tab.
- **Confirmation.** DangerConfirm for logout, conversation/message deletes and leaving groups. None for 拉黑 / 删除好友 (T33).
- **Remark editing in 3 forms.** Inline input + button in the peer sheet (T:components/chat/ChatPeerProfilePopover.vue:89-94); inline editor in chat settings (T:components/chat/ContactChatSettingsPanel.vue:200-208); FormSheet in contact details (T:components/ContactDetailPanel.vue:139-143).
- **Announcements in 5 places.** Banner (T19), 公告 tab (T18), inline editor in chat settings (T30), kit sheet in group details (T38), read bar (T38).
- **Mute has two sources of truth.** IM conversation mute in chat settings vs Social notifyMode in group details (T30).
- **Search in 4 forms.** Local list filter (T11); drawer with filter tabs and date range (T49); single-filter dialog (T27); submit-only fields in the add-friend and public-group sheets (T36, T41).
- **Mixed icon API.** Raw ionicons glyph imports for header buttons (T:components/contacts/ContactsPanel.vue:31; T:components/groups/GroupsPanel.vue:28; T:components/chat/SessionList.vue:18; T:components/addressbook/AddressBookPanel.vue:8-13; T:components/user/UserProfileDrawer.vue:20) vs semantic icon names in nav and settings rows (T:views/Main.vue:206-217).
- **Settings rows used as content.** Auth feature list (T02) and chat-welcome steps (T15).
- **Destructive styling varies.** 退出群组 is a red settings row (T:components/chat/GroupChatSettingsPanel.vue:201) while group details use the kit's red block button (K:components/contacts/FlareGroupDetail.vue:325-327). 从列表移除 is danger-styled for 1:1 (T:components/chat/ContactChatSettingsPanel.vue:151) but not for groups (T:components/chat/GroupChatSettingsPanel.vue:200).
- **Counts in titles.** "联系人 (N)" style only on Address Book lists (ContactsPanel.vue:490, 536, 556; GroupsPanel.vue:316).

### Web vs Tauri

| Concept | Web | Tauri |
|---|---|---|
| Top-level IA | 4 tabs incl. 我; settings are pages + sheets | 3 tabs + system rail items (搜索, 设置, 我的资料, 退出); settings are drawers |
| Global search | Full-shell overlay; friends + groups + messages; message hit scrolls to the message | Drawer; all users + groups + messages; date range; message hit only opens the chat |
| In-chat search | Replaces the timeline; 7 type filters + 3 ranges; pages history to locate | Dialog; 1 filter; can only jump to loaded messages |
| Chat details | Kit ContactDetail / GroupDetail in the third column | Custom settings panes; management lives in Address Book |
| Conversation actions | pin, mute, read, unread, clear, delete | same + archive + batch mode |
| Message actions | + 举报; no forward / pin / multi-select / download | forward, pin, mark, multi-select, download, receipts; no 举报 |
| Composer | @mention picker; image + file; no drafts | no mention picker; file + image + video; per-conversation drafts |
| Contacts layout | Page stack; 新的好友 / 好友 / 我的群聊 | Master-detail frame with category tabs; 新的联系人 / 我的联系人 / 我的群组 |
| Add friend | Page + verification sheet; debounced id/nickname search | One sheet with 3 paths; id-only submit search; manual id field |
| Create group | Name + ≥1 member; opens the chat | Name + optional members + description + friend search; stays in Address Book |
| Join group | Search only | Group id, invite code, public-group search |
| Unblock | Inline 移出 + confirm | Separate sheet with RelationActionBar |
| Remove / block friend | Confirmed (errors swallowed) | Not confirmed (errors swallowed) |
| Privacy | One toggle | Full form + moments rules |
| Devices | Real list + revoke | Fake single "本设备" row |
| Theme / language | Cycle rows | None (light only, no locale switch) |
| Logout | Settings row, no confirm | Rail item, confirmed |
| Connection state | Banner on all tabs incl. kicked / expired (no action) | Chat tab only; kicked / expired unhandled |
| Loading idiom | Banners and empty-state spinners | Skeletons |
| Auth | English; "Account" key; show-password; gateway URL | Chinese; "用户 ID"; gateway + WS URLs; restore + sync progress |
| Avatar edit | File upload | Pasted URL |
| Report form | Shared reason list; Textarea with counter | App-local reason list; Input with hint counter |
| Moments refresh | Reload on every visit (remount) | Once per session (KeepAlive) |
| Empty conversation list | No CTA | 打开通讯录 CTA |


## Web and Tauri: gaps

### Web: supported below the UI, not exposed

- **Forward, multi-select, message pin, mark, media download.**
  - The shared op contract already has these (`message_builder.create_forward`, `message.pin_by_message_id`, `message.mark_by_message_id`, T:flare-sdk/bridge/ipc.ts:22-33), and web's `imInvoke` can call any op (W:social/sdk.ts:137-140).
  - The kit hides them only because no listener is bound (W:components/ChatArea.vue:269-290; K:shared/config/messageMenu.ts:117-146).
- **Typing indicator, presence, read-receipt details, pinned bar, announcement banner in chat.** The kit components exist and Tauri composes them (T:components/chat/ChatPanel.vue:1703-1763, 1890-1892).
- **Per-conversation drafts.** Summaries already carry `draft` (W:social/store.ts:203), but web throws drafts away (W:components/ChatArea.vue:244-251).
- **Realtime social events.** The SDK emits profile, friend-request, badge, contact, group, member and join-request events (SDK:events/index.ts:66-139). Web subscribes only to login alerts (W:social/directory.ts:813-822).
- **Group tools.** Join by invite code (SDK:modules/group.ts:75), revoke invite link (102), direct add (134), bans (143-158), cancel own join request (232).
- **Privacy.** Friend verification mode and profile/mobile/email visibility go through `updateMyPrivacy` (SDK:modules/user.ts:45), but web sends one field (W:components/SettingsPanel.vue:331).
- **Account security.** Change password (SDK:modules/user.ts:69), bind phone/email (55), account deletion (65), account info (50): no UI in either app.
- **Identity.** Custom status (SDK:modules/user.ts:105-109); username / Flare ID set and lookup (121-126).
- **Relationships.** Contact tags (SDK:modules/relation.ts:169-181), friendship check (117-123), add friend by QR (188), share contact card (192).
- **Moments.** Moment detail (SDK:modules/moments.ts:31), a user's moments (41), delete comment (65). Moment images could reuse the existing upload wrapper (W:social/sdk.ts:304-308).
- **Conversation archive.** Core `conversation.set_archived` exists (T:flare-sdk/bridge/ipc.ts:63) but is deliberately not offered, because there's no archived section (W:social/store.ts:207-211).

### Web: dead ends, placeholders, controls that do nothing

- 我 › 朋友圈 row has no handler (W:components/MeTab.vue:55, 86-93).
- `@logout` on ProfilePanel never fires (W:components/MeTab.vue:113; K:components/profile/FlareProfilePanel.vue:38).
- Notification preferences have no effect (W:host/notifications.ts:54-71).
- The kicked / token-expired banner offers no action (W:views/MainView.vue:89-92).
- On phone, a failed chat or search-result open leaves a header-less empty chat with the tab bar hidden (W:views/MainView.vue:68-73, 162-195; W:components/ChatArea.vue:342-348).
- The Advanced gateway URL is ignored after the first attempt (W:social/sdk.ts:111-127).
- Group invite codes can be generated but never redeemed in web (K:components/contacts/FlareGroupDetail.vue:421-433; W:components/JoinGroupPanel.vue).
- 我的二维码 has no scanning or adding counterpart (W:components/MeTab.vue:135-153).
- Disabled 语音/视频 buttons on contact details (W:components/ContactDetailPanel.vue:109).
- In 圈子, author, liker and image taps do nothing, and the cover avatar opens the composer (W:components/MomentsTab.vue:194, 209; K:components/moments/FlareMomentCard.vue:45-54, 93).
- The 群成员 row and non-manager member taps in group details do nothing (K:components/contacts/FlareGroupDetail.vue:97, 163-186, 230-234).
- "+ 发起聊天" lands on the Contacts home, not a picker (W:components/ConversationPane.vue:61; W:views/MainView.vue:182-185).
- Read-only rows are rendered as buttons: diagnostics, report history, QR token (W:components/SettingsPanel.vue:177-193; W:components/MeTab.vue:62-77).
- 发消息 on a matched contact creates a pseudo group (W:components/AddFriendPanel.vue:158; W:social/store.ts:502-517).

### Tauri: supported below the UI, not exposed

- **Login devices.** The SDK can list and revoke sessions (SDK:modules/user.ts:74-101); the drawer shows only the local instance, and the code comment admits it (T:components/settings/AppSettingsDrawer.vue:149-158; T:views/Main.vue:136-137).
- **Wrappers exported with no caller.**
  - Messages: thread reply (T:flare-sdk/api/message.ts:108), burn-after-read (29), unmark (467), get message (431).
  - Moments: detail, user moments, delete comment (T:flare-sdk/api/moments.ts:46, 54, 82).
  - Media: upload with progress (T:flare-sdk/api/media.ts:86-93).
  - Other: rich-text edit (T:flare-sdk/api/richDocV2.ts:66), participants list (T:flare-sdk/api/conversation.ts:47), chat preference writes (T:flare-sdk/api/chatSession.ts:65, 116).
- **Theme and language.** Theme switching is supported by the kit provider (K:design-system/provider/FlareUiProvider.vue:22), and a locale setter exists but is never called (T:composables/useAppImLocale.ts:37-44).
- **Session-ending events.** Kicked / token-expired callbacks exist (T:host/events/createImEventHub.ts:153-154, 388-396) and are unused.
- **Message reports.** The target kind exists (T:composables/useReportDialog.ts:64) but nothing opens it.
- **@mention picker.** Kit Composer supports mention candidates, and web uses them (W:components/ChatArea.vue:117-121).
- **Same SDK features web also lacks** (none wrapped in T:flare-sdk/api/social.ts): account security, custom status, username, contact tags, bans, revoke invite link, add-by-QR, share card.

### Tauri: dead ends, placeholders, calls that cannot succeed

- **Unrouted IPC commands.** `sdkSendCallInvite` (T:flare-sdk/api/call.ts:13), `sdkBatchGetUserPresence` (T:flare-sdk/api/presence.ts:13) and every `sdkRichDocV2*` command (T:flare-sdk/api/richDocV2.ts:36-80) have no entry in `IM_API_ID` or `SOCIAL_OP` (T:flare-sdk/bridge/ipc.ts:12-164). They fall back to typed commands that `flare_invoke_handler` doesn't register (TB:lib.rs:61-140). Result: call buttons, the initial presence fetch and rich-text sends reject (UI: T:components/chat/ChatPeerProfilePopover.vue:86; T:components/chat/ChatPanel.vue:531-554, 989-1008, 1320-1329).
- Placeholder row "创建群组 · 即将支持" (T:components/chat/ContactChatSettingsPanel.vue:140). Group-call toast "即将支持" (T:components/chat/ChatPanel.vue:1011).
- 关于 Flare IM row has no handler (T:components/settings/AppSettingsDrawer.vue:119, 123-128).
- 打开文件夹 only shows a toast (T:components/chat/ChatPanel.vue:1606-1609).
- Archive has no archived view (T:components/chat/SessionList.vue:65-73; T:host/utils/conversationList.ts:163-164).
- Notification preferences have no effect (T:components/settings/AppSettingsDrawer.vue:160-202).
- In the peer sheet, 发消息 opens settings, and the remark hint for strangers has no add action (T:components/chat/ChatPeerProfilePopover.vue:86, 95).
- 编辑公告 on the 公告 tab is shown to non-admins (T:components/chat/ChatPanel.vue:1716).
- `has-older` is always true (T:components/chat/ChatPanel.vue:1738). Pinned and search jumps only work inside loaded messages (815-818).
- The chat-settings profile row isn't tappable (T:components/chat/ContactChatSettingsPanel.vue:194-198).
- In 圈子, author, image and liker taps do nothing (T:components/moments/MomentsTab.vue:235-242).
- Chat-welcome steps and the Auth feature list look tappable (T:components/chat/ChatWelcome.vue:31; T:views/Auth.vue:480).

### Kit components that would close gaps, unused by both apps

- `StartConversationDialog` for a new-chat picker (K:components/index.ts:43).
- `MemberPanel`, `MemberRoleSheet`, `GroupPermissionMatrix` for member management (184, 207-208).
- `UnknownUserPlaceholder` / `RelationActionBar` for stranger profiles in chat details (205-206). Tauri uses RelationActionBar only in the blocklist.
- `CommandPalette` for desktop search (179); `MediaCenter` for chat files and media (188).
- `BrandLogo` (132). Both apps keep a stale "no BrandLogo" workaround (W:views/AuthView.vue:267-268; T:views/Auth.vue:473).
- `CallView` / `IncomingCall` (61-64). Tauri shows call buttons with no call UI.
- `TransferProgress` / `TransferQueue` for upload progress (176, 182); `CapabilityBoundary` / `PermissionPrompt` (190, 198).

## Flutter: flare-social-flutter-app

### Navigation model

- **Root:** `MaterialApp.home` switches between `_BootSplash`, `AuthScreen` and `BaseShell`, driven by `_restoring` and `_session` (`fl/app.dart:47-62`). There are no named routes. The Material theme is derived from kit tokens (`fl/host/material_theme.dart:9-23`) and wrapped in `FlareTheme(brand: violet)` (`fl/app.dart:55-56`) with `ThemeMode.system`. No localization delegates are installed.
- **Shell:** `FlareIMAppKit` has 5 destinations, with a count badge for unread messages on 消息 and for pending friend requests on 通讯录 (`fl/screens/base_shell.dart:261-306`).
- **Breakpoints:**
  - `LayoutBuilder` passes width and text scale to `flareApplicationResponsiveModeForWidth` (`fl/screens/base_shell.dart:312-318`).
  - On mobile the kit renders `FlareMobileAppShell` with a bottom nav. At ≥ 600 it renders `FlareDesktopAppShell` with a rail or sidebar, wrapped in `Scaffold(body: SafeArea(...))` (`fl/screens/base_shell.dart:332`; `kfl/application/application_composition.dart:1093-1117`).
- **Split view:**
  - Only the 消息 tab splits at ≥ 600: the list is `primary` and the chat is `content` (`fl/screens/base_shell.dart:320-327, 475-494`). All other tabs render a single pane at every width.
  - Shrinking to mobile width drops the open conversation, because `_selectedConversationId` is set to null during build (`fl/screens/base_shell.dart:319`).
- **Details:** `Navigator.push(MaterialPageRoute)` is used for chat on phones, add friend, friend requests, contact detail, join group, group detail and profile center (`fl/screens/base_shell.dart:150-185, 508, 530, 566-572, 591-596, 638-645`). The shell reloads its data only when a route pops `true` (`fl/screens/base_shell.dart:150-155`).
- **Overlays:** all go through kit presenters.
  - `FlareDialog.show`: create group, remark and description edits, block and remove confirms, join confirm, moment composer, comment prompt.
  - `FlareBottomSheet.show`: forward and all profile sheets.
  - `FlareDangerConfirm.show`: recall, delete, withdraw request, remove member, leave group, delete moment.
  - Also `FlareMessageActionSheet.show` and `FlareToast.show`.
  - Inside `FlareGroupDetail` the kit itself calls raw `showDialog` / `showModalBottomSheet` (`kfl/components/flare_group_detail.dart:333-720`).
- **Menus:** none. Every action is a header button.
- **System back:**
  - Pushed routes pop through the Navigator. Contact detail intercepts the pop to return a "changed" flag (`fl/screens/social_action_screens.dart:172-176`); `PopScope(canPop: false)` also removes the iOS edge-swipe on that page.
  - The wide-layout chat is not a route, so Android back from the split chat leaves the app.
- **Tab state:** tab content is rebuilt on every switch (`fl/screens/base_shell.dart:337-347`). `MomentsScreen` builds a new view model and refetches the feed on each visit (`fl/screens/moments_screen.dart:25-34`).

### Screens

| # | Screen | Entry (file:line) | Form factors | Kit components used | App-local widgets and styling | States | UX or visual issues |
|---:|---|---|---|---|---|---|---|
| 1 | Boot splash | `fl/app.dart:57-58, 66-78` | All | FlareScreen, FlareEmptyState(loading) | `_BootSplash`, Scaffold (`fl/app.dart:71`) | Load ✓ (`:74`) · Empty – · Error ✗: a failed restore silently shows Auth and deletes the saved token (`fl/sdk/base_social_client.dart:626-629`) · Offline ✗ | Any failure while fetching the profile during restore wipes the session (`fl/sdk/base_social_client.dart:612-629`), so a cold start offline or with the gateway down likely logs the user out. |
| 2 | Auth: Sign in / Create account (includes the "Advanced · gateway" disclosure) | `fl/app.dart:60` | Phone: one column. ≥ 900: brand rail plus form (`fl/screens/auth_screen.dart:156-181`) | FlareScreen(brand), FlareBrandLogo, FlareSegmentedControl, FlareFormField, FlareInput, FlareCheckbox, FlareButton, FlareStatusBanner, FlareTopicChip, FlareToast | `_BrandLockup`, `_BrandRail`, `_SpecChips`; Scaffold (`:152`); raw `TextStyle` headings (`:205, 214, 350, 361, 390, 401`); `AutofillGroup` with no autofill hints (`:190`) | Load ✓ (`:303-317`) · Error partial: banner (`:298-301`), but anything unrecognised shows the raw exception (`:139-148`) · Offline ✗ · Permission – | Password only: no code login and no reset, because the Flutter SDK has no verification-code API (`sdkfl/flare_social_sdk.dart:362-412`). Register sends no code although the server requires one (`ios/SocialSession.swift:136-137`), so sign-up likely fails. Mixed English/Chinese copy (`fl/screens/auth_screen.dart:198-314`). Spec chips claim "WASM · core in-page" on an FFI build (`:424-426`). Show-password is a checkbox instead of an eye toggle (`:256-261`). The wide layout shows the lockup twice (`:174, 195`) and the chips twice (`:319, 408`). A developer gateway field sits in the consumer login (`:277-297`). |
| 3 | Shell with sync and connection banners | `fl/screens/base_shell.dart:310-335, 383-431` | Phone: bottom nav. ≥ 600: rail or sidebar | FlareIMAppKit, FlareStatusBanner | Scaffold + SafeArea on wide layouts (`:332`) | Load ✓ "正在同步 Base 数据" (`:386-399`) · Offline partial: the banner reflects `session.imConnected` from login time only (`:400-413`); connection events are filtered out (`:64-70`; `sdkfl/event_code.dart:60-65`) · Error ✓ list-refresh banner with 重试 (`:414-428`) | Kicked and token-expired states are never surfaced. Banner copy is developer wording ("Base 数据"). Five tabs here against four on iOS and Android. |
| 4 | 消息: conversation list | `fl/screens/base_shell.dart:337-338, 434-473` | Phone: full screen. ≥ 600: primary pane | FlareConversationListContainer, FlareScreenHeader, FlareIconButton, FlareConversationList, FlareEmptyState, FlareAvatar | RefreshIndicator (`:459`); GestureDetector avatar (`:356-364`) | Load ✓ (`:451-452`) · Empty ✓ (`:465-469`) · Error partial: only a kit icon button with no text when the list is empty (`:453-455`; `kfl/application/application_composition.dart:1155-1161`), plus a banner when rows exist · Offline ✗ | No search entry (the container's `search:` slot is unused). No long-press actions although the kit supports `onLongPress` (`kfl/components/flare_conversation_list.dart:20-34`). Mention and draft flags are never mapped (`fl/sdk/im_client.dart:104-115`). Header avatar is 32 px (`FlareSizes.iconSizeXl`). |
| 5 | Chat placeholder (wide, nothing selected) | `fl/screens/base_shell.dart:475-485` | ≥ 600 only | FlareEmptyState | Center | – | Rotating to a phone width loses the selection (`:319`). |
| 6 | Chat | Phone push `fl/screens/base_shell.dart:171-185`; wide pane `:486-493`; from contact or group detail `fl/screens/social_action_screens.dart:148-156, 911-919` | Phone: route. ≥ 600: content pane on the 消息 tab only; from other tabs it is always a full-screen route | FlareConversationHeader, FlareMessageList, FlareComposer, FlareEmptyState, FlareToast | Scaffold with the kit header as `appBar` (`fl/screens/chat_screen.dart:350-377`) | Load ✓ (`:387`) · Empty ✓ (`:391-395`) · Error ✗: `listMessages` returns `[]` on any error, which renders as "还没有消息" (`fl/sdk/base_social_client.dart:780-782`) · Offline ✗ · Permission ✓ microphone handled by the kit (`kfl/components/flare_inline_voice.dart:79-81`) | See the list after this table. |
| 7 | Chat header | `fl/screens/chat_screen.dart:351-377` | Phone shows back; wide hides it (`:372-373`) | FlareConversationHeader | – | – | Only groups get a details target (`:361-366`). Capabilities are limited to `{'identity'}`, so there are no call, search or more buttons (`:369-371`). |
| 8 | Message action sheet | Long-press, `fl/screens/chat_screen.dart:177-232` | All | FlareMessageActionSheet.show (core availability), FlareDangerConfirm | – | Load ✗: availability is awaited with no pending cue (`:178-181`) · Error partial: a failed availability read gives an empty sheet (`fl/sdk/base_social_client.dart:830-831`) · Offline partial: `connected` is passed, but it is the login snapshot (`:180`) | Reply, resend, multi-select, pin, mark, edit, save and preview are hidden (`:162-173`). Copy gives no feedback (`:203-205`) and copies an empty string for non-text messages (`:196-198`). |
| 9 | Recall and delete confirms | `fl/screens/chat_screen.dart:206-229` | All | FlareDangerConfirm.show(action) | – | Error ✓ the error stays in the dialog (`fl/sdk/base_social_client.dart:834-852`) | Delete is for self only; the data layer's delete-for-everyone is unused (`fl/sdk/base_social_client.dart:843-852`). |
| 10 | Forward picker | `fl/screens/chat_screen.dart:240-297` | All (bottom sheet at 70% height) | FlareBottomSheet.show, FlareForwardPicker, FlareToast | Fixed `SizedBox` height of 0.7 × screen (`:271-272`) | Load ✗ · Empty ✓ toast (`:265-268`) · Error ✓ list-failure toast (`:244-252`) and partial-send toast (`:279-290`) | Forward reads a raw-message cache that every `listMessages` call clears (`fl/sdk/base_social_client.dart:767-773`). If another chat reloads first, forwarding returns 0 and shows "转发失败". |
| 11 | Composer: text, rich text, emoji and sticker panel | `fl/screens/chat_screen.dart:398-440` | All | FlareComposer; its built-in emoji panel inserts `[key]` into the text (`kfl/components/flare_composer.dart:748-751`) | – | Error ✓ text is kept on a failed send, because the kit awaits the result (`kfl/components/flare_composer.dart:319-337`), plus a toast (`fl/screens/chat_screen.dart:313-318`) · Rich text is cleared before the result (`kfl/components/flare_composer.dart:312-317`) and its failures are silent (`fl/screens/chat_screen.dart:409-417`) | Sticker failures are silent (`:418-430`). |
| 12 | Composer "+" panel and gallery picker | `fl/screens/chat_screen.dart:322-345, 431-438` | All | FlareComposer with capabilities `{'image'}` | `image_picker` system gallery | Load ✓ composer disabled while uploading (`:329-335`) · Error ✓ toast (`:339-343`) · Permission ✓ plist strings (`ios/Runner/Info.plist:69-74`) | No camera, file, video or location. No upload progress. |
| 13 | Voice recorder (kit, inline) | `fl/screens/chat_screen.dart:400-405` | All | FlareComposer(enableVoice) | – | Permission ✓ (kit) · Error ✓ (kit) | Recipients cannot play voice messages (see row 6). |
| 14 | Mention picker sheet | `fl/screens/chat_screen.dart:439`; roster from `:108-130` | Group chats | FlareComposer, which opens FlareMentionPicker | – | Load ✗ candidates arrive asynchronously · Error ✗ a failed roster load is silent (`:110-111`) | Picking inserts plain "@name " text (`kfl/components/flare_composer.dart:263-272`). `sendText` sends `mentionAll: false` and no mention ids (`fl/sdk/base_social_client.dart:940-944`), so mentioned users are not notified. The roster is loaded with the conversation id as the group id, so it is likely always empty (row 6). |
| 15 | 通讯录 tab | `fl/screens/base_shell.dart:339, 497-577` | All (single pane at every width) | FlareFriendListContainer, FlareScreenHeader, FlareButton, FlareSettingsList (新的朋友 row), FlareContactList, FlareEmptyState, FlareStatusBanner | RefreshIndicator plus a ListView wrapper for the empty state (`:540-551`) | Load ✓ first load only (`:534-537`) · Empty ✓ (`:544-550`) · Error ✗: `loadDashboard` swallows every error and shows empty (`fl/sdk/base_social_client.dart:1594-1603`) · Offline ✗ | The contact subtitle is the raw user id (`:559`). No blocked-list entry. Accepting a request does not refresh this tab or the badge, because `FriendRequestsScreen` never pops `true` (`:150-155, 530`). |
| 16 | Add friend | `fl/screens/base_shell.dart:508` | All (route) | FlareScreen, FlareSearchBar, FlareEmptyState, FlareContactMatchList ×2, FlareFormField, FlareInput, FlareButton | ListView (`fl/screens/social_action_screens.dart:296`) | Load ✓ (`:313-321`) · Empty ✓ (`:317-323`) · Error ✓ for search (`:310-323`, covered by `test/search_states_test.dart`), but shows raw error text · Address-book match: Error ✗, failures show as no matches (`fl/sdk/base_social_client.dart:1705-1718`) | Search fires on every keystroke (`:303`). No greeting message (`fl/sdk/base_social_client.dart:1072-1082`). A failed request is silent (`:344-348`). "已申请" is the kit's "message" label reused on a disabled button (`:340-343`). Address-book hits keep "添加" enabled after a request is sent, and "发消息" is disabled for existing friends because `onOpenConversation` is not passed (`:373-391`; `kfl/components/flare_contact_match_list.dart:104-117`). |
| 17 | 新的朋友 (friend requests) | `fl/screens/base_shell.dart:530` | All (route) | FlareScreen, FlareSkeleton, FlareFilterTabs, FlareNewFriendRequests (incoming and outgoing), FlareEmptyState, FlareDangerConfirm | – | Load ✓ skeleton (`fl/screens/social_action_screens.dart:592-593`) · Empty ✓ (`:631, 636-640`) · Error ✗ errors show as empty (`fl/sdk/base_social_client.dart:1126-1149`) · Offline ✗ | Accept and reject give no feedback and swallow errors (`:567-570`; `fl/sdk/base_social_client.dart:1084-1087`). The withdraw confirm always reports success, because `cancelFriendRequest` never throws (`:572-583`; `fl/sdk/base_social_client.dart:1089-1092`). |
| 18 | Contact detail | `fl/screens/base_shell.dart:564-573` | All (route) | FlareScreen, FlareContactDetail, FlareDialog, FlareInput, FlareButton, FlareToast | `PopScope(canPop: false)` (`fl/screens/social_action_screens.dart:172-176`); Scaffold (`:177`) | Load – (uses the list snapshot) · Error ✓ for opening a chat (`:157-164`) · Error ✗ for edits: local state updates regardless of the write result (`:35-66`; `fl/sdk/base_social_client.dart:1097-1123`) | No report entry. The star toggles optimistically with no rollback (`:60-66`). "发消息" pushes a full-screen chat even on tablet (`:148-156`). |
| 19 | Edit remark and description dialogs | `fl/screens/social_action_screens.dart:35-58, 68-100` | All (centered dialog) | FlareDialog.show, FlareInput, FlareButton | – | Error ✗ | Save always appears to succeed. |
| 20 | Block and remove-friend confirms | `fl/screens/social_action_screens.dart:102-132, 194-203` | All | FlareDialog | – | Error ✗ | A neutral "确定" dialog is used, not a danger confirm, unlike recall, leave and the other apps. It pops with "changed" even when the write failed. |
| 21 | 群组 tab | `fl/screens/base_shell.dart:340, 580-649` | All | FlareFriendListContainer, FlareScreenHeader, FlareButton ×2, FlareGroupList, FlareEmptyState, FlareStatusBanner | RefreshIndicator, ListView | Load ✓ first load · Empty ✓ (`:617-626`) · Error ✗ swallowed (`fl/sdk/base_social_client.dart:1605-1614`) | Groups are a separate top-level tab here; iOS and Android place them under 通讯录. Unknown member counts render the label "群组" (`:637`). |
| 22 | Create group dialog | `fl/screens/base_shell.dart:187-218` | All | FlareDialog.show, FlareInput, FlareButton | – | Load ✗ no busy state · Error ✗ a null result is ignored (`:214-217`) | Name only, and it always creates an empty group via `createGroup(name, const [])` (`:215`), although the data layer accepts member ids (`fl/sdk/base_social_client.dart:1163-1171`). The new group is not opened. |
| 23 | Join group | `fl/screens/base_shell.dart:591-596` | All (route) | FlareScreen, FlareSearchBar, FlareEmptyState, FlareGroupList, FlareDialog, FlareToast | – | Load ✓ (`fl/screens/social_action_screens.dart:498`) · Empty ✗ no query, no results and errors all show "搜索加入群聊" (`:505-510`; errors come back as `[]` from `fl/sdk/base_social_client.dart:1370-1378`) · A failed join is silent (`:474-482`) | Searches every keystroke with no guard against stale results (`:424-443`). The "applied" state is appended to the group name (`:516-518`). The join message is fixed (`fl/sdk/base_social_client.dart:1380`). |
| 24 | Group detail | `fl/screens/base_shell.dart:638-645`; from chat `fl/screens/chat_screen.dart:139-148` | All (route) | FlareScreen, FlareGroupDetail, FlareAnnouncementReadBar, FlareDangerConfirm | Scaffold (`fl/screens/social_action_screens.dart:925`) | Load ✓ (`:932`) · Error partial: the kit shows "unavailable" when the model is null · Writes: Error ✗ (`:951-1019`, all through `_social`) except remove member and leave (`:849-898`) | See the list after this table. |
| 25 | Member management, announcement, invite and join-request sheets (kit-internal) | Callbacks at `fl/screens/social_action_screens.dart:950-1020` | All | FlareGroupDetail internals (`kfl/components/flare_group_detail.dart:333-720`) | – | Error ✗ writes are silent | Muting a member sends no expiry here (server default applies), while Android sends a 24 h `muted_until` (`and/SocialSession.kt:1024-1029`). The generated invite code has no redemption path in any app (`soc/ffi/ops/group.rs:239`). |
| 26 | Remove-member and leave/dissolve confirms | `fl/screens/social_action_screens.dart:849-860, 885-898` | All | FlareDangerConfirm.show | – | Error ✓ `_socialOrThrow` keeps the error in the dialog (`fl/sdk/base_social_client.dart:1221-1225, 1363-1368`) | Reference behaviour: leaving from a chat also pops the chat (`fl/screens/chat_screen.dart:150-153`). |
| 27 | 圈子 feed | `fl/screens/base_shell.dart:341-345` | All (single pane) | FlareScreenHeader, FlareIconButton, FlareButton, FlareSkeleton, FlareMomentsCoverHeader, FlareMomentCard, FlareEmptyState, FlareToast | RefreshIndicator plus `ListView.builder` (`fl/screens/moments_screen.dart:149-166`) | Load ✓ skeleton (`:130-132`) · Empty ✓ (`:137-147`) · Error partial: toast plus empty state, no retry (`:45-53`; `fl/viewmodels/moments_view_model.dart:104-118`) · Offline ✗ | No pagination: first 20 only, the cursor is unused (`fl/sdk/base_social_client.dart:1393-1405`). No report. Images cannot be opened (`onOpenImage` not passed). No reply to comments, although the view model supports it (`fl/viewmodels/moments_view_model.dart:174-191`). The header lacks the profile avatar the other tabs show. Refetches on every tab visit. |
| 28 | Publish composer (centered dialog) with inline audience panel | `fl/screens/moments_screen.dart:73-92, 171-298` | All | FlareDialog.show, FlareMomentComposer, FlareMomentAudienceSheet, FlareToast | `Padding(viewInsets)`; literal `EdgeInsets.symmetric(vertical: 24)` (`:265`) | Load ✓ busy (`:214-219, 236-245`) · Error ✓ toast (`:221-227, 249-253`) | Friends are fetched before the dialog opens, with no loading cue (`:75-85`). The audience panel renders inline under the card rather than as an overlay (`:279-291`). |
| 29 | Comment prompt | `fl/screens/moments_screen.dart:55-59, 300-333` | All | FlareDialog.show, FlareInput, FlareButton | `_promptText` | Error ✓ view-model toast (`fl/viewmodels/moments_view_model.dart:186-190`) | An empty comment is silently ignored. |
| 30 | Delete-moment confirm | `fl/screens/moments_screen.dart:61-71` | Own moments | FlareDangerConfirm.show | – | Error ✗: `deleteMoment` swallows errors and the card is removed anyway (`fl/viewmodels/moments_view_model.dart:194-199`; `fl/sdk/base_social_client.dart:1458-1459`) | – |
| 31 | 设置 tab | `fl/screens/base_shell.dart:346, 652-774` | All | FlareScreenHeader, FlareStatusBanner, FlareSettingsList | Column / ListView / RefreshIndicator | Offline ✓ banner (`:671-679`) | Developer diagnostics (网关, 用户, counts) are shown in consumer settings (`:695-733`), and those value rows are tappable no-ops (`kfl/components/flare_settings_list.dart:122-137`). "隐私与好友验证" opens Profile Center, not the privacy sheet (`:734-744, 758-760`). Logout has no confirmation (`:763-764`). No theme, language, notification, device, blocked-list or report entries. |
| 32 | Profile center | `fl/screens/base_shell.dart:157-169, 758-760` | All (route) | FlareScreen, FlareIconButton, FlareSkeleton, FlareStatusBanner, FlareProfilePanel, FlareToast | RefreshIndicator / ListView (`fl/screens/profile_center_screen.dart:96-101`); Scaffold (`:81`) | Load ✓ (`:94-95`) · Error ✓ toast (`:54-60`), but unreachable because `loadDashboard` never throws · Offline ✓ banner (`:109-115`) | The overview rows 好友 / 群组 / 申请 are tappable dead ends (`:130-155, 227-246`). A second logout entry, also unconfirmed (`:208-217, 243-244`). A placeholder model with fake counts 8 / 3 / 1 exists for a missing dashboard (`fl/sdk/base_social_client.dart:389-400`). |
| 33 | Profile editor sheet | `fl/screens/profile_center_screen.dart:332-347, 559-612` | All | FlareBottomSheet.show, FlareProfileEditor, FlareToast | `_ProfileEditorSheet`, SingleChildScrollView | Error ✗ the catch branch is dead because `updateMyProfile` swallows errors (`fl/sdk/base_social_client.dart:1024-1032`) | No avatar change (`onPickAvatar` not passed). |
| 34 | Privacy sheet (stranger messages) | `fl/screens/profile_center_screen.dart:349-379` | All | FlareBottomSheet.show, FlareSettingsList (toggle) | StatefulBuilder | Load ✗ fetched before opening, no indicator (`:351`) · Error ✗ the toggle is not reverted on failure (`:372-375`); an unknown value defaults to "allowed" (`:351`) | Titled 隐私与好友验证, but friend-verification mode is not offered. |
| 35 | 朋友圈权限 sheet with nested friend picker | `fl/screens/profile_center_screen.dart:385-465` | All | FlareBottomSheet.show ×2, FlareMomentsVisibilityRuleList ×2, FlareContactList, FlareEmptyState | StatefulBuilder | Load ✗ two awaits before opening (`:386-388`) · Empty ✓ picker (`:421-425`) · Error ✗ writes are silent (`:405-409`) | – |
| 36 | 朋友圈范围 sheet | `fl/screens/profile_center_screen.dart:467-501` | All | FlareBottomSheet.show, FlareSettingsList (select) | – | Error partial: on failure it returns the requested value, so the UI shows it as saved (`fl/sdk/base_social_client.dart:1658-1666`) | – |
| 37 | 我的二维码 sheet | `fl/screens/profile_center_screen.dart:125-127, 503-556` | All | FlareBottomSheet.show, FlareQRCard, FlareFormField, FlareInput (disabled), FlareButton, FlareToast | A `TextEditingController` created in `build` (`:532`) | Load ✗ the token is fetched before opening · Empty ✓ kit "unavailable" frame (`:517-523`) | Shows the raw QR token with a copy button (developer UX). No save or share. No scanner in any app (`soc/ffi/ops/relation.rs:220` `add_friend_by_qr` is unused). |
| 38 | 缓存与同步 sheet | `fl/screens/profile_center_screen.dart:313-330` | All | FlareBottomSheet.show, FlareStorageUsage | – | – | Placeholder: sizes are unknown and there is no clear-cache action. The core has `media.cache_stats` and `media.clear_cache` (`core/bindings/contract/apis.json:742, 760`). |
| 39 | SDK 能力 sheet | `fl/screens/profile_center_screen.dart:248-311` | All | FlareBottomSheet.show, FlareSettingsList, FlareDeviceSessions | – | – | A single fake "Flutter · 本机" device (`:296-305`). No real device list, no revoke, no new-device alert. |
| 40 | Global toasts | e.g. `fl/screens/base_shell.dart:87-91`; `fl/screens/chat_screen.dart:313-317` | All | FlareToast.show | – | – | Some toasts embed raw exceptions such as `加载失败：$e` (`fl/screens/base_shell.dart:89`). |
| 41 | System gallery picker (moments) | `fl/screens/moments_screen.dart:208-228` | All | – | `image_picker` | Error ✓ toast (`:221-227`) | Flutter is the only app that lets moments carry images. |
| 42 | Header profile avatar (entry to 个人中心) | `fl/screens/base_shell.dart:350-379` | All tabs except 圈子 | FlareAvatar, FlareScreenHeader | GestureDetector plus Semantics | – | A 32 px touch target, and two routes to the same profile and settings content (rows 31 and 32). |

Row 6 (chat) issues:

- No history paging: the limit is 50, and `hasOlder` / `onLoadOlder` are unused (`fl/sdk/base_social_client.dart:743-757`).
- Media bubbles are inert: `onMediaAction` and `onResend` are not passed, and without them kit taps do nothing (`kfl/components/flare_message_content_view.dart:107-137`).
- The header and member roster use the conversation id as the group id (`fl/screens/chat_screen.dart:110, 141-146`). Group conversation ids are `2A…` hashes of the group id (`fcore/common/conversation.rs:340-359`), so group details and mentions likely fail.
- Every message-range event, including typing (2006, 2021) and presence (2019), reloads the thread, marks it read and forces a jump to the bottom (`:67-73, 84-90, 299-304`). There is no lifecycle check, so a chat left open in the background still marks messages read.

Row 24 (group detail) issues:

- `isAdmin` treats role 3 (member) as admin (`fl/sdk/base_social_client.dart:274`; `soc/modules/group/domain/model.rs:229-233` defines Owner = 1, Admin = 2, Member = 3), so every member sees management UI and join requests are fetched for everyone.
- Demoting an admin writes roles `[1]`, which is Owner (`fl/sdk/base_social_client.dart:1227-1232`).
- Join requests show the raw applicant id (`fl/screens/social_action_screens.dart:809`), and `onLoadContacts` is a no-op (`:1015`).
- "发消息" opens a chat whose id is the group id (`:900-920`), which is the wrong conversation id.
- No report entry.
- The admin-only "查看未读" link is shown but not wired (`:944`; `kfl/components/flare_announcement_read_bar.dart:92-95`).


## iOS: flare-social-ios-app (SwiftUI)

### Navigation model

- **Root:**
  - `FlareSocialRootView` switches between `AuthView` and `ConnectionBanner` + `MainShell` on `session.phase` (`ios/FlareSocialRootView.swift:17-29`).
  - The kit feedback host for toasts and confirms is installed on the root (`:31`).
  - Theme and language come from `@AppStorage` (`:12-13, 32-33`).
  - There is no session restore: the phase starts `.signedOut` (`ios/SocialSession.swift:31`) and no token is persisted.
- **Shell:**
  - `IMAppKitView` has 4 destinations with an unread badge on 消息 only (`ios/MainShell.swift:14-25`).
  - The responsive mode comes from `GeometryReader` width (`:28-37`).
  - The bottom nav is hidden while a chat is pushed (`immersive`, `:12, 35`; set at `ios/ConversationsView.swift:28` and `ios/MainShell.swift:169-171`).
- **Tab state:** all four tab roots stay mounted in a `ZStack`; inactive ones are hidden via opacity and hit-testing (`ios/MainShell.swift:40-58`).
- **Tablet:**
  - 消息 uses `NavigationSplitView` when `horizontalSizeClass == .regular`, otherwise `NavigationStack` (`ios/ConversationsView.swift:17-24, 33-83`).
  - Every other tab is a `NavigationStack` at all sizes.
  - The shell switches on width and 消息 switches on size class, so the two can disagree (for example iPad portrait gets rail, list and chat in three columns).
- **Details:** `NavigationStack` paths and destinations (`ios/ConversationsView.swift:34-39`; `ios/MainShell.swift:64-71, 101-153`), plus `.navigationDestination(isPresented:)` in chat, Me and Settings (`ios/ChatView.swift:146`; `ios/MainShell.swift:252`; `ios/SettingsViews.swift:112-115`).
- **Sheets:**
  - SwiftUI `.sheet`: global search, create group, profile editor, QR, moment composer, comment, emoji picker, moments-privacy picker (`ios/ConversationsView.swift:25`; `ios/MainShell.swift:161, 253-254`; `ios/MomentsView.swift:87-88`; `ios/ChatView.swift:109`; `ios/SettingsViews.swift:111, 457`).
  - Kit `.flareBottomSheet`: message actions, forward, report, remark and description edits, location, audience, settings pickers.
- **Confirms and toasts:** `FlareFeedback.confirm` / `.toast` (`ios/ChatView.swift:188`; `ios/FriendActionViews.swift:119-125`; `ios/GroupViews.swift:213-246`; `ios/SettingsViews.swift:145-151, 370-381`; `ios/MomentsView.swift:93-99`).
- **Menus:** the kit `ActionMenuView` for the 通讯录 "+" button (`ios/MainShell.swift:154-160`).
- **System back:** `NavigationStack` back button and swipe; sheets swipe down. Chat hides the system back button and the navigation bar and uses the kit header back (`ios/ChatView.swift:55, 107-108`). `.navigationBarBackButtonHidden(true)` likely disables the interactive swipe-back on chat.

### Screens

| # | Screen | Entry (file:line) | Form factors | Kit components used | App-local views and styling | States | UX or visual issues |
|---:|---|---|---|---|---|---|---|
| 1 | Auth: 登录 / 验证码登录 / 注册 | `ios/FlareSocialRootView.swift:26-28` | Phone: one column. Width ≥ 720 pt: brand rail (`ios/AuthView.swift:85-97`) | FlareScreen(brand), FlareBrandLogo, SegmentedControlView, FormFieldView, InputView, IconButtonView, ButtonView, StatusBannerView | GeometryReader / ScrollView / HStack; SwiftUI fonts `.title`, `.body`, `.caption2`, `.largeTitle` (`:133-157, 217-223`) | Load ✓ (`:265, 318`) · Error ✓ banners (`:256-264`) with verification-code errors mapped to copy (`ios/SocialSession.swift:229-237`) · Offline ✗ | No session restore, so users sign in on every cold start. An autologin hook embeds QA credentials (`ios/FlareSocialRootView.swift:35-39`). A developer gateway field sits in the consumer login (`ios/AuthView.swift:327-340`). |
| 2 | Forgot password subflow | `ios/AuthView.swift:311-313, 395-420` | Same | Same, plus a resend countdown | – | Load ✓ · Error ✓ · Success notice ✓ (`:405-411`) | The most complete of the three apps. |
| 3 | Shell with connection and send-error banners | `ios/FlareSocialRootView.swift:20-25, 51-85` | Phone: bottom nav. ≥ 600: rail. ≥ 900: sidebar | IMAppKitView, StatusBannerView | VStack (`:22-25`) | Offline ✓ reconnecting, disconnected, kicked, expired (`:54-67`) · Error ✓ send-failure banner (`:79-82`) | Kicked and expired banners say "请重新登录" but offer no action (`:62-65`). Connection is assumed connected before any event (`ios/SocialSession.swift:60`). The banner is inserted in layout, so the whole shell shifts down (`:22-25`). |
| 4 | 消息: conversation list | `ios/MainShell.swift:44` | Phone: stack. Regular width: split-view sidebar (`ios/ConversationsView.swift:53-60`) | ConversationListContainerView, ConversationListView, SearchBarView(readOnly) | Toolbar SwiftUI `Button` with `Image(systemName: "arrow.clockwise")` and no accessibility label (`:115-121`) | Load ✓ (`:92-93`) · Empty ✓ (`:94-95`) · Error ✗ `loadConversations` swallows errors (`ios/SocialSession.swift:431-441`) · Offline ✓ global banner | No long-press actions, although the kit supports `onLongPress` (`kios/Components/ConversationListView.swift:23`). No pull-to-refresh. Rows show no mention or draft. |
| 5 | Split-view placeholder | `ios/ConversationsView.swift:67-74` | Regular width only | EmptyStateView | – | – | – |
| 6 | Global search sheet | `ios/ConversationsView.swift:25-27, 100-101`; `ios/SearchView.swift` | All (`.sheet`) | SearchBarView, IconButtonView, EmptyStateView, SearchResultsView | NavigationStack / HStack; `.background(colors.bgPrimary)` (`ios/SearchView.swift:41`) | Load ✓ spinner in the bar (`:24`) · Empty ✓ kit "no results" (`kios/Components/SearchResultsView.swift:25-26`), which also shows while the first request is still running · Error ✗ every source is swallowed (`ios/SocialSession.swift:1208-1254`) | Contact results come from `search_contacts`, which searches friends only (`ios/SocialSession.swift:1208`). Message hits open the chat but never jump to the message (`ios/ConversationsView.swift:136-138`). Group hits open a chat; Android opens group detail instead. |
| 7 | Chat | `ios/ConversationsView.swift:37-39, 65-66`; `ios/MainShell.swift:145-148` | Phone: push with the nav bar hidden. iPad or landscape: split detail | ConversationHeaderView, MessageListView, ComposerView, MessageActionSheetView, ForwardPickerView, FlareEmojiStickerPicker | `.photosPicker`, `.sheet`, `.navigationBarBackButtonHidden`, `.toolbar(.hidden)` (`ios/ChatView.swift:95-121`) | Load ✓ (`:61-62`) · Empty ✓ (`:63`) · Error ✗ `loadMessages` returns `[]` (`ios/SocialSession.swift:763-766`) and image-send errors are swallowed (`:104`) · Offline ✓ global banner · Permission ✓ microphone via the kit, with English copy (`kios/Components/InlineVoiceComposerView.swift:26-28`) | See the list after this table. |
| 8 | Chat header | `ios/ChatView.swift:45-57` | Phone shows back; split hides it | ConversationHeaderView | – | – | Group or friend details open only when the chat is pushed; the iPad split has none (`:211-213`). Non-friend 1:1 chats have none. |
| 9 | Message action sheet | `ios/ChatView.swift:64-66, 124-134` | All | `.flareBottomSheet` + MessageActionSheetView | – | Load ✗ availability is awaited before the sheet appears (`:65`) · Offline ✓ `isConnected` is passed (`ios/SocialSession.swift:1544`) | Same hidden actions as the other apps (`:31`). Copy gives no feedback (`:174`). |
| 10 | Recall and delete confirms | `ios/ChatView.swift:186-207` | All | FlareFeedback.confirm | – | Error ✓ `UserFacingError` keeps the dialog open (`:194-202`) | – |
| 11 | Forward picker | `ios/ChatView.swift:136-145` | All (kit bottom sheet) | ForwardPickerView | – | Error ✗ `forwardMessage` swallows errors and returns nothing, so there is no success or failure feedback (`:141`; `ios/SocialSession.swift:1564-1573`) | Only existing conversations are offered as targets. |
| 12 | Emoji and sticker sheet | `ios/ChatView.swift:109-121` | All (`.sheet`, medium and large) | FlareEmojiStickerPicker | `.presentationDetents` | Error ✗ | Tapping an emoji sends a standalone emoji message instead of inserting it into the text (`:111-114`). |
| 13 | Attach panel: 位置 / 名片 / 投票 | `ios/ChatView.swift:34-38, 78-86` | All | ComposerView actions | – | Error ✗ | Canned demo payloads: a fixed West Lake location, your own card, and a fixed poll "周末去哪玩？" with a per-user constant voteId (`ios/SocialSession.swift:800-819`). |
| 14 | Photos picker | `ios/ChatView.swift:75, 95-106` | All | ComposerView `onImage` | PhotosPicker | Error ✗ load, write and send errors are all ignored (`:100-104`) | No progress or preview. |
| 15 | Voice recorder (kit, inline) | `ios/ChatView.swift:87-92` | All | ComposerView(enableVoice) | – | Permission ✓ (kit) | Recipients cannot play voice messages (`onMediaAction` is not wired). |
| 16 | 通讯录: 联系人 / 群组 / 新的联系人 | `ios/MainShell.swift:45, 73-173` | All (stack) | SegmentedControlView, ContactListView, GroupListView, NewFriendRequestsView, ActionMenuView | Toolbar `Image(systemName: "plus")` inside the kit menu (`:156-158`) | Load ✓ contacts segment only (`:123`) · Empty ✓ (`:109, 115`) · Error ✗ `loadDirectory` uses `try?` (`ios/SocialSession.swift:399-427`) | No pending-request badge on the tab or the segment. If the contact leaves the list while its route is on the stack, the page goes blank (`:134-144`). |
| 17 | "+" action menu | `ios/MainShell.swift:81-98, 154-160` | All | ActionMenuView | – | – | "刷新" sits among creation actions. |
| 18 | New friend requests segment | `ios/MainShell.swift:111-121` | All | NewFriendRequestsView (incoming and outgoing) | – | Empty ✓ (`:115`) · Error ✗ accept, reject and withdraw are swallowed (`ios/SocialSession.swift:554-609`) | Withdraw has no confirm (`:120`); Flutter confirms. |
| 19 | Blocked list | `ios/MainShell.swift:94, 151, 176-206` | All (push) | EmptyStateView, ContactItemView (trailing), ButtonView | ScrollView / LazyVStack; `.background` (`:201`) | Load ✗ the empty state flashes before data loads (`:183-185, 204`) · Error ✗ | Unblock has no confirm and no feedback (`:191-193`). |
| 20 | Contact detail | `ios/MainShell.swift:134-144`; `ios/ChatView.swift:220-224` | All (push) | FlareContactDetail, ButtonView (举报此人), FormSheetView, FormFieldView, InputView, StatusBannerView | VStack | Load partial: extras load asynchronously (`ios/FriendActionViews.swift:128-133`) · Error ✓ for remark, description and star (`:53-54, 87-92, 104-107`) · Error ✗ for block and delete, whose actions cannot throw (`:57-66`; `ios/SocialSession.swift:637-646`) | Report is a footer text button (`:68-72`); Android puts it in an overflow menu. |
| 21 | Edit remark and description sheets | `ios/FriendActionViews.swift:79-114` | All | `.flareBottomSheet` + FormSheetView | – | Error ✓ inline banner | – |
| 22 | Block and delete-friend confirms | `ios/FriendActionViews.swift:57-66, 117-125` | All | FlareFeedback.confirm | – | Error ✗ always closes as success | – |
| 23 | Report sheet | `ios/FriendActionViews.swift:78`; `ios/GroupViews.swift:139`; `ios/MomentsView.swift:77`; `ios/ReportViews.swift:19-81` | All | FormSheetView, StatusBannerView, FormFieldView, RadioGroupView, TextareaView, FlareFeedback.toast | – | Load ✓ busy (`ios/ReportViews.swift:40`) · Error ✓ including the 429 rate limit (`:72-78`) · Success toast (`:69`) | The reason is preselected as 垃圾广告 (`:26`); Android preselects nothing. No entry point for reporting a message or a comment, although those target kinds exist (`ios/SocialSession.swift:1702-1716`). |
| 24 | Add friend | `ios/MainShell.swift:91, 149`; `ios/FriendActionViews.swift:136-244` | All (push) | SearchBarView, EmptyStateView, ContactItemView (trailing), ButtonView, InputView, ContactMatchListView | Divider (`:176`); SwiftUI `Text` with `.font(.subheadline / .caption)` (`:190-194`); `.background` (`:179`) | Load ✓ spinner in the bar (`:152`) · Empty ✓ (`:154-158`) · Error ✗ | Search calls `session.search`, which uses friends-only `search_contacts`, so strangers cannot be found (`:227-243`; `ios/SocialSession.swift:1206-1221`). Searches every keystroke (`:182`). No greeting message. Address-book "发消息" for existing friends does nothing (`:201-204`). |
| 25 | Join group | `ios/MainShell.swift:92, 150`; `ios/FriendActionViews.swift:246-309` | All (push) | SearchBarView, EmptyStateView, ContactItemView (trailing), ButtonView | LazyVStack; `.background` (`:285`) | Load ✓ · Empty ✓ distinct copy for no query and no results (`:261-263`) · Error ✗ a failed join is silent (`:276`) | Every result shows "0 人" (`:271, 302`). |
| 26 | Create group sheet | `ios/MainShell.swift:93, 161-163`; `ios/GroupViews.swift:10-64` | All (`.sheet`) | InputView, EmptyStateView, StartConversationView | NavigationStack; SwiftUI `Button("取消")` (`ios/GroupViews.swift:46-50`) | Load ✓ busy (`:38`) · Empty ✓ no contacts (`:30-32`) · Error ✗ a failure dismisses silently (`:54-63`) | After creation it opens group detail rather than the new chat (`ios/MainShell.swift:162`). |
| 27 | Group detail | `ios/MainShell.swift:130-133`; `ios/ChatView.swift:218-219` | All (push) | FlareGroupDetail, AnnouncementReadBarView, ButtonView (举报群聊), FlareFeedback | – | Load ✓ (`ios/GroupViews.swift:101`) · Error ✗ writes are swallowed (`:111-133`; `ios/SocialSession.swift:1347-1422`). `loadGroupDetail` never returns nil, so a failed load renders an empty fake group instead of an error (`ios/SocialSession.swift:1273-1345`) | Notify mode collapses the server's three levels (all, mentions only, muted) into a boolean (`ios/SocialSession.swift:1413-1417`). The admin "查看未读" link is not wired (`:145-150`; `kios/Components/VisibilityAndMatchViews.swift:319-320`). Leaving a group from its chat returns to the dead chat (`:244`). |
| 28 | Member management and edit sheets (kit-internal) | Callbacks at `ios/GroupViews.swift:111-134` | All | FlareGroupDetail internals | – | Error ✗ | – |
| 29 | Remove-member and leave/dissolve confirms | `ios/GroupViews.swift:213-246` | All | FlareFeedback.confirm | – | Error ✓ | – |
| 30 | 圈子 feed | `ios/MainShell.swift:46`; `ios/MomentsView.swift:9-100` | All | MomentsCoverHeaderView, EmptyStateView, MomentCardView, ButtonView (举报) | NavigationStack; ScrollView / LazyVStack; HStack / Spacer; toolbar `Image(systemName: "camera")` with no label (`:78-84`); `.background` (`:74`); `.refreshable` (`:85`) | Load ✗ blank while first loading, because `isEmpty` excludes loading (`ios/MomentsViewModel.swift:25` against `ios/MomentsView.swift:37-45`, which makes the "加载中…" title dead code) · Empty ✓ · Error partial: the raw `String(describing:)` shows in the empty state only (`:40`; `ios/MomentsViewModel.swift:143-145`) | No paging, although the view model supports a cursor (`ios/MomentsViewModel.swift:40-56`). Tapping your own avatar opens the composer (`:34`). A 举报 text button sits under every card from someone else (`:58-69`). Like, comment and delete errors are invisible once the feed has items. |
| 31 | Publish sheet | `ios/MomentsView.swift:80-82, 87, 106-216` | All (`.sheet`) | MomentComposerView(maxImages: 0), FormSheetView, FormFieldView, InputView, MomentAudienceSheetView | NavigationStack; HStack / Spacer | Load ✓ busy · Error ✗ a failure keeps the sheet open with no message (`:200-215`) | Text-only moments (`:151-152`); Flutter supports images. |
| 32 | Location sheet | `ios/MomentsView.swift:170-181` | All | `.flareBottomSheet` + FormSheetView | – | – | Free text; no location picker. |
| 33 | Audience sheet | `ios/MomentsView.swift:182-195` | All | `.flareBottomSheet` + MomentAudienceSheetView | – | – | Presented as a real overlay. |
| 34 | Comment sheet | `ios/MomentsView.swift:52-54, 88, 222-275` | All (`.sheet`) | MomentCardView, InputView, ButtonView | Divider; HStack; SwiftUI `Button("关闭")` (`:259-261`) | Error ✗ failures are silent (`:265-273`) | Tapping a comment opens the same sheet with no reply target (`:54`); the view model's reply parameter is unused (`ios/MomentsViewModel.swift:102`). |
| 35 | Delete-moment confirm | `ios/MomentsView.swift:93-99` | Own moments | FlareFeedback.confirm | – | Error ✗ delete cannot throw (`ios/MomentsViewModel.swift:120-127`) | – |
| 36 | 我 | `ios/MainShell.swift:47, 212-257` | All | ProfilePanelView | ZStack over `colors.bgSecondary` | – | Only two rows: 设置 and a developer "FFI 契约" value (`:233-239`). |
| 37 | Profile editor sheet | `ios/MainShell.swift:253`; `ios/SettingsViews.swift:385-425` | All (`.sheet`) | ProfileEditorView | NavigationStack / ZStack | Error ✗ dismisses even when the save failed (`:410-415`) | The signature is not prefilled (`signature: nil`, `:401`), so saving likely blanks an existing bio. No avatar picker. |
| 38 | My QR sheet | `ios/MainShell.swift:254`; `ios/SettingsViews.swift:111, 278-302` | All (`.sheet`) | QRCardView | SwiftUI `Button("完成")` (`:298`) | Load partial: the kit "unavailable" frame shows until the token arrives (`:293`) | No save, share or scan. |
| 39 | 设置 | `ios/MainShell.swift:252`; `ios/SettingsViews.swift:36-185` | All (push) | SettingsListView, `.flareBottomSheet` + RadioGroupView, FlareFeedback | – | Load ✗ the privacy toggle shows "on" until loaded, and `privacyKnown` is never used (`:45-46, 101`) · Error ✗ the toggle write is swallowed (`:80`) | Choosing English only changes the locale; kit and app copy stay Chinese (`:26-32`; `kios/Tokens/FlareStrings.swift:503-520`). Developer 联调诊断 sits in the 账号 section (`:168`). |
| 40 | Theme, language and moments-range pickers | `ios/SettingsViews.swift:104-123` | All | `.flareBottomSheet`, RadioGroupView | – | Error ✗ for the range write | – |
| 41 | Logout confirm | `ios/SettingsViews.swift:145-151` | All | FlareFeedback.confirm | – | – | The only app that confirms logout. |
| 42 | 联调诊断 | `ios/SettingsViews.swift:114, 189-274` | All (push) | StatusBannerView, SettingsListView, ButtonView | VStack | Offline ✓ | "重新登录" logs out without confirmation (`:221-223`). |
| 43 | 多设备登录 | `ios/SettingsViews.swift:112, 305-382` | All (push) | DeviceSessionsView, StatusBannerView, IconButtonView, FlareFeedback | ScrollView | Load ✓ · Empty ✓ · Error ✓ with reload (`:320-331, 360-366`) · Revoke confirm ✓ | Reference behaviour: revoke is disabled while the current device is unknown (`:317-325`). |
| 44 | 我的举报 | `ios/SettingsViews.swift:113`; `ios/ReportViews.swift:85-166` | All (push) | EmptyStateView, SettingsListView, IconButtonView | – | Load ✓ · Empty ✓ · Error ✓ with retry (`:95-106`) | The date format is hard-coded to "MM/dd HH:mm" (`:153-158`). |
| 45 | 朋友圈权限 with picker sheet | `ios/SettingsViews.swift:115, 431-489` | All | MomentsVisibilityRuleListView ×2, ContactListView, IconButtonView | `.sheet` wrapping a NavigationStack (`:457-470`) | Load ✓ (`:443, 448`) · Error ✗ (`:485-488`) | – |
| 46 | Global toasts (login alert, report submitted, star failure) | `ios/SocialSession.swift:351-354`; `ios/ReportViews.swift:69`; `ios/FriendActionViews.swift:54` | All | FlareFeedback.toast | – | – | Uses the kit presenter. |

Row 7 (chat) issues:

- No paging: the limit is 50 and the data layer has no `beforeSeq` parameter.
- Media taps are inert (`onMediaAction` is not passed).
- No drafts and no reply: `ComposerView`'s `text:` and `replyTo:` parameters are unused (`kios/Components/ComposerView.swift:80-84`).
- Group chats are detected by a "群聊" row tag (`ios/ChatView.swift:237-239`). A chat opened from search or contacts without a list row renders as a single chat titled "会话" (`ios/ConversationsView.swift:125-129`; `ios/MainShell.swift:146-148`).
- Every SDK event reloads the thread and marks it read, with no visibility or scene-phase check (`ios/ChatView.swift:158-163`). With keep-alive tabs (`ios/MainShell.swift:40-58`), an iPad split chat keeps marking read while another tab is showing.
- The read seq is the maximum over whichever chat loaded last (`ios/SocialSession.swift:1596-1599, 774-778`).


## Android: flare-social-android-app (Compose)

### Navigation model

- **Root:**
  - `MainActivity` enables edge-to-edge, points native data roots at app storage and hard-codes the emulator social gateway `http://10.0.2.2:50200` (`and/MainActivity.kt:16-29`). It reads dev hooks from intent extras (`:32-36`).
  - `FlareSocialApp` switches between `AuthScreen` and `ConnectionBanner` + `MainShell`, inside `ThemedRoot` and the kit `FlareToastHost` (`and/FlareSocialApp.kt:75-94, 134-150`).
  - No session restore: the phase starts `SignedOut` (`and/SocialSession.kt:278`).
- **Shell:** kit `IMAppKit` with 4 destinations and an unread badge only (`and/FlareSocialApp.kt:565-575, 646-674`). The mode comes from `BoxWithConstraints` `maxWidth` (`:626-628`). The phone bottom nav is hidden whenever a route is open, or a chat is open on a phone (`:673`).
- **Navigation:**
  - No navigation library. `MainShell` keeps nullable and boolean route flags in `rememberSaveable` and resolves them with a priority `when` (`:547-555, 578-624`). Routes replace the shell content.
  - 我 sub-screens return early inside the tab (`and/SettingsScreen.kt:98-105`), and so does the moments composer (`and/MomentsScreen.kt:82-85`). Both leave the bottom nav visible.
- **Tablet:** on 消息 with no route open, the inbox is the `primary` pane and the chat or placeholder is the content (`and/FlareSocialApp.kt:645-658`). Opening any route removes the inbox pane (`:645`). Other tabs are single pane.
- **Overlays:** all kit, and all implemented as Dialog or Popup windows, so system back dismisses them (`kand/BottomSheet.kt:100`; `kand/FormDialog.kt:38`; `kand/ActionMenu.kt:289`).
  - `BottomSheet`: message actions, audience, profile editor.
  - `FormDialog`: remark and description, comment, theme, moments range, notify mode, location, report, moment actions.
  - `DangerConfirm`: recall and delete, block and delete friend, remove member, leave group, delete moment.
  - `ActionMenu` popups: 通讯录 更多, contact 更多, group 更多.
- **System back:** the kit registers `BackHandler` for `FlareScreen(onBack)`, `ConversationHeader(showBack)` and `FlareGroupDetail(onBack)`, because the default adapter declares `nativeBack` (`kand/FlarePlatform.kt:46-54, 196-200`; `kand/FlareScreen.kt:56`; `kand/ConversationHeader.kt:175`; `kand/FlareGroupDetail.kt:247`). Routes therefore pop. Tab roots register nothing, so back exits the app.

### Screens

| # | Screen | Entry (file:line) | Form factors | Kit components used | App-local composables and styling | States | UX or visual issues |
|---:|---|---|---|---|---|---|---|
| 1 | Auth: Sign in / Code sign-in / Create account | `and/FlareSocialApp.kt:89-91, 172-338` | Phone: one column. ≥ 720 dp: two columns (`:324-335`) | FlareScreen(brand), FlareBrandLogo, SegmentedControl, FormField, Input, IconButton, Button, StatusBanner | `AuthForm`, `BrandRail`, `BrandLockup`, `AuthHeading`, `SpecStrip`, `AuthFooterLine`; material3 `Text` (`:343-399`) | Load ✓ (`:434-438`) · Error ✓ banner with verification-code errors mapped to copy (`and/SocialSession.kt:445-456`) · Offline ✗ | The whole auth UI is English while the rest of the app is Chinese (`:289-510`). The spec strip claims "WASM core in-page" on an FFI build (`:530`). No session restore. Autologin with QA credentials can be triggered by intent extras on the exported activity (`:76-78`; `and/MainActivity.kt:32-36`). |
| 2 | Reset password | `and/FlareSocialApp.kt:223-224, 259-277` | Same | Same | – | Load ✓ · Error ✓ · Success notice ✓ (`and/SocialSession.kt:421-436`) | – |
| 3 | Shell with connection and send-error banners, and toasts | `and/FlareSocialApp.kt:82-126, 545-676` | Phone: bottom nav. ≥ 600: rail. ≥ 900: sidebar | IMAppKit, StatusBanner, FlareToastHost | `ConnectionBanner`; Column (`:85-88`); `ThemedRoot` with the default Material color scheme (`:146-148`) | Offline ✓ (`:105-111`) · Error ✓ send banner (`:122-124`); sends are blocked while kicked (`and/SocialSession.kt:836-842`) | Opening a chat from the 通讯录 tab strands the user on phones (see the list after this table). Kicked and expired banners have no re-login action. Connection is assumed connected before any event (`and/SocialSession.kt:265`). |
| 4 | 消息 list | Phone `and/FlareSocialApp.kt:660`; wide primary pane `:653` | Phone: full screen. ≥ 600: primary pane | FlareScreen, IconButton ×2, ConversationListContainer, SearchBar(readOnly), ConversationList | Row | Load ✓ (`and/ConversationsScreen.kt:37-40`) · Empty ✓ (`:65-66`) · Error ✗ (`and/SocialSession.kt:777`) · Offline ✓ banner | Create group lives here (`:46`); iOS puts it under 通讯录 and Flutter under 群组. No long-press actions. The draft label works (`:61-68`), but the mention label never shows because `mentioned` is not mapped (`and/SocialSession.kt:1517-1527`). |
| 5 | Wide placeholder | `and/FlareSocialApp.kt:657-658` | ≥ 600 | EmptyState | – | – | – |
| 6 | Search | `and/FlareSocialApp.kt:607-622`; `and/SearchScreen.kt` | All (route) | FlareScreen, SearchBar, SearchResults | – | Load ✓ spinner in the bar (`and/SearchScreen.kt:47-52`) · Empty partial: kit "no results" shows even before typing (`:55`) · Error ✗ each source is swallowed (`and/SocialSession.kt:913-947`) | Contact hits do nothing unless a conversation id equals the user id (`and/FlareSocialApp.kt:617-618`). Message hits open the conversation but do not jump to the message (`:615-616`). Group hits open group detail. |
| 7 | Chat | `and/FlareSocialApp.kt:629-636, 657, 660` | Phone: full screen with the nav hidden. ≥ 600: content pane | ConversationHeader, MessageList, Composer, FlareEmojiStickerPicker, BottomSheet, MessageActionSheet, DangerConfirm, FlareScreen, ForwardPicker, toast | Column with `background`, `statusBarsPadding` and `navigationBarsPadding`, but no IME padding (`and/ChatScreen.kt:164, 195`) | Load ✓ (`:188`) · Empty ✓ (`:189`) · Error ✗ `loadMessages` returns `[]` (`and/SocialSession.kt:794-796`) · Offline ✓ global banner and send guard · Permission ✓ microphone via the kit (`kand/InlineVoiceComposer.kt:112-121`) | The composer is likely covered by the keyboard: the app is edge-to-edge and nothing on this path handles IME insets (`and/MainActivity.kt:16`; `kand/FlareScreen.kt:50, 64`). A back arrow shows even in the tablet content pane (`:177`). No paging. Media taps are inert. Drafts work (`:197-198`). Message maps are mutated off the main thread (`and/SocialSession.kt:793-813`). |
| 8 | Chat header | `and/ChatScreen.kt:166-182` | All | ConversationHeader | – | – | Only groups get details (`:173`); iOS also opens a friend's card. |
| 9 | Message action sheet | `and/ChatScreen.kt:190, 239-258` | All | BottomSheet, MessageActionSheet | – | Load ✗ | Copy gives no feedback (`:252`). |
| 10 | Recall and delete confirms | `and/ChatScreen.kt:260-277` | All | DangerConfirm | – | Error partial: the dialog closes first, then a toast reports failure (`:267-273`) | Flutter and iOS keep the error inside the dialog instead. |
| 11 | Forward (full screen) | `and/ChatScreen.kt:131-144` | All (route inside the chat) | FlareScreen, ForwardPicker | – | Error ✗ the result is ignored (`:139`; `and/SocialSession.kt:1407-1419`) | The forward screen is an early return inside `ChatScreen` (`:132-144`), so the message list leaves composition and scroll position resets on return. |
| 12 | Emoji and sticker panel (docked) | `and/ChatScreen.kt:211, 220-233` | All | FlareEmojiStickerPicker | – | Error partial: send failures raise the global banner (`and/SocialSession.kt:843-848`) | Tapping an emoji sends a message (`:224-227`). |
| 13 | Attach panel demos | `and/ChatScreen.kt:119-125, 203-210` | All | Composer actions | – | – | The same canned payloads as iOS (`and/SocialSession.kt:852-868`). |
| 14 | Image picker | `and/ChatScreen.kt:146-162, 202` | All | Composer `onImage` | `rememberLauncherForActivityResult(OpenDocument)` plus a temp-file copy | Error partial: a toast on exceptions only; `sendImage` returning false is silent (`:157-160`) | Uses the document picker rather than the Photo Picker (`:147`). |
| 15 | Voice recorder (kit, inline) | `and/ChatScreen.kt:212-218` | All | Composer(enableVoice) | – | Permission ✓ (kit) | – |
| 16 | 通讯录 | `and/FlareSocialApp.kt:661-668`; `and/ContactsScreen.kt` | All | FlareScreen, IconButton, ActionMenu, SegmentedControl, ContactList, GroupList, NewFriendRequests, EmptyState | `EmptyHint` (`and/ContactsScreen.kt:108-113`); Box / Column | Load ✗ the empty hint shows while loading (`:85, 88`) · Empty ✓ · Error ✗ | The menu has no 发起群聊 (`:58-62`). No request badge. Refetches on every visit (`:47`). |
| 17 | 更多 menu (通讯录) | `and/ContactsScreen.kt:52-74` | All | IconButton, ActionMenu | – | – | – |
| 18 | Friend requests segment | `and/ContactsScreen.kt:90-101` | All | NewFriendRequests | – | Empty ✓ · Error ✗ (`and/SocialSession.kt:617-624, 664`) | Withdraw has no confirm (`:99`). Incoming requests read top-level name fields only (`and/SocialSession.kt:1471-1476`), while iOS and Flutter read the applicant profile (`ios/SocialSession.swift:728-738`; `fl/sdk/base_social_client.dart:141-163`), so names likely show blank. |
| 19 | Blocked list | `and/FlareSocialApp.kt:599, 667`; `and/FriendActionScreens.kt:306-327` | All (route) | FlareScreen, EmptyState, ContactItem (trailing), Button | LazyColumn | Load ✗ (`:313-316`) · Error ✗ | Unblock has no confirm and no feedback (`:321`). |
| 20 | Contact detail with 更多 menu | `and/FlareSocialApp.kt:593-596`; `and/FriendActionScreens.kt:54-150` | All (route) | FlareScreen, IconButton, ActionMenu, StatusBanner, ContactDetail, FormDialog, FormField, Input, DangerConfirm, ReportSheet | Box / Column | Load – (uses the session cache) · Error partial: a banner when a chat cannot be opened (`:98-106`); remark, description and star writes are silent (`:111, 118-131`) | Opening a chat from here strands the user (row 3). Report is hidden in the overflow menu (`:76-87`). The remark does not update on the card until the directory reloads. Starting a first chat may fail: `resolvePeerConversation` returns null unless the conversation is already listed (`and/SocialSession.kt:762-769`). |
| 21 | Remark and description dialogs | `and/FriendActionScreens.kt:118-132` | All | FormDialog | – | Error ✗ | – |
| 22 | Block and delete-friend confirms | `and/FriendActionScreens.kt:133-148` | All | DangerConfirm | – | Error ✗ the dialog closes and navigates back regardless of the result (`:137, 145`) | – |
| 23 | Report dialog | `and/ReportSheet.kt:72-125`, opened from contact, group and moment | All | FormDialog(danger), FormField, RadioGroup, Textarea, StatusBanner, toast | material3 `Text` (`:107`) | Load ✓ busy · Error ✓ with the 429 message (`:128-132`) · Success toast (`:92`) | No preselected reason (`:77-78`); iOS preselects one. Reason copy "诈骗欺诈" against iOS "诈骗". |
| 24 | Add friend | `and/FlareSocialApp.kt:597`; `and/FriendActionScreens.kt:152-253` | All (route) | FlareScreen, SearchBar, EmptyState, ContactItem (trailing), Button, Input, ContactMatchList | LazyColumn; material3 `Text` section heading (`:206-211`) | Load ✗ no spinner (`:175`) · Empty ✓ (`:178-184`) · Error ✗ | Searches on every keystroke with no debounce (`:165-171`). No greeting message. Address-book "发消息" does nothing. |
| 25 | Join group | `and/FlareSocialApp.kt:598`; `and/FriendActionScreens.kt:255-304` | All (route) | FlareScreen, SearchBar, EmptyState, ContactItem (trailing), Button | LazyColumn | Load ✗ · Empty ✓ · Error ✗ a failed join is silent (`:296`) | The member count is dropped (`:269`). |
| 26 | Create group | `and/FlareSocialApp.kt:600-606, 642`; `and/GroupScreens.kt:50-81` | All (route) | FlareScreen, FormField, Input, StartConversationDialog | Column | Load ✓ busy · Empty ✓ picker · Error ✗ a failure silently navigates back (`:72-75`) | After creation it opens group detail (`and/FlareSocialApp.kt:603`). |
| 27 | Group detail with header 更多 menu | `and/FlareSocialApp.kt:579-591`; from chat `:633` | All (route; replaces the inbox pane on tablet) | FlareGroupDetail (onBack, headerActions, afterInfo, footer), IconButton, ActionMenu, AnnouncementReadBar, Button, DangerConfirm, FormDialog, RadioGroup, ReportSheet | Box; `statusBarsPadding` / `navigationBarsPadding` (`and/GroupScreens.kt:182, 229`) | Load ✓ (`:183`) · Error partial: remove and leave errors stay in the dialog (`:278-316`); every other write is silent (`:131-132`) | "发消息" does nothing when the group has no local conversation yet (`and/FlareSocialApp.kt:584-589`). After leaving from a chat, back returns to the dead chat (`:310`). The admin "查看未读" link is correctly hidden when unwired (`kand/VisibilityAndMatch.kt:317`). |
| 28 | 通知方式 dialog (all / mentions only / muted) | `and/GroupScreens.kt:199-212, 320-341` | All | FormDialog, RadioGroup | – | Error ✗ | Only Android exposes the "mentions only" setting. |
| 29 | Member management (kit-internal) | Callbacks at `and/GroupScreens.kt:240-275` | All | FlareGroupDetail internals | – | Error ✗ | Muting a member always sends a 24 h `muted_until` (`and/SocialSession.kt:1024-1029`); iOS and Flutter send no expiry. |
| 30 | Remove-member and leave/dissolve confirms | `and/GroupScreens.kt:278-316` | All | DangerConfirm (busy, error) | – | Error ✓ | – |
| 31 | 圈子 feed | `and/FlareSocialApp.kt:669`; `and/MomentsScreen.kt:58-180` | All | FlareScreen, IconButton ×2, MomentsCoverHeader, EmptyState, MomentCard | LazyColumn; `pointerInput` long-press wrapper (`:124-127`) | Load ✓ (`:112-114`) · Empty ✓ · Error partial: the raw `t.message` shows as the empty-state description (`:113`; `and/MomentsViewModel.kt:193`) | Report is reachable only by long-pressing or tapping the author (`:124-134`). No paging: `loadMore` is never called (`and/MomentsViewModel.kt:62-67`). No pull-to-refresh. Tapping your own avatar opens the composer (`:105`). |
| 32 | Moment actions dialog | `and/MomentsScreen.kt:164-178` | Moments from others | FormDialog(danger) | material3 `Text` (`:176`) | – | A dialog whose only action is 举报. Tapping an author never opens a profile. |
| 33 | Comment and reply dialog | `and/MomentsScreen.kt:145-155` | All | FormDialog, Input | – | Error ✗ silent unless the feed is empty | The only app with reply-to-comment. |
| 34 | Delete-moment confirm | `and/MomentsScreen.kt:156-163` | Own moments | DangerConfirm | – | Error ✗ | The fixed sentence "删除后不可恢复。" is passed as `target`, the slot meant for the item's name (`:158`). |
| 35 | Publish composer (route) | `and/MomentsScreen.kt:82-85, 187-249` | All (full screen, bottom nav still visible) | FlareScreen, MomentComposer(maxImages = 0), BottomSheet, MomentAudienceSheet | Column | Load ✓ busy · Error ✗ the screen closes even when publishing failed, losing the text (`:225-232`) | Text-only moments. |
| 36 | Location dialog | `and/MomentsScreen.kt:252-260` | All | FormDialog, Input | – | – | – |
| 37 | Audience sheet | `and/MomentsScreen.kt:235-247` | All | BottomSheet, MomentAudienceSheet | – | – | – |
| 38 | 我 | `and/FlareSocialApp.kt:670`; `and/SettingsScreen.kt:77-171` | All | FlareScreen, ProfilePanel, SettingsList | Column | Load ✗ the privacy toggle shows "on" until loaded (`:86-89`) · Error ✗ writes are silent (`:154`) | See the list after this table. |
| 39 | Edit profile sheet | `and/SettingsScreen.kt:148, 173, 213-236` | All | BottomSheet, ProfileEditor | `Column(verticalScroll)` | Error ✗ closes even when the save failed (`:229-232`) | No avatar edit. |
| 40 | Theme dialog | `and/SettingsScreen.kt:175-191` | All | FormDialog, RadioGroup | – | – | Not persisted. |
| 41 | Moments range dialog | `and/SettingsScreen.kt:193-210` | All | FormDialog, RadioGroup | – | Error partial: returns the requested value on failure | – |
| 42 | QR screen | `and/SettingsScreen.kt:99, 149, 242-256` | All (tab sub-route) | FlareScreen, QRCard | Box | Load partial: the kit "unavailable" frame shows until the token arrives | No share, save or scan. |
| 43 | 联调诊断 | `and/SettingsScreen.kt:101, 262-311` | All | FlareScreen, StatusBanner, SettingsList, Button ×2 | Row / Box | Offline ✓ | "重新登录" logs out without confirmation (`:305-307`). |
| 44 | 多设备登录 | `and/SettingsScreen.kt:100, 343-389` | All | FlareScreen, IconButton, DeviceSessions | – | Load ✓ · Error partial: a load failure shows an empty list (`and/SocialSession.kt:1344-1355`); a revoke failure shows a banner (`:382`) | Revoke has no confirmation (`:377-385`) and no guard while the current device is unknown. |
| 45 | 我的举报 | `and/SettingsScreen.kt:103, 395-434` | All | FlareScreen, IconButton, EmptyState, SettingsList | Box | Load ✓ · Empty ✓ · Error ✗ a failure shows as empty (`and/SocialSession.kt:1195-1198`) | Target names are not resolved (`:424`). |
| 46 | 朋友圈权限 with picker screen | `and/SettingsScreen.kt:102, 442-493` | All | FlareScreen ×2, MomentsVisibilityRuleList ×2, ContactList | – | Load ✓ (`:477, 486`) · Error ✗ | – |
| 47 | Global toasts | `and/SocialSession.kt:291, 544` | All | FlareToastHost, LocalFlareToast | – | – | – |

Row 3 (shell) issue: opening a chat from the 通讯录 tab strands the user on phones.

- Contact detail "发消息" and group detail "发消息" both set `openId` but leave `tab = "contacts"` (`and/FlareSocialApp.kt:584-596`).
- Content is chosen by tab (`:655-671`), so 通讯录 keeps rendering, while `hideMobileNavigation = mobile && open != null` hides the bottom nav (`:673`).
- `ContactsScreen` has no back handler (`and/ContactsScreen.kt:49-51`), so the only way out is leaving the app.

Row 38 (我) issues:

- The language row toggles between zh and en immediately, although it looks like a navigation row with a chevron. It only writes the profile locale; no UI copy changes (`and/SettingsScreen.kt:111-112, 159`; `and/SocialSession.kt:1226-1231`).
- Logout has no confirmation (`:166`).
- Theme is not persisted (`and/SocialSession.kt:319`).
- 联调诊断 uses the same icon as 多设备登录 (`:124-126`).


## Flutter, iOS and Android: consistency

Verdict: **Idiom** means a legitimate platform difference; **Drift** means the difference should be removed.

| Area | Flutter | iOS | Android | Verdict |
|---|---|---|---|---|
| Session persistence | Restores from a stored token snapshot, but deletes it on any restore error (`fl/sdk/base_social_client.dart:570-630`) | No restore | No restore | **Drift.** The ops exist (`soc/ffi/ops/auth.rs:60-84`), and only the Flutter SDK wrapper has IM-only login. |
| Auth modes and copy | Password and register; mixed English/Chinese; show-password checkbox; spec chips claim WASM | Password, code, register and reset; Chinese; eye toggle; correct "C ABI" strip | Same modes as iOS; English; eye toggle; claims WASM | **Drift** in feature set, language, reveal control and the false spec copy. **Idiom:** system fonts on iOS. |
| Wide auth layout | Brand rail at ≥ 900 (`FlareSizes.appShellCompactMinWidth`) | Brand rail at ≥ 900 (`appShellCompactMinWidth`) | Brand rail at ≥ 900 | **Converged** (Round 9): iOS and Android had borrowed the 720 pane threshold, which no longer exists; the Tauri auth page's 860 px media query moved to 900 with them. |
| Shell information architecture | 5 tabs (群组 and 设置 are tabs), avatar opens 个人中心, badges for unread and requests | 4 tabs (我), unread badge only | 4 tabs (我), unread badge only | **Drift** (IA and badges). **Idiom:** tab icons come from each platform's set (Material Icons, SF Symbols, Material filled), but the 圈子 metaphor differs (camera, photo stack, explore), which is drift. |
| Tablet and wide layout | Split on 消息 at ≥ 600; resizing drops the selection; details and contact chats are always full-screen routes | 消息 splits by size class; shell mode follows width; the split chat has no details | Inbox pane on 消息 at ≥ 600; any route removes the pane; chat keeps a back arrow in the pane | **Idiom:** NavigationSplitView on iPad. **Drift:** what triggers the split, details availability in the split, the back arrow in a pane. |
| System back | Navigator; the wide chat is not a route; contact detail blocks swipe-back | NavigationStack; chat hides the back button, so swipe-back is likely lost | Kit BackHandler on routes; tab roots exit the app | **Idiom:** mechanisms differ per platform. **Drift:** iOS chat breaks the platform gesture; the Android strand bug (§3). |
| Conversation list toolbar | Refresh button plus pull-to-refresh; no search entry | Refresh toolbar button, read-only search bar opens a sheet, no pull-to-refresh | Create-group and refresh icons, read-only search bar opens a route | **Drift.** **Idiom:** sheet on iOS against route on Android. |
| Conversation row actions | None | None | None | Consistently missing. The kits support `onLongPress` and a ConversationActionSheet; the core has pin, mute, delete, archive and mark-unread (`core/bindings/contract/apis.json:641-671`). |
| Global search | None | Friends (friends-only op), groups, messages; group hit opens a chat; message hit does not locate | Users, groups, messages; contact hit is a dead end; group hit opens detail; message hit does not locate | **Drift.** |
| Chat header details | Groups only, using the wrong group id | Group or friend, pushed only | Groups only | **Drift.** |
| Message action sheet | Kit sheet with core availability; same hidden action set | Same | Same | **Converged.** The confirm-failure pattern still drifts: Flutter and iOS keep the error in the dialog; Android closes the dialog and shows a toast. |
| Forward | Bottom sheet at 70% height; toast with result counts | Kit bottom sheet; no feedback | Full-screen route; no feedback; scroll resets on return | **Drift** in feedback. **Idiom:** sheet against full screen. |
| Emoji input | Kit panel inserts `[key]` into the text | Sheet; a tap sends a standalone emoji message | Docked panel; a tap sends a standalone emoji message | **Drift.** iOS and Android break the usual IM expectation that emoji insert into the text. |
| Attach panel | Kit default action set, image only | Canned demo location, card and poll; image via toolbar | Same canned demos as iOS; image via the document picker | **Drift.** Android should use the Photo Picker (**PLATFORM** idiom). |
| Mentions | "@name" text only, no ids sent | No picker | The "@" tool appends one character | **Drift.** The kit composer send contract carries text only on all three (`kfl/components/flare_composer.dart:141`; `kios/Components/ComposerView.swift:90`; `kand/Composer.kt:127`). |
| Failed send | Text kept, because the kit awaits the result | Text cleared immediately (`kios/Components/ComposerView.swift:298-303`) | Text cleared immediately (`kand/Composer.kt:168-182`) | **Drift** in the kit contract (DESIGN_SYSTEM). |
| Drafts | None | None, although `text:` binding exists | In-memory drafts with a row label | **Drift.** None use `conversation.update_draft` (`core/bindings/contract/apis.json:671`). |
| Media viewing | Inert | Inert | Inert | Consistently missing (§5, item 2). |
| Contacts IA | Groups is its own tab; requests are a row pushing tabbed incoming/sent; no blocked list | Segments 联系人 / 群组 / 新的联系人; "+" menu holds add, join, create group, blocked, refresh | Same segments; 更多 menu holds add, join, blocked; create group lives on 消息 | **Drift.** Copy differs too (新的朋友 against 新的联系人). |
| Contact detail | Neutral dialogs for block and delete; no report; edits in centered dialogs | Danger confirms; report as footer button; edits in bottom sheets | Danger confirms; report in overflow menu; edits in centered dialogs | **Idiom:** sheet against dialog. **Drift:** confirm severity and report placement. |
| Add friend | Global user search, match list | Friends-only search, match list | Global user search, match list | **Drift.** iOS is functionally broken. None offer a greeting message. |
| Join group | Tap row, then confirm dialog | Trailing button, no confirm; always "0 人" | Trailing button, no confirm; no count | **Drift.** |
| Create group | Name-only dialog; empty group; stays on list | Sheet with name and member picker; opens group detail | Route with name and member picker; opens group detail | **Drift.** Flutter lacks the member picker. **Idiom:** sheet against route. |
| Group detail | Kit screen; roles mis-mapped; no report; notify is a boolean; pops the chat after leaving | Kit screen; report footer; notify is a boolean; returns to the dead chat | Kit screen; report footer; three-level notify in 更多; returns to the dead chat; 24 h member mute | **Drift** throughout. |
| Announcement read bar | "查看未读" shown and inert | "查看未读" shown and inert | Hidden when unwired | **Drift in the kits** (DESIGN_SYSTEM): same props, different behaviour. |
| Moments composer | Centered dialog; images allowed; audience inline | Sheet; text only; audience as overlay | Full-screen route with the nav visible; text only; audience in a bottom sheet | **Idiom:** presentation style. **Drift:** image support, audience presentation. |
| Moments comments and report | Comment dialog, no reply, no report | Comment sheet, no reply, 举报 text button under each card | Comment dialog with reply; report via long-press or author tap | **Drift.** The Android gesture-only report is hard to discover. |
| Moments error, paging, cover | Toast plus empty state; first 20; no avatar on cover | Raw error in empty state; blank while loading; avatar opens composer | Raw error in empty state; avatar opens composer | **Drift.** |
| Me and settings IA | 设置 tab with developer diagnostics plus 个人中心 route; two logout entries | 我: ProfilePanel, 设置 and a "FFI 契约" row; 设置 holds theme, language, privacy, account and a confirmed logout | 我: ProfilePanel and the settings list inline; logout unconfirmed | **Drift.** All three expose developer diagnostics in consumer settings (DESIGN). |
| Theme and language | System theme only; no language setting | Persisted theme; language picker with no effect on copy | In-memory theme; language row toggles with no visible effect | **Drift.** The kits ship Chinese strings only (`kios/Tokens/FlareStrings.swift:503-520`; `kand/FlareStrings.kt:2791`). |
| Privacy | Sheet with one toggle, mislabelled | Toggle in 设置 | Toggle in 我 | **Idiom:** placement. **Drift:** Android loads friend-verification mode and never shows it (`and/SocialSession.kt:1233-1246`). |
| Devices | Fake entry | Real list with confirmed revoke | Real list, unconfirmed revoke | **Drift.** |
| Blocked users | None | Push, unconfirmed unblock | Route, unconfirmed unblock | **Drift.** |
| Reports | None | Sheet; preselected reason; grouped My reports with retry | Dialog; no preselect; flat My reports without error state | **Drift.** **Idiom:** sheet against dialog. |
| QR | Sheet with raw token and copy | Sheet with 完成 | Full-screen sub-route | **Idiom:** presentation. **Drift:** the raw token. No app can scan. |
| Connection and offline | Banner from the login snapshot | Live banner, no re-login action | Live banner, no re-login action; sends blocked when kicked | **Drift.** |
| Feedback presenters | Kit toast, dialog, sheet and confirm | Kit FlareFeedback | Kit toast host, dialogs and sheets | **Converged** on kit presenters. Banners are still inserted in layout on iOS and Android, causing jumps. |
| Empty and error states | Kit error state is icon-only; many errors render as empty | Many errors render as empty; My reports and Devices have proper error states | Many errors render as empty | Systemic **drift** from the kit's `FlareViewState` contract; everything else treats failure as "no data". |


## Flutter, iOS and Android: gaps

### Flutter

**Supported by the data layer but not exposed on any screen:**

- Blocked list and unblock: `listBlocked`, `unblockUser` (`fl/sdk/base_social_client.dart:1119-1160`).
- A user's moments, moment detail and comment deletion: `loadUserMoments`, `getMoment`, `deleteMomentComment` (`:1408-1431, 1496-1497`).
- Reply to a comment: `addMomentComment(replyToCommentId:)` (`:1476-1493`; `fl/viewmodels/moments_view_model.dart:174-191`).
- Pagination: moments feed cursor (`:1393-1405`) and message history `beforeSeq` (`:743-749`).
- Delete for everyone: `deleteMessage(forEveryone:)` (`:843-852`).
- Custom greeting: `sendFriendRequest(message:)`, `joinGroup(message:)` (`:1072-1082, 1380-1386`).
- Create a group with members: `createGroup(name, memberIds)` (`:1163-1171`), but the UI passes `const []` (`fl/screens/base_shell.dart:215`).
- Resolved media URLs (`:1520-1566`) are never used for preview or playback.

**Supported by the SDK but not wrapped in the app or its Flutter SDK:**

- Verification-code login, register with code and password reset (the iOS and Android wrappers have them; `sdkfl/flare_social_sdk.dart:362-412` does not).
- Moderation: `create_report`, `list_my_reports` (`soc/ffi/ops/moderation.rs:26-31`).
- Login sessions and revoke (`soc/ffi/ops/user.rs:80-81`).
- New-device login alert events.
- Connection event handling (`sdkfl/event_code.dart:9-16` defines the codes; the app filters them out).
- Conversation pin, mute, delete, mark-unread and draft; message typing, presence and in-conversation search (`core/bindings/contract/apis.json:239, 468, 570, 641-671`).

**Dead-end controls and placeholders:**

- The 隐私与好友验证 row opens Profile Center instead of privacy (`fl/screens/base_shell.dart:734-744, 758-760`).
- Value rows in 设置 and in the Profile Center overview are tappable no-ops (`fl/screens/base_shell.dart:698-731`; `fl/screens/profile_center_screen.dart:130-155, 227-246`).
- SDK 能力 shows a fake device (`fl/screens/profile_center_screen.dart:296-305`).
- 缓存与同步 is a placeholder (`:313-330`).
- A fabricated placeholder profile with counts 8 / 3 / 1 (`fl/sdk/base_social_client.dart:389-400`).
- Announcement "查看未读" is not wired (`fl/screens/social_action_screens.dart:944`).
- Address-book "发消息" is disabled for existing friends (`fl/screens/social_action_screens.dart:373-391`).
- `onLoadContacts: () {}` (`fl/screens/social_action_screens.dart:1015`).
- Spec chips claim "WASM" (`fl/screens/auth_screen.dart:424-426`).
- The profile editor's error branch is unreachable (`fl/screens/profile_center_screen.dart:582-590`).
- Notification permission and preferences: no screen, although the kit ships `FlareNotificationPreferences`.

### iOS

**Supported by the data layer but not exposed:**

- Delete for everyone: `deleteMessage(forEveryone:)` (`ios/SocialSession.swift:1557-1561`).
- The "mentions only" notify level via `setMyGroupNotifyMode` (`:1408-1411`); the comment at `:1414` says "暂无入口".
- Moments pagination with `loadFeed(reset: false)` (`ios/MomentsViewModel.swift:40-56`) and comment replies with `comment(replyToCommentId:)` (`:102-117`).
- Reporting a message or a comment: `createReport(conversationId:)` and those target kinds exist (`ios/SocialSession.swift:1702-1716, 1781-1793`).
- Custom greeting: `sendFriendRequest(message:)`, `joinGroup(message:)` (`:566, 683`).
- Image moments: the kit supports images and the upload pipeline exists (`:834-839`), but the composer sets `maxImages: 0` (`ios/MomentsView.swift:151-152`).

**Supported by the kit but not wired:**

- `ComposerView` `text:` and `replyTo:` for drafts and reply (`kios/Components/ComposerView.swift:80-84`).
- `MessageListView` `onMediaAction`, `onResend`, `hasOlder` / `onLoadOlder` (`kios/Components/MessageListView.swift:64-80`).
- `ConversationListView` `onLongPress` (`kios/Components/ConversationListView.swift:23`).
- `MomentCardView` `onOpenImage` (`kios/Components/MomentViews.swift:418-431`).
- `ContactMatchListView` `onOpenConversation`.

**Supported by the SDK but not wrapped:**

- Session restore ops (`soc/ffi/ops/auth.rs:60-84`).
- Message history `beforeSeq` paging (the core accepts it; the app sends 0).
- Conversation pin, mute and delete; typing; presence (as for Flutter).
- Join a group by invite code: `join_group_by_invite` (`soc/ffi/ops/group.rs:239`). Group detail generates a code that nobody can use.
- Add a friend by QR: `add_friend_by_qr` (`soc/ffi/ops/relation.rs:220`).
- Change password (`soc/ffi/ops/user.rs:74`).

**Dead-end controls and placeholders:**

- Canned demo attach actions (`ios/SocialSession.swift:800-819`).
- Join-group results always show "0 人" (`ios/FriendActionViews.swift:271, 302`).
- Kicked and expired banners have no action (`ios/FlareSocialRootView.swift:62-65`).
- The English option does not change copy (`ios/SettingsViews.swift:26-32`).
- Announcement "查看未读" is not wired (`ios/GroupViews.swift:145-150`).
- Address-book "发消息" does nothing (`ios/FriendActionViews.swift:201-204`).
- The "FFI 契约" row on 我 (`ios/MainShell.swift:236-238`).
- `privacyKnown` is never read (`ios/SettingsViews.swift:46, 101`).
- The "加载中…" moments title is unreachable (`ios/MomentsView.swift:37-39`).
- `VoiceRecorder.swift` is dead code with zero references.
- The autologin hook embeds QA credentials (`ios/FlareSocialRootView.swift:35-39`).

### Android

**Supported by the data layer but not exposed:**

- Friend-verification mode and profile visibility: `setFriendVerifyMode`, `PrivacyState.friendVerifyMode`, `profileVisibility` (`and/SocialSession.kt:231, 1233-1246`).
- Moments pagination with `loadMore` and `hasMore` (`and/MomentsViewModel.kt:62-67, 184`).
- Login-alert history: `lastLoginAlert` is stored but only toasted (`and/SocialSession.kt:304, 541-544`).
- Reporting a message or a comment: `createReport(conversationId)` and those target kinds exist (`and/SocialSession.kt:1180-1192`; `and/ReportSheet.kt:47-54`).
- Custom greeting: `sendFriendRequest(message)`, `joinGroup(message)` (`and/SocialSession.kt:632, 754`).
- Persisted drafts: drafts are memory-only, although the core has `conversation.update_draft`.

**Supported by the kit but not wired:**

- `MessageList` `onMediaAction`, `onResend`, `hasOlder` / `onLoadOlder` (`kand/MessageList.kt:81-98`).
- `ConversationList` `onLongPress` (`kand/ConversationList.kt:33`).
- `ContactMatchList` `onOpenConversation` (`kand/VisibilityAndMatch.kt:195`).
- `MomentCard` `onOpenImage`.

**Supported by the SDK but not wrapped:** session restore, invite-code join, add friend by QR, change password, conversation management, typing, presence (as for iOS).

**Dead-end controls and placeholders:**

- Global search contact hits (`and/FlareSocialApp.kt:617-618`).
- Group "发消息" when no local conversation exists (`:584-589`).
- The language row that toggles with no visible effect (`and/SettingsScreen.kt:159`).
- The hard-coded emulator social gateway (`and/MainActivity.kt:28`), which makes physical devices depend on an unreachable host.
- The "WASM" spec strip (`and/FlareSocialApp.kt:530`).
- Canned demo attach actions (`and/SocialSession.kt:852-868`).
- `VoiceRecorder.kt` is dead code with zero references.
- Autologin QA credentials triggerable by intent extras on the exported activity (`and/FlareSocialApp.kt:76-78`; `and/MainActivity.kt:32-36`).
