<script setup>
import FlareIcon from "flare-core-vue-im-ui/components/general/FlareIcon.vue";
import { flareIconNames } from "flare-core-vue-im-ui/shared/icons";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="grid">
      <div v-for="n in flareIconNames" :key="n" class="cell">
        <FlareIcon :name="n" :size="22" />
        <span class="name">{{ n }}</span>
      </div>
    </div>
  </DemoStage>
</template>
<style scoped>
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(84px, 1fr)); gap: 4px; padding: 16px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.cell { display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 12px 4px; border-radius: 10px; color: var(--flare-color-text-primary); transition: background 0.15s ease; }
.cell:hover { background: var(--flare-color-bg-primary); }
.name { font-size: 10px; color: var(--flare-color-text-tertiary); text-align: center; word-break: break-all; }
</style>
