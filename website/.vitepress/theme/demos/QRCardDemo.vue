<script setup>
import { FlareQRCard } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
import { ref } from "vue";
const phase = ref("ready");
function refresh() { phase.value = "refreshing"; setTimeout(() => { phase.value = "ready"; }, 900); }
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareQRCard name="Ivy Chen" subtitle="设计 · 组件组" qr-payload="https://scan.flare.test/u/vYy5hW5dKbiV8aZraFR4rA" :phase="phase" @refresh="refresh" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
