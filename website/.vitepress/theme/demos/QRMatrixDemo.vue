<script setup lang="ts">
import { FlareQrMatrix } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const payload = "https://scan.flare.test/u/vYy5hW5dKbiV8aZraFR4rA";
</script>

<template>
  <DemoStage>
    <div class="qr-matrix-demo">
      <FlareQrMatrix :payload="payload" label="Ivy Chen contact code" />
    </div>
  </DemoStage>
</template>

<style scoped>
.qr-matrix-demo {
  width: min(100%, 240px);
  margin-inline: auto;
}
</style>
