---
title: ContactDetail
---

# ContactDetail

<p><span class="flare-tag">通讯录</span></p>

> 联系人名片 —— 头像 / 名称 / 签名 + 资料字段 + 发消息 / 语音 / 视频 / 更多操作。

**数据源**：一个 Contact 详情；操作经 client 打开会话 / 发起通话

## 预览

<div class="flare-demo flare-demo--stack">
  <ContactDetailDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `contact` | [`Contact`](/reference/data-types#contact) | ✓ | — | 要展示的联系人。 |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">message</span> <span class="flare-tag">call</span> <span class="flare-tag">video</span> <span class="flare-tag">edit</span> <span class="flare-tag">editDescription</span> <span class="flare-tag">toggleStar</span> <span class="flare-tag">block</span> <span class="flare-tag">remove</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>FlareContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactDetail</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareContactDetail } from "@flare-im/vue-ui";
</script>
<template>
  <FlareContactDetail
  :contact="contact"
  @message="onMessage"
  @call="onCall"
  @video="onVideo"
  />
</template>
```

```dart [Flutter]
FlareContactDetail(
  contact: contact,
  onMessage: onMessage,
  onCall: onCall,
  onVideo: onVideo,
);
```

```swift [iOS]
ContactDetailView(contact: contact, onMessage: onMessage, onCall: onCall, onVideo: onVideo)
```

```kotlin [Android]
ContactDetail(
  contact = contact,
  onMessage = onMessage,
  onCall = onCall,
  onVideo = onVideo,
)
```

:::

