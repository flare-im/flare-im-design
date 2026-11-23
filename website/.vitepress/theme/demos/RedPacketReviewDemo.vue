<script setup>
import { ref } from "vue";
import { FlareRedPacketReview } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// The send confirmation a red packet plugin declares as presentation.renderer "redPacket.review".
const busy = ref(false);
function send() {
  busy.value = true;
  setTimeout(() => { busy.value = false; }, 1200);
}
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareRedPacketReview amount="¥26.64" kind-label="拼手气红包 · 3 个" blessing="恭喜发财，大吉大利" :busy="busy" @submit="send" />
      <FlareRedPacketReview amount="¥8.88" kind-label="普通红包 · 1 个" blessing="生日快乐" error="余额不足，请先充值" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: grid; gap: 24px; max-width: 420px; padding-block: 16px; background: var(--flare-color-bg-secondary); border-radius: 14px; overflow: hidden; }
</style>
