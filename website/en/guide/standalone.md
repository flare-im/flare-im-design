# Connect host data

Components are **pure presentation**: data goes in via props and interactions come
back as events. Any IM backend or local data source that maps to the public contracts works.

> Runnable example: [`examples/vue`](https://github.com/flare-im/flare-im-design/tree/main/examples/vue) — a plain in-memory data source, runnable with `npm i && npm run dev`.

## 1) Your "backend" is a plain store

No core, no observable views — a plain reactive object does the job. Swap it for your
own REST / WebSocket.

```ts
// backend.ts
import { reactive } from "vue";

export const backend = reactive({
  activeId: "c1",
  conversations: [
    { id: "c1", displayName: "Henry Ford", lastMessagePreview: "See you", updatedAt: Date.now() },
    { id: "c2", displayName: "Design Team", unreadCount: 2, lastMessagePreview: "shipped it" },
  ],
  threads: {
    c1: [{ id: "m1", self: false, text: "did the build go out?" }],
  } as Record<string, { id: string; self: boolean; text: string }[]>,

  get messages() { return this.threads[this.activeId] ?? []; },
  select(id: string) { this.activeId = id; },
  send(text: string) {
    this.threads[this.activeId].push({ id: crypto.randomUUID(), self: true, text });
    // …then POST to your backend / push over your WebSocket
  },
});
```

## 2) Feed data via props, listen for events

```vue
<script setup lang="ts">
import { computed, ref } from "vue";
import { useFlareI18nProvider } from "@flare-im/vue-ui/i18n";
import {
  FlareConversationList, FlareConversationRow,
  FlareMessageList, FlareComposer, useViewportProvider, type MessageLike,
} from "@flare-im/vue-ui";
import "@flare-im/vue-ui/style.css";
import { backend } from "./backend";

useFlareI18nProvider("en-US"); // one-time: language (zh / en built in)

const draft = ref("");
useViewportProvider();
const messages = computed<MessageLike[]>(() => backend.messages.map((m, index) => ({
  serverId: m.id, clientMsgId: m.id,
  senderId: m.self ? "me" : backend.activeId,
  senderDisplayName: m.self ? "You" : backend.activeId,
  conversationSeq: index + 1, createdAt: 0, clientCreatedAt: 0,
  messageType: 1, content: { contentType: "text", text: { text: m.text } },
  status: "sent", isRecalled: false, isRead: false,
  timelineKey: m.id, timelineSortTs: index, attributes: {}, extensions: {},
})));
function send() {
  const t = draft.value.trim();
  if (!t) return;
  backend.send(t);   // the component just emitted an event — how you send is up to you
  draft.value = "";
}
</script>

<template>
  <!-- Conversation list: items in, select event out -->
  <FlareConversationList :items="backend.conversations" :active-id="backend.activeId">
    <template #item="{ item, active }">
      <FlareConversationRow :item="item" :active="active" @select="backend.select(item.id)" />
    </template>
  </FlareConversationList>

  <!-- The list owns rows, bubbles, content, timestamps, and delivery states -->
  <FlareMessageList :messages="messages" current-user-id="me" :conversation-id="backend.activeId" :has-older="false" />

  <!-- Composer: send event callback -->
  <FlareComposer v-model="draft" :actions="[]" @send="send" />
</template>
```

That's it. **No bundled backend**: components take props and emit events; where the data
comes from and how messages are sent is entirely yours.

Here `createdAt: 0` means no timestamp is available and `sent` represents acceptance by the in-memory store. Production adapters must map actual backend timestamps and delivery states. `FlareTextMessage` renders content only, not bubble chrome.

## The whole contract

| You provide | Components give you |
|---|---|
| `items` / `messages` etc. as props | Rendering + interaction events (`@select` / `@send` / `@react` …) |
| `useFlareI18nProvider(locale)` (once) | Built-in zh / en copy |
| `import "…/style.css"` + override `--flare-color-*` (optional) | Light + dark, one-line re-skin |

See [Data Types](/en/reference/data-types) for the shapes, [Theming](/en/guide/theming)
for re-skinning, and [Getting started](/en/guide/getting-started) for complete composition.
