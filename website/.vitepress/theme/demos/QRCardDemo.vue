<script setup>
import { FlareQRCard } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareQRCard name="Ivy Chen" subtitle="设计 · 组件组" qr-payload="https://flare.im/add/ivy-chen" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
