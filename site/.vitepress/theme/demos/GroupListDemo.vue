<script setup>
import FlareGroupList from "flare-core-vue-im-ui/components/contacts/FlareGroupList.vue";
import DemoStage from "./DemoStage.vue";

const items = [
  { id: "g1", name: "设计评审组", memberCount: 12 },
  { id: "g2", name: "Flare 前端", memberCount: 34 },
  { id: "g3", name: "周会同步", memberCount: 8 },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareGroupList :items="items" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 360px; }
</style>
