---
title: MomentAudienceSheet
---

# MomentAudienceSheet

<p><span class="flare-tag">Moments</span></p>

> Audience picker for a new moment — public/friends/private, plus the mutually exclusive include and exclude lists. The two directions are not symmetric in consequence, so copy and accent differ.

**Data source**: passed in by you (friend list + current selection)



## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `visibility` | `number` | ✓ | — | 0=friends 1=public 2=private. |
| `audienceMode` | `number` | ✓ | — | 0=none 1=include 2=exclude; orthogonal to visibility. |
| `audienceUserIds` | `string[]` | ✓ | — | Current list. |
| `contacts` | `FlareContactBrief[]` | ✓ | — | Selectable friends. |
| `open` | `boolean` |  | — | Whether the picker is open. |


## States

<span class="flare-tag">collapsed</span> <span class="flare-tag">picking</span>

## Events

<span class="flare-tag">update:visibility</span> <span class="flare-tag">update:audience</span> <span class="flare-tag">close</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMomentAudienceSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMomentAudienceSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MomentAudienceSheetView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MomentAudienceSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMomentAudienceSheet } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMomentAudienceSheet
  :visibility="visibility"
  :audienceMode="audienceMode"
  :audienceUserIds="audienceUserIds"
  :contacts="contacts"
  @update:visibility="onUpdate:visibility"
  @update:audience="onUpdate:audience"
  @close="onClose"
  />
</template>
```

```dart [Flutter]
FlareMomentAudienceSheet(
  visibility: visibility,
  audienceMode: audienceMode,
  audienceUserIds: audienceUserIds,
  contacts: contacts,
  onUpdate:visibility: onUpdate:visibility,
  onUpdate:audience: onUpdate:audience,
  onClose: onClose,
);
```

```swift [iOS]
MomentAudienceSheetView(visibility: visibility, audienceMode: audienceMode, audienceUserIds: audienceUserIds, contacts: contacts, onUpdate:visibility: onUpdate:visibility, onUpdate:audience: onUpdate:audience, onClose: onClose)
```

```kotlin [Android]
MomentAudienceSheet(
  visibility = visibility,
  audienceMode = audienceMode,
  audienceUserIds = audienceUserIds,
  contacts = contacts,
  onUpdate:visibility = onUpdate:visibility,
  onUpdate:audience = onUpdate:audience,
  onClose = onClose,
)
```

:::

