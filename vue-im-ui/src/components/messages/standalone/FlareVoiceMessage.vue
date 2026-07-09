<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
// Presentational — emits `play`; `playing` drives the active look. The host owns
// the audio source and playback.
withDefaults(defineProps<{ seconds?: number; playing?: boolean }>(), { seconds: 1, playing: false });
const emit = defineEmits<{ (e: "play"): void }>();
</script>
<template>
  <button class="fm-voice" :class="{ playing }" @click="emit('play')">
    <MsgIcon :name="playing ? 'volume' : 'play'" :size="17" />
    <span class="wave"><i v-for="n in 9" :key="n" :style="{ height: 4 + ((n * 5) % 13) + 'px' }" /></span>
    <span class="dur">{{ seconds }}&quot;</span>
  </button>
</template>
<style scoped>
.fm-voice { border: 1px solid var(--im-border-subtle, var(--flare-color-border-secondary, #eef0f4)); display: inline-flex; align-items: center; gap: 8px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); color: var(--im-text-secondary, var(--flare-color-text-secondary, #6b7280)); cursor: pointer; }
.fm-voice.playing { color: var(--im-primary, var(--flare-color-primary, #7c3aed)); }
.wave { display: flex; align-items: center; gap: 2px; }
.wave i { width: 2px; border-radius: 2px; background: var(--im-primary, var(--flare-color-primary, #7c3aed)); }
.dur { font-size: 12px; color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #a3a7ae)); }
</style>
