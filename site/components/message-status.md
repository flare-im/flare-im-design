---
title: MessageStatus
---

# MessageStatus

<p><span class="flare-tag">通用</span></p>

> 送达状态指示 —— 发送中转圈、已发送 / 已读勾、失败可重试。

**数据源**：取时间线视图的 message.status（乐观显示，由 send-ack 校正）

## 预览

<div class="flare-demo">
  <MessageStatusDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `status` | `'pending' \| 'sent' \| 'read' \| 'failed'` | ✓ | — | 当前送达态；决定图标与颜色。 |
| `variant` | `'tick' \| 'compact'` |  | — | `tick` 显示勾；`compact` 显示极简圆点。 |


## States

<span class="flare-tag">pending</span> <span class="flare-tag">sent</span> <span class="flare-tag">read</span> <span class="flare-tag">failed</span>

## Events

<span class="flare-tag">resend</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageStatus</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageStatus</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageStatusView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageStatus</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareMessageStatus } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMessageStatus
  :status="status"
  :variant="variant"
  @resend="onResend"
  />
</template>
```

```dart [Flutter]
FlareMessageStatus(
  status: status,
  variant: variant,
  onResend: onResend,
);
```

```swift [iOS]
MessageStatusView(status: status, variant: variant, onResend: onResend)
```

```kotlin [Android]
MessageStatus(
  status = status,
  variant = variant,
  onResend = onResend,
)
```

:::

