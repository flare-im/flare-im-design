<script setup>
import { ref } from "vue";
import { FlareProfilePanel } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const user = {
  id: "u2",
  name: "Ivy Chen",
  signature: "设计即沟通",
  flareId: "ivy_chen",
};
// The identity and the QR button are controls because the demo handles both intents.
const lastIntent = ref("");
const show = (name) => { lastIntent.value = name; };
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareProfilePanel :user="user" @edit="show('edit')" @qr="show('qr')" @action="(item) => show(item.key)" />
      <p class="intent" role="status">{{ lastIntent }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
.intent { min-height: 1.5em; margin: 8px 0 0; color: var(--flare-color-text-secondary); font-size: 13px; text-align: center; }
</style>
