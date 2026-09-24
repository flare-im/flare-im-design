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
        :row-presentation="{ showAvatar: !row.self && row.gs, reserveAvatarSpace: !row.self, showSenderName: false, avatarPlacement: 'leading' }"
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
