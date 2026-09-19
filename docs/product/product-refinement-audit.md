# Product Refinement Audit

Date: 2026-09-15. Round 5 of the reference-app program, phase 1 (audit). Scope: the five flare-social reference apps and the four kits of flare-im-design, judged as complete IM products rather than as component consumers.

Evidence:

- **Running golden app.** The web app runs unchanged on an in-memory fixture core that replaces the wasm social core at its module boundary (`flare-social-web-app/tests/app-visual`; no app source changes, no backend, no sign-in). 29 review captures at 1440, 1280, 1024, 834, 768, 600, 390 and 320 px, light and dark, seven data scenarios (default, empty, error, offline, send failure, long content, 1000 conversations). Regenerate with `CAPTURE_DIR=<dir> npx playwright test -c tests/app-visual/playwright.config.ts review-capture`. Fixture data is for review only; it is not evidence that a feature works against the real core.
- **Static audits** of every screen in the five apps (`screen-inventory.md`), the icon systems of four kits and five apps (`../design/icon-inventory.md`), and integration friction per app (section 6).
- **Prior state.** Rounds 0 to 4 (`final-app-design-report.md`): 150 components, 37 gates, all P0 and P1 friction entries of those rounds fixed, 23 P2 open.

## 1. Where Round 5 starts

The kit holds its contracts, and the apps compile and pass their tests. As products they are uneven:

- **Web (golden).** The core loop reads well on desktop. The findings are responsive gaps, missing everyday operations (forward, multi-select, download, typing) and failures that show as empty lists.
- **Tauri.** It has the widest feature set, but it showed read messages as failed (fixed in R5.0) and it calls three IPC commands the binding does not route.
- **Native apps.** They have kit presenters and headers since Round 3, but they lack core IM functions:
  - received media cannot be opened;
  - there are no conversation actions and no history paging;
  - iOS and Android do not stay signed in.
- **Kit.** The components compose well, but the icon system is a registry the components mostly bypass, and the Flutter and SwiftUI kits have dozens of icon-only controls without a name.

Golden app: **web** (unchanged). Second reference app: **iOS** (unchanged). SwiftUI differs most from the Vue kit in idiom (system menus, sheets, navigation), so it tests the cross-platform contracts best. Flutter and Android stay parity apps.

## 2. frontend-design PASS 1: golden app (navigation, conversation list, chat)

Brief: a knowledge worker in a Chinese team IM on desktop all day and on a phone in between. The page's job is to read and answer conversations fast. Secondary tasks: find a conversation or message, manage a group, check a contact.

### Scores (1 to 10)

| Dimension | Round 4 | PASS 1 | Why it moved |
|---|---:|---:|---|
| Product fit | 7 | 7 | |
| Task clarity | 8 | 7 | Unhighlighted mentions; the empty inbox offers no action; search is a full-screen takeover on desktop |
| Information architecture | 7 | 6 | Contacts, moments and me are single full-width columns on desktop |
| Hierarchy | 8 | 7 | Separator pills compete with messages; the settings row squeezes labels |
| Layout | 7 | 6 | 600 to 767 px leaves the chat about 210 px wide; no width constraints on desktop pages |
| Typography | 7 | 7 | |
| Color | 7 | 7 | Dark avatar fallbacks glare |
| Spacing and density | 7 | 6 | Pill inflation (times, system notices, "no more messages") |
| Component consistency | 8 | 7 | One concept, several glyphs (reply, forward, error, mute) |
| State completeness | 7 | 6 | Offline composer stays live; failed sends do not reach the row; group detail renders nothing while loading |
| Responsive behavior | 8 | 5 | The fixture exposed the 600 to 767 band and the 1000-row list (P0) |
| Accessibility | 9 | 7 | The avatar picker was unreachable (P0, fixed); three hover-toolbar tab stops per message |
| Product character | 6 | 6 | |
| Anti-template restraint | 8 | 7 | Saturated hero on the me tab; gradient cover on moments |
| Implementation consistency | 8 | 7 | Icons bypass the registry |

Round 4 scores were code and harness evidence. PASS 1 is the first review of the running composition at every breakpoint; the drop is new evidence, not a regression.

### Findings

| ID | Pri | Class | Problem | User impact | Evidence | Change |
|---|---|---|---|---|---|---|
| G1 | P0 | DESIGN_SYSTEM | Conversation list virtualization: the window spacers are shrinkable flex items, so the bottom spacer (70560 px) renders 0 px | With 200 or more conversations, rows after about #37 cannot be reached | scale fixture: scroll height 1440 instead of 72000 | Fixed in R5.0 |
| G2 | P1 | DESIGN_SYSTEM | Row timestamps ellipsize: "2025/12/31" shows as "2025/12/…" | Older conversations lose their date | captures 14, 15, 17 | Time column sized to its content; older-year format fits |
| G3 | P1 | DESIGN_SYSTEM | Mentions render as plain text in bubbles on Vue, Flutter and SwiftUI | "@林夏" and "@所有人" do not stand out, although being mentioned is the strongest group signal | captures 02, 05 | Mention entities highlighted in text bodies on four kits |
| G4 | P1 | DESIGN_SYSTEM | Time separators every 5 minutes plus a time in every bubble; an unread divider stacked on a time pill; the first loaded message has no date | Noise between messages; missing context at the top | captures 02, 04 | One separator rule: date changes and long gaps; the first row always dated; the divider absorbs the separator |
| G5 | P1 | DESIGN_SYSTEM | 600 to 767 px keeps a 72 px rail and a 320 px list | The chat is about 210 px wide; titles show 1 character, bubbles 4 per line | capture 16 | Single pane below a usable chat width; the detail fit check uses the rail width. Round 5: the fit check measures the rail (R5.1); the single pane moves to FR-095 because it needs shell-derived back visibility on four kits |
| G6 | P1 | APP | The messages tab badge counts muted conversations (32 includes 23 muted) | The badge overstates what needs attention | captures 01, 17 | Exclude muted unread from the total |
| G7 | P1 | DESIGN_SYSTEM | A settings row with a long value squeezes the label to one character per line | The group announcement row is unreadable | capture 06 | Long values wrap under the label |
| G8 | P1 | DESIGN_SYSTEM | Member grid names clip at the panel edge | Long nicknames overflow | capture 06 | Ellipsis within the cell |
| G9 | P1 | DESIGN_SYSTEM | Avatar fallbacks keep light pastel grounds in dark mode | Glare in dark lists and headers | captures 03, 19, 28 | Dark avatar fallback tokens |
| G10 | P1 | APP + DESIGN | Global search on desktop is a full-screen takeover with a 1340 px input, no recent searches and no grouping | Search feels like leaving the app | capture 09 | A centered search panel on desktop (kit command palette), grouped results, recent searches |
| G11 | P1 | APP + DESIGN | Contacts, moments and me render as one full-width column on desktop | 1360 px rows and cards are hard to scan; no list-detail | captures 10, 11, 12 | List and detail panes on desktop; reading width for content pages |
| G12 | P1 | DESIGN_SYSTEM | The contact index puts every Chinese name under "#" (FR-044) | The index encodes nothing | capture 10 | Pinyin initials |
| G13 | P1 | DESIGN_SYSTEM | Icons: reply is a speech bubble in the hover toolbar and an arrow in the menu; clear history and delete share the trash glyph | The same action looks different; two different actions look the same | captures 07, 08 | Semantic icon system (R5.12) |
| G14 | P1 | DESIGN_SYSTEM | The empty inbox has no action, and the content pane still says "choose a conversation on the left" | A new user has nowhere to go | captures 23, 24 | Empty inbox with a start-chat action; the content pane follows the list state |
| G15 | P1 | SDK + APP | A failed send never reaches the conversation row | A failure is invisible from the list | capture 27 | Row `failed` state (kit ready) once the core projects send state (SDK gap S3) |
| G16 | P1 | DESIGN_SYSTEM | Every message puts three hover-toolbar buttons in the tab order | Keyboard users tab through three stops per message | DOM probe | Roving focus in the timeline; the toolbar reachable from the focused message |
| G17 | P1 | DESIGN_SYSTEM | The profile editor's avatar picker was a clickable `div` | Unreachable by keyboard and screen reader | code | Fixed in R5.0 |
| G18 | P2 HIGH | DESIGN_SYSTEM | The me tab has a saturated full-width hero and the moments tab a gradient cover | Decoration outranks content | captures 11, 12 | Quiet profile header; cover limited to its content |
| G19 | P2 MEDIUM | DESIGN_SYSTEM | Time, system notice, recall notice and "no more messages" are all bordered pills | Pill inflation | captures 02, 04 | Text separators; pills only for system notices |
| G20 | P2 MEDIUM | DESIGN_SYSTEM | A failed bubble turns all its text red on pink | Alarm is louder than recovery | capture 27 | A normal bubble with an error mark and retry. Round 5: deferred as a four-kit change: the natives already draw a normal bubble with the failed glyph and retry in the meta row, but a red glyph on an outgoing bubble fails contrast, so the mark has to move beside the bubble on all four kits together |
| G21 | P2 MEDIUM | APP | The offline composer stays fully enabled with no hint | Users type into a state that cannot send | capture 26 | Composer hint while offline; sends queue or fail visibly. Round 5: covered by the kit connection notice (网络不可用，恢复后会自动重连 above the shell) and the core's pending send queue; no separate composer hint |

