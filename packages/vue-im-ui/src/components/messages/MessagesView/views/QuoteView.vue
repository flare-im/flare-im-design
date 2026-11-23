<script setup lang="ts">
import { computed } from "vue";
import { ReturnUpBackOutline } from "../../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import PlainTextEmojiRich from "../../../shared/PlainTextEmojiRich.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";
import { flareQuoteSenderText } from "../../../../utils/displayName";

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
// Never the id: the projected sender, a name the host wrote in, else the kit's unnamed person (spec quoteSender).
const quotedSender = computed(() =>
  flareQuoteSenderText(
    {
      sender: payload.value.quotedSender,
      senderName: readString(payload.value, "quotedSenderName"),
      senderId: readString(payload.value, "quotedSenderId"),
    },
    t,
  ),
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
  <div class="im-quote" :class="{ 'im-quote--outgoing': isSelf }">
    <button
      v-if="quotedMessageId && locatable"
      type="button"
      class="im-quote__source im-quote__source--clickable"
      @click.stop="emit('locate-message', quotedMessageId)"
    >
      <n-icon size="var(--flare-size-icon-size-sm)" aria-hidden="true" :component="ReturnUpBackOutline" />
      <span>{{ quotedSender }}</span>
      <strong>{{ quotedPreview || t("preview.message") }}</strong>
    </button>
    <div v-else class="im-quote__source">
      <n-icon size="var(--flare-size-icon-size-sm)" aria-hidden="true" :component="ReturnUpBackOutline" />
      <span>{{ quotedSender }}</span>
      <strong>{{ quotedPreview || t("preview.message") }}</strong>
    </div>
    <PlainTextEmojiRich class="im-quote__body" :text="currentText" />
  </div>
</template>

<style scoped>
.im-quote__source {
  --flare-component-quote-fill: var(--flare-color-message-reply-background);

  box-sizing: border-box;
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: var(--flare-size-spacing-2xs) var(--flare-size-spacing-xs);
  align-items: center;
  width: 100%;
  margin-block-end: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-2sm);
  border: 0;
  border-inline-start: 3px solid var(--flare-color-message-reply-border);
  border-start-end-radius: var(--flare-size-radius-md);
  border-end-end-radius: var(--flare-size-radius-md);
  background: var(--flare-component-quote-fill);
  color: inherit;
  font-size: var(--flare-size-font-size-sm);
  line-height: 1.4;
  text-align: start;
}

.im-quote--outgoing .im-quote__source {
  --flare-component-quote-fill: rgb(0 0 0 / 18%);
  border-inline-start-color: color-mix(in srgb, currentColor 58%, transparent);
}

.im-quote__source > span {
  overflow: hidden;
  color: color-mix(in srgb, currentColor 82%, transparent);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-quote__source strong {
  display: -webkit-box;
  grid-column: 1 / -1;
  overflow: hidden;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  overflow-wrap: anywhere;
  font-size: var(--flare-size-font-size-md);
  font-weight: 400;
}

.im-quote__source--clickable {
  min-height: 44px;
  cursor: pointer;
  transition: background var(--flare-component-motion-fast);
}

.im-quote__source--clickable:hover {
  background: color-mix(in srgb, currentColor 8%, var(--flare-component-quote-fill));
}

.im-quote__source--clickable:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

.im-quote__body {
  font-size: 14px;
  line-height: 1.5;
}
</style>
