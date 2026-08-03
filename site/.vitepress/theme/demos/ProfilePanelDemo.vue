<script setup>
import FlareProfilePanel from "@flare-im/vue-ui/components/profile/FlareProfilePanel.vue";
import DemoStage from "./DemoStage.vue";

const user = {
  id: "u2",
  name: "Ivy Chen",
  signature: "设计即沟通",
  flareId: "ivy_chen",
};
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareProfilePanel :user="user" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
</style>
