---
title: MessageStatus
---

# MessageStatus

<p><span class="flare-tag">General</span></p>

> Delivery status indicator — sending spinner, sent/read ticks, failed with retry.

**Data source**: message.status from the timeline view (optimistic, reconciled by send-ack)

## Preview

<div class="flare-demo">
  <MessageStatusDemo />
</div>

## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `status` | `'pending' \| 'sent' \| 'read' \| 'failed'` | ✔ | — | Current delivery state; drives icon and color. |
| `variant` | `'tick' \| 'compact'` |  | — | `tick` shows ticks; `compact` shows a minimal dot. |


## States

<span class="flare-tag">pending</span> <span class="flare-tag">sent</span> <span class="flare-tag">read</span> <span class="flare-tag">failed</span>

## Events

<span class="flare-tag">resend</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMessageStatus</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMessageStatus</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MessageStatusView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MessageStatus</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

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

