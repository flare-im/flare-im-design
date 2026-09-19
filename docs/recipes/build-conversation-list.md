# Recipe: Build the Conversation List

The inbox is the app's home: every conversation, newest first, with unread counts, and one tap into a chat. This recipe is the golden reference app's list (`flare-social-web-app/src/components/ConversationPane.vue`), trimmed.

## Components

| Region | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Container with loading, error and retry | `FlareConversationListContainer` | `FlareConversationListContainer` | `ConversationListContainerView` | `ConversationListContainer` |
| Rows, selection and row actions | `FlareConversationList` | `FlareConversationList` | `ConversationListView` | `ConversationList` |
| Refresh-failure banner | `FlareStatusBanner` in `#status` | `FlareStatusBanner` in `filters` | `StatusBannerView` | `StatusBanner` |
| First-run empty state | `FlareEmptyState` in `#empty` | `emptyPlaceholder` | `EmptyStateView` | `EmptyState` |

## Composition (Vue)

```vue
<script setup lang="ts">
import { computed } from "vue";
import {
  FlareConversationList,
  FlareConversationListContainer,
  FlareEmptyState,
  FlareStatusBanner,
  useFlareConfirm,
  useFlareToast,
  type ConversationActionCapabilities,
  type FlareConversationAction,
  type FlareViewState,
} from "@flare-im/vue-ui";
import { activeId, conversations, conversationsError, loadConversations, loadingConversations, runConversationAction } from "../social/store";

// Only the actions this app performs; archive is left out because there is no archived view.
const capabilities: ConversationActionCapabilities = { markRead: true, markUnread: true, pin: true, mute: true, clearHistory: true, delete: true };

const emit = defineEmits<{ (e: "select", id: string): void }>();
const confirm = useFlareConfirm();
const toast = useFlareToast();

// Rows stay on screen when a refresh fails; only a first load with nothing to show is an error.
const listState = computed<FlareViewState<readonly unknown[]>>(() => {
  if (loadingConversations.value && !conversations.value.length) return { status: "loading" };
  if (conversationsError.value && !conversations.value.length) return { status: "error", error: "会话列表加载失败" };
  return { status: "ready" };
});

function onAction(action: FlareConversationAction, id: string) {
  if (action === "delete") {
    const target = conversations.value.find((row) => row.id === id)?.displayName ?? "";
    void confirm({ title: "删除会话", description: "会话和本机上的消息会一起删除。", target, confirmText: "删除", action: () => runConversationAction(id, action) });
    return;
  }
  runConversationAction(id, action).catch(() => toast({ message: "操作未完成，请重试", tone: "danger" }));
}
</script>

<template>
  <FlareConversationListContainer :state="listState" label="会话" retry-label="重试" @retry="loadConversations">
    <template v-if="conversationsError && conversations.length" #status>
      <FlareStatusBanner tone="warning" text="会话列表暂时无法刷新" action-text="重试" @action="loadConversations" />
    </template>
    <FlareConversationList :items="conversations" :active-id="activeId ?? undefined" :capabilities="capabilities" @select="emit('select', $event)" @action="onAction">
      <template #empty>
        <FlareEmptyState icon="chats" title="暂无会话" description="从通讯录选择好友开始聊天。" />
      </template>
    </FlareConversationList>
  </FlareConversationListContainer>
</template>
```

## The row model is the app's job

Map each core conversation once, in the store:

- `displayName`, `avatarUrl`, `lastMessagePreview` and a short time label: a clock for today, "昨天", then the date.
- `unreadCount`, plus `pinned`, `muted` and `draft` from `isPinned`, `isMuted` and `draft`.

Row actions are not part of the row model. The list takes `capabilities`, the actions the app performs, and each row offers exactly those (right-click, Shift+F10 or long-press; a sheet on phones). Without `capabilities` a row has no menu. The same ids (`markRead`, `clearHistory`, ...) come back in `action` and are what `FlareConversationActionSheet` uses.

The core already orders conversations, pinned first. Pass them in its order: the kit list renders host order and no longer moves pinned rows itself (four kits).

## States

| State | What the user sees |
|---|---|
| First load | Container loading state |
| First load failed | Error state with retry |
| Refresh failed with rows | Rows plus a warning banner with retry |
| No conversations | Empty state that says how to start one |
| Destructive row action | Confirmation with busy, error and retry (pattern 3 in `docs/design/pattern-catalog.md`) |

## Do and don't

- Do reuse the kit row. Do not replace it through `#item` to restyle it or to add a checkbox: batch selection is `selectable` plus `selectedIds` and `@toggle-select`. If the row lacks something, log friction.
- Do confirm delete and clear history. Pin, mute and mark read are reversible and run immediately.
- Don't turn a failed read into an empty list.
- Don't count muted conversations in the navigation badge.
- Do put 发起聊天 in the empty inbox's empty state; the content pane beside it then shows text only, so the screen has one call to action.
