<script setup>
import FlareCallView from "@flare-im/vue-ui/components/call/FlareCallView.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareCallView
        peer-name="Ivy Chen"
        mode="video"
        state="connected"
        duration-label="03:24"
        :camera-on="true"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 320px; }
</style>
