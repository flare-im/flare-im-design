<script setup>
import { ref } from "vue";
import { FlareScanViewfinder, FlareFilterTabs } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const state = ref("choosing");
const last = ref("");
const options = ["live", "choosing", "denied", "cameraBusy", "noCamera"].map(value => ({ value, label: value }));
const markers = [{ id: "first", corners: [{ x: .1, y: .15 }, { x: .43, y: .48 }] }, { id: "second", corners: [{ x: .56, y: .42 }, { x: .89, y: .75 }] }];
</script>
<template>
  <DemoStage><div class="scan-demo">
    <FlareFilterTabs v-model="state" :options="options" />
    <div class="scan-demo__view"><FlareScanViewfinder :state="state" :markers="state === 'choosing' ? markers : []" :capabilities="{ live: true, album: true, paste: true, myCode: true, torch: true }" @close="last = 'close'" @select-marker="id => last = `selected ${id}`" @pick-image="last = 'pick image'" @paste="last = 'paste'" @open-my-code="last = 'my code'" @toggle-torch="last = 'torch'" @request-permission="last = 'request permission'" @retry="last = 'retry'"><template #preview><div class="scan-demo__preview" /></template></FlareScanViewfinder></div>
    <p role="status">{{ last }}</p>
  </div></DemoStage>
</template>
<style scoped>
.scan-demo { width: 100%; display: grid; gap: var(--flare-size-spacing-md); }
.scan-demo__view { height: 520px; border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-lg); overflow: hidden; }
.scan-demo__preview { width: 100%; height: 100%; background: var(--flare-color-bg-secondary); }
</style>
