<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ title: { type: String, default: "位置" }, address: { type: String, default: "" } });
</script>
<template>
  <div class="bubble loc">
    <div class="map"><DemoIcon name="location" :size="22" /></div>
    <div class="meta"><b>{{ title }}</b><small>{{ address }}</small></div>
  </div>
</template>
<style scoped>
.bubble { display: inline-block; width: 264px; max-width: 100%; border-radius: 16px 16px 16px 4px; overflow: hidden; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); }
.map { height: 84px; display: grid; place-items: center; color: var(--flare-color-primary); background: color-mix(in srgb, var(--flare-color-primary) 8%, var(--flare-color-bg-tertiary)); }
.meta { padding: 8px 12px; display: flex; flex-direction: column; }
.meta b { font-size: 14px; font-weight: 500; color: var(--flare-color-text-primary); }
.meta small { font-size: 11px; color: var(--flare-color-text-tertiary); }
</style>
