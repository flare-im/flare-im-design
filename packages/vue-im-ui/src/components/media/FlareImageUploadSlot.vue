<script setup lang="ts">
import { computed } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";

/** Presentation only. The host owns the picker, bytes, transport and preview lifetime. */
const props = withDefaults(
  defineProps<{
    title: string;
    state: "empty" | "selected" | "uploading" | "uploaded" | "failed";
    statusText: string;
    pickLabel: string;
    actionLabel?: string;
    previewUrl?: string;
    /** Opt an uploaded material into a separate, read-only preview intent. */
    previewLabel?: string;
    previewLoading?: boolean;
    previewDisabled?: boolean;
    disabled?: boolean;
  }>(),
  { disabled: false, previewLoading: false, previewDisabled: false },
);
const emit = defineEmits<{ choose: []; action: []; preview: [] }>();
const previewMode = computed(
  () => props.state === "uploaded" && !!props.previewLabel,
);
const bodyDisabled = computed(() =>
  previewMode.value
    ? props.previewDisabled || props.previewLoading
    : props.disabled ||
      props.state === "uploaded" ||
      props.state === "uploading",
);
function activate() {
  if (bodyDisabled.value) return;
  if (previewMode.value) emit("preview");
  else emit("choose");
}
</script>

<template>
  <section
    class="flare-image-upload"
    :class="`flare-image-upload--${state}`"
    :aria-label="title"
    :aria-busy="state === 'uploading' || previewLoading"
  >
    <h3 class="flare-image-upload__title">{{ title }}</h3>
    <button
      type="button"
      class="flare-image-upload__picker"
      :disabled="bodyDisabled"
      :aria-label="`${previewMode ? previewLabel : pickLabel}: ${title}`"
      @click="activate"
    >
      <img
        v-if="previewUrl"
        class="flare-image-upload__preview"
        :src="previewUrl"
        alt=""
      />
      <template v-else>
        <FlareIcon
          :name="state === 'uploaded' ? 'check' : 'camera'"
          :size="28"
        />
        <span>{{
          previewMode
            ? previewLabel
            : state === "uploaded" || state === "uploading"
              ? statusText
              : pickLabel
        }}</span>
      </template>
      <progress
        v-if="state === 'uploading' || previewLoading"
        :aria-label="`${title}: ${statusText}`"
      />
    </button>
    <div class="flare-image-upload__footer">
      <span role="status" class="flare-image-upload__status">{{
        statusText
      }}</span>
      <FlareButton
        v-if="actionLabel && (state === 'selected' || state === 'failed')"
        size="sm"
        :label="actionLabel"
        :disabled="disabled"
        @click="emit('action')"
      />
    </div>
  </section>
</template>

<style scoped>
.flare-image-upload {
  display: flex;
  flex-direction: column;
  min-width: 0;
  gap: var(--flare-size-spacing-sm);
}
.flare-image-upload__title {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  font-weight: var(--flare-size-font-weight-medium);
  color: var(--flare-color-text-primary);
}
.flare-image-upload__picker {
  position: relative;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: calc(var(--flare-size-layout-touch-target) * 2.5);
  overflow: hidden;
  padding: var(--flare-size-spacing-md);
  border: 1px dashed var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm);
  cursor: pointer;
}
.flare-image-upload__picker:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-image-upload__picker:hover:not(:disabled) {
  border-color: var(--flare-color-border-selected);
  background: var(--flare-color-bg-selected);
}
.flare-image-upload__picker:disabled {
  cursor: default;
}
.flare-image-upload--uploaded .flare-image-upload__picker {
  border-style: solid;
  color: var(--flare-color-success-text);
  background: color-mix(
    in srgb,
    var(--flare-color-success) 6%,
    var(--flare-color-bg-primary)
  );
}
.flare-image-upload--failed .flare-image-upload__picker {
  border-color: var(--flare-color-error);
}
.flare-image-upload__preview {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
}
.flare-image-upload__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-control-height-sm);
}
.flare-image-upload__status {
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  overflow-wrap: anywhere;
}
.flare-image-upload--failed .flare-image-upload__status {
  color: var(--flare-color-error-text);
}
.flare-image-upload__picker progress {
  position: absolute;
  inset-inline: var(--flare-size-spacing-md);
  bottom: var(--flare-size-spacing-sm);
  width: calc(100% - var(--flare-size-spacing-md) * 2);
  height: var(--flare-size-spacing-xs);
  accent-color: var(--flare-color-primary);
}
@media (forced-colors: active) {
  .flare-image-upload--uploaded .flare-image-upload__picker {
    border: 2px solid CanvasText;
  }
}
</style>
