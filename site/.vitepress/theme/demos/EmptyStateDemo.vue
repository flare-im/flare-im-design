<script setup>
import FlareEmptyState from "flare-core-vue-im-ui/components/general/FlareEmptyState.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <FlareEmptyState
      title="还没有会话"
      description="发起一个聊天，或从通讯录里找人开始对话。"
      action-text="发起聊天"
      icon="chats"
    />
  </DemoStage>
</template>
