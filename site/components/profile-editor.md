---
title: ProfileEditor
---

# ProfileEditor

<p><span class="flare-tag">个人中心</span></p>

> 资料编辑 —— 头像、昵称、签名等字段编辑与保存。

**数据源**：受控草稿；保存经 client 提交

## 预览

<div class="flare-demo flare-demo--stack">
  <ProfileEditorDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `user` | [`UserProfile`](/reference/data-types#user-profile) | ✔ | — | 草稿初始的资料。 |
| `busy` | `boolean` |  | — | 提交中禁用保存并转圈。 |


## States

<span class="flare-tag">idle</span> <span class="flare-tag">dirty</span> <span class="flare-tag">saving</span>

## Events

<span class="flare-tag">save</span> <span class="flare-tag">cancel</span> <span class="flare-tag">pickAvatar</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareProfileEditor</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareProfileEditor</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ProfileEditorView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ProfileEditor</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareProfileEditor } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareProfileEditor
  :user="user"
  :busy="busy"
  @save="onSave"
  @cancel="onCancel"
  @pickAvatar="onPickAvatar"
  />
</template>
```

```dart [Flutter]
FlareProfileEditor(
  user: user,
  busy: busy,
  onSave: onSave,
  onCancel: onCancel,
  onPickAvatar: onPickAvatar,
);
```

```swift [iOS]
ProfileEditorView(user: user, busy: busy, onSave: onSave, onCancel: onCancel, onPickAvatar: onPickAvatar)
```

```kotlin [Android]
ProfileEditor(
  user = user,
  busy = busy,
  onSave = onSave,
  onCancel = onCancel,
  onPickAvatar = onPickAvatar,
)
```

:::

