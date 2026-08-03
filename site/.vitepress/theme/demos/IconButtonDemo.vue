<script setup>
import { NIcon } from "naive-ui";
import { SearchOutline, HeartOutline, EllipsisHorizontal } from "@vicons/ionicons5";
import FlareIconButton from "@flare-im/vue-ui/components/general/FlareIconButton.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stack">
      <div class="row"><FlareIconButton :icon="SearchOutline" aria-label="搜索" variant="plain" /><FlareIconButton :icon="HeartOutline" aria-label="喜欢" variant="tinted" /><FlareIconButton :icon="EllipsisHorizontal" aria-label="更多" variant="solid" /><FlareIconButton :icon="HeartOutline" aria-label="已选" active /></div>
      <div class="row"><FlareIconButton :icon="SearchOutline" aria-label="小" size="sm" variant="tinted" /><FlareIconButton :icon="SearchOutline" aria-label="中" size="md" variant="tinted" /><FlareIconButton :icon="SearchOutline" aria-label="大" size="lg" variant="tinted" /><FlareIconButton :icon="SearchOutline" aria-label="方" shape="square" variant="tinted" /></div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.row { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }
</style>
