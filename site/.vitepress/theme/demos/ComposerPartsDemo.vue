<script setup>
// Assembled from the real composer parts (each also shown on its own page).
import FlareVoiceHoldButton from "flare-core-vue-im-ui/components/composer/FlareVoiceHoldButton.vue";
import FlareComposerActionPanel from "flare-core-vue-im-ui/components/composer/FlareComposerActionPanel.vue";
import FlareComposerSendButton from "flare-core-vue-im-ui/components/composer/FlareComposerSendButton.vue";
import DemoStage from "./DemoStage.vue";

const actions = [
  { key: "album", label: "相册" },
  { key: "camera", label: "拍摄" },
  { key: "file", label: "文件" },
  { key: "location", label: "位置" },
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
