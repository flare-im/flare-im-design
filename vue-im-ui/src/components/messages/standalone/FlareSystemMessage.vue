<script setup lang="ts">
defineProps<{ text?: string }>();
</script>
<template>
  <div class="fm-sys">{{ text }}</div>
</template>
<style scoped>
.fm-sys { display: inline-block; font-size: 12px; color: var(--im-text-tertiary, #a3a7ae); background: var(--im-bg-surface-alt, #f2f3f5); padding: 4px 12px; border-radius: 999px; }
</style>
