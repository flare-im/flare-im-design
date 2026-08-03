<script setup>
import { ref } from "vue";
import FlareTextarea from "@flare-im/vue-ui/components/form/FlareTextarea.vue";
import DemoStage from "./DemoStage.vue";
const a = ref("");
const b = ref("这一刻的想法…");
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareTextarea v-model="a" placeholder="自动增高,⌘/Ctrl+Enter 提交" :max-rows="6" />
      <FlareTextarea v-model="b" :show-count="true" :maxlength="120" placeholder="带字数统计" />
      <FlareTextarea model-value="禁用态" disabled />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
