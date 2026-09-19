<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 16 });
</script>

<template>
  <svg
    class="message-double-check"
    :width="size"
    :height="size"
    viewBox="0 0 16 16"
    fill="none"
    aria-hidden="true"
    focusable="false"
  >
    <path d="M1.75 8.5 4.5 11.25 9.25 5.75" />
    <path d="M6 8.5 8.75 11.25 14.25 4.75" />
  </svg>
</template>

<style scoped>
.message-double-check {
  display: block;
  overflow: visible;
}

.message-double-check path {
  stroke: currentColor;
  stroke-width: 1.5;
  stroke-linecap: round;
  stroke-linejoin: round;
  vector-effect: non-scaling-stroke;
}
</style>
