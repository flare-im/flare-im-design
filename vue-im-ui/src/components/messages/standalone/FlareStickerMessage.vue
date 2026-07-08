<script setup lang="ts">
withDefaults(defineProps<{ emoji?: string; src?: string }>(), { emoji: "🐱" });
</script>
<template>
  <div class="fm-sticker"><img v-if="src" :src="src" alt="" /><span v-else>{{ emoji }}</span></div>
</template>
<style scoped>
.fm-sticker { font-size: 72px; line-height: 1; }
.fm-sticker img { width: 96px; height: 96px; object-fit: contain; }
</style>
