# 接你自己的后端（不需要 Flare core）

组件是**纯展示**：数据用 props 传入、交互以事件抛出，**不绑定任何 SDK**。所以任何 IM 后端 / 数据源都能接——Flare core 只是可选的开箱即用项。

> 可运行示例：[`vue-im-ui/examples/standalone`](https://github.com/flare-im/flare-im-design/tree/main/vue-im-ui/examples/standalone) —— 纯内存"后端"，零 core，`npm i && npm run dev` 即可跑。

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
import { ref } from "vue";
import { useFlareI18nProvider } from "@flare-im/vue-ui/i18n";
import {
  FlareConversationList, FlareConversationRow,
  FlareTextMessage, FlareComposerSendButton,
} from "@flare-im/vue-ui/components";
import "@flare-im/vue-ui/style.css";
import { backend } from "./backend";

useFlareI18nProvider("en-US"); // 一次性：语言（内置 zh / en）

const draft = ref("");
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

  <!-- 消息线：每种消息体一个独立组件 -->
  <FlareTextMessage v-for="m in backend.messages" :key="m.id" :text="m.text" :self="m.self" />

  <!-- 输入：send 事件回调 -->
  <textarea v-model="draft" @keydown.enter.prevent="send" />
  <FlareComposerSendButton :active="!!draft.trim()" @send="send" />
</template>
```

就这些。**没有 core、没有 SDK**——组件收 props、抛事件,数据从哪来、消息怎么发,全由你决定。

## 就这一点点约定

| 你提供 | 组件给你 |
|---|---|
| `items` / `messages` 等数据（props） | 渲染 + 交互事件（`@select` / `@send` / `@react` …） |
| `useFlareI18nProvider(locale)`（一次） | 内置 zh / en 文案 |
| `import "…/style.css"` + 覆盖 `--flare-color-*`（可选） | 明暗双主题 + 一键换肤 |

数据类型见[数据类型](/reference/data-types)；换肤见[主题定制](/guide/theming)。想要开箱即用的可靠收发与多端同步,再[可选接 Flare core](/guide/getting-started) 即可——但组件本身不依赖它。
