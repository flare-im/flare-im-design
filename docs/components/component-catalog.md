# Component Catalog: Consumers and Decisions

Date: 2026-09-14, after Round 4 of the reference-app program. Scope: the 149 components in `spec/components.json` on four platforms, judged by who actually uses them.

This page answers, for every public component: what it is for, who uses it today, and what happens to it. Component contracts, props and live previews stay on the website component pages; this page is the consumption record behind the brief "every public component has a real consumer".

## 1. How consumers were counted

- **Reference apps:** a component counts as used by an app when the app source references its platform symbol: web and Tauri (Vue symbol or tag), Flutter, iOS and Android (Compose symbol with a kit import). Five apps under `flare-social/flare-social-sdk/examples/apps`.
- **Core examples:** the same scan over `flare-im-core-client-sdk/examples` (web, Electron, Tauri, uni-app, Flutter, iOS, Android). They prove the core contract; they count as consumers here.
- **Kit composition:** Vue kit files that import the component's source file. A part rendered by a composite the apps use has a real consumer through that composite.
- **Limits:** symbol scans do not see dynamic registration, and composition is read from the Vue kit, which is the contract reference; native composition can differ. Friction IDs come from `docs/product/design-system-friction.md`.

## 2. Summary

| Measure | Count |
|---|---:|
| Components | 150 |
| Used directly by at least one flare-social reference app | 79 |
| Used directly by a reference app or a core example | 92 |
| Used only as a part of another kit component | 30 |
| No consumer of any kind | 28 |

| Decision | Components |
|---|---:|
| KEEP | 108 |
| REFACTOR | 1 |
| MERGE | 8 |
| SPLIT | 0 |
| INTERNALIZE | 14 |
| DEPRECATE | 16 |
| REMOVE | 3 |

Decision vocabulary: KEEP (has a consumer), REFACTOR (the need is real but the component is not wired where the need is), MERGE (a second implementation of something another component already does), SPLIT, INTERNALIZE (a part nobody composes directly; stays inside the kit), DEPRECATE (no consumer and no present need; experimental until an app needs it), REMOVE (not IM-generic).

Execution: none of the non-KEEP decisions is executed in the 2.0 RC. Each one changes the public surface on four platforms, and the RC takes P0 and P1 fixes only. They are the input for the next minor release, gated by `tooling/check-reference-app-consumers.mjs` so no reference app breaks.

## 3. Decisions that change the public surface

