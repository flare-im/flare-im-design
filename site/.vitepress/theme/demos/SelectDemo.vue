<script setup>
import { ref } from "vue";
import FlareSelect from "@flare-im/vue-ui/components/form/FlareSelect.vue";
import DemoStage from "./DemoStage.vue";
const v = ref("");
const opts = [
  { value: "zh", label: "简体中文" },
  { value: "en", label: "English" },
  { value: "ja", label: "日本語" },
  { value: "ko", label: "한국어(即将支持)", disabled: true },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareSelect v-model="v" :options="opts" placeholder="选择语言" />
      <p class="hint">当前:{{ v || "（未选）" }}</p>
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 40px 24px 100px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.hint { margin: 0; font-size: 13px; color: var(--flare-color-text-tertiary); }
</style>
