<script lang="ts">
import type { Component } from "vue";

export interface FlareFilterTabOption {
  value: string;
  label: string;
  badge?: number;
  /** Optional leading icon (any Vue component, e.g. a `@vicons` glyph). */
  icon?: Component;
}
</script>

<script setup lang="ts">
import { computed, type CSSProperties } from "vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

// Replaces per-app filter rows. Grid mode keeps every option visible in a
// fixed-width pane instead of introducing horizontal scrolling.
const props = withDefaults(defineProps<{
  options: FlareFilterTabOption[];
  layout?: "scroll" | "wrap" | "grid";
  columns?: number;
  ariaLabel?: string;
}>(), { layout: "scroll", columns: 4, ariaLabel: undefined });
const { t } = useFlareI18nOptional();
const active = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

const layoutStyle = computed<CSSProperties>(() => ({
  "--flare-filter-columns": String(Math.max(1, Math.floor(props.columns))),
} as CSSProperties));

function select(value: string): void {
  active.value = value;
  emit("change", value);
}
</script>

<template>
  <div
    class="flare-filter-tabs"
    :class="`flare-filter-tabs--${layout}`"
    :style="layoutStyle"
    role="tablist"
    :aria-label="ariaLabel ?? t('common.filters')"
  >
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
      <component :is="option.icon" v-if="option.icon" class="flare-filter-tab__icon" />
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

.flare-filter-tabs--wrap {
  flex-wrap: wrap;
  overflow-x: hidden;
}

.flare-filter-tabs--grid {
  display: grid;
  grid-template-columns: repeat(var(--flare-filter-columns), minmax(0, 1fr));
  gap: 4px;
  overflow: hidden;
  padding: 3px;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
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
  color: var(--flare-color-primary-text);
  background: color-mix(in srgb, var(--flare-color-primary) 12%, transparent);
  border-color: color-mix(in srgb, var(--flare-color-primary) 26%, transparent);
  font-weight: 600;
}

.flare-filter-tab__icon {
  display: inline-flex;
  width: 15px;
  height: 15px;
  flex: none;
}
.flare-filter-tab__icon :deep(svg) {
  width: 100%;
  height: 100%;
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
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}

.flare-filter-tabs--grid .flare-filter-tab {
  width: 100%;
  min-width: 0;
  justify-content: center;
  padding-inline: 6px;
  overflow: hidden;
  border-radius: calc(var(--flare-size-radius-md) - 2px);
  background: transparent;
  text-overflow: ellipsis;
}

.flare-filter-tabs--grid .flare-filter-tab--active {
  border-color: transparent;
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-sm);
}

@media (pointer: coarse) {
  .flare-filter-tab {
    min-height: var(--flare-size-layout-touch-target);
  }
}
</style>
