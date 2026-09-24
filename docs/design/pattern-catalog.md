# IM Interaction Pattern Catalog

Date: 2026-09-15 (Round 5). Scope: interaction patterns that every Flare IM surface follows, on four kits, as used by the five flare-social reference apps. Layout regions (workbench, chat workspace, search workspace) are defined in `docs/composition-patterns.md` and `spec/composition-patterns.json`; this page covers behaviour.

Each pattern names the problem, the rules, the kit API on each platform, the states it must cover, and where a reference app uses it. The "Replaces" line records the defect that made the pattern necessary.

## 1. Controls follow handled intents

**Problem.** A menu item, toolbar button or reaction pill that does nothing when pressed teaches users the product is broken.

**Rules.**
- A control appears only when the host handles its intent.
- Capability (can this message be recalled?) and wiring (does this screen implement recall?) are separate inputs; both must allow the control.
- An empty toolbar or menu is not rendered.

**API.**
- Vue: `FlareMessageList` masks menu actions, the hover toolbar and reaction pills by the listeners the host attaches (`@reply`, `@react`, `@forward` …).
- Flutter, iOS, Compose: nullable callbacks (`onReact`, `onBack`, `onToggle`); a null callback draws no control.
- Sheets: `MessageActionSheet` takes `availability` plus `hiddenActions` for standard actions the screen does not implement.
- Headers: `ConversationHeader` `capabilities.availableActionIds`; the identity is a button only with an identity `action`.
- Conversation rows: no menu without `capabilities`, and then the browser's own context menu is left alone.
- Host actions such as report: Vue `actions` on `FlareMessageList` (`FlareMessageActionExtension` with an `available` rule per message) plus an `@action` listener; ordinary actions sit before Delete and destructive ones after it.
- Composer: the voice tile and microphone appear only with a voice handler.
- Group detail: the message button appears only when the host opens the chat; the announcement read bar offers "view unread" only with a handler; rows the viewer can edit carry a chevron, the rest read as values.
- Contact detail: message, voice and video, the editable remark and description rows, the star switch, block and remove each appear only with their handler, so a stranger's profile shows no friend-only actions (Vue; natives in Batch 4).
- Moments: the author, likers and comment rows are buttons only when the host handles selecting them; otherwise they are text.
- Timeline polls and tasks: an option is a control only with `vote`, a task's checkbox only with `taskToggle`, and neither while the list is selecting (Round 9, four kits).

