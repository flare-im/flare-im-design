---
title: Avatar
---

# Avatar

<p><span class="flare-tag">通用</span></p>

> 用户 / 群组头像 —— 图片、首字母兜底、可选在线状态点。

**数据源**：身份字段（displayName、avatarUrl）由你传入；在线状态可选来自 Flare core presence

## 预览

<div class="flare-demo">
  <AvatarDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `userId` | `string` | ✔ | — | 稳定 id，无图片时据此派生兜底底色。 |
| `displayName` | `string` | ✔ | — | 展示名；其首字母作为兜底。 |
| `avatarUrl` | `string` |  | — | 头像图 URL；加载失败回退到首字母。 |
| `size` | `number` |  | `42` | 直径（px）。 |
| `presence` | `'online' \| 'offline' \| 'busy' \| 'away'` |  | — | 在线状态圈点；不传则隐藏。 |


## States

<span class="flare-tag">image</span> <span class="flare-tag">fallback</span> <span class="flare-tag">presence</span>

## Events

<span class="flare-tag">click</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareAvatar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareAvatar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>AvatarView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>Avatar</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareAvatar } from "@flare-im/vue-ui";
</script>
<template>
  <FlareAvatar
  :userId="userId"
  :displayName="displayName"
  :avatarUrl="avatarUrl"
  @click="onClick"
  />
</template>
```

```dart [Flutter]
FlareAvatar(
  userId: userId,
  displayName: displayName,
  avatarUrl: avatarUrl,
  onClick: onClick,
);
```

```swift [iOS]
AvatarView(userId: userId, displayName: displayName, avatarUrl: avatarUrl, onClick: onClick)
```

```kotlin [Android]
Avatar(
  userId = userId,
  displayName = displayName,
  avatarUrl = avatarUrl,
  onClick = onClick,
)
```

:::


## 示例

### 尺寸与在线状态

头像自动从 userId 生成兜底底色，displayName 生成首字母；presence 显示右下角圆点。

::: code-group

```vue [Vue]
<FlareAvatar user-id="u1" display-name="Henry Ford" :size="48" presence="online" />
```

```dart [Flutter]
FlareAvatar(userId: 'u1', displayName: 'Henry Ford', size: 48, presence: FlarePresence.online)
```

```swift [iOS]
AvatarView(userId: "u1", displayName: "Henry Ford", size: 48, presence: .online)
```

```kotlin [Android]
Avatar(userId = "u1", displayName = "Henry Ford", size = 48.dp, presence = FlarePresence.Online)
```

:::
