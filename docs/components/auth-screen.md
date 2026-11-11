# Authentication screen

Core authentication remains product code in
`flare-core-examples/shared/vue-reference/workbench/app/components/AuthScreen.vue`.
It now composes the public `FlareAuthShell`, `FlareFormField`, `FlareInput`,
`FlareButton` and `FlareIcon` instead of owning a second login layout.

The common brand, linked-message motif, responsive geometry and shared token
measurements are defined in [Authentication product experience](../auth-product-experience.md).
Social Web/Tauri, Flutter, Compose, SwiftUI and Console use that same shell.
Core still supplies its supported identity flow; Social supplies password,
registration and invitation flows; Console supplies its existing staff,
captcha, MFA and account-recovery flows. The kit owns presentation only.

On wide screens the brand occupies 44% and the form 56%, with a 420 logical-pixel
form maximum. Below 900 the decorative story is omitted and a compact wordmark
precedes the single task heading. Short windows, large text, registration and
software keyboards keep fields and the primary action reachable by scrolling.
Both themes and both languages share the same semantic hierarchy.

Focused Vue `AuthScreen.test.ts` checks the field, submission guards, loading,
identity retention and unique accessible references. The browser login-surface
suite covers narrow/short/desktop layouts, keyboard flow and both themes.
Native shell renders, unit tests, app compilation and actual device checks are
reported separately; adopting the shell does not imply every authentication
backend has been exercised.
