<script setup>
import { ref } from "vue";
import { FlareRedPacketCard } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 状态按「当前查看者」推导：未领取饱和；已领取 / 已被领完 / 已过期整体变淡，仍可点开看详情。
// 处理中和不可用保持未领取的外观，只换状态行，不可点。
const state = ref("unopened");
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareRedPacketCard
        blessing="恭喜发财，大吉大利"
        kind-label="拼手气红包"
        :state="state"
        amount="0.88 元"
        @open="state = state === 'unopened' ? 'claimed' : 'unopened'"
      />
      <FlareRedPacketCard blessing="新年快乐" kind-label="拼手气红包" state="finished" />
      <FlareRedPacketCard blessing="生日快乐" state="expired" />
      <FlareRedPacketCard blessing="恭喜发财" busy />
      <FlareRedPacketCard blessing="恭喜发财" status-label="待领取" disabled />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 14px; align-items: flex-start; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
