<script setup>
import { computed, inject, ref } from "vue";
import { FlareBottomSheet, FlareButton, FlareMessageBubble, FlareMessageActionSheet } from "@flare-im/vue-ui/components";
import { buildMessageContextSheetModel } from "@flare-im/vue-ui/utils";
import DemoStage from "./DemoStage.vue";
import { previewContextKey } from "./preview-context";

const preview = inject(previewContextKey, null);
const mobile = computed(() => preview?.viewport.value === "mobile");
const open = ref(true);
const time = new Date(2025, 0, 15, 14, 30).getTime();
const messages = [
  { id: "1", senderId: "ivy", senderDisplayName: "Ivy Chen", text: "新版设计稿已经上传，请查收。" },
  { id: "2", senderId: "me", senderDisplayName: "", text: "收到，我下午给你反馈。" },
].map(({ id, text, ...sender }) => ({
  ...sender, serverId: id, clientMsgId: id, conversationSeq: Number(id),
  createdAt: time, clientCreatedAt: time, messageType: 1,
  content: { contentType: "text", text: { text } },
  status: "read", isRecalled: false, isRead: true,
  timelineKey: id, timelineSortTs: time, attributes: {},
}));
const model = buildMessageContextSheetModel(messages[1], "me");
</script>

<template>
  <DemoStage>
    <div v-if="!mobile" class="mas-demo__thread" data-preview-platform="desktop">
      <FlareMessageBubble v-for="message in messages" :key="message.serverId" :message="message" current-user-id="me" :self="message.senderId === 'me'" conversation-kind="single" />
    </div>
    <div v-else data-preview-platform="mobile">
      <FlareButton label="消息操作" @click="open = true" />
      <FlareBottomSheet :open="open" @close="open = false">
        <FlareMessageActionSheet :model="model" :show-grabber="false" @action="open = false" @react="open = false" />
      </FlareBottomSheet>
    </div>
  </DemoStage>
</template>

<style scoped>
.mas-demo__thread { display: flex; flex-direction: column; gap: 12px; width: 100%; min-width: 0; }
</style>
