<script setup>
import FlareProfileCard from "flare-core-vue-im-ui/components/profile/FlareProfileCard.vue";
import DemoStage from "./DemoStage.vue";
const user = {
  id: "flare_ivy", name: "Ivy Chen", presence: "online",
  signature: "设计即沟通 · 一套契约，四端原生实现",
  region: "上海", tags: ["设计", "评审组"],
};
</script>
<template>
  <DemoStage>
    <div class="stage"><FlareProfileCard :user="user" /></div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
