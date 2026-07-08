# Components

One contract, four native implementations. **51** components across **9** categories.

## General

- [**Avatar**](/en/components/avatar) — User or group avatar — image, initials fallback, optional presence dot.
- [**TimeStamp**](/en/components/time-stamp) — Relative/absolute time label for a message or conversation row.
- [**MessageStatus**](/en/components/message-status) — Delivery status indicator — sending spinner, sent/read ticks, failed with retry.
- [**SearchBar**](/en/components/search-bar) — Unified search field — the entry to conversation/contact/message search, with clear and submit.
- [**Input**](/en/components/input) — General text input — single/multi-line, char limit, clearable, disabled/read-only; the backbone of forms and search.
- [**EmptyState**](/en/components/empty-state) — Empty-state placeholder — icon + title + description + optional action; for empty inbox/search/contacts.

## Conversation

- [**ConversationList**](/en/components/conversation-list) — The inbox — virtualised rows of conversations (avatar, title, preview, unread, timestamp).
- [**ConversationRow**](/en/components/conversation-row) — A single inbox row — avatar, title, last-message/draft preview, unread badge, time, mute/pin markers.
- [**ConversationDetails**](/en/components/conversation-details) — The conversation info/settings panel — counts, connection state, and per-conversation actions (mute/pin/archive/clear/delete/sync).
- [**StartConversationDialog**](/en/components/start-conversation-dialog) — New-conversation entry — pick a contact or create a group.

## Message

- [**MessageBubble**](/en/components/message-bubble) — One message in a thread — content, sender, grouping, delivery status. Delegates body to a per-content-type view.
- [**MessageList**](/en/components/message-list) — The virtualised message thread — grouping, load-older, multi-select, per-message actions, media state.
- [**ChatHeader**](/en/components/chat-header) — The active conversation's header — title, subtitle/presence, and header actions (search/call/details).
- [**PinnedMessageBar**](/en/components/pinned-message-bar) — Sticky bar showing pinned messages above the thread; tap to focus the pinned message.
- [**MessageContentView**](/en/components/message-content-view) — Content-type dispatcher — renders a message body by type via the content-type registry (text/image/video/card/vote/task/…). Extension point for products.
- [**TextMessage**](/en/components/text-message) — Text message body — linkifies bare URLs; self flips to the brand bubble.
- [**ImageMessage**](/en/components/image-message) — Image message body — a rounded thumbnail.
- [**VideoMessage**](/en/components/video-message) — Video message body — poster with a play overlay and duration badge.
- [**VoiceMessage**](/en/components/voice-message) — Audio / voice message body — a waveform and duration.
- [**FileMessage**](/en/components/file-message) — File message body — icon, name / size / ext, download affordance.
- [**LocationMessage**](/en/components/location-message) — Location message body — a map placeholder over title / address.
- [**ContactMessage**](/en/components/contact-message) — Contact / business card — pastel avatar + name / id.
- [**LinkCardMessage**](/en/components/link-card-message) — Link card — thumbnail + title + domain.
- [**VoteMessage**](/en/components/vote-message) — Vote message body — a title over options with proportional bars.
- [**TaskMessage**](/en/components/task-message) — Task message body — checkbox + title (struck when done) + meta.
- [**StickerMessage**](/en/components/sticker-message) — Sticker body — a bare, larger glyph / image (no bubble).
- [**EmojiMessage**](/en/components/emoji-message) — Large-emoji body — bare, no bubble.
- [**SystemMessage**](/en/components/system-message) — System / notification body — a centered pill.
- [**MessageActionSheet**](/en/components/message-action-sheet) — The message long-press action sheet — a reaction strip, quick actions (reply/forward/recall), and grouped actions (multi-select/mark/pin/copy/edit/delete). Delete in red.

## Composer

- [**Composer**](/en/components/composer) — The input — rich or plain text, emoji, format bar, attachments, reply strip. Emits built content; send is optimistic.
- [**VoiceHoldButton**](/en/components/voice-hold-button) — Hold-to-talk voice button — press to record, slide up to cancel. A composable Composer part.
- [**ComposerActionPanel**](/en/components/composer-action-panel) — The attachment action grid (image/file/card/vote/…) — the expandable panel behind the composer's + button.
- [**ComposerSendButton**](/en/components/composer-send-button) — Send button (发送) — brand-purple when active, disabled otherwise. A composable Composer part.
- [**ComposerReplyStrip**](/en/components/composer-reply-strip) — Reply strip (回复条) — shown above the input when replying: left brand rail + sender / summary + cancel.
- [**RichMarkdownInput**](/en/components/rich-markdown-input) — The rich (RichDoc/Markdown) text field with formatting preview and length limit — used inside Composer.

## Media

- [**ImagePreviewModal**](/en/components/image-preview-modal) — Full-screen image viewer — zoom/pan, download with progress.
- [**VideoPlayerModal**](/en/components/video-player-modal) — Full-screen video player with poster and title.
- [**MarkdownPreview**](/en/components/markdown-preview) — Rendered read-only Markdown/RichDoc content with optional stats.

## Contacts

- [**ContactList**](/en/components/contact-list) — The address book — contacts grouped A–Z by pinyin/letter, with a side index bar and quick jump.
- [**ContactItem**](/en/components/contact-item) — A contact row — avatar, name, signature/department, presence.
- [**ContactDetail**](/en/components/contact-detail) — Contact card — avatar/name/signature + profile fields + message/voice/video/more actions.
- [**NewFriendRequests**](/en/components/new-friend-requests) — New friends — friend-request list with accept/reject and request notes.
- [**GroupList**](/en/components/group-list) — My groups — group avatar, name, member count.

## Profile

- [**ProfilePanel**](/en/components/profile-panel) — Personal center — avatar/name/id/QR + entry list (favorites/settings/about), with logout.
- [**ProfileEditor**](/en/components/profile-editor) — Profile editor — edit and save avatar, nickname, signature and similar fields.
- [**SettingsList**](/en/components/settings-list) — Settings list — grouped toggles/navigation/choice rows; a general settings container.

## Call

- [**CallView**](/en/components/call-view) — In-call surface — peer video/avatar, state, duration, with an overlaid control bar. Video render is host-injected.
- [**IncomingCall**](/en/components/incoming-call) — Incoming call / invite — caller avatar/name, audio/video kind, accept & reject.
- [**CallControls**](/en/components/call-controls) — Call control bar — mute, camera, speaker, flip camera, hang up (adapts to audio/video).

## Layout

- [**AppShell**](/en/components/app-shell) — App shell — responsive navigation (mobile bottom tab / tablet-desktop side rail) + content area; the skeleton of the whole IM app.
- [**ResponsiveLayout**](/en/components/responsive-layout) — Responsive conversation layout — mobile single column (list↔chat), tablet two columns (list+chat), desktop three columns (list+chat+detail).

