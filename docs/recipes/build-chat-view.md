# Recipe: Build the Chat View

One conversation: a header that says who you are talking to, the timeline, and the composer at the bottom. This recipe follows the golden reference app (`flare-social-web-app/src/components/ChatArea.vue`); the composer has its own recipe (`build-chat-composer.md`).

## Components

| Region | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Header: identity, back, actions | `FlareConversationHeader` | `FlareConversationHeader` | `ConversationHeaderView` | `ConversationHeader` |
| Timeline | `FlareMessageList` | `FlareMessageList` | `MessageListView` | `MessageList` |
| Unread divider, typing row, empty timeline | `unreadFromId` plus `#unread-divider`, `#footer`, `#empty` on the list | host rows around the list | host rows around the list | host rows around the list |
| Status line (locating a message, send errors) | `FlareStatusBanner` | `FlareStatusBanner` | `StatusBannerView` | `StatusBanner` |
| Composer | `FlareComposer` | `FlareComposer` | `ComposerView` | `Composer` |
| No conversation selected | `FlareEmptyState` | `FlareEmptyState` | `EmptyStateView` | `EmptyState` |

## Composition (Vue)

```vue
<script setup lang="ts">
import { computed } from "vue";
import {
  FlareConversationHeader,
  FlareEmptyState,
  FlareMessageList,
  useFlareConfirm,
  useFlareToast,
  type FlareConversationHeaderAction,
  type FlareConversationHeaderCapabilities,
  type FlareConversationHeaderConfiguration,
  type MessageMenuExtension,
} from "@flare-im/vue-ui";

// Offer only what this screen wires. Tapping the avatar or title opens the details (identity `action`);
// search is a toggle, so the header shows it pressed while the search panel is open.
const headerCapabilities: FlareConversationHeaderCapabilities = { availableActionIds: ["search", "details"] };
const headerConfiguration = computed<FlareConversationHeaderConfiguration>(() => ({
  actionOverrides: [{ id: "search", pressed: showSearch.value }],
  compactMaxPrimaryActions: 2,
}));
const headerIdentity = computed(() => ({ ...identity.value, action: { id: "details", label: "聊天详情" } }));
const confirm = useFlareConfirm();
const toast = useFlareToast();

// App actions listed in the message menu next to the kit's own; `available` filters per message.
const messageActions: MessageMenuExtension[] = [
  { id: "report", label: "举报", icon: "warning", destructive: true, available: (ctx) => !ctx.isSelf },
];

function onHeaderAction(action: FlareConversationHeaderAction) {
  if (action.id === "search") showSearch.value = !showSearch.value;
  else if (action.id === "details") emit("openSettings");
}
function onDelete(kitId: string) {
  void confirm({ title: "删除消息", description: "只删除本机上的这条消息，对方仍能看到。", confirmText: "删除", action: () => deleteMessage(coreMessageId(kitId)) });
}
function onMessageAction(actionId: string, kitId: string) {
  if (actionId === "report") openReportFor(kitId);
}
function onCopy(_kitId: string, copied: boolean) {
  toast(copied ? { message: "已复制", tone: "success" } : { message: "复制失败，请手动选择文字", tone: "danger" });
}
</script>

<template>
  <section class="chat-area">
    <template v-if="activeConversation && headerIdentity">
      <FlareConversationHeader
        :identity="headerIdentity"
        :capabilities="headerCapabilities"
        :configuration="headerConfiguration"
        :show-back="showBack"
        @back="emit('back')"
        @action="onHeaderAction"
      />
      <!-- Attach only the intents this screen performs: the list hides every other control. -->
      <FlareMessageList
        ref="timeline"
        :conversation-id="convId"
        :conversation-type="convKind"
        :messages="messages"
        :current-user-id="uid"
        :loading-older="loadingOlder"
        :has-older="hasOlder"
        :unread-from-id="unreadFromId ?? undefined"
        :actions="messageActions"
        @load-older="loadOlderMessages"
        @react="onReact"
        @reply="onReply"
        @edit="onEdit"
        @recall="onRecall"
        @delete="onDelete"
        @resend="resendMessage"
        @action="onMessageAction"
        @copy="onCopy"
      >
        <template #empty>
          <FlareEmptyState v-if="loadingMessages" loading title="正在加载消息" />
          <FlareEmptyState v-else icon="chats" title="还没有消息" description="发一条消息，开始这段对话。" />
        </template>
      </FlareMessageList>
      <!-- FlareComposer: see build-chat-composer.md -->
    </template>
    <FlareEmptyState v-else icon="chats" title="选择一个会话" description="从左侧列表选择一个会话开始聊天。" />
  </section>
</template>
```

