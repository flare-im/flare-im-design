<script setup lang="ts">
withDefaults(defineProps<{ emoji?: string; src?: string }>(), { emoji: "🐱" });
const emit = defineEmits<{ (e: "click"): void }>();
</script>
<template>
  <button class="fm-sticker" @click="emit('click')">
    <img v-if="src" :src="src" alt="" /><span v-else>{{ emoji }}</span>
  </button>
</template>
<style scoped>
.fm-sticker { border: none; background: none; padding: 0; font-size: 72px; line-height: 1; cursor: pointer; }
.fm-sticker img { width: 96px; height: 96px; object-fit: contain; }
</style>
