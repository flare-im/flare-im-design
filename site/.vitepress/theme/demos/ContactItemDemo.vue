<script setup>
import FlareContactItem from "flare-core-vue-im-ui/components/contacts/FlareContactItem.vue";
import DemoStage from "./DemoStage.vue";

const people = [
  { id: "u1", name: "Henry Ford", signature: "Keep it simple.", presence: "online" },
  { id: "u2", name: "Ivy Chen", signature: "设计即沟通", presence: "busy" },
  { id: "u3", name: "Kai", signature: "在路上", presence: "away" },
];
</script>

<template>
  <DemoStage>
    <div class="list">
      <FlareContactItem v-for="p in people" :key="p.id" :item="p" show-presence />
    </div>
  </DemoStage>
</template>

<style scoped>
.list { width: 100%; max-width: 360px; }
</style>