## 3. Cross-app findings

From `screen-inventory.md` (static) and verified in code where marked. Class and priority follow the program rules.

### P0

| ID | App | Class | Problem | Status |
|---|---|---|---|---|
| X1 | Tauri | APP | Read receipts wrote proto status 4 (FAILED), so messages the peer read showed failed with a resend button; a failed send ack wrote 5 (RECALLED) and looked sent. Verified in code | Fixed in R5.0 |
| X2 | Android | APP | "发消息" from a contact or group under 通讯录 hid the navigation and never showed the chat, a dead end on phones. Verified | Fixed in R5.0 |
| X3 | Flutter | APP | Group chats used the conversation id as the group id, so group details, the mention roster and group "发消息" targeted the wrong entity. Verified | Fixed in R5.0 |
| X4 | Flutter | APP | Group roles were mis-mapped: members counted as admins, and demoting wrote the Owner role. Verified | Fixed in R5.0 |
| X5 | Flutter, iOS, Android | APP + DESIGN_SYSTEM | Received images, voice, video and files cannot be opened or played; no app passes the media action and no native kit has a default preview | Open (R5.6) |
| X6 | Flutter, SwiftUI, Compose kits | DESIGN_SYSTEM | Icon-only controls without an accessible name: Flutter 27, SwiftUI 29, Compose 11 (voice send and cancel, image preview close and download, exit multi-select, the whole iOS composer toolbar) | Open (R5.11 and R5.12) |
| X26 | Tauri | APP | Received images, videos, voice and files never load: the host media resolver and the preview and download paths use `media.resolve_access`'s source kind (the string "remote" or "local") as the address. Verified in code | Fixed after the re-grade (2026-09-16): both paths resolve through the app's own access-url reader |
| X27 | Flutter, SwiftUI, Compose kits | DESIGN_SYSTEM | The timeline opens at the oldest loaded message and does not follow new messages: Compose scrolled to item 0 on open, SwiftUI's scroll position started at the top, and the Flutter kit pivoted on the first message (the Flutter app compensated with its own tail logic; the iOS and Android apps did not). Verified in code | Fixed in Batch 6 on all three kits, with the Vue contract (open at the newest message, follow while at the bottom or when the message is the reader's own, keep the position and count while scrolled up, keep the anchor when older pages arrive); the Flutter app's copy of the logic was deleted. Tests: Compose 7 unit + 3 instrumented (compile-only), Flutter 20 + 7 repaired, SwiftUI in `TimelineFollowTests` (12 failing assertions from the interrupted run repaired) |

### P1

