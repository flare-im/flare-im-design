---
title: MomentCard
---

# MomentCard

<p><span class="flare-tag">Moments</span></p>

> Moment card — author/text/photo grid/location/time + a ··· like-comment popover + likers row + comments. The feed's hero.

**Data source**: passed in by you



## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `moment` | `FlareMoment` | ✓ | — | The moment data. |


## States

_None_

## Events

<span class="flare-tag">like</span> <span class="flare-tag">comment</span> <span class="flare-tag">openImage</span> <span class="flare-tag">selectAuthor</span> <span class="flare-tag">selectLiker</span> <span class="flare-tag">selectComment</span> <span class="flare-tag">delete</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMomentCard</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMomentCard</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MomentCardView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MomentCard</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMomentCard } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMomentCard
  :moment="moment"
  @like="onLike"
  @comment="onComment"
  @openImage="onOpenImage"
  />
</template>
```

```dart [Flutter]
FlareMomentCard(
  moment: moment,
  onLike: onLike,
  onComment: onComment,
  onOpenImage: onOpenImage,
);
```

```swift [iOS]
MomentCardView(moment: moment, onLike: onLike, onComment: onComment, onOpenImage: onOpenImage)
```

```kotlin [Android]
MomentCard(
  moment = moment,
  onLike = onLike,
  onComment = onComment,
  onOpenImage = onOpenImage,
)
```

:::

