<script setup>
import { ref } from "vue";
import FlareStartConversationDialog from "@flare-im/vue-ui/components/shell/FlareStartConversationDialog.vue";
import DemoStage from "./DemoStage.vue";

const open = ref(false);
</script>

<template>
  <DemoStage>
    <div class="stage">
      <button class="trigger" @click="open = true">发起会话</button>
      <FlareStartConversationDialog v-model:open="open" />
    </div>
  </DemoStage>
</template>

<style scoped>
.trigger { padding: 8px 18px; border-radius: 8px; border: 1px solid var(--flare-color-primary); background: none; color: var(--flare-color-primary); font-size: 14px; cursor: pointer; }
</style>
