<script setup>
import { ref } from "vue";
import FlareTimePicker from "@flare-im/vue-ui/components/form/FlareTimePicker.vue";
import DevicePreview from "./DevicePreview.vue";
const t = ref("09:30");
</script>
<template>
  <DevicePreview>
    <div class="tp-demo">
      <label class="lbl">提醒时间</label>
      <FlareTimePicker v-model="t" placeholder="选择时间" title="选择时间" :minute-step="5" />
      <p class="hint">当前:<code>{{ t || "—" }}</code></p>
    </div>
  </DevicePreview>
</template>
<style scoped>
.tp-demo { display: flex; flex-direction: column; gap: 10px; align-items: flex-start; }
.lbl { font-size: 13px; font-weight: 500; color: var(--flare-color-text-secondary); }
.hint { margin: 4px 0 0; font-size: 12px; color: var(--flare-color-text-tertiary); }
.hint code { font-family: var(--vp-font-family-mono); color: var(--flare-color-primary); }
</style>
