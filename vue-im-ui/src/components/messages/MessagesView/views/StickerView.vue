<script setup lang="ts">
import { computed, ref, watch } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { resolveStickerUrlByPackageAndId } from "../../../composer/ComposerEmojiStickerPopover/composerStickers";
import FrozenStickerThumb from "../../../composer/FrozenStickerThumb/index.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean; playAnimated?: boolean }>();

const stickerUrl = computed(() => {
  const nested = pickNestedPayload(props.content, "sticker");
  const direct = readString(nested, "url") || readString(props.content, "url");
  if (direct) return direct;
  return "";
});

const stickerAsset = computed(() => {
  const nested = pickNestedPayload(props.content, "sticker");
  const packageId = readString(nested, "packageId") || "gifs";
  const stickerId = readString(nested, "stickerId", "id");
  return { packageId, stickerId };
});

const resolvedStickerUrl = ref("");
let gen = 0;

const fallbackText = computed(() => {
  const { packageId, stickerId } = stickerAsset.value;
  if (stickerId) return `[Sticker:${packageId}/${stickerId}]`;
  return "[Sticker]";
});

watch(
  stickerAsset,
  async (asset) => {
    const my = ++gen;
    if (stickerUrl.value || !asset.stickerId) {
      resolvedStickerUrl.value = "";
      return;
    }
    const url = await resolveStickerUrlByPackageAndId(asset.packageId, asset.stickerId);
    if (my !== gen) return;
    resolvedStickerUrl.value = url ?? "";
  },
  { immediate: true },
);
</script>

<template>
  <div class="im-sticker">
    <img
      v-if="(stickerUrl || resolvedStickerUrl) && playAnimated"
      :src="stickerUrl || resolvedStickerUrl"
      alt="Sticker"
      class="im-sticker__img"
      loading="lazy"
      decoding="async"
    />
    <FrozenStickerThumb
      v-else-if="stickerUrl || resolvedStickerUrl"
      class="im-sticker__img"
      :src="stickerUrl || resolvedStickerUrl"
      alt="Sticker"
      object-fit="contain"
    />
    <span v-else class="im-sticker__fallback">{{ fallbackText }}</span>
  </div>
</template>

<style scoped>
.im-sticker {
  display: flex;
  justify-content: center;
}

.im-sticker__img {
  width: min(8em, 180px);
  height: min(8em, 180px);
  max-width: min(8em, 180px);
  max-height: min(8em, 180px);
}

.im-sticker__fallback {
  display: inline-flex;
  max-width: min(220px, 100%);
  min-width: 0;
  color: var(--im-text-secondary);
  font-size: 15px;
  line-height: 1.35;
  overflow-wrap: anywhere;
  text-align: center;
}
</style>
