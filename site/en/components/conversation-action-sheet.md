---
title: ConversationActionSheet
---

# ConversationActionSheet

Per-conversation action menu opened by long-press, right-click or a "more" button. The host passes a conversation snapshot and the capabilities it can honour; the shared `conversationActions(conversation, capabilities)` contract computes the visible actions so all four platforms show the same set, order and grouping. Delete sits alone in a trailing danger group. The component owns no positioning — hosts place it in a bottom sheet, popover or dialog.

<div class="flare-demo flare-demo--stack"><ConversationActionSheetDemo /></div>

<ComponentApi name="ConversationActionSheet" />

Rules: a capability that is absent or `false` hides its action; `pinned`/`muted`/`archived` select one of pin/unpin, mute/unmute, archive/unarchive; markRead only appears with `unreadCount > 0`; delete is always last and rendered with the error token plus its icon; `busy` disables every row; with no capabilities the `emptyText` is shown instead of a blank menu. The action enum is `pin | unpin | mute | unmute | markRead | archive | unarchive | hide | delete`, and the `action` payload is `{ id, action }` with the host's stable conversation id echoed back.

Hosts set `busy` synchronously before dispatching and update the snapshot after the SDK confirms; the component never mutates state or performs network calls. `close` fires on Escape; the host dismisses its own overlay.

Entries: FlareConversationActionSheet (Vue/Flutter), ConversationActionSheetView (SwiftUI, plus `dialogButtons()` for `.confirmationDialog`), ConversationActionSheet (Compose). Native callbacks: onAction(id, action), onClose(). Vue emits action({id, action}), close. Rows are at least 48 logical units, keyboard-navigable (Tab / arrows / Enter / Escape) with a visible focus ring, and expose the conversation title as the menu's accessible name. See the [full integration guide](/components/conversation-action-sheet).
