---
title: Composer
---

# Composer

<p><span class="flare-tag">Composer</span></p>

> The input — rich or plain text, emoji, format bar, attachments, reply strip. Emits built content; send is optimistic.

**Data source**: writes through client.messages.send(...); local echo < 16 ms, status via the view

## Preview

<div class="flare-demo flare-demo--stack">
  <ComposerDemo />
</div>

### Free composition (assemble from parts)

<div class="flare-demo flare-demo--stack">
  <ComposerPartsDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `conversationId` | `string` | ✔ | — | Target conversation for sends and the draft. |
| `replyTo` | `Message \| null` |  | — | Message being replied to; shows the reply strip. |
| `rich` | `boolean` |  | — | Enable rich (Markdown/RichDoc) editing vs. plain text. |
| `placeholder` | `string` |  | — | Empty-field hint text. |


## States

<span class="flare-tag">draft</span> <span class="flare-tag">sending</span> <span class="flare-tag">typing</span> <span class="flare-tag">disabled</span>

## Events

<span class="flare-tag">send</span> <span class="flare-tag">attach</span> <span class="flare-tag">typing</span>

> [!TIP]
> Composed from reusable parts you can also use standalone: [VoiceHoldButton](/en/components/voice-hold-button) · [ComposerActionPanel](/en/components/composer-action-panel) · [ComposerSendButton](/en/components/composer-send-button) · [ComposerReplyStrip](/en/components/composer-reply-strip).

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ComposerView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>Composer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareComposer } from "@flare-im/vue-ui";
</script>
<template>
  <FlareComposer
  :conversationId="conversationId"
  :replyTo="replyTo"
  :rich="rich"
  @send="onSend"
  @attach="onAttach"
  @typing="onTyping"
  />
</template>
```

```dart [Flutter]
FlareComposer(
  conversationId: conversationId,
  replyTo: replyTo,
  rich: rich,
  onSend: onSend,
  onAttach: onAttach,
  onTyping: onTyping,
);
```

```swift [iOS]
ComposerView(conversationId: conversationId, replyTo: replyTo, rich: rich, onSend: onSend, onAttach: onAttach, onTyping: onTyping)
```

```kotlin [Android]
Composer(
  conversationId = conversationId,
  replyTo = replyTo,
  rich = rich,
  onSend = onSend,
  onAttach = onAttach,
  onTyping = onTyping,
)
```

:::


## Examples

### Optimistic send + reply

onSend fires immediately (local echo next frame, < 16 ms); the host writes to core asynchronously. replyTo shows the reply strip.

::: code-group

```vue [Vue]
<FlareComposer :rich="false" :reply-to="replyTo" @send="sendOptimistic" @attach="openSheet" @cancel-reply="clearReply" />
```

```dart [Flutter]
FlareComposer(
  rich: false,
  replyTo: replyTo,
  onSend: (text) => sendOptimistic(text),
  onAttach: () => FlareMessageActionSheet.show(context),
)
```

```swift [iOS]
ComposerView(rich: false, replyTo: replyTo) { text in sendOptimistic(text) }
```

```kotlin [Android]
Composer(rich = false, replyTo = replyTo, onSend = ::sendOptimistic)
```

:::

### Voice + action panel (complete, ready to use)

enableVoice adds the hold-to-talk toggle; passing actions makes + expand an inline action grid (image/file/card/vote/…) that resolves through onAction. The host just wires the voice/action callbacks.

::: code-group

```vue [Vue]
<!-- Vue 完整 composer 见 FlareComposer；语音/功能区为独立可组合 parts -->
<FlareVoiceHoldButton @start="startRec" @end="sendVoice" @cancel="cancelRec" />
<FlareComposerActionPanel @action="build($event.key)" />
```

```dart [Flutter]
FlareComposer(
  enableVoice: true,
  actions: FlareMessageActionSheet.defaultActions,   // 下方功能区
  onSend: sendOptimistic,
  onAction: (a) => build(a.key),
  onVoiceStart: startRec, onVoiceEnd: sendVoice, onVoiceCancel: cancelRec,
)
```

```swift [iOS]
ComposerView(
  enableVoice: true,
  actions: MessageActionSheetView.defaultActions,
  onSend: sendOptimistic,
  onAction: { build($0.id) },
  onVoiceStart: startRec, onVoiceEnd: sendVoice
)
```

```kotlin [Android]
Composer(
  enableVoice = true,
  actions = defaultComposerActions,
  onSend = ::sendOptimistic,
  onAction = { build(it.key) },
  onVoiceStart = ::startRec, onVoiceEnd = ::sendVoice,
)
```

:::

### Free composition: build your own composer

Every part is exported on its own — voice button, icon button, send button, reply strip, action panel — so you can assemble a composer to fit your product instead of using the complete default.

::: code-group

```vue [Vue]
<FlareComposerActionPanel :actions="myActions" @action="pick" />
<FlareVoiceHoldButton @end="sendVoice" />
```

```dart [Flutter]
Row(children: [
  FlareComposerIconButton(icon: Icons.mic_none_rounded, onTap: toggleVoice),
  Expanded(child: myTextField),
  FlareComposerSendButton(active: canSend, onTap: send),
]);
// 需要时展开：FlareComposerActionPanel(actions: myActions, onAction: pick)
```

```swift [iOS]
HStack {
  FlareComposerActionPanel(actions: myActions) { pick($0) }
}
FlareVoiceHoldButton(onEnd: sendVoice)
```

```kotlin [Android]
Row {
  FlareVoiceHoldButton(onEnd = ::sendVoice)
}
FlareComposerActionPanel(actions = myActions, onAction = ::pick)
```

:::
