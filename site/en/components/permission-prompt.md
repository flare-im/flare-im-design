---
title: PermissionPrompt
---

# PermissionPrompt

Unified explanation panel for a missing or denied system permission. It names the permission and the feature it unlocks, and hands `request` / `openSettings` to the host. Reused by voice recording (Composer), calls (microphone / camera), notifications, storage / photos, contacts and location. The view never requests a permission or inspects the platform: the host supplies `kind` + `state`.

<div class="flare-demo flare-demo--stack"><PermissionPromptDemo /></div>

<ComponentApi name="PermissionPrompt" />

| state | Meaning | Visible actions |
|---|---|---|
| undetermined | Not asked yet | `request` (if the host supplied it) + optional `dismiss` |
| denied | User refused; only the system settings can re-enable | `openSettings` (if supplied) + optional `dismiss` |
| restricted | Parental control / enterprise policy | explanation + optional `dismiss` |
| unavailable | No such hardware or unsupported runtime | explanation + optional `dismiss` |
| busy | Host is requesting / navigating | every action disabled |

Each kind has its own icon; each state has an icon + text label, so status never relies on colour alone. Shared logic on all four platforms: `permissionActions(state, {hasRequest, hasOpenSettings, hasDismiss, busy})` → `{request, openSettings, dismiss, enabled}` and `defaultPermissionCopy(kind, state, featureLabel?)` → `{title, description, primaryLabel}`. All copy props default from that function and may be overridden.

Hosts set `busy` synchronously before calling the platform API and update `state` from the result. `compact` renders a single-row variant for the strip above a composer; the default is a card for settings and pre-call checks. Web emits `request` / `open-settings` / `dismiss`; unbound events hide their button. Native callbacks `onRequest` / `onOpenSettings` / `onDismiss` hide their button when nil.

Entries: FlarePermissionPrompt (Vue/Flutter), PermissionPromptView (SwiftUI), PermissionPrompt (Compose). See the [full integration guide](/components/permission-prompt).
