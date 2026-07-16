<script setup>
import { ref } from "vue";
import FlareRating from "flare-core-vue-im-ui/components/form/FlareRating.vue";
import DemoStage from "./DemoStage.vue";
const a = ref(3), b = ref(4);
</script>
<template>
  <DemoStage>
    <div class="stack">
      <label class="line"><FlareRating v-model="a" :clearable="true" /> 评分 {{ a }} / 5</label>
      <label class="line"><FlareRating v-model="b" :count="5" :size="20" /> 小星</label>
      <label class="line"><FlareRating :model-value="4" readonly :size="18" /> 只读</label>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.line { display: flex; align-items: center; gap: 12px; font-size: 14px; color: var(--flare-color-text-primary); }
</style>
