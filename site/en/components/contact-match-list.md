---
title: ContactMatchList
---

# ContactMatchList

<p><span class="flare-tag">Contacts</span></p>

> Contact match results — matched users, showing Add or Message per alreadyFriend. The key screen for new-user onboarding.

**Data source**: passed in by you (SDK match_contacts)



## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `matches` | `FlareMatchedContact[]` | ✓ | — | Match results. matchedBy echoes which number matched so the user can tell who it is. |
| `loading` | `boolean` |  | — | Matching. |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">ready</span>

## Events

<span class="flare-tag">addFriend</span> <span class="flare-tag">openConversation</span> <span class="flare-tag">selectContact</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareContactMatchList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareContactMatchList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>ContactMatchListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>ContactMatchList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

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

