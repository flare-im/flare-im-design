<script lang="ts">
export interface FlareComposerMediaPreviewItem {
  id: string;
  kind: string;
  name: string;
  previewUrl?: string;
  mimeType?: string;
  size?: number;
}
</script>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NModal } from "naive-ui";
import FlareButton from "../general/FlareButton.vue";
import FlareTextarea from "../form/FlareTextarea.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareNativeBack } from "../../shared/platform/useFlareNativeBack";
const { t } = useFlareI18n();

const props = defineProps<{
  show: boolean;
  kind: string;
  items: readonly FlareComposerMediaPreviewItem[];
  loading?: boolean;
}>();

const emit = defineEmits<{
  (event: "update:show", value: boolean): void;
  (event: "cancel"): void;
  (event: "submit", description: string): void;
}>();

const description = ref("");

const mediaCount = computed(() => props.items.length);
const isSingle = computed(() => mediaCount.value === 1);
const primaryItem = computed(() => props.items[0]);
const descriptionPlaceholder = computed(() => {
  if (props.kind === "file") return t("composer.fileCaption");
  if (props.kind === "video") return t("composer.videoCaption");
  if (props.kind === "imageGroup") return t("composer.imagesCaption");
  return t("composer.imageCaption");
});

watch(
  () => props.show,
  (open) => {
    if (open) description.value = "";
  },
);

function close(): void {
  if (props.loading) return;
  emit("update:show", false);
  emit("cancel");
}
useFlareNativeBack(() => props.show, close);

function handleModalUpdate(open: boolean): void {
  if (open) {
    emit("update:show", true);
    return;
  }
  close();
}

function submit(): void {
  if (props.loading || !props.items.length) return;
  emit("submit", description.value.trim());
}

function formatBytes(value: number): string {
  if (!Number.isFinite(value) || value <= 0) return "";
  const units = ["B", "KB", "MB", "GB"];
  let next = value;
  let index = 0;
  while (next >= 1024 && index < units.length - 1) {
    next /= 1024;
    index += 1;
  }
  return `${next >= 10 || index === 0 ? Math.round(next) : next.toFixed(1)} ${units[index]}`;
}
</script>

<template>
  <n-modal
    :show="show"
    preset="card"
    class="media-composer-preview"
    :bordered="true"
    :mask-closable="!loading"
    :close-on-esc="!loading"
    :title="t('composer.attachmentPreview')"
    :closable="false"
    @update:show="handleModalUpdate"
  >
    <div class="media-composer-preview__body">
      <!-- 图片/视频:大预览 -->
      <article
        v-if="
          isSingle &&
          primaryItem &&
          primaryItem.previewUrl &&
          (primaryItem.kind === 'image' || primaryItem.kind === 'imageGroup' || primaryItem.kind === 'video')
        "
        class="media-composer-preview__hero"
      >
        <img
          v-if="primaryItem.kind === 'image' || primaryItem.kind === 'imageGroup'"
          :src="primaryItem.previewUrl"
          :alt="primaryItem.name"
        />
        <video v-else :src="primaryItem.previewUrl" controls playsinline />
        <div class="media-composer-preview__hero-caption">
          <span>{{ primaryItem.name }}</span>
          <small v-if="primaryItem.size">{{ formatBytes(primaryItem.size) }}</small>
        </div>
      </article>

      <!-- 文件:不做大预览,只显示文件名(+大小) -->
      <div v-else-if="isSingle && primaryItem" class="media-composer-preview__filerow">
        <span class="media-composer-preview__filerow-name">{{ primaryItem.name }}</span>
        <small v-if="primaryItem.size">{{ formatBytes(primaryItem.size) }}</small>
      </div>

      <div v-else class="media-composer-preview__gallery">
        <article
          v-for="(item, index) in items"
          :key="item.id"
          class="media-composer-preview__thumb"
        >
          <img
            v-if="(item.kind === 'image' || item.kind === 'imageGroup') && item.previewUrl"
            :src="item.previewUrl"
            :alt="item.name"
          />
          <video
            v-else-if="item.kind === 'video' && item.previewUrl"
            :src="item.previewUrl"
            controls
            playsinline
          />
          <div v-else class="media-composer-preview__file">
            <strong>{{ item.name }}</strong>
            <span v-if="item.mimeType">{{ item.mimeType }}</span>
            <span v-if="item.size">{{ formatBytes(item.size) }}</span>
          </div>
          <span class="media-composer-preview__index">{{ index + 1 }}</span>
          <span class="media-composer-preview__name">{{ item.name }}</span>
        </article>
      </div>

      <label class="media-composer-preview__caption">
        <span>
          {{ t("composer.caption") }}
          <small>{{ t("composer.captionOptional") }}</small>
        </span>
        <FlareTextarea
          v-model="description"
          :rows="1"
          :max-rows="5"
          :placeholder="descriptionPlaceholder"
          :disabled="loading"
        />
      </label>
    </div>

    <template #footer>
      <div class="media-composer-preview__footer">
        <FlareButton variant="secondary" :disabled="loading" @click="close">{{ t("common.cancel") }}</FlareButton>
        <FlareButton :loading="loading" :disabled="!items.length" @click="submit">
          {{ t("composer.send") }}
        </FlareButton>
      </div>
    </template>
  </n-modal>
