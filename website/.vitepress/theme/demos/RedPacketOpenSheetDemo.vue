<script setup>
import { onBeforeUnmount, ref } from "vue";
import { FlareButton, FlareRedPacketOpenSheet } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 宿主把服务端结论换成 state：点「開」进入 opening 并调 claim，这里用定时器模拟结果。
const open = ref(false);
const state = ref("ready");
const message = ref("");
let timer;
onBeforeUnmount(() => clearTimeout(timer));
function show(next) {
  clearTimeout(timer);
  state.value = next;
  message.value = next === "notEligible" ? "仅 TA 可领取" : next === "error" ? "网络暂时不可用，请重试" : "";
  open.value = true;
}
function claim() {
  clearTimeout(timer);
  message.value = "";
  state.value = "opening";
  timer = setTimeout(() => {
    state.value = "finished";
  }, 1500);
}
</script>
<template>
  <DemoStage>
    <div class="row">
      <FlareButton label="可领取" @click="show('ready')" />
      <FlareButton label="已领完" variant="secondary" @click="show('finished')" />
      <FlareButton label="已过期" variant="secondary" @click="show('expired')" />
      <FlareButton label="已退回" variant="secondary" @click="show('refunded')" />
      <FlareButton label="领取失败" variant="secondary" @click="show('error')" />
      <FlareButton label="专属他人" variant="secondary" @click="show('notEligible')" />
    </div>
    <FlareRedPacketOpenSheet
      :open="open"
      sender-name="小明"
      blessing="恭喜发财，大吉大利"
      kind-label="拼手气红包"
      :state="state"
      :message="message"
      @open="claim"
      @view-details="open = false"
      @close="open = false"
    />
  </DemoStage>
</template>
<style scoped>
.row { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); }
</style>
