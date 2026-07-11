<script setup>
import FlareMessageActionSheet from "flare-core-vue-im-ui/components/composer/MessageActionSheet.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareMessageActionSheet />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 420px; }
</style>
