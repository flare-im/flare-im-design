<script setup>
import { ref } from "vue";
import FlareScrollToLatest from "flare-core-vue-im-ui/components/messages/FlareScrollToLatest.vue";
import DemoStage from "./DemoStage.vue";
const count = ref(3);
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareScrollToLatest :count="count" @click="count = 0" />
      <FlareScrollToLatest :count="0" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; gap: 20px; align-items: center; padding: 28px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
