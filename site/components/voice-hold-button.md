---
title: VoiceHoldButton
---

# VoiceHoldButton

<p><span class="flare-tag">输入</span></p>

> 按住说话的语音按钮 —— 按住录音、上滑取消。可自由组合的 Composer 部件。

**数据源**：纯展示 —— 抛出 start / end / cancel；录音与发送由宿主处理

## 预览

<div class="flare-demo">
  <VoiceHoldButtonDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `label` | `string` |  | — | 空闲态文案（如「按住 说话」）。 |
| `recordingLabel` | `string` |  | — | 录音态文案。 |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">recording</span> <span class="flare-tag">cancelHint</span>

## Events

<span class="flare-tag">start</span> <span class="flare-tag">end</span> <span class="flare-tag">cancel</span>

> [!TIP]
> 属于 [Composer](/components/composer) 的部件 —— 可单独使用，自拼输入栏。

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>FlareVoiceHoldButton</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareVoiceHoldButton } from "@flare-im/vue-ui";
</script>
<template>
  <FlareVoiceHoldButton
  :label="label"
  :recordingLabel="recordingLabel"
  @start="onStart"
  @end="onEnd"
  @cancel="onCancel"
  />
</template>
```

```dart [Flutter]
FlareVoiceHoldButton(
  label: label,
  recordingLabel: recordingLabel,
  onStart: onStart,
  onEnd: onEnd,
  onCancel: onCancel,
);
```

```swift [iOS]
FlareVoiceHoldButton(label: label, recordingLabel: recordingLabel, onStart: onStart, onEnd: onEnd, onCancel: onCancel)
```

```kotlin [Android]
FlareVoiceHoldButton(
  label = label,
  recordingLabel = recordingLabel,
  onStart = onStart,
  onEnd = onEnd,
  onCancel = onCancel,
)
```

:::

