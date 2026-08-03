<script setup>
import { ref } from "vue";
import FlareSlider from "@flare-im/vue-ui/components/form/FlareSlider.vue";
import DemoStage from "./DemoStage.vue";
const a = ref(40), b = ref(2);
</script>
<template>
  <DemoStage>
    <div class="stack">
      <div class="row"><span class="k">音量</span><FlareSlider v-model="a" :show-value="true" /></div>
      <div class="row"><span class="k">语速</span><FlareSlider v-model="b" :min="1" :max="4" :step="1" /></div>
      <div class="row"><span class="k">禁用</span><FlareSlider :model-value="70" disabled /></div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 22px; padding: 24px 28px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.row { display: flex; align-items: center; gap: 16px; }
.k { width: 40px; flex: 0 0 auto; font-size: 13px; color: var(--flare-color-text-tertiary); }
</style>
