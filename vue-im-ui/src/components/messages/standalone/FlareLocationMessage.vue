<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
// Presentational — emits `open`; the host opens the map.
withDefaults(defineProps<{ title?: string; address?: string; mapImage?: string }>(), { title: "location", address: "" });
const emit = defineEmits<{ (e: "open"): void }>();
</script>
<template>
  <div class="fm-loc" @click="emit('open')">
    <div class="map">
      <img v-if="mapImage" :src="mapImage" alt="" />
      <MsgIcon v-else name="location" :size="22" />
    </div>
    <div class="meta"><b>{{ title }}</b><small>{{ address }}</small></div>
  </div>
</template>
<style scoped>
.fm-loc { display: inline-block; width: 264px; max-width: 100%; border-radius: 16px 16px 16px 4px; overflow: hidden; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, #eef0f4); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); cursor: pointer; }
.map { height: 84px; display: grid; place-items: center; overflow: hidden; color: var(--im-primary, #7c3aed); background: color-mix(in srgb, var(--im-primary, #7c3aed) 8%, var(--im-bg-surface-alt, #f2f3f5)); }
.map img { width: 100%; height: 100%; object-fit: cover; }
.meta { padding: 8px 12px; display: flex; flex-direction: column; }
.meta b { font-size: 14px; font-weight: 500; color: var(--im-text-primary, #111318); }
.meta small { font-size: 11px; color: var(--im-text-tertiary, #a3a7ae); }
</style>
