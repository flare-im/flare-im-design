<script setup>
import FlareTypingIndicator from "@flare-im/vue-ui/components/messages/FlareTypingIndicator.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareTypingIndicator user-id="ivy" />
      <FlareTypingIndicator user-id="leo" :names="['Leo Wang']" />
      <FlareTypingIndicator :names="['Ivy', 'Leo', 'Mia']" />
      <FlareTypingIndicator variant="inline" :names="['Ivy Chen']" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; flex-direction: column; gap: 16px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); align-items: flex-start; }
</style>
