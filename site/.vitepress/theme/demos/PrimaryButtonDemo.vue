<script setup>
import { ref } from "vue";
import FlarePrimaryButton from "flare-core-vue-im-ui/components/general/FlarePrimaryButton.vue";
import DemoStage from "./DemoStage.vue";
const busy = ref(false);
function go() { busy.value = true; setTimeout(() => (busy.value = false), 1400); }
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlarePrimaryButton label="登录" :loading="busy" loading-label="连接中…" @click="go" />
      <FlarePrimaryButton label="发起投票" />
      <FlarePrimaryButton label="不可用" disabled />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 12px; max-width: 320px; margin: 0 auto; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
