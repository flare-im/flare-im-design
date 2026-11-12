<script setup>
import { ref } from "vue";
import { FlareButton, FlareCapabilityConsent } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// The host shows this for the engine's consent request; the choice goes back as {granted}, and "once" is revoked
// after the request.
const asks = {
  证件拍摄: { pluginName: "实名认证", capability: "documentCapture", purpose: "拍摄身份证件用于实名认证" },
  一次定位: { pluginName: "签到", capability: "locationOnce", params: { precision: "coarse" } },
};
const current = ref(null);
const log = ref("");
function decide(decision) {
  log.value = decision;
  current.value = null;
}
</script>
<template>
  <DemoStage>
    <div class="row">
      <FlareButton v-for="(ask, name) in asks" :key="name" :label="name" variant="secondary" @click="current = ask" />
    </div>
    <p v-if="log" class="log">decide: {{ log }}</p>
    <FlareCapabilityConsent v-if="current" :open="Boolean(current)" v-bind="current" @decide="decide" />
  </DemoStage>
</template>
<style scoped>
.row { display: flex; flex-wrap: wrap; gap: 8px; }
.log { margin: 12px 0 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
</style>
