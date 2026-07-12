<script lang="ts">
export interface FlareFilterTabOption {
  value: string;
  label: string;
  badge?: number;
}
</script>

<script setup lang="ts">
// A horizontal, scrollable tablist for filtering (conversations, search kinds…).
// Replaces the per-app bespoke conversation-filter rows.
defineProps<{ options: FlareFilterTabOption[] }>();
const active = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

function select(value: string): void {
  active.value = value;
  emit("change", value);
}
</script>

<template>
  <div class="flare-filter-tabs" role="tablist" aria-label="Filters">
    <button
      v-for="option in options"
      :key="option.value"
      type="button"
      role="tab"
      class="flare-filter-tab"
      :class="{ 'flare-filter-tab--active': active === option.value }"
      :aria-selected="active === option.value"
      @click="select(option.value)"
    >
      {{ option.label }}
      <span v-if="option.badge" class="flare-filter-tab__badge">{{ option.badge }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-filter-tabs {
  display: flex;
  align-items: center;
  gap: 6px;
  overflow-x: auto;
  padding: 2px;
  scrollbar-width: none;
}
.flare-filter-tabs::-webkit-scrollbar {
  display: none;
}

.flare-filter-tab {
  flex: none;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  font: inherit;
  font-size: 13px;
  font-weight: 500;
  line-height: 1.2;
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
  border: 1px solid transparent;
  border-radius: 999px;
  cursor: pointer;
  white-space: nowrap;
  transition:
    color 0.15s ease,
    background 0.15s ease;
}

.flare-filter-tab:hover {
  color: var(--flare-color-text-primary);
}

.flare-filter-tab--active {
  color: var(--flare-color-primary);
  background: color-mix(in srgb, var(--flare-color-primary) 12%, transparent);
  border-color: color-mix(in srgb, var(--flare-color-primary) 26%, transparent);
  font-weight: 600;
}

.flare-filter-tab__badge {
  min-width: 16px;
  height: 16px;
  padding: 0 5px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
  color: #fff;
  background: var(--flare-color-primary);
  border-radius: 999px;
}

.flare-filter-tab:focus-visible {
  outline: 2px solid var(--flare-color-primary);
  outline-offset: 2px;
}
</style>
