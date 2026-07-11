<script setup>
import FlareAvatar from "flare-core-vue-im-ui/components/conversation/FlareAvatar.vue";
import DemoStage from "./DemoStage.vue";

const people = [
  { id: "u1", name: "Henry Ford", status: "online" },
  { id: "u2", name: "Ivy Chen", status: "busy" },
  { id: "u3", name: "Kai", status: "busy" },
  { id: "u4", name: "Team Flare", status: null },
];
</script>

<template>
  <DemoStage>
    <div class="av-row">
      <FlareAvatar
        v-for="p in people"
        :key="p.id"
        :user-id="p.id"
        :display-name="p.name"
        :size="42"
        :show-status="!!p.status"
        :status="p.status || 'offline'"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.av-row { display: flex; gap: 14px; align-items: center; }
</style>
