<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
// Presentational — emits `click`; the host opens the full-size viewer.
withDefaults(defineProps<{ src?: string; width?: number; height?: number; alt?: string }>(), { width: 132, height: 92, alt: "" });
const emit = defineEmits<{ (e: "click"): void }>();
</script>
<template>
  <button class="fm-img" :style="{ width: width + 'px', height: height + 'px' }" @click="emit('click')">
    <img v-if="src" :src="src" :alt="alt" />
    <MsgIcon v-else name="image" :size="26" />
  </button>
</template>
<style scoped>
.fm-img { padding: 0; border: none; border-radius: 12px; overflow: hidden; background: var(--im-bg-surface-alt, #f2f3f5); display: grid; place-items: center; color: var(--im-text-tertiary, #a3a7ae); cursor: pointer; }
.fm-img img { width: 100%; height: 100%; object-fit: cover; }
</style>
