<script setup>
import { ref } from "vue";
import FlareImagePreview from "flare-core-vue-im-ui/components/message-preview/ImagePreviewModal.vue";
import DemoStage from "./DemoStage.vue";

const open = ref(false);
const src =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="480" height="320"><rect width="480" height="320" fill="#7c3aed"/><text x="50%" y="50%" fill="#fff" font-size="28" font-family="sans-serif" text-anchor="middle" dominant-baseline="middle">Preview</text></svg>',
  );
</script>

<template>
  <DemoStage>
    <div class="stage">
      <button class="trigger" @click="open = true">打开图片预览</button>
      <FlareImagePreview
        :show="open"
        :image-src="src"
        alt="示例图片"
        @close="open = false"
        @update:show="open = $event"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.trigger { padding: 8px 18px; border-radius: 8px; border: 1px solid var(--flare-color-primary); background: none; color: var(--flare-color-primary); font-size: 14px; cursor: pointer; }
</style>
