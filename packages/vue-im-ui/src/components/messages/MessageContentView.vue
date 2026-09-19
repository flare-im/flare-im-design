<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import type { MessageContentLike } from "../../utils/contentElem";
import { ContentView } from "./MessagesView";
import type { MessageMediaDownloadUiState } from "./MessageBubble.vue";

defineProps<{
  content?: MessageContentLike;
  self?: boolean;
  previewMode?: boolean;
  messageId?: string;
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
}>();

// A poll's options and a task's checkbox are controls only while the host takes them.
const instance = getCurrentInstance();
const intentListeners = computed(() => ({
  ...(instance?.vnode.props?.onVote ? { vote: (optionIndex: number) => emit("vote", optionIndex) } : {}),
  ...(instance?.vnode.props?.onTaskToggle ? { taskToggle: (done: boolean) => emit("taskToggle", done) } : {}),
}));
</script>

<template>
  <ContentView
    :content="content"
    :is-self="self"
    :preview-mode="previewMode"
    :message-id="messageId"
    :message-extra="messageExtra"
    :sender-name="senderName"
    :media-action="mediaAction"
    :media-state="mediaState"
    v-on="intentListeners"
    @locate-message="emit('locate-message', $event)"
    @media-action="emit('media-action', $event)"
  />
</template>
