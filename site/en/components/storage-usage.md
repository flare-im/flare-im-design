---
title: StorageUsage
---

# StorageUsage

The "storage space" section of the settings page: the host hands over a snapshot of per-category usage plus what it is able to clear, and the component shows it and dispatches the intent. Sizes, file counts and clearability are all measured by the host — the component starts no measurement, retries nothing, and deletes nothing itself. A category the host has not measured reads "unknown", never 0 B: an unknown size or percentage is reported as unknown, never as zero. All four platforms share the same pure functions: `formatBytes`, `storageTotals`, `storageShare`, `canClearStorage`.

<div class="flare-demo flare-demo--stack"><StorageUsageDemo /></div>

<ComponentApi name="StorageUsage" />

Rules: a row shows the category label, its size, an optional file count, a share bar and a clear button; the header carries the total and, when the host knows it, the free space left on the device. `bytes` that is `null`, `NaN`, infinite or negative renders the unknown text and draws **no** bar, yet keeps its clear button — not having measured a category is not evidence that it is empty. A category measured at exactly 0 bytes, or one the host cannot clear, shows no button at all rather than a dead one. `loading` with nothing measured yet renders a skeleton plus a spoken "measuring" status, never a fake empty list; `loading` with categories already known keeps them on screen. A whole-snapshot `error` keeps the known categories visible and offers re-measure and dismiss. Per category, `busy` locks that row alone and `error` keeps its reason with retry and dismiss, so a partial failure preserves every category that succeeded.

The total is the host's `totalBytes` when it supplies a usable one — it can see things the category list cannot. Otherwise the component sums the **known** categories and labels the result "at least" whenever something is unmeasured; passing a partial sum off as the whole would be a lie. Share bars come from `storageShare(bytes, total)` and are omitted when the size is unknown or the total is not positive, since a zero-width bar reads as "this category is empty".

Clearing is irreversible, so the button carries a danger colour **and** a trash icon — never colour alone — but the second confirmation is **not** in this component: `clear` is an intent, and the host wraps it in [DangerConfirm](/components/danger-confirm), then sets that category's `busy` synchronously before dispatching, and writes back either the new `bytes` or that category's `error`.

`formatBytes(bytes, locale?)` is identical on the four platforms and covered by tests on each: unknown (`null`/`NaN`/infinite/negative) → `null`, so the caller applies its own unknown text; `0` → `"0 B"`; below 1024 → `"N B"`; then 1024 per step through KB, MB, GB and TB with one decimal ("2.0 KB", "1.5 GB"), matching the existing attachment formatters on iOS and Android. `locale` lets the host thread its language through, while the digits and unit suffixes stay the same everywhere — one storage snapshot must not read two ways on the same user's two devices.

Entries: FlareStorageUsage (Vue/Flutter), StorageUsageView (SwiftUI), StorageUsage (Compose). Native callbacks: onClear(categoryId), onReload(), onDismissError(categoryId | null — null is the whole-snapshot error); a native panel with no onClear shows no clear button, and one with no onReload shows no re-measure. Category ids must be stable, every event echoes them. Rows are at least 48 logical units, native lists are bounded (Compose `LazyColumn` with a height cap, Flutter `ListView.builder` shrink-wrapped and non-scrolling), the clear button is announced as "clear + category name", and every state is text or icon as well as colour. See the [full integration guide](/components/storage-usage).
