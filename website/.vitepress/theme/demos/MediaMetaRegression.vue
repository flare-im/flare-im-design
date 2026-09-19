<script setup lang="ts">
import { ref } from "vue";
import { FlareMessageBubble } from "@flare-im/vue-ui/components";
import type { MessageLike, MessageStatusState } from "@flare-im/vue-ui/contracts";
import DemoStage from "./DemoStage.vue";
import artwork from "../../../../packages/vue-im-ui/src/assets/brand/auth-technology.webp";

const status = ref<MessageStatusState>("read");
const retries = ref(0);
const states: MessageStatusState[] = ["pending", "sending", "sent", "delivered", "read", "failed", "retrying"];
const cases = [
  { id: "sticker", content: { contentType: "sticker", sticker: { url: "/flare-im-ui-assets/stickers/classic/001.webp" } } },
  { id: "emoji", content: { contentType: "emoji", emoji: { key: "grinning_face" } } },
  { id: "single-emoji", content: { contentType: "text", text: { text: "[grinning_face]" } } },
  { id: "image", content: { contentType: "image", image: { url: artwork } } },
  { id: "video", content: { contentType: "video", video: { coverUrl: artwork } } },
  { id: "upload", content: { contentType: "image", image: { url: artwork } } },
  { id: "edited", content: { contentType: "emoji", emoji: { key: "grinning_face" } } },
  { id: "text", content: { contentType: "text", text: { text: "See you tomorrow." } } },
];
const timestamp = new Date(2025, 0, 15, 23, 13).getTime();
function message(item: typeof cases[number], self: boolean): MessageLike {
  const id = `${item.id}-${self ? "out" : "in"}`;
  return {
    serverId: id, clientMsgId: id, senderId: self ? "me" : "ivy", senderDisplayName: "Ivy",
    conversationSeq: 1, createdAt: timestamp, clientCreatedAt: timestamp, messageType: 1,
    content: item.content, status: item.id === "upload" ? "sending" : status.value,
    isRecalled: false, isRead: item.id !== "upload" && status.value === "read",
    localState: item.id === "upload" && self ? { uploading: true, uploadProgress: 45 } : undefined,
    timelineKey: id, timelineSortTs: timestamp, isEdited: item.id === "edited",
    attributes: item.id === "edited" ? { ephemeralState: "readOnce" } : {},
  };
}
</script>

<template>
  <DemoStage>
    <main id="media-meta-regression" :data-retries="retries">
      <label class="state-picker">Delivery state
        <select v-model="status" aria-label="Delivery state">
          <option v-for="state in states" :key="state" :value="state">{{ state }}</option>
        </select>
      </label>
      <section v-for="item in cases" :key="item.id" :data-media-case="item.id" :aria-label="item.id">
        <FlareMessageBubble v-for="self in [false, true]" :key="String(self)"
          :message="message(item, self)" :self="self" current-user-id="me"
          @resend="retries += 1" />
      </section>
    </main>
  </DemoStage>
</template>

<style scoped>
#media-meta-regression {
  box-sizing: border-box;
  width: min(100%, 900px);
  margin-inline: auto;
  padding: var(--flare-size-spacing-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
}
section { margin-block: var(--flare-size-spacing-md); }
.state-picker { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); }
select { font: inherit; color: inherit; background: var(--flare-color-bg-primary); }
</style>
