---
title: MessageActionSheet
---

# MessageActionSheet

<p><span class="flare-tag">Message</span></p>

> The message long-press action sheet — a reaction strip, quick actions (reply/forward/recall), and grouped actions (multi-select/mark/pin/copy/edit/delete). Delete in red.

**Data source**: driven by the message's menuConfig (which actions are enabled); actions dispatch through the timeline view / client

## Preview

<div class="flare-demo flare-demo--stack">
  <MessageActionSheetDemo />
</div>


## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `open` | `boolean` | ✓ | — | Whether the sheet is shown. |
| `reactions` | `string[]` |  | — | Emoji shown in the reaction strip (the trailing chip opens the full picker). |
| `menuConfig` | `MessageMenuConfig` |  | — | Which actions are enabled for this message; disabled ones are hidden. |
| `canRecall` | `boolean` |  | — | Show the recall action (own, recent messages only). |


## States

<span class="flare-tag">reactionStrip</span> <span class="flare-tag">quickActions</span> <span class="flare-tag">emojiExpanded</span>

## Events

<span class="flare-tag">build</span>

> [!TIP]
> All four platforms deliberately converge on a single action dispatch rather than per-op events: Vue emits build(op); Flutter/iOS/Compose take onAction(FlareComposerAction).

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
  @build="onBuild"
  />
</template>
```

```dart [Flutter]
FlareMessageActionSheet(
  open: open,
  reactions: reactions,
  menuConfig: menuConfig,
  onBuild: onBuild,
);
```

```swift [iOS]
MessageActionSheetView(open: open, reactions: reactions, menuConfig: menuConfig, onBuild: onBuild)
```

```kotlin [Android]
MessageActionSheet(
  open = open,
  reactions = reactions,
  menuConfig = menuConfig,
  onBuild = onBuild,
)
```

:::

