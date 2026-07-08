<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { ImageOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readString } from "../../../../utils/contentData";
import { imageInfoIsMotion } from "../../../../utils/motionImage";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";
import ImagePreviewModal from "../../../message-preview/ImagePreviewModal.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean; messageId?: string; playAnimated?: boolean }>();

const previewOpen = ref(false);
const imageLoadFailed = ref(false);
const imageRetryKey = ref(0);

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "image");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const source = computed(() => asRecord(payload.value.source));
const thumbnail = computed(() => asRecord(payload.value.thumbnail));
const sourceId = computed(() =>
  readString(source.value, "imageId", "fileId", "id", "uuid") ||
  readString(payload.value, "imageId", "fileId", "id", "uuid"),
);
const thumbnailId = computed(() =>
  readString(thumbnail.value, "imageId", "fileId", "id", "uuid") ||
  readString(payload.value, "thumbnailId", "thumbnailFileId", "thumbnailUuid"),
);
const sourceDirectUrl = computed(() =>
  readString(source.value, "url", "localPreviewUrl", "downloadUrl") ||
  readString(payload.value, "url", "localPreviewUrl", "downloadUrl"),
);
const thumbnailDirectUrl = computed(() =>
  readString(thumbnail.value, "url", "localPreviewUrl", "downloadUrl") ||
  readString(payload.value, "thumbnailUrl", "localPreviewUrl", "snapshotUrl"),
);
const sourceRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "image",
    messageId: props.messageId,
    url: sourceDirectUrl.value,
    id: sourceId.value,
    localPath: readMediaLocalPath(source.value, payload.value),
    mimeType: readString(source.value, "mimeType") || readString(payload.value, "mimeType"),
    fileName: readString(payload.value, "fileName", "title"),
  }),
);
const thumbnailRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "imageThumbnail",
    messageId: props.messageId,
    url: thumbnailDirectUrl.value || sourceDirectUrl.value,
    id: thumbnailId.value || sourceId.value,
    localPath: readMediaLocalPath(thumbnail.value, payload.value) || readMediaLocalPath(source.value, payload.value),
    mimeType: readString(thumbnail.value, "mimeType") || readString(source.value, "mimeType"),
    fileName: readString(payload.value, "fileName", "title"),
  }),
);
const resolvedThumb = useResolvedMediaUrl(thumbnailRequest);
const resolvedFull = useResolvedMediaUrl(sourceRequest);
const thumbUrl = computed(() => resolvedThumb.url.value || resolvedFull.url.value);
const fullUrl = computed(() => resolvedFull.url.value || resolvedThumb.url.value);

const description = computed(() => readString(payload.value, "description", "caption", "title"));

const isMotion = computed(() => imageInfoIsMotion(payload.value as { animated?: boolean; format?: number; mimeType?: string }));

watch(thumbUrl, () => {
  imageLoadFailed.value = false;
  imageRetryKey.value = 0;
});

function retryImage(): void {
  if (!thumbUrl.value) return;
  imageLoadFailed.value = false;
  imageRetryKey.value += 1;
}
</script>

<template>
  <div v-if="payload" class="im-image">
    <div class="im-image__media">
      <button v-if="thumbUrl && !imageLoadFailed" type="button" class="im-image__button" @click="previewOpen = true">
        <img
          :key="`${thumbUrl}:${imageRetryKey}`"
          :src="thumbUrl"
          :alt="description || '图片'"
          class="im-image__thumb"
          loading="lazy"
          decoding="async"
          @error="imageLoadFailed = true"
        />
        <span v-if="isMotion && !playAnimated" class="im-image__badge">GIF</span>
      </button>
      <button
        v-else
        type="button"
        class="im-image__placeholder"
        :class="{ 'im-image__placeholder--retry': Boolean(thumbUrl) }"
        :disabled="!thumbUrl"
        @click="retryImage"
      >
        <n-icon :component="ImageOutline" />
        <span>{{ resolvedThumb.loading.value || resolvedFull.loading.value ? "图片加载中" : thumbUrl ? "图片加载失败" : "查看图片" }}</span>
        <small v-if="resolvedThumb.error.value || resolvedFull.error.value">{{ resolvedThumb.error.value || resolvedFull.error.value }}</small>
        <small v-else-if="thumbUrl">点击重试</small>
      </button>
    </div>
    <p v-if="description" class="im-media-caption im-image__desc">{{ description }}</p>
    <ImagePreviewModal v-model:show="previewOpen" :image-src="fullUrl" :alt="description || '原图'" />
  </div>
</template>

<style scoped>
.im-image {
  position: relative;
  display: inline-flex;
  flex-direction: column;
  gap: 7px;
  width: var(--im-media-image-max-width);
  min-width: min(var(--im-media-card-min-width), 72vw);
  max-width: 72vw;
}

.im-image__media {
  position: relative;
  overflow: hidden;
  width: 100%;
  min-height: 132px;
  border-radius: 14px;
  background: color-mix(in srgb, var(--im-bg-surface-alt, #f2f3f5) 92%, #ffffff 8%);
  box-shadow:
    0 10px 22px rgb(15 23 42 / 10%),
    0 1px 0 rgb(15 23 42 / 5%);
}

.im-image__media::after {
  position: absolute;
  inset: 0;
  border: 1px solid rgb(15 23 42 / 6%);
  border-radius: inherit;
  pointer-events: none;
  content: "";
}

.im-image__button {
  position: relative;
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  min-height: 132px;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: zoom-in;
}

.im-image__thumb {
  display: block;
  width: auto;
  min-width: min(220px, 100%);
  max-width: 100%;
  height: auto;
  min-height: 132px;
  max-height: min(300px, 42vh);
  object-fit: contain;
}

.im-image__badge {
  position: absolute;
  right: 8px;
  bottom: 8px;
  padding: 2px 6px;
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.55);
  color: #fff;
  font-size: 11px;
}

.im-image__placeholder {
  display: grid;
  place-items: center;
  gap: 6px;
  width: 100%;
  min-height: 132px;
  padding: 12px;
  border: 0;
  border-radius: inherit;
  background: transparent;
  color: var(--im-text-secondary);
  font-size: 12px;
  cursor: default;
}

.im-image__placeholder--retry {
  cursor: pointer;
}

.im-image__placeholder small {
  color: var(--im-text-tertiary, #9ca3af);
  font-size: 11px;
}

.im-image__desc {
  width: 100%;
  margin: 0;
  font-size: 12px;
  color: var(--im-text-primary);
  line-height: 1.45;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

@media (max-width: 599px) {
  .im-image {
    max-width: 76vw;
  }
}
</style>
