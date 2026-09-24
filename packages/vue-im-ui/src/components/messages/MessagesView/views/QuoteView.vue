<script setup lang="ts">
import { computed } from "vue";
import { ReturnUpBackOutline } from "../../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import PlainTextEmojiRich from "../../../shared/PlainTextEmojiRich.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{ content: ContentElem; isSelf: boolean; messageExtra?: Record<string, unknown> }>(),
  {
    messageExtra: () => ({}),
  },
);

const emit = defineEmits<{
  (event: "locate-message", messageId: string): void;
}>();
const { t } = useFlareI18nOptional();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "quote");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const quotedMessageId = computed(() => readString(payload.value, "quotedMessageId"));
/** The list says whether a tap would reach the quoted message; on its own, assume it would. */
const locatable = computed(() => readString(props.messageExtra, "quoteLocatable") !== "0");
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
      v-if="quotedMessageId && locatable"
      type="button"
      class="im-quote__source im-quote__source--clickable"
      @click.stop="emit('locate-message', quotedMessageId)"
    >
      <n-icon aria-hidden="true" :component="ReturnUpBackOutline" />
      <span>{{ quotedSender || t("quote.originalMessage") }}</span>
      <strong>{{ quotedPreview || t("preview.message") }}</strong>
    </button>
    <div v-else class="im-quote__source">
      <n-icon aria-hidden="true" :component="ReturnUpBackOutline" />
      <span>{{ quotedSender || t("quote.originalMessage") }}</span>
      <strong>{{ quotedPreview || t("preview.message") }}</strong>
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
  padding: 8px var(--flare-size-spacing-2sm);
  border-left: 3px solid var(--flare-color-message-outgoing-background);
  border-top: 0;
  border-right: 0;
  border-bottom: 0;
  border-radius: 0 8px 8px 0;
  background: color-mix(in srgb, var(--flare-color-bg-tertiary) 88%, transparent);
  color: var(--flare-color-text-secondary);
  font-size: 12px;
  text-align: left;
}

.im-quote__source strong {
  width: 100%;
  color: var(--flare-color-text-primary);
  font-size: 13px;
}

.im-quote__source--clickable {
  cursor: pointer;
  transition:
    background var(--flare-component-motion-fast),
    border-color var(--flare-component-motion-fast);
}

.im-quote__source--clickable:hover,
.im-quote__source--clickable:focus-visible {
  border-left-color: var(--flare-color-primary);
  outline: none;
  background: color-mix(in srgb, var(--flare-color-primary) 12%, var(--flare-color-bg-tertiary));
}

.im-quote__body {
  font-size: 14px;
  line-height: 1.5;
}
</style>
