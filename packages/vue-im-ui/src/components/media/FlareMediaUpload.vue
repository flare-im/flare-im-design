<script setup lang="ts">
import { computed, ref, useId } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareFileUpload from "./FlareFileUpload.vue";
import type { FlareMediaUploadItem } from "../../shared/contracts/upload";
import { useFileDropTarget } from "../../shared/useFileDropTarget";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

/** Controlled Web selection and upload presentation. Never starts a transfer or owns object URLs. */
const props = withDefaults(defineProps<{
  title: string;
  items: ReadonlyArray<FlareMediaUploadItem>;
  statusText: string;
  pickLabel: string;
  layout?: "files" | "images";
  accept?: string;
  maxCount?: number;
  disabled?: boolean;
  showPicker?: boolean;
  uploadLabel?: string;
  retryLabel?: string;
  cancelLabel?: string;
  removeLabel?: string;
  previewLabel?: string;
  error?: string;
}>(), { layout: "files", disabled: false, showPicker: true });
const emit = defineEmits<{
  select: [files: File[]];
  upload: [id: string];
  retry: [id: string];
  cancel: [id: string];
  remove: [id: string];
  preview: [id: string];
}>();
const picker = ref<HTMLInputElement>();
const hintId = useId();
const { t } = useFlareI18nOptional();
function percentage(item: FlareMediaUploadItem) {
  return Number.isFinite(item.progress) ? Math.min(100, Math.max(0, item.progress!)) : undefined;
}
const full = computed(() => props.maxCount !== undefined && props.items.length >= Math.max(0, props.maxCount));
const canChoose = computed(() => props.showPicker && !props.disabled && !full.value);
// Emit the whole batch in source order. Hosts must report policy failures rather than silently lose files.
const { dragging, enter, over, leave, dropped } = useFileDropTarget(() => canChoose.value, (files) => emit("select", files));
function choose() { if (canChoose.value) picker.value?.click(); }
function selected(event: Event) {
  const input = event.target as HTMLInputElement;
  const files = Array.from(input.files ?? []);
  input.value = "";
  if (canChoose.value && files.length) emit("select", files);
}
function action(event: "upload" | "retry" | "cancel" | "remove" | "preview", item: FlareMediaUploadItem) {
  if (props.disabled || item.disabled) return;
  if (event === "upload" && item.state !== "selected") return;
  if (event === "retry" && item.state !== "failed") return;
  if (event === "cancel" && item.state !== "uploading") return;
  if (event === "remove" && item.state === "uploading") return;
  if (event === "upload") emit("upload", item.id);
  else if (event === "retry") emit("retry", item.id);
  else if (event === "cancel") emit("cancel", item.id);
  else if (event === "remove") emit("remove", item.id);
  else if (event === "preview" && item.previewUrl && props.previewLabel) emit("preview", item.id);
}
</script>

