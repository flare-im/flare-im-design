<script setup lang="ts">
import { ref } from "vue";
import {
  FlareChatWorkspace,
  FlareComposer,
  FlareConversationHeader,
  FlareMessageList,
  FlareStatusBanner,
  type FlareConversationHeaderAction,
} from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";

const draft = ref("");
const messages = ref([
  message("1", "ivy", "Ivy Chen", "The updated navigation is ready for review.", 0),
  message("2", "ivy", "Ivy Chen", "I kept the mobile path focused on the conversation.", 54_000),
  message("3", "me", "Me", "Great. I will verify the grouped timeline next.", 118_000, "read"),
]);

const headerCapabilities = {
  availableActionIds: ["search", "addMember", "share", "details", "task"],
};
const headerActions: FlareConversationHeaderAction[] = [
  { id: "task", label: "Create task", icon: "check", placement: "add", order: 60 },
];

function message(id: string, senderId: string, name: string, text: string, offset: number, status = "sent") {
  const time = new Date(2025, 0, 15, 14, 27).getTime() + offset;
  return {
    serverId: id,
    clientMsgId: id,
    senderId,
    senderDisplayName: name,
    conversationSeq: Number(id),
    createdAt: time,
    clientCreatedAt: time,
    messageType: 1,
    content: { contentType: "text", text: { text } },
    status,
    isRecalled: false,
    isRead: true,
    timelineKey: id,
    timelineSortTs: time,
    attributes: {},
    reactions: id === "2" ? [{ emoji: "👍", count: 2, selected: true }] : [],
  };
}

function send(text: string) {
  const value = text.trim();
  if (!value) return;
  messages.value.push(message(String(messages.value.length + 1), "me", "Me", value, 180_000, "read"));
  draft.value = "";
}
</script>

<template>
  <DemoStage>
    <div class="workspace-demo">
      <FlareChatWorkspace label="Product room conversation">
        <template #context>
          <FlareStatusBanner text="Demo data · actions stay host-owned" tone="info" />
        </template>
        <template #header>
          <FlareConversationHeader
            :identity="{ id: 'product-room', title: 'Product room', kind: 'group', memberCount: 18 }"
            :capabilities="headerCapabilities"
            :actions="headerActions"
            @action="() => undefined"
          />
        </template>
        <template #timeline>
          <FlareMessageList
            conversation-id="product-room"
            conversation-kind="group"
            :messages="messages"
            current-user-id="me"
            :has-older="false"
          />
        </template>
        <template #composer>
          <FlareComposer v-model="draft" target-name="Product room" @send="send" />
        </template>
      </FlareChatWorkspace>
    </div>
  </DemoStage>
</template>

<style scoped>
.workspace-demo {
  width: 100%;
  height: 470px;
  min-width: 0;
  overflow: hidden;
  background: var(--flare-color-bg-secondary);
}
</style>
