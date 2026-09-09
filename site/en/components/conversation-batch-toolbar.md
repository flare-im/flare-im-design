---
title: ConversationBatchToolbar
---

# ConversationBatchToolbar

Batch bar for multi-select mode in the conversation list: selection count, the batch actions the host can honour, the in-flight state, and — the part that makes it more than a button row — a partial-failure summary with per-item recovery. It shares the bar / count / actions / cancel visual with MessageBatchToolbar and adds the result strip that delivers the "keep the successes, recover each failure individually" rule from the global state contract.

<div class="flare-demo flare-demo--stack"><ConversationBatchToolbarDemo /></div>

<ComponentApi name="ConversationBatchToolbar" />

States: nothing selected disables every action and shows `emptyText`; a selection shows the count and the capability-enabled actions; exceeding `maxSelection` disables the actions and shows `maxSelectionText` (`{n}` is the limit); `busy` disables everything and shows progress plus an accessible label on the pending action; a previous partial failure shows both "N succeeded" and "N failed" and expands to each item's title and reason with a retry button; a fully successful batch shows only the dismissible success summary — never a global success toast.

Visibility comes from the pure `batchActionsAvailable(selectedIds, capabilities, busy, maxSelection)`: an absent or false capability removes the action entirely, and an empty selection, `busy` or an over-limit selection all return an empty list. `summarizeBatchResult(result)` computes the counts and the deduplicated `retryIds` in failure order, which is the `retryFailed` payload. Action order is fixed across platforms as `markRead → mute → archive → delete`, with delete always last, rendered with the error tone plus its icon.

**Delete is not confirmed inside the toolbar.** The component only emits `action({ action: 'delete', ids })`; the host must route it through DangerConfirm. Confirming inside the toolbar would give one intent two confirmation paths.

Pass stable conversation ids in `selectedIds` — never array indices or titles. Set `busy` synchronously before dispatching, then write `result` and clear `busy`: drop the succeeded ids from the selection and keep the failed ones selected so the user can retry straight away. Permission denials, deleted conversations and network failures are mapped to a user-facing `reason` by the host; the component does not know error codes. Concurrency limits, idempotency and account isolation belong to the SDK adapter — and switching accounts must clear both the selection and `result`, never carrying the previous account's outcome across.

Vue emits `action({ action, ids })`, `retryFailed(ids)`, `clearSelection()`, `dismissResult()`; Flutter, SwiftUI and Compose take `onAction(action, ids)`, `onRetryFailed(ids)`, `onClearSelection()`, `onDismissResult()` and hide the corresponding affordance when a callback is absent.

At 320 width the actions wrap rather than overflow, and buttons stay at least 48 logical units. The failure list is bounded and scrolls internally (a lazy list on natives); long titles and reasons wrap. The count and result summary are polite live regions so the end of a batch is announced, and the expand/collapse control exposes `aria-expanded`. Delete carries an icon and its own group, so danger is never signalled by colour alone. The demo runs on local state and does not stand in for real SDK batches, concurrency limits or on-device screen-reader acceptance. See the [full integration guide](/components/conversation-batch-toolbar).
