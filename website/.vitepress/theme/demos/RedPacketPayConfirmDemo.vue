<script setup>
import { ref } from "vue";
import { FlareButton, FlareRedPacketPayConfirm } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 余额是否足够由宿主判定；busy 期间两个按钮和所有关闭方式都锁定。
const open = ref(false);
const insufficient = ref(false);
const busy = ref(false);
function show(short) {
  insufficient.value = short;
  open.value = true;
}
function pay() {
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
      <FlareButton label="余额充足" @click="show(false)" />
      <FlareButton label="余额不足" variant="secondary" @click="show(true)" />
    </div>
    <FlareRedPacketPayConfirm
      :open="open"
      amount="¥8.88"
      :method-label="insufficient ? '钱包（余额 ¥5.00）' : '钱包（余额 ¥12.00）'"
      :insufficient="insufficient"
      :busy="busy"
      @confirm="pay"
      @cancel="open = false"
    />
  </DemoStage>
</template>
<style scoped>
.row { display: flex; flex-wrap: wrap; gap: 8px; }
</style>
