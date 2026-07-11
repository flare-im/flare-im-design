<script setup>
import FlareConversationRow from "flare-core-vue-im-ui/components/conversation/FlareConversationRow.vue";
import DemoStage from "./DemoStage.vue";

const item = {
  id: "u2",
  displayName: "Ivy Chen",
  lastMessagePreview: "好的，那我们明天上午同步一下 👍",
  updatedAt: Date.now() - 90000,
  unreadCount: 3,
  pinned: true,
  tags: [{ text: "Official", tone: "warning" }],
};
</script>

<template>
  <DemoStage>
    <div class="row-stage">
      <FlareConversationRow :item="item" />
    </div>
  </DemoStage>
</template>

<style scoped>
.row-stage { width: 100%; max-width: 420px; }
</style>
