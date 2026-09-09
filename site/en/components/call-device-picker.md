---
title: CallDevicePicker
---

# CallDevicePicker

Controlled microphone, speaker and camera selection. The host supplies stable device IDs, labels, confirmed selection and busy state. Denied permissions, pending switches and empty inventories disable selection. Removed devices reset the displayed selection to a placeholder without selecting a replacement; empty and duplicate IDs are filtered.

<div class="flare-demo flare-demo--stack"><CallDevicePickerDemo /></div>

<ComponentApi name="CallDevicePicker" />

## Ownership

Vue emits `select({ kind, deviceId })`; native implementations use `onSelect(kind, deviceId)`. Set busy synchronously before switching hardware. Update selectedId only after the RTC provider confirms success; keep the previous value on failure and explain recovery. Scope results to the current account, call and request generation.

`permissionAction` / `onPermissionAction` has no arguments. The host requests permission or opens settings. Mounting this component does not access hardware, start RTC or trigger a permission prompt.

## Platforms

Vue uses CallDeviceGroup / CallDeviceKind / CallDevice. Native types have the Flare prefix. Kinds are microphone / speaker / camera (Microphone / Speaker / Camera in Compose). Supply one group per kind and use provider IDs, never localized labels as identity.

Swift: CallDevicePickerView; Compose: CallDevicePicker; Vue/Flutter: FlareCallDevicePicker. Native hosts provide vertical scrolling. Controls reserve at least 48 logical units.

## Screen sharing

Screen sharing is a separate operation, not a camera selection. The host invokes the system picker and shows sharing only after the user authorizes it and RTC publishes the track. Cancellation preserves the call; stopping sharing stops only its track. Use CapabilityBoundary for unsupported, denied and failed states, and retain hangup throughout.

The demo uses local fixtures. Hardware switching, permissions and screen sharing require validation with the host RTC plugin.
