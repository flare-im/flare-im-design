---
title: ProfilePanel
---

# ProfilePanel

<p><span class="flare-tag">Profile</span></p>

> Personal center — avatar/name/id/QR + entry list (favorites/settings/about), with logout.

**Data source**: current user profile + app entry configuration

## Preview

<div class="flare-demo flare-demo--stack">
  <ProfilePanelDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `user` | [`UserProfile`](/en/reference/data-types#user-profile) | ✓ | — | The signed-in user's profile. |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">edit</span> <span class="flare-tag">openSettings</span> <span class="flare-tag">action</span> <span class="flare-tag">logout</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareProfilePanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareProfilePanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ProfilePanelView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ProfilePanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareProfilePanel } from "@flare-im/vue-ui";
</script>
<template>
  <FlareProfilePanel
  :user="user"
  @edit="onEdit"
  @openSettings="onOpenSettings"
  @action="onAction"
  />
</template>
```

```dart [Flutter]
FlareProfilePanel(
  user: user,
  onEdit: onEdit,
  onOpenSettings: onOpenSettings,
  onAction: onAction,
);
```

```swift [iOS]
ProfilePanelView(user: user, onEdit: onEdit, onOpenSettings: onOpenSettings, onAction: onAction)
```

```kotlin [Android]
ProfilePanel(
  user = user,
  onEdit = onEdit,
  onOpenSettings = onOpenSettings,
  onAction = onAction,
)
```

:::


## Examples

### Personal center

Avatar / name / Flare ID + entry list (entries are customizable); tap the header to edit.

::: code-group

```vue [Vue]
<FlareProfilePanel :user="me" @edit="editProfile" @action="openEntry" />
```

```dart [Flutter]
FlareProfilePanel(user: me, onEdit: editProfile, onEntry: openEntry)
```

```swift [iOS]
ProfilePanelView(user: me, onEdit: editProfile, onEntry: openEntry)
```

```kotlin [Android]
ProfilePanel(user = me, onEdit = ::editProfile, onEntry = ::openEntry)
```

:::
