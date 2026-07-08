<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ seconds: { type: Number, default: 7 } });
</script>
<template>
  <div class="bubble voice">
    <DemoIcon name="volume" :size="17" />
    <span class="wave"><i v-for="n in 9" :key="n" :style="{ height: 4 + ((n * 5) % 13) + 'px' }" /></span>
    <span class="dur">{{ seconds }}&quot;</span>
  </div>
</template>
<style scoped>
.bubble { display: inline-flex; align-items: center; gap: 8px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); color: var(--flare-color-text-secondary); }
.wave { display: flex; align-items: center; gap: 2px; }
.wave i { width: 2px; border-radius: 2px; background: var(--flare-color-primary); }
.dur { font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
