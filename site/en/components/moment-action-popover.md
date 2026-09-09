---
title: MomentActionPopover
---

# MomentActionPopover

<p><span class="flare-tag">Moments</span></p>

> Like/comment popover — a dark capsule that slides from the ··· button.

**Data source**: passed in by you



## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `liked` | `boolean` |  | — | Whether liked (toggles the label). |


## States

_None_

## Events

<span class="flare-tag">like</span> <span class="flare-tag">comment</span> <span class="flare-tag">delete</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMomentActionPopover</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMomentActionPopover</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MomentActionPopoverView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MomentActionPopover</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMomentActionPopover } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMomentActionPopover
  :liked="liked"
  @like="onLike"
  @comment="onComment"
  @delete="onDelete"
  />
</template>
```

```dart [Flutter]
FlareMomentActionPopover(
  liked: liked,
  onLike: onLike,
  onComment: onComment,
  onDelete: onDelete,
);
```

```swift [iOS]
MomentActionPopoverView(liked: liked, onLike: onLike, onComment: onComment, onDelete: onDelete)
```

```kotlin [Android]
MomentActionPopover(
  liked = liked,
  onLike = onLike,
  onComment = onComment,
  onDelete = onDelete,
)
```

:::

