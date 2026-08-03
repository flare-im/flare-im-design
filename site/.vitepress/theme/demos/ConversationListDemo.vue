<script setup>
import FlareConversationList from "@flare-im/vue-ui/components/conversation/FlareConversationList.vue";
import DemoStage from "./DemoStage.vue";

const now = Date.now();
const items = [
  { id: "c1", displayName: "Ivy Chen", lastMessagePreview: "好的，那我们明天上午同步一下 👍", updatedAt: now - 90000, unreadCount: 3, pinned: true },
  { id: "c2", displayName: "设计评审组", lastMessagePreview: "Kai: 新稿已上传", updatedAt: now - 3600000, unreadCount: 0 },
  { id: "c3", displayName: "Henry Ford", lastMessagePreview: "[图片]", updatedAt: now - 86400000, draft: "回头看下" },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareConversationList :items="items" active-id="c1" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
</style>
