<script setup>
import FlareContactDetail from "flare-core-vue-im-ui/components/contacts/FlareContactDetail.vue";
import DemoStage from "./DemoStage.vue";

const contact = {
  id: "u2",
  name: "Ivy Chen",
  signature: "设计即沟通 · 一套契约，四端原生实现",
  presence: "online",
};
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareContactDetail :contact="contact" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
</style>
