<script setup>
import { ref } from "vue";
import { NIcon } from "naive-ui";
import { SendOutline } from "@vicons/ionicons5";
import FlareButton from "@flare-im/vue-ui/components/general/FlareButton.vue";
import DemoStage from "./DemoStage.vue";
const busy = ref(false);
function go() { busy.value = true; setTimeout(() => (busy.value = false), 1300); }
const send = SendOutline;
</script>
<template>
  <DemoStage>
    <div class="stack">
      <div class="row"><FlareButton label="Primary" /><FlareButton label="Secondary" variant="secondary" /><FlareButton label="Ghost" variant="ghost" /><FlareButton label="Danger" variant="danger" /><FlareButton label="Text" variant="text" /></div>
      <div class="row"><FlareButton label="Small" size="sm" /><FlareButton label="Medium" size="md" /><FlareButton label="Large" size="lg" /></div>
      <div class="row"><FlareButton label="发送" :icon="send" /><FlareButton :label="busy ? '提交中' : '提交'" :loading="busy" @click="go" /><FlareButton label="Disabled" disabled /></div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.row { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
</style>
