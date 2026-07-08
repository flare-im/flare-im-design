<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
withDefaults(defineProps<{ title?: string; meta?: string; done?: boolean }>(), { title: "task" });
</script>
<template>
  <div class="fm-task">
    <span class="box" :class="{ done }"><MsgIcon v-if="done" name="check" :size="13" /></span>
    <span class="meta"><b :class="{ done }">{{ title }}</b><small v-if="meta">{{ meta }}</small></span>
  </div>
</template>
<style scoped>
.fm-task { display: inline-flex; align-items: center; gap: 10px; min-width: 220px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, #eef0f4); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); }
.box { width: 20px; height: 20px; border-radius: 6px; flex: none; display: grid; place-items: center; border: 1.5px solid var(--im-border, #e7e9ee); }
.box.done { background: var(--im-primary, #7c3aed); border-color: var(--im-primary, #7c3aed); color: #fff; }
.meta { flex: 1; display: flex; flex-direction: column; }
.meta b { font-size: 14px; font-weight: 500; color: var(--im-text-primary, #111318); }
.meta b.done { text-decoration: line-through; color: var(--im-text-tertiary, #a3a7ae); }
.meta small { font-size: 11px; color: var(--im-text-tertiary, #a3a7ae); }
</style>
