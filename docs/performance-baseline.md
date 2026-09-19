# Performance baseline

## Automated structural baseline

| Surface | Dataset | Automated invariant |
|---|---:|---|
| Vue conversation list | 1,000 and 10,000 | Rendered rows remain bounded to viewport plus overscan; stable keys |
| Message list | 10,000; 100,000 projected | Lazy/windowed projection; prepend preserves anchor |
| Flutter | 10,000 rows | `ListView.builder`; stable item identity; no eager child list |
| Compose | 10,000 rows | `LazyColumn` with keys; item state remains scoped |
| SwiftUI | 10,000 rows | `LazyVStack`/`List` with stable IDs |
| Transfer/reaction stress | 100 uploads / 500 reactions | Item-scoped updates; bounded summary UI |

## Physical budgets

- 60 Hz device: p95 frame under 16.7 ms during steady scroll; no frame over 100 ms.
- 120 Hz device: report both 8.3 ms and 16.7 ms thresholds; do not hide missed high-refresh frames.
- Opening and closing a thread 20 times must return within 10% of settled memory.
- Media decode is thumbnail-first and viewport-scoped; only the active media item may play.
- Conversation and message scroll position must survive one prepend and one reconnect.

## Repeatable capture

Record commit, release version, device model, OS/API, refresh rate, build mode, dataset seed,
three cold runs, five warm runs, p50/p95/p99 frames, peak/settled memory, and retained object
counts. Android uses Macrobenchmark/Profiler; iOS uses Instruments; web uses Chrome Performance;
Flutter uses profile mode DevTools. Host build durations are diagnostic only and are not frame
or memory evidence.

Physical measurements are `MANUAL_REQUIRED`; see `manual-release-blockers.md`.
