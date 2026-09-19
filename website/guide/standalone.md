# 接入宿主数据

组件是**纯展示**：数据用 props 传入，交互以事件抛出，不绑定任何 SDK。任何符合公开 contract 的 IM 后端或本地数据源都可以接入。

> 可运行示例：[`examples/vue`](https://github.com/flare-im/flare-im-design/tree/main/examples/vue) —— 纯内存数据源，`npm i && npm run dev` 即可跑。

## 1) 你的"后端"就是一个普通 store

不需要 core / 可观察视图——一个普通的响应式对象即可。换成你的 REST / WebSocket 也一样。

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
    // …然后 POST 到你的后端 / 通过 WebSocket 发出去
  },
});
```

## 2) 用 props 喂数据、监听事件

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

useFlareI18nProvider("en-US"); // 一次性：语言（内置 zh / en）

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
  backend.send(t);   // 组件只是抛了个事件，怎么发是你的事
  draft.value = "";
}
</script>

<template>
  <!-- 会话列表：items 进，选中事件出 -->
  <FlareConversationList :items="backend.conversations" :active-id="backend.activeId">
    <template #item="{ item, active }">
      <FlareConversationRow :item="item" :active="active" @select="backend.select(item.id)" />
    </template>
  </FlareConversationList>

  <!-- 消息列表统一负责行布局、气泡、正文、时间和状态 -->
  <FlareMessageList :messages="messages" current-user-id="me" :conversation-id="backend.activeId" :has-older="false" />

  <!-- 输入：send 事件回调 -->
  <FlareComposer v-model="draft" :actions="[]" @send="send" />
</template>
```

就这些。**不内置后端**：组件收 props、抛事件，数据从哪来、消息怎么发全由宿主决定。

示例的 `createdAt: 0` 表示没有时间信息，内存存储成功后显示 `sent`；生产适配器必须映射后端的真实时间与投递状态。`FlareTextMessage` 只渲染正文，不单独拥有气泡外观。

## 就这一点点约定

| 你提供 | 组件给你 |
|---|---|
| `items` / `messages` 等数据（props） | 渲染 + 交互事件（`@select` / `@send` / `@react` …） |
| `useFlareI18nProvider(locale)`（一次） | 内置 zh / en 文案 |
| `import "…/style.css"` + 覆盖 `--flare-color-*`（可选） | 明暗双主题 + 一键换肤 |

数据类型见[数据类型](/reference/data-types)；换肤见[主题定制](/guide/theming)；完整组合方式见[快速开始](/guide/getting-started)。
