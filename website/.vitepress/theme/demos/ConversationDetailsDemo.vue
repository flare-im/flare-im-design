<script setup>
import { FlareConversationDetails } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const conversation = { conversationId: "c1", displayName: "设计评审组", conversationKind: "group" };
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareConversationDetails
        :conversation="conversation"
        connection-text="已连接"
        tone="success"
        :message-count="128"
        latest-message-id="m_128"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 360px; }
</style>
