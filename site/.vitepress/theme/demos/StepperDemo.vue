<script setup>
import { ref } from "vue";
import FlareStepper from "@flare-im/vue-ui/components/form/FlareStepper.vue";
import DemoStage from "./DemoStage.vue";
const a = ref(1), b = ref(3), c = ref(10);
</script>
<template>
  <DemoStage>
    <div class="stack">
      <label class="line"><FlareStepper v-model="a" :min="0" :max="9" /> 数量(0–9)</label>
      <label class="line"><FlareStepper v-model="b" :min="1" :max="20" :step="1" size="sm" /> 小尺寸</label>
      <label class="line"><FlareStepper v-model="c" :step="5" readonly /> 只读中值(步进 5)</label>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.line { display: flex; align-items: center; gap: 12px; font-size: 14px; color: var(--flare-color-text-primary); }
</style>
