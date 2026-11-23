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
// 发送前的附件确认 —— 走组件库自己的模态面(`presentation="auto"`):手机上是底部
// 面板,指针设备上是居中弹窗。以前这里是一张写死的 naive 模态卡片,于是手机上也弹出
// 一张桌面卡片;而且它不在共用的模态栈里,滚动锁和 Escape 的层序都各算各的。
import { computed, getCurrentInstance, ref, watch } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareMediaUpload from "../media/FlareMediaUpload.vue";
import ImagePreviewModal from "../message-preview/ImagePreviewModal.vue";
import FlareTextarea from "../form/FlareTextarea.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const { t } = useFlareI18n();

const props = withDefaults(defineProps<{
  show: boolean;
  kind: string;
  items: readonly FlareComposerMediaPreviewItem[];
  loading?: boolean;
  /** Seed the field when reopening a selection after a failed send. */
  initialDescription?: string;
  showDescription?: boolean;
  notice?: string;
  error?: string;
}>(), { initialDescription: "", showDescription: true });

const emit = defineEmits<{
  (event: "update:show", value: boolean): void;
  (event: "cancel"): void;
  (event: "remove", id: string): void;
  (event: "submit", description: string): void;
}>();

const instance = getCurrentInstance();
const canRemove = computed(() => !!instance?.vnode.props?.onRemove);
const uploadItems = computed(() => props.items.map(item => ({ ...item, state: "selected" as const, statusText: t("pluginFileSelected") })));
const description = ref(props.initialDescription);
const previewId = ref<string | null>(null);
const isImage = (item: FlareComposerMediaPreviewItem) => item.kind === "image" || item.kind === "imageGroup";
const previewImages = computed(() => props.items.filter(item => isImage(item) && item.previewUrl));
const previewIndex = computed(() => previewImages.value.findIndex(item => item.id === previewId.value));
const previewItem = computed(() => previewImages.value[previewIndex.value]);
watch([() => props.show, previewItem], () => { if (!props.show || !previewItem.value) previewId.value = null; });
function movePreview(offset: number) {
  const item = previewImages.value[previewIndex.value + offset];
  if (item) previewId.value = item.id;
}

const primaryItem = computed(() => props.items.length === 1 ? props.items[0] : undefined);
const title = computed(() => {
  if (props.kind === "image" || props.kind === "imageGroup") return t("composer.imageAttachmentPreview");
  if (props.kind === "video") return t("composer.videoAttachmentPreview");
  return t("composer.attachmentPreview");
});
const descriptionPlaceholder = computed(() => {
  if (props.kind === "file") return t("composer.fileCaption");
  if (props.kind === "video") return t("composer.videoCaption");
  if (props.kind === "imageGroup") return t("composer.imagesCaption");
  return t("composer.imageCaption");
});

watch(
  () => props.show,
  (open) => {
    if (open) description.value = props.initialDescription;
  },
);

// 发送中不放行:scrim、Escape、平台返回键都从 FlareBottomSheet 的 dismissible 走同一条路。
function close(): void {
  if (props.loading) return;
  emit("update:show", false);
  emit("cancel");
}

