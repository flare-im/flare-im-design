<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
// Presentational — emits `play`; the host opens the player.
withDefaults(defineProps<{ poster?: string; duration?: string; alt?: string }>(), { duration: "00:00", alt: "" });
const emit = defineEmits<{ (e: "play"): void }>();
</script>
<template>
  <button class="fm-video" @click="emit('play')">
    <img v-if="poster" :src="poster" :alt="alt" />
    <MsgIcon v-else name="video" :size="24" class="ph" />
    <span class="play"><MsgIcon name="play" :size="30" /></span>
    <span class="dur">{{ duration }}</span>
  </button>
</template>
<style scoped>
.fm-video { padding: 0; border: none; position: relative; width: 148px; height: 92px; border-radius: 12px; overflow: hidden; background: var(--im-bg-surface-alt, #f2f3f5); display: grid; place-items: center; cursor: pointer; }
.fm-video img { width: 100%; height: 100%; object-fit: cover; }
.ph { opacity: .5; color: var(--im-text-tertiary, #a3a7ae); }
.play { position: absolute; inset: 0; display: grid; place-items: center; color: #fff; background: rgba(0,0,0,.28); }
.dur { position: absolute; right: 6px; bottom: 5px; font-size: 10px; color: #fff; background: rgba(0,0,0,.45); padding: 1px 5px; border-radius: 5px; font-variant-numeric: tabular-nums; }
</style>
