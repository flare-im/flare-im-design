<script setup lang="ts">
import { computed } from "vue";
import { DownloadOutline } from "../../shared/icon-glyphs";
import { useResolvedMediaUrl } from "../../composables/useMediaResolver";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { downloadUrlWithFileName } from "../../utils/browserDownload";
import { flareImageGalleryAlt, flareImageGalleryRequest } from "../../utils/imageGallery";
import { imageGroupItemFileName } from "../../utils/imageRequests";
import ImagePreviewModal from "../message-preview/ImagePreviewModal.vue";
import type { TimelineImageGallery } from "./timelineImageGallery";

// The full-screen preview of a message list's gallery: one picture at a time, at the address its body resolved —
// or resolved here when its body is not drawn — with the download its body offers. An album's picture is always
// saved by the browser, as its album saves it.
const props = defineProps<{ gallery: TimelineImageGallery }>();
const { t } = useFlareI18n();

const current = computed(() => {
  const at = props.gallery.position.value;
  return at == null ? null : props.gallery.pictures.value[at] ?? null;
});
const entry = computed(() => (current.value ? props.gallery.entry(current.value) : undefined));
const request = computed(() => (current.value && !entry.value?.fullUrl ? flareImageGalleryRequest(current.value) : null));
const resolved = useResolvedMediaUrl(request);
const src = computed(() => entry.value?.fullUrl || resolved.url.value);
const alt = computed(() => entry.value?.alt || (current.value ? flareImageGalleryAlt(current.value) : "") || t("mediaMessage.image"));
const download = computed<(() => void) | null>(() => {
  if (entry.value) return entry.value.download;
  const item = current.value;
  const url = src.value;
  if (item?.kind !== "imageGroupItem" || !url) return null;
  return () => void downloadUrlWithFileName(url, imageGroupItemFileName(item.image, item.index));
});
const show = computed({
  get: () => current.value != null,
  set: (open: boolean) => {
    if (!open) props.gallery.close();
  },
});
</script>

<template>
  <ImagePreviewModal
    v-model:show="show"
    :image-src="src"
    :loading="!src && resolved.loading.value"
    :alt="alt"
    :gallery-index="gallery.position.value ?? undefined"
    :gallery-count="gallery.pictures.value.length"
    :primary-action-icon="download ? DownloadOutline : undefined"
    :primary-action-title="download ? t('media.downloadImage') : ''"
    :primary-action-disabled="Boolean(entry?.downloading)"
    :downloading="Boolean(entry?.downloading)"
    @primary-action="download?.()"
    @previous="gallery.page(-1)"
    @next="gallery.page(1)"
  />
</template>
