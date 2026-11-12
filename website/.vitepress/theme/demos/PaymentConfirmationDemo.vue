<script setup>
import { ref } from "vue";
import { FlareButton, FlarePaymentConfirmation } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// The host shows this for the engine's confirmPayment request. Verifying the viewer is the host's reauthenticate
// flow; here a short timer stands in for it.
const open = ref(false);
const busy = ref(false);
const order = ref(null);
function show(seconds) {
  order.value = { orderId: "rp-20261113-0042", amount: "88.80", currency: "CNY", payee: "钱包", title: "红包", expiresAtMs: Date.now() + seconds * 1000 };
  open.value = true;
}
function confirm() {
  busy.value = true;
  setTimeout(() => {
    busy.value = false;
    open.value = false;
  }, 1200);
}
</script>
<template>
  <DemoStage>
    <div class="row">
      <FlareButton label="确认付款" @click="show(120)" />
      <FlareButton label="即将失效" variant="secondary" @click="show(5)" />
    </div>
    <FlarePaymentConfirmation
      v-if="order"
      :open="open"
      :order="order"
      plugin-name="红包"
      :busy="busy"
      @confirm="confirm"
      @cancel="open = false"
    />
  </DemoStage>
</template>
<style scoped>
.row { display: flex; flex-wrap: wrap; gap: 8px; }
</style>
