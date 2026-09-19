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
.fm-loc { display: inline-block; width: 264px; max-width: 100%; border-radius: 16px 16px 16px 4px; overflow: hidden; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: var(--flare-component-bubble-shadow); cursor: pointer; }
.map { height: 84px; display: grid; place-items: center; overflow: hidden; color: var(--flare-color-primary-text); background: color-mix(in srgb, var(--flare-color-primary) 8%, var(--flare-color-bg-tertiary)); }
.map img { width: 100%; height: 100%; object-fit: cover; }
.meta { padding: 8px 12px; display: flex; flex-direction: column; }
.meta b { font-size: 14px; font-weight: 500; color: var(--flare-color-text-primary); }
.meta small { font-size: 11px; color: var(--flare-color-text-tertiary); }
</style>
