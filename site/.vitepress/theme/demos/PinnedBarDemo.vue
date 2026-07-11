<script setup>
import PinnedMessageBar from "flare-core-vue-im-ui/components/messages/PinnedMessageBar.vue";
import DemoStage from "./DemoStage.vue";

const items = [
  {
    serverId: "1",
    clientMsgId: "1",
    senderDisplayName: "Ivy Chen",
    content: { contentType: "text", text: { text: "周五 15:00 设计评审，会议室 A" } },
  },
  {
    serverId: "2",
    clientMsgId: "2",
    senderDisplayName: "Kai",
    content: { contentType: "text", text: { text: "记得提交本周周报" } },
  },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <PinnedMessageBar :items="items" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 420px; }
</style>
