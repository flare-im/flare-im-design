<script setup>
import FlareTopicChip from "@flare-im/vue-ui/components/moments/FlareTopicChip.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <p>今天去看了展 <FlareTopicChip topic="城市漫步" @click="() => {}" /> 顺手拍了几张 <FlareTopicChip topic="随手拍" @click="() => {}" /></p>
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.stage p { margin: 0; font-size: 15px; line-height: 1.6; color: var(--flare-color-text-primary); }
</style>
