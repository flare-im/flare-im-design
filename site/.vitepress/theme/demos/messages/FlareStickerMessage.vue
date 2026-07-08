<script setup>
defineProps({ emoji: { type: String, default: "🐱" }, src: String });
</script>
<template>
  <div class="sticker"><img v-if="src" :src="src" alt="" /><span v-else>{{ emoji }}</span></div>
</template>
<style scoped>
.sticker { font-size: 72px; line-height: 1; }
.sticker img { width: 96px; height: 96px; object-fit: contain; }
</style>
