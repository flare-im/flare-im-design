<script setup lang="ts">
import { computed } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { NIcon } from "naive-ui";
import { RemoveOutline, AddOutline } from "../../shared/icon-glyphs";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";

const props = withDefaults(
  defineProps<{
    min?: number;
    max?: number;
    step?: number;
    disabled?: boolean;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Hide the editable middle field, showing value as static text. */
    readonly?: boolean;
  }>(),
  { min: 0, max: Number.POSITIVE_INFINITY, step: 1, disabled: false, readonly: false },
);
const value = defineModel<number>({ default: 0 });
const emit = defineEmits<{ (e: "change", value: number): void }>();

// Resolve the config once at setup — calling inject() lazily inside a computed
// can bind to a throwaway default if first evaluated outside render.
const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
const canDec = computed(() => !props.disabled && value.value > props.min);
const canInc = computed(() => !props.disabled && value.value < props.max);

function clamp(n: number): number {
  return Math.min(props.max, Math.max(props.min, n));
}
function set(n: number): void {
  const next = clamp(n);
  if (next === value.value) return;
  value.value = next;
  emit("change", next);
}
const { t } = useFlareI18n();
function dec(): void { if (canDec.value) set(value.value - props.step); }
function inc(): void { if (canInc.value) set(value.value + props.step); }
function onInput(e: Event): void {
  const el = e.target as HTMLInputElement;
  const raw = Number(el.value);
  if (!Number.isNaN(raw)) set(raw);
  // Always re-sync the DOM to the normalized model — a clamped or invalid entry
  // (e.g. "999" → max, or "abc") leaves the model unchanged, so Vue won't repaint
  // the input on its own and it would keep showing the stale raw text.
  el.value = String(value.value);
}
</script>

<template>
  <div class="flare-stepper" :class="[`flare-stepper--${rsize}`, { 'is-disabled': disabled }]">
    <button type="button" class="flare-stepper__btn" :disabled="!canDec" :aria-label="t('stepper.decrease')" @click="dec">
      <n-icon aria-hidden="true" :component="RemoveOutline" />
    </button>
    <input
      v-if="!readonly"
      class="flare-stepper__field"
      type="text"
      inputmode="numeric"
      :value="value"
      :disabled="disabled"
      @change="onInput"
    />
    <span v-else class="flare-stepper__field is-static">{{ value }}</span>
    <button type="button" class="flare-stepper__btn" :disabled="!canInc" :aria-label="t('stepper.increase')" @click="inc">
      <n-icon aria-hidden="true" :component="AddOutline" />
    </button>
  </div>
</template>

<style scoped>
.flare-stepper {
  display: inline-flex;
  align-items: center;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  overflow: hidden;
}
.flare-stepper.is-disabled { opacity: 0.55; }
.flare-stepper__btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: var(--flare-color-text-secondary);
  cursor: pointer;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-stepper__btn:hover:not(:disabled) { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
.flare-stepper__btn:active:not(:disabled) { transform: scale(0.9); }
.flare-stepper__btn:disabled { opacity: 0.4; cursor: not-allowed; }
.flare-stepper__field {
  width: 44px;
  border: none;
  outline: none;
  text-align: center;
  background: transparent;
  color: var(--flare-color-text-primary);
  font: inherit;
  font-variant-numeric: tabular-nums;
  -moz-appearance: textfield;
}
.flare-stepper__field.is-static { display: inline-flex; align-items: center; justify-content: center; }
.flare-stepper:focus-within { border-color: var(--flare-color-border-selected); box-shadow: 0 0 0 2px var(--flare-color-focus-ring); }

.flare-stepper--sm { height: 32px; } .flare-stepper--sm .flare-stepper__btn { width: 30px; height: 30px; font-size: 15px; } .flare-stepper--sm .flare-stepper__field { font-size: 13px; }
.flare-stepper--md { height: 40px; } .flare-stepper--md .flare-stepper__btn { width: 38px; height: 38px; font-size: 18px; } .flare-stepper--md .flare-stepper__field { font-size: 14px; }
.flare-stepper--lg { height: 48px; } .flare-stepper--lg .flare-stepper__btn { width: 46px; height: 46px; font-size: 20px; } .flare-stepper--lg .flare-stepper__field { width: 52px; font-size: 15px; }
</style>
