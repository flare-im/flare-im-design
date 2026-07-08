<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NButton, NInput, NModal } from "naive-ui";
import type { EnhancedMessageKind, MediaComposerPreviewItem } from "../types";

const props = defineProps<{
  show: boolean;
  kind: EnhancedMessageKind;
  items: readonly MediaComposerPreviewItem[];
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
  if (props.kind === "file") return "添加文件说明";
  if (props.kind === "video") return "添加视频描述";
  if (props.kind === "imageGroup") return "添加这组图片的描述";
  return "添加描述";
});

watch(
  () => props.show,
  (open) => {
    if (open) description.value = "";
  },
);

function close(): void {
  emit("update:show", false);
  emit("cancel");
}

function handleModalUpdate(open: boolean): void {
  if (open) {
    emit("update:show", true);
    return;
  }
  close();
}

function submit(): void {
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
    :bordered="false"
    :closable="false"
    @update:show="handleModalUpdate"
  >
    <div class="media-composer-preview__body">
      <article
        v-if="isSingle && primaryItem"
        class="media-composer-preview__hero"
        :class="{ 'media-composer-preview__hero--file': !primaryItem.previewUrl }"
      >
        <img
          v-if="(primaryItem.kind === 'image' || primaryItem.kind === 'imageGroup') && primaryItem.previewUrl"
          :src="primaryItem.previewUrl"
          :alt="primaryItem.name"
        />
        <video
          v-else-if="primaryItem.kind === 'video' && primaryItem.previewUrl"
          :src="primaryItem.previewUrl"
          controls
          playsinline
        />
        <div v-else class="media-composer-preview__file">
          <strong>{{ primaryItem.name }}</strong>
          <span v-if="primaryItem.mimeType">{{ primaryItem.mimeType }}</span>
          <span v-if="primaryItem.size">{{ formatBytes(primaryItem.size) }}</span>
        </div>
        <div class="media-composer-preview__hero-caption">
          <span>{{ primaryItem.name }}</span>
          <small v-if="primaryItem.size">{{ formatBytes(primaryItem.size) }}</small>
        </div>
      </article>

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
          描述
          <small>随媒体一起发送，可留空</small>
        </span>
        <NInput
          v-model:value="description"
          type="textarea"
          :autosize="{ minRows: 1, maxRows: 5 }"
          :placeholder="descriptionPlaceholder"
          :disabled="loading"
        />
      </label>
    </div>

    <template #footer>
      <div class="media-composer-preview__footer">
        <NButton secondary :disabled="loading" @click="close">取消</NButton>
        <NButton type="primary" :loading="loading" :disabled="!items.length" @click="submit">
          发送
        </NButton>
      </div>
    </template>
  </n-modal>
</template>

<style scoped>
:global(.media-composer-preview.n-card) {
  width: min(980px, calc(100vw - 56px));
  max-height: calc(100vh - 64px);
  overflow: hidden;
  border-radius: 18px;
  box-shadow:
    0 24px 80px rgba(15, 23, 42, 0.22),
    0 0 0 1px rgba(148, 163, 184, 0.16);
}

:global(.media-composer-preview.n-card > .n-card-header) {
  display: none;
}

:global(.media-composer-preview.n-card > .n-card__content) {
  padding-top: 20px;
}

.media-composer-preview {
  width: min(980px, calc(100vw - 56px));
  max-height: calc(100vh - 64px);
}

.media-composer-preview__body {
  display: grid;
  gap: 16px;
}

.media-composer-preview__hero,
.media-composer-preview__gallery {
  border: 1px solid rgba(148, 163, 184, 0.2);
  background:
    radial-gradient(circle at 20% 0%, rgba(124, 58, 237, 0.16), transparent 34%),
    linear-gradient(135deg, rgba(15, 23, 42, 0.9), rgba(31, 41, 55, 0.78));
}

.media-composer-preview__hero {
  position: relative;
  display: grid;
  place-items: center;
  min-height: min(56vh, 520px);
  overflow: hidden;
  border-radius: 16px;
}

.media-composer-preview__hero--file {
  min-height: 220px;
}

.media-composer-preview__hero img,
.media-composer-preview__hero video {
  display: block;
  width: 100%;
  max-height: min(56vh, 520px);
  object-fit: contain;
}

.media-composer-preview__hero-caption {
  position: absolute;
  right: 14px;
  bottom: 14px;
  left: 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 38px;
  padding: 9px 12px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  color: #e5e7eb;
  background: linear-gradient(90deg, rgba(15, 23, 42, 0.72), rgba(15, 23, 42, 0.4));
  box-shadow: 0 12px 30px rgba(15, 23, 42, 0.18);
  backdrop-filter: blur(16px);
}

.media-composer-preview__hero-caption span,
.media-composer-preview__hero-caption small {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.media-composer-preview__hero-caption small {
  flex: 0 0 auto;
  color: rgba(229, 231, 235, 0.78);
}

.media-composer-preview__gallery {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(156px, 1fr));
  gap: 14px;
  max-height: min(56vh, 540px);
  padding: 14px;
  overflow: auto;
  border-radius: 16px;
}

.media-composer-preview__thumb {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 142px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 13px;
  background: rgba(15, 23, 42, 0.46);
  box-shadow: 0 10px 24px rgba(15, 23, 42, 0.12);
}

.media-composer-preview__thumb img,
.media-composer-preview__thumb video {
  display: block;
  width: 100%;
  height: 100%;
  min-height: 142px;
  object-fit: cover;
  background: transparent;
}

.media-composer-preview__file {
  display: grid;
  align-content: center;
  gap: 8px;
  min-height: 148px;
  padding: 20px;
  color: #e5e7eb;
  text-align: center;
}

.media-composer-preview__file strong {
  word-break: break-word;
}

.media-composer-preview__file span,
.media-composer-preview__name,
.media-composer-preview__caption span,
.media-composer-preview__caption small {
  color: var(--flare-text-secondary, #8f97a7);
}

.media-composer-preview__index {
  position: absolute;
  top: 8px;
  left: 8px;
  display: inline-grid;
  place-items: center;
  width: 22px;
  height: 22px;
  border-radius: 999px;
  color: #ffffff;
  background: rgba(124, 58, 237, 0.9);
  box-shadow: 0 8px 18px rgba(124, 58, 237, 0.2);
  font-size: 12px;
  font-weight: 800;
}

.media-composer-preview__name {
  position: absolute;
  right: auto;
  bottom: 8px;
  left: 8px;
  max-width: calc(100% - 16px);
  overflow: hidden;
  border-radius: 9px;
  padding: 6px 9px;
  background: rgba(2, 6, 23, 0.64);
  text-overflow: ellipsis;
  white-space: nowrap;
  backdrop-filter: blur(12px);
}

.media-composer-preview__caption {
  display: grid;
  gap: 8px;
}

.media-composer-preview__caption > span {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
}

.media-composer-preview__caption > span > small {
  font-size: 12px;
  font-weight: 500;
}

.media-composer-preview__caption :deep(.n-input) {
  border-radius: 12px;
}

.media-composer-preview__caption :deep(.n-input__textarea-el),
.media-composer-preview__caption :deep(.n-input__textarea-mirror) {
  line-height: 22px;
}

.media-composer-preview__footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

@media (max-width: 720px) {
  :global(.media-composer-preview.n-card),
  .media-composer-preview {
    width: calc(100vw - 24px);
  }

  .media-composer-preview__gallery {
    grid-template-columns: repeat(auto-fill, minmax(128px, 1fr));
  }
}
</style>
