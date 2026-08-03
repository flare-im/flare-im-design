---
title: ProfileEditor
---

# ProfileEditor

<p><span class="flare-tag">Profile</span></p>

> Profile editor — edit and save avatar, nickname, signature and similar fields.

**Data source**: controlled draft; save is submitted via the client

## Preview

<div class="flare-demo flare-demo--stack">
  <ProfileEditorDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `user` | [`UserProfile`](/en/reference/data-types#user-profile) | ✔ | — | Initial profile the draft starts from. |
| `busy` | `boolean` |  | — | Disables save and shows a spinner while submitting. |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">dirty</span> <span class="flare-tag">saving</span>

## Events

<span class="flare-tag">save</span> <span class="flare-tag">cancel</span> <span class="flare-tag">pickAvatar</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareProfileEditor</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareProfileEditor</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ProfileEditorView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ProfileEditor</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareProfileEditor } from "@flare-im/vue-ui";
</script>
<template>
  <FlareProfileEditor
  :user="user"
  :busy="busy"
  @save="onSave"
  @cancel="onCancel"
  @pickAvatar="onPickAvatar"
  />
</template>
```

```dart [Flutter]
FlareProfileEditor(
  user: user,
  busy: busy,
  onSave: onSave,
  onCancel: onCancel,
  onPickAvatar: onPickAvatar,
);
```

```swift [iOS]
ProfileEditorView(user: user, busy: busy, onSave: onSave, onCancel: onCancel, onPickAvatar: onPickAvatar)
```

```kotlin [Android]
ProfileEditor(
  user = user,
  busy = busy,
  onSave = onSave,
  onCancel = onCancel,
  onPickAvatar = onPickAvatar,
)
```

:::

