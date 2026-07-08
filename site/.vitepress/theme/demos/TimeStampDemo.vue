<script setup>
const labels = ["刚刚", "14:32", "昨天", "周三", "6/28"];
</script>

<template>
  <span v-for="l in labels" :key="l" class="ts">{{ l }}</span>
</template>

<style scoped>
.ts {
  color: var(--flare-color-text-tertiary);
  font-size: 12px;
  padding: 4px 8px;
  border-radius: 6px;
  background: var(--flare-color-bg-secondary);
}
</style>
