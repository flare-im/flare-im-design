<script setup>
import { FlareRedPacketArch } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stack">
      <div class="page"><FlareRedPacketArch /></div>
      <div class="page"><FlareRedPacketArch compact /></div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: grid; gap: 16px; max-width: 420px; }
.page { min-height: 120px; border-radius: 14px; overflow: hidden; background: var(--flare-color-bg-secondary); }
</style>
