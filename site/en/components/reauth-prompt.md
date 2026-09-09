---
title: ReauthPrompt
---

# ReauthPrompt

Re-authentication panel shown when the session can no longer be used: names the reason (expired / kicked by another device / credential invalid / account disabled), locks repeat submits, keeps the last failure visible and dispatches actions to the host. The host owns the login flow and the container (full-screen overlay or dialog); no mask is included.

<div class="flare-demo flare-demo--stack"><ReauthPromptDemo /></div>

<ComponentApi name="ReauthPrompt" />

`reauthActions(reason, {hasReauth, hasLogout, busy})` decides visibility and enablement: `reauthenticate` needs a host handler and is never offered for `accountDisabled`; `logout` needs a host handler; `busy` disables everything and shows a progress indicator with `busyText` in the primary button. `error` stays in the panel until the host clears it. Enter triggers the primary action when not busy; Escape never dismisses (Web stops propagation, SwiftUI uses `interactiveDismissDisabled`, Compose consumes the key; hosts disable system back on their container).

Set `busy` synchronously before dispatching, close the container on success, and write the user-facing failure into `error` otherwise. Use `logoutText` to label the secondary action as sign out or switch account. Buttons without a bound handler are not rendered.

Entries: FlareReauthPrompt (Vue/Flutter), ReauthPromptView (SwiftUI), ReauthPrompt (Compose). Native callbacks: onReauthenticate(), onLogout(). Vue emits reauthenticate, logout. See the [full integration guide](/components/reauth-prompt).
