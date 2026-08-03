<script setup>
import FlarePollComposer from "@flare-im/vue-ui/components/composer/FlarePollComposer.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlarePollComposer @submit="() => {}" @cancel="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
