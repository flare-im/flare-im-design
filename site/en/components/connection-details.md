---
title: ConnectionDetails
---

# ConnectionDetails

Detail panel for connection and session state, used behind a StatusBanner ("connection details") or as the "network and connection" page in settings. The host supplies the state, the already-formatted facts (transport, endpoint, last sync) and the user-facing reason; the component only presents them and dispatches reconnect, re-authentication and copy-diagnostics to the host.

<div class="flare-demo flare-demo--stack"><ConnectionDetailsDemo /></div>

<ComponentApi name="ConnectionDetails" />

Every state carries an icon, a label and a tone together — never colour alone; `connecting` and `reconnecting` add an indeterminate progress indicator. Tones and actions: `connected` (success) copyDiagnostics; `connecting` (warning + progress) copyDiagnostics; `reconnecting` (warning + progress) reconnect, copyDiagnostics; `offline` (danger) reconnect, copyDiagnostics; `sessionExpired` (danger, lock icon) reauth, copyDiagnostics; `kicked` (danger, devices icon) reauth, copyDiagnostics; `sdkUnready` (neutral) no action at all, only the explanation that the client is not ready; `busy` keeps the current tone and disables every button without removing it.

Visibility comes from the pure `availableConnectionActions(state, { hasReconnect, hasReauth, hasDiagnostics, busy })`: `reconnect` appears only for offline / reconnecting, `reauth` only for sessionExpired / kicked, `copyDiagnostics` only when `diagnostics` is non-empty, `sdkUnready` never offers an action, and `busy` returns an empty list. The component computes which buttons exist with `busy = false` and uses `busy` only to disable them, so buttons do not jump around while a command is in flight.

Diagnostics are collapsed by default; expanded they are monospaced multi-line text bounded to 240 logical units with internal scrolling. The copy action only emits an event — writing to the clipboard is the host's job (on the web the Clipboard API must be called inside the user gesture).

Hosts map `state` from the SDK connection state machine and pass `lastSyncAt` already localised; the component never parses time. `reason` is a user-facing cause, not an error code — codes, close codes and retry counts belong in `diagnostics`. Vue uses `@reconnect` / `@reauth` / `@copy-diagnostics` and explicit `has-reconnect` / `has-reauth` props (false by default, hiding the button); Flutter, SwiftUI and Compose use `onReconnect` / `onReauth` / `onCopyDiagnostics` callbacks and hide the button when one is absent. Set `busy` synchronously before dispatching and clear it once the new `state` flows back; the component has no timers, retries or network side effects.

The panel itself does not scroll — place it inside a settings scroll container or an overlay; only the diagnostics area scrolls, and it is bounded. Long endpoints are visually truncated (natives truncate in the middle) while the accessible name stays the full address, and endpoint plus diagnostics text is forced LTR so an RTL interface cannot break URL reading order. Reason and button labels wrap, buttons are at least 48 logical units, Tab / Enter work throughout, and the diagnostics toggle exposes `aria-expanded`. The status area is a polite live region so state changes are announced. The demo runs on local state and does not stand in for the real SDK state machine or on-device screen-reader acceptance. See the [full integration guide](/components/connection-details).
