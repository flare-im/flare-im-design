# Performance Contract

The enforceable evidence map is `spec/performance-contract.json`.

| Scenario | Budget |
|---|---|
| 1k conversations | Render only the visible window |
| 10k conversations | No eager 10k-node UI tree; stable keys and windowing |
| 10k messages | O(visible plus overscan) rendered rows |
| Estimated 100k messages | Host supplies a bounded paged projection and stable reading anchor |
| Many images | Decode near the viewport; display thumbnail before original |
| Upload queue | Progress updates rebuild only the changed transfer row |

Vue conversation lists switch to explicit windowing above a configurable threshold; Vue message lists already use a virtual window. Flutter uses builder/sliver delegates, Compose uses `LazyColumn`, and SwiftUI uses `List`/`LazyVStack`.

Stable identity is mandatory for scroll restoration, focus continuity, and item-scoped updates. The design kit does not retain an unbounded authoritative timeline; Core and the host own paging and eviction.

Run `node tooling/check-performance.mjs` to verify the evidence paths and required implementation terms. Runtime frame-time and memory profiling remain release checks on representative devices.
