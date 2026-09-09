<script setup lang="ts">
defineProps<{ text?: string }>();
</script>
<template>
  <div class="fm-sys">{{ text }}</div>
</template>
<style scoped>
.fm-sys { display: inline-block; font-size: 12px; color: var(--im-text-tertiary, var(--flare-color-text-tertiary, #687182)); background: var(--im-bg-surface-alt, var(--flare-color-bg-tertiary, #F1F2F5)); padding: 4px 12px; border-radius: 999px; }
</style>
