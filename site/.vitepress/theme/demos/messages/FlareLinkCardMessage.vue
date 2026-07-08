<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ title: { type: String, default: "链接标题" }, domain: { type: String, default: "example.com" }, thumb: String });
</script>
<template>
  <div class="bubble link">
    <div class="thumb"><img v-if="thumb" :src="thumb" alt="" /><DemoIcon v-else name="image" :size="22" /></div>
    <div class="meta">
      <b>{{ title }}</b>
      <small><DemoIcon name="link" :size="12" />{{ domain }}</small>
    </div>
  </div>
</template>
<style scoped>
.bubble { display: inline-flex; gap: 10px; align-items: center; max-width: 300px; padding: 8px 10px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); }
.thumb { width: 48px; height: 48px; border-radius: 8px; flex: none; overflow: hidden; background: var(--flare-color-bg-tertiary); display: grid; place-items: center; color: var(--flare-color-text-tertiary); }
.thumb img { width: 100%; height: 100%; object-fit: cover; }
.meta { min-width: 0; display: flex; flex-direction: column; gap: 3px; }
.meta b { font-size: 14px; font-weight: 500; color: var(--flare-color-text-primary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.meta small { display: flex; align-items: center; gap: 3px; color: var(--flare-color-text-tertiary); }
</style>
