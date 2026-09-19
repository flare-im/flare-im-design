<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { resolveStickerUrlByPackageAndId } from "../../../composer/ComposerEmojiStickerPopover/composerStickers";
import FlareStickerMessage from "../../standalone/FlareStickerMessage.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";

// Timeline adapter: sticker url / (packageId, stickerId) → the contract body.
const props = defineProps<{ content: ContentElem; isSelf: boolean; playAnimated?: boolean }>();
const { t } = useFlareI18nOptional();

const stickerUrl = computed(() => {
  const nested = pickNestedPayload(props.content, "sticker");
  return readString(nested, "url") || readString(props.content, "url") || "";
});

const stickerAsset = computed(() => {
  const nested = pickNestedPayload(props.content, "sticker");
  return { packageId: readString(nested, "packageId") || "gifs", stickerId: readString(nested, "stickerId", "id") };
});

const loadSrc = computed(() => {
  const { packageId, stickerId } = stickerAsset.value;
  if (stickerUrl.value || !stickerId) return undefined;
  return async () => (await resolveStickerUrlByPackageAndId(packageId, stickerId)) ?? undefined;
});

const fallbackText = computed(() => t("preview.sticker"));
</script>

<template>
  <div class="im-sticker">
    <FlareStickerMessage
      :src="stickerUrl"
      :load-src="loadSrc"
      :animated="Boolean(playAnimated)"
      :fallback-text="stickerUrl || loadSrc ? '' : fallbackText"
:alt="t('preview.stickerLabel')"
    />
  </div>
</template>

<style scoped>
.im-sticker { display: flex; justify-content: center; }
</style>
