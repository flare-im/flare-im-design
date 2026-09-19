<script setup>
import { FlareBrandLogo } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="row">
      <FlareBrandLogo :size="64" />
      <FlareBrandLogo :size="40" />
      <span class="plate"><FlareBrandLogo :size="64" variant="plate" /></span>
    </div>
  </DemoStage>
</template>
<style scoped>
.row { display: flex; align-items: center; gap: 24px; }
.plate { display: inline-flex; padding: 16px; border-radius: var(--flare-size-radius-xl); background: var(--flare-color-primary); }
</style>
