<script setup>
import { computed } from "vue";
import { FlareRedPacketDetail } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 详情是普通页面的正文；宿主把它放进 FlareScreen。服务端按查看者裁剪：只有发送人拿到总额，本人金额只给本人，
// 非指定人什么金额都没有。Kit 只画给到的字段，金额按 currencyExponent 格式化。
const props = defineProps({ previewState: { type: String, default: "sender" } });
const now = Date.now();
const base = { kind: "lucky", greeting: "恭喜发财，大吉大利", currency: "CNY", currencyExponent: 2, shareCount: 3, createdAtMs: now - 60_000, expiresAtMs: now + 86_400_000 };
const views = {
  sender: { ...base, viewerRole: "sender", status: "completed", totalMinor: "210", claimedMinor: "210", claimedCount: 3, completedAtMs: now - 15_000, claimsListed: true },
  claimer: { ...base, viewerRole: "claimer", status: "open", myAmountMinor: "88", claimedCount: 2, claimsListed: true },
  eligible: { ...base, viewerRole: "eligible", status: "completed", claimedCount: 3, completedAtMs: now - 15_000, claimsListed: true },
  ineligible: { ...base, kind: "exclusive", shareCount: 1, viewerRole: "ineligible", status: "open", claimedCount: 0, claimsListed: false },
  empty: { ...base, viewerRole: "sender", status: "open", totalMinor: "210", claimedMinor: "0", claimedCount: 0, claimsListed: true },
};
const details = computed(() => views[props.previewState] ?? views.sender);
const claims = computed(() => (props.previewState === "empty" ? [] : [
  { id: "u1", name: "阿花", amountMinor: "62", claimedAtMs: now - 50_000, best: false },
  { id: "u2", name: "大壮", amountMinor: "88", claimedAtMs: now - 40_000, best: true },
  { id: "u3", name: "小红", amountMinor: "60", claimedAtMs: now - 20_000, best: false },
]));
</script>
<template>
  <DemoStage>
    <div class="frame">
      <FlareRedPacketDetail sender-name="小明" :details="details" designated-name="Bob" :claims="claims" @back="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.frame { max-width: 390px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; overflow: hidden; }
</style>
