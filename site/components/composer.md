---
title: Composer
---

# Composer

<p><span class="flare-tag">输入</span></p>

> 输入框 —— 富文本 / 纯文本、表情、格式条、附件、回复条。产出内容；发送为乐观。

**数据源**：经 client.messages.send(...) 写入；本地回显 < 16ms，状态经视图

## 预览

<div class="flare-demo flare-demo--stack">
  <ComposerDemo />
</div>

### 自由组合（用 parts 自己拼）

<div class="flare-demo flare-demo--stack">
  <ComposerPartsDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `conversationId` | `string` | ✔ | — | 发送与草稿归属的目标会话。 |
| `replyTo` | `Message \| null` |  | — | 被回复的消息；显示回复条。 |
| `rich` | `boolean` |  | — | 启用富文本（Markdown/RichDoc）编辑，否则纯文本。 |
| `placeholder` | `string` |  | — | 空输入时的占位提示。 |


## States

<span class="flare-tag">draft</span> <span class="flare-tag">sending</span> <span class="flare-tag">typing</span> <span class="flare-tag">disabled</span>

## Events

<span class="flare-tag">send</span> <span class="flare-tag">attach</span> <span class="flare-tag">typing</span>

> [!TIP]
> 由可复用的部件组成，这些部件也能单独使用：[VoiceHoldButton](/components/voice-hold-button) · [ComposerActionPanel](/components/composer-action-panel) · [ComposerSendButton](/components/composer-send-button) · [ComposerReplyStrip](/components/composer-reply-strip)。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareComposer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareComposer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ComposerView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>Composer</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareComposer } from "flare-core-vue-im-ui";
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


## 示例

### 乐观发送 + 回复

onSend 立即触发（下一帧本地回显，< 16ms），宿主再异步写入 core；replyTo 显示回复条。

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

### 语音 + 下方功能区（完整可直接用）

开启 enableVoice 显示「按住说话」切换；传 actions 时「＋」展开内联功能区网格（图片/文件/名片/投票…），选择回 onAction。宿主拿到语音/动作回调即可。

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

### 自由组合：用 parts 自己拼输入栏

所有小组件都单独导出——语音按钮、图标按钮、发送按钮、回复条、下方功能区——产品可自由组合出自己的输入栏，而不用完整默认装配。

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
