---
title: MessageActionSheet
---

# MessageActionSheet

<p><span class="flare-tag">Message</span></p>

> Message actions — reaction, quick actions (reply/forward/recall), and grouped actions (multi-select/mark/pin/copy/edit/delete). Delete in red.

The interaction is **platform-split** (same actions, two presentations):

- **Desktop**: hovering a bubble reveals <strong>react · reply · more</strong>; the rest open from "more" as a dropdown. Right-click works too.
- **Mobile**: long-press a bubble opens a bottom **sheet** (reaction strip + quick grid + full action list).

Which one shows is decided automatically by viewport / pointer capability (see `MessageBubble`); you only supply `menuConfig` to enable actions. Both platforms share one reaction set (`MESSAGE_QUICK_REACTIONS`).

**Data source**: driven by the message's menuConfig (which actions are enabled); actions dispatch through the timeline view / client.

## Preview

Hover any bubble below for the desktop three-button bar; on mobile it's a long-press sheet.

<div class="flare-demo flare-demo--stack">
  <MessageActionSheetDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `open` | `boolean` | ✔ | — | Whether the sheet is shown. |
| `reactions` | `string[]` |  | — | Emoji shown in the reaction strip (the trailing chip opens the full picker). |
| `menuConfig` | `MessageMenuConfig` |  | — | Which actions are enabled for this message; disabled ones are hidden. |
| `canRecall` | `boolean` |  | — | Show the recall action (own, recent messages only). |


## States

<span class="flare-tag">reactionStrip</span> <span class="flare-tag">quickActions</span> <span class="flare-tag">emojiExpanded</span>

## Events

<span class="flare-tag">react</span> <span class="flare-tag">reply</span> <span class="flare-tag">forward</span> <span class="flare-tag">recall</span> <span class="flare-tag">multiSelect</span> <span class="flare-tag">mark</span> <span class="flare-tag">pin</span> <span class="flare-tag">copy</span> <span class="flare-tag">edit</span> <span class="flare-tag">delete</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageActionSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageActionSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageActionSheetView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageActionSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageActionSheet } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMessageActionSheet
  :open="open"
  :reactions="reactions"
  :menuConfig="menuConfig"
  @react="onReact"
  @reply="onReply"
  @forward="onForward"
  />
</template>
```

```dart [Flutter]
FlareMessageActionSheet(
  open: open,
  reactions: reactions,
  menuConfig: menuConfig,
  onReact: onReact,
  onReply: onReply,
  onForward: onForward,
);
```

```swift [iOS]
MessageActionSheetView(open: open, reactions: reactions, menuConfig: menuConfig, onReact: onReact, onReply: onReply, onForward: onForward)
```

```kotlin [Android]
MessageActionSheet(
  open = open,
  reactions = reactions,
  menuConfig = menuConfig,
  onReact = onReact,
  onReply = onReply,
  onForward = onForward,
)
```

:::