| Component | Decision | Why | Friction |
|---|---|---|---|
| UnknownUserPlaceholder | REFACTOR | Apps show raw sender ids when a profile is missing (web mapper falls back to senderId); the bubble and row fallbacks should use it instead of each host. | - |
| DesktopAppShell | MERGE | Vue, iOS and Compose IMAppKit render AppLayout on desktop while Flutter renders this shell: two desktop shells for one job. Keep one, with its keyboard commands on the IMAppKit desktop path. | - |
| VoiceRecordingBar | MERGE | The Vue composer uses its own voice panel and no native composer renders this bar; one voice recording surface. | - |
| EmojiPicker | MERGE | The Vue EmojiStickerPicker, which every reference app uses, draws its own grids instead of composing these; the recorded reason to keep them (Android reactions, duplication register D14) no longer holds after Round 0. | - |
| StickerPanel | MERGE | The Vue EmojiStickerPicker, which every reference app uses, draws its own grids instead of composing these; the recorded reason to keep them (Android reactions, duplication register D14) no longer holds after Round 0. | - |
| MemberPanel | MERGE | A second member list next to GroupDetail and GroupMemberGrid with no consumer; merge into the group detail composition. | - |
| GroupPermissionMatrix | MERGE | GroupDetail already draws member management (promote, mute, transfer, remove) and the permission toggles itself (checked in Vue and Compose); keep one implementation (FR-028). | - |
| MemberRoleSheet | MERGE | GroupDetail already draws member management (promote, mute, transfer, remove) and the permission toggles itself (checked in Vue and Compose); keep one implementation (FR-028). | - |
| AdaptiveWorkbench | MERGE | The same navigation, primary, content and detail grid with single, dual and triple pane modes as AppLayout (checked in Vue), which every reference app reaches through IMAppKit. Removed from the four kits in Round 10 (FR-140, duplication register D18). | FR-140 |
| TextMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| ImageMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| VideoMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| VoiceMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| FileMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| LocationMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| ContactMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| LinkCardMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| VoteMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| TaskMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| StickerMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| EmojiMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| SystemMessage | INTERNALIZE | Reached only through MessageContentView inside MessageBubble; no host composes a renderer directly, and products add types through the content registry. | - |
| TransferProgress | INTERNALIZE | Drawn only inside TransferQueue. | - |
| CallView | DEPRECATE | No reference app implements calls and the Tauri call-invite route is missing; mark experimental until an app ships calls end to end. | - |
| IncomingCall | DEPRECATE | No reference app implements calls and the Tauri call-invite route is missing; mark experimental until an app ships calls end to end. | - |
| CallControls | DEPRECATE | No reference app implements calls and the Tauri call-invite route is missing; mark experimental until an app ships calls end to end. | - |
| GroupCallView | DEPRECATE | No reference app implements calls and the Tauri call-invite route is missing; mark experimental until an app ships calls end to end. | - |
| QuickPhrases | DEPRECATE | Bot and command products; no composer integration and no reference app need. | - |
| CallDock | DEPRECATE | No reference app implements calls and the Tauri call-invite route is missing; mark experimental until an app ships calls end to end. | - |
| SlashCommandMenu | DEPRECATE | Bot and command products; no composer integration and no reference app need. | - |
| TranslationView | DEPRECATE | Translate is a capability stub in the SDK (friction log Appendix B); no backend to drive it. | - |
| ChatWallpaperPicker | DEPRECATE | Cosmetic setting with no consumer. | - |
| TimePicker | DEPRECATE | No consumer; scheduling UI is not part of any reference app. | - |
| TransferQueue | DEPRECATE | No consumer; standalone transfer progress is never emitted by the SDK (friction log Appendix B), so a queue cannot bind. | - |
| PermissionPrompt | DEPRECATE | No consumer; platform permission prompts are raised by the host adapters today. | - |
| MediaCenter | DEPRECATE | No consumer; no reference app has a conversation media browser, and the transfer queue it hosts cannot bind yet. | - |
| CallDevicePicker | DEPRECATE | No reference app implements calls and the Tauri call-invite route is missing; mark experimental until an app ships calls end to end. | - |
| ScreenShare | DEPRECATE | No reference app implements calls and the Tauri call-invite route is missing; mark experimental until an app ships calls end to end. | - |
| CommandPalette | DEPRECATE | Desktop power feature with no consumer, including the desktop Tauri app. | - |
| RedPacketCard | REMOVE | A payments product feature, bound to one business model; no IM-generic task and no consumer. | - |
| Stepper | REMOVE | Generic form primitives with no IM task and no consumer in any example app. | - |
| Rating | REMOVE | Generic form primitives with no IM task and no consumer in any example app. | - |

## 4. Full catalog

### General

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| Avatar | User or group avatar — image, initials fallback, optional presence dot. | tauri, flutter | vue, flutter, ios | CallDock, CallView, ContactDetail, ContactItem, ContactMatchList, ConversationDetails, ConversationHeader, ConversationRow, ForwardPicker, GroupCallView, GroupDetail, GroupList, GroupMemberGrid, IncomingCall, MemberRoleSheet, MentionPicker, MomentAudienceSheet, MomentCard, MomentsCoverHeader, MomentsVisibilityRuleList, NewFriendRequests, ProfileCard, ProfileEditor, ProfilePanel, QRCard, ReadReceiptSheet, SearchResults, TypingIndicator | KEEP | Friction: FR-039 |
| Button | Button — primary/secondary/ghost/danger/text variants × sm/md/lg sizes, with loading/disabled/icon/block. | web, tauri, flutter, ios, android | vue, ios | ComposerMediaPreview, FormSheet, GroupDetail, PermissionPrompt, SceneList | KEEP | - |
| IconButton | Icon button — plain/tinted/solid × sm/md/lg × circle/square, with an active state. | web, tauri, flutter, ios, android | vue, flutter, ios | - | KEEP | - |
| Icon | Icon library — a cross-platform set of semantic icon names (search/send/heart/…); each platform maps the same names. | - | vue | ConversationHeader, FlareActionMenuList, FlareGlyph, Input, PermissionPrompt, ScreenShare, SearchBar, SearchDateRangeFilter, UnknownMessage | KEEP | - |
| ConfigProvider | Root UI provider — installs theme (brand / light-dark), language, adaptive layout, viewport, media resolution, the platform contract, the overlay container and the default control size in one place; descendants read and switch through useFlareConfig() / useFlarePlatform() / useFlareAdaptive(). | web, tauri | vue | - | KEEP | - |
| BrandLogo | Brand logo — the forward-leaning geometric F (skewX -9°) in two variants, gradient (brand gradient plate + white F) or plate (white plate + gradient F); one geometry on all four platforms. | flutter, ios, android | vue, flutter, ios, compose | - | KEEP | Friction: FR-048 |

