<script setup lang="ts">
import { NIcon } from "naive-ui";
import { CloseOutline, DocumentAttachOutline, RefreshOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

/** One queued attachment as the host reports it; the host owns the upload itself. */
export type FlareComposerUploadPreview = {
  id: string;
  name: string;
  progress?: number;
  state?: "uploading" | "ready" | "failed";
  thumbnailUrl?: string;
};

// Pending-attachment strip of the composer: pure presentation of host-owned
// upload state with retry / remove intents handed back to the host.
defineProps<{ items: readonly FlareComposerUploadPreview[]; blocked?: boolean }>();
const emit = defineEmits<{ (event: "retry", id: string): void; (event: "remove", id: string): void }>();
const { t } = useFlareI18n();
</script>

<template>
  <section class="composer-upload-strip" :aria-label="t('composer.uploads')">
    <article
      v-for="item in items"
      :key="item.id"
      class="composer-upload-item"
      :class="`composer-upload-item--${item.state ?? 'uploading'}`"
    >
      <img v-if="item.thumbnailUrl" :src="item.thumbnailUrl" alt="" />
      <span v-else class="composer-upload-item__preview" aria-hidden="true"><n-icon aria-hidden="true" :component="DocumentAttachOutline" /></span>
      <span class="composer-upload-item__body">
        <strong>{{ item.name }}</strong>
        <span>{{ item.state === 'failed' ? t('composer.uploadFailed') : item.state === 'ready' ? t('composer.uploadReady') : t('composer.uploading') }}</span>
        <progress v-if="item.state !== 'ready'" max="1" :value="item.progress" :aria-label="item.name" />
      </span>
      <button v-if="item.state === 'failed'" type="button" :disabled="blocked" :title="t('composer.retryUpload')" :aria-label="t('composer.retryUpload')" @click="emit('retry', item.id)">
        <n-icon aria-hidden="true" :component="RefreshOutline" />
      </button>
      <button type="button" :disabled="blocked" :title="t('composer.removeUpload')" :aria-label="t('composer.removeUpload')" @click="emit('remove', item.id)">
        <n-icon aria-hidden="true" :component="CloseOutline" />
      </button>
    </article>
  </section>
</template>

<style scoped>
.composer-upload-strip {
  position: relative;
  display: flex;
  min-width: 0;
  width: 100%;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md) 9px;
  overflow-x: auto;
  background: transparent;
  scrollbar-width: thin;
}
.composer-upload-item {
  display: grid;
  grid-template-columns: 36px minmax(88px, 1fr) 28px;
  align-items: center;
  flex: 0 0 min(230px, 72vw);
  min-width: 0;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-2xs);
  border: 0;
  border-radius: var(--flare-size-radius-sm, 6px);
  background: var(--studio-surface-subtle, var(--flare-color-bg-secondary));
}
.composer-upload-item--failed {
  --studio-accent: var(--flare-color-error);
  grid-template-columns: 36px minmax(88px, 1fr) 28px 28px;
}
.composer-upload-item > img,
.composer-upload-item__preview {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  overflow: hidden;
  border-radius: var(--flare-size-radius-xs, 3px);
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-tertiary);
  object-fit: cover;
}
.composer-upload-item__body { display: grid; min-width: 0; gap: 2px; }
.composer-upload-item__body strong,
.composer-upload-item__body span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.composer-upload-item__body strong { color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-sm); font-weight: 600; }
.composer-upload-item__body span { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); }
.composer-upload-item progress {
  appearance: none;
  width: 100%;
  height: 3px;
  overflow: hidden;
  border: 0;
  border-radius: var(--flare-size-radius-full, 999px);
  background: var(--flare-color-border-secondary);
}
.composer-upload-item progress::-webkit-progress-bar { background: var(--flare-color-border-secondary); }
.composer-upload-item progress::-webkit-progress-value { background: var(--studio-accent, var(--flare-color-primary)); }
.composer-upload-item progress::-moz-progress-bar { background: var(--studio-accent, var(--flare-color-primary)); }
.composer-upload-item > button {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-sm, 6px);
  color: var(--flare-color-text-tertiary);
  background: transparent;
  cursor: pointer;
}
.composer-upload-item > button:hover { color: var(--flare-color-text-primary); background: var(--flare-color-bg-hover); }
.composer-upload-item > button:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
@media (pointer: coarse) {
  .composer-upload-item { grid-template-columns: 36px minmax(0, 1fr) 44px; flex-basis: min(290px, 88vw); }
  .composer-upload-item--failed { grid-template-columns: 36px minmax(0, 1fr) 44px 44px; }
  .composer-upload-item > button { width: 44px; height: 44px; }
}
</style>
