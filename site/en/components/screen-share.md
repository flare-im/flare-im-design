---
title: ScreenShare
---

# ScreenShare

Screen-share control and status panel for an ongoing call. Capture, source enumeration, encoding and publishing all belong to the host or the RTC plugin; the component only presents the state the host reports and dispatches start, stop and cancel intents.

<div class="flare-demo flare-demo--stack"><ScreenShareDemo /></div>

<ComponentApi name="ScreenShare" />

Every state carries an icon, a label and a tone together — never colour alone. `idle` (neutral, devices icon) means nothing is being shared and the local user may start; `requesting` (warning, refresh icon) adds an indeterminate progress indicator while the system or plugin decides; `sharing` (success, video icon) deepens the status tint to emphasise that a share is live; `viewing` (info, eye icon) means someone else is presenting; `unavailable` (neutral, block icon) means the runtime or plugin has no screen-sharing capability at all. `busy` keeps the current tone and disables every button without removing it.

Visibility comes from the pure `screenShareActions(state, { hasStart, hasStop, hasCancel, busy })`, which returns `{ start, stop, cancel, enabled }`: `start` only for idle, `stop` only for sharing, `cancel` only for requesting, and `enabled` is false while busy. The component computes which buttons exist with `busy = false` and uses `enabled` only to disable them, so buttons do not jump around while a command is in flight. A viewer never gets `stop` — you cannot end someone else's share — and `unavailable` offers no action at all, only the reason in `detail`, instead of a button that would do nothing. `sourceLabel` shows only while sharing, `presenterName` only while viewing.

Permission denial is deliberately not handled here. Screen recording is the `screen` kind of `PermissionPrompt`, so a host whose permission was denied renders `PermissionPrompt(kind: "screen", state: "denied")` (and likewise for `restricted` / `unavailable`) and lets it own the explanation and the `openSettings` intent. Do not build a second refusal panel inside ScreenShare — one intent keeps exactly one path. ScreenShare's own `unavailable` describes a runtime that cannot capture at all (no browser capture API, no plugin), which is a different thing from a capable runtime whose permission was refused.

Hosts map `state` from their RTC session: set `busy` synchronously and dispatch `start`, move to `requesting` once the plugin opens the picker, then to `sharing` with `sourceLabel` filled in ("Entire screen", "Chrome window"), and to `viewing` with `presenterName` when a remote share track arrives. `detail` carries extra host explanation such as a bitrate-limited notice or why sharing is unavailable — not error codes. The component has no timers, retries or network side effects and never enumerates sources. Vue uses `@start` / `@stop` / `@cancel` with explicit `has-start` / `has-stop` / `has-cancel` props (false by default, hiding the button); Flutter, SwiftUI and Compose use `onStart` / `onStop` / `onCancel` callbacks and hide a button when its callback is absent.

The panel itself does not scroll and holds no list, so it drops into a call control area, a call-details overlay or a settings scroll container without introducing unbounded scrolling. Source names, presenter names and detail text wrap rather than overflow, and RTL layout is unaffected. Buttons are at least 48 logical units and keep their place, Tab / Enter work throughout, the status area is a polite live region so the requesting → sharing transition is announced, and the progress indicator has an accessible name. The demo runs on local state and does not stand in for a real RTC plugin or on-device permission acceptance. See the [full integration guide](/components/screen-share).