## Message model

The timeline renders what the app maps. Map every core message once:

- **Identity:** client id first (`resolveMessageId`); every intent carries that key.
- **Status:** from proto status, `conversationSeq` and `isRead`. Status 4 is failed and never read.
- **Content:** passed through as the core serializes it (`{ contentType, text, source, … }`).
- **Lifecycle and metadata:** `isRecalled`, `isEdited`, `pinned` (the core keeps it in `attributes.pinned`), `replyTo`, `quotePreview`, `textPreview`, `attributes` when a renderer needs host metadata, `localState` (upload progress), `timelineKey`, `timelineSortTs`.
- **Reactions:** `{ emoji, count, selected }`, where selected means the current user is among the reactors.

Order: sequenced messages by `conversationSeq`, then pending ones by `timelineSortTs`. Native apps map into `FlareMessageData` with the same rules, plus `reactions`, `lifecycle` for recall, `sentAtMs` for grouping, `replyTo` (`FlareReplyTarget` with the quoted row's id, sender name and summary) and a `timeLabel` from `FlareTimeFormat`.

Unread divider: remember the conversation's unread count when it opens, pick the message that many messages from others back from the end, and pass its id as `unreadFromId` until the user leaves the conversation.

## States

| State | Behaviour |
|---|---|
| Opening | Cached page first; the `#empty` slot shows loading while nothing is loaded; the load-older strip only appears while paging |
| Empty conversation | The `#empty` slot |
| Unread messages on open | `UnreadDivider` above the first unread message, with the count of messages from others below it |
| Failed send | Failed status on the bubble; retry through `@resend` re-sends the stored message with the same client id |
| Recalled message | Kit notice in place of the content, no actions |
| Locate a search hit or a quote | Page older history until the message is loaded, scroll to it, report "missing" if it never appears. Native lists scroll to a loaded quoted message themselves and call `onLocateMessage` otherwise |
| Copy | The kit writes the clipboard and emits `copy` with whether it worked; the app confirms with a toast |
| Keyboard | The list is one Tab stop: the last focused message, else the newest. Arrow keys, Home and End move between messages, Enter opens the message menu and Escape returns focus to the message; hover toolbar buttons are reachable only from the focused message |
| Start of history | Stop offering older messages when the core has no older page. Native apps backfill with `sync.conversation_history_backfill` when a page comes back short above seq 1 and stop on an empty page, because `message.list` returns no `has_more` (SDK gap S17); a failed load keeps the load-older retry |
| Pinned messages | `FlarePinnedMessageBar` above the timeline, a compact bar of single-line rows. The core has no op that lists a conversation's pinned messages and sends no pin events (SDK gap S20), so the bar lists the pinned messages that are loaded |
| Connection lost, signed out elsewhere, session expired | One `FlareStatusBanner` above every tab with the copy, tone and recovery from `connectionNotice(phase, t, { canReconnect })`; kicked and expired always offer 重新登录, which clears the local session even when logout fails. Log the core's technical reason; don't show it |

## Do and don't

- Don't show header actions the screen cannot perform; declare `capabilities`.
- Don't attach intent listeners you do not implement; an attached listener offers the control. Host actions in `actions` appear only while `@action` is attached.
- Don't render a typing row or an empty state beside the list; use the list's `#footer` and `#empty` slots so the timeline keeps its scroll and its tail.
- Do confirm recall and delete; do not confirm reactions, reply or edit.
- On phones, the header carries the back control. Don't add a separate back bar.
