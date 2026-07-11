<script setup>
import FlareCallControls from "flare-core-vue-im-ui/components/call/FlareCallControls.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareCallControls mode="video" :camera-on="true" :speaker-on="true" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 360px; display: flex; justify-content: center; }
</style>
