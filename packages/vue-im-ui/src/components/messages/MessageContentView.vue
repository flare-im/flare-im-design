<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import type { MessageContentLike } from "../../utils/contentElem";
import { ContentView } from "./MessagesView";
import type { MessageMediaDownloadUiState } from "./MessageBubble.vue";
import type { FlareLocationValue } from "../../shared/contracts/location";

defineProps<{
  content?: MessageContentLike;
  self?: boolean;
  previewMode?: boolean;
  messageId?: string;
  /** The id a custom renderer receives as `messageId` (server id, else client id). */
  rendererMessageId?: string;
  conversationId?: string;
  messageExtra?: Record<string, unknown>;
  senderName?: string;
  mediaAction?: "download" | "openFolder" | null;
  mediaState?: MessageMediaDownloadUiState | null;
}>();

const emit = defineEmits<{
  (event: "locate-message", messageId: string): void;
  (event: "media-action", action: "download" | "openFolder"): void;
  (event: "vote", optionIndex: number): void;
  (event: "taskToggle", done: boolean): void;
  (event: "cardOpen", userId: string): void;
  (event: "locationOpen", location: FlareLocationValue): void;
}>();

// A poll's options and a task's checkbox are controls only while the host takes them.
const instance = getCurrentInstance();
const intentListeners = computed(() => ({
  ...(instance?.vnode.props?.onVote ? { vote: (optionIndex: number) => emit("vote", optionIndex) } : {}),
  ...(instance?.vnode.props?.onTaskToggle ? { taskToggle: (done: boolean) => emit("taskToggle", done) } : {}),
  ...(instance?.vnode.props?.onCardOpen ? { cardOpen: (userId: string) => emit("cardOpen", userId) } : {}),
  ...(instance?.vnode.props?.onLocationOpen
    ? { locationOpen: (location: FlareLocationValue) => emit("locationOpen", location) }
    : {}),
}));
</script>

<template>
  <ContentView
    :content="content"
    :is-self="self"
    :preview-mode="previewMode"
    :message-id="messageId"
    :renderer-message-id="rendererMessageId"
    :conversation-id="conversationId"
    :message-extra="messageExtra"
    :sender-name="senderName"
    :media-action="mediaAction"
    :media-state="mediaState"
    v-on="intentListeners"
    @locate-message="emit('locate-message', $event)"
    @media-action="emit('media-action', $event)"
  />
</template>
