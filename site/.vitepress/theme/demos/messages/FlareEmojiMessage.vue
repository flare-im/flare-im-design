<script setup>
defineProps({ emoji: { type: String, default: "🎉" } });
</script>
<template>
  <div class="big">{{ emoji }}</div>
</template>
<style scoped>
.big { font-size: 40px; line-height: 1; }
</style>
