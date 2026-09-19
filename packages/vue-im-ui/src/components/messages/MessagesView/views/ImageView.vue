<script setup lang="ts">
import { computed, ref, watchEffect } from "vue";
import { DownloadOutline } from "../../../../shared/icon-glyphs";
import type { ContentElem } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { imageInfoIsMotion } from "../../../../utils/motionImage";
import { imageMessagePayload, imageSourceRequest, imageThumbnailRequest } from "../../../../utils/imageRequests";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import ImagePreviewModal from "../../../message-preview/ImagePreviewModal.vue";
import FlareImageMessage from "../../standalone/FlareImageMessage.vue";
import type { MessageMediaDownloadUiState } from "../../MessageBubble.vue";
import { injectTimelineImageGallery } from "../../timelineImageGallery";

// Timeline adapter: image payload → thumbnail / full-size resolution → the
// contract body (flexible mode). The body owns load-failure + retry; the
// caption stays here, and so does the preview of a body outside a message list.
// In a list the image opens the list's gallery, which this body tells what it
// resolved and how the image is saved.
const props = defineProps<{
  content: ContentElem;
  isSelf: boolean;
  messageId?: string;
  playAnimated?: boolean;
  /** The download the host offers for this image; the preview shows a download button only then. */
  mediaAction?: "download" | "openFolder" | null;
  mediaState?: MessageMediaDownloadUiState | null;
}>();
const emit = defineEmits<{ (event: "media-action", action: "download" | "openFolder"): void }>();
const { t } = useFlareI18n();
const canDownload = computed(() => props.mediaAction === "download");

const previewOpen = ref(false);

const payload = computed(() => imageMessagePayload(props.content));
const sourceRequest = computed(() => imageSourceRequest(payload.value, props.messageId));
const thumbnailRequest = computed(() => imageThumbnailRequest(payload.value, props.messageId));
const resolvedThumb = useResolvedMediaUrl(thumbnailRequest);
const resolvedFull = useResolvedMediaUrl(sourceRequest);
const thumbUrl = computed(() => resolvedThumb.url.value || resolvedFull.url.value);
const fullUrl = computed(() => resolvedFull.url.value || resolvedThumb.url.value);
const resolving = computed(() => !thumbUrl.value && (resolvedThumb.loading.value || resolvedFull.loading.value));

const description = computed(() => readString(payload.value, "description", "caption", "title"));
const isMotion = computed(() => imageInfoIsMotion(payload.value as { animated?: boolean; format?: number; mimeType?: string }));
const badge = computed(() => (isMotion.value && !props.playAnimated ? "GIF" : ""));

const gallery = injectTimelineImageGallery();
watchEffect((onCleanup) => {
  const messageId = props.messageId;
  if (!gallery || !messageId) return;
  gallery.report(messageId, 0, {
    fullUrl: fullUrl.value,
    alt: description.value,
    download: canDownload.value ? () => emit("media-action", "download") : null,
    downloading: props.mediaState === "downloading",
  });
  onCleanup(() => gallery.report(messageId, 0, undefined));
});

function openPreview(): void {
  if (props.messageId && gallery?.open(props.messageId, 0)) return;
  if (!fullUrl.value) return;
  previewOpen.value = true;
}
</script>

<template>
  <div class="im-image">
    <FlareImageMessage
      :src="thumbUrl"
      :alt="description"
      :badge="badge"
      :loading="resolving"
      max-width="var(--flare-component-media-image-max-width)"
      max-height="min(300px, 42vh)"
      @click="openPreview"
    />
    <p v-if="description" class="im-media-caption">{{ description }}</p>
    <ImagePreviewModal
      v-model:show="previewOpen"
      :image-src="fullUrl"
      :alt="description || t('mediaMessage.image')"
      :primary-action-icon="canDownload ? DownloadOutline : undefined"
      :primary-action-title="canDownload ? t('media.downloadImage') : ''"
      :primary-action-disabled="mediaState === 'downloading'"
      :downloading="mediaState === 'downloading'"
      @primary-action="emit('media-action', 'download')"
    />
  </div>
</template>

<style scoped>
/* `100%` as well as the viewport share: a media body must never be wider than the bubble it sits
   in. Without it a bubble narrower than 72vw — any bubble outside a timeline, or any narrow pane —
   has its picture hang out over the page edge (FR-157). */
.im-image {
  position: relative;
  display: inline-flex;
  flex-direction: column;
  gap: 7px;
  max-width: min(72vw, 100%);
}

@container flare-timeline (max-width: 599px) {
  .im-image {
    max-width: min(76vw, 100%);
  }
}
</style>
