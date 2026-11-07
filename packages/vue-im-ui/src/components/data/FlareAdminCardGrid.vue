<script setup lang="ts">
withDefaults(defineProps<{ density?: "normal" | "compact" }>(), {
  density: "normal",
});
</script>
<template>
  <div
    class="flare-admin-card-grid"
    :class="{ 'flare-admin-card-grid--compact': density === 'compact' }"
  >
    <slot />
  </div>
</template>
<style scoped>
.flare-admin-card-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  align-items: stretch;
  gap: 10px;
}
@media (max-width: 1024px) {
  .flare-admin-card-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
@media (max-width: 600px) {
  .flare-admin-card-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
.flare-admin-card-grid--compact {
  grid-template-columns: repeat(auto-fill, minmax(min(100%, 260px), 1fr));
  gap: var(--flare-size-spacing-sm);
}
</style>
