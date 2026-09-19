<script setup lang="ts">
defineProps<{ text?: string }>();
</script>
<template>
  <div class="fm-sys">{{ text }}</div>
</template>
<style scoped>
.fm-sys { display: inline-block; font-size: 12px; color: var(--flare-color-text-tertiary); background: var(--flare-color-bg-tertiary); padding: 4px 12px; border-radius: 999px; }
</style>
