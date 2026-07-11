<script setup>
import FlareComposerActionPanel from "flare-core-vue-im-ui/components/composer/FlareComposerActionPanel.vue";
import DemoStage from "./DemoStage.vue";

const actions = [
  { key: "album", label: "相册" },
  { key: "camera", label: "拍摄" },
  { key: "file", label: "文件" },
  { key: "location", label: "位置" },
  { key: "card", label: "名片" },
  { key: "voice", label: "语音通话" },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareComposerActionPanel :actions="actions" :columns="4" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 420px; }
</style>
