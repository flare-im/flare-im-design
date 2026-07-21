<script setup lang="ts">
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import { Star, StarOutline } from "../../shared/icon-glyphs";

const props = withDefaults(
  defineProps<{
    /** Number of icons. */
    count?: number;
    disabled?: boolean;
    /** Read-only display (no hover/click). */
    readonly?: boolean;
    /** Glyph size in px. */
    size?: number;
    /** Allow clicking the current value again to clear to 0. */
    clearable?: boolean;
  }>(),
  { count: 5, disabled: false, readonly: false, size: 24, clearable: false },
);
const value = defineModel<number>({ default: 0 });
const emit = defineEmits<{ (e: "change", value: number): void }>();

const hover = ref(0);
const stars = computed(() => Array.from({ length: props.count }, (_, i) => i + 1));
const active = computed(() => (hover.value > 0 ? hover.value : value.value));
const interactive = computed(() => !props.disabled && !props.readonly);

function enter(n: number): void { if (interactive.value) hover.value = n; }
function leave(): void { hover.value = 0; }
function commit(next: number): void {
  value.value = next;
  emit("change", next);
}
function pick(n: number): void {
  if (!interactive.value) return;
  commit(props.clearable && value.value === n ? 0 : n);
}
// The one star in the tab order: the current value, or the first when unset.
const tabStar = computed(() => value.value || 1);
function onKey(e: KeyboardEvent): void {
  if (!interactive.value) return;
  const lo = props.clearable ? 0 : 1;
  if (e.key === "ArrowLeft" || e.key === "ArrowDown") { e.preventDefault(); commit(Math.max(lo, value.value - 1)); }
  else if (e.key === "ArrowRight" || e.key === "ArrowUp") { e.preventDefault(); commit(Math.min(props.count, value.value + 1)); }
  else if (e.key === "Home") { e.preventDefault(); commit(lo === 0 ? 0 : 1); }
  else if (e.key === "End") { e.preventDefault(); commit(props.count); }
}
</script>

<template>
  <div
    class="flare-rating"
    :class="{ 'is-disabled': disabled, 'is-readonly': readonly }"
    role="radiogroup"
    @mouseleave="leave"
    @keydown="onKey"
  >
    <button
      v-for="n in stars"
      :key="n"
      type="button"
      class="flare-rating__star"
      :class="{ 'is-on': n <= active }"
      :style="{ fontSize: `${size}px` }"
      :disabled="disabled || readonly"
      :aria-label="`${n}`"
      :aria-checked="n === value"
      :tabindex="interactive && n === tabStar ? 0 : -1"
      role="radio"
      @mouseenter="enter(n)"
      @click="pick(n)"
    >
      <n-icon :component="n <= active ? Star : StarOutline" />
    </button>
  </div>
</template>

<style scoped>
.flare-rating { display: inline-flex; align-items: center; gap: 4px; }
.flare-rating.is-disabled { opacity: 0.5; }
.flare-rating__star {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  border: none;
  background: transparent;
  line-height: 1;
  color: var(--flare-color-border-hover, #d5d1e0);
  cursor: pointer;
  transition: color var(--flare-transition-fast, 150ms ease), transform var(--flare-transition-fast, 150ms ease);
}
.flare-rating__star.is-on { color: var(--flare-color-warning, #f5a623); }
.flare-rating:not(.is-readonly):not(.is-disabled) .flare-rating__star:hover { transform: scale(1.16); }
.flare-rating.is-readonly .flare-rating__star, .flare-rating.is-disabled .flare-rating__star { cursor: default; }
</style>
