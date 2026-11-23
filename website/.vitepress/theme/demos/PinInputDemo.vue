<script setup>
import { ref } from "vue";
import { FlarePinInput, FlareButton } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const pin = ref("");
const wrong = ref(false);
const verified = ref("");
// The demo treats 123456 as the right PIN; anything else shakes and clears.
function complete(value) {
  wrong.value = value !== "123456";
  verified.value = wrong.value ? "" : value;
}
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlarePinInput v-model="pin" label="支付密码" :error="wrong" :auto-focus="false" @update:model-value="wrong = false" @complete="complete" />
      <p class="hint">{{ verified ? "已验证" : "输入 123456 通过，其他数字会抖动并清空" }}</p>
      <FlareButton variant="secondary" size="sm" label="清空" @click="pin = ''; wrong = false; verified = ''" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; align-items: flex-start; gap: var(--flare-size-spacing-lg); padding: var(--flare-size-spacing-2xl); border-radius: var(--flare-size-radius-xl); background: var(--flare-color-bg-secondary); }
.hint { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-tertiary); }
</style>