| ID | Apps | Class | Problem |
|---|---|---|---|
| X7 | all | APP | Failed writes show as success or as empty data: contacts, groups, requests and reports load failures become empty lists; leave, remove, block, accept and save failures close the dialog as if done |
| X8 | web, Tauri | APP | Session endings are dead ends: kicked and expired banners offer no way back; an offline cold start deletes the stored web session; Tauri ignores kicked and expired |
| X9 | Tauri | SDK + APP | Rich-text send, call invite and presence batch call IPC commands the binding does not route: format mode always errors, call buttons always error, headers read offline |
| X10 | web | APP | Forward, multi-select, message pin, file download, typing and presence are supported by kit and core but not wired; drafts and failed-send text are lost |
| X11 | iOS, Android | APP + SDK | No persistent login; Flutter deletes the session when a restore fails |
| X12 | Flutter | SDK + APP | No code login or password reset, and sign-up sends no verification code (likely fails) |
| X13 | natives | APP | History capped at the latest 50 messages; moments never paginate |
| X14 | natives | APP | Read state is sent without a visibility check (background on Flutter, hidden split panes on iOS) |
| X15 | natives | APP | No conversation actions (pin, mute, delete, mark unread); mentions do not work end to end |
| X16 | iOS, Android | APP | Demo payloads ship as real composer actions: 位置 sends a fixed location, 投票 a fixed poll |
| X17 | iOS | APP | Add-friend search only searches existing friends; join group shows "0 人" for every group |
| X18 | web | APP | 1:1 chat details show a raw user id and friend-only actions for strangers; "发消息" on a matched contact creates a pseudo group |
| X19 | Tauri, web | APP | Destructive actions without confirmation: Tauri removes or blocks a friend in one click; web signs out without confirmation; Tauri offers owners 退出群组 |
| X20 | all | APP + DESIGN_SYSTEM | Mixed languages: web auth is English, Android auth is English, Flutter mixes both; kit literals in English (FR-049); iOS "English" changes nothing |
| X21 | all | APP | Dead controls and settings: notification preferences do nothing (web, Tauri); fake device lists (Tauri, Flutter); web 我 › 朋友圈 does nothing; web invite codes cannot be redeemed |
| X22 | web, Tauri | APP | Internal information in the product UI: endpoints, raw ids, tokens, `#seq`, start-script hints, raw error strings |
| X23 | kits | DESIGN_SYSTEM | Settings rows are all buttons (read-only rows look actionable, value rows have no chevron); ContactDetail renders disabled call buttons and friend-only actions regardless of relationship; GroupDetail renders nothing while loading and its 群成员 row is inert; phone sheet titles are 13 px tertiary text |
| X24 | Tauri | APP | "Load older" never ends; pinned and search jumps fail outside the loaded page; group management actions eject to the address book |
| X25 | web | APP | Browser and system back never close a chat, detail or sheet on phones; switching tabs unmounts sub-pages |
| X28 | Tauri | APP | Message pin omits the `scope` the core requires, so every pin fails; the send ack is read as `serverMsgId` while the core sends `serverId`; the composer never asks for the expanded toolbar, so format mode cannot be reached. Fixed after the re-grade |
| X29 | web | APP | Older history comes only from the core's local store: the app never calls `sync.conversation_history_backfill`, so a fresh device stops at whatever was synced, and a failed page only toasted. Fixed after the re-grade |
| X30 | iOS | APP | Forward, reaction and image-upload failures are swallowed; global search parses the array replies of `search_contacts` and `search_groups` as envelopes and drops them; no 重新连接 although `connection.notify_network_change` is reachable; the announcement's 查看未读 link has no handler; the stranger-message switch shows "on" before it loads |
| X31 | Android | APP | The Activity-scoped moments view model survives sign-out, so the next account sees the previous account's feed; a failed image upload is silent; search, privacy and invite-link reads fail silently |
| X32 | Flutter | APP | Group mute never saves (the app writes `muted`, which `update_my_group_settings` ignores since it takes `notifyMode`); a denied gallery permission throws unhandled; the connection and session-end notice shows only above the shell tabs, not in a pushed chat or the moments tab |
| X33 | kits | DESIGN_SYSTEM | Copy is offered on messages with no copyable text (the core's availability says so); text links in bubbles reach no handler on SwiftUI and Compose; the Compose mention picker writes `@全体成员`, which the core does not parse as mention-all; Vue business cards draw a 查看详情 button nobody handles and the mini-program card prints its app id and page path; Vue group settings that failed to load read as "off" |

## 4. Icon system

Full inventory, coverage and rules: `../design/icon-inventory.md`, `../design/icon-coverage.md`, `../design/icon-guidelines.md`. The main problems:

- **The registry is bypassed.** It holds 61 names, identical on four kits, but components draw 1203 glyphs around it (Vue 237, Flutter 335, SwiftUI 322, Compose 309). Public APIs take platform glyph types, which pushes apps onto Material and SF Symbols directly.
- **Unnamed controls.** Flutter has 27 icon-only controls without a name, SwiftUI 29 and Compose 11 (X6).
- **Wrong meanings.**
  - recall draws the reply arrow and unpin the pin;
  - hang up is a rotated phone, remove member is logout and transfer owner is a star;
  - error is a cancel circle;
  - iOS `location` is the current-position arrow and Vue `poll` is a ballot box.
- **Coverage.** 129 IM concepts checked: 38 exist, 13 exist under another name, 39 will be added because something draws them today, and the rest are not added because nothing draws them.
- **Sizes and Unicode.** The four token sizes are mostly ignored (17 to 19 literal sizes per native kit). 20 Unicode characters are used as control icons (`×`, `←`, `★`, `🔍`, `•`).

## 5. P2 re-triage

The 23 open P2 friction entries were checked again in code; none is obsolete.

| Value | Entries | Round |
|---|---|---|
| HIGH | FR-044 CJK contact index · FR-049 kit English literals · FR-036 emoji and sticker asset root breaks sub-path deploys · FR-043 SearchPanel not composed from kit parts · FR-047 native apps cannot change the avatar | R5.7, R5.13, R5.3, R5.5, R5.9 |
| MEDIUM | FR-037 list re-sorts pinned first (fixed in R5.0) · FR-040 responsive mode composable · FR-042 danger confirm on phones · FR-053 composer pickers through the platform adapter · FR-057 list container stale state · FR-034 message batch toolbar API · FR-035 typing state on programmatic changes · FR-038 Flutter list refresh and contact empty state · FR-039 Flutter avatar tap target · FR-045 input reveal toggle · FR-046 contact detail extra actions · FR-048 BrandLogo not adopted · FR-051 typography roles · FR-050 density promise | R5.1 to R5.13 |
| LOW | FR-041 native shell composition · FR-052 redundant Compose MaterialTheme · FR-056 conversation kind vocabulary · FR-067 toast accepts an error value | not planned |

## 6. Integration friction

Full table: `design-system-escape-hatches.md` section 3b. The kit-reference gate reads zero on every count, and those zeros hold: no naive-ui, no deep imports, no visual literals. What the gate does not see:

- **Behaviour rebuilt from kit parts** (lines involved): web 679, Tauri 2,922, Flutter 1,149, iOS 728, Android 886. That covers prompt sheets, host-held confirm state, native message-menu orchestration, connection banners and responsive state machines.
- **Glue code:** web 2,933 lines, Tauri 11,829, Flutter 2,818, iOS 2,069, Android 2,404. The three native apps each keep their own core data adapter.
- **DOM hacks:** web 4, Tauri 25 (15 of them dead code).
- **Selectors into kit internals:** web 1, Tauri 3, plus 4 `:deep` in Tauri.

The kit changes with the largest payoff are FR-092 (prompt and confirm presenters, about 630 app lines), FR-093 (native data adapter, about 980), FR-094 (native message menu and reaction direction, about 250), FR-095 (shell measures and derives, about 160) and FR-096 (connection banner, about 160).

## 7. SDK gaps

The kit shows each of these states when the SDK provides them. No app fakes them.

| ID | Gap | Owner | Impact | UI fallback today | Blocks a complete app | Kit ready |
|---|---|---|---|---|---|---|
| S1 | @me mention counts on conversation summaries | IM core | Groups that mention the user look like any unread group | None; rows show plain unread | Yes, for group-heavy use | Yes: row `mentioned` and mention tag |
| S2 | Resend operation | IM core | Apps re-send a stored message themselves | Web re-sends the stored row; natives offer nothing | Partly | Yes: failed status with retry |
| S3 | Presentational send state (sending, sent, delivered, read, failed) | IM core | Each app projects proto status itself; Tauri got it wrong (X1) | App mappers | No, but a recurring defect source | Yes: MessageStatus |
| S4 | Group member search | Social SDK | Large groups cannot be searched | Filter over loaded members (200) | For large groups | Yes: member panel search |
| S5 | Transfer progress events | IM core | No progress for large uploads or downloads | Indeterminate uploading state | No | Yes: TransferProgress |
| S6 | Stable reaction order | IM core | Reaction pills reorder between loads | None | No | Yes: renders the given order |
| S7 | Tauri binding routes for rich-text send, call invite, presence batch | SDK (Tauri binding) | X9. Round 5: presence batch and rich-doc normalise and create are reachable through `sdk_invoke_json` direct routes, but `bindings/contract/apis.json` still names typed Tauri commands the binding never registers (`sdk_batch_get_user_presence`, `sdk_rich_doc_v2_*`, `sdk_rtc_*`); there is no call invite for this binding; `sdkPathExists` and `sdkMediaUpload*` are also unregistered | Call entry points removed; presence and rich text use the direct routes | For calls | Yes |
| S8 | IM-only session restore in the Swift and Kotlin wrappers | SDK (Apple, Android) | X11: sign in on every launch | None | Yes, for iOS and Android | n/a |
| S9 | Verification-code login, registration and password reset in the Flutter SDK | Social SDK (Flutter) | X12 | None | Yes, for Flutter onboarding | n/a |
| S10 | Typed write results on native wrappers | SDK (wrappers) | Apps cannot tell failure from success (part of X7) | App-side error handling | No | Yes: confirm with error and retry |
| S11 | One source for a member's group pin and notification mode | Social server + IM core | Group settings (`update_my_group_settings`) are projected onto the IM conversation participant (`flare-group` `handle_update_my_group_settings`), but conversation rows pin and mute through `conversation.set_pinned` / `set_muted`; no projection back to the group settings was found, so pinning a group from the list can leave 置顶该群 off in group details | Web group details read and write the group settings and now report failed writes; the fixture mirrors the server projection | No, but toggles can disagree | Yes: both surfaces render the state they are given |
| S12 | Media URLs that stay valid for an open chat | IM core | `media.get_url` returns URLs that expire after an hour and has no batch form; apps resolve each media id before mapping (Flutter serially), and a chat left open past expiry shows failed media until messages reload | Apps cache resolved URLs for 50 minutes; players show a retry state | No, but long sessions degrade | Yes: preview and players show loading, failed and retry |
| S13 | Voice duration on send | IM core (`message_builder.create_audio`) | The builder takes no duration, so voice sent from Android has duration 0 and bubbles show 语音 until played | Bubbles count up while playing | No | Yes: voice bubbles show duration when given |
| S14 | Mentions by display name reach the message | IM core (`message_builder`) | `create_text` resolves `@<display name>` to user ids against the conversation roster (`src/client/api/message_build.rs:187-207`, `content/mention.rs` `parse_mentions`), but `build_text` keeps a mention only where the literal `@<userId>` appears (`src/application/services/message_builder.rs:137, 708-726`), so a member picked by name gets neither a mention span nor an entry in `mention_users`: no highlight and no @me for them; only @全员 works. Every kit composer inserts the display name, so mentions do not work end to end on any client | None possible in apps | Yes: group mentions | Yes: highlights and @me render once spans arrive |
| S15 | Poll selection mode on send | IM core (`message_builder.create_vote`) | No single or multiple choice field, so the kit poll composer's choice cannot be sent (iOS sends question and options only; Android removed the poll action) | Apps send single-choice polls or none | No | Yes: poll composer |
| S16 | A named reconnect on the native wrappers | SDK (Swift wrapper) | The wrapper exposes no reconnect method, but its generic dispatch reaches `connection.notify_network_change`, which reconnects the current session: Round 5 wires the iOS app to it, so this is a wrapper ergonomics gap, not a blocker | Notice without a reconnect action | No | Yes: connection notice with `canReconnect` |
| S17 | End of history from `message.list` | IM core | `message.list` returns no `has_more`, so apps infer the end from an empty page after a backfill; `open_timeline` / `load_older` return it but are not on the C dispatch | Apps stop on an empty page or seq 1 | No | Yes: load-older states |
| S18 | Product-safe auth warnings | SDK (Tauri binding) | The auth `warning` string carries a start-script path and ports (`commands/social.rs:35-42`) | The app no longer shows it | No | n/a |
| S19 | Rich-doc send request shape documented for apps | IM core contract | `message_builder.create_rich_doc` requires `docJson`, `contentSchema` and `plainText`; only the smoke runtime accepted `markdown`, and four apps shipped the `markdown` form, which fails on the real core | Apps normalise with `rich_doc_v2.normalize_from_markdown` first (Round 5) | No | n/a |
| S20 | Pinned messages of a conversation | IM core | No op lists a conversation's pinned messages, and pin, unpin and mark events are registered but have no case in `sdk_event_payload` (`bindings/shared/src/event.rs`), so the pinned bar lists only pinned messages that are loaded and other members' pins arrive only with a reload; the local pin update has no scope | Pinned bar from loaded messages; 仅自己置顶 hidden on web | No | Yes: PinnedMessageBar |
| S21 | Presence lookups on web | IM core (web presence) | A failed lookup reports offline and `presence.subscribe` only records ids | Web shows no presence for failed lookups | No | Yes: header presence |
| S22 | Copy availability on messages without text | IM core | `message.action_availability` sets `canCopy` from `text_for_storage()`, which returns a preview-token JSON for image, voice and file messages (`src/domain/message_actions.rs:82-85`, `src/content/preview_storage.rs:57-66`), so every kit that trusts the core offers 复制 on media: Android copied nothing, Flutter copied an empty string | The kits offer Copy only for messages with copyable text (Round 5) | No | Yes: the sheet hides what the message cannot do |
| S23 | `create_quote` needs `quotedContent`, and the contract says it is optional | IM core | `bindings/contract/dispatch.json` marks `quoted_content` `optional_built_content`, but `MessageBuilderService::build_quote` (`src/application/services/message_builder.rs:171-176`) returns `InvalidParameter / missing_quoted_content` without it. A client that reads the contract builds a reply the core always refuses — and only against a real backend, which is how it survived four rounds here: the TypeScript SDK's `createQuote` sent three fields, so **every reply from the web app would have failed**, and the Tauri app sent a `quotedMessage` field the dispatch does not read. Round 6 fixed both clients (the TS wrapper now takes the quoted message, the Tauri payload sends `quotedContent` and `quotedSenderId`) and made the web fixture refuse the request the way the core does. The core still owes either a required field in the contract or a build that does not need it | Reply fails with a send error; nothing is queued | No (clients can pass it) | Yes: the quote renders from the content the sender supplies |
| S24 | The Apple and Flutter SDK facades have no `createQuote` | SDK (platform wrappers) | `FlareMessageModule` (Apple) and its Dart counterpart expose `createText`, `createSticker`, `createMedia` and so on, but nothing for a reply, so the iOS and Flutter apps dispatch `message_builder.create_quote` through the generic path. The capability is reachable — this is wrapper ergonomics, the same class as S16 — but every app then owns the request shape, which is how the TypeScript wrapper's three-field version (S23) went unnoticed for four rounds. The TypeScript wrapper now takes the quoted message and cannot build an invalid request; the other two wrappers should follow | The apps build the request themselves | No (the op is reachable) | Yes: the kit computes the summary either way |
| S25 | Markdown tables, underline, images and links survive rich-text normalisation | IM core (`rich_doc_v2::from_markdown`) | A table becomes an empty `custom_block` (`markdown_table`), inline `<u>` from the Vue composer is dropped an image keeps only its alt text, autolinked, email and reference links lose their words (Round 10 measured), and an unsafe inline link fails the whole normalisation, so the stored document — which all four kits draw since R9-B6 — and its `plain_text` no longer hold them; before B6 the Vue kit drew the sender's Markdown and showed them | None: the body draws what the document holds | No | Partly: `custom_block` children are drawn; a table block would need a kit body Proposal and patch with tests: `sdk-change-proposals.md` §1 (Round 10) |
| S26 | Acting on a poll or a task | IM core (`message_builder`) | The contract has builders only (`create_vote`, `create_task`, `create_schedule`): no op casts a vote or reads who voted, and none changes a task's status or assignee (`bindings/contract/dispatch.json`), so the vote and task-toggle intents all four kits report since R9-B8 have nowhere to go | Apps pass no handler; polls and tasks stay read-only | No | Yes: `vote` and `taskToggle` on the timeline (R9-B8) Design: `sdk-change-proposals.md` §2 (Round 10) |
| S27 | A tight Markdown list normalises | IM core (`rich_doc_v2::from_markdown`) | Any list whose items are not separated by blank lines — `- 苹果\n- 梨`, `1. 第一步`, a single `- 一项`, and exactly what the Vue composer's list shortcuts and the SwiftUI composer's bullet format write — fails with `unclosed list item`: `next_block` consumes the item's text and then its end tag, so the rich send fails on every client. Measured in Round 10 on byte-identical copies of the SDK files; the SDK's Markdown tests cover only `hello` | Apps return the text to the composer with the send error | Yes: lists are basic rich text | Yes: the kit draws lists. Proposal and patch with tests: `sdk-change-proposals.md` §1 |

## 8. Fixed during the audit (R5.0)

| Item | Change | Verification |
|---|---|---|
| G1 | Vue list spacers no longer shrink; list renders host order (FR-037); Flutter list renders host order | Vue kit tests +2; web fixture test reaches row 1000 by keyboard and fails when the fix is removed |
| G17 | Profile editor avatar picker is a named button; labels wired through FormField; kit buttons | Kit tests +2 |
| X1 | Tauri read state rides on `isRead`; failed acks write FAILED with the local failed flag | `vue-tsc` 0; message order and session title checks pass |
| X2 | Android opens chats on the 消息 tab from 通讯录 and group detail; contact search hits resolve the 1:1 conversation | `compileDebugKotlin` succeeds |
| X3, X4 | Flutter conversations carry their group id; group "发消息" resolves the group conversation through the core; roles 2 admin, 3 member | `flutter analyze` 0 issues; app tests 28 pass (+2); lockfile unchanged |
| Test environment | Website visual tests launch Chromium with classic scrollers on macOS (process argument domain only), so `scrollbar-gutter: stable` renders the same with or without a mouse | The reference-app screenshot passes against the unchanged baseline |

## 8b. Landed after the audit (Batch 1 to Batch 4: four kits, web, Tauri and the native apps)

This table lists only what is implemented and verified. Nothing in it was run against a backend; signed-in checks are in the final report's External Validation Steps.

| Item | Change | Verification |
|---|---|---|
| R5.12 prerequisite (Batch 1) | 99 icon names in one order on four kits; wrong meanings fixed; every kit icon-only control named (Flutter 27, SwiftUI 29, Compose 11) with 44 pt / 48 dp targets; Tauri vendor glyph imports removed | `tooling/check-icon-registry.mjs` in `npm run check`; kit tests Vue 664, Flutter 715, SwiftUI 336, Compose 236; app gate counter `vendorGlyphImport` 0 |
| G2, FR-081 | Conversation row time column fits a full date | 63 px measured in the web app |
| G3, G4 (Vue) | Mention spans highlighted; date separators only at the first message and day changes, unread divider after the date | `textMentions.test.ts`, `timeline-label.test.ts` |
| G6, G14 | Tab badge excludes muted conversations; empty inbox offers 发起聊天 with one call to action | Web app, fixture scenario `empty` |
| FR-036 | Emoji and sticker files resolve under a deployment sub-path (`assetBaseUrl`, shared Vite plugin) | The emoji panel loads `image/webp` in the web app; web, Tauri and website builds copy the files |
| FR-035, FR-105 | Typing is reported only for the user's own edits; reply and edit put the caret in the input | `EnhancedComposer.test.ts`, reverse-validated |
| FR-103 | "@", a few letters and Enter mentions the highlighted person; IME Enter ignored | `FlareMentionPicker.test.ts`; web app |
| FR-049 (Vue) | English literals in Chinese UI localized (emoji panel, format strip and inserted samples, rich-editor chips, media actions, sticker fallback, contact list, filter tabs, profile panel, mini-program card); missing catalog keys added with a completeness test (FR-109) | `messages.keys.test.ts`, `EmojiStickerPicker.test.ts` |
| FR-107 | Timeline mount regression from 1,153 ms to 7.2 s fixed (lazy message menus, cached formatters): 704 ms, 23 nodes per row | `performance-budget.spec.ts` passes; the Round 3 and 4 website commands had excluded `@perf` |
| FR-043, FR-108, G10 (part) | Search panel composed from kit search bar and filter tabs, searches as you type (IME-safe), keeps results while the next query runs; search fields focus when opened; web global search closes on Escape | `FlareSearchPanel.test.ts`; web app |
| FR-044 (Vue), G12 | Chinese contact names indexed by pinyin initial without a dependency; scoped jumps; named index buttons | `contactIndex.test.ts`; web 通讯录 |
| FR-084 (part), G7 | Long settings values wrap under the label | `FlareSettingsRow.test.ts`; group announcement in the web app |
| FR-089 (part) | Group detail previews 20 member cells; 群成员 opens a searchable list of everyone | `FlareGroupDetail.test.ts`; web app |
| Header | A More button with one overflow action performs it (group chats no longer open a one-item menu) | `ConversationHeader.test.ts` |
| FR-104 (Vue) | Call device toggles are switches named by the device; the dock's main button says 返回通话 | `FlareCallControls.test.ts` |
| FR-096 (Vue, web), X8 (web) | Kit connection notice with copy and recovery; kicked and expired offer 重新登录, which clears the local session even when logout fails | `connectionNotice.test.ts`; fixture `im://kicked_off` |
| FR-048, X20 (web) | Web sign-in in Chinese product copy with the kit brand logo; Tauri brand column without inert rows or engine jargon | Web app; `auth-shell.spec.ts` selectors updated (not run: registers accounts) |
| X7 (part), S11 | Web group pin and mute writes report failures; SDK gap S11 recorded for the two pin and mute paths | Web app; fixture mirrors the server projection |
| X19 (part) | Web sign-out asks first; Tauri block and remove friend ask first and keep the dialog open on failure; Tauri owners get 解散群聊 instead of a leave the server rejects | `vue-tsc` 0 on both apps |
| X21, X22 (part) | Web 我 › 圈子 opens moments (it did nothing); the QR token and report target ids are no longer shown as text | Web app |
| G16, FR-088 | One message is in the Tab sequence (last focused, else newest); arrow keys, Home and End move between messages; hover toolbar buttons are reachable only from the focused message; the focused bubble is a named group described by its content and draws a visible outline (the desktop focus-within shadow had hidden the ring) | `MessageList.focus.test.ts`, reverse-validated; web fixture at 1280 px: 1 Tab stop in the list instead of 36, Shift+Tab returns to the last focused message, Enter opens the menu and Escape returns focus |
| X25 (back, web) | The platform contract's `onNativeBack` gets its first consumers: `useFlareNativeBack` in ConversationHeader and FlareScreen (when the host handles back), FlareBottomSheet and the forms built on it, message action sheet, image and video preview, merged-forward drawer, danger confirm and media send preview; `createWebPlatformAdapter({ historyBack: true })` maps the browser's back to it with one marked history entry; the web app opts in and its global search closes on back. Tab switches still unmount sub-pages (FR-095) | `nativeBack.test.ts`, reverse-validated; web fixture at 375 px: back closes in-chat search, then the chat, then leaves the page; after the on-screen back one browser back leaves |
| X8 (web cold start, Tauri) | Web: a cold start whose SDK fails to load (offline, dropped download) keeps the stored session and restores it when the network returns; only a session the SDK rejects is cleared; a failed SDK bootstrap is no longer memoized (sign-in kept failing until reload). Tauri: kicked and expired are tracked by the event hub and the shell shows the kit connection notice above every tab with 重新登录 (it showed 未连接 in the chat pane only) | `tests/session-restore.test.ts` (web), reverse-validated; `vue-tsc` 0 on both apps |
| X23 (Vue) | ContactDetail shows an intent only when the host handles it (no disabled call buttons, no friend-only actions for strangers); GroupDetail shows a loading state and chevrons on rows the viewer can edit | `FlareContactDetail.test.ts`, `FlareGroupDetail.test.ts`, reverse-validated |
| G18 | The profile header is a quiet identity card on the list surface instead of a full-bleed brand banner, and it is a real button with the QR button beside it (it was a clickable `div` with a nested button, unreachable by keyboard); the moments cover without a photo is a short neutral band with normal text colours instead of a brand gradient | `FlareProfilePanel.test.ts`; web app 我 tab in dark at 1280 px |
| Moments accessibility (Vue) | MomentCard author, likers and comment rows are buttons only when the host handles them (a clickable `div`, `<a>` without `href` and clickable list items before); comment rows are named 回复 {name}：{text}; names use the accessible primary text colour | `FlareMomentCard.test.ts`, reverse-validated |
| G19 (Vue) | System and recall notices are a quiet chip (tertiary surface, regular weight, no border or shadow), matching the native kits' notice line and the Vue date chip; the transient 没有更多消息了 hint keeps its floating chip because it sits over messages | Contrast 5.09:1 light, 5.42:1 dark (12 px text) |
| G11 (kit part), X20 (kit part) | FlareScreen `readable` keeps a page's header and content in a centred 720 px column on wide panes (`--flare-component-screen-reading-width`); its back button is named 返回 (it was the English literal "Back") and is 40 px | `FlareScreen.test.ts`; the web app adopts `readable` on 我, 圈子, 设置 and 通讯录 pages in Batch 3 |
| X13 (natives) | History pages past the local store: when a page before the cursor comes back short and its oldest message is above seq 1, the apps call `sync.conversation_history_backfill`, read the page again and stop on an empty page; a failed backfill with nothing older locally shows the load-older error with retry instead of ending history (iOS, Flutter, Android); moments load more on scroll | iOS logic check 68, Flutter `chat_timeline_view_model_test`, Android `TimelinePagingTest` 12; not run against a server |
| X7, X14, X15, X16, X17 (natives, Batch 2b) | Load failures show error states with retry and failed writes keep the dialog or toast; read state only while the chat is visible and the app is in the foreground; conversation rows offer the kit action sheet (group pin and mute through the group settings, S11); fixed demo location and poll payloads removed (iOS keeps a poll composer that sends what the user entered); iOS add-friend searches users and join-group shows real member counts | Kit and app tests in the Batch 2b reports; simulator and Gradle builds |
| FR-078, FR-080, FR-082, FR-104 (native kits, Batch 2) | Received images, videos and voice open or play with the kit defaults on Flutter, SwiftUI and Compose, and files go to the host through `onOpenFile` (no native app could open received media); mention spans are highlighted; date separators appear at the first message and at day changes with 今天 and 昨天; call device toggles are switches named by the device | Flutter kit 715 to 759 tests, app 28 to 35; SwiftUI 336 to 379 and the simulator build; Compose 236 to 262 unit tests, 73 instrumented tests compiled, app mapping JVM checks 4 |
| FR-092, FR-096, FR-084, FR-089, FR-103, FR-044 (native kits, Batch 2b) | The Vue items above on three more kits: kit connection notice with 重新登录 for kicked and expired; prompt and confirm presenters that keep the dialog open with the error; a single overflow action performs it; header default copy, member count and presence from the strings table; long settings values stack; 20-cell member preview with a searchable list; mention picker driven by the keyboard; Chinese contacts indexed by pinyin initial (Flutter GB2312 level-1 table; Compose and SwiftUI platform transliteration) | SwiftUI 379 to 420; Flutter 759 to 800; Compose 262 to 294 unit tests and 88 instrumented tests compiled |
| X23, G18, moments accessibility, X22 kit part (native kits, Batch 4) | ContactDetail and ProfileCard show only the intents the host handles; the profile header is an identity card with a separate QR control; moments authors, likers and comments are controls only when handled, and comment rows are named 回复 {name}：{text}; a cover without a photo is a neutral band; the Flare ID row shows only a public handle. Compose ProfileCard, which still drew all three action tiles with unnamed call and video tiles, now follows the same rule with named 48 dp targets | Flutter kit 815 and app 76; SwiftUI 435 and the iOS app logic checks 83 (a harness outside the app repository) with the simulator build; Compose 307 unit tests and 97 instrumented tests compiled |
| S19 (Flutter, iOS and Android apps) | Rich-text send normalises the markdown with `rich_doc_v2.normalize_from_markdown` before `message_builder.create_rich_doc`; the `{ markdown }` request the core rejects is gone, and a failed normalise or create shows the send failure | Android `RichDocSendTest` 3; Flutter `im_client_test.dart`; iOS logic checks (`RichDocSend` request mapping) |
| X22 (native apps) | iOS and Android no longer print account ids as names (a missing name reads 未知用户 from the kit strings), and the profile editor no longer treats the account id as the Flare ID; the apps pass the username as the public handle | Android `PersonDisplayTest` 3 and `compileDebugKotlin`; iOS logic checks 83 and the simulator build |
| FR-049 (native kits, follow-up) | Profile panel default entries come from the strings table (收藏, 圈子, 设置) instead of English literals on Flutter; SwiftUI already did and its 朋友圈 default now reads 圈子 like the other kits and all five apps; Compose builds them from the strings table too (`profileEntries(strings)`) | Flutter kit 816; SwiftUI 435; Compose `ProfilePanelEntriesTest` 3 |
| Kit gaps from the Tauri pass | A message located right after a conversation opens stays on screen (`scrollToMessage` enters browse mode and cancels the pending bottom scrolls); ProfileCard actions follow handled intents; FriendListContainer forwards `retryLabel` | `MessageList.history.test.ts`, `FlareProfileCard.test.ts`, `FlareFriendListContainer.test.ts`, reverse-validated |
| X22 (kit part, web, Tauri) | ContactDetail and ProfileCard show a Flare ID only from a public handle (`FlareContact.flareId`), never the account id; the web and Tauri connection banners no longer print the core's technical disconnect reason (it goes to the console); FlareEmptyState's action no longer submits forms; the moments avatar keeps to the top of its card | `FlareContactDetail.test.ts`, `FlareProfileCard.test.ts`; `vue-tsc` 0 on both apps |
| X7, X18, X21, X22 and dead ends (web, Batch 3) | Directory loads keep their rows and show kit error states with 重试; writes throw product copy so confirmations and sheets stay open; chat details for a stranger use the kit relation bar instead of friend-only actions; 发消息 on a matched contact opens the 1:1 chat (no pseudo group); join by invite code; 发起聊天 opens a friend picker; notification preferences and diagnostics rows removed; auth shows no gateway settings or raw errors; a failed chat open on a phone returns to the list with a toast; full pages use the reading column | Web unit tests 72; app-visual specs 36 (new specs fail on the pre-change sources: 16 of 16); every op exercised through the fixture core only |
| X7, X9, X21, X22, X24 (Tauri, Batch 3) | Load failures show error states with 重试 and writes keep dialogs open; presence and rich-text send go through routed core ops (`presence.batch_get`, `rich_doc_v2.*` via `sdk_invoke_json`) and call entry points are removed; notification preferences removed, login devices are the real list with revoke, one privacy entry, a version row, archive removed, group pin and mute read and write one source; ids, `#seq`, tokens and start-script hints removed; history paging ends at the first message; pinned, search and quote jumps page to the target; global search locates message hits and lists only friends as contacts; group management stays in the chat's detail pane. Also fixed: remark saves always failed and group preference writes did nothing (wrapped params) | `vue-tsc` 0 and `vite build`; no runtime check (no fixture harness) |
| X10 (web, Batch 3) | Forward to other conversations (merged, or one message per send because the core rejects several sources unmerged), multi-select with the kit batch toolbar (forward, delete with confirmation), message pin with the kit pinned bar, file and image downloads through resolved media URLs, typing out and in with the kit indicator, 1:1 presence, per-conversation drafts saved to the core, failed sends that give the text back; rich text sends a normalised document (the old `{ markdown }` request fails on the real core) and the desktop composer shows the format tool | Web unit tests 75; app-visual specs 39 pass; server-side behaviour proven only through the fixture core |
| Kit gaps from the web pass | Multi-select controls are named checkboxes; the pinned bar reads 置顶消息 and localizes its fallbacks; a merged forward shows its title as the title (not as 附言) and never prints sender account ids; an address the page cannot fetch opens in a new tab instead of navigating the app away; batch toolbar labels keep their width on phones and the row scrolls; the image preview offers the host's download | `ImageView.test.ts`, `browserDownload.test.ts`, reverse-validated; kit tests 692 |
| Tauri forward (follow-up) | Forward each sends one message per source per destination (the core rejects several sources unmerged); partial failures keep only failed destinations selected; merged forwards send no title | `vue-tsc` 0 and `vite build` |
| Test environment | Website ConfigProvider demo no longer animates colour under reduced motion (an axe scan under load read the transition) | Full website suite 142 of 143 before the change; axe 3 of 3 alone |
| X26, X28 (Tauri, after the re-grade) | Received media resolves through the app's own access-url reader (local path or the remote URL), not `media.resolve_access`'s source kind; the preview and download targets read the core's nested `source`; message pin and unpin send `scope: 0`; the send ack reads `serverId`; the composer asks for the expanded toolbar on desktop windows, so format mode is reachable | `vue-tsc` 0 and `vite build`; the media path cannot be proven without a media service (External Validation Steps A2) |
| X29 (web, after the re-grade) | Older history pages past the local store: a short page above seq 1 triggers `sync.conversation_history_backfill` and a re-read, an empty page ends the history, and a failed backfill with nothing older keeps the history open with 更早的消息没有加载出来 and a retry; a conversation whose oldest loaded message is not the first now offers older messages at all | `tests/timeline.test.ts` +3 (2 of 3 fail on the previous logic); fixture op added; web unit tests 77 |
| X33 (Vue kit, after the re-grade) | Settings rows gained `action` (in place) and made `value` read-only, so information rows are no longer buttons; `FlareGroupDetailModel.myMuted` / `myPinned` accept `null` for a setting that could not be read, which renders as 暂时无法读取 instead of "off"; business cards no longer draw a 查看详情 button nobody handles, and the mini-program card drops its app id and page path | `FlareSettingsRow.test.ts` +2, `FlareGroupDetail.test.ts` +1, `FlareBusinessMessageViews.test.ts` 5 (5 of 5 fail on the previous views) |
| FR-083 (Vue kit, web) | A window too narrow for the list beside a usable chat (below 752 px) shows one pane with the rail, and the shell reports the presentation it uses (`layoutChange`) so the host shows the chat's back control | `FlareAppLayout.test.ts` +2, `application.test.ts`, application spec at 700 px; reverse-validated |
| Desktop search (web) | Global search is a centred palette over the app on pointer devices instead of a full-screen takeover; phones keep the full page. The kit's dialog width became a component token (`--flare-component-sheet-dialog-width`) so a host can widen it | Application-visual baseline `desktop-search.png`; app-visual suite 52 specs |
| FR-091 (web) | Application-visual baselines: 12 screenshots of the running app (inbox, chat, dark chat, search, group members, settings, image preview, empty, error, tablet, phone, dark phone) with macOS classic scrollbars and a per-platform baseline folder | Three consecutive runs identical; Linux baselines are an external step |
| Delete copy (web, Tauri) | The message delete confirmation says the message goes from all of the user's devices, because `message.delete` is `delete_for_self` with the user-private scope, which the core syncs; conversation delete and clear history keep their local wording | Code review against `flare-im-core-sdk` `src/client/api/message.rs:175-188` |
| Language switching (Vue kit) | `FlareUiProvider` follows a host that binds `locale`: it watched theme, brand, layout, size and the asset root but read the language once, so a host switching languages kept the kit strings it started with (Tauri binds a computed locale) | `FlareUiProvider.test.ts` (new, reverse-validated) |
| X27, X33 (native kits, Batch 6) | The timeline opens at the newest message and follows the tail on all three native kits, with the jump-to-latest count when the reader has scrolled up; Copy appears only where there is text to copy; text links reach a host intent (`onOpenLink`) and, on SwiftUI and Compose, the platform opener behind the safe-URL gate when the host does not handle them; Compose writes `@所有人`, the token the core parses; Flutter and Compose render inline emoji tokens in text bodies | Compose kit 324 unit tests and 101 instrumented compiled; Flutter kit 836 and app 90; SwiftUI kit 455 with the simulator build; gates per report |
| X30, X31, X32 (native apps, Batch 6) | iOS reports forward, reaction and image-upload failures, parses the array replies of the search ops, offers 重新连接 through `connection.notify_network_change`, wires or hides the announcement read link, and shows the stranger-message switch only once it is known; Android re-keys its account-scoped view models on sign-out, reports failed uploads and failed reads, pads for the keyboard and refreshes its stale signed-in test expectations; Flutter writes the group notification mode the op takes, shows the connection notice inside the chat and the moments tab, and catches a denied gallery permission | iOS app harness 16 checks and the simulator build; Android `:app:compileDebugKotlin` with its JVM-harness tests; Flutter app tests 90 |
| Semantic icon names (three native kits and three native apps, Batch 5) | Every public icon field on the native kits takes a registry name instead of a platform glyph type (`ImageVector`, SF Symbol name, `IconData`): navigation items, settings rows, message menu entries, composer actions, buttons, icon buttons, empty states, workspace pane empties. An unknown name draws the registry fallback and warns once per name in a debug build, so a glyph written into a name parameter is visible in development rather than silently a question mark in production. The default-navigation and contact-navigation constants became functions of the strings table, so their labels are no longer English literals in a Chinese-first kit | `platformGlyph` in the three native apps 60 / 48 / 32 → **0 / 0 / 0**; kit-internal glyph references flutter 221 → 176, ios 116 → 76, compose 182 → 170, both ratchets re-locked; Compose `SemanticIconTest`, SwiftUI `SemanticIconApiTests`, Flutter icon tests |
| Settings row kinds and unreadable settings (three native kits, Batch 5) | `FlareSettingKind` gained `action` on all three native kits, and a `value` row is no longer a button anywhere: no control, no focus stop, no callback, and a screen reader reads it as one "label, value" element. A group setting that could not be read renders as 暂时无法读取 rather than a switch that claims "off" | Compose `SettingsRowKindTest`, SwiftUI `SettingsRowKindTests` (5), Flutter settings tests; `check-hardcoded-strings` unchanged on all four kits |
| FR-083, FR-095 (three native kits and three native apps, Batch 5.4) | The single-pane rule below navigation + list + a usable chat (752) and the `onLayoutChange` report landed on Flutter, SwiftUI and Compose; each kit's layout measures its own box rather than the window, and each app dropped its own width guess. The iOS one was a real defect: `horizontalSizeClass` is `.regular` in an iPad Split View, so a 700 pt window squeezed the chat to about 380 pt | Nine new cases in `spec/application-layout-vectors.json`, all four kits passing them unchanged; Flutter kit 859 and app 93; SwiftUI kit 473 including three tests hosted in a real window (an inspected `GeometryReader` always reads single-pane); Compose kit tests green |

## 9. Plan

Each round follows the same steps:

1. Pick a real scenario.
2. Review it with frontend-design against captures.
3. Classify each finding.
4. Make the smallest correct change.
5. Verify the component.
6. Verify the app.
7. Delete the workaround.
8. Record the evidence.

The lead owns the Vue kit, web, Tauri, spec, website and docs. One agent per native platform owns its kit and app. HIGH and MEDIUM items only.

| Round | Scope | Items |
|---|---|---|
| R5.1 | Shell, navigation, conversation list, chat layout | G2 time column · G5 600 to 767 single pane and the detail fit check (FR-040) · G6 muted badge · G14 empty inbox · X25 web back handling · X21 dead controls on these surfaces |
| R5.2 | Message rendering | G3 mentions on four kits · G4 separator rule · G19 pills · G20 failed bubble · FR-093 native data adapter · FR-094 native message menu and reaction direction · X14 read on visibility (natives) · X13 history paging (natives) · X24 Tauri paging and jumps |
| R5.3 | Composer | FR-036 asset root · FR-053 pickers · FR-035 typing · X16 remove demo payloads · G21 offline composer · IME check |
| R5.4 | Actions | X10 web forward, multi-select, pin, download · X15 native conversation actions · FR-034 batch toolbar API · X19 confirmations |
| R5.5 | Search | G10 desktop search panel · FR-043 SearchPanel · recent searches · jump to context on four apps |
| R5.6 | Media | X5 default image, video and file preview and voice playback on native kits, wired in three apps |
| R5.7 | Members and group | FR-044 CJK index · X23 GroupDetail loading, member row, ContactDetail relationship · G7, G8 · FR-046 · X17, X18 |
| R5.8 | Loading, error, empty, offline | X7 failures on five apps · X8 session endings · FR-096 connection banner · FR-092 prompt and confirm presenters · FR-057 stale state · FR-042 phone confirm |
| R5.9 | Settings and theme | FR-047 native avatar · FR-048 BrandLogo · FR-045 reveal toggle · X21 settings that do nothing · X22 internal information |
| R5.10 | Responsive | FR-095 shell measures and derives (includes FR-040, FR-083 and web back handling) · 320 to 1440 matrix on the fixture · G11 list-detail and reading width on desktop pages |
| R5.11 | Accessibility and keyboard | X6 unnamed controls on three kits · G16 timeline roving focus · IME composition |
| R5.12 | Semantic icon system | 39 new names on four kits · 6 remaps · removals · name-typed APIs · size tokens · Unicode · ratchet gates · app migration |
| R5.13 | Visual consistency | G9 dark avatars · G18 hero and cover · FR-049 literals · FR-051 typography roles · FR-050 density decision · X20 languages |
| R5.14 | DX, recipes, composition proof | Recipes against the current API; a composition proof built without golden-app glue; application visual baselines from the fixture |
| R5.15 | Final product review | PASS 8 on captures; full regression; final report |

## 10. External validation (needs two signed-in accounts)

Signing in needs credentials, which this program does not enter. A person with two befriended test accounts (A and B) runs these steps on each app in its supported form factors and records pass or fail:

1. A and B sign in, then quit and relaunch: the session is restored (X11).
2. A opens the 1:1 conversation from 通讯录 and sends text; B receives it live, and the row preview, time and unread badge update.
3. B opens the conversation: the unread badge clears, and A's message shows read.
4. B replies with a quote; A receives it, and the quote locates the original.
5. A reacts, then removes the reaction; B sees both changes.
6. A pins and unpins the conversation and a message; the order and pinned bar follow.
7. With B offline, A sends: the message stays pending or failed with a retry; retry after B reconnects delivers once.
8. A creates a group with B, sends "@B", and B sees the mention.
9. A promotes B to admin and demotes B again. A mutes B and removes B; each change reaches B.
10. B leaves the group; A sees the member count change.
11. A sends an image, a file and a voice message; B opens each one (X5).
