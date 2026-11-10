# Upload

## Overview
Represent queued media transfer and recovery without owning transport.

## When to use
Represent queued media transfer and recovery without owning transport.

## When not to use
Do not treat UI progress as authoritative upload state.

## Anatomy
file identity, progress, state, retry, pause, cancel. Regions use semantic tokens and host-owned content.

## Variants
single progress, queue, drop composition. Choose one variant from task priority, not decoration.

## Sizes
list or compact inline. Minimum interactive targets remain 48 logical pixels.

## States
queued, transferring, paused, completed, failed, cancelled. Loading preserves geometry; errors keep a recovery path.

## Interactions
Components emit intent callbacks. The host owns data, permissions, persistence, and side effects.

## Keyboard
Actions are reachable by Tab and expose progress values.

## Accessibility
Provide a localized name, role, state, availability, focus order, visible focus, and reduced-motion equivalent. Decorative imagery is hidden.

## Responsive
Preserve the primary task. Supporting regions become a drawer, sheet, overlay, or route rather than compressed desktop geometry.

## Platform differences
Vue uses ARIA and pointer conventions; Flutter uses Semantics and Focus; Compose uses semantics and native gestures; SwiftUI uses accessibility traits, Dynamic Type, and native presentation. Semantic states and intents remain identical.

## Code examples
Use the public component named in `spec/components.json`; supply controlled state and intent callbacks. See the shared fixtures in `examples/gallery/gallery-manifest.json` for deterministic examples.

## Fixed photo slots

For a small fixed set of required photos, use `FlareImageUploadSlot` in Vue,
Flutter, Compose and SwiftUI. It presents a short title, a bounded photo area,
localized state and optional upload/retry action. The host owns the native picker,
local preview lifetime, validation and transfer; the component never requests a
remote image or persists bytes. States are empty, selected, uploading, uploaded
and failed. Uploaded slots are read-only by default. A host can explicitly supply an independent
preview callback and localized label; preview does not enable choosing, replacing or deleting
the uploaded file. The Vue wrapper below can separately opt into controlled replacement.
The host owns access checks, expiring preview bytes and cleanup.
Put format and size guidance once above the group. Use three columns
on desktop, two on mobile, and one for narrow layouts or large text; preserve
48 logical pixel interaction targets.

## Vue file and image field

`FlareFileUpload` composes the existing photo slot and a native single-file picker.
It is exported from the main, components and focused admin entries. The host
supplies localized labels, `empty | selected | uploading | uploaded | failed`,
file name, optional image preview and percentage progress. It emits `select(File)`,
`upload`, `retry`, `cancel` and `remove`; it never performs these operations itself.
Choosing the same file again works, while cancelling the native picker leaves the
current host-owned selection intact. Read-only state disables every mutation.

The `accept` hint comes from the authenticated backend policy. No file-size or MIME
limit is invented by the component, and native picker filtering is not a security
check. The host keeps durable media IDs separate from temporary previews, cancels
pending work when application/identity/form lifetime changes, rejects late results
and revokes object URLs. Replacing or removing a local selection is not remote media
deletion. Network progress reaching 100 percent is not proof of server completion.

Vue and Flutter provide `FlareFileUpload`. Native plugin forms compose the shared photo slots with equivalent controlled intents. No uploader or business transport is implied.

For SDK-resolved private material inputs, use the host-picker mode and typed
`PluginForm` file states/events described in [Plugin file inputs](../plugin-file-inputs.md).
The default Vue `select(File)` picker behavior remains available to existing general upload consumers.
The Vue slot's optional `replaceable`, `icon`, `progress` and `actions` slot enable
this composition while preserving its completed/read-only default.

## Do / Don't
Do keep task hierarchy and recovery explicit. Don't duplicate business state, invent platform-only semantics, or introduce local visual constants.

## Controlled image slot

Use `FlareImageUploadSlot` (Compose) / `ImageUploadSlotView` (SwiftUI) for a small image form field. This is a presentation component, not an uploader. The host supplies the title, localized status/action copy, `empty | uploading | uploaded | failed`, optional transient local preview and choose/retry callbacks. It never owns file picking, transport, remote material grants, persistence or business validation.

The rectangular body keeps stable geometry while uploading. Its title is outside the slot; an empty slot shows a camera/action, an uploading slot shows an indicator, an uploaded slot shows a check or the current local preview, and failure preserves a retry intent. The native slots and default Vue slot offer choosing again only before the business layer says the material is uploaded. The Vue file wrapper separately opts into controlled replacement; remote deletion is never implied. Do not fetch a historical private preview without an existing grant.

Place one format/size hint above a group, rather than repeating it on every field. Group layout belongs to the page: three columns at 600 logical pixels, two at 320, and one on narrow or large-text views. The slot and retry controls keep at least the kit touch target; status is exposed to assistive technology without displaying internal error codes. Titles, status, action and retry strings must be localized by the host.

In SwiftUI, compose stateful slots with `FlareAdaptiveGrid(singleColumn:layoutDirection:)`.
It selects one, two or three columns from the proposed content width while retaining
one set of child identities. Set `singleColumn` for large Dynamic Type and pass the
environment layout direction. Do not put copies of asynchronous image slots in
separate `ViewThatFits` candidate grids: candidate measurement can repeatedly mount
and cancel their decoders as the images change intrinsic size.

Native entry points:

Read-only preview is independent of the upload/edit disabled state and has its own
loading/disabled state. In Vue, supply `previewLabel`, `previewLoading`,
`previewDisabled` and handle `preview`; leaving `previewLabel` unset preserves the
noninteractive uploaded slot. Previews use only transient bytes or local object URLs;
grants, access checks, expiry and retries remain with the SDK/host.

- Compose: `FlareImageUploadState`, `FlareImageUploadSlot(title, state, statusText, actionText, retryText, preview, onChoose, onRetry)`
- SwiftUI: `FlareImageUploadState`, `ImageUploadSlotView(title:state:statusText:actionText:retryText:preview:onChoose:onRetry:)`

Only static syntax checks were performed for these new native slots in this change. Product screenshots, UI builds, light/dark, keyboard and assistive-technology behavior require the next native acceptance run.
