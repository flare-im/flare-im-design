<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { DownloadOutline, EyeOutline, ImageOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import { asRecord, readString } from "../../../../utils/contentData";
import { downloadUrlWithFileName } from "../../../../utils/browserDownload";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";
import ImagePreviewModal from "../../../message-preview/ImagePreviewModal.vue";

const props = defineProps<{
  image: Record<string, unknown>;
  index: number;
  messageId?: string;
}>();

const failed = ref(false);
const previewOpen = ref(false);
const source = computed(() => asRecord(props.image.source));
const thumbnail = computed(() => asRecord(props.image.thumbnail));
const fileName = computed(() =>
  readString(props.image, "fileName", "title") ||
  readString(source.value, "fileName", "name", "title") ||
  `image-${props.index + 1}`,
);
const fullImageId = computed(() =>
  readString(source.value, "imageId", "fileId", "id", "uuid") ||
  readString(props.image, "imageId", "fileId", "id", "uuid"),
);
const imageId = computed(() =>
  readString(thumbnail.value, "imageId", "fileId", "id", "uuid") ||
  fullImageId.value,
);
const fullDirectUrl = computed(() =>
  readString(source.value, "url", "localPreviewUrl", "downloadUrl") ||
  readString(props.image, "url", "localPreviewUrl", "downloadUrl"),
);
const directUrl = computed(() =>
  readString(thumbnail.value, "url", "localPreviewUrl", "downloadUrl") ||
  readString(props.image, "thumbnailUrl", "snapshotUrl") ||
  fullDirectUrl.value,
);
const fullRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "imageGroupItem",
    messageId: props.messageId,
    url: fullDirectUrl.value,
    id: fullImageId.value,
    localPath: readMediaLocalPath(source.value, props.image),
    mimeType: readString(source.value, "mimeType") || readString(props.image, "mimeType"),
    fileName: fileName.value,
  }),
);
const request = computed(() =>
  buildMediaResolveRequest({
    kind: "imageThumbnail",
    messageId: props.messageId,
    url: directUrl.value,
    id: imageId.value,
    localPath: readMediaLocalPath(thumbnail.value, props.image),
    mimeType: readString(thumbnail.value, "mimeType") || readString(props.image, "mimeType"),
    fileName: fileName.value,
  }),
);
const resolved = useResolvedMediaUrl(request);
const resolvedFull = useResolvedMediaUrl(fullRequest);
const url = computed(() => resolved.url.value);
const fullUrl = computed(() => resolvedFull.url.value || url.value);
const alt = computed(() => readString(props.image, "description", "title") || `Image ${props.index + 1}`);
const canPreview = computed(() => Boolean(fullUrl.value));

async function downloadImage(): Promise<void> {
  if (!fullUrl.value) return;
  await downloadUrlWithFileName(fullUrl.value, fileName.value);
}

watch(url, () => {
  failed.value = false;
});
</script>

<template>
  <div class="im-image-group-cell">
    <button
      v-if="url && !failed"
      type="button"
      class="im-image-group-cell__preview"
      :disabled="!canPreview"
      :aria-label="`Preview ${alt}`"
      @click="previewOpen = true"
    >
      <img
        :src="url"
        :alt="alt"
        loading="lazy"
        decoding="async"
        @error="failed = true"
      />
    </button>
    <span v-else class="im-image-group-cell__placeholder">
      <n-icon :component="ImageOutline" />
      <small v-if="resolved.loading.value">Loading</small>
    </span>
    <div v-if="canPreview" class="im-image-group-cell__actions" aria-label="Image actions">
      <button type="button" class="im-image-group-cell__action" title="Preview" aria-label="Preview image" @click.stop="previewOpen = true">
        <n-icon :component="EyeOutline" />
      </button>
      <button
        type="button"
        class="im-image-group-cell__action"
        title="Download"
        aria-label="Download image"
        @click.stop="downloadImage"
      >
        <n-icon :component="DownloadOutline" />
      </button>
    </div>
    <ImagePreviewModal v-model:show="previewOpen" :image-src="fullUrl" :alt="alt" />
  </div>
</template>

<style scoped>
.im-image-group-cell {
  position: relative;
  width: 100%;
  height: 100%;
}

.im-image-group-cell__preview {
  display: block;
  width: 100%;
  height: 100%;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: zoom-in;
}

.im-image-group-cell__preview:disabled {
  cursor: default;
}

.im-image-group-cell__preview img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.im-image-group-cell__placeholder {
  display: grid;
  place-items: center;
  gap: 4px;
  width: 100%;
  height: 100%;
  min-height: 96px;
  color: var(--im-text-secondary);
  font-size: 11px;
  background:
    linear-gradient(135deg, rgb(255 255 255 / 18%), transparent),
    color-mix(in srgb, var(--im-bg-surface-alt, #f2f3f5) 88%, var(--im-bg-surface, #ffffff));
}

.im-image-group-cell__actions {
  position: absolute;
  top: 6px;
  right: 6px;
  display: flex;
  gap: 4px;
  opacity: 0;
  transform: translateY(-2px);
  transition:
    opacity var(--im-motion-fast, 140ms ease),
    transform var(--im-motion-fast, 140ms ease);
}

.im-image-group-cell:hover .im-image-group-cell__actions,
.im-image-group-cell:focus-within .im-image-group-cell__actions {
  opacity: 1;
  transform: translateY(0);
}

.im-image-group-cell__action {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border: 0;
  border-radius: 9px;
  color: #fff;
  background: rgb(17 24 39 / 72%);
  box-shadow: 0 6px 14px rgb(15 23 42 / 20%);
  cursor: pointer;
  text-decoration: none;
  backdrop-filter: blur(10px);
}

.im-image-group-cell__action:hover,
.im-image-group-cell__action:focus-visible {
  background: color-mix(in srgb, var(--im-brand-primary, #7c3aed) 76%, #111827);
}

.im-image-group-cell__action .n-icon {
  font-size: 16px;
}
</style>
