<script setup lang="ts">
import { ref } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareImageUploadSlot from "./FlareImageUploadSlot.vue";
import type { FlareUploadState } from "../../shared/contracts/upload";

/** A single-file picker and controlled upload surface. It makes no network requests. */
const props = withDefaults(
  defineProps<{
    title: string;
    state: FlareUploadState;
    statusText: string;
    pickLabel: string;
    fileName?: string;
    image?: boolean;
    /** A picker hint supplied by the host's authoritative policy; never an authorization check. */
    accept?: string;
    previewUrl?: string;
    progress?: number;
    uploadLabel?: string;
    replaceLabel?: string;
    retryLabel?: string;
    cancelLabel?: string;
    removeLabel?: string;
    disabled?: boolean;
    /** Delegate choosing to the application; the internal DOM picker stays unused. */
    hostPicker?: boolean;
    previewLabel?: string;
    previewLoading?: boolean;
  }>(),
  { image: false, disabled: false, hostPicker: false },
);
const emit = defineEmits<{
  select: [file: File];
  upload: [];
  retry: [];
  cancel: [];
  remove: [];
  choose: [];
  replace: [];
  preview: [];
}>();
const picker = ref<HTMLInputElement>();
function choose() {
  if (props.disabled || props.state === "uploading") return;
  if (props.hostPicker) {
    if (props.state === "empty") emit("choose");
    else emit("replace");
    return;
  }
  picker.value?.click();
}
function selected(event: Event) {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  input.value = "";
  if (!file || props.disabled || props.state === "uploading") return;
  emit("select", file);
}
</script>

<template>
  <div class="flare-file-upload">
    <input
      v-if="!hostPicker"
      ref="picker"
      hidden
      type="file"
      :accept="accept"
      :disabled="disabled || state === 'uploading'"
      :aria-label="`${pickLabel}: ${title}`"
      @change="selected"
    />
    <FlareImageUploadSlot
      :title="title"
      :state="state"
      :status-text="statusText"
      :pick-label="
        state === 'uploaded' && replaceLabel ? replaceLabel : pickLabel
      "
      :icon="image ? 'camera' : 'file'"
      :preview-url="image ? previewUrl : undefined"
      :progress="progress"
      :replaceable="!!replaceLabel"
      :disabled="disabled"
      :preview-label="previewLabel"
      :preview-loading="previewLoading"
      :preview-disabled="disabled"
      @choose="choose"
      @preview="emit('preview')"
    >
      <template #actions>
        <FlareButton
          v-if="(state === 'uploading' || state === 'selected') && cancelLabel"
          size="sm"
          variant="secondary"
          :label="cancelLabel"
          :disabled="disabled"
          @click="emit('cancel')"
        />
        <FlareButton
          v-if="state === 'failed' && retryLabel"
          size="sm"
          :label="retryLabel"
          :disabled="disabled"
          @click="emit('retry')"
        />
        <FlareButton
          v-if="state === 'selected' && uploadLabel"
          size="sm"
          :label="uploadLabel"
          :disabled="disabled"
          @click="emit('upload')"
        />
        <FlareButton
          v-if="state !== 'empty' && state !== 'uploading' && replaceLabel"
          size="sm"
          variant="secondary"
          :label="replaceLabel"
          :disabled="disabled"
          @click="choose"
        />
        <FlareButton
          v-if="state !== 'empty' && state !== 'uploading' && removeLabel"
          size="sm"
          variant="ghost"
          :label="removeLabel"
          :disabled="disabled"
          @click="emit('remove')"
        />
      </template>
    </FlareImageUploadSlot>
    <span v-if="fileName" class="flare-file-upload__name">{{ fileName }}</span>
  </div>
</template>

<style scoped>
.flare-file-upload {
  display: grid;
  min-width: 0;
  gap: var(--flare-size-spacing-xs);
}
.flare-file-upload__name {
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  overflow-wrap: anywhere;
}
</style>
