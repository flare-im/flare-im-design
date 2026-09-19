# Interaction State Machines

The canonical contract is `spec/interaction-contracts.json`; executable reducers live in all four platform packages.

## Shared machines

| Machine | Required behavior |
|---|---|
| Composer | Deterministic precedence from read-only/permission/offline constraints through sending, recording, upload, edit, mention, reply, typing, and idle |
| MessageBubble | Normal, hover, selected, multi-selected, delivery, failure/retry, edited, recalled/deleted, and ephemeral states |
| ConversationItem | Active, selected, unread, muted, pinned, draft, typing, failed, and offline presentation |
| MessageList | Loading older, ready, empty, error, following latest, reading history, and multi-select |
| Search | Idle, typing, loading, results, empty, and error |
| Thread | Loading, ready, empty, error, locked, and permission denied |
| Reaction | Idle, pressed, selected, loading, failed, and disabled |
| Upload | Queued, preparing, uploading, paused, failed, complete, and cancelled |
| CallDock | Idle, incoming, connecting, active, reconnecting, ended, and failed |
| ContextMenu | Closed, opening, open, invoking, and closing |
| MultiSelect | Inactive, active, range selecting, action pending, and clearing |

## Composer precedence

The composer never derives state from rendering order. Constraint states win in this order: read-only, permission denied, offline, slow mode, send blocked. Active operations then win: sending, recording, uploading, editing, mentioning, replying, typing, idle. Each reducer also returns allowed intents so hosts do not infer action availability from color or labels.

## Selection and gestures

Selection reducers support replace, toggle, extend-range, and clear against stable IDs. Swipe intent requires at least 56 logical pixels and 1.25 horizontal dominance, honors RTL, and is disabled for system rows and multi-select mode.

## Message capabilities

All four packages expose resolveMessageCapabilities. It accepts the orthogonal lifecycle, ownership, moderation permission, and content support flags, then returns the product-neutral action set: reply, reaction, copy, forward, multi-select, edit, delete, recall, pin, save, translate, and report. Terminal and failed states suppress incompatible actions; hosts still own authorization and command execution.

These reducers are UI policy, not a second source of truth. Hosts map Core state into the reducer input and send resulting intents back to Core or navigation.
