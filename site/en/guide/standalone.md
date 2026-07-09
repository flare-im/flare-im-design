# Bring your own backend (no Flare core)

Components are **pure presentation**: data goes in via props, interactions come back
as events, with **no SDK lock-in**. So any IM backend / data source works — the Flare
core is just an optional, batteries-included path.

> Runnable example: [`vue-im-ui/examples/standalone`](https://github.com/flare-im/flare-im-design/tree/main/vue-im-ui/examples/standalone) — a plain in-memory "backend", zero core, `npm i && npm run dev`.

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
import { ref } from "vue";
import { useFlareI18nProvider } from "flare-core-vue-im-ui/i18n";
import {
  FlareConversationList, FlareConversationRow,
  FlareTextMessage, FlareComposerSendButton,
} from "flare-core-vue-im-ui/components";
import "flare-core-vue-im-ui/style.css";
import { backend } from "./backend";

useFlareI18nProvider("en-US"); // one-time: language (zh / en built in)

const draft = ref("");
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

  <!-- Thread: one component per message type -->
  <FlareTextMessage v-for="m in backend.messages" :key="m.id" :text="m.text" :self="m.self" />

  <!-- Composer: send event callback -->
  <textarea v-model="draft" @keydown.enter.prevent="send" />
  <FlareComposerSendButton :active="!!draft.trim()" @send="send" />
</template>
```

That's it. **No core, no SDK** — components take props and emit events; where the data
comes from and how messages are sent is entirely yours.

## The whole contract

| You provide | Components give you |
|---|---|
| `items` / `messages` etc. as props | Rendering + interaction events (`@select` / `@send` / `@react` …) |
| `useFlareI18nProvider(locale)` (once) | Built-in zh / en copy |
| `import "…/style.css"` + override `--flare-color-*` (optional) | Light + dark, one-line re-skin |

See [Data Types](/en/reference/data-types) for the shapes and [Theming](/en/guide/theming)
for re-skinning. Want reliable send + multi-device sync out of the box? Then
[optionally wire Flare core](/en/guide/getting-started) — but the components don't
depend on it.
