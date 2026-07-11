<script setup>
import FlareVoiceHoldButton from "flare-core-vue-im-ui/components/composer/FlareVoiceHoldButton.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareVoiceHoldButton label="按住 说话" recording-label="松开发送 · 上滑取消" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 320px; }
</style>
