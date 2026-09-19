<script setup>
import { ref } from "vue";
import { FlareContactItem } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const opened = ref("");

const people = [
  { id: "u1", name: "Henry Ford", signature: "Keep it simple.", presence: "online" },
  { id: "u2", name: "Ivy Chen", signature: "设计即沟通", presence: "busy" },
  { id: "u3", name: "Kai", signature: "在路上", presence: "away" },
];
</script>

<template>
  <DemoStage>
    <div class="list">
      <FlareContactItem v-for="p in people" :key="p.id" :item="p" show-presence @select="opened = p.id" />
    </div>
  </DemoStage>
</template>

<style scoped>
.list { width: 100%; max-width: 360px; }
</style>
