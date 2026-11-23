<script setup lang="ts">
// Compact equal-width segmented selector (分段选择器) — mutually-exclusive options.
// Distinct from FlareFilterTabs (scrollable pills w/ badges); this is a bordered
// iOS-style segmented control for a small in-page filter.
const props = defineProps<{
  options: string[];
  /** Colour of the selected segment's label (a CSS colour); the brand text colour when omitted. */
  accent?: string;
}>();
const active = defineModel<number>({ default: 0 });
const emit = defineEmits<{ (e: "change", index: number): void }>();

function select(i: number): void {
  active.value = i;
  emit("change", i);
}
function navigate(event: KeyboardEvent, index: number): void {
  const keys = ['ArrowLeft', 'ArrowRight', 'Home', 'End'];
  if (!keys.includes(event.key) || !props.options.length) return;
  event.preventDefault();
  const rtl = (event.currentTarget as HTMLElement).closest('[dir="rtl"]') !== null;
  const step = (event.key === 'ArrowRight' ? 1 : -1) * (rtl ? -1 : 1);
  const next = event.key === 'Home' ? 0 : event.key === 'End' ? props.options.length - 1
    : (index + step + props.options.length) % props.options.length;
  const target = (event.currentTarget as HTMLElement).parentElement?.querySelectorAll<HTMLButtonElement>('button')[next];
  if (target?.disabled || target?.matches(':disabled')) return;
  select(next);
  target?.focus();
}
</script>

<template>
  <div class="flare-segmented" role="tablist" :style="accent ? { '--flare-segmented-accent': accent } : undefined">
    <button
      v-for="(label, i) in options"
      :key="i"
      type="button"
      role="tab"
      class="flare-segmented__seg"
      :class="{ 'is-active': active === i }"
      :aria-selected="active === i"
      :title="label"
      :tabindex="active === i || active < 0 && i === 0 ? 0 : -1"
      @click="select(i)"
      @keydown="navigate($event, i)"
    >{{ label }}</button>
  </div>
</template>

<style scoped>
.flare-segmented {
  display: inline-flex;
  padding: var(--flare-size-spacing-3xs);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  border: 1px solid var(--flare-color-border-primary);
}
.flare-segmented__seg {
  flex: 1;
  min-width: 0;
  min-height: var(--flare-size-layout-control-height-sm);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border: none;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-md);
  font-weight: var(--flare-size-font-weight-medium);
  cursor: pointer;
  white-space: normal;
  overflow-wrap: anywhere;
  line-height: var(--flare-size-line-height-snug);
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-segmented__seg:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
/* §4.7: a touch segment is the 48 touch target. */
@media (pointer: coarse) {
  .flare-segmented__seg { min-height: var(--flare-size-layout-touch-target); }
}
.flare-segmented__seg.is-active {
  background: var(--flare-color-bg-primary);
  color: var(--flare-segmented-accent, var(--flare-color-primary-text));
  box-shadow: var(--flare-shadow-sm);
}
</style>
