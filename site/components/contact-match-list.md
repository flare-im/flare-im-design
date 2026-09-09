---
title: ContactMatchList
---

# ContactMatchList

<p><span class="flare-tag">通讯录</span></p>

> 通讯录匹配结果 —— 命中用户列表，按 alreadyFriend 分别显示「添加」或「发消息」。新用户上手的关键一屏。

**数据源**：由你传入（SDK match_contacts）



## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `matches` | `FlareMatchedContact[]` | ✓ | — | 匹配结果。matchedBy 用于在条目上回显命中的号码，便于用户确认是谁。 |
| `loading` | `boolean` |  | — | 匹配中。 |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">ready</span>

## Events

<span class="flare-tag">addFriend</span> <span class="flare-tag">openConversation</span> <span class="flare-tag">selectContact</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactMatchList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactMatchList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactMatchListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactMatchList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

::: code-group

```vue [Vue]
<script setup>
import { FlareContactMatchList } from "@flare-im/vue-ui";
</script>
<template>
  <FlareContactMatchList
  :matches="matches"
  :loading="loading"
  @addFriend="onAddFriend"
  @openConversation="onOpenConversation"
  @selectContact="onSelectContact"
  />
</template>
```

```dart [Flutter]
FlareContactMatchList(
  matches: matches,
  loading: loading,
  onAddFriend: onAddFriend,
  onOpenConversation: onOpenConversation,
  onSelectContact: onSelectContact,
);
```

```swift [iOS]
ContactMatchListView(matches: matches, loading: loading, onAddFriend: onAddFriend, onOpenConversation: onOpenConversation, onSelectContact: onSelectContact)
```

```kotlin [Android]
ContactMatchList(
  matches = matches,
  loading = loading,
  onAddFriend = onAddFriend,
  onOpenConversation = onOpenConversation,
  onSelectContact = onSelectContact,
)
```

:::

