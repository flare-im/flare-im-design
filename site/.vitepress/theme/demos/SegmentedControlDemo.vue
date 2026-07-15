<script setup>
import { ref } from "vue";
import FlareSegmentedControl from "flare-core-vue-im-ui/components/general/FlareSegmentedControl.vue";
import DemoStage from "./DemoStage.vue";
const tab = ref(0);
const labels = ["联系人", "群组", "新的联系人"];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareSegmentedControl v-model="tab" :options="labels" />
      <p class="hint">当前:{{ labels[tab] }}</p>
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 28px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.hint { margin: 0; font-size: 13px; color: var(--flare-color-text-tertiary); }
</style>
