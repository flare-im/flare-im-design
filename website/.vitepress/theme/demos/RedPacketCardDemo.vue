<script setup>
import { ref } from "vue";
import { FlareRedPacketCard } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 卡片永不显示金额：祝福语、类型角标、专属的「给 某某」和一行状态。状态由插件公开层与本人层得出
// （flareRedPacketCardState）：领取红包 / 查看红包（发送人或非指定人）饱和；已领取 / 已被领完 / 已过期 /
// 已退回变淡，仍可点开。处理中和不可用保持未领取的外观，只换状态行，不可点。
const state = ref("unopened");
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareRedPacketCard
        blessing="恭喜发财，大吉大利"
        kind="lucky"
        :state="state"
        @open="state = state === 'unopened' ? 'claimed' : 'unopened'"
      />
      <FlareRedPacketCard blessing="生日快乐" kind="exclusive" recipient-name="Bob" state="viewable" />
      <FlareRedPacketCard blessing="新年快乐" kind="lucky" state="finished" />
      <FlareRedPacketCard blessing="出差辛苦" state="expired" />
      <FlareRedPacketCard blessing="谢谢你" kind="exclusive" recipient-name="Carol" state="refunded" />
      <FlareRedPacketCard blessing="恭喜发财" busy />
      <FlareRedPacketCard blessing="恭喜发财" disabled />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 14px; align-items: flex-start; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
