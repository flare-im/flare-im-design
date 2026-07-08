<script setup lang="ts">
withDefaults(defineProps<{ emoji?: string }>(), { emoji: "🎉" });
const emit = defineEmits<{ (e: "click"): void }>();
</script>
<template>
  <button class="fm-emoji" @click="emit('click')">{{ emoji }}</button>
</template>
<style scoped>
.fm-emoji { border: none; background: none; padding: 0; font-size: 40px; line-height: 1; cursor: pointer; }
</style>