**Used by.** Web `ChatArea.vue` (attaches only the intents it wires, adds Report on other people's messages); Android `ChatScreen.kt`, Flutter `chat_screen.dart` and iOS `ChatView.swift` (hide reply, pin, edit and the other actions they do not implement).

**Replaces.** A 14-flag `menuConfig` table in the web app, and toolbar reaction buttons shown to hosts without a reaction handler.

## 2. Message availability comes from the core

**Problem.** "Who can recall", "can a failed message be pinned" and "is there text to copy" were decided differently on each platform. Android offered recall on other people's messages and reactions on pending ones.

**Rules.**
- The core answers `message.action_availability` with `{ canReply, canForward, canCopy, canEdit, canDelete, canRecall, canPin, canUnpin, canReact, canMultiSelect, canSave, canResend }`.
- The screen passes only situational inputs it owns: `multiSelectMode`, `isPending`, `isFailed`, `isPinned` and `isConnected`.
- A failed read offers nothing rather than guessing.
- The reaction strip follows `canReact`, including a host-supplied reaction list.

**API.** `FlareMessageActionAvailability.fromJson` (Compose, Flutter) and `FlareMessageActionAvailability(json:)` (iOS) read the core answer. Vue derives availability from the same rules in `messageActionAvailability` because the web kit renders menus inline.

**Used by.** Android `SocialSession.actionAvailability`, iOS `SocialSession.actionAvailability`, Flutter `BaseSocialClient.actionAvailability`.

## 3. Destructive confirmation with busy, error and retry

**Problem.** Recall, delete, clear history, block, remove a member and leave a group ran immediately in several apps. Where apps did confirm, each built its own dialog state.

**Rules.**
- The dialog names the consequence (description) and the object (target) on its own line.
- The confirm button uses the action's verb ("删除", "撤回"), never a generic OK.
- The step runs while the dialog shows busy; back and barrier dismissal are blocked while busy.
- A failure keeps the dialog open with the error so the user can retry or cancel.
- The caller learns the outcome: confirmed and succeeded, or cancelled.
- One confirmation at a time.
- A composite confirms only a step it presents itself. `FlareGroupDetail` confirms an ownership transfer; the host confirms removing a member, leaving and dissolving, because it owns the write, its busy state and its error.

**API.**
- Vue: `const confirm = useFlareConfirm(); await confirm({ title, description, target, confirmText, action })`.
- Flutter: `await FlareDangerConfirm.show(context, title:, description:, target:, confirmText:, action:)`.
- iOS: `await feedback?.confirm(FlareConfirmOptions(...))` with `@Environment(\.flareFeedback)`, presented by `flareFeedbackHost(_:)` at the app root.
- Compose: `DangerConfirm` in composition, with `busy` and `error` held by the screen.

**Used by.** Web (8 steps), Tauri (13 sites plus removing a member and leaving a group), Flutter and Android chat (recall and delete), iOS (recall, delete, block, delete friend, delete a moment, sign out, sign out a device, remove a member, leave or dissolve a group), and removing a member and leaving a group in every app.

## 4. Transient feedback

**Problem.** Apps grew their own toast hosts: web had one timer, Tauri had ten per-panel hosts, and Flutter has a helper with 19 call sites. Toasts were cut short or never dismissed.

**Rules.**
- The provider owns placement, stacking and timers, not the screen that raised the toast.
- At most three are on screen, and a new one pushes out the oldest.
- Info and success stay 4 seconds; danger stays 6 seconds; a toast with an action can be sticky.
- Failure text says what did not happen and what to do ("撤回失败，请重试").
- Feedback reports what actually happened. A forward that reached two of three conversations says so.

**API.**
- Vue: `useFlareToast()`, rendered by `FlareUiProvider`.
- Flutter: `FlareToast.show(context, message: ...)`.
- iOS: `feedback?.toast(...)` with `@Environment(\.flareFeedback)`, presented by `flareFeedbackHost(_:)`.
- Compose: `LocalFlareToast.current.show(...)` inside `FlareToastHost`.

Every presenter keeps the same queue, durations, close control and polite announcement.

**Used by.** All five apps, for all feedback; no app owns a toast host.

## 5. Stale content with retry

**Problem.** A failed refresh replaced the inbox with an empty list (web, Flutter). The user saw "no conversations" instead of "could not refresh".

**Rules.**
- A refresh failure keeps the rows on screen and shows a warning banner with a retry action.
- Only a first load that fails with nothing to show uses the error state, with retry.
- A successful read clears the failure.
- Loading, empty, error and ready are distinct states; empty never stands in for error.

**API.**
- Vue: `FlareConversationListContainer` `state` plus the `#status` slot with `FlareStatusBanner`.
- Flutter: `FlareConversationListContainer` `state` and `onRetry`, with a `FlareStatusBanner` in `filters`.

**Used by.** Web `ConversationPane.vue`, Flutter `base_shell.dart`.

## 6. Optimistic send and failure recovery

**Rules.**
- The bubble appears on the next frame. Status goes sending, then sent or read; a failed send is never shown as read.
- Receipts are projected from core state: proto status 4 is failed; status 1 without a conversation sequence is sending; read comes from `isRead`.
- A failed message offers retry when the host wires resend. Retry re-sends the stored message with the same client id, so the row stays in place.
- A send that fails before the message exists gives the composer text back, unless the user has already started typing again.

**API.** `status` or `lifecycle` on the message model (four kits). Resend: Vue `@resend`, Compose `onResend`. Composer text: Vue `v-model`, Flutter `controller`.

**Used by.** Web (resend, rich-send restore), Flutter (text restore). Each app has its own status projection function; the core should provide it once (friction log Appendix B).

## 7. Recalled message notice

**Problem.** The core keeps a recalled message's content and only flags it. Native bubbles ignored the flag, so recalled text stayed readable in three apps.

**Rules.**
- A lifecycle mutation outranks every other state (spec `messageLifecycle.precedence`).
- A recalled message renders a centred notice in place of its content. "你撤回了一条消息" when it is yours; "{name} 撤回了一条消息" in a group; "对方撤回了一条消息" in a direct chat.
- The notice has no status, avatar, reactions, selection, long-press or swipe-reply.
- It ends the sender's grouping run.
- It is a quiet chip: tertiary surface, regular weight, no border or shadow, the same as system notices, so a notice never outranks the messages around it.

**API.** Vue `isRecalled` on `MessageLike`. Flutter, iOS and Compose: `lifecycle` mutation `recalled` on `FlareMessageData` (`isRecalled` computed). Strings: `messageRecalledSelf`, `messageRecalledPeer`, `messageRecalledGroupOther`, overridable per host.

**Used by.** All five apps map `isRecalled` or proto status 5.

## 8. Reaction toggle

**Rules.**
- Tapping an existing reaction pill toggles the viewer's own reaction; the picker and the sheet strip use the same toggle.
- The pill shows selected when the viewer is among the reactors (`aria-pressed` on web, a selected trait on iOS).
- Pills are display-only labels when the host does not handle reactions, and they never toggle in multi-select mode (a tap selects the row).
- The strip is offered only when `canReact` allows it.
- The default quick set, the same on every platform: 👍 ❤️ 😂 😮 😢 🎉. Hosts may override it.

**API.** Vue `@react(messageId, emoji)`. Flutter, iOS and Compose: `onReact(message, emoji)` on `MessageList` and `MessageBubble`; `ReactionSummary` under the bubble.

**Used by.** Web store `reactTo`, Android `toggleReaction`, iOS `toggleReaction`, Flutter `toggleReaction`: `message.remove_reaction` when already reacted, `message.add_reaction` otherwise.

## 9. One message identity

**Rules.**
- A message's key is its client id when present, otherwise its server id. The server id arrives only with the ack; keying by it re-keys the row and loses scroll position.
- Every intent (reply, react, recall, resend) carries that key, and hosts look messages up through the same rule.
- Core message ops resolve either id.

**API.** Vue `resolveMessageId` and `findMessage` on `@flare-im/vue-ui/contracts`. Native apps apply the same rule in their mappers.

**Used by.** All five apps.

## 10. Phone single-pane navigation and system back

**Rules.**
- Wide layouts place list, conversation and detail side by side. A phone shows one of them, chosen by the host's navigation state, from the same slot content.
- The chat header carries the back control on phone; there is no separate back bar.
- System back runs the innermost visible back control. A screen without a back control leaves back to the host.
- Bottom navigation hides on secondary pages (an open chat, a detail page), from the depth the destination reports rather than a host formula.
- The platform back (Android back, a phone browser's back when the host opts in) closes the layer opened last first: a sheet, a preview, in-chat search, then the chat. A layer claims back only while it is on screen and its host handles closing it, so back is never captured by something the user cannot see.

**API.** `activePane` on `AppLayout` inside the destination, and the depth a destination reports to hide the phone tab bar (§34; `IMAppKit`'s own `activePane` and `hideMobileNavigation` were removed in Round 9); `showBack` and `onBack` on `ConversationHeader`; `onBack` on Compose `FlareScreen` and `FlareGroupDetail`, which register system back when the platform declares `nativeBack`. Vue: `useFlareNativeBack(active, onBack)`, used by ConversationHeader, FlareScreen, FlareResponsiveLayout, FlareBottomSheet and the sheets built on it, the message action sheet, image and video previews, the merged-forward drawer, FlareDangerConfirm and the media send preview; `createWebPlatformAdapter({ historyBack: true })` implements `onNativeBack` with one marked history entry.

**Used by.** Web `MainView.vue` and `App.vue` (history back), kit `examples/vue`, Android `FlareSocialApp.kt`.

## 11. Time that stays readable

**Rules.**
- Timeline separators are absolute and localized: a clock for today, "昨天 14:05" for yesterday, the date otherwise, with the year only when it differs.
- In-bubble times on native threads, which have no separators yet, keep the day beside the clock for anything older than today.
- Conversation rows use short forms: a clock for today, "昨天", then the date.
- Clocks follow the locale's hour cycle: 09:05 in 24-hour locales, 9:05 AM in 12-hour ones.
- Feeds use relative times up to a week ("3 分钟前"), then the date.

**API.** Vue `formatMessageTime`, `formatConversationTime`, `formatRelativeTime` and `timelineDateLabel` on `@flare-im/vue-ui/utils` (the bubble, the row and the timeline use them). Flutter, iOS and Compose: `FlareTimeFormat`. Native apps pass the formatted `timeLabel` and `sentAtMs` (used for grouping).

**Used by.** Web (kit separators, rows, bubbles and moments), Android, iOS and Flutter mappers.

## 12. Capability-filtered header actions

**Rules.**
- The header offers only actions the host can perform (`capabilities`).
- The host may promote one action to primary; compact widths cap primary actions and move the rest to overflow.
- The identity (avatar, title, subtitle) stays readable at every width.
- Details open from the identity: with an identity `action`, avatar, title and subtitle are one button named "{title}, {action}".
- A toggle action (search open, details open) shows its pressed state.

**API.** `ConversationHeader` `identity` (with `action`), `capabilities`, `configuration.actionOverrides` (with `pressed`) and `compactMaxPrimaryActions` (four kits).

**Used by.** Web (identity opens details; search pressed while open), Tauri (search and details pressed; add member and read receipts in overflow), iOS and Flutter (identity opens details), Android (group details).

## 13. Sheets, dialogs and drawers follow the input

**Problem.** Forms and panels slid up from the bottom edge of a 1440 px desktop window, far from the pointer that opened them.

**Rules.**
- On phone form factors a sheet rises from the bottom, with a grip.
- On pointer devices the same content is a centred dialog.
- Long-lived side panels (settings, profile, search) are drawers on the inline end, full height.
- All three take focus on open and return it to the opener on close; Escape and the scrim dismiss them unless the step must not be interrupted; motion is reduced when the user asks.

**API.** Vue `presentation` on `FlareBottomSheet` and `FlareFormSheet`: `auto` (default; the platform `bottomSheet` capability decides), `sheet`, `dialog`, `drawer`. Flutter `FlareBottomSheet.show` and `FlareDialog.show`; iOS `flareBottomSheet(item:)`; Compose `BottomSheet`.

**Used by.** Web and Tauri forms (dialogs at desktop widths); Tauri settings, privacy, search and profile (drawers); Flutter (10 sheets, 7 dialogs), iOS (7 kit sheets, plus the moments history range, theme and language pickers since Round 4) and Android (message sheet, audience and profile editor).

**Replaces.** Bottom sheets on desktop, and Flutter's transparent route presenters.

## 14. Where unread messages start

**Rules.**
- Opening a conversation with unread messages marks the first one with a divider that counts the unread messages from others.
- The divider starts a new sender run, so the first unread message shows its avatar and name.
- First-load loading, an empty conversation and loading older pages are separate states.

**API.** Vue `unreadFromId` on `FlareMessageList` (default `FlareUnreadDivider`, replaceable through `#unread-divider`); `#empty`, `#header` and `#footer` slots; the footer keeps a reader at the tail while it grows (typing indicator).

**Used by.** Web (unread position from the count at open; loading and empty states), Tauri (typing indicator in `#footer`).

## 15. Selection mode in lists

**Rules.**
- In selection mode a row is a checkbox named by its title; it opens nothing and offers no menu.
- A trailing control on a row (Remove, Withdraw) is a separate button and never selects the row.
- Outgoing friend requests show their pending state and a Withdraw action only when the host handles it.

**API.** Vue `selectable` with `selectedIds` / `selected` and `toggleSelect` on `FlareConversationList`, `FlareConversationRow`, `FlareContactList` and `FlareContactItem`; `#trailing` on contacts; each request's `direction` and the `withdraw` event on `FlareNewFriendRequests`. Flutter, iOS and Compose: the same props with `trailingBuilder` (Flutter) or `trailing`.

**Used by.** Tauri batch conversation management and group picker; web create group and blocked list; iOS and Android friend screens; the kit's group invite picker.

## 16. Search entry and result navigation

**Rules.**
- An inbox search field that opens a search screen is one button named by its placeholder, not an inert input under an overlay.
- A message hit opens its conversation at that message, paging history when needed; a group hit opens the group conversation.
- Result rows are keyed by kind and id, so a user and a group with the same id stay separate.

**API.** `readOnly` and `activate` (`onActivate` on native) on SearchBar (four kits). Vue `target` (`conversationId`, `messageId`) on `FlareSearchResultItem`; `scrollToMessage` on `FlareMessageList` for the jump.

**Used by.** Web inbox and global search, iOS conversation list, Android conversations.

## 17. Small menus

**Problem.** "New", "more" and context menus were built four ways: naive-ui dropdowns inside the Vue kit with options that were plain divs and a focus that never moved, a bottom sheet with settings rows in Tauri, a Material dropdown in the Android app and a hand-written SwiftUI `Menu` in iOS. One of them silently dropped every pick (FR-071).

**Rules.**
- Every menu draws the kit's one action descriptor, `FlareActionItem`, in host order; a separator comes where the group changes.
- Hidden actions are left out; unavailable ones stay in place, announced as disabled with their reason; toggles carry a check; destructive ones use the error text colour.
- Choosing closes the menu first, then reports the id. Escape or back closes it and returns focus to the trigger.
- On pointer devices the menu is anchored to its trigger or the pointer; on phones (Vue, Flutter) it is a bottom sheet titled with the menu's name. iOS and Android use their native anchored menus.
- A menu without visible actions never opens.

**API.** Vue `FlareActionMenu` (`items`, `label`, the trigger as its default slot, or `open` with `x` / `y` for a context menu). Flutter `FlareActionMenu(builder:)` and `FlareActionMenu.show(context, items:, label:, anchor:)`. iOS `ActionMenuView(items:accessibilityLabel:onSelect:label:)`. Compose `ActionMenu(expanded, items, onDismiss, onSelect)` inside the trigger's `Box`.

**Used by.** The kits' conversation row, header and message menus; the Tauri new menu; the iOS toolbar menu; the Android overflow menu on contacts, contact details and group details.

**Replaces.** Four menu implementations and the Tauri settings-list sheet used as a menu.

## 18. Keyboard navigation in the timeline

**Problem.** Every bubble and three hover-toolbar buttons per message were Tab stops, so a keyboard user tabbed through the whole history to reach the composer, and the desktop focus ring was hidden under a hover shadow.

**Rules.**
- One message is in the Tab sequence: the one focus was last in, else the newest message that opens a menu.
- ArrowUp and ArrowDown move between messages, Home and End go to the first and last loaded message; Enter or Space opens the message menu, and Escape returns focus to the message.
- Hover controls repeat what the menu offers, so they join the Tab sequence only while focus is inside that message; content controls (links, voice play, files) stay in the sequence.
- A focused message is named by sender and time and described by its content, and draws an outline in `borderSelected`.

**API.** Vue `FlareMessageList` (internal `timelineFocus`); a standalone `MessageBubble` keeps its own Tab stop. Natives keep platform focus.

**Used by.** Web and Tauri chats.

## 19. Connection state and recovery

**Rules.**
- Connected shows nothing. Connecting and reconnecting say so with progress; offline waits for the network; disconnected offers 重新连接 only when the host can reconnect.
- Kicked and expired are final: the core does not reconnect, so they always offer 重新登录, which clears the local session and returns to sign-in even when the logout request fails.
- The notice sits above every tab, not inside one pane.
- A cold start whose SDK cannot load keeps the stored session; only a session the SDK rejects is cleared.

**API.** Vue `connectionNotice` (`./utils`), Flutter `flareConnectionNotice`, iOS `FlareConnectionNotice.resolve`, Compose `flareConnectionNotice`; rendered with each kit's status banner.

**Used by.** Web and Tauri main views, Flutter base shell, iOS root view, Android app shell.

## 20. Mentions

**Rules.**
- Typing "@" at the start of a word, or the mention tool, opens the member picker with the roster; the picked person replaces the "@" as `@<display name> `.
- The picker keeps focus in its search field: the first match is highlighted, arrows move it, Enter picks it, the Enter that commits an IME composition is ignored, Escape closes.
- The core resolves mentions from the text against the conversation roster; apps do not build mention entities. Display names must be the roster names the core knows.
- Mentions of the reader and of everyone are tinted in bubbles.

**API.** Vue `FlareMentionPicker` inside `FlareComposer` (`mentionCandidates`); Flutter, iOS and Compose composer `mentionCandidates` with their pickers; `textMentionSpans` and the native span converters for display.

**Known gap.** The core keeps a mention only where the literal `@<userId>` appears, so people mentioned by name get no span and no @me (SDK gap S14); mentions do not work end to end until it is fixed.

## 21. Reading width on wide panes

**Rules.**
- Profile, settings and feed pages keep their header and content in a centred column on wide panes; the page background still fills the pane.
- Lists that drive a detail pane use list and detail panes instead of a wide column.

**API.** Vue `FlareScreen` `readable` (`--flare-component-screen-reading-width`, 720 px).

**Used by.** Web 我, 圈子, 设置 and 通讯录 pages.


## 22. One pane below a usable chat width

**Rules.**
- A workspace shows the list beside the chat only while the chat keeps its minimum width: navigation + list + 360 px. With a 72 px rail and a 320 px list that is 752 px; below it the workspace shows one pane at a time and keeps the rail.
- The pane that shows is the one the host marks active, the same slots the wide layout places side by side; a detail becomes a page rather than an overlay.
- The shell reports the presentation it actually uses, so the host can show the chat's back control instead of guessing from the window width.
- Text scale counts, for the chat only: its minimum is 360 times the text scale, while the rail, list and detail keep the widths they are drawn at. 200 % text needs a 720 px chat.
- It is the same rule `ResponsiveLayout` uses (FR-110): no device floors, one vocabulary, one report.

**API.** Vue `resolvePaneMode` / `paneModeMinWidth` / `resolveWorkspacePresentation` (`./contracts`), `FlareAppLayout`, `FlareIMAppKit` and `FlareResponsiveLayout` `layoutChange`; the same names on SwiftUI and Compose, `flarePaneModeForWidth` / `flarePaneModeMinWidth` on Flutter. The shared rule lives in `spec/application-layout-vectors.json` (`panes`, then `cases`).

**Used by.** All five reference apps: the chat header's back control follows `layoutChange` from the `AppLayout` inside the messages destination (§34).

## 23. A settings row says what it is

**Rules.**
- `navigation` opens a page or a picker: a button with a chevron, and the current value as its detail.
- `toggle` is a switch.
- `action` runs in place (clear history, sign out): a button, no chevron, `danger` when it destroys something.
- `value` is information: not a button, no chevron, no hover, and it ignores taps. Assistive technology reads it as one line of text.
- A setting whose value could not be read is a `value` row that says so; a switch never guesses "off".

**API.** Vue `FlareSettingKind` on `FlareSettingsItem`, rendered by `FlareSettingsRow` for both `FlareSettingsList` and `FlareProfilePanel`; `FlareGroupDetailModel.myMuted` / `myPinned` accept `null` for "could not be read".

**Used by.** Web settings and me pages, Tauri chat settings panels, the kit's contact and group detail. The three native kits follow in Batch 5.

## 24. Search is a palette, not a takeover

**Rules.**
- On pointer devices global search opens as a centred panel over the app: the app stays visible behind a scrim, Escape and the scrim close it, and the field takes focus.
- On phones search is a full page with its own back control.
- A failed source says so and offers a retry; partial failures keep the results that did arrive under a warning.

**API.** Vue `FlareBottomSheet` `presentation="dialog"` with `--flare-component-sheet-dialog-width` for the palette width; `FlareSearchBar` and `FlareSearchResults`, or the composed `FlareSearchPanel`.

**Used by.** Web global search (palette on desktop, page on phones), Tauri global search (drawer), in-conversation search on both.

## 25. What a message says in one line

**Rules.**
- A conversation row, a reply strip and a bubble's quote describe a message the same way: its own text when it has one (the text itself, an image's description, a link card's title, a task's title), otherwise a word for what it is — `[图片]`, `[语音]`, `[文件] 报价单.pdf`, `[转发] 3 条消息`.
- The words belong to the kit's strings table (`preview.*`), never to an app. Four apps writing `[图片]` in four places is how the same image ends up described three different ways.
- A summary can be empty, and a conversation row may then show nothing. A reply strip and a quote never show a blank line: they fall back to `preview.message`.
- The **sender** computes the summary and sends it with the reply (`quotedTextPreview`), so a receiver that never loaded the quoted message still reads the same line.

**Rules (markdown).** A preview is text, not a renderer: marks are stripped and never interpreted. `**周报**已发出` reads as 周报已发出, a link keeps its words and loses its target, an image becomes the `preview.image` term with its alt text, and a fenced block keeps the code inside it. The pass runs over every text preview, which is why `user_id_value` has to survive it. Markdown first, pack keys second, so a line that is both marked up and full of pack tokens reads the same everywhere (`spec/markdown-preview-vectors.json`).

**Rules (emoji packs).** A pack message reads as the pack's name in the reader's language, never as its key: 一百分, not `hundred_points`. A key the shipped table does not know falls back to the key itself, and a body with no key at all falls back to the `preview.emoji` term. The same pass runs over a plain line that carries `[pack_key]` tokens — a conversation row, a reply strip, the core's own preview string — because those places are text, not pictures; the bubble draws the image instead.

**API.** Vue `previewTextFromMessageContent` / `displayTextFromStoredPreview` (`./utils`) and the `preview.*` keys; the three native kits implement the same rule over their own content models. The shared table is `spec/message-preview-vectors.json` (31 cases), read by all four kits' tests; the emoji cases are the only ones whose expectation differs by language, which is what holds the column rule. The pack names come from `emoji-locales.json`, the same file in all four kits, through `emojiLabel` / `localizePackKeysInText`. Each summary takes an optional locale and otherwise reads the device's.

**Used by.** Reply strips and quotes on five apps; conversation rows on web and Tauri.

## 26. Tapping a quote goes back to the message

**Rules.**
- A quote whose message is on screen is a control: tapping it takes the reader to that message — centred, animated unless the reader asked for less motion, and the timeline stops following the newest message.
- A quote whose message is not loaded is still a control. The host pages history until it arrives, then asks the list to show it. **One tap**, not two.
- The list answers whether it had the message, so the host can tell "you are looking at it" from "it is not in this conversation's history" and say the second one out loud rather than doing nothing.
- A quote names the message it quotes by the core's id for it — the id every other client knows. A row answers to that id and to the one it is drawn with, so the host hands the list exactly what the list gave it and translates nothing.
- The answer is about the pass the list last drew, so the host yields one of its own builds before asking.
- **The trip is one algorithm, not one per app.** Ask the list first, so a message already on screen reads no history; while it is not shown, there is history left, the last page brought something in and fewer than 24 pages have been read, read one page, let the list draw, and ask again; when the history or the budget is spent, let it draw and ask up to 6 more times, because the rows of the last page may not be drawn yet. It ends as `shown`, `notInHistory` or `cancelled` — and `cancelled`, for a reader who has left the conversation, says nothing at all.
- The host still chooses the words for a miss: a page that failed and a message that is genuinely gone read differently, and only the host knows which happened.
- **The row that was found says so.** Landing is not enough: the row the jump reached is marked for one window (1600 ms) with a ring of the primary colour behind the bubble, strongest as the list starts moving and gone as the window closes. One row is marked at a time; a second jump moves the mark. Reduce Motion holds the ring still rather than removing it — a reader who asked for less motion still needs to be told where the jump landed, and a mark that only exists as an animation is no mark at all for them.
- The mark has a spoken half. A landed jump is announced — the sender and the same one line a reply strip would show — so a reader who cannot see the ring is told the same fact: which row this is, and what it says.
- Where a platform can move the reading cursor without changing how everyone else navigates, the jump takes the reader there as well: Vue through the timeline's roving tabindex, SwiftUI through `@AccessibilityFocusState`. Flutter and Compose do not, because neither has an accessibility-only cursor and moving it would mean making every row focusable — a change to everyone's keyboard and DPAD navigation for a need the announcement already meets. A jump that found nothing is the host's to say, because only the host knows whether a page failed or the message is gone.

**API.** The trip is `flareLocateMessage` (Vue, Flutter, Compose) and `FlareLocate.run` (SwiftUI), over five callbacks — `showInList`, `hasOlder`, `readOlder`, `settle`, `isCurrent` — with the budgets and the stop conditions in `spec/locate-orchestration-vectors.json`, whose 13 scripted runs every kit's tests replay, counting asks and pages rather than only outcomes. The mark's window and its three stops are `spec/locate-highlight-vectors.json`, read by every kit's tests — Vue's stylesheet holds the same numbers (`.message-row--locating`), and the three native kits compute them (`flareLocateHighlight`, `FlareLocateHighlight.resolve`, `locateHighlight`) and draw the ring from inside the list, with nothing for a host to configure. Vue `FlareMessageList.scrollToMessage(id)` on the component instance; Flutter and SwiftUI `FlareMessageListController`, Compose `FlareMessageListState` with `rememberFlareMessageListState()`, all passed to the list (`controller`, Compose `state`) and all spelling the method `scrollToMessage`. The return is each platform's idiom for one answer: sync on Flutter and SwiftUI, a promise on Vue, suspending on Compose.

**Used by.** The five apps' chat timelines. Centring is one rule per kit, at the bottom of the locate path, so a tapped quote and a host-driven `scrollToMessage` land the row in the same place: `block: "center"` on Vue, `alignment: 0.5` on Flutter, `anchor: .center` on SwiftUI, and on Compose an offset computed from the viewport and the row's height, aimed with an estimate and corrected once the row is laid out (FR-113). A row at least as tall as the viewport starts at the top on every platform — there is nothing to centre, and pushing it down would hide the beginning the reader came back for.

## 27. Swiping a message to reply to it

**Rules.**
- Dragging a message row towards the trailing edge starts a reply to it; under a right-to-left layout the direction mirrors. The other direction does nothing.
- The timeline's own scrolling comes first: a drag whose horizontal travel is under 1.25 times its vertical travel belongs to the list, not to the row.
- The row follows the finger — that is the feedback — as far as 56, then resists at 0.35 and never travels past 72. Releasing before 56 cancels; dragging back below it cancels too.
- 56 is where the gesture arms, and the reply glyph reaches full strength exactly there. The reader knows one more millimetre will reply **before** letting go, which is the difference between a gesture and a surprise.
- Crossing that line is also **felt**: one selection tick on the way in and one on the way back out, because on a phone the finger is on the thing that changed. Never one per frame — a finger resting past the line is not a drum (`spec/haptic-vectors.json`). The same rule runs at the voice button's cancel threshold, the kit's other gesture with a line. Whether it is felt at all is the reader's own system setting, which every platform primitive already obeys, so the kit adds no switch of its own.
- Releasing springs the row back (instantly for a reader who asked for less motion) and raises the intent only when it was armed.
- A notice, a recalled message and multi-select mode carry no swipe: a row with no message actions has nothing to reply to, and selection already owns the row.
- The swipe is never the only way to reply. The message menu raises the same intent, and the host builds the same quote for both — so a reader who cannot make the gesture loses nothing, and the two entrances cannot drift apart in wording or in which id they name.

**API.** `onSwipeReply` on the three native lists (Flutter `FlareMessageList`, SwiftUI `MessageListView`, Compose `MessageList`), carrying the message. The rule itself is one pure function per kit — `flareSwipeReplyGesture`, `FlareSwipeReply.resolve`, `swipeReplyGesture` — over the shared table `spec/swipe-reply-vectors.json`, which every kit's tests read.

**Used by.** The three native apps' chat timelines. The tick is `flareHapticCrossed` + the platform's selection feedback (`HapticFeedback.selectionClick`, `LocalHapticFeedback`, `UISelectionFeedbackGenerator`; nothing on a Mac, which has no such generator). Vue has no swipe: the web timeline is pointer-first, where the hover toolbar and the context menu carry the same intent, and a horizontal touch drag there fights the list's own scrolling.

## 28. A semantic colour comes in a pair

**Rules.**
- Every semantic colour is two tokens, not one: the fill (`primary`, `error`, `success`, `info`, `warning`) and the same meaning as type (`primaryText`, `errorText`, `successText`, `infoText`, `warningText`). Blocks of colour take the first; letters and icons take the second.
- The two are not interchangeable, and dark mode is where that stops being a nicety. The brand fill is the same hex in both themes — 5.55:1 on the light page, **2.66:1** on the dark one — while the text half lightens for dark and reads at 8.5:1. In light the two halves of the brand and warning pairs are the *same* value, which is why using the right one changes nothing there and everything in the dark.
- White is not a foreground you can assume. A fill light enough to read as an accent on a dark page is too light to carry white type: dark `error` at #EF4444 gave white 3.76:1. A coloured chip states its own foreground, and if the pair cannot carry it, the chip is neutral instead.
- Do not dim a colour token to make it quieter. `opacity: 0.8` on an already-calibrated colour is how a 4.5:1 becomes a 3.78:1; choose the quieter token instead.
- Text tokens are not fills either. A badge painted with `text-tertiary` reads white-on-grey at 2.54:1 in dark, because a text colour is chosen against a surface, not to be one.

**API.** `tokens.json` holds both halves of each pair for both themes; every kit exposes them under the same names (CSS `--flare-color-<family>` / `--flare-color-<family>-text`, and `colors.<family>` / `colors.<family>Text` on Flutter, SwiftUI and Compose). `tooling/check-contrast-tokens.mjs` refuses a fill used as a foreground and a text colour used as a fill, on all four kits and the documentation site.

**Used by.** Everything that paints meaning: ghost and text buttons, active tabs, selected rows, mentions, links, danger labels, counters, badges. The web sweep scans every component preview in both themes (`@a11y`); the three native kits have no scanner, so the gate above is what holds them.

## 29. Saying "I am typing", and believing it

**Rules.**
- The two halves are one rule. What this client reports about itself and how long it believes a peer are only correct in relation to each other, so they live in one table (`spec/typing-vectors.json`) with the invariant `refreshMs < peerTtlMs` asserted by every kit. Split across two files, "renew every 3 s" and "forget after 2 s" both look reasonable.
- Report `true` at most once per `refreshMs` (2500), **and keep reporting it** while the person is still typing. Deduplicating without renewing is worse than not deduplicating: the peer's belief expires at `peerTtlMs` (6000) and the indicator dies mid-sentence, while the person is still typing.
- Report `false` the moment it is known — the box was cleared, the message went out, the reader left, the conversation changed — and otherwise `idleStopMs` (4000) after the last edit. Sending ends typing because the message says more than the signal did.
- Only the person's own edits count. The composer's clear after a send, a text the host puts back, and a caret that moved are not typing; the kit reports them through `onUserInput` (Vue `user-input`) and keeps its own writes out of it.
- A belief about a peer expires on its own. A client that stops mid-sentence — crashed, backgrounded, offline — must not leave someone typing forever, so every belief carries a deadline and the roster prunes at it.
- A message from someone who was typing ends their typing, and a server listing of who is typing replaces the conversation's whole set. A roster that only hears start and stop drifts out of true on the first lost event.
- The typer's name is a name. A peer the directory has not introduced falls back to the conversation's own name (1:1) or a generic member word (group); a raw id is never shown.

**API.** `FlareTypingSignal` (send) and `FlareTypingRoster` (receive) on all four kits, plus `flareTypingNames`. Both take the clock as an argument rather than reading it, so the same script produces the same result on four platforms — and instants are 64-bit, because epoch milliseconds do not fit in a 32-bit integer and a table that starts at zero cannot see that. `TypingIndicator` draws it; `ConversationRow`'s `typing` puts it on the row, under the same precedence as everything else on that line (see §30).

**Used by.** The chat header's subtitle, the timeline footer under the newest message, and the conversation row. All five reference apps.

## 30. What the second line of a conversation row says

**Rules.**
- One precedence, everywhere: a failed send, then a draft, then someone typing, then a mention, then the last message. It is a single ordered decision (`previewKind`), not a pile of conditions, and all four kits compute it identically.
- The row model carries facts, not opinions. The core owns the preview, the unread count, the timestamp; the host owns exactly three things it knows and the core does not — the draft this device is holding, whether anyone is typing, and the peer's presence — and adds them through one narrow copy (`hostFacts`). A value type without that copy makes a whole branch unreachable, which is how `typing` stayed unfed for several rounds.
- A draft that trims to nothing is a cleared draft. A row with an empty draft is an ordinary row, not a row with an empty draft on it.
- Presence that nobody could look up is **absent, not offline**. The core answers an impossible lookup with an empty shell; reading that as 离线 puts a state in front of a reader that nobody ever reported. An absent presence draws no dot.

**API.** `ConversationRowData` (`previewKind`, `titleEmphasis`, `unreadLabel`) on four kits; `hostFacts(draftPreview:typing:presence:)` on the two whose models are value types (Kotlin gets it from `data class`). `spec/conversation-state-vectors.json` covers the precedence.

**Used by.** Every conversation list in the five reference apps.

## 31. A draft belongs to the account, not to the device

**Rules.**
- A draft is written to the core, so it is on the other device when the person picks it up there. Storing it in local storage or in memory answers the smaller question — keep what I typed here — and silently fails the one people actually have.
- Write after a pause (`saveDelayMs`, 1200), and write **immediately** when leaving the conversation, the screen or the app. A draft lost to a pending timer is the failure nobody forgives.
- A send that reached nothing puts its text back at once, above whatever was typed while it was in flight, never twice, and never through the debounce.
- Do not write what is already there. The conversation summary carries the draft the core holds; seed the rule with it so an unchanged draft is never written back, and so a draft typed on another device appears rather than being overwritten.
- Sending clears the draft and cancels any pending write. Editing a sent message is not composing: that text belongs to the message, the host does not report it as a draft, and the draft from before the edit is waiting when the edit ends.

**API.** `FlareDraftAutosave` and `flareRestoredDraft` on four kits against `spec/draft-vectors.json`; `conversation.update_draft` through each platform's SDK facade. `ConversationRow` shows it under §30's precedence.

**Used by.** The composer and the conversation list in all five reference apps.

## 32. Coming back is not the same as never having left

**Rules.**
- A gap has three consequences and they need three different answers. A belief formed before it may be stale (the peer who stopped typing never got to say so). A server-side watch dies with the stream that carried it. A change that happened during the gap was never delivered, and a subscription only ever promises the next one. Doing one of the three is not doing the job.
- The first connection creates no work. The app's own open path already subscribes and reads; repeating it here doubles every cold start.
- A drop is counted once, however many phases it passes through on the way down (disconnected, then reconnecting, then offline is one gap). A return refreshes once — and a flap refreshes once per return, because every gap swallowed something.
- **A session that ended is not a gap.** Being kicked or having the sign-in expire is terminal: the core does not reconnect by design, so re-subscribing is work for a session that no longer exists. Terminal also forgets that this client was ever connected, which is what makes the next connection a fresh start rather than a recovery — the real sequence is socket first, reason second, so without that the interruption recorded on the way down would still be standing when the new session arrives.

**API.** `FlareConnectionRefresh.observe(phase)` on all four kits, answering `dropStaleBeliefs` / `resubscribe` / `reread`, against `spec/reconnect-refresh-vectors.json`. Phases are the same `FlareConnectionPhase` the connection notice takes, so an app reads one value and gets both the banner and the work.

**Used by.** All five reference apps, at whichever layer holds the connection phase.

## 33. An ephemeral signal still has to cross the cluster

**Rules.**
- "Lossy" describes what happens when delivery fails, not who is allowed to receive it. A relay that reaches only the subscribers on the node that received the frame is not lossy — it is wrong for the most ordinary deployment there is, two people on two nodes.
- Give it its own transport, not the message path's. Messages carry a seq and move a watermark; a typing frame has neither, and putting it through the same call makes an ephemeral signal touch durable state.
- Aggregate first, broadcast second. What crosses the cluster should be the coalesced frame — one per window per conversation — never one per keystroke.
- The node that received the uplink broadcasts; the nodes that receive the broadcast only relay locally. Making a loop impossible by structure beats guarding against it with a flag.
- Skip yourself. The originating node has already told its own connections, and a broadcast that includes it delivers the same signal twice on the same device.
- One implementation for both entries. The uplink path and the peer RPC must relay identically; written twice, they will diverge.

**API.** `AccessGateway.RelayRealtimeControl` (gateway ⇄ gateway) plus `RealtimeControlRelay`, shared by the uplink handler and the RPC handler. Single-instance deployments find no peers and behave exactly as before.

**Used by.** Typing today; the same path carries presence hints and read cursors, which have the same shape.

## 34. A destination owns its panes

**Problem.** Five apps measured the window to pick a phone, tablet or desktop layout, kept their own tab state alive (or lost it), and wrote a formula for when the phone tab bar hides. The shell rendered what it was told, and each app told it something slightly different.

**Rules.**
- The shell measures its own box, not the window, and puts the mode it found in context. A pane frame inside the shell uses that mode; outside a shell it measures itself.
- The shell renders destinations by navigation id, and a destination arranges its own panes: tabs contain split views, the way every platform's own containers do. The shell has no list, detail or active-pane parameters.
- A visited destination stays alive, with its scroll position and state, until its navigation item goes away. Nobody wraps destinations in a keep-alive of their own.
- The phone tab bar hides while the active destination is deeper than its root. Depth is reported, not guessed: a screen with a back action and a single-pane frame showing a non-root pane report it themselves; a host-drawn secondary page registers it. The rail and sidebar on wider modes are unaffected.
- Hidden destinations do not animate. Under reduced motion "tiny durations" still animate `visibility`, which shows the old page for a frame.

**API.** Vue `FlareIMAppKit` `destination` slot and `useFlareDestinationDepth`; Flutter `destinationBuilder`, `FlareShellScope`, `FlareDestinationDepth`; SwiftUI `IMAppKitView(destination:)`, `.flareDestinationDepth(_:)`, `flareDestinationActive`, `flareDestinationPresentation`; Compose `IMAppKit(destination)` and `FlareDestinationDepth(active)`. `check-ui-reuse` refuses an app that brings back its own measurement, keep-alive or tab-bar formula.

**Used by.** All five reference apps.

**Replaces.** `responsiveMode` passed by the host, nine IMAppKit parameters, a resize listener per app and four tab-bar formulas (FR-095).

## 35. Draw what the core stores

**Rules.**
- A message body draws the form the core persists and validates, not the text the sender typed. For rich text that is the RichDoc v2 document: search, notifications and every other platform read the document, so a body that draws the Markdown source can show something nobody else sees.
- When the document cannot be drawn, draw the core's plain text; when there is none, say what the message is. Never draw an empty bubble.
- A link is live only when its address passes `safeExternalUrl`; a refused link keeps its words.
- A covered spoiler keeps its text out of what is rendered — each visible character becomes a blank of the same width — so neither a screen reader, a copy nor a contrast checker can read it before it is revealed; the cover itself is read as "spoiler, tap to show".
- What normalisation drops is a core gap, recorded there (S25), not patched in a kit.

**API.** `RichTextMessage` on four kits (`docJson`, `plainText`, `title`, `self`, `selectable`, `linkClick`); native `FlareRichTextContent`; the reading rule in `spec/rich-doc-vectors.json`.

**Used by.** The timelines of all five reference apps.

## 36. An album, and a chat's pictures

**Rules.**
- One layout for any number of pictures: one to three in as many columns, four in a two-by-two grid, five and more in three columns; at most nine tiles, the ninth covered with "+N" for the rest. Every tile is named by its place ("picture 3 of 12").
- A picture tapped in a timeline opens the chat's gallery at that picture: every picture of every image and album message, in timeline order and album order, skipping recalled messages and pictures with nothing to load. The preview says where it is and pages with side controls and a sideways swipe while unzoomed; the control with nowhere to go is disabled. A body used on its own previews its one picture.
- Sending several pictures sends one message. Upload all of them first, in the order picked, and send nothing if any upload fails — never part of an album. One picture is an image message, not an album of one. A picker that cannot limit the count sends the first nine and says so.
- The request shape belongs to the SDK wrapper, not to five apps.

**API.** `ImageGroupMessage` on four kits and native `FlareImageGroupContent`; preview `galleryIndex` / `galleryCount` with previous and next; `flareImageGalleryItems` / `flareImageGalleryStart` (Flutter, SwiftUI, Compose); `createImageGroup` in the TypeScript, Dart and Apple wrappers and the Android facade. Rules in `spec/image-group-layout-vectors.json` and `spec/image-gallery-vectors.json`.

**Used by.** All five reference apps (receive, gallery and multi-picture send).
