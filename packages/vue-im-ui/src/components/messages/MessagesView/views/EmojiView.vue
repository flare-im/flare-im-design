<script setup lang="ts">
import { computed } from "vue";
import { normalizeEmojiPackKey } from "../../../../utils/messageContent";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { resolveEmojiPackAssetUrlByKey } from "../../../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { formatEmojiPackBracket, isKnownEmojiPackKey } from "../../../../utils/emojiPackI18n";
import FlareEmojiMessage from "../../standalone/FlareEmojiMessage.vue";

// Timeline adapter: emoji-pack key → asset loader, rendered by the contract body.
const props = defineProps<{ content: ContentElem; isSelf: boolean; playAnimated?: boolean }>();

const key = computed(() => {
  const nested = pickNestedPayload(props.content, "emoji");
  return normalizeEmojiPackKey(readString(nested, "emoji", "key") || readString(props.content, "emoji", "key"));
});

const loadSrc = computed(() => {
  const k = key.value;
  if (!k || !isKnownEmojiPackKey(k)) return undefined;
  return () => resolveEmojiPackAssetUrlByKey(k);
});

const fallbackText = computed(() => (key.value ? formatEmojiPackBracket(key.value) : "[Emoji]"));
</script>

<template>
  <div class="im-emoji">
    <FlareEmojiMessage :load-src="loadSrc" :fallback-text="loadSrc ? '' : fallbackText" :alt="key" />
  </div>
</template>

<style scoped>
.im-emoji { display: flex; justify-content: center; }
</style>
