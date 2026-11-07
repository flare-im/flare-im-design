<script setup lang="ts">
import { NModal, NCard, NImage, NButton, NAlert, NSpin } from "naive-ui";
import { ref, watch } from "vue";
const props = defineProps<{
  open: boolean;
  url?: string;
  kind?: string;
  title: string;
  loading?: boolean;
  error?: string;
  failedText: string;
  closeText: string;
  downloadText: string;
}>();
const emit = defineEmits<{ close: []; download: [] }>();
const mediaFailed = ref(false);
watch(
  () => [props.open, props.url],
  () => {
    mediaFailed.value = false;
  },
);
</script>
<template>
  <NModal
    :show="open"
    :mask-closable="true"
    @update:show="
      (show) => {
        if (!show) emit('close');
      }
    "
  >
    <NCard
      class="flare-admin-attachment-preview"
      :title="title"
      size="small"
      role="dialog"
      aria-modal="true"
      :aria-label="title"
      closable
      @close="emit('close')"
    >
      <NSpin
        :show="loading"
        content-class="flare-admin-attachment-preview__body"
      >
        <NAlert v-if="error" type="error">{{ error }}</NAlert>
        <NAlert v-else-if="mediaFailed" type="error">{{ failedText }}</NAlert>
        <template v-else-if="open && url">
          <NImage
            v-if="kind === 'image'"
            :src="url"
            :alt="title"
            :img-props="{
              crossorigin: 'anonymous',
              referrerpolicy: 'no-referrer',
            }"
            object-fit="contain"
            :preview-disabled="true"
            @error="mediaFailed = true"
          />
          <video
            v-else-if="kind === 'video'"
            :src="url"
            controls
            playsinline
            preload="metadata"
            crossorigin="anonymous"
            :aria-label="title"
            @error="mediaFailed = true"
          />
          <audio
            v-else-if="kind === 'audio'"
            :src="url"
            controls
            preload="metadata"
            crossorigin="anonymous"
            :aria-label="title"
            @error="mediaFailed = true"
          />
        </template>
      </NSpin>
      <template #footer
        ><div class="flare-admin-attachment-preview__footer">
          <NButton size="small" @click="emit('close')">{{ closeText }}</NButton
          ><NButton
            size="small"
            type="primary"
            :disabled="loading || !url || !!error"
            @click="emit('download')"
            >{{ downloadText }}</NButton
          >
        </div></template
      >
    </NCard>
  </NModal>
</template>
<style scoped>
.flare-admin-attachment-preview {
  width: min(960px, calc(100vw - 24px));
  max-height: calc(100dvh - 24px);
  overflow: auto;
}
.flare-admin-attachment-preview :deep(.flare-admin-attachment-preview__body) {
  min-height: 120px;
}
.flare-admin-attachment-preview video,
.flare-admin-attachment-preview audio {
  width: 100%;
  max-height: 65dvh;
}
.flare-admin-attachment-preview :deep(.n-image img) {
  max-width: 100%;
  max-height: 65dvh;
}
.flare-admin-attachment-preview__footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-sm);
  flex-wrap: wrap;
}
</style>
