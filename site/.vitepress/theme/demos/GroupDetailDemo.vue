<script setup>
import FlareGroupDetail from "flare-core-vue-im-ui/components/contacts/FlareGroupDetail.vue";
import DemoStage from "./DemoStage.vue";

const model = {
  groupId: "flare_demo_group",
  name: "设计评审群",
  memberCount: 4,
  announcement: "每周三 14:00 设计评审",
  members: [
    { id: "ivy", name: "Ivy Chen" },
    { id: "leo", name: "Leo Wang" },
    { id: "mia", name: "Mia Zhao" },
    { id: "sam", name: "Sam Li" },
  ],
  ownerId: "ivy",
  adminIds: ["leo"],
  mutedIds: [],
  canManage: true,
  isOwner: true,
  myNickname: "",
  myMuted: false,
  myPinned: false,
  joinPolicy: 2,
  muteAll: false,
  onlyAdminCanAtAll: false,
  onlyAdminCanPin: false,
  shareCardPermission: true,
};
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareGroupDetail :model="model" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage {
  width: 100%;
  max-width: 380px;
  border-radius: 14px;
  overflow: hidden;
  background: var(--flare-color-bg-secondary);
  border: 1px solid var(--flare-color-border-secondary);
}
</style>