### Layout

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| AppLayout | Root application region composer for mobile, tablet, desktop, and wide desktop. | - | - | DesktopAppShell, IMAppKit, WorkspaceFrame | KEEP | Composition part of IMAppKit, WorkspaceFrame. Not for: For an application shell; use IMAppKit, which adds navigation and the phone single-pane mode. Friction: FR-020 |
| MobileAppShell | Safe-area mobile shell with content, bottom navigation, and overlay hosts. | ios | - | IMAppKit | KEEP | Not for: For an application shell; use IMAppKit. |
| DesktopAppShell | Desktop application shell with adaptive navigation and pane regions. | - | - | - | MERGE | - |
| ChatWorkspace | The semantic active-chat surface: optional Context → Header → top-anchored Timeline → Composer. | - | vue | - | KEEP | - |
| ResponsiveLayout | Available-container layout: single below 720 logical units, dual from 720, triple from 1100 when content fits. Large text may reduce pane count. Dual pane foregrounds detail when requested. | - | - | ConversationWorkspace | KEEP | Composition part of ConversationWorkspace. |
| ScreenHeader | Large-title screen header — the quiet top bar for a tab surface, with an actions slot; distinct from ChatHeader. | web, tauri, flutter | vue | - | KEEP | Friction: FR-039 |
| ConversationWorkspace | Conversation workspace — composes ResponsiveLayout and resolves loading / empty / failure for the list, chat and detail panes in one place, plus a cross-pane banner. | tauri | - | - | KEEP | - |
| Screen | Page scaffold — large title, optional back, three surfaces (canvas / surface / brand) and a scrollable body every business page composes on. | web, tauri, flutter, ios, android | vue | - | KEEP | Friction: FR-005 |

### Navigation

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| AdaptiveNavigation | One navigation model rendered as a bottom bar, rail, or sidebar. | ios | - | DesktopAppShell, IMAppKit, MobileAppShell | KEEP | - |
| SearchBar | Unified search field — the entry to conversation/contact/message search, with clear and submit. | web, tauri, flutter, ios, android | vue | - | KEEP | Friction: FR-027 |
| FilterTabs | Scrollable filter tablist ({value,label,badge?}) with a v-model active value and a change event. | tauri, flutter | vue, flutter, ios | ReadReceiptSheet | KEEP | - |
| SegmentedControl | Segmented control — a compact equal-width mutually-exclusive in-page filter; selected chip raised. | web, tauri, flutter, ios, android | flutter, ios, compose | - | KEEP | - |
| CommandPalette | Searchable, keyboard-first command surface with grouped host-owned intents. | - | - | - | DEPRECATE | - |

### Patterns

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| ConversationListContainer | State-aware conversation list composition with search, filters, pinned, archived, and pagination regions. | web, tauri, flutter, ios, android | vue, ios | FriendListContainer | KEEP | Friction: FR-057 |
| FriendListContainer | State-aware friend directory composition with search and request regions. | web, tauri, flutter | - | - | KEEP | - |
| AdaptiveWorkbench | Host-level adaptive workbench that composes navigation and content panes. Removed in Round 10 (D18). | - | - | - | MERGE | FR-140 |

### Workspaces

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| WorkspaceFrame | Adaptive workspace frame: primary, content and detail panes with shared loading, empty, error and offline rendering. | tauri | - | - | KEEP | - |

### AppKit

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| IMAppKit | Top-level host-neutral IM application assembler. | web, tauri, flutter, ios, android | flutter, ios, compose | - | KEEP | Friction: FR-019, FR-070 |

