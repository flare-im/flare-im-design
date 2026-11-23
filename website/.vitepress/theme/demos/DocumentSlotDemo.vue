<script setup>
import { ref } from "vue";
import { FlareDocumentSlot } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// The capture tiles of a "check and submit" page: each one is the native entry of a document input.
const photo = "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 100"><rect width="160" height="100" fill="#c9d3e0"/><rect x="104" y="20" width="40" height="52" rx="4" fill="#8fa1b8"/><rect x="16" y="24" width="72" height="8" rx="4" fill="#8fa1b8"/><rect x="16" y="44" width="56" height="8" rx="4" fill="#8fa1b8"/></svg>');
const front = ref("empty");
function capture() {
  front.value = "uploading";
  setTimeout(() => { front.value = "captured"; }, 1200);
}
</script>
<template>
  <DemoStage>
    <div class="grid">
      <FlareDocumentSlot label="证件正面" side="front" :state="front" :image-url="front === 'empty' ? undefined : photo" :progress="60" @capture="capture" />
      <FlareDocumentSlot label="证件反面" side="back" />
      <FlareDocumentSlot label="本人手持证件" side="holding" />
      <FlareDocumentSlot label="证件反面" side="back" state="failed" :image-url="photo" />
    </div>
  </DemoStage>
</template>
<style scoped>
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 12px; max-width: 600px; }
</style>
