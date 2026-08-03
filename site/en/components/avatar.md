---
title: Avatar
---

# Avatar

<p><span class="flare-tag">General</span></p>

> User or group avatar — image, initials fallback, optional presence dot.

**Data source**: identity fields (displayName, avatarUrl) you pass in; presence optionally from Flare core

## Preview

<div class="flare-demo">
  <AvatarDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `userId` | `string` | ✔ | — | Stable id, used to derive the fallback color when no image loads. |
| `displayName` | `string` | ✔ | — | Name to render; its initials become the fallback. |
| `avatarUrl` | `string` |  | — | Image URL; on load failure it falls back to initials. |
| `size` | `number` |  | `42` | Diameter in px. |
| `presence` | `'online' \| 'offline' \| 'busy' \| 'away'` |  | — | Presence ring/dot; omit to hide. |


## States

<span class="flare-tag">image</span> <span class="flare-tag">fallback</span> <span class="flare-tag">presence</span>

## Events

<span class="flare-tag">click</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareAvatar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareAvatar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>AvatarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>Avatar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareAvatar } from "@flare-im/vue-ui";
</script>
<template>
  <FlareAvatar
  :userId="userId"
  :displayName="displayName"
  :avatarUrl="avatarUrl"
  @click="onClick"
  />
</template>
```

```dart [Flutter]
FlareAvatar(
  userId: userId,
  displayName: displayName,
  avatarUrl: avatarUrl,
  onClick: onClick,
);
```

```swift [iOS]
AvatarView(userId: userId, displayName: displayName, avatarUrl: avatarUrl, onClick: onClick)
```

```kotlin [Android]
Avatar(
  userId = userId,
  displayName = displayName,
  avatarUrl = avatarUrl,
  onClick = onClick,
)
```

:::


## Examples

### Size & presence

The avatar derives its fallback color from userId and its initials from displayName; presence shows a bottom-right dot.

::: code-group

```vue [Vue]
<FlareAvatar user-id="u1" display-name="Henry Ford" :size="48" presence="online" />
```

```dart [Flutter]
FlareAvatar(userId: 'u1', displayName: 'Henry Ford', size: 48, presence: FlarePresence.online)
```

```swift [iOS]
AvatarView(userId: "u1", displayName: "Henry Ford", size: 48, presence: .online)
```

```kotlin [Android]
Avatar(userId = "u1", displayName = "Henry Ford", size = 48.dp, presence = FlarePresence.Online)
```

:::
