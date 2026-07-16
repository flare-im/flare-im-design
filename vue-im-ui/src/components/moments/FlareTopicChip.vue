<script setup lang="ts">
// A #topic / hashtag chip in a moment. Brand-tinted, tappable.
defineProps<{ topic: string }>();
const emit = defineEmits<{ (e: "click"): void }>();
</script>

<template>
  <button type="button" class="flare-topic-chip" @click="emit('click')">#{{ topic }}</button>
</template>

<style scoped>
.flare-topic-chip {
  display: inline;
  border: none;
  background: transparent;
  padding: 0;
  color: var(--flare-color-primary, #7c3aed);
  font-size: inherit;
  font-weight: 500;
  cursor: pointer;
}
.flare-topic-chip:hover { text-decoration: underline; }
</style>
