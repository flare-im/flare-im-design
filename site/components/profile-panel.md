---
title: ProfilePanel
---

# ProfilePanel

<p><span class="flare-tag">个人中心</span></p>

> 个人中心 —— 头像 / 名称 / ID / 二维码 + 入口列表（我的收藏 / 设置 / 关于），支持退出。

**数据源**：当前用户资料 + 应用入口配置

## 预览

<div class="flare-demo flare-demo--stack">
  <ProfilePanelDemo />
</div>

## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `user` | [`UserProfile`](/reference/data-types#user-profile) | ✔ | — | 已登录用户的资料。 |


## States

<span class="flare-tag">default</span>

## Events

<span class="flare-tag">edit</span> <span class="flare-tag">openSettings</span> <span class="flare-tag">action</span> <span class="flare-tag">logout</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareProfilePanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareProfilePanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ProfilePanelView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ProfilePanel</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareProfilePanel } from "flare-core-vue-im-ui";
</script>
<template>
  <FlareProfilePanel
  :user="user"
  @edit="onEdit"
  @openSettings="onOpenSettings"
  @action="onAction"
  />
</template>
```

```dart [Flutter]
FlareProfilePanel(
  user: user,
  onEdit: onEdit,
  onOpenSettings: onOpenSettings,
  onAction: onAction,
);
```

```swift [iOS]
ProfilePanelView(user: user, onEdit: onEdit, onOpenSettings: onOpenSettings, onAction: onAction)
```

```kotlin [Android]
ProfilePanel(
  user = user,
  onEdit = onEdit,
  onOpenSettings = onOpenSettings,
  onAction = onAction,
)
```

:::


## 示例

### 个人中心

头像/名称/Flare ID + 入口列表（可自定义 entries）；点头部进编辑。

::: code-group

```vue [Vue]
<FlareProfilePanel :user="me" @edit="editProfile" @action="openEntry" />
```

```dart [Flutter]
FlareProfilePanel(user: me, onEdit: editProfile, onEntry: openEntry)
```

```swift [iOS]
ProfilePanelView(user: me, onEdit: editProfile, onEntry: openEntry)
```

```kotlin [Android]
ProfilePanel(user = me, onEdit = ::editProfile, onEntry = ::openEntry)
```

:::
