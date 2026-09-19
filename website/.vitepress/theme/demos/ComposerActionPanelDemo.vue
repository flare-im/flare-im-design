<script setup>
import { FlareComposerActionPanel } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const actions = [
  { id: "album", label: "相册" },
  { id: "camera", label: "拍摄" },
  { id: "file", label: "文件" },
  { id: "location", label: "位置" },
  { id: "contact", label: "名片" },
  { id: "voice", label: "语音通话" },
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