<template>
  <section role="group" class="flare-media-upload" :class="{ 'is-dragging': dragging, 'is-images': layout === 'images', 'is-review': !showPicker }"
    :aria-label="title" :aria-describedby="maxCount !== undefined ? hintId : undefined" @dragenter="enter" @dragover="over" @dragleave="leave" @drop="dropped">
    <input v-if="showPicker" ref="picker" hidden type="file" multiple :accept="accept" :disabled="!canChoose" :aria-label="`${pickLabel}: ${title}`" @change="selected" />
    <FlareFileUpload v-if="layout === 'files' && showPicker && !full" :title="title" state="empty" :status-text="statusText" :pick-label="pickLabel"
      :disabled="!canChoose" host-picker @choose="choose" />
    <div v-else-if="layout === 'files' && showPicker" class="flare-media-upload__capacity"><h3>{{ title }}</h3><p>{{ statusText }}</p></div>
    <p v-if="error" class="flare-media-upload__error" role="alert">{{ error }}</p>
    <p :id="hintId" class="flare-media-upload__count" role="status" v-if="maxCount !== undefined">{{ items.length }} / {{ maxCount }}</p>
    <ul v-if="items.length || (layout === 'images' && showPicker && !full)" class="flare-media-upload__items" :aria-label="title">
      <li v-for="item in items" :key="item.id" class="flare-media-upload__item">
        <div v-if="layout === 'images'" class="flare-media-upload__tile" :class="{ 'is-failed': item.state === 'failed' }">
          <button type="button" class="flare-media-upload__thumbnail" :aria-label="`${previewLabel || t('pluginFilePreview')}: ${item.name}`"
            :disabled="disabled || item.disabled || !item.previewUrl || !previewLabel" :title="item.state === 'failed' ? item.statusText : undefined"
            @click="action('preview', item)">
            <img v-if="item.previewUrl" :src="item.previewUrl" :alt="item.name" referrerpolicy="no-referrer" />
            <FlareIcon v-else name="image" size="xl" aria-hidden="true" />
          </button>
          <div v-if="item.state === 'uploading'" class="flare-media-upload__progress">
            <span>{{ percentage(item) === undefined ? item.statusText : `${percentage(item)}%` }}</span>
            <progress :value="percentage(item)" max="100" :aria-label="`${item.name}: ${item.statusText}`" />
          </div>
          <div v-if="(item.state === 'uploading' && cancelLabel) || (item.state !== 'uploading' && removeLabel)" class="flare-media-upload__corner">
            <FlareIconButton size="sm" variant="tinted" :icon="flareIcons.close" :ariaLabel="`${item.state === 'uploading' ? cancelLabel : removeLabel}: ${item.name}`"
              :disabled="disabled || item.disabled" @click="action(item.state === 'uploading' ? 'cancel' : 'remove', item)" />
          </div>
          <div v-if="item.state === 'failed' || (item.state === 'selected' && uploadLabel)" class="flare-media-upload__recovery">
            <span v-if="item.state === 'failed'" class="flare-media-upload__sr" role="alert">{{ item.name }}: {{ item.statusText }}</span>
            <FlareButton v-if="item.state === 'failed' && retryLabel" size="sm" :label="retryLabel" :aria-label="`${retryLabel}: ${item.name}`" :disabled="disabled || item.disabled" @click="action('retry', item)" />
            <FlareIcon v-else-if="item.state === 'failed'" name="warning" size="md" aria-hidden="true" />
            <FlareButton v-else-if="uploadLabel" size="sm" :label="uploadLabel" :aria-label="`${uploadLabel}: ${item.name}`" :disabled="disabled || item.disabled" @click="action('upload', item)" />
          </div>
        </div>
        <div v-else class="flare-media-upload__file">
          <FlareIcon name="file" size="lg" aria-hidden="true" />
          <div class="flare-media-upload__copy">
            <span class="flare-media-upload__name">{{ item.name }}</span>
            <span class="flare-media-upload__status" :class="{ 'is-error': item.state === 'failed' }" :role="item.state === 'failed' ? 'alert' : 'status'">{{ item.statusText }}</span>
          </div>
        </div>
        <progress v-if="layout === 'files' && item.state === 'uploading'" :value="Number.isFinite(item.progress) ? Math.min(100, Math.max(0, item.progress!)) : undefined" max="100" :aria-label="`${item.name}: ${item.statusText}`" />
        <div v-if="layout === 'files'" class="flare-media-upload__actions">
          <FlareButton v-if="item.state === 'selected' && uploadLabel" size="sm" :label="uploadLabel" :aria-label="`${uploadLabel}: ${item.name}`" :disabled="disabled || item.disabled" @click="action('upload', item)" />
          <FlareButton v-if="item.state === 'failed' && retryLabel" size="sm" :label="retryLabel" :aria-label="`${retryLabel}: ${item.name}`" :disabled="disabled || item.disabled" @click="action('retry', item)" />
          <FlareButton v-if="item.state === 'uploading' && cancelLabel" size="sm" variant="secondary" :label="cancelLabel" :aria-label="`${cancelLabel}: ${item.name}`" :disabled="disabled || item.disabled" @click="action('cancel', item)" />
          <FlareButton v-if="item.state !== 'uploading' && removeLabel" size="sm" variant="ghost" :label="removeLabel" :aria-label="`${removeLabel}: ${item.name}`" :disabled="disabled || item.disabled" @click="action('remove', item)" />
        </div>
      </li>
      <li v-if="layout === 'images' && showPicker && !full" class="flare-media-upload__item flare-media-upload__add-item">
        <button type="button" class="flare-media-upload__add" :aria-label="`${pickLabel}: ${title}`" :title="statusText" :disabled="!canChoose" @click="choose">
          <FlareIcon name="add" size="lg" aria-hidden="true" />
        </button>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.flare-media-upload { display: grid; min-width: 0; gap: var(--flare-size-spacing-sm); }
