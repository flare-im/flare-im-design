<script setup>
import { ref } from "vue";
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

// A window opened around an earlier message: newer history below it, and the way back to the latest.
const around = [
  msg({ id: 101, senderId: "ivy", name: "Ivy Chen", text: "上周定的验收标准在这里。", ts: base - 86_400_000 }),
  msg({ id: 102, self: true, text: "定位到的就是这一条，下面还有更新的消息。", ts: base - 86_340_000, status: "read" }),
];
const newerPage = [
  msg({ id: 103, senderId: "ivy", name: "Ivy Chen", text: "往下滚或点「加载更新的消息」，更新的一页接在下面。", ts: base - 86_280_000 }),
];
const aroundWindow = ref(around);
const hasNewer = ref(true);
const loadingNewer = ref(false);
function loadNewer() {
  loadingNewer.value = true;
  setTimeout(() => {
    // The page reaches the latest messages: the window is attached again.
    aroundWindow.value = [...around, ...newerPage, ...messages];
    hasNewer.value = false;
    loadingNewer.value = false;
  }, 600);
}
function jumpToLatest() {
  aroundWindow.value = messages;
  hasNewer.value = false;
}
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareMessageList :messages="messages" :has-older="false" current-user-id="me" conversation-kind="group" />
    </div>
    <div class="stage">
      <FlareMessageList
        :messages="aroundWindow"
        :has-older="false"
        :has-newer="hasNewer"
        :loading-newer="loadingNewer"
        current-user-id="me"
        conversation-kind="group"
        @load-newer="loadNewer"
        @jump-to-latest="jumpToLatest"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; height: 360px; border-radius: 14px; background: var(--flare-color-bg-secondary); overflow: hidden; }
.stage + .stage { margin-top: 16px; }
</style>
