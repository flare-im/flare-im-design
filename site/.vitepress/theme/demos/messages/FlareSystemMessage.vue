<script setup>
defineProps({ text: { type: String, default: "" } });
</script>
<template>
  <div class="sys">{{ text }}</div>
</template>
<style scoped>
.sys { display: inline-block; font-size: 12px; color: var(--flare-color-text-tertiary); background: var(--flare-color-bg-tertiary); padding: 4px 12px; border-radius: 999px; }
</style>
