<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { textBodyFromContent } from "../../../../utils/contentElem";
import {
  resolveLoneEmojiPackInText,
  splitPlainTextForEmojiDisplay,
} from "../../../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { formatEmojiPackBracket } from "../../../../utils/emojiPackI18n";
import { escapeHtml } from "../../../../utils/escapeHtml";
import { isMarkdown, renderMarkdown } from "../../../../utils/markdown";
import PlainTextEmojiRich from "../../../shared/PlainTextEmojiRich.vue";
import FrozenStickerThumb from "../../../composer/FrozenStickerThumb/index.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const rawText = computed(() => textBodyFromContent(props.content));

const loneMappedEmoji = computed(() => {
  const text = rawText.value;
  if (!text || isMarkdown(text)) return null;
  return resolveLoneEmojiPackInText(text);
});

const loneEmojiBracketFallback = computed(() => {
  const text = rawText.value.trim();
  if (!text || isMarkdown(rawText.value)) return null;
  const parts = splitPlainTextForEmojiDisplay(text);
  if (parts.length !== 1 || parts[0].kind !== "emojiUnknown") return null;
  return parts[0];
});

const emojiRichSegments = computed(() => {
  if (loneMappedEmoji.value || loneEmojiBracketFallback.value) return null;
  const text = rawText.value;
  if (!text || isMarkdown(text)) return null;
  const parts = splitPlainTextForEmojiDisplay(text);
  if (!parts.some((part) => part.kind === "emoji" || part.kind === "emojiUnknown")) return null;
  return parts;
});

const renderedHtml = computed(() => {
  const text = rawText.value;
  if (!text) return "";
  if (isMarkdown(text)) return renderMarkdown(text);
  return escapeHtml(text).replace(/\n/g, "<br>");
});
</script>

<template>
  <div v-if="loneMappedEmoji" class="im-text im-text--lone-emoji">
    <FrozenStickerThumb
      class="im-lone-emoji-img"
      :load-src="loneMappedEmoji.loadUrl"
      :alt="loneMappedEmoji.key"
      object-fit="contain"
    />
  </div>
  <div v-else-if="loneEmojiBracketFallback" class="im-text im-text--lone-emoji im-text--lone-bracket">
    <span class="im-emoji-bracket">{{ formatEmojiPackBracket(loneEmojiBracketFallback.key) }}</span>
  </div>
  <div v-else-if="emojiRichSegments" class="im-text im-text--emoji-rich">
    <PlainTextEmojiRich :text="rawText" />
  </div>
  <div v-else class="im-text" v-html="renderedHtml" />
</template>

<style scoped>
.im-text {
  font-size: 14px;
  line-height: 1.5;
  color: inherit;
  white-space: pre-wrap;
  word-break: normal;
  overflow-wrap: break-word;
}

.im-text--lone-emoji {
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 0;
}

.im-lone-emoji-img {
  max-width: min(6.3em, 34vw);
  max-height: min(6.3em, 34vw);
  width: min(6.3em, 34vw);
  height: min(6.3em, 34vw);
}

.im-emoji-bracket {
  font-size: 20px;
  font-weight: 500;
  color: var(--im-text-secondary, #86909c);
}

.im-text :deep(a) {
  color: var(--im-message-outgoing, #2f6bff);
  text-decoration: none;
}

.im-text :deep(a:hover) {
  text-decoration: underline;
}

.im-text :deep(pre) {
  background: var(--im-bg-surface-alt, var(--flare-color-bg-tertiary, #f2f3f5));
  border-radius: 8px;
  padding: 10px;
  overflow-x: auto;
}
</style>
