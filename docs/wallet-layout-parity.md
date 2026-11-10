# Wallet layout refinement

The reference image supplies hierarchy. The implementation retains Flare's current theme, typography, tokens and plugin-driven financial workflows.

## Shared composition

All four kits use the resolved `account` presentation: one collection of actual wallet/account cards, declared quick actions, account information, then service rows. The former overview balance and “My wallets” list no longer repeat the same amount. Each card uses its original row amount, column label, name and metadata; all overview fields remain in account information because spendable and book balance can differ. Consumer flow pages use a step description, labeled receipt and the existing guarded action runner. Desktop content is centered within the existing 880 directory width token; phone controls wrap to the available width and multiple wallet cards form a grid on desktop.

The initial layout refinement covered 20 consumer pages; the later records extension is documented in [wallet-records-completion.md](wallet-records-completion.md). Confirmation and checkout retain the specialized `payment.confirm` renderer. Opening requests use ordinary labeled rows; restricted funds and cashflow history supply amount/name/description columns in the account renderer's expected order.

The subsequent card-to-ledger refinement is documented in [wallet-card-ledger.md](wallet-card-ledger.md): one-click scoped history, compact record shortcuts, localized wallet/status copy and explicit wallet context. Historical validation and deployment statements below describe the initial refinement only.

Public `PluginView` additions:

- `actionLayout`: inline (default), compact or list. Only the visual grouping changes.
- `labelRows`: false by default; flow rows show the primary column caption and pair secondary values with column labels.
- `showError`: true by default; composed runners may hide their outer banner while keeping errors visible in open forms and continuing to process settlement.
- `inlineFormActionId`: opt one eligible top-level action into visible page data entry. Complete bindings, a non-password form, no confirmation, an available writable view and an action listener are required. Other actions retain their guarded sheets.

`PluginForm.embedded` removes sheet insets and the cancel key, retaining the original action label on a full-width submit. Inline submission locks synchronously, retains values and errors after failed settlement, and resets only that form after clean settlement. Mounting the form never executes an action. Password, payment-confirmation and row actions retain their existing flow.

Actions use the visible resolved IDs, with wallet slots `primary`, `secondary`, `tertiary` and flow slot `submit`. Visible conditional primary actions remain primary after authorization or password-state changes. Confirmation, form input, page/data/row binding, permissions, busy state and unknown-result recovery remain with the original runners and SDK.

In the initial layout refinement, the standard wallet exporter synchronized the production and sandbox template manifests; other SDK model, API and operation artifacts were unchanged. The subsequent record-query extension has its own validation report. No deployment or live financial commands were performed.

## Verification

| Surface | Evidence |
| --- | --- |
| Rust wallet contract | 19 focused tests and generated-artifact consistency passed; action input, guard and continuation structures preserved. |
| Vue | 177 account/page/action/form tests, typecheck, and compilation of all 269 SFCs passed. |
| Browser | 44 resolved views plus the multiple-wallet case across 320, 390 and 1360 widths in light/dark: six matrices passed. Inline submit reachability, wallet grid, masking and section order checked. Original screenshots saved under `.local/wallet-flow-refinement/vue/`. |
| Flutter | 37 account/wallet/inline tests and 24 existing action checks passed. An additional dynamic eligibility-loss/restore regression passed while preserving the external SDK busy lock. Analysis passed. |
| SwiftUI | 60 related tests passed; the final header/icon refresh passed another 13 account/snapshot checks. Snapshots render the production SwiftUI components on macOS, rather than an iOS simulator session. |
| Compose | 37 related JVM tests and 12 emulator interactions passed, including wallet bindings, inline data entry, repeat-submit locks, error retention/reset and password/confirmation fallback. |
| Shared public API | PluginView has no missing props/events on the four platforms; shared control geometry checks passed. Vue's existing administrative extension events remain outside this shared signature. |

The 44 shared resolved vectors include nonempty wallet, opening, history, restricted-fund and cashflow rows, authorization/password variants and pending-operation recovery in Chinese and English. A separate synthetic `wallet-card-vectors.json` adds multiple currencies, duplicate rows and a deliberately different overview spendable amount. Fixtures contain display-only sample values and run without submitting financial operations or calculating a total across wallets.

The initial Android modal-form system capture was obscured by an emulator ANR dialog and excluded from evidence. The follow-up now includes valid direct page-form captures for recharge, withdrawal and payout profiles, plus phone/desktop multiple-wallet captures.

One repository-wide check remains unrelated to these wallet changes: `check-platform-contract.mjs` rejects an existing `matchMedia("(hover` use in `EnhancedComposer.vue` outside the platform module. The wallet-specific checks above passed.

## Local previews

- Vue/Flutter originals: `flare-im-design/.local/wallet-flow-refinement/`.
- SwiftUI/Compose originals: workspace `.local/wallet-flow-refinement/ios/` and `android/`.
- Shared declarations and behavior: [plugin-components.md](plugin-components.md#钱包与资金流程的-account-布局).
- Canonical display data: [wallet-flow-vectors.json](../spec/wallet-flow-vectors.json).
