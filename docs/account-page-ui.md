# Account page presentation

`FlarePluginPage.appearance` explicitly selects `document` or `account` in Vue, Flutter, SwiftUI and Compose. Without an explicit override, a resolved `presentation.renderer: "account"` selects the shared account presentation. The design kit contains no plugin IDs, SDK calls, financial validation or calculated balances.

The first declared field is the account headline, and remaining fields are statistics. Values are opaque, server-formatted strings. The eye control hides every overview value and announces the hidden state. `presentation.props.maskRowAmounts` also masks asset/wallet row amounts; transaction pages leave it false. No totals are inferred from a partially loaded ledger; currencies are not combined.

In account rows, cell zero is the amount. The resolved badge names the entry type; other text cells are its description. A declared time column supplies its date group and time; absent times remain unknown. Row identity is the block and the original row key; duplicates within a block keep the first row. The existing merged resolved rows are authoritative, rather than the first page's raw data. A leading plus changes display colour only.

Each entry opens local details, including entries without a packet action. Original columns, type, amount and row key are shown. Only actions both declared by the block and bound by that row are available. Existing PluginView confirms, forms, busy/error signals and settling are reused. Original row key/input and original page/data are forwarded unchanged. The parent page still owns loading, unavailable reasons, refresh, filters and cursor pagination.

Actions use low-emphasis text appearance; semantic primary/danger colours remain. Touch/focus targets remain present. Shared theme tokens and localized labels support light/dark and narrow layouts. Warning/danger notices stay visible, including unknown-operation recovery. Informational rules remain under a disclosure. `groupByDate: false` omits date headings for asset/wallet lists, and `sectionTitle` supplies the translated section label. There are no fabricated top-up or withdrawal controls.

Common regression fixture: `spec/account-view-vectors.json` (fictional balances and transactions). The Vue preview is `examples/vue/wallet.html`. Widget/unit regressions cover exact amount text, row identity, unknown dates, empty/unavailable/error states, balance masking, original bound action input and page data. Product builds are verified separately from fixture interaction tests.

详情标题可由 `presentation.props.detailTitle` 指定，缺省使用 `sectionTitle`；`rowKeyLabel` 可覆盖详情中的“记录编号”标签。
