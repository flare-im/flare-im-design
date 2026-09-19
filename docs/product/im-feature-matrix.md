# IM feature matrix

**Purpose.** One evidence-based view of what the Flare IM stack delivers per feature, across the SDK, the design system and the five social example apps, so that work on the core IM loop goes to the layer that actually blocks it.

**Date.** 2026-09-16 (Round 5 re-grade, then Batches 5, 6 and 5.4), with the Round 9 message-body rows re-graded on 2026-09-18. The first grading was 2026-09-14.

**Sources.** The read-only audits of 2026-09-14 (`audit-sdk.md`, `audit-kit-vue.md`, `audit-web.md`, `audit-tauri.md`, `audit-flutter.md`, `audit-native.md`), and the Round 5 re-grade: five read-only passes (Web and the Vue kit, Tauri, iOS and the SwiftUI kit, Flutter, Android) that checked every cell of their column against the working tree and the core and social op contracts. Where those disagreed with a self-assessment, source decided.

**Reference apps.** Golden: Web (`flare-social-web-app`). Second reference: iOS (`flare-social-ios-app`). Tauri (`flare-social-tauri-app`), Flutter (`flare-social-flutter-app`) and Android (`flare-social-android-app`) are parity apps. Their columns never change Result.

**Build state (Round 8 · B3, round closed).** All five apps build against the kit working tree, as verified this round: web and Tauri `vue-tsc` 0 errors, Flutter `flutter analyze` 0 issues, iOS `swift build --target FlareSocialApp` (the library target — the executable links the Rust FFI archive, which is cross-compiled for the simulator only and cannot link on macOS, as the app's README says), Android `:app:compileDebugKotlin` and `:app:compileDebugAndroidTestKotlin`. The simulator `xcodebuild` and the Gradle instrumented runs are External Validation Steps on this machine. App tests: web 80 unit and 58 application specs (including 12 application-visual baselines and 3 performance probes), Flutter 122, Android instrumented tests compiled (no emulator on this machine), iOS 26 logic checks in a harness outside the app repository (it was 52 until B8 moved the locate scenarios into the kit, where they are one shared table answered by four platforms instead of one app's rules), Tauri none. Kit tests: Vue 987, Flutter 1207, SwiftUI 513, Compose 378. Social SDK packages: TypeScript 69, Flutter 40, Apple 15. Server (`flare-im-core`, Round 8): `cargo check --workspace` clean, `flare-signaling-gateway` 56 and `flare-im-service-kit` 32 lib tests pass; `flare-im-arch-tests` has one **pre-existing** failure (`production_env_vars_are_registered`, seven undocumented env vars in files Round 8 did not touch).


**How this re-grade was made.** Every app column was re-checked against the code, not against the earlier grades: an app cell is C only when a user can reach the control and it calls an op that exists in the core or social contract, with a request shape that matches the op and a visible outcome on failure. Local fake data and canned payloads grade at most P. The web fixture core (`tests/app-visual`) replaces the SDK in tests only: it proves wiring, never server behaviour. A feature wired in the app but blocked by a core or server gap grades P with the gap named (S-numbers are in `product-refinement-audit.md` section 7). The Design System column is the weaker of the Vue kit and the SwiftUI kit, both re-graded feature by feature; Flutter and Compose kit gaps appear in notes. Nothing here was verified against a backend: signed-in checks are in the final report's External Validation Steps.



## How to read the matrix

### Status vocabulary

| Code | Status | Meaning |
|---|---|---|
| C | COMPLETE | Reachable UI wired to a real SDK path end to end. |
| P | PARTIAL | Exists but stubbed, local-only, or some paths missing or broken. |
| M | MISSING | Absent. |
| NS | NOT_SUPPORTED | Intentionally absent because a lower layer (SDK or server) lacks it. |
| NA | NOT_APPLICABLE | Not meaningful for this layer or app. |

In the SDK and Design System columns, C means the layer exposes what the feature needs: a public API whose events are delivered, or a public component or contract.

### Columns

- **SDK**: `flare-im-core-sdk`, `flare-im-core-client-sdk` and `flare-social-sdk` as reached through their bindings. Statuses follow section 2 of `audit-sdk.md`. One reinterpretation: that audit rates Message search COMPLETE (local-only); this legend rates local-only as PARTIAL.
- **Design System**: `@flare-im/vue-ui` 2.0.0-rc.1 (used by Web and Tauri) and FlareIMUI (used by iOS), graded from `audit-kit-vue.md` and `audit-native.md` and reconciled with `component-maturity.json`. Source decided every disagreement. Compose and Flutter kit gaps appear in notes only.
- **Web, Tauri, Flutter, iOS, Android**: section H of the matching app audit.
- **Tests**: `kit` means a Vue kit test (`packages/vue-im-ui/src/**/*.test.ts`) or Flutter kit test (`packages/flutter-im-ui/test`) matches the feature by keyword. `app` means a Web test (`tests/*.test.ts`, `tests/browser/*.spec.ts`), Flutter app test (`test/`) or Android instrumentation test (`androidTest`) touches it. `—` means none. This is a keyword grep, not proof of coverage. Most app tests need a live backend or are stale: 4 of 6 Web Playwright specs are stale, Web vitest passes 10 of 11, 5 of 6 Flutter app tests do not compile, and Tauri and iOS have no tests.
- **Evidence / note**: at most 25 words and one file:line citation.

### Result rule

Result is the weakest status among the SDK, Design System, Web and iOS columns, ignoring NA, ordered M, NS, P, C from weakest to strongest. An app NS caused by the SDK makes Result NS only when the SDK column is M (that SDK M then also counts as NS); otherwise the NS counts as P.

### Blocking layer rule

Blocking layer names the layers that keep Result below C, lowest first: SERVER, SDK, PLATFORM, DESIGN_SYSTEM, APP. Every listed layer has a defect of its own. A higher layer is left out when its gap only follows from a lower one: apps cannot show a mention count that the SDK and server never provide, so Mention unread is blocked by SERVER and SDK, not APP. SERVER is used where `audit-sdk.md` traces the gap to `flare-im-core` or `flare-social`. `—` means Result is C.

### Citation prefixes

| Prefix | Path |
|---|---|
| `sdk:` | Paths as cited in `audit-sdk.md`, including its CORE, CSDK, SOC, GW and ROUTE aliases |
| `kit-vue:` | `flare-im-design/packages/vue-im-ui/src/` |
| `kit-ios:` | `flare-im-design/packages/ios-im-ui/Sources/FlareIMUI/` (added for iOS kit evidence) |
| `kit-flutter:` | `flare-im-design/packages/flutter-im-ui/lib/` |
| `kit-compose:` | `flare-im-design/packages/android-im-ui/src/main/kotlin/com/flare/im/ui/` |
| `web:` | `flare-social-web-app/src/` |
| `tauri:` | `flare-social-tauri-app/src/` |
| `flutter:` | `flare-social-flutter-app/lib/` |
| `ios:` | `flare-social-ios-app/Sources/FlareSocialApp/` |
| `android:` | `flare-social-android-app/app/src/main/kotlin/com/flare/social/app/` |

