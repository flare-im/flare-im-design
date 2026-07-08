<script setup lang="ts">
defineProps<{
  label: string;
}>();
</script>

<template>
  <div class="timestamp-chip">{{ label }}</div>
</template>
