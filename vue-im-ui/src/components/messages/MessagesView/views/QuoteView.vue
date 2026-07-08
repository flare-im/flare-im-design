<script setup lang="ts">
import { computed } from "vue";
import { ReturnUpBackOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import PlainTextEmojiRich from "../../../shared/PlainTextEmojiRich.vue";

const props = withDefaults(
  defineProps<{ content: ContentElem; isSelf: boolean; messageExtra?: Record<string, unknown> }>(),
  {
    messageExtra: () => ({}),
  },
);

const emit = defineEmits<{
  (event: "locate-message", messageId: string): void;
}>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "quote");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const quotedMessageId = computed(() => readString(payload.value, "quotedMessageId"));
const quotedSender = computed(() =>
  readString(payload.value, "quotedSenderName", "quotedSenderId"),
);
const quotedPreview = computed(() => readString(payload.value, "quotedTextPreview", "preview"));
const currentText = computed(() => {
  const direct = readString(payload.value, "currentText", "text", "body");
  if (direct) return direct;
  const camelCurrentContent = pickNestedPayload(payload.value as ContentElem, "currentContent");
  const currentContent = camelCurrentContent;
  const currentData = pickNestedPayload(currentContent as ContentElem, "data");
  return (
    readString(currentContent, "text", "body") ||
    readString(currentData, "text", "body") ||
    readString(props.messageExtra, "textPreview", "quotePreview")
  );
});
</script>

<template>
  <div class="im-quote">
    <button
      v-if="quotedMessageId"
      type="button"
      class="im-quote__source im-quote__source--clickable"
      @click.stop="emit('locate-message', quotedMessageId)"
    >
      <n-icon :component="ReturnUpBackOutline" />
      <span>{{ quotedSender || "原消息" }}</span>
      <strong>{{ quotedPreview || "引用消息" }}</strong>
    </button>
    <div v-else class="im-quote__source">
      <n-icon :component="ReturnUpBackOutline" />
      <span>{{ quotedSender || "原消息" }}</span>
      <strong>{{ quotedPreview || "引用消息" }}</strong>
    </div>
    <PlainTextEmojiRich class="im-quote__body" :text="currentText" />
  </div>
</template>

<style scoped>
.im-quote__source {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: center;
  width: 100%;
  margin-bottom: 8px;
  padding: 8px 10px;
  border-left: 3px solid var(--im-message-outgoing, #2f6bff);
  border-top: 0;
  border-right: 0;
  border-bottom: 0;
  border-radius: 0 8px 8px 0;
  background: color-mix(in srgb, var(--im-bg-surface-alt) 88%, transparent);
  color: var(--im-text-secondary);
  font-size: 12px;
  text-align: left;
}

.im-quote__source strong {
  width: 100%;
  color: var(--im-text-primary);
  font-size: 13px;
}

.im-quote__source--clickable {
  cursor: pointer;
  transition:
    background var(--im-motion-fast, 140ms ease),
    border-color var(--im-motion-fast, 140ms ease);
}

.im-quote__source--clickable:hover,
.im-quote__source--clickable:focus-visible {
  border-left-color: var(--im-primary);
  outline: none;
  background: color-mix(in srgb, var(--im-primary) 12%, var(--im-bg-surface-alt));
}

.im-quote__body {
  font-size: 14px;
  line-height: 1.5;
}
</style>
