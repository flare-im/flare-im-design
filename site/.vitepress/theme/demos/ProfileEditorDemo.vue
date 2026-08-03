<script setup>
import FlareProfileEditor from "@flare-im/vue-ui/components/profile/FlareProfileEditor.vue";
import DemoStage from "./DemoStage.vue";

const user = {
  id: "me",
  name: "Ivy Chen",
  signature: "设计即沟通",
  flareId: "ivy_chen",
};
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareProfileEditor :user="user" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 400px; }
</style>
