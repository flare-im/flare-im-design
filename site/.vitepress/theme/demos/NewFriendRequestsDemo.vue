<script setup>
import FlareNewFriendRequests from "flare-core-vue-im-ui/components/contacts/FlareNewFriendRequests.vue";
import DemoStage from "./DemoStage.vue";

const items = [
  { id: "r1", name: "Ivy Chen", message: "我是 Ivy，一起做设计～" },
  { id: "r2", name: "Kai", message: "在群里看到你，加个好友" },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareNewFriendRequests :items="items" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 360px; }
</style>