### Message

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| MessageStatus | Lifecycle projection — pending/sending progress, sent check, compact delivered/read double-check, and retryable failure. | - | flutter | MessageMeta | KEEP | - |
| MessageMeta | Stable metadata row composing timestamp, edited and ephemeral labels, delivery status, and retry. | - | - | MessageBubble | KEEP | Composition part of MessageBubble. |
| MessageBubble | One message in a thread — content, sender, grouping, delivery status. Delegates body to a per-content-type view. | - | flutter, ios, compose | MessageList | KEEP | Not for: Inside a thread; use MessageList, which owns grouping, identity and intent masks. Friction: FR-003, FR-006, FR-062 |
| MessageList | The virtualised message thread — grouping, load-older, multi-select, per-message actions, media state. | web, tauri, flutter, ios, android | vue | - | KEEP | Friction: FR-003, FR-006, FR-033, FR-073 |
| ConversationHeader | A configurable active-conversation header with identity, capability-filtered actions, responsive overflow, and targeted extension regions. | web, tauri, flutter, ios, android | vue, flutter, ios, compose | - | KEEP | Not for: To add actions the host cannot perform; declare capabilities so unwired actions stay hidden. Friction: FR-055 |
| PinnedMessageBar | Sticky bar showing pinned messages above the thread; tap to focus the pinned message. | tauri | vue | - | KEEP | - |
| MessageContentView | Content-type dispatcher — renders a message body by type via the content-type registry (text/image/video/card/vote/task/…). Extension point for products. | - | vue | MessageBubble | KEEP | Not for: For a whole message; use MessageBubble or MessageList. |
| TextMessage | Canonical text body with safe links. MessageBubble owns the surface, grouping and metadata. | - | - | TextView | INTERNALIZE | - |
| ImageMessage | Image message body — a rounded thumbnail. | - | - | ImageView | INTERNALIZE | - |
| VideoMessage | Video message body — poster with a play overlay and duration badge. | - | - | VideoView | INTERNALIZE | - |
| VoiceMessage | Audio / voice message body — a waveform and duration. | - | - | AudioView | INTERNALIZE | - |
| FileMessage | File message body — icon, name / size / ext, download affordance. | - | - | FileView | INTERNALIZE | - |
| LocationMessage | Location message body — a map placeholder over title / address. | - | - | LocationView | INTERNALIZE | - |
| ContactMessage | Contact / business card — pastel avatar + name / id. | - | - | CardView | INTERNALIZE | - |
| LinkCardMessage | Link card — thumbnail + title + domain. | - | - | LinkCardView | INTERNALIZE | - |
| VoteMessage | Vote message body — a title over options with proportional bars. | - | - | FlareVoteMessageView | INTERNALIZE | - |
| TaskMessage | Task message body — checkbox + title (struck when done) + meta. | - | - | FlareTaskMessageView | INTERNALIZE | - |
| StickerMessage | Sticker body — a bare, larger glyph / image (no bubble). | - | - | StickerView | INTERNALIZE | - |
| EmojiMessage | Large-emoji body — bare, no bubble. | - | - | EmojiView | INTERNALIZE | - |
| SystemMessage | System / notification body — a centered pill. | - | - | SystemView | INTERNALIZE | - |
| MessageActionSheet | The message long-press action sheet — a reaction strip, quick actions (reply/forward/recall), and grouped actions (multi-select/mark/pin/copy/edit/delete). Delete in red. | flutter, ios, android | flutter, ios, compose | MessageMenu | KEEP | Not for: With hand-written availability; pass the core answer (message.action_availability). Friction: FR-010, FR-063 |
| TypingIndicator | Typing indicator — bouncing dots, single/multi-typer copy. | tauri | - | - | KEEP | - |
| UnreadDivider | Unread divider — the “N new messages” line. | - | - | MessageList | KEEP | Composition part of MessageList. Not for: Inside a thread; pass unreadFromId to MessageList, which places it and restarts the sender run. |
| ScrollToLatest | Scroll-to-latest pill — floating back-to-bottom + unread badge. | - | - | MessageList | KEEP | Composition part of MessageList. |
| ReactionSummary | Reaction summary — emoji pills under a bubble, tap to toggle + add. | - | flutter, ios | - | KEEP | Not for: Under a message; MessageBubble renders it from message reactions. Friction: FR-064 |
| ReadReceiptSheet | Group read receipt — read/unread tabs + member avatars. | tauri | - | - | KEEP | - |
| MessageBatchToolbar | Batch toolbar — forward each/merged, delete, select-all, exit. | tauri | vue | - | KEEP | Friction: FR-034 |
| AnnouncementBanner | Announcement banner — pinned notice, expand/dismiss. | tauri | - | - | KEEP | - |
| DatePill | Date pill — timeline day chip, optionally sticky. | - | flutter, ios | MessageList | KEEP | - |
| RedPacketCard | Red packet — gradient + blessing + claim state. | - | - | - | REMOVE | - |
| TranslationView | Inline translation — text + attribution + show original. | - | - | - | DEPRECATE | - |
| ImageGrid | Adaptive image grid — layout by count + N. | - | - | MomentCard | KEEP | Composition part of MomentCard. |
| VoicePlayer | Voice player — progress wave+speed+transcript. | - | flutter | - | KEEP | - |
| UnknownMessage | Body for a message this client cannot render: a human placeholder plus the raw content type kept as a diagnostic. | - | - | ContentView | KEEP | Composition part of ContentView (check that composite's own consumers). |

### Conversation

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| ConversationList | The inbox — virtualised rows of conversations (avatar, title, preview, unread, timestamp). | web, tauri, flutter, ios, android | vue, ios | - | KEEP | Friction: FR-037 |
| ConversationRow | A single inbox row — avatar, title, last-message/draft preview, unread badge, time, mute/pin markers. | flutter | vue, flutter, ios | ConversationList | KEEP | Not for: For a list; use ConversationList (virtualized, row actions, selection). Friction: FR-016, FR-017, FR-018, FR-033 |
| ConversationDetails | The conversation info/settings panel — counts, connection state, and per-conversation actions (mute/pin/archive/clear/delete/sync). | - | vue | - | KEEP | - |
| StartConversationDialog | New-conversation entry — pick a contact or create a group. | ios, android | vue | - | KEEP | - |
| ForwardPicker | Forward picker — search chats, multi-select, send. | tauri, flutter, ios, android | vue | - | KEEP | - |
| ChatWallpaperPicker | Wallpaper picker — swatch grid+selected. | - | - | - | DEPRECATE | - |
| ConversationActionSheet | Per-conversation action menu (long-press / right-click / more) with a shared action set, danger group and busy lock across platforms. | - | flutter, ios | ConversationRow | KEEP | Friction: FR-016 |
| ConversationBatchToolbar | Multi-select batch bar for the conversation list, with a partial-failure summary and per-item recovery. | tauri | - | - | KEEP | - |

### Composer

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| Composer | The input — rich or plain text, emoji, format bar, attachments, reply strip. Emits built content; send is optimistic. | web, tauri, flutter, ios, android | vue, flutter, ios | - | KEEP | Friction: FR-011, FR-012, FR-013, FR-014, FR-015, FR-035 |
| VoiceHoldButton | Hold-to-talk voice button — press to record, slide up to cancel. A composable Composer part. | - | - | - | KEEP | Composition part of the Compose Composer (ComposerParts.kt); the Vue composer uses its own voice panel (see VoiceRecordingBar). |
| ComposerActionPanel | The attachment action grid (image/file/card/vote/…) — the expandable panel behind the composer's + button. | - | vue | ComposerMoreSurface | KEEP | - |
| EmojiStickerPicker | The composer emoji + sticker picker: animated emoji keys and sticker packs from the kit asset catalog, with recents. | web, tauri, ios, android | vue, ios | - | KEEP | - |
| ComposerMediaPreview | Pre-send attachment preview: the picked images / videos / files with an optional caption, confirmed or cancelled before anything is uploaded. | - | vue | - | KEEP | - |
| ComposerSendButton | Send (发送) — a paper plane, not a filled disc; the brand colour carries the state and fades while there is nothing to send. A composable Composer part. | - | - | Composer | KEEP | Composition part of Composer. Not for: In a standard composer; Composer already renders it. Use it only for a custom bar. |
| ComposerReplyStrip | Reply strip (回复条) — shown above the input when replying: left brand rail + sender / summary + cancel. | - | - | Composer | KEEP | Composition part of Composer. Not for: In a standard composer; Composer renders it from reply props. |
| RichMarkdownInput | The rich (RichDoc/Markdown) text field with formatting preview and length limit — used inside Composer. | - | - | Composer | KEEP | Composition part of Composer. |
| MentionPicker | Mention picker — searchable members, incl. @everyone. | - | - | Composer | KEEP | Composition part of Composer. Not for: In a standard composer; Composer opens it. |
| QuickPhrases | Quick phrases — grouped canned replies, tap to insert. | - | - | - | DEPRECATE | - |
| SlashCommandMenu | Slash-command menu — command + hint + desc, filterable. | - | - | - | DEPRECATE | - |
| VoiceRecordingBar | Voice recording bar — waveform+timer+cancel. | - | - | - | MERGE | - |
| PollComposer | Poll composer — question+options+multi. | - | - | - | KEEP | Adoption gap: the reference apps send a canned poll from the attach panel; creating a real poll needs this form (APP P2). |
| EmojiPicker | Full emoji picker — search+categories+recents+tones. | - | - | - | MERGE | - |
| StickerPanel | Sticker panel — pack rail+recents+grid. | - | - | - | MERGE | - |

### Media

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| ImagePreviewModal | Full-screen image viewer — zoom/pan, download with progress. | tauri | flutter, ios, compose | ImageGroupCell, ImageView | KEEP | - |
| VideoPlayerModal | Full-screen video player with poster and title. | tauri | flutter, ios, compose | VideoView | KEEP | - |
| MarkdownPreview | Rendered read-only Markdown/RichDoc content with optional stats. | tauri | vue | RichTextView | KEEP | - |
| TransferProgress | Attachment transfer status with measured progress and capability-gated recovery actions. | - | - | TransferQueue | INTERNALIZE | - |
| TransferQueue | Bounded transfer queue with per-task recovery and retry-failed batch action. | - | - | MediaCenter | DEPRECATE | - |
| MediaCenter | MediaCenter scene composition with explicit host-owned state. | - | - | - | DEPRECATE | - |

### Form

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| Input | General text input — single/multi-line, char limit, clearable, disabled/read-only; the backbone of forms and search. | web, tauri, flutter, ios, android | vue, flutter, ios, compose | GroupDetail, ProfileEditor | KEEP | Friction: FR-032, FR-045 |
| FormField | Form field — label (+ required mark) + control slot + hint/error (error replaces hint). | web, tauri, flutter, ios, android | vue, flutter, ios, compose | - | KEEP | Friction: FR-032 |
| Switch | Switch — boolean v-model with a sliding knob. | tauri | vue | - | KEEP | - |
| Checkbox | Checkbox — checked / indeterminate + label. | web, flutter | vue | ContactItem | KEEP | Friction: FR-018 |
| RadioGroup | Radio group — mutually-exclusive options, inline or vertical, per-option disable. | web, tauri, ios, android | - | GroupDetail | KEEP | - |
| Select | Select — adaptive: dropdown on desktop, bottom sheet on H5 / native app; checked state, per-option disable, focus ring. | tauri | vue | - | KEEP | - |
| Textarea | Multi-line input — auto-grow, character counter, ⌘/Ctrl+Enter to submit. | web, tauri, ios, android | vue | ComposerMediaPreview | KEEP | - |
| Stepper | Stepper — −/+ numeric increment with min/max/step; can be read-only. | - | - | - | REMOVE | - |
| Slider | Slider — range value with solid brand fill and an optional value bubble. | - | flutter | - | KEEP | - |
| Rating | Rating — star value with hover preview; read-only / clearable. | - | - | - | REMOVE | - |
| TimePicker | TimePicker — adaptive: anchored popover (hour/minute columns) on PC, bottom sheet on App/H5; v-model as "HH:mm". | - | - | - | DEPRECATE | - |
| DatePicker | DatePicker — adaptive: anchored month-calendar popover on PC, bottom sheet on App/H5; v-model as "YYYY-MM-DD", min/max supported. | - | - | SearchDateRangeFilter | KEEP | Composition part of SearchDateRangeFilter. |
| SearchDateRangeFilter | Search time-range filter: host-supplied preset chips plus a custom start/end pair built from the shared DatePicker, emitting one inclusive epoch-millisecond FlareSearchTimeRange. | tauri | - | - | KEEP | - |

### Feedback

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| EmptyState | Empty-state placeholder — icon + title + description + optional action; for empty inbox/search/contacts. | web, tauri, flutter, ios, android | vue, flutter, ios, compose | ContactList, ConversationList, ConversationListContainer, ForwardPicker, GroupDetail, GroupList, NewFriendRequests, ReadReceiptSheet, SearchResults, WorkspacePane | KEEP | - |
| StatusBanner | Compact status strip (connection / sync / runtime) with a tone, an optional pulsing dot and an optional inline action. | web, tauri, flutter, ios, android | vue, ios | CapabilityBoundary, ConversationListContainer, ConversationWorkspace, SearchPanel, TransferQueue, WorkspaceFrame, WorkspacePane | KEEP | - |
| SearchResults | Search results — contact/group/message groups + highlight. | web, ios, android | vue | SearchPanel | KEEP | Friction: FR-026 |
| Skeleton | Skeleton — list/thread/profile loading, shimmer sweep. | tauri, flutter | - | ConversationListContainer, SceneList, WorkspacePane | KEEP | - |
| Toast | Toast — 5 variants + action + spinner. | flutter | vue, flutter, ios | ConfigProvider | KEEP | Not for: To announce feedback; use a presenter so it owns queue and timers: useFlareToast (Vue), FlareToast.show (Flutter), FlareFeedback (iOS), FlareToastHost (Compose). Friction: FR-021, FR-067 |
| AnnouncementReadBar | Announcement read bar — a confirm button while unread, switching to an x/y read count once confirmed. Counts come from the server; never derive them from the truncated unread list. | web, tauri, flutter, ios, android | - | - | KEEP | Friction: FR-074 |
| CapabilityBoundary | CapabilityBoundary scene composition with explicit host-owned state. | - | - | CallDevicePicker, NotificationPreferences | KEEP | Composition part of NotificationPreferences. |
| PermissionPrompt | Unified explanation panel for a missing / denied system permission; request and openSettings are delegated to the host. | - | - | - | DEPRECATE | - |

### Contacts

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| ContactList | The address book — contacts grouped A–Z by pinyin/letter, with a side index bar and quick jump. | web, tauri, flutter, ios, android | - | GroupDetail | KEEP | Friction: FR-029, FR-044 |
| ContactItem | A contact row — avatar, name, signature/department, presence. | ios, android | - | ContactList | KEEP | Friction: FR-029 |
| ContactDetail | Contact card — avatar/name/signature + profile fields + message/voice/video/more actions. | web, tauri, flutter, ios, android | - | - | KEEP | Friction: FR-046 |
| GroupDetail | Group detail/management — info / my settings / management / permissions, member grid, member actions, join approval, invite link. | web, tauri, flutter, ios, android | - | - | KEEP | Friction: FR-028, FR-046 |
| NewFriendRequests | New friends — friend-request list with accept/reject and request notes. | web, tauri, flutter, ios, android | - | - | KEEP | Friction: FR-030 |
| GroupList | My groups — group avatar, name, member count. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| GroupMemberGrid | Group member grid — avatars + owner/admin badges + add. | tauri | - | GroupDetail | KEEP | - |
| ContactMatchList | Contact match results — matched users, showing Add or Message per alreadyFriend. The key screen for new-user onboarding. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| MemberPanel | MemberPanel scene composition with explicit host-owned state. | - | - | - | MERGE | - |
| UnknownUserPlaceholder | Placeholder for an account the host cannot describe — unknown, deactivated, blocked or unreachable — so a row never renders blank or shows a bare user id as its title. | - | - | - | REFACTOR | - |
| RelationActionBar | Relation action bar for the contact detail page: the host supplies the relation, the component computes which actions exist, in one order, with the danger group trailing. | tauri | - | - | KEEP | - |
| GroupPermissionMatrix | Group settings panel over the real group permission fields, with per-row busy, per-row failure and read-only rendering when the viewer cannot manage. | - | - | - | MERGE | - |
| MemberRoleSheet | Per-member management menu (role, mute, remove, transfer ownership) with rank rules before capabilities and a trailing danger group. | - | - | - | MERGE | - |

### Profile

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| ProfilePanel | Personal center — avatar/name/id/QR + entry list (favorites/settings/about), with logout. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| ProfileEditor | Profile editor — edit and save avatar, nickname, signature and similar fields. | web, tauri, flutter, ios, android | - | - | KEEP | Friction: FR-047 |
| SettingsList | Settings list — grouped toggles/navigation/choice rows; a general settings container. | web, tauri, flutter, ios, android | flutter | ContactDetail, GroupDetail | KEEP | - |
| ProfileCard | Mini profile card — avatar popover + message/voice/video. | tauri | - | - | KEEP | - |
| QRCard | QR name card — avatar + name + QR frame. | web, tauri, flutter, ios, android | - | - | KEEP | Friction: FR-031 |
| DeviceSessions | DeviceSessions scene composition with explicit host-owned state. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| NotificationPreferences | NotificationPreferences scene composition with explicit host-owned state. | web, tauri | - | - | KEEP | - |
| StorageUsage | Storage management panel over a host-measured usage snapshot, with per-category busy, per-category clear failure, and unknown sizes reported as unknown instead of 0 B. | web, tauri, flutter | - | - | KEEP | - |
| SettingsRow | One settings row — the single rendering of a FlareSettingsItem: icon, label, detail, toggle or chevron, danger / disabled semantics; SettingsList is built from it. | tauri | flutter, ios | ProfilePanel, SettingsList | KEEP | - |

### Call

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| CallView | In-call surface — peer video/avatar, state, duration, with an overlaid control bar. Video render is host-injected. | - | - | - | DEPRECATE | - |
| IncomingCall | Incoming call / invite — caller avatar/name, audio/video kind, accept & reject. | - | - | - | DEPRECATE | - |
| CallControls | Call control bar — mute, camera, speaker, flip camera, hang up (adapts to audio/video). | - | - | CallView, GroupCallView | DEPRECATE | - |
| GroupCallView | Group (multi-party) call — participant grid, speaking highlight, mute/camera badges, add member. | - | - | - | DEPRECATE | - |
| CallDock | Call dock — floating minimized bar + mute/hang-up/expand. | - | - | - | DEPRECATE | - |
| CallDevicePicker | Controlled RTC device selection with permission and busy states. | - | - | - | DEPRECATE | - |
| ScreenShare | In-call screen-share control and status panel with per-state icon, text and tone, indeterminate progress while requesting, and host-dispatched start / stop / cancel intents. | - | - | - | DEPRECATE | - |

### Moments

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| MomentCard | Moment card — author/text/photo grid/location/time + a ··· like-comment popover + likers row + comments. The feed's hero. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| MomentComposer | Moment composer — text + add-photo grid + location/visibility + post. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| MomentActionPopover | Like/comment popover — a dark capsule that slides from the ··· button. | - | - | MomentCard | KEEP | Composition part of MomentCard. |
| MomentsCoverHeader | Moments cover header — a cover photo + name + avatar overlapping the bottom-right. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| CommentThread | Comment thread — "A: text" or "A replying to B: text". | ios | - | MomentCard | KEEP | - |
| TopicChip | Topic chip — an inline #hashtag, brand-colored and tappable. | flutter | - | - | KEEP | - |
| MomentsVisibilityRuleList | Moments visibility list — members under hide-from / mute rules, with add and remove. The two directions are opposites; they must read as visually distinct or users will set the wrong one. | web, tauri, flutter, ios, android | - | - | KEEP | - |
| MomentAudienceSheet | Audience picker for a new moment — public/friends/private, plus the mutually exclusive include and exclude lists. The two directions are not symmetric in consequence, so copy and accent differ. | web, tauri, flutter, ios, android | - | - | KEEP | - |

### Overlay

| Component | Purpose | Reference apps | Core examples | Rendered by (kit) | Decision | Notes |
|---|---|---|---|---|---|---|
| SearchPanel | Search field, filters, result snapshot and recovery in one panel. | web, tauri | - | - | KEEP | Friction: FR-043 |
| DangerConfirm | DangerConfirm scene composition with explicit host-owned state. | flutter, android | vue, flutter | ConfigProvider | KEEP | Not for: Rendered by hand; use useFlareConfirm (Vue), FlareDangerConfirm.show (Flutter) or FlareFeedback.confirm (iOS) for busy, error and retry. Friction: FR-022, FR-042 |
| BottomSheet | Adaptive bottom-sheet primitive — the phone-form-factor surface behind Select / the pickers / form sheets; focus return, scroll lock, optional title and height cap. | web, tauri, flutter, android | - | ActionMenu, ConversationRow, DatePicker, FormSheet, GroupDetail, Select, StartConversationDialog, TimePicker | KEEP | Not for: For a form with confirm, busy and error; use FormSheet. Leave presentation on auto unless the panel is a long-lived side panel (drawer). Friction: FR-023 |
| ActionMenu | A small menu of actions: the new, more and context menus of an IM app, drawn from the shared action descriptor. Anchored to its trigger or the pointer on pointer devices and a bottom sheet on phones (Vue, Flutter); the system pull-down menu on iOS and the anchored dropdown on Android. | tauri, ios, android | - | ConversationHeader, ConversationRow, MessageMenu | KEEP | - |
| FormSheet | Form sheet — title, field slot, confirm / cancel; busy locks the fields and dismissal; the host supplies fields, validation and persistence. | web, tauri, ios, android | vue | GroupDetail | KEEP | Friction: FR-023 |
