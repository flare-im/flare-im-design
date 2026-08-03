<script setup>
import FlareMessageList from "@flare-im/vue-ui/components/messages/MessageList.vue";
import DemoStage from "./DemoStage.vue";

const me = "me";
const base = Date.now() - 300000;
function msg({ id, self, senderId, name, text, ts, status = 2 }) {
  return {
    serverId: String(id), clientMsgId: String(id),
    senderId: self ? me : senderId, senderDisplayName: name ?? "",
    conversationSeq: id, createdAt: ts, clientCreatedAt: ts, messageType: 1,
    content: { contentType: "text", text: { text } },
    status, isRecalled: false, isRead: true, timelineKey: String(id), timelineSortTs: ts,
  };
}
const messages = [
  msg({ id: 1, senderId: "ivy", name: "Ivy Chen", text: "新版设计稿已经上传啦，帮忙看下～", ts: base }),
  msg({ id: 2, self: true, text: "收到，我下午过一遍给你反馈 👍", ts: base + 60000, status: 4 }),
  msg({ id: 3, senderId: "ivy", name: "Ivy Chen", text: "辛苦～重点看下会话列表那块", ts: base + 120000 }),
  msg({ id: 4, self: true, text: "好的，没问题", ts: base + 180000, status: 4 }),
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareMessageList :messages="messages" current-user-id="me" conversation-type="group" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; height: 360px; border-radius: 14px; background: var(--flare-color-bg-secondary); overflow: hidden; }
</style>
