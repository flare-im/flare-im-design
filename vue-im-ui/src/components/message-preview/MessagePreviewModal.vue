<script setup lang="ts">
import { computed } from "vue";
import { NTag } from "naive-ui";
import { messageContentTypeForUi } from "../../utils/messageContent";
import { ContentView } from "../messages/MessagesView";
import { normalizeToContentElem } from "../../utils/contentElem";
import { previewTextFromMessageContent } from "../../utils/messagePreview";
import { isMarkdown } from "../../utils/markdown";
import { textBodyFromContent } from "../../utils/contentElem";
import MarkdownPreview from "./MarkdownPreview.vue";

type PreviewMessage = {
  senderDisplayName?: string;
  senderId?: string;
  createdAt?: number;
  clientCreatedAt?: number;
  content?: {
    contentType?: string;
    data?: Record<string, unknown>;
  };
  attributes?: Record<string, unknown>;
};

const props = defineProps<{
  message?: PreviewMessage | null;
}>();

const type = computed(() =>
  messageContentTypeForUi(props.message?.content?.contentType ?? "text"),
);
const decoded = computed(() => normalizeToContentElem(props.message?.content));
const summary = computed(() =>
  previewTextFromMessageContent(props.message?.content),
);
const markdownBody = computed(() => {
  if (!decoded.value || type.value !== "text") return "";
  const body = textBodyFromContent(decoded.value);
  return isMarkdown(body) ? body : "";
});

const title = computed(() => {
  const labels: Record<string, string> = {
    image: "Image preview",
    video: "Video preview",
    audio: "Voice preview",
    file: "File preview",
    location: "Location",
    quote: "Quote message",
    forward: "Forwarded message",
    richText: "Rich text",
    sticker: "Sticker",
    emoji: "Emoji",
  };
  return labels[type.value] ?? "Message details";
});

const timeText = computed(() => {
  const ts = Number(
    props.message?.createdAt ?? props.message?.clientCreatedAt ?? 0,
  );
  if (!ts) return "";
  return new Date(ts).toLocaleString("zh-CN");
});
</script>

<template>
  <section v-if="message" class="preview-modal">
    <header class="preview-modal__head">
      <div>
        <strong>{{ title }}</strong>
        <span>{{
          message.senderDisplayName || message.senderId || "Unknown sender"
        }}</span>
        <small v-if="timeText">{{ timeText }}</small>
      </div>
      <n-tag round size="small">{{ type }}</n-tag>
    </header>

    <div class="preview-modal__body" :class="`preview-modal__body--${type}`">
      <ContentView
        v-if="message.content"
        :content="message.content"
        preview-mode
        :sender-name="message.senderDisplayName"
        :message-extra="message.attributes"
      />
      <MarkdownPreview v-else-if="markdownBody" :content="markdownBody" />
      <p v-else class="preview-modal__fallback">{{ summary }}</p>
    </div>

    <details
      v-if="message.content?.data && Object.keys(message.content.data).length"
      class="preview-modal__raw"
    >
      <summary>Raw payload</summary>
      <pre>{{ JSON.stringify(message.content.data, null, 2) }}</pre>
    </details>
  </section>
</template>

<style scoped>
.preview-modal {
  display: flex;
  flex-direction: column;
  gap: 14px;
  min-width: 0;
}

.preview-modal__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.preview-modal__head span,
.preview-modal__head small {
  display: block;
  color: var(--im-text-secondary);
  font-size: 12px;
}

.preview-modal__body {
  min-height: 120px;
  padding: 12px;
  border: 1px solid var(--im-border);
  border-radius: 12px;
  background: var(--im-bg-surface-alt, #f4f6f9);
}

.preview-modal__fallback {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  color: var(--im-text-primary);
}

.preview-modal__raw summary {
  cursor: pointer;
  color: var(--im-text-secondary);
  font-size: 12px;
}

.preview-modal__raw pre {
  margin-top: 8px;
  max-height: 220px;
  overflow: auto;
  padding: 10px;
  border-radius: 8px;
  background: var(--im-bg-surface);
  font-size: 11px;
}
</style>
