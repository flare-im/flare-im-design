<script setup>
import { ref } from "vue";
import { FlareRedPacketPage } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// What FlarePluginPage draws for a page whose view names presentation.renderer "redPacket.compose" (the inputs and
// the bound send key come from the plugin's page) and "redPacket.review" (its confirm page).
const busy = ref("");
const compose = {
  available: true, title: "发红包", fields: [],
  presentation: { renderer: "redPacket.compose", props: { maxRecipients: 100 }, actions: { submit: "prepare" } },
  actions: [{ id: "prepare", label: "塞钱进红包", form: ["kind", "amount", "shareCount", "greeting"] }],
  inputs: [
    { id: "kind", kind: "select", label: "红包类型", required: true, default: "lucky", choices: [{ value: "lucky", label: "拼手气" }, { value: "normal", label: "普通红包" }, { value: "exclusive", label: "专属红包" }] },
    { id: "amount", kind: "money", label: "金额", required: true, money: { currency: "CNY", scale: 2, min: "0.01", max: "200.00" } },
    { id: "shareCount", kind: "number", label: "份数", required: true, min: 1, max: 100, default: 1 },
    { id: "greeting", kind: "text", label: "祝福语", required: true, default: "恭喜发财，大吉大利" },
  ],
};
const review = {
  available: true, title: "发送红包", fields: [],
  presentation: { renderer: "redPacket.review", props: { amount: "26.64", currency: "CNY", kind: "lucky", shareCount: 3, blessing: "恭喜发财，大吉大利" }, actions: { submit: "commit" } },
  actions: [{ id: "commit", label: "发红包" }],
};
const members = [{ userId: "u1", name: "苏晚晴" }, { userId: "u2", name: "周屿" }, { userId: "u3", name: "林川" }];
function run(id) {
  busy.value = id;
  setTimeout(() => { busy.value = ""; }, 1200);
}
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareRedPacketPage :view="compose" :members="members" :busy-action-id="busy || undefined" :on-action="run" />
      <FlareRedPacketPage :view="review" :busy-action-id="busy || undefined" :on-action="run" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: grid; gap: 24px; max-width: 420px; padding-block: 16px; background: var(--flare-color-bg-secondary); border-radius: 14px; overflow: hidden; }
</style>
