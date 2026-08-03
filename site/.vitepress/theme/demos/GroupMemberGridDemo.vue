<script setup>
import FlareGroupMemberGrid from "@flare-im/vue-ui/components/contacts/FlareGroupMemberGrid.vue";
import DemoStage from "./DemoStage.vue";
const members = [
  { id: "ivy", name: "Ivy Chen" }, { id: "leo", name: "Leo Wang" },
  { id: "mia", name: "Mia Zhao" }, { id: "sam", name: "Sam Li" },
  { id: "amy", name: "Amy Xu" }, { id: "ken", name: "Ken Zhou" },
  { id: "me", name: "我" },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareGroupMemberGrid :members="members" owner-id="ivy" :admin-ids="['leo']" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { width: 100%; max-width: 420px; border-radius: 14px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); }
</style>
