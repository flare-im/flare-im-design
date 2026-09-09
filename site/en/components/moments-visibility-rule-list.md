---
title: MomentsVisibilityRuleList
---

# MomentsVisibilityRuleList

<p><span class="flare-tag">Moments</span></p>

> Moments visibility list — members under hide-from / mute rules, with add and remove. The two directions are opposites; they must read as visually distinct or users will set the wrong one.

**Data source**: passed in by you (SDK list_visibility_rules)



## Props

| Name | Type | Req. | Default | Description |
|---|---|:---:|---|---|
| `kind` | `'hideFrom' \| 'mute'` | ✓ | — | Rule kind. Drives the title and empty-state copy; the two must not share wording. |
| `members` | `FlareContactBrief[]` | ✓ | — | Members under this rule. |
| `loading` | `boolean` |  | — | Loading. |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">ready</span>

## Events

<span class="flare-tag">add</span> <span class="flare-tag">remove</span> <span class="flare-tag">selectMember</span>

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMomentsVisibilityRuleList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMomentsVisibilityRuleList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MomentsVisibilityRuleListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MomentsVisibilityRuleList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## Usage

::: code-group

```vue [Vue]
<script setup>
import { FlareMomentsVisibilityRuleList } from "@flare-im/vue-ui";
</script>
<template>
  <FlareMomentsVisibilityRuleList
  :kind="kind"
  :members="members"
  :loading="loading"
  @add="onAdd"
  @remove="onRemove"
  @selectMember="onSelectMember"
  />
</template>
```

```dart [Flutter]
FlareMomentsVisibilityRuleList(
  kind: kind,
  members: members,
  loading: loading,
  onAdd: onAdd,
  onRemove: onRemove,
  onSelectMember: onSelectMember,
);
```

```swift [iOS]
MomentsVisibilityRuleListView(kind: kind, members: members, loading: loading, onAdd: onAdd, onRemove: onRemove, onSelectMember: onSelectMember)
```

```kotlin [Android]
MomentsVisibilityRuleList(
  kind = kind,
  members = members,
  loading = loading,
  onAdd = onAdd,
  onRemove = onRemove,
  onSelectMember = onSelectMember,
)
```

:::

