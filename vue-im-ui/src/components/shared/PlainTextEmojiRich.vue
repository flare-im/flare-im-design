<script setup lang="ts">
import { computed } from "vue";
import { splitPlainTextForEmojiDisplay } from "../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { formatEmojiPackBracket } from "../../utils/emojiPackI18n";
import { isMarkdown } from "../../utils/markdown";
import FrozenStickerThumb from "../composer/FrozenStickerThumb/index.vue";

const props = withDefaults(
  defineProps<{
    text: string;
    inlineEmSize?: number;
  }>(),
  { inlineEmSize: 1.72 },
);

const asMarkdownFallback = computed(() => {
  const value = props.text ?? "";
  return value.length > 0 && isMarkdown(value);
});

const segments = computed(() => {
  if (asMarkdownFallback.value) return null;
  const value = props.text ?? "";
  if (!value) return null;
  const parts = splitPlainTextForEmojiDisplay(value);
  if (!parts.some((part) => part.kind === "emoji" || part.kind === "emojiUnknown")) return null;
  return parts;
});
</script>

<template>
  <span v-if="asMarkdownFallback" class="pte-fallback">{{ text }}</span>
  <span v-else-if="segments" class="pte-rich">
    <template v-for="(segment, index) in segments" :key="`${segment.kind}-${index}`">
      <span v-if="segment.kind === 'text'" class="pte-run">{{ segment.text }}</span>
      <FrozenStickerThumb
        v-else-if="segment.kind === 'emoji'"
        class="pte-emoji-img"
        :load-src="segment.loadUrl"
        :alt="formatEmojiPackBracket(segment.key)"
        :em-size="inlineEmSize"
        object-fit="contain"
      />
      <span v-else class="pte-emoji-fallback" role="img" :aria-label="segment.key">{{
        formatEmojiPackBracket(segment.key)
      }}</span>
    </template>
  </span>
  <span v-else class="pte-plain">{{ text }}</span>
</template>

<style scoped>
.pte-fallback,
.pte-plain {
  white-space: pre-wrap;
  word-break: break-word;
}

.pte-rich {
  display: inline;
  vertical-align: baseline;
  line-height: var(--line-height, 1.4);
}

.pte-run {
  white-space: pre-wrap;
  word-break: break-word;
}

.pte-emoji-img {
  display: inline-block;
  vertical-align: middle;
  margin: 0 0.05em;
}

.pte-emoji-fallback {
  display: inline;
  vertical-align: middle;
  margin: 0 0.04em;
  color: var(--im-text-secondary, #86909c);
  font-weight: 500;
}
</style>
