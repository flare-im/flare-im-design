---
title: MomentAudienceSheet
---

# MomentAudienceSheet

<p><span class="flare-tag">圈子</span></p>

> 发动态时选「谁可以看」—— 公开/好友/私密三档，加上「部分可见」与「不给谁看」两份互斥名单。设错方向的后果不对称，所以两者文案与配色分开。

**数据源**：由你传入（好友列表 + 当前选择）



## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `visibility` | `number` | ✓ | — | 0=好友 1=公开 2=私密。 |
| `audienceMode` | `number` | ✓ | — | 0=无名单 1=部分可见 2=不给谁看。与 visibility 正交。 |
| `audienceUserIds` | `string[]` | ✓ | — | 当前名单。 |
| `contacts` | `FlareContactBrief[]` | ✓ | — | 可选好友。 |
| `open` | `boolean` |  | — | 是否展开选人。 |


## States

<span class="flare-tag">collapsed</span> <span class="flare-tag">picking</span>

## Events

<span class="flare-tag">update:visibility</span> <span class="flare-tag">update:audience</span> <span class="flare-tag">close</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMomentAudienceSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMomentAudienceSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MomentAudienceSheetView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MomentAudienceSheet</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareMomentAudienceSheet } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMomentAudienceSheet
  :visibility="visibility"
  :audienceMode="audienceMode"
  :audienceUserIds="audienceUserIds"
  :contacts="contacts"
  @update:visibility="onUpdate:visibility"
  @update:audience="onUpdate:audience"
  @close="onClose"
  />
</template>
```

```dart [Flutter]
FlareMomentAudienceSheet(
  visibility: visibility,
  audienceMode: audienceMode,
  audienceUserIds: audienceUserIds,
  contacts: contacts,
  onUpdate:visibility: onUpdate:visibility,
  onUpdate:audience: onUpdate:audience,
  onClose: onClose,
);
```

```swift [iOS]
MomentAudienceSheetView(visibility: visibility, audienceMode: audienceMode, audienceUserIds: audienceUserIds, contacts: contacts, onUpdate:visibility: onUpdate:visibility, onUpdate:audience: onUpdate:audience, onClose: onClose)
```

```kotlin [Android]
MomentAudienceSheet(
  visibility = visibility,
  audienceMode = audienceMode,
  audienceUserIds = audienceUserIds,
  contacts = contacts,
  onUpdate:visibility = onUpdate:visibility,
  onUpdate:audience = onUpdate:audience,
  onClose = onClose,
)
```

:::

