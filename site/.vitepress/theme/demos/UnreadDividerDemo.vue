<script setup>
import FlareUnreadDivider from "flare-core-vue-im-ui/components/messages/FlareUnreadDivider.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareUnreadDivider :count="6" />
      <FlareUnreadDivider />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { width: 100%; max-width: 460px; display: flex; flex-direction: column; gap: 8px; padding: 16px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
