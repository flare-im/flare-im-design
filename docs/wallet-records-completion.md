# Wallet record completion

The reference supplies hierarchy only. Record pages retain Flare's current theme and use the same resolved plugin declarations in Vue, Flutter, SwiftUI and Compose. The wallet now declares 24 consumer pages, including separate recharge and withdrawal histories and authoritative record details.

## Record behavior

- Transaction history supports server-side income/expense filters. It represents a wallet, asset and funds order's exact net change across its owned accounts. Zero-net freezes and releases remain internal movements in the unfiltered list. Different wallets and assets are never summed together. The existing low-level per-account `transactions.list` contract remains compatible.
- Recharge and withdrawal history share an owner-scoped query with direction, processing status and stable server pagination. Their dedicated entry points fix the relevant direction. The amount is labeled as the requested amount; completion and approval remain separate statuses.
- Entry navigation uses the explicitly declared row detail action and original opaque input. Transaction detail includes net change and labeled journal entries. Cashflow detail uses the existing receipt/proof/recovery actions, including their original confirmation and credential guards. No fee or completion result is invented by the UI.
- Record titles, independent semantic status/direction tags, wallet/asset descriptions, exact display amounts and localized times use the same mapping on all four kits. Records precede secondary service actions. Narrow layouts wrap the amount rather than truncate it.
- Filters request a new first page through the host and apply only after success. There is no filtering of the currently loaded rows in the kit. Loading, empty, first-read failure and loaded-read failure have distinct states; loaded records survive a read error and expose retry.

## Host concurrency

First-page queries invalidate old pagination tickets and clear their busy state. Old paging success, error and finally handlers cannot replace a new query or release a newer paging request. Paging is blocked during first load or refresh. `PluginPage.pagingToken` releases a cursor after a read settles, including repeated identical errors completed within one render frame.

Read errors use the page error channel. Refresh and paging retry preserve financial action errors, field errors, `settleToken`, pending-operation identity and unknown-outcome locks. These changes are read-side state management, not a new financial retry mechanism.

An independent review also found a pre-existing Vue route boundary: a previous page's late action could clear a new page's action lock, errors and form settlement. Route/session changes now invalidate an independent action ticket and reset only the UI presentation session, suppressing old page navigation as well as old result/catch/finally handlers. The port's financial command journal remains untouched. A same-page read refresh does not invalidate the current action.

## Canonical display fixtures

[`wallet-record-vectors.json`](../spec/wallet-record-vectors.json) has 22 Chinese/English cases. Explicit synthetic projection inputs pass through the actual Rust declarations and resolver; the resulting views cover income, expense, internal movement, cashflow states, requested amounts, journal breakdowns and receipt details. They are not claimed as live or database query output. Database query assertions are separate.

The public `PluginPage` signature, including `pagingToken`, has no missing properties or events on any of the four platforms. Flutter's public `FlareTag` matches its declared API; SwiftUI and Compose retain their internal plugin badges rather than claiming a new public Tag component.

## Validation scope

| Surface | Evidence |
| --- | --- |
| Wallet contract and artifacts | 22 contract tests, the standard Rust-source/six-platform generated-artifact consistency check, three SDK Node tests, targeted Rust formatting and diff whitespace checks passed. |
| Isolated PostgreSQL | Six focused query/owner/cursor/read-only and hold/withdrawal lifecycle tests passed (74 filtered, wrapper exit 0), using a Unix-socket-only owned cluster with distinct nonsuperuser owner/runtime roles. The separate version-12-to-13 upgrade test passed. |
| Vue kit | 93 focused account/page/rows/detail tests and typecheck passed. |
| Core Vue host | 19 tests and typecheck passed, including stale paging results, failed-filter rollback, repeated retry, financial-error isolation, stale action results/navigation across routes and current action settlement across refresh. |
| Browser | 22 resolved cases across 320/390/1360 widths and light/dark passed six matrices. Navigation keeps the original input; filter requests preserve other dimensions; amounts do not truncate; loaded-error retry retains records. A separate synthetic very long amount also wraps without squeezing the title into individual characters. Final English enum-value updates passed two additional matrices. |
| Flutter | 44 record renders (22 cases at phone/desktop widths), 11 focused record checks, eight final caption checks and five app host/profile tests passed; targeted analysis passed. |
| SwiftUI | 62 kit tests (including 22 record vectors and six native renders) and 14 app host tests passed, including paging ownership, failed-filter rollback, same-error retry and financial-error isolation. Renders use the production SwiftUI components on macOS, not an iOS simulator run. |
| Compose | 39 kit tests, seven app host tests and 15 emulator UI interactions passed; six record/receipt renders and a narrow long-amount capture were inspected. |
| Shared contracts | Four-platform PluginPage signatures, Vue/Flutter Tag signatures and component/geometry contracts passed. |

Final detail fixtures passed incremental Flutter and native checks after the consumer fields were reduced to seven and English field values were localized. Independent review found no further SQL scope, cursor, net-amount or migration/grant defect.

The initial full wallet integration run had 63 passes and 17 failures. A process-restart timeout passed on a later rerun; other failures concern signed RPC fixture feature declarations, a default-limit expectation and existing funding permission expectations. The full 80-test run is not claimed as green. Focused query and lifecycle checks above passed after the final migration change.

Commands, exact failing case names and unchanged-source evidence are in the [wallet backend validation report](../../flare-plugins-commercial/plugins/wallet/server/docs/user-record-query-validation.md). No clean-baseline full-suite run was performed; unchanged-source evidence is not represented as such a run.

The repository-wide public API check still reports four unrelated unregistered Vue exports and an existing `FlareConnectionNotice` registry/export mismatch. Full specification validation reports 29 other signature differences (message/group/call/admin/media surfaces); it reports no PluginPage or Tag drift. These are not represented as passing release gates.

No backend deployment, live account mutation, live payment, recharge or withdrawal was performed during this work. UI fixtures only collect emitted actions. Local database validation uses an owned isolated PostgreSQL cluster.

## Local previews

- Vue: `flare-im-design/.local/wallet-records/vue/` (96 phone/desktop, light/dark captures, including explicitly synthetic overflow probes).
- Flutter: `flare-im-design/.local/wallet-flow-refinement/flutter/flutter-record-*.png`.
- SwiftUI: workspace `.local/wallet-records/ios/`.
- Compose: workspace `.local/wallet-records/android/`.

## Upgrade compatibility

New read functions live in the additive `wallet.user-record-queries` initialization step 13 with explicit runtime execute grants and PUBLIC execution revoked. Historical step-1 and step-9 SQL retain their task-start contents, including pre-existing workspace changes. The old `transactions.list` query and generated `TransactionView` / `WalletPageRequest` schemas retain their previous shape. A version-12 database was upgraded in the private test cluster without changing historical steps.

Production and sandbox wallet artifacts were synchronized with the standard exporter and checked against Rust source. The new service queries require the normal wallet service upgrade; no running development or production wallet database was migrated here. The owned PostgreSQL cluster and test processes were stopped after verification.
