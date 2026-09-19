<script setup lang="ts">
// Compact equal-width segmented selector (分段选择器) — mutually-exclusive options.
// Distinct from FlareFilterTabs (scrollable pills w/ badges); this is a bordered
// iOS-style segmented control for a small in-page filter.
defineProps<{ options: string[] }>();
const active = defineModel<number>({ default: 0 });
const emit = defineEmits<{ (e: "change", index: number): void }>();

function select(i: number): void {
  active.value = i;
  emit("change", i);
}
</script>

<template>
  <div class="flare-segmented" role="tablist">
    <button
      v-for="(label, i) in options"
      :key="i"
      type="button"
      role="tab"
      class="flare-segmented__seg"
      :class="{ 'is-active': active === i }"
      :aria-selected="active === i"
      @click="select(i)"
    >{{ label }}</button>
  </div>
</template>

<style scoped>
.flare-segmented {
  display: inline-flex;
  padding: 3px;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  border: 1px solid var(--flare-color-border-primary);
}
.flare-segmented__seg {
  flex: 1;
  min-width: 64px;
  padding: 6px 16px;
  border: none;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  color: var(--flare-color-text-secondary);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  white-space: nowrap;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-segmented__seg.is-active {
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-primary-text);
  box-shadow: var(--flare-shadow-sm);
}
</style>
