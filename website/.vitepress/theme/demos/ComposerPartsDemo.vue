<script setup>
// Assembled from the real composer parts (each also shown on its own page).
import { FlareVoiceHoldButton } from "@flare-im/vue-ui/components";
import { FlareComposerActionPanel } from "@flare-im/vue-ui/components";
import { FlareComposerSendButton } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const actions = [
  { id: "album", label: "相册" },
  { id: "camera", label: "拍摄" },
  { id: "file", label: "文件" },
  { id: "location", label: "位置" },
];
</script>

<template>
  <DemoStage>
    <div class="parts">
      <div class="part">
        <FlareVoiceHoldButton label="按住 说话" recording-label="松开发送" />
        <div class="cap">FlareVoiceHoldButton</div>
      </div>
      <div class="part">
        <FlareComposerActionPanel :actions="actions" :columns="4" />
        <div class="cap">FlareComposerActionPanel</div>
      </div>
      <div class="part">
        <FlareComposerSendButton :active="true" />
        <div class="cap">FlareComposerSendButton</div>
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.parts { display: flex; flex-direction: column; gap: 20px; width: 100%; max-width: 420px; }
.part { display: flex; flex-direction: column; gap: 8px; align-items: center; }
.cap { font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
