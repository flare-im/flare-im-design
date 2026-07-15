<script setup>
import { ref } from "vue";
import FlareCallDock from "flare-core-vue-im-ui/components/call/FlareCallDock.vue";
import DemoStage from "./DemoStage.vue";
const muted = ref(false);
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareCallDock
        title="Ivy Chen"
        mode="audio"
        duration-label="02:14"
        :muted="muted"
        @toggle-mute="muted = !muted"
        @expand="() => {}"
        @hangup="() => {}"
      />
      <FlareCallDock title="Flare 设计评审" mode="video" duration-label="18:05" @expand="() => {}" @hangup="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; align-items: flex-start; padding: 28px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
