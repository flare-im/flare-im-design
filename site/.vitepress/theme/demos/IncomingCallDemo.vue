<script setup>
import FlareIncomingCall from "@flare-im/vue-ui/components/call/FlareIncomingCall.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareIncomingCall caller-name="Ivy Chen" mode="video" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 320px; }
</style>