.is-dragging > .flare-file-upload :deep(.flare-image-upload__picker) { border-color: var(--flare-color-border-selected); background: var(--flare-color-bg-selected); }
.flare-media-upload__error { margin: 0; color: var(--flare-color-error-text); font-size: var(--flare-size-font-size-sm); overflow-wrap: anywhere; }
.flare-media-upload__capacity { display: grid; gap: var(--flare-size-spacing-xs); }
.flare-media-upload__capacity h3 { margin: 0; color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-md); }
.flare-media-upload__capacity p { margin: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); overflow-wrap: anywhere; }
.flare-media-upload__count { margin: 0; text-align: end; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); font-variant-numeric: tabular-nums; }
.flare-media-upload__items { display: grid; gap: var(--flare-size-spacing-md); margin: 0; padding: 0; list-style: none; min-width: 0; }
.flare-media-upload__item { display: grid; align-content: start; gap: var(--flare-size-spacing-xs); min-width: 0; padding-bottom: var(--flare-size-spacing-sm); border-bottom: 1px solid var(--flare-color-border-secondary); }
.flare-media-upload__file { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-media-upload__copy { display: grid; min-width: 0; gap: var(--flare-size-spacing-3xs); }
.flare-media-upload__name { color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-md); overflow-wrap: anywhere; }
.flare-media-upload__status { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); overflow-wrap: anywhere; }
.flare-media-upload__status.is-error { color: var(--flare-color-error-text); }
.flare-media-upload__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-xs); }
.flare-media-upload__item progress { width: 100%; height: var(--flare-size-spacing-xs); accent-color: var(--flare-color-primary); }
.is-images .flare-media-upload__items { width: 100%; max-width: var(--flare-size-component-media-image-max-width); grid-template-columns: repeat(3, minmax(0, 1fr)); gap: var(--flare-size-spacing-sm); }
.is-images.is-review .flare-media-upload__items { margin-inline: auto; }
.is-images .flare-media-upload__item { border: none; padding: 0; }
.flare-media-upload__add { display: grid; place-items: center; box-sizing: border-box; width: 100%; aspect-ratio: 1; min-height: var(--flare-size-layout-touch-target); padding: 0; border: 1px dashed var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md); background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); cursor: pointer; }
.flare-media-upload__add:hover:not(:disabled), .is-dragging .flare-media-upload__add { border-color: var(--flare-color-border-selected); background: var(--flare-color-bg-selected); color: var(--flare-color-text-primary); }
.flare-media-upload__add:disabled { opacity: .45; cursor: not-allowed; }
.flare-media-upload__tile { position: relative; min-width: 0; aspect-ratio: 1; }
.flare-media-upload__thumbnail { box-sizing: border-box; display: grid; place-items: center; width: 100%; height: 100%; min-width: 0; min-height: 0; padding: 0; overflow: hidden; border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-md); background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); cursor: pointer; }
.flare-media-upload__thumbnail img { width: 100%; height: 100%; object-fit: cover; }
.flare-media-upload__thumbnail:disabled { cursor: default; }
.flare-media-upload__thumbnail:focus-visible, .flare-media-upload__add:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.is-failed .flare-media-upload__thumbnail { border-color: var(--flare-color-error); }
.flare-media-upload__corner { position: absolute; top: 0; inset-inline-end: 0; line-height: 0; }
.flare-media-upload__progress, .flare-media-upload__recovery { position: absolute; inset-inline: 0; bottom: 0; display: grid; justify-items: center; gap: var(--flare-size-spacing-xs); box-sizing: border-box; padding: var(--flare-size-spacing-xs); border-radius: 0 0 var(--flare-size-radius-md) var(--flare-size-radius-md); background: color-mix(in srgb, var(--flare-color-bg-primary) 94%, transparent); color: var(--flare-color-text-secondary); font-size: var(--flare-text-caption-font-size); }
.flare-media-upload__progress { pointer-events: none; }
.flare-media-upload__progress span { max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-media-upload__recovery { color: var(--flare-color-error-text); }
.flare-media-upload__sr { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0; }
</style>
