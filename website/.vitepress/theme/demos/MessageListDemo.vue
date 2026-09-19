<script setup>
import { FlareMessageList } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const me = "me";
const base = new Date(2025, 0, 15, 14, 27).getTime();
function msg({ id, self, senderId, name, text, ts, status = "sent", reactions = [] }) {
  return {
    serverId: String(id), clientMsgId: String(id),
    senderId: self ? me : senderId, senderDisplayName: name ?? "",
    conversationSeq: id, createdAt: ts, clientCreatedAt: ts, messageType: 1,
    content: { contentType: "text", text: { text } },
    status, isRecalled: false, isRead: true, timelineKey: String(id), timelineSortTs: ts,
    attributes: {}, reactions,
  };
}
const messages = [
  msg({ id: 1, senderId: "ivy", name: "Ivy Chen", text: "新版设计稿已经上传啦。", ts: base }),
  msg({ id: 2, senderId: "ivy", name: "Ivy Chen", text: "重点看消息分组、头像对齐和移动端操作。", ts: base + 25_000, reactions: [{ emoji: "👍", count: 2, selected: true }] }),
  msg({ id: 3, self: true, text: "收到，我会同时检查窄屏和长内容在最大宽度下的换行表现。", ts: base + 120_000, status: "read" }),
  msg({ id: 4, self: true, text: "这条消息发送失败，可以在原位重试。", ts: base + 180_000, status: "failed" }),
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareMessageList :messages="messages" :has-older="false" current-user-id="me" conversation-kind="group" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; height: 360px; border-radius: 14px; background: var(--flare-color-bg-secondary); overflow: hidden; }
</style>
