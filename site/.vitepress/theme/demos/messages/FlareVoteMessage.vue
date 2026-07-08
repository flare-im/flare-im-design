<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ title: { type: String, default: "投票" }, options: { type: Array, default: () => [] } });
</script>
<template>
  <div class="bubble vote">
    <div class="vt"><DemoIcon name="poll" :size="16" />{{ title }}</div>
    <div v-for="o in options" :key="o.text" class="opt">
      <div class="bar" :style="{ width: o.pct + '%' }" /><span class="t">{{ o.text }}</span><span class="p">{{ o.pct }}%</span>
    </div>
  </div>
</template>
<style scoped>
.bubble { display: inline-flex; flex-direction: column; gap: 8px; min-width: 220px; padding: 10px 12px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); }
.vt { display: flex; align-items: center; gap: 6px; font-weight: 600; font-size: 14px; color: var(--flare-color-text-primary); }
.opt { position: relative; display: flex; align-items: center; height: 30px; padding: 0 10px; border-radius: 7px; background: var(--flare-color-bg-secondary); overflow: hidden; }
.bar { position: absolute; left: 0; top: 0; bottom: 0; background: color-mix(in srgb, var(--flare-color-primary) 16%, transparent); }
.t { position: relative; flex: 1; font-size: 13px; color: var(--flare-color-text-primary); }
.p { position: relative; font-size: 12px; color: var(--flare-color-text-secondary); font-variant-numeric: tabular-nums; }
</style>
