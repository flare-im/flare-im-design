<script setup>
import FlareContactList from "flare-core-vue-im-ui/components/contacts/FlareContactList.vue";
import DemoStage from "./DemoStage.vue";

const items = [
  { id: "u1", name: "Henry Ford", signature: "Keep it simple.", presence: "online" },
  { id: "u2", name: "Ivy Chen", signature: "设计即沟通", presence: "busy" },
  { id: "u3", name: "Kai", signature: "在路上", presence: "away" },
  { id: "u4", name: "Mia", signature: "🎧", presence: "offline" },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareContactList :items="items" indexed />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 360px; }
</style>
