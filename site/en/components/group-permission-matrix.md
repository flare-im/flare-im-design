---
title: GroupPermissionMatrix
---

# GroupPermissionMatrix

The "group settings" section of group management: join policy, mute-all, only-admins-can-@everyone, only-admins-can-pin, and allow-sharing-the-group-card. Each row maps to a field that really exists on the group model (`joinPolicy`, `muteAll`, `onlyAdminCanAtAll`, `onlyAdminCanPin`, `shareCardPermission`) — the component invents no permission the backend does not have. Visible rows and their state come from the shared `groupPermissionRows(settings, canManage, busyKeys, errors)` contract, so all four platforms render the same set, order and read/write shape.

<div class="flare-demo flare-demo--stack"><GroupPermissionMatrixDemo /></div>

<ComponentApi name="GroupPermissionMatrix" />

Rules: with `canManage = true` the four flags are switches and the join policy is a three-way radio group; with `canManage = false` every row becomes a read-only value (on/off text, policy label) rather than a disabled switch, and the header explains that only the owner and admins can change them. `busyKeys` locks one row at a time — its siblings stay usable — and `errors` keeps that row's reason on screen with retry and dismiss. A partial failure therefore keeps the settings that succeeded and reverts nothing else. A `joinPolicy` outside 1/2/3 is passed through untouched: no option is selected and the panel says the current policy is unknown, instead of misreporting the group.

Toggling only emits `change`; the component never flips the value itself. The host writes the confirmed `settings` back after the SDK acknowledges, so a failure naturally leaves the old value on screen. The payload is `{ key, value }` — boolean for the flags, number for the join policy (SwiftUI spells the union as `FlareGroupPermissionValue.flag/.policy`; Flutter and Compose use `Object`/`Any`). `dismissError` carries the key only. Retry re-sends the last intent this component dispatched; with none recorded a toggle falls back to flipping its current value and a choice row offers no retry button, since its three options are right there.

Hosts add the key to `busyKeys` synchronously before dispatching, remove it when the command returns, then write either `settings` or `errors`. The key names are shared across platforms: `joinPolicy`, `muteAll`, `onlyAdminCanAtAll`, `onlyAdminCanPin`, `shareCardPermission`.

Entries: FlareGroupPermissionMatrix (Vue/Flutter), GroupPermissionMatrixView (SwiftUI), GroupPermissionMatrix (Compose). Native callbacks: onChange(key, value), onDismissError(key); a native panel with no onChange renders read-only. Rows are at least 48 logical units, switches expose `role="switch"` with the row label, the policy group is a radio group, and state is never colour alone — read-only shows text, busy shows a progress label, failure shows an icon plus its reason. See the [full integration guide](/components/group-permission-matrix).
