<script setup>
import FlareComposer from "flare-core-vue-im-ui/components/composer/EnhancedComposer.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareComposer target-name="Ivy Chen" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; }
</style>
