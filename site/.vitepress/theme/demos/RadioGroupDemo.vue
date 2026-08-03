<script setup>
import { ref } from "vue";
import FlareRadioGroup from "@flare-im/vue-ui/components/form/FlareRadioGroup.vue";
import DemoStage from "./DemoStage.vue";
const v = ref("all");
const opts = [
  { value: "all", label: "所有人" },
  { value: "friends", label: "仅好友" },
  { value: "private", label: "仅自己" },
  { value: "off", label: "关闭", disabled: true },
];
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareRadioGroup v-model="v" :options="opts" />
      <FlareRadioGroup v-model="v" :options="opts" vertical />
      <p class="hint">当前:{{ v }}</p>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 18px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.hint { margin: 0; font-size: 13px; color: var(--flare-color-text-tertiary); }
</style>