## Feature matrix

### Authentication

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Login | P | NA | C | C | P | P | P | P | SDK | app | Password, code, register and reset sign-in work, but every launch signs in again: the Swift wrapper has no IM session restore (S8) `ios:SocialSession.swift:31` |
| Logout | C | NA | C | C | C | C | C | C | — | — | 登出清本地会话；账号级 ViewModel 按账号重建并在换号时自清，下一个账号不再看到上一个的圈子 `android:MomentsScreen.kt:71-74` |
| Reconnect | C | C | P | P | P | C | P | P | APP | — | 断线横幅给 重新连接，调 connection.notify_network_change；失败有提示 `ios:SocialSession.swift:1445` |
| Session expiration | P | C | C | P | P | P | P | P | SERVER, SDK | app | Kicked and expired show the kit notice with 重新登录, which clears the stored session even when logout fails; the core refreshes tokens first `web:views/MainView.vue:84-100`; `sdk:CORE/src/client/im_client/session_watchers.rs:75-86` |
| Account state | C | P | P | P | P | P | P | P | DESIGN_SYSTEM | kit, app | Profile and devices wired; get_my_account, password change and username unwired; kit ProfileEditor saves only name and signature, plus avatar pick `kit-vue:components/profile/FlareProfileEditor.vue:10-15` |

### Conversation

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Conversation list | C | C | C | C | C | C | C | C | — | kit, app | 两栏还是一栏改由外壳按自身宽度决定，不再看模式阈值；仅实现变化。 `kit-flutter:src/application/application_composition.dart:763-781`; `flutter:screens/base_shell.dart:461-485` |
| Private chat | C | C | C | C | C | C | C | C | — | kit, app | 单面板时聊天顶替列表并自带返回；双面板时不再画一个只会清空右栏的返回。 `flutter:screens/base_shell.dart:638-654` |
| Group chat | C | C | C | C | C | C | C | C | — | kit, app | Wired in all apps; web re-derives the core group conversation id client-side `web:social/sdk.ts:168-195` |
| Unread | C | C | C | C | C | C | C | C | — | kit | Row badges, tab total and read only while the chat is visible; the tab total still counts muted conversations (G6) `ios:MainShell.swift:17-20` |
| Mention unread | M | C | M | P | M | M | M | M | SERVER, SDK | kit | SDK hardcodes mention count 0 and the server summary has no field; Tauri prefix keys on mentionMe and never shows (verified) `sdk:CORE/src/model/conversation.rs:797-798` |
| Mute | C | C | C | C | C | C | C | C | — | kit | 单聊走 conversation.set_muted，群聊改发 notifyMode（MUTED/ALL），写得进去也读得回来。 `flutter:sdk/base_social_client.dart:1795-1800`; `flutter:screens/base_shell.dart:293-300` |
| Pin | C | C | C | C | C | C | C | C | — | kit | Row menu pins through conversation.set_pinned, the core lists pinned rows first, failures toast; group details keep a separate pin (S11) `web:social/store.ts:225, 431-433` |
| Draft | C | C | C | C | C | C | C | C | — | kit, app | R7-B4: all five apps write through `conversation.update_draft`, so a draft roams to the account's other devices; when to write is the kit's rule (`FlareDraftAutosave`, `spec/draft-vectors.json`, 23 scripts × 2 clock bases) — after a 1200 ms pause, immediately on leaving, cancelled on send. `updateDraft` added to the Flutter, Apple and Android facades (only TypeScript had it). Tauri's localStorage store and the web/Android copies of `restoredDraft` are deleted. Arrival on a second device is External Validation. `kit-vue:utils/draftAutosave.ts`; `flutter:viewmodels/conversation_signals.dart` |
| Typing | C | C | C | C | C | C | C | C | — | kit, server | R7-B1/B2 + R8-B1: one rule on four kits over one table (`spec/typing-vectors.json`) — `FlareTypingSignal` reports (idle 4000, refresh 2500) and `FlareTypingRoster` believes (ttl 6000), with `refreshMs < peerTtlMs` asserted everywhere; all five apps send and show it. The gateway now broadcasts the aggregated frame to the other gateway instances (`AccessGateway.RelayRealtimeControl`, skipping itself), so two people on two nodes see each other — it used to relay only to its own node's subscribers. Multi-node behaviour itself is External Validation: this machine runs one instance `sdk:GW/domain/service/realtime_relay.rs`; `kit-vue:utils/typingSignal.ts` |
| Online status | C | C | C | C | C | C | C | C | — | kit | R7-B3 + R8-B2: all five apps read presence for every direct peer the list shows, again when a conversation opens, **and again when the connection comes back** — S21 turned out to be app-side, not SDK-side: the client core forgets its own subscription bookkeeping when the stream ends, so nothing was stopping a fresh subscribe except that nobody made one. A lookup the core could not make is **unknown, not offline**; the projection is under `sdk-spec/golden/presence-projection.json` (13 lookups, 10 pushes) on four SDK packages, where it had no test at all `kit-vue:utils/connectionRefresh.ts`; `ios:SocialSession.swift` |
| Last message | C | C | C | C | C | C | C | C | — | kit, app | Preview tokens decoded in all apps; the kit parses the server preview-token grammar directly `kit-vue:utils/messagePreview.ts:178-245` |
| Timestamp | C | C | C | C | C | C | C | C | — | kit | Row times shown everywhere with fixed zh or en formats; kit row formatting supports only en-US or zh-CN `kit-vue:components/conversation/FlareConversationRow.vue:117-129` |
| Archive | C | C | M | M | M | M | M | M | APP | kit | Archive action removed because there is no archived view; rows archived elsewhere are still hidden with no way to reach them `tauri:components/chat/SessionList.vue:68-76`; `tauri:host/utils/conversationList.ts:164` |
| Delete conversation | P | C | P | P | P | P | P | P | SERVER, SDK | kit | 仅文案：会话删除与清空记录仍写「本机」，因为核心确实只删本机 `ios:ConversationsView.swift:84-104` |
| Search conversation | C | C | P | C | M | P | P | P | APP | — | No list filter; global search finds friends, groups and local message hits and opens their chats; 1:1 chats with non-friends are not found by name `web:views/MainView.vue:215-223` |
| Create conversation | C | C | C | P | P | C | C | C | — | kit, app | 发起聊天 picks a friend and opens conversation.get_one; 建群 creates the group and opens its chat; failures return to the list with a toast `web:components/ConversationPane.vue:66-84`; `web:views/MainView.vue:181-212` |

