<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { readString } from "../../../../utils/contentData";
import { imageGroupItemFileName, imageGroupItemRequest, imageGroupItemThumbnailRequest } from "../../../../utils/imageRequests";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import MsgIcon from "../../standalone/MsgIcon.vue";

/** What a tile learnt about its image: the full-size address the preview opens, and a file name to save it as. */
export interface ImageGroupCellResolution {
  index: number;
  fullUrl: string;
  fileName: string;
  alt: string;
}

// One album tile's picture: resolves the core's image ids through the host's media resolver and draws the
// thumbnail, or a placeholder while it resolves or after it fails. The tile's button, label and `+N` cover
// belong to FlareImageGroupMessage, which draws this in its `image` slot.
const props = defineProps<{
  image: Record<string, unknown>;
  index: number;
  messageId?: string;
}>();
const emit = defineEmits<{ (event: "resolved", value: ImageGroupCellResolution): void }>();
const { t } = useFlareI18n();

const failed = ref(false);
const fileName = computed(() => imageGroupItemFileName(props.image, props.index));
const fullRequest = computed(() => imageGroupItemRequest(props.image, props.index, props.messageId));
const thumbnailRequest = computed(() => imageGroupItemThumbnailRequest(props.image, props.index, props.messageId));
const resolvedThumbnail = useResolvedMediaUrl(thumbnailRequest);
const resolvedFull = useResolvedMediaUrl(fullRequest);
const url = computed(() => resolvedThumbnail.url.value || resolvedFull.url.value);
const alt = computed(() => readString(props.image, "description", "title"));

watch(url, () => { failed.value = false; });
watch(
  () => resolvedFull.url.value || resolvedThumbnail.url.value,
  (fullUrl) => emit("resolved", { index: props.index, fullUrl, fileName: fileName.value, alt: alt.value }),
  { immediate: true },
);
</script>

<template>
  <img v-if="url && !failed" :src="url" :alt="alt" loading="lazy" decoding="async" @error="failed = true" />
  <span v-else class="im-image-group-cell__placeholder">
    <MsgIcon name="image" :size="22" />
    <small v-if="resolvedThumbnail.loading.value || resolvedFull.loading.value">{{ t('media.loading') }}</small>
  </span>
</template>

<style scoped>
.im-image-group-cell__placeholder {
  display: grid;
  place-items: center;
  align-content: center;
  gap: var(--flare-size-spacing-xs);
  width: 100%;
  height: 100%;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-xs);
}
</style>
