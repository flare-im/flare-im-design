# Account page presentation

The four design Kits serve Web/Tauri, Flutter, iOS and Android. `PluginPage.appearance` defaults to `document`; a resolved `presentation.renderer: "account"` still selects AccountView automatically. `account` explicitly selects AccountView. The Kit contains no plugin IDs, SDK calls, financial validation or calculated balances.

`presentation.props.layout` selects the hierarchy:

- `wallet`: real wallet cards, declared record shortcuts, account information, then service rows. Cards use original row amounts and their column labels; overview fields remain in account information. Book and spendable amounts are not interchangeable. Wallet home does not render its description; flow and ledger descriptions remain unchanged.
- `flow`: step, summary and description, result state, then the original labeled receipt and guarded form. No field becomes a large balance merely because it is first. The original block order and result/unavailable fallback remain authoritative.
- `ledger`: wallet context and description, optional declared summary, records, then services. The description is not repeated inside a summary. Filters and pagination remain server queries.

Without a layout, the legacy first-field headline and remaining statistics remain unchanged. Values are opaque server-formatted strings. The eye control hides overview values and announces the hidden state; `maskRowAmounts` additionally hides row amounts. No totals are inferred or currencies combined.

In rows, cell zero is the exact amount. Declared labels, independent badges and time columns supply the remaining context. Identity is the block and original row key; duplicates within one block keep the first. Existing merged rows remain authoritative. Direct navigation only uses the explicitly declared eligible row action; otherwise local details reuse the original PluginView action, confirmation and form runner. Original page, data, row input, busy/error state, unknown-outcome lock and settlement signals remain intact.

## Shared available-container geometry

`Screen.contentMaxWidth` is optional and defaults to no constraint. `PluginPage.contentMaxWidth` defaults to the 880 directory token; explicit null opts out. The outer width includes page gutters and applies to the header, filters, every body state and pagination. Backgrounds fill the pane. Tauri uses the existing generic drawer width prop for plugin pages, with its normal window clamp; other settings drawers keep their width.

For container width `w`, outer width is `min(w, 880)` and inner width is outer minus 32. Body insets are 16 horizontal, 12 top and 20 bottom plus native safe areas. Wallet cards use one column below 572 inner width, otherwise at most two with a 12 gap. One card fills the row. A labeled inline form is at most 420 wide and lives inside 16-unit receipt insets: 256 at a 320 container, 326 at 390, and 420 at 768 or wider.

Wallet title and action groups keep a minimum 12-unit gap both inline and when wrapped. Wallet cards align at the top and retain their natural height; the tallest card determines only the next row’s vertical position, without stretching its neighbours.

Focused headers use 12 horizontal and 8 vertical insets, a 48-unit minimum inner height, a 48-unit back target, an 8 gap and a 24 bold title. Account section titles are 15 semibold; ledger sections 18 semibold; wallet names 20 semibold and amounts 24 bold. Metadata labels are 12, values 14 medium, with a 4 label gap, 12 column gap and 8 row gap, at most two columns. Wallet cards use 16 padding and an 8 internal gap. Legacy 44-unit headlines and specialized payment components are unchanged.

Flow step/summary/description use an 8 gap, followed by 12 to the result or receipt. Step text is 12 semibold brand, summary 15 semibold and description 12 secondary. Ledger context is 13 medium primary and description 12 secondary, with an 8 gap. Shared tokens provide theme, borders and surfaces.

## Visibility and accessibility

Nonblank warning/danger **note and status** blocks stay visible exactly once outside the wallet/ledger information disclosure. Info/neutral blocks remain ordinary information. Flow keeps its original blocks and existing result/unavailable priority; Kit does not infer a business outcome. Information controls have a 48-unit minimum target. Section and date headings expose heading semantics; hidden balances are announced. Long original amounts, labels and status reasons wrap without truncating financial text.

Loading, first-read failure, loaded-read failure, unavailable, read-only, busy, empty, form errors and unknown outcomes remain distinct. Failed form settlement retains values; successful settlement resets only the original form. Passwords and confirmations retain their existing guarded components.

## Shared display probes

`spec/account-layout-vectors.json` provides six display-only clones: wallet, flow and ledger in Chinese and English. Seven viewport expectations cover 320/390/603/604/768/880/1360, including the exact one-to-two-column boundary, form caps, typed warning/danger, ordinary information, long amounts and opaque row actions. These are explicitly synthetic modifications of historical resolved fixtures, not new resolver or database output. The generator is preserved in the workspace's `.planning/2026-11-09-wallet-ui-kit-alignment/` directory.

Existing `account-view-vectors.json`, 44 wallet flows, 32 cashflows, multiple-wallet, record, scoped-history and payout-kind fixtures remain available without rewriting historical data. Rendering tests collect emitted actions only and never execute a financial operation. Product builds and actual-device acceptance are separate evidence.

Local detail titles may use `presentation.props.detailTitle`, falling back to `sectionTitle`; `rowKeyLabel` overrides the record-key caption.
