<script setup>
// Renders the REAL kit component so the docs cannot drift from the shipped bubble.
import { FlareMessageBubble } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const me = "me";
const base = new Date(2025, 0, 15, 14, 30).getTime();

function msg({ id, self, senderId, name, text, ts, status = "sent" }) {
  return {
    serverId: String(id),
    clientMsgId: String(id),
    senderId: self ? me : senderId,
    senderDisplayName: name ?? "",
    conversationSeq: id,
    createdAt: ts,
    clientCreatedAt: ts,
    messageType: 1,
    content: { contentType: "text", text: { text } },
    status,
    isRecalled: false,
    isRead: true,
    timelineKey: String(id),
    timelineSortTs: ts,
    attributes: {},
  };
}

const thread = [
  { m: msg({ id: 2, senderId: "ivy", name: "Ivy", text: "新版设计稿已经上传啦，帮忙看下～", ts: base }), self: false, gs: true, ge: true },
  { m: msg({ id: 3, self: true, text: "收到，我下午过一遍给你反馈 👍", ts: base + 1000, status: "read" }), self: true, gs: true, ge: false },
  { m: msg({ id: 4, self: true, text: "整体方向没问题", ts: base + 2000, status: "read" }), self: true, gs: false, ge: true },
];
</script>

<template>
  <DemoStage>
    <div class="canvas">
      <FlareMessageBubble
        v-for="(row, i) in thread"
        :key="i"
        :message="row.m"
        current-user-id="me"
        :self="row.self"
        conversation-kind="group"
        :group-position="row.gs && row.ge ? 'single' : row.gs ? 'first' : row.ge ? 'last' : 'middle'"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.canvas {
  width: 100%;
  max-width: 460px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 16px;
  border-radius: 14px;
  background: var(--flare-color-bg-secondary);
}
</style>
