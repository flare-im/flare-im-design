# Wallet card and transaction navigation

Wallet cards now open their own full transaction history in one action. The wallet plugin declares the existing `wallet` row action as a navigation to `history`, with the original row-bound `walletId`. The kits use the same `rowEntryAction` guards as transaction rows: available, writable, declared in both row and block, listener present, no form or confirmation, and no active action. Otherwise the original detail and guarded runner remain available.

The home page hierarchy is wallet cards, bill/history shortcuts, account information, then account/security services. Three optional generic presentation slots (`shortcutPrimary`, `shortcutSecondary`, `shortcutTertiary`) select only resolved visible actions. Primary actions take precedence, then shortcuts, then services; duplicate IDs render once. The shortcut group uses the existing compact action runner and wraps on narrow screens. The redundant combined cashflow home entry is removed; its underlying page and query remain available.

Balances remain the server's original strings. Known primary-wallet names and status values are localized by the wallet contract; custom names are retained. Single cards use the available desktop content width; multiple cards form the existing responsive grid. Metadata uses labeled compact columns and the card's declared entry label provides a clear footer. No cross-wallet or cross-asset total is calculated.

Scoped history binds the server's `walletContext` to generic `contextLabel`, separate from monetary fields. The owner-checked wallet and its actual asset labels identify the current scope. Income/expense filters, server cursors, retries and detail bindings retain `walletId`. Global history leaves the context absent. The database query semantics and schema 13 are unchanged.

Scoped history also declares a “钱包管理” action to the existing wallet management page, preserving the same walletId and its original fund restrictions, default-wallet and guarded financial/account actions. Global history hides this action. Direct card navigation therefore preserves access to existing wallet capabilities.

The final immutable wallet version is 0.2.4. Its migration declaration retains offline, irreversible behavior for older pre-schema-13 versions and explicitly declares same-schema upgrades from 0.2.2 onward online and reversible. No new financial command, permission or capability is enabled by this UI change.

Synthetic projection fixtures are resolved through the actual Rust contract: 44 flows, 22 record views, one multiple-wallet case and four scoped history views. They exercise presentation and emitted bindings; they are not database output. Reproducible helpers are preserved in the workspace's `.planning/2026-11-09-wallet-card-ledger/fixtures-source/`.

Validation and live PC acceptance are recorded in the workspace's `.planning/2026-11-09-wallet-card-ledger/` report. Source alignment spans Vue, Flutter, SwiftUI and Compose; native typechecking and JVM tests do not constitute iOS/Android device acceptance.
