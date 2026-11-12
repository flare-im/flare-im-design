<script setup>
import { ref } from "vue";
import { FlareButton, FlareDocumentCapture } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// The camera is the host's; this demo has none, so it offers the album only. The kit re-encodes the chosen photo
// without metadata and within maxBytes.
const open = ref(false);
const side = ref("front");
const result = ref("");
function pickPhoto() {
  return new Promise((resolve) => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/*";
    input.onchange = () => resolve(input.files?.[0] ?? null);
    input.click();
  });
}
function done(file) {
  result.value = `${file.fileName} · ${(file.bytes.length / 1024).toFixed(0)} KiB`;
  open.value = false;
}
</script>
<template>
  <DemoStage>
    <div class="row">
      <FlareButton label="证件正面" @click="side = 'front'; open = true" />
      <FlareButton label="手持证件" variant="secondary" @click="side = 'holding'; open = true" />
    </div>
    <p v-if="result" class="log">{{ result }}</p>
    <FlareDocumentCapture
      :open="open"
      :side="side"
      :max-bytes="1048576"
      :accept="['image/jpeg']"
      camera-unavailable
      :pick-photo="pickPhoto"
      @done="done"
      @cancel="open = false"
    />
  </DemoStage>
</template>
<style scoped>
.row { display: flex; flex-wrap: wrap; gap: 8px; }
.log { margin: 12px 0 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
</style>
