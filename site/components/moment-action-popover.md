---
title: MomentActionPopover
---

# MomentActionPopover

<p><span class="flare-tag">圈子</span></p>

> 赞/评论弹条 —— 从「···」滑出的深色胶囊(仿微信黑气泡)。

**数据源**：由你传入



## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `liked` | `boolean` |  | — | 是否已赞(切换文案)。 |


## States

_无_

## Events

<span class="flare-tag">like</span> <span class="flare-tag">comment</span> <span class="flare-tag">delete</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMomentActionPopover</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMomentActionPopover</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MomentActionPopoverView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MomentActionPopover</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

