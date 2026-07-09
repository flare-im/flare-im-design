<script setup lang="ts">
// Reply strip — a composable composer part shown above the input when replying.
// Left rail + label/sender + summary + cancel. `label` is host-provided text
// (default "Reply") so the component carries no baked-in language.
withDefaults(defineProps<{ senderName: string; summary: string; label?: string }>(), {
  label: "Reply",
});
const emit = defineEmits<{ (e: "cancel"): void }>();
</script>

<template>
  <div class="flare-reply">
    <div class="body">
      <div class="who">{{ label }} {{ senderName }}</div>
      <div class="sum">{{ summary }}</div>
    </div>
    <button class="x" aria-label="Cancel reply" @click="emit('cancel')">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor"
        stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M6 6l12 12M18 6L6 18" />
      </svg>
    </button>
  </div>
</template>

<style scoped>
.flare-reply {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  border-radius: var(--flare-size-radius-md, 6px);
  background: var(--flare-color-bg-secondary, var(--flare-color-bg-secondary, #f5f6f8));
  border-left: 3px solid var(--flare-color-primary, var(--flare-color-primary, #7c3aed));
}
.body { flex: 1; min-width: 0; }
.who { font-size: 11px; font-weight: 600; color: var(--flare-color-primary, var(--flare-color-primary, #7c3aed)); }
.sum {
  font-size: 12px;
  color: var(--flare-color-text-secondary, var(--flare-color-text-secondary, #6b7280));
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.x {
  flex: none;
  border: none;
  background: none;
  padding: 0;
  display: flex;
  color: var(--flare-color-text-tertiary, var(--flare-color-text-tertiary, #a3a7ae));
  cursor: pointer;
}
</style>