function submit(): void {
  if (props.loading || !props.items.length) return;
  emit("submit", props.showDescription ? description.value.trim() : "");
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
  <FlareBottomSheet
    :open="show"
    :title="title"
    :dismissible="!loading"
    max-height="calc(100dvh - 32px)"
    @close="close"
  >
    <div class="media-composer-preview" :aria-busy="loading || undefined">
      <div class="media-composer-preview__body">
        <FlareStatusBanner v-if="notice" :text="notice" />
        <FlareMediaUpload v-if="kind === 'imageGroup'" :items="uploadItems" layout="images" :show-picker="false"
          :title="title" :pick-label="t('pluginFileChoose')" :status-text="t('pluginFileSelected')"
          :disabled="loading" :remove-label="canRemove ? t('pluginFileRemove') : undefined" :preview-label="t('pluginFilePreview')"
          @remove="emit('remove', $event)" @preview="previewId = $event" />
        <article
          v-else-if="primaryItem"
          class="media-composer-preview__hero"
        >
          <button
            v-if="isImage(primaryItem) && primaryItem.previewUrl"
            type="button"
            class="media-composer-preview__image-button"
            :aria-label="`${t('pluginFilePreview')}: ${primaryItem.name}`"
            :disabled="loading"
            @click="previewId = primaryItem.id"
          >
            <img :src="primaryItem.previewUrl" :alt="primaryItem.name" />
          </button>
          <video v-else-if="primaryItem.kind === 'video' && primaryItem.previewUrl" :src="primaryItem.previewUrl"
            :aria-label="primaryItem.name" preload="metadata" controls playsinline />
          <div class="media-composer-preview__details">
            <FlareIcon v-if="!primaryItem.previewUrl || (!isImage(primaryItem) && primaryItem.kind !== 'video')"
              :name="isImage(primaryItem) ? 'image' : primaryItem.kind === 'video' ? 'video' : 'file'" aria-hidden="true" />
            <span>{{ primaryItem.name }}</span>
            <small v-if="primaryItem.size">{{ formatBytes(primaryItem.size) }}</small>
            <FlareIconButton
              v-if="canRemove"
              :class="{ 'media-composer-preview__remove--overlay': isImage(primaryItem) && primaryItem.previewUrl }"
              size="sm"
              variant="tinted"
              :icon="flareIcons.close"
              :ariaLabel="`${t('pluginFileRemove')}: ${primaryItem.name}`"
              :disabled="loading"
              @click="emit('remove', primaryItem.id)"
            />
          </div>
        </article>

        <div v-else-if="items.length" class="media-composer-preview__gallery">
          <article v-for="item in items" :key="item.id" class="media-composer-preview__thumb">
            <img v-if="isImage(item) && item.previewUrl" :src="item.previewUrl" :alt="item.name" />
            <video v-else-if="item.kind === 'video' && item.previewUrl" :src="item.previewUrl"
              :aria-label="item.name" preload="metadata" controls playsinline />
            <div v-else class="media-composer-preview__file">
              <strong>{{ item.name }}</strong>
              <span v-if="item.mimeType">{{ item.mimeType }}</span>
              <span v-if="item.size">{{ formatBytes(item.size) }}</span>
            </div>
            <span class="media-composer-preview__name">{{ item.name }}</span>
          </article>
        </div>

        <FlareTextarea v-if="showDescription" v-model="description" :rows="2" :max-rows="5"
          :placeholder="descriptionPlaceholder" :aria-label="t('composer.caption')" :disabled="loading" @enter="submit" />
        <FlareStatusBanner v-if="error" :text="error" tone="danger" />
      </div>

      <div class="media-composer-preview__footer">
        <FlareButton variant="secondary" :disabled="loading" @click="close">{{ t("common.cancel") }}</FlareButton>
        <FlareButton :loading="loading" :disabled="!items.length" @click="submit">
          {{ t("composer.send") }}
        </FlareButton>
      </div>
    </div>
  </FlareBottomSheet>
  <ImagePreviewModal v-if="previewItem" :show="true" :image-src="previewItem.previewUrl!" :alt="previewItem.name"
    :loading-text="t('common.loading')" :error-text="t('mediaMessage.imageFailed')" :retry-text="t('common.retry')"
    :gallery-index="previewIndex" :gallery-count="previewImages.length" @update:show="previewId = null"
    @previous="movePreview(-1)" @next="movePreview(1)" />
</template>

<style scoped>
.media-composer-preview__body {
  display: grid;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-md);
}
.media-composer-preview__hero {
  position: relative;
  margin: 0;
  min-width: 0;
  overflow: hidden;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
}
.media-composer-preview__image-button {
  display: block;
  width: 100%;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: zoom-in;
}
.media-composer-preview__image-button:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
.media-composer-preview__remove--overlay {
  position: absolute;
  inset-block-start: var(--flare-size-spacing-xs);
  inset-inline-end: var(--flare-size-spacing-xs);
}
.media-composer-preview__hero img,
.media-composer-preview__hero video {
  display: block;
  width: 100%;
  max-height: min(40dvh, var(--flare-size-component-media-image-max-width));
  object-fit: contain;
}
.media-composer-preview__details {
  display: flex;
  align-items: center;
  min-width: 0;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
}
.media-composer-preview__details > span {
  flex: 1;
  min-width: 0;
  overflow-wrap: anywhere;
}
.media-composer-preview__details small {
  flex-shrink: 0;
  font-size: inherit;
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
.media-composer-preview__name {
  min-width: 0;
  padding: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.media-composer-preview__footer {
  display: flex;
  position: sticky;
  bottom: 0;
  z-index: 1;
  gap: var(--flare-size-spacing-sm);
  margin-inline: var(--flare-size-spacing-lg);
  padding-block: var(--flare-size-spacing-md) var(--flare-size-spacing-sm);
  border-top: 1px solid var(--flare-color-border-secondary);
  background: var(--flare-color-bg-primary);
}
/* 手机上这排键是这张面的底,拇指够得着才行:平分整行。桌面收在末端。 */
[data-flare-presentation="sheet"] .media-composer-preview__footer > * {
  flex: 1;
}
[data-flare-presentation="dialog"] .media-composer-preview__footer {
  justify-content: flex-end;
}
</style>
