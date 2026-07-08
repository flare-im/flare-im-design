<script setup lang="ts">
import { computed } from "vue";
import { normalizeEmojiPackKey } from "../../../../utils/messageContent";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { resolveEmojiPackAssetUrlByKey } from "../../../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { formatEmojiPackBracket, isKnownEmojiPackKey } from "../../../../utils/emojiPackI18n";
import FrozenStickerThumb from "../../../composer/FrozenStickerThumb/index.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean; playAnimated?: boolean }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "emoji");
  const key = normalizeEmojiPackKey(readString(nested, "emoji", "key") || readString(props.content, "emoji", "key"));
  return { key };
});

const emojiLoadSrc = computed(() => {
  const key = payload.value.key;
  if (!key || !isKnownEmojiPackKey(key)) return undefined;
  return () => resolveEmojiPackAssetUrlByKey(key);
});

const fallbackText = computed(() =>
  payload.value.key ? formatEmojiPackBracket(payload.value.key) : "[表情]",
);
</script>

<template>
  <div class="im-emoji">
    <FrozenStickerThumb
      v-if="emojiLoadSrc"
      class="im-emoji__thumb"
      :load-src="emojiLoadSrc"
      :alt="payload.key"
      object-fit="contain"
    />
    <span v-else class="im-emoji__fallback">{{ fallbackText }}</span>
  </div>
</template>

<style scoped>
.im-emoji {
  display: flex;
  justify-content: center;
}

.im-emoji__thumb {
  width: min(5.5em, 120px);
  height: min(5.5em, 120px);
}

.im-emoji__fallback {
  display: inline-flex;
  max-width: 100%;
  min-width: 0;
  overflow-wrap: anywhere;
  font-size: 18px;
  color: var(--im-text-secondary);
  line-height: 1.35;
  text-align: center;
}
</style>
