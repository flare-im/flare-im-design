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

// Surfaces (spec/message-surface-vectors.json): a card is never put inside a bubble, and its time sits below it.
// In a group the viewer's own message shows the SDK's read summary in place of the ticks.
const location = {
  ...msg({ id: 5, self: true, text: "", ts: base + 3000, status: "read" }),
  content: { contentType: "location", location: { latitude: 31.2304, longitude: 121.4737, name: "人民广场", address: "上海市黄浦区人民大道" } },
};
const summarised = { ...msg({ id: 6, self: true, text: "周五下午三点评审，记得带上数据", ts: base + 4000, status: "sent" }), readSummary: { readCount: 4, unreadCount: 2, total: 6 } };
const failedCard = { ...location, serverId: "7", clientMsgId: "7", status: "failed" };

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
    <!-- 单聊:有头像、没有名字行 —— 头像贴着气泡顶(群聊那一版贴着名字行)。
         standalone 的气泡默认不画头像,呈现由宿主(列表)给,这里照列表给单聊算出的那份传。 -->
    <div class="canvas" aria-label="单聊">
      <FlareMessageBubble
        v-for="(row, i) in thread"
        :key="`direct-${i}`"
        :message="row.m"
        current-user-id="me"
        :self="row.self"
        conversation-kind="single"
        :group-position="row.gs && row.ge ? 'single' : row.gs ? 'first' : row.ge ? 'last' : 'middle'"
        :row-presentation="{ showAvatar: !row.self && row.gs, reserveAvatarSpace: !row.self, showSenderName: false, avatarPlacement: 'leading', tail: row.ge }"
      />
    </div>
    <div class="canvas" aria-label="卡片与已读摘要">
      <FlareMessageBubble :message="location" current-user-id="me" self conversation-kind="group" />
      <FlareMessageBubble :message="summarised" current-user-id="me" self conversation-kind="group" @read-receipt-open="() => {}" />
      <FlareMessageBubble :message="failedCard" current-user-id="me" self conversation-kind="group" @resend="() => {}" />
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
}
.canvas + .canvas {
  margin-top: 12px;
  padding: 16px;
  border-radius: 14px;
  /* 与 app 里时间线同一种面(FlareAppLayout / --flare-component-chat-window-bg),
     否则文档里的气泡画在一张 app 从不使用的底上。 */
  background: var(--flare-component-chat-window-bg);
}
</style>