### Messaging

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Text | C | C | C | C | C | C | C | C | — | kit, app | Text send works in all apps; Tauri now orders the timeline by the core's conversationSeq, keeping unsequenced sends last `tauri:host/chat/utils/messageIdentity.ts:32-46` |
| Emoji | C | C | C | C | C | C | C | C | — | kit | 文本气泡把 `[key]` 画成内联表情图片，未知 key 保留方括号文本；贴纸与独立表情照旧。 `kit-flutter:src/components/flare_message_bodies.dart:143-190` |
| Mention | P | C | P | P | P | P | P | P | SDK | kit | 选「所有人」写入 `@所有人`，核心能解析为 @全体；点名 @某人 仍被核心丢弃（S14） `kit-compose:FlareStrings.kt:112-113` |
| Reply | C | C | C | C | C | C | C | C | — | kit | Reply sends six fields through `create_quote` then `message.send`; the returned quote block locates or reads history `flutter:screens/chat_screen.dart:272, 460-492, 665` |
| Quote | C | C | C | C | C | C | C | C | — | kit | `imQuoteCreateParams` sends `quotedContent`, `quotedSenderId` and the kit summary, so the core no longer refuses the quote `flutter:sdk/im_client.dart:785-812`; `flutter:sdk/base_social_client.dart:1281` |
| Reaction | C | C | C | C | P | C | C | C | — | kit | 气泡回应失败弹危险提示，不再静默；仍非乐观更新 `ios:ChatView.swift:416` |
| Image | C | C | C | P | C | C | C | C | — | kit | 收图开 kit 预览；读图、写临时文件、上传发送三段失败各自提示 `ios:ChatView.swift:147` |
| Multiple images | C | C | C | C | C | C | C | C | — | kit, app | R9-B7: all four kits draw an album (nine tiles, `+N`); apps pick up to nine and send one album, nothing if an upload fails `web:social/store.ts:793-830` |
| Video | C | C | C | P | P | P | P | P | APP | kit | Received videos resolve their file id and play in the kit player; no video send, the picker takes images only `ios:SocialSession.swift:1158-1162` |
| Audio | C | C | C | P | P | P | P | P | APP | kit | Received audio resolves its file id and plays as a voice bubble; no audio-file send `ios:SocialSession.swift:1155-1157` |
| Voice message | P | C | P | P | P | P | P | P | SDK | kit | Kit recorder is on through send-voice-handler and sends via create_audio; the core has no voice-note flag or send duration (S13) `web:components/ChatArea.vue:142-144, 622` |
| File | C | C | C | P | P | P | P | P | APP | kit | Files send through create_file; received files download from the media.get_url address inline or from the menu, with a failure toast `web:components/ChatArea.vue:389-401` |
| Location | C | C | M | M | P | P | P | M | APP | kit | Demo location send removed; received locations render as a kit card that does not open; no location send `ios:SocialSession.swift:1145-1146` |
| Contact | C | P | M | M | P | P | P | M | DESIGN_SYSTEM, APP | kit | `create_card` unused on web and Tauri, whose attach grids omit contact; iOS and Android send only the user's own card `web:components/ChatArea.vue:139-142` |
| Link | P | P | M | M | P | P | P | M | SDK, DESIGN_SYSTEM, APP | kit | 文本里的链接与链接卡片现在都能打开（无 handler 时 kit 只开 safeExternalUrl 认可的 http/https）；仍不能发链接卡片 `kit-compose:MediaPresentation.kt:96-101` |
| Rich text | P | C | C | P | C | C | C | P | SDK | kit, app | R9-B6: all four kits draw the stored RichDoc v2 document, never the sender's Markdown. R10: any tight Markdown list, including the kits' own list buttons, fails normalisation, so the send fails (S27); tables, underline, images and some links are lost (S25); patch in `sdk-change-proposals.md` `sdk:CORE/src/content/rich_doc_v2/from_markdown.rs:111-115` |
| Poll | P | C | M | M | P | P | P | M | SDK, APP | kit | R9-B8: all four kits report a vote (the option's index) when the host takes it; no op casts one (S26), no choice mode on send (S15) `kit-vue:components/messages/business/FlareVoteMessageView.vue` |
| Topic | P | M | M | M | M | M | M | M | SDK, DESIGN_SYSTEM | kit | No thread list, count or unread API; kit renders thread messages as a generic info card with no thread view (verified) `kit-vue:components/messages/MessagesView/ContentView.vue:177-178` |
| Mini app | C | P | M | M | P | P | P | M | DESIGN_SYSTEM, APP | kit | Received mini programs render as a kit card that does not open; no send `ios:SocialSession.swift:1181-1183` |
| Schedule | P | P | M | M | P | P | P | M | SDK, DESIGN_SYSTEM, APP | kit | Received schedules render as a kit card with the time range, not a generic chip; no send or RSVP `ios:SocialSession.swift:1178-1180` |
| Task | P | C | M | M | P | P | P | M | SDK, APP | kit | R9-B8: all four kits report a task toggle (the done state asked for) when the host takes it; no op updates a task (S26), no send `kit-vue:components/messages/business/FlareTaskMessageView.vue` |
| System message | C | C | C | C | C | C | C | C | — | kit | Server event_kind keys decoded in all apps; iOS, Android and Flutter each keep a hard-coded zh event table `ios:SocialSession.swift:946-957` |

### Message states

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Sending | C | C | C | C | C | C | C | C | — | kit | Created messages without a seq show sending and messages without a status pending, from core status (web rule) `ios:SocialSession.swift:1091-1103` |
| Sent | C | C | C | C | C | C | C | C | — | kit | Sent and persisted core statuses map to the sent mark instead of a hard-coded default `ios:SocialSession.swift:1098-1099` |
| Delivered | P | C | M | M | M | M | M | M | SERVER, SDK, APP | kit | PERSISTED now shows as sent and nothing maps to delivered: proto has no DELIVERED and core's derived delivery state is unbound `tauri:host/chat/utils/kitMessage.ts:19-34` |
| Read | P | C | P | P | P | P | P | P | SERVER, SDK | kit | Outgoing messages show read from the core isRead flag; no group read-by list in the SDK, kit ReadReceiptSheetView unused `ios:SocialSession.swift:1099` |
| Failed | P | C | P | P | P | P | P | P | SDK | kit | Failed bubbles resend the stored row through message.send and unsent text returns to the composer; the core has no resend op (S2) `web:social/store.ts:640-652` |
| Recalled | C | C | C | C | C | C | C | C | — | kit | isRecalled or status 5 becomes the kit recalled notice in place of the content `ios:SocialSession.swift:1038-1048` |
| Deleted | C | P | P | P | P | P | P | P | DESIGN_SYSTEM | — | Delete is for self only (message.delete syncs to the user's devices, though the dialog says this device); delete for everyone is not offered `web:components/ChatArea.vue:368-376`; `sdk:CORE/src/client/api/message.rs:175-188` |

### Message actions

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Copy | NA | C | C | C | C | C | C | C | — | kit | 组件库按内容判定可复制正文，图片/语音/文件不再出现空复制；核心 S22 仍记在 SDK 缺口。 `kit-flutter:src/components/flare_message_action_sheet.dart:84-101, 188` |
| Reply | C | C | C | C | C | C | C | C | — | kit | Reply left the hidden set; the sheet sets a kit-built reply target and the send reaches `create_quote` `flutter:screens/chat_screen.dart:234, 272` |
| Reaction | C | C | C | C | P | C | C | C | — | kit | 操作表回应失败弹提示；与气泡回应同一条路径 `ios:ChatView.swift:416` |
| Forward | C | C | C | C | C | C | C | C | — | kit | 逐个会话转发，失败保留选择器并点名失败会话 `ios:SocialSession.swift:2075` |
| Merge forward | C | P | C | C | M | M | M | M | DESIGN_SYSTEM, APP | kit | Multi-select 合并转发 sends one merged create_forward record per destination `web:components/ChatArea.vue:471-473, 609-610` |
| Multi-forward | P | C | C | C | M | M | M | M | SDK, APP | — | Several messages to several conversations, one unit per message and destination (no batch op); only failed destinations stay selected `web:social/store.ts:826-832, 876-894` |
| Delete | C | C | C | C | C | C | C | C | — | kit | 文案改成「从你的所有设备上删除」，与 delete_for_self 的用户级作用域一致（原文案说成本机）。 `flutter:screens/chat_screen.dart:260-266` |
| Multi-delete | P | C | C | C | M | M | M | M | SDK, APP | — | Batch toolbar delete confirms, calls message.delete per message and keeps failed ones selected with the error in the dialog `web:components/ChatArea.vue:426-445`; `web:social/store.ts:793-814` |
| Recall | C | C | C | C | C | C | C | C | — | kit | Recall offered by core availability, confirmed, failure kept for retry; recalled messages render the notice `ios:ChatView.swift:281-302` |
| Pin | P | C | P | P | M | M | M | M | SERVER, SDK, APP | kit | Pin and unpin through message.pin_by_message_id with conversation scope; the pinned bar lists loaded messages only and others' pins need a reload (S20) `web:social/store.ts:903-913`; `web:components/chat/chatView.ts:43-56` |
| Multi-select | NA | C | C | C | M | M | M | M | APP | kit | 多选 enters kit selection with the batch toolbar; Escape, back and 退出多选 leave it `web:components/ChatArea.vue:403-452, 603-614` |
| Save | C | C | C | M | M | M | M | M | APP | kit | The kit save entry (canSave) is a browser download of the core's media URL for images, videos and files `web:components/ChatArea.vue:341-344, 389-401` |
| Download | C | C | C | P | C | C | C | C | — | kit | Menu, hover and inline download resolve media.get_url and hand the address to a browser download; unresolved addresses toast. R10 gave all four kits the timeline download key (FR-144); R11 wired the three native apps to it (FR-047's sibling): Android writes the picture to the gallery through MediaStore, iOS hands it to the system share panel, and the Flutter app does both through its own host channel with no new dependency `android:ChatScreen.kt`, `ios:ChatView.swift`, `flutter:lib/host/gallery_save.dart` |
| Translate | M | P | NS | NS | NS | NS | NS | NS | SDK, DESIGN_SYSTEM | kit | Only an AI-plugin capability stub; kit TranslationView exists but the closed menu union has no translate (verified) `sdk:CSDK/docs/plugin-marketplace.md:83-95` |
| Report | C | P | C | M | M | M | M | M | DESIGN_SYSTEM, APP | — | 举报 is a kit menu extension on others' messages; the report sheet submits a message report and keeps errors in the sheet `web:components/ChatArea.vue:336-355`; `web:social/report.ts:35-51` |

### Composer

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Text input | NA | C | C | C | C | C | C | C | — | kit | Kit composer in all apps; web leaves it enabled while disconnected or muted because sendBlocked and readOnly are never passed `web:components/ChatArea.vue:249-270` |
| Multiline | NA | C | C | C | C | C | C | C | — | — | Shift+Enter handled by every kit composer; Enter-to-send is not configurable in the Vue kit `kit-vue:components/composer/EnhancedComposer.vue:587` |
| Emoji | C | C | C | C | P | P | P | P | APP | kit | 面板插入 `[key]` 并能发送；输入框里仍显示裸 token（Flutter TextField 内联图片的 kit 缺口）。 `kit-flutter:src/components/flare_composer.dart:748-753` |
| Mention | P | C | P | M | P | P | P | P | SDK | kit | 成员选择器写入的全体词改为 `@所有人`；点名 mention 仍不到达（S14） `kit-compose:Composer.kt:205-206` |
| Reply preview | C | C | C | C | C | C | C | C | — | kit | Kit reply strip wired on the three native apps: cancel, chat switch and a successful send clear it; a failed send returns text and strip `flutter:chat_screen.dart:681-682` |
| Rich text | P | C | C | P | C | C | C | P | SDK | kit | Desktop uses the expanded toolbar with the format toggle; rich sends normalise through the core and return the text on failure, which a list always is today (S27) `web:components/ChatArea.vue:96-98, 619-624` |
| Paste image | C | M | M | M | M | M | M | M | DESIGN_SYSTEM | — | Kit rich input handles text/plain paste only (verified) and no app intercepts pasted images `kit-vue:components/composer/ComposerRichMarkdownInput.vue:1032-1037` |
| Drag/drop | C | M | M | M | M | M | M | M | DESIGN_SYSTEM | kit | Kit fileDropEnabled defaults to false and no app handles files-drop `kit-vue:components/composer/EnhancedComposer.vue:142` |
| Attachment | C | C | C | C | P | P | P | P | APP | kit | Attach grid offers image and file with the kit's labels and glyphs; both upload and build by mime type `web:components/ChatArea.vue:214-217, 502-512` |
| Image picker | C | C | C | C | C | C | C | C | — | kit, app | R9-B7c: every app picks up to nine pictures in order through its host picker; the kit pickImages adapter is still unused `kit-vue:shared/platform/contract.ts:77-84` |
| File picker | C | C | C | C | M | M | M | M | APP | kit | Web and Tauri pick files via a hidden input; iOS, Android and Flutter have no file picker `ios:ChatView.swift:31-35` |
| Camera | C | M | M | M | M | M | M | M | DESIGN_SYSTEM | kit | Kit defines a camera action id but no app offers capture `kit-vue:shared/contracts/composer.ts:68-87` |
| Audio | P | C | P | C | C | C | P | P | SDK | kit | The kit mic records and sends through create_audio via send-voice-handler; the core has no voice-note flag or send duration (S13) `kit-vue:components/composer/EnhancedComposer.vue:843-855` |
| Location | C | P | M | M | M | M | M | M | DESIGN_SYSTEM, APP | kit | Fixed demo location removed; the attach panel has no location action `ios:ChatView.swift:51-56` |
| Contact | C | P | M | M | M | P | P | M | DESIGN_SYSTEM, APP | kit | Kit contact action has no contact picker (maturity partial); iOS and Android can only send the user's own card `ios:SocialSession.swift:787-806` |
| Poll | P | C | M | M | M | P | M | M | SDK, APP | kit | Kit poll composer sends what the user entered; its single or multiple choice cannot be sent (S15) `ios:ChatView.swift:182-187` |
| Schedule | P | M | M | M | M | M | M | M | SDK, DESIGN_SYSTEM | kit | `create_schedule` unused by all apps; kit has an action id but no schedule form; SDK has no RSVP or update `sdk:CORE/bindings/contract/dispatch.json:882-912` |
| Task | P | M | M | M | M | M | M | M | SDK, DESIGN_SYSTEM | kit | `create_task` unused by all apps; kit has an action id but no task form; SDK has no status or assignee update `sdk:CORE/bindings/contract/dispatch.json:855-881` |
| Topic | P | M | M | M | M | M | M | M | SDK, DESIGN_SYSTEM | — | No topic or thread action id in the kit (verified) and no thread list API; `create_thread_reply` unused `kit-vue:shared/contracts/composer.ts:68-87` |
| Mini app | C | M | M | M | M | M | M | M | DESIGN_SYSTEM | kit | `create_mini_program` unused by all apps; kit has miniApp action ids but no picker `sdk:CORE/bindings/contract/dispatch.json:748-778` |
| IME | NA | C | C | C | C | C | C | C | — | kit | 输入区按 navigationBars ∪ ime 让位，键盘打开时不再盖住输入框；未在设备上复核 `android:ChatScreen.kt:365-370` |
| Keyboard shortcut | NA | P | P | C | P | M | M | M | DESIGN_SYSTEM, APP | kit | iOS and Android have none; Vue Enter-to-send is fixed and IMAppKit does not use DesktopAppShell shortcuts `kit-vue:components/layout/FlareDesktopAppShell.vue:37-51` |

### Group

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Group info | C | C | C | C | C | C | C | C | — | kit | 窄平板改单面板，群资料是页面而不是浮层；入口不再只在窄布局出现。 `kit-flutter:src/application/application_composition.dart:493-520` |
| Members | C | C | P | C | C | C | C | P | APP | kit | Details load at most 100 members without cursor paging; the kit 群成员 list searches only those loaded `web:social/directory.ts:494-498` |
| Invite | C | C | C | C | C | C | C | C | — | — | Invite failures toast, and 加入群聊 redeems invite codes through join_group_by_invite `web:components/JoinGroupPanel.vue:104-125` |
| Remove | C | C | C | C | C | C | C | C | — | — | Web confirms removal and keeps the dialog open with the error; the kit member sheet itself still emits without asking `web:components/GroupDetailPanel.vue:199-207` |
| Admin | C | C | C | C | C | C | C | C | — | kit | The kit intent carries the new role, and set_group_member_roles failures toast `web:social/directory.ts:614-618` |
| Owner | C | C | C | C | C | C | C | C | — | kit | Owner detection with dissolve versus leave in all apps `ios:GroupViews.swift:140-145` |
| Transfer owner | C | C | C | C | C | C | C | C | — | kit | Wired in all apps with the kit confirmation dialog `web:social/directory.ts:490-491` |
| Mute member | C | C | C | C | C | C | C | C | — | kit | Wired everywhere; iOS mutes indefinitely while Android sends a 24 h muted_until `android:SocialSession.kt:976-982` |
| Mute group | C | P | C | C | C | P | C | P | DESIGN_SYSTEM | kit | 群详情开关发 notifyMode；读不到时显示「暂时无法读取」而不是假装关着。 `flutter:screens/social_action_screens.dart:1151-1170`; `kit-flutter:src/components/flare_group_detail.dart:239-276` |
| Announcement | C | C | C | C | C | C | C | C | — | — | 查看未读已接线：打开服务端点名的未读成员，人数用 total−read `ios:GroupViews.swift:214` |
| Nickname | C | C | C | C | C | C | C | C | — | — | Group nickname via `update_group_member` in all apps; dispatch-only on Tauri `web:social/directory.ts:604-610` |
| Group avatar | P | P | M | M | M | P | P | M | SDK, DESIGN_SYSTEM, APP | — | UpdateGroupRequest has no avatar field although the gateway accepts one; kit GroupDetail emits no avatar edit `sdk:SOC/src/modules/group/domain/model.rs:202-215` |
| Group settings | C | C | C | C | C | P | P | P | APP | kit | Join policy and flags wired; native lack an admin-permission editor and iOS lacks mention-only notify `ios:SocialSession.swift:1292-1296` |

### Search

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Conversation search | C | C | P | C | M | P | P | P | APP | — | Only Tauri filters the conversation list locally; web and native offer global search only `tauri:components/chat/SessionList.vue:93-104` |
| Message search | P | C | P | P | M | P | P | P | SERVER, SDK | kit | In-chat search uses message.search_in_conversation with type and time filters, but only over the local store, with no server search `web:components/ConversationSearch.vue:33-60` |
| Member search | M | P | P | P | P | P | P | M | SDK, DESIGN_SYSTEM | — | Kit 群成员 list searches loaded members, but the web loads at most 100 without paging and the SDK has no keyword filter (S4) `web:social/directory.ts:494-498`; `kit-vue:components/contacts/FlareGroupDetail.vue:253-259` |
| Global search | P | C | P | C | M | P | P | P | SDK | kit, app | 某一来源失败会明说并可重试，不再读成「没有结果」；消息命中仍不跳到那条消息 `android:SocialSession.kt:1171-1228` |
| Search result navigation | P | P | P | P | M | P | P | P | SDK, DESIGN_SYSTEM | kit | Hits open the chat and page back through up to 48 local pages to show the message; no load-around op `web:components/ChatArea.vue:111-132` |

### Media

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Image preview | C | C | C | P | C | C | C | C | — | kit | 未变；本轮只补了选图失败的说法，预览链路不动。 `kit-flutter:src/components/flare_message_content_view.dart:153-165` |
| Gallery | P | C | P | P | P | P | P | P | SDK | kit | R9-B7b: a tapped picture pages through every loaded picture of the timeline on all four kits; no media index for older history `kit-vue:components/messages/timelineImageGallery.ts:44` |
| Video playback | C | C | C | P | C | C | C | C | — | kit | Videos map with resolved source and cover; the kit player plays, with a failed state and retry `ios:SocialSession.swift:1158-1162` |
| Audio playback | C | C | C | P | C | C | C | C | — | kit | audioId resolves to a URL; the kit plays one voice message at a time in the bubble `ios:CoreMediaURLs.swift:46-47` |
| File preview | C | M | M | M | P | P | P | M | DESIGN_SYSTEM | — | Files open outside the app after safeExternalURL, with a toast when they cannot; no in-app viewer `ios:ChatView.swift:253-259` |
| Download | C | C | C | P | C | C | C | C | — | kit | Received files, images and videos download from a fresh media.get_url address through the browser; failures toast. R11: the three native apps save a picture or a video from the preview (gallery / share panel / host channel). R12: they save a received file too — Android to `Download/Flare` through MediaStore, iOS through the system panel where Save to Files lives, Flutter through the host channel it already had, none of them with a new dependency `web:social/store.ts:922-936`; `flutter:lib/host/gallery_save.dart`, `android:GallerySave.kt`, `ios:ChatView.swift` |
| Upload progress | P | C | M | M | M | M | M | M | SDK, APP | kit | localState is passed to the kit, but uploads finish before the message row exists and the core reports no upload progress (S5) `web:social/sdk.ts:323-342` |
| Failure | C | C | P | P | P | C | C | P | APP | kit | 预览/播放器/语音失败态照旧，图片上传与发送失败不再静默 `ios:ChatView.swift:162` |
| Retry | P | C | P | M | M | M | M | M | SDK, APP | kit | Failed sends that reach the timeline resend through message.send; a failed upload leaves no row to retry (no upload retry op) `web:social/store.ts:640-652, 720-733` |

### Multi-device / State

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Unread sync | C | NA | C | C | C | C | C | C | — | — | Server summary is authoritative; apps reload lists on unread events (Flutter subscription uncommitted) `flutter:screens/base_shell.dart:64-70` |
| Read sync | C | NA | P | P | P | C | C | P | APP | — | Peer read receipts show from isRead after event reloads; own read positions roam through the core `ios:SocialSession.swift:1098-1099` |
| Message sync | C | NA | P | C | C | C | C | P | APP | kit, app | 不变；时间线现在开在最新一条并跟随新消息（X27 修复），翻历史保持阅读位置 `kit-compose:MessageList.kt:383-420` |
| Conversation sync | C | NA | C | C | C | C | C | C | — | — | Every SDK event triggers a full list reload in all apps: a performance risk, not a functional gap `ios:SocialSession.swift:249-261` |
| Reconnect | C | C | C | C | C | C | C | C | — | kit | R8-B2：重连后要重建什么由 kit 的 `FlareConnectionRefresh`（`spec/reconnect-refresh-vectors.json`，17 条迁移脚本）决定，五端同一份 —— 丢弃可能过期的信念、重订、重读；被踢/过期是终态，什么都不做。手动重连仍在 `ios:SocialSession.swift` |
| Offline message | C | NA | C | C | C | C | C | C | — | — | Queued and failed sends show pending, sending or failed from core status; offline pull is core-side `ios:SocialSession.swift:1091-1103` |
| Draft sync | C | NA | C | C | C | C | C | C | — | — | R7-B4: every app writes `conversation.update_draft`, which the core syncs as a user setting, and seeds from the summary's `draft` so a draft written elsewhere appears rather than being overwritten `flutter:viewmodels/conversation_signals.dart`; `android:SocialSession.kt` |

### UX states

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Loading | NA | C | C | C | C | C | C | C | — | kit | Chat, details, directory and the first list load show kit loading states; only my QR code reads unavailable while it loads `web:components/ChatArea.vue:594-597`; `web:components/ConversationPane.vue:43-47` |
| Empty | NA | C | C | C | C | C | C | C | — | kit, app | EmptyState used throughout; kit ContactList and GroupList fall back to English empty text `kit-vue:components/contacts/FlareContactList.vue:32` |
| Error | P | C | P | P | P | C | C | P | SDK | kit, app | 转发、表情回应、图片上传、全局搜索的失败现在都有可见结果 `ios:ChatView.swift:428` |
| Offline | C | C | C | C | P | C | C | C | — | kit | 无变化，列出以说明本批未触及连接类单元 — |
| Reconnect | C | C | C | C | C | C | C | C | — | — | 连接通知跟到被 push 的聊天页和圈子 tab；被踢 / 过期在任何一页都看得到并能重新登录。 `flutter:host/connection_notice.dart:15-57`; `flutter:screens/base_shell.dart:196-210` |
| Permission denied | NA | C | P | P | P | P | P | P | APP | kit | 相册权限被拒给出产品文案而不是未捕获异常；kit PermissionPrompt 仍未用，麦克风只有行内提示。 `flutter:screens/chat_screen.dart:441-470` |
| Unsupported capability | P | C | P | P | P | P | P | P | SDK | kit, app | Web hides what it cannot do (no call buttons or coming-soon text); CapabilityBoundary unused; core capability events never reach bindings `web:components/ChatArea.vue:185-187` |

### Settings

| Feature | SDK | Design System | Web | Tauri | Flutter | iOS | Android | Result | Blocking layer | Tests | Evidence / note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Theme | NA | C | C | P | P | C | P | C | — | kit | R11: one theme vocabulary on four kits (`FlareThemeMode`, `spec/theme-mode-vectors.json`) and four apps; web and iOS persist the choice, Tauri and Flutter follow the system without offering one, and Android keeps the choice in memory `tauri:App.vue:71`; `android:SocialSession.kt:577` |
| Dark mode | NA | C | C | M | P | C | P | C | — | kit | The report form is now kit FormSheet, RadioGroup and Textarea on kit tokens, so it follows dark mode `web:components/ReportSheet.vue:6-15, 95-102` |
| Notification | P | C | M | M | NS | NS | NS | M | SDK, APP | kit | Preferences removed because nothing read them; the web raises no browser notification for new messages `web:components/SettingsPanel.vue:14-16` |
| Language | NA | P | P | P | M | P | P | P | DESIGN_SYSTEM, APP | kit | Kit strings follow the host's language (the Vue provider watches it, the Compose labels read the strings table); the SwiftUI recorder keeps English literals and every app hard-codes Chinese `kit-compose:ApplicationComposition.kt:91-108` |
| Appearance | NA | P | P | M | M | P | P | P | DESIGN_SYSTEM | kit, app | 设置行区分 navigation / toggle / action / value；工作区在放不下可用聊天宽度时改为单面板并保留导航栏 `kit-compose:ApplicationComposition.kt:230-243` |
| Account | P | P | P | P | P | P | P | P | SERVER, SDK, DESIGN_SYSTEM | kit, app | Flutter edits name and signature only and lists one fake local device with no revoke; no password change or username `flutter:screens/profile_center_screen.dart:297-305` |
| Privacy | C | C | P | C | P | C | P | P | APP | — | 陌生人开关读出来之前禁用、读失败可重试；仍只有这一项隐私设置 `ios:SettingsViews.swift:204` |

## Tally

135 features per column.

After Batches 5, 6 and 5.4, Round 9 (rich text, B6; albums, multi-image send and the conversation gallery, B7; poll and task intents, B8), Round 10 (the SDK column of both Rich text rows drops to P: S27) Round 11 (the three native apps save a picture, so Media / Message-actions Download moves off M; the theme row says what the four apps really do) and Round 12 (the same three apps save a received file, so Media / Download is C on all three and its Result with them), with the Round 5 re-grade in round brackets and the 2026-09-14 grading in square brackets.

Recounted from the rows at R9-B7. Rounds 6 to 8 moved rows (drafts, typing, presence, message actions and others) without moving this table, so the first figures had fallen behind the rows by up to nine cells per column; they are now the rows' own count. Since Round 10 a gate keeps them there: `tooling/check-feature-matrix.mjs` (in `npm run check`) recounts the rows into the first figure of every cell, checks the feature count, and holds each row to the Result rule and the Blocking layer rule above. The figures in brackets are history and are not checked.

| Column | C | P | M | NS | NA |
|---|---|---|---|---|---|
| SDK | 84 (84) [86] | 35 (35) [33] | 3 (3) [3] | 0 (0) [0] | 13 (13) [13] |
| Design System | 99 (91) [87] | 19 (26) [33] | 9 (9) [6] | 0 (0) [0] | 8 (9) [9] |
| Web | 78 (74) [50] | 31 (33) [40] | 25 (27) [44] | 1 (1) [1] | 0 (0) [0] |
| Tauri | 69 (65) [51] | 35 (35) [50] | 30 (34) [33] | 1 (1) [1] | 0 (0) [0] |
| Flutter | 61 (43) [38] | 40 (46) [31] | 32 (44) [64] | 2 (2) [2] | 0 (0) [0] |
| iOS | 70 (48) [36] | 40 (52) [48] | 23 (33) [49] | 2 (2) [2] | 0 (0) [0] |
| Android | 66 (47) [34] | 43 (53) [51] | 24 (33) [48] | 2 (2) [2] | 0 (0) [0] |
| Result | 60 (44) [27] | 38 (44) [47] | 36 (46) [60] | 1 (1) [1] | 0 (0) [0] |

The Design System column moved in both directions at the re-grade: the Vue and SwiftUI kits gained media defaults, mention spans, date separators, connection notices and the identity card, and lost points where the re-grade found gaps the earlier audit missed (Copy offered on messages with no text, text links with no handler, no rich-text body on the native kits). The two SDK cells that moved are Mention and composer Mention: `create_text` drops mentions by display name (S14).

The three native columns then moved again in the implementation batches: iOS +9 C, Android +6 C, Flutter +5 C, and the Result column with them (+5 C, −5 P). No column moved because a grade was relaxed — every cell that moved names the op it now calls and the failure it now shows, in its own row. The Design System and SDK columns did not move in those batches: the kit changes they carried (semantic icon names, settings kinds, the single-pane rule) are not features the matrix grades, and the SDK gaps they exposed are recorded rather than worked around.

## Top gaps by blocking layer

Only items that block the core IM loop (conversation list, open chat, read, compose, send, receive, reply or reaction or other message action, unread and read) or that are P0 functional bugs. Re-written at the Round 5 re-grade, then again on 2026-09-16 after Batches 5, 6 and 5.4 landed: everything the three native batches fixed has been struck from this list rather than left standing.

### APP

- ~~Drafts reach the core only in the web app; Tauri keeps them in session storage, the natives in memory, so a draft never roams.~~ Closed in R7-B4: the op is wrapped in all four SDK packages and all five apps write through it (FR-132).
- ~~Typing and presence are wired only in web and Tauri; the three native apps neither send nor show either.~~ Closed in R7-B1/B2/B3 (FR-126, FR-131). What remains is one layer down: the gateway relays typing only to subscribers on its own node, and presence is not resubscribed after reconnect (S21).
- No app sends a location, a contact card, a link card, a poll or a schedule from a real picker: the attach panels offer image, file and voice, and the demo payloads were removed in Round 5. (Several images: sent as one album by all five apps since R9-B7c.) `ios:ChatView.swift:51-56`
- Tauri hides conversations archived elsewhere with no archived view, and maps nothing to delivered. `tauri:host/utils/conversationList.ts:164`
- The web app's message search reads the core's local store only, so results stop where the device's history stops (the timeline itself now backfills; search does not). `web:social/directory.ts`

Fixed in Round 5 (was on this list): Flutter group mute wrote an ignored `muted` field; iOS swallowed forward, reaction and image-upload failures and read `search_contacts` array replies as envelopes; the Android moments view model was Activity-scoped and survived sign-out; iOS had no 重新连接; the Tauri app used `media.resolve_access`'s source kind as a URL.

### DESIGN_SYSTEM

- ~~The native kits have no image-group content type, so an album degrades to a count.~~ Closed in R9-B7a: `ImageGroupMessage` on all four kits, one layout rule (`spec/image-group-layout-vectors.json`). (Rich text: drawn from the stored document on all four kits since R9-B6.)
- ~~Poll and task bodies are read-only on every kit: no vote or status intent, so a host cannot wire one even where the SDK could.~~ Closed in R9-B8: all four timelines report `vote` and `taskToggle` when the host takes them. The SDK has no op to act on either (S26), so the apps still pass none.
- Reactions are a fixed set of six quick emoji with no wider picker on the native kits. `kit-vue:shared/constants/messageReactions.ts:5`
- ~~The media host presents one image at a time; there is no gallery of a conversation's images.~~ Closed in R9-B7b: a picture tapped in a timeline pages through the timeline's pictures on all four kits (`spec/image-gallery-vectors.json`).
- GroupDetail models the viewer's notification as a boolean (nullable since Round 5), so mention-only cannot be offered even where the server supports it. `kit-vue:shared/contracts/directory.ts:104`
- Flutter is the one kit whose text links do nothing without a host handler: it has no URL launcher and the lock files are frozen, so `onOpenLink` is the only path there. Registered platform gap, not a defect. `kit-flutter:src/components/flare_message_bodies.dart`

Fixed in Round 5 (was on this list): the SwiftUI and Compose timelines opened at the oldest loaded message and did not follow new ones; the action sheets offered Copy for messages with no copyable text (the core still reports `canCopy` for them — SDK gap S22, below); text links reached no handler on SwiftUI and Compose; the kits took platform glyph types (`ImageVector`, SF Symbol names, `IconData`) in public item models. The group member sheet's server-side search callback (`onSearchMembers`) exists on all four kits and should not have been on this list.

### SDK / SERVER

- Mentions by display name never reach the message: `create_text` resolves them, `build_text` then keeps only spans it finds as a literal `@<userId>` (S14). `sdk:CORE/src/application/services/message_builder.rs:708-726`
- The @me count is a stub that is always 0 and the server conversation summary has no field for it (S1). `sdk:CORE/src/model/conversation.rs:797-798`
- There is no resend op, and the TS `sendMessage` resolves instead of rejecting when the ack reports failure (S2). `sdk:CORE/src/application/usecases/message/send.rs:216-277`
- `message.list` returns no `has_more`, so every app infers the end of history from an empty page (S17). `sdk:CORE/bindings/contract/dispatch.json`
- No op lists a conversation's pinned messages, and pin, unpin and mark events never reach the bindings' event payload (S20). `sdk:CORE/bindings/shared/src/event.rs:352`
- `message.action_availability` reports `canCopy` for image, voice and file messages, because `text_for_storage` returns a preview token for them (S22). `sdk:CORE/src/domain/message_actions.rs:82-85`
- `social.group.list_members` has no keyword filter, so member search is client-side over the loaded page (S4). `sdk:SOC/src/ffi/ops/group.rs:37-43`
- `message_builder.create_audio` takes no duration, so a sent voice message carries 0 (S13). `sdk:CORE/bindings/contract/dispatch.json`
- `media.get_url` returns URLs that expire after an hour and has no batch form (S12). `sdk:CORE/bindings/contract/dispatch.json`
- `create_vote` carries no single or multiple choice and there is no cast or results op (S15, S26; design in `sdk-change-proposals.md`). `sdk:CORE/bindings/contract/dispatch.json:828-854`
- Rich-text normalisation fails on any tight Markdown list, the form the kits' list buttons write, because `next_block` consumes the item's end with its text (S27); it also drops tables, underline, image addresses and autolinked, email and reference links (S25). Patch with tests in `sdk-change-proposals.md`. `sdk:CORE/src/content/rich_doc_v2/from_markdown.rs:111-115`
- The Swift and Kotlin wrappers have no IM-only session restore, so those apps sign in on every launch (S8); the Flutter SDK has no code login, reset or verified sign-up (S9). `sdk:SOC/src/ffi/ops/auth.rs:46-72`
- Proto has no DELIVERED status and the core's derived delivery state is not bound, so no app can show delivered. `sdk:CORE/src/domain/message_actions.rs:323-365`
- `conversation.delete` is local-only: the conversation returns on the next summary sync, and the server's per-user delete is not client-reachable. `sdk:CORE/src/infrastructure/persistence/sqlite/conversation_repo.rs:1149-1189`
- The server authorizes no message action: any member can recall without a time limit, edit, react, pin or delete for everyone. `sdk:ROUTE/application/handlers/event_routing_handler.rs:42-87`
- ~~Typing reaches only subscribers on the same gateway node; presence is not resubscribed after reconnect and a failed web lookup reads as offline (S21).~~ All three closed: R8-B1 broadcasts the aggregated typing frame to the other gateway instances (FR-135); R8-B2 re-subscribes and re-reads presence when the connection returns (FR-134); R7-B3 made a lookup the core could not answer read as unknown rather than offline, with a golden table on four SDK packages.

## Resolved audit disagreements

- **Copy.** The Tauri audit graded it C; the Web audit said "likely hidden". Kit availability requires `content.data.text` and core serializes flattened content, so Copy is hidden in both Vue apps. Tauri changed to P.
- **Kit maturity versus source.** Reaction "existing" renders inert spans (P). Translate "existing" has no menu action (P). Presence "existing" is absent from the Vue row model (P). Calendar event and mini app "missing" both have card views (C). Topic "missing" is confirmed: thread messages fall back to a generic info card. Task "partial" is confirmed: the card is read-only.
- **iOS reply.** The native audit's grading table says the kit offers replyTo and onSwipeReply; its appendix says the message model lacks replyTo. Both hold: swipe-to-reply and a composer strip exist, but `FlareMessageData` has no replyTo, quote or reactions, so the iOS kit cannot render replies (Design System P).
- **Tablet message menu.** Confirmed: the tablet profile uses the dropdown without a hover toolbar, and the dropdown skips reply and forward.
- **Tauri mention prefix.** Graded P by its audit. The code keys on `mentionMe`, which the SDK hardcodes to false, so it never shows; kept P as a dead path.
- **restore_im_session.** The native audit calls it an unused SDK op. It exists only in `sdk-spec/modules/auth.json` and as a Tauri host command, with no social dispatch arm, so native warm start is an SDK gap.
- **Web op names.** Confirmed: core message dispatch accepts `add_reaction` and `edit_text_by_message_id` and rejects any other name as unsupported.
- **iOS content keys.** The audit said "likely". Confirmed in code: core `ImageElem` nests `source` and `thumbnail`, and iOS reads a top-level `url`.
- **Translate.** The Tauri audit graded M. Changed to NS like the other apps, because the SDK has no translate API.
- **Message search (SDK).** `audit-sdk.md` rates it COMPLETE (local-only); graded P under this legend.

### Round 5 re-grade (2026-09-16)

- **Copy on media.** The core's `message.action_availability` says `canCopy` for image, voice and file messages, against its own comment, because `text_for_storage` returns a preview token for them. Android then showed a 复制 item that did nothing and Flutter copied an empty string. Recorded as SDK gap S22; the kits stop offering Copy without copyable text.
- **Delete for self.** `message.delete` is `delete_for_self` with the user-private scope, which the core syncs to the user's other devices. The apps' "only this device" copy was wrong and is now "从你的所有设备上删除…".
- **Mention-all token.** The core accepts `all`, `everyone`, `全员` and `所有人`. The Compose picker wrote `@全体成员`, so no mention-all reached the server from Android.
- **History paging.** `message.list` reads the core's local store, so "history paging works" held only where the device had already synced. The natives call `sync.conversation_history_backfill`; the web app did not until Round 5.
- **Tauri media.** The screen inventory recorded received media as opening in Tauri; the app used `media.resolve_access`'s source kind (the string "remote") as the address, so nothing loaded. Fixed after the re-grade.
- **Pane collapse (FR-083).** No matrix row covers how many panes a window shows or when the chat carries a back control either. The rule landed anyway: below navigation + list + a usable chat (752 px with a rail) the workspace shows one pane and reports it to the host — **on all four kits and all five apps** by 2026-09-16, with nine cases in the shared vectors. The iOS case was a defect rather than a refinement: `horizontalSizeClass` stays `.regular` in an iPad Split View, so a 700 pt window squeezed the chat to about 380 pt.
- **Timeline anchoring.** No matrix row covers where a conversation opens. The SwiftUI and Compose lists opened at the oldest loaded message; the finding is recorded as X27 and fixed on all three native kits, with tests that assert what is on screen rather than widget order.
