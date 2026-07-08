<script setup lang="ts">
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
}>();
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
    @locate-message="emit('locate-message', $event)"
    @media-action="emit('media-action', $event)"
  />
</template>
