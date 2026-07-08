<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ title: { type: String, default: "任务" }, meta: String, done: Boolean });
</script>
<template>
  <div class="bubble task">
    <span class="box" :class="{ done }"><DemoIcon v-if="done" name="check" :size="13" /></span>
    <span class="meta"><b :class="{ done }">{{ title }}</b><small v-if="meta">{{ meta }}</small></span>
  </div>
</template>
<style scoped>
.bubble { display: inline-flex; align-items: center; gap: 10px; min-width: 220px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); }
.box { width: 20px; height: 20px; border-radius: 6px; flex: none; display: grid; place-items: center; border: 1.5px solid var(--flare-color-border-primary); }
.box.done { background: var(--flare-color-primary); border-color: var(--flare-color-primary); color: #fff; }
.meta { flex: 1; display: flex; flex-direction: column; }
.meta b { font-size: 14px; font-weight: 500; color: var(--flare-color-text-primary); }
.meta b.done { text-decoration: line-through; color: var(--flare-color-text-tertiary); }
.meta small { font-size: 11px; color: var(--flare-color-text-tertiary); }
</style>
