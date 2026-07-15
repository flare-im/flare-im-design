<script setup lang="ts">
defineProps<{
  /** The pre-formatted date label (e.g. "Today", "Yesterday", "Jul 15"). */
  label: string;
  /** Sticky mode — pins to the top of the scroll area while scrolling. */
  floating?: boolean;
}>();
</script>

<template>
  <div class="flare-date-pill" :class="{ 'is-floating': floating }">
    <span class="flare-date-pill__chip">{{ label }}</span>
  </div>
</template>

<style scoped>
.flare-date-pill {
  display: flex;
  justify-content: center;
  padding: 4px 0;
  pointer-events: none;
}
.flare-date-pill.is-floating {
  position: sticky;
  top: 6px;
  z-index: 2;
}
.flare-date-pill__chip {
  padding: 3px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
  color: var(--flare-color-text-secondary, #6b6780);
  background: color-mix(in srgb, var(--flare-color-bg-primary, #fff) 78%, transparent);
  backdrop-filter: blur(6px);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-sm, 0 2px 6px rgba(21, 18, 32, 0.08));
}
</style>
