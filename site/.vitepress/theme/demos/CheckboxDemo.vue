<script setup>
import { ref } from "vue";
import FlareCheckbox from "flare-core-vue-im-ui/components/form/FlareCheckbox.vue";
import DemoStage from "./DemoStage.vue";
const a = ref(true), b = ref(false), c = ref(false);
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareCheckbox v-model="a" label="记住登录" />
      <FlareCheckbox v-model="b" label="接收营销邮件" />
      <FlareCheckbox :model-value="false" indeterminate label="部分选中(indeterminate)" />
      <FlareCheckbox v-model="c" disabled label="禁用" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 14px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
