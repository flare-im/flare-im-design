<script setup>
import FlareReadReceiptSheet from "@flare-im/vue-ui/components/messages/FlareReadReceiptSheet.vue";
import DemoStage from "./DemoStage.vue";
const readers = [
  { id: "ivy", name: "Ivy Chen", presence: "online" },
  { id: "leo", name: "Leo Wang" },
  { id: "ada", name: "Ada Li" },
];
const unread = [
  { id: "mia", name: "Mia Zhou" },
  { id: "sam", name: "Sam Gao" },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareReadReceiptSheet :readers="readers" :unread="unread" dismissible />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
