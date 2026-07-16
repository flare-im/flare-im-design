<script setup>
import { ref } from "vue";
import FlareSwitch from "flare-core-vue-im-ui/components/form/FlareSwitch.vue";
import DemoStage from "./DemoStage.vue";
const a = ref(true), b = ref(false);
</script>
<template>
  <DemoStage>
    <div class="stack">
      <label class="line"><FlareSwitch v-model="a" /> 消息通知 {{ a ? "开" : "关" }}</label>
      <label class="line"><FlareSwitch v-model="b" /> 免打扰</label>
      <label class="line"><FlareSwitch :model-value="true" disabled /> 禁用(开)</label>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.line { display: flex; align-items: center; gap: 10px; font-size: 14px; color: var(--flare-color-text-primary); }
</style>
