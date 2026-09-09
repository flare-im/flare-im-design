---
title: MomentsVisibilityRuleList
---

# MomentsVisibilityRuleList

<p><span class="flare-tag">圈子</span></p>

> 朋友圈可见性名单 —— 「不让他看我的」/「不看他的」两类规则的成员列表与增删。两类方向相反，同屏时必须视觉可分，否则用户会设反。

**数据源**：由你传入（SDK list_visibility_rules）



## Props

| 名称 | 类型 | 必填 | 默认 | 说明 |
|---|---|:---:|---|---|
| `kind` | `'hideFrom' \| 'mute'` | ✓ | — | 规则类型。决定标题与空态文案 —— 两类不可共用一套措辞。 |
| `members` | `FlareContactBrief[]` | ✓ | — | 该规则下的成员。 |
| `loading` | `boolean` |  | — | 加载中。 |


## States

<span class="flare-tag">loading</span> <span class="flare-tag">empty</span> <span class="flare-tag">ready</span>

## Events

<span class="flare-tag">add</span> <span class="flare-tag">remove</span> <span class="flare-tag">selectMember</span>

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareMomentsVisibilityRuleList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareMomentsVisibilityRuleList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>MomentsVisibilityRuleListView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>MomentsVisibilityRuleList</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>


## 用法

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

