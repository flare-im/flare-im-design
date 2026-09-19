<script setup>
/**
 * DoD 27 — the load the budgets are written against: 1000 conversations and
 * 5000 messages, mounted for real so the Playwright probe can count what the
 * kit actually put in the DOM and how long the mount took.
 *
 * Not a gallery: nothing here is styled for looks. It exists to be measured.
 */
import { computed, nextTick, onMounted, ref } from "vue";
import { FlareConversationList, FlareMessageList, FlareUiProvider } from "@flare-im/vue-ui/components";

// The load the budgets are written against. Both numbers are also the DoD 27
// scenario: 1000 conversations, 5000 messages.
const CONVERSATIONS = Number(new URLSearchParams(typeof location === "undefined" ? "" : location.search).get("conversations") ?? 1000);
const MESSAGES = Number(new URLSearchParams(typeof location === "undefined" ? "" : location.search).get("messages") ?? 5000);
// A fixed clock keeps the rendered timestamps stable between runs.
const EPOCH = Date.UTC(2025, 0, 15, 6, 32);

const conversations = computed(() =>
  Array.from({ length: CONVERSATIONS }, (_, index) => ({
    id: `conv-${index}`,
    displayName: `会话 ${index}`,
    lastMessagePreview: `第 ${index} 条预览文本，够长以触发省略号处理。`,
    updatedAt: EPOCH - index * 60_000,
    unreadCount: index % 7 === 0 ? (index % 40) + 1 : 0,
    pinned: index < 3,
    muted: index % 11 === 0,
  })),
);

const messages = computed(() =>
  Array.from({ length: MESSAGES }, (_, index) => {
    const ts = EPOCH - (MESSAGES - index) * 30_000;
    return {
      serverId: `msg-${index}`,
      clientMsgId: `msg-${index}`,
      senderId: index % 3 === 0 ? "me" : "peer",
      senderDisplayName: index % 3 === 0 ? "我" : `同事 ${index % 17}`,
      conversationSeq: index,
      createdAt: ts,
      clientCreatedAt: ts,
      messageType: 1,
      content: { contentType: "text", text: { text: `第 ${index} 条消息，带一点长度以产生真实换行与气泡宽度。` } },
      status: "read",
      isRecalled: false,
      isRead: true,
      timelineKey: `msg-${index}`,
      timelineSortTs: ts,
      attributes: {},
      reactions: [],
    };
  }),
);

const ready = ref(false);

onMounted(async () => {
  // Two frames: the first mounts, the second lets the virtual viewport settle
  // against real measured row heights.
  const started = performance.now();
  await nextTick();
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      window.__flarePerf = {
        conversations: CONVERSATIONS,
        messages: MESSAGES,
        mountMs: performance.now() - started,
      };
      ready.value = true;
    });
  });
});
</script>

<template>
  <FlareUiProvider theme-mode="light">
    <div id="perf-fixture" :data-perf-ready="ready ? 'true' : 'false'">
      <section data-perf-case="conversations">
        <FlareConversationList :items="conversations" />
      </section>
      <section data-perf-case="messages">
        <FlareMessageList :messages="messages" current-user-id="me" :has-older="false" />
      </section>
    </div>
  </FlareUiProvider>
</template>

<style scoped>
#perf-fixture {
  display: grid;
  grid-template-columns: 360px minmax(0, 1fr);
  gap: 12px;
  height: 100vh;
  background: var(--flare-color-bg-secondary);
}
#perf-fixture > section {
  min-width: 0;
  min-height: 0;
  height: 100%;
  overflow: hidden;
  background: var(--flare-color-bg-primary);
}
</style>
