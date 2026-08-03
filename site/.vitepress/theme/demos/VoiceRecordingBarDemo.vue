<script setup>
import FlareVoiceRecordingBar from "@flare-im/vue-ui/components/composer/FlareVoiceRecordingBar.vue";
import DemoStage from "./DemoStage.vue";
const amps = Array.from({ length: 28 }, (_, i) => 0.25 + 0.7 * Math.abs(Math.sin(i * 0.8 + 1)));
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareVoiceRecordingBar duration-label="0:07" :amplitudes="amps" @cancel="() => {}" @send="() => {}" />
      <FlareVoiceRecordingBar duration-label="0:12" :amplitudes="amps" cancelling @cancel="() => {}" @send="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
