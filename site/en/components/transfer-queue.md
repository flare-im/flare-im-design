---
title: TransferQueue
---

# TransferQueue

A bounded task queue composed from TransferProgress, with per-task recovery, refresh failure and retry-failed batch events.

<div class="flare-demo flare-demo--stack"><TransferQueueDemo /></div>

<ComponentApi name="TransferQueue" />

Batch retry includes failed tasks with a nonblank retry capability and `busy=false`. Cancelled, completed and busy tasks are excluded. Hosts set busy synchronously before executing commands and report each result independently. Partial failure retains successful tasks. Reload errors retain cached entries.

Use unique stable task IDs and a bounded height on native platforms. Native lists are lazy; the Web list scrolls within 60vh. Hosts supply a bounded window (recommended at most 50 tasks). The count describes this window, not global history. Operations, retry scheduling, concurrency, persistence and account isolation belong to SDK adapters. Unmounting this view does not cancel transfers.

Entries: FlareTransferQueue (Vue/Flutter), TransferQueueView (SwiftUI), TransferQueue (Compose). Native callbacks: onAction(id, action), onRetryFailed(ids), onReload(). Vue emits action({id, action}), retryFailed(ids), reload(). See the [full integration guide](/components/transfer-queue).
