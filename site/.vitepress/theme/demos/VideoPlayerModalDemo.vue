<script setup>
import { ref } from "vue";
import FlareVideoPreview from "flare-core-vue-im-ui/components/message-preview/VideoPlayerModal.vue";
import DemoStage from "./DemoStage.vue";

const open = ref(false);
const poster =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="480" height="270"><rect width="480" height="270" fill="#1f2430"/><text x="50%" y="50%" fill="#fff" font-size="24" font-family="sans-serif" text-anchor="middle" dominant-baseline="middle">Video</text></svg>',
  );
</script>

<template>
  <DemoStage>
    <div class="stage">
      <button class="trigger" @click="open = true">打开视频播放</button>
      <FlareVideoPreview
        :show="open"
        video-src=""
        :poster="poster"
        title="示例视频"
        @close="open = false"
        @update:show="open = $event"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.trigger { padding: 8px 18px; border-radius: 8px; border: 1px solid var(--flare-color-primary); background: none; color: var(--flare-color-primary); font-size: 14px; cursor: pointer; }
</style>
