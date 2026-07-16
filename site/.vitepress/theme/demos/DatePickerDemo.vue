<script setup>
import { ref } from "vue";
import FlareDatePicker from "flare-core-vue-im-ui/components/form/FlareDatePicker.vue";
import DevicePreview from "./DevicePreview.vue";
const d = ref("2026-07-16");
</script>
<template>
  <DevicePreview>
    <div class="dp-demo">
      <label class="lbl">截止日期</label>
      <FlareDatePicker v-model="d" placeholder="选择日期" title="选择日期" />
      <p class="hint">当前:<code>{{ d || "—" }}</code></p>
    </div>
  </DevicePreview>
</template>
<style scoped>
.dp-demo { display: flex; flex-direction: column; gap: 10px; align-items: flex-start; }
.lbl { font-size: 13px; font-weight: 500; color: var(--flare-color-text-secondary); }
.hint { margin: 4px 0 0; font-size: 12px; color: var(--flare-color-text-tertiary); }
.hint code { font-family: var(--vp-font-family-mono); color: var(--flare-color-primary); }
</style>
