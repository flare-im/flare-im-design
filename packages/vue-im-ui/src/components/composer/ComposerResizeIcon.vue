<script setup lang="ts">
/** The two diagonal arrows from the approved composer design. */
defineProps<{ expanded?: boolean }>();
</script>

<template>
  <svg class="composer-resize-icon" viewBox="0 0 24 24" width="18" height="18"
    fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"
    stroke-linejoin="round" aria-hidden="true" focusable="false">
    <path :d="expanded
      ? 'M20 9h-5V4M15 9l6-6M4 15h5v5M9 15l-6 6'
      : 'M14 4h6v6M20 4l-7 7M4 14v6h6M4 20l7-7'" />
  </svg>
</template>