</template>

<style scoped>
.media-composer-preview {
  width: min(720px, calc(100vw - 32px));
  max-height: calc(100dvh - 32px);
  border-radius: var(--flare-size-radius-lg);
}
.media-composer-preview__body {
  display: grid;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  max-height: calc(100dvh - 208px);
  padding: 3px;
  overflow: auto;
  overscroll-behavior: contain;
}
.media-composer-preview__hero {
  margin: 0;
  min-width: 0;
}
.media-composer-preview__hero img,
.media-composer-preview__hero video {
  display: block;
  width: 100%;
  max-height: min(48dvh, 460px);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  object-fit: contain;
}
.media-composer-preview__hero-caption,
.media-composer-preview__filerow {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-width: 0;
  gap: var(--flare-size-spacing-sm);
  padding-block: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-secondary);
}
.media-composer-preview__hero-caption span,
.media-composer-preview__filerow-name {
  min-width: 0;
  overflow-wrap: anywhere;
}
.media-composer-preview__hero-caption small,
.media-composer-preview__filerow small {
  flex-shrink: 0;
}
.media-composer-preview__gallery {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(148px, 100%), 1fr));
  gap: var(--flare-size-spacing-sm);
}
.media-composer-preview__thumb {
  position: relative;
  display: grid;
  grid-template-rows: 140px auto;
  min-width: 0;
  margin: 0;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  overflow: hidden;
}
.media-composer-preview__thumb img,
.media-composer-preview__thumb video {
  width: 100%;
  height: 140px;
  object-fit: contain;
}
.media-composer-preview__file {
  display: grid;
  align-content: center;
  gap: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-md);
  min-width: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  overflow-wrap: anywhere;
}
.media-composer-preview__index {
  position: absolute;
  top: 6px;
  left: 6px;
  display: grid;
  place-items: center;
  min-width: 24px;
  height: 24px;
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
  font-size: var(--flare-size-font-size-sm);
}
.media-composer-preview__name {
  min-width: 0;
  padding: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.media-composer-preview__caption {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  color: var(--flare-color-text-secondary);
}
.media-composer-preview__caption > span {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--flare-size-spacing-xs);
}
.media-composer-preview__caption small {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
.media-composer-preview__footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-sm);
}
/* The host decides where this mounts, so there is no container it is guaranteed to sit inside,
   and a named container query that matches nothing applies nothing. It is sized against the
   window on purpose (100vw / 100dvh below), so the window is what it asks. */
@media (max-width: 639px) {
  .media-composer-preview {
    width: calc(100vw - 16px);
    max-height: calc(100dvh - env(safe-area-inset-top) - env(safe-area-inset-bottom) - 16px);
  }
}
</style>
