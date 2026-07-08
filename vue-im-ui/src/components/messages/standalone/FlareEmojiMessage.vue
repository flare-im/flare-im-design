<script setup lang="ts">
withDefaults(defineProps<{ emoji?: string }>(), { emoji: "🎉" });
</script>
<template>
  <div class="fm-emoji">{{ emoji }}</div>
</template>
<style scoped>
.fm-emoji { font-size: 40px; line-height: 1; }
</style>
