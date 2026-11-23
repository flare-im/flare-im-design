<script setup lang="ts">
// Spec PinInput (§5.10 / R6 of docs/plugin-experience.md): a 6-digit payment PIN as six cells over one real input, so
// the value stays one string and the keyboard, paste and autofill reach the input. Digits only; the cells show dots and
// the next cell carries the focus ring, so typing advances by itself. The sixth digit (or Enter when full) emits
// complete. A new error clears the digits and shakes the row once (no shake under reduced motion).
import { computed, onBeforeUnmount, onMounted, ref, useId, watch } from "vue";
import { useFlareFormControl } from "../../shared/useFlareFormField";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const LENGTH = 6;
const props = withDefaults(
  defineProps<{
    modelValue: string;
    /** Accessible name, such as "Payment password". */
    label: string;
    /** Wrong PIN: error border; turning on clears the value and shakes once. */
    error?: boolean;
    /** Locked while verifying. */
    disabled?: boolean;
    /** Focus (and open the numeric keyboard) on appear. */
    autoFocus?: boolean;
  }>(),
  { error: false, disabled: false, autoFocus: true },
);
const emit = defineEmits<{ "update:modelValue": [value: string]; complete: [value: string] }>();
const control = useFlareFormControl({});
const { t } = useFlareI18nOptional();
const input = ref<HTMLInputElement | null>(null);
const focused = ref(false);
const shaking = ref(false);
let shakeTimer: ReturnType<typeof setTimeout> | undefined;
const digits = computed(() => (props.modelValue ?? "").replace(/\D/g, "").slice(0, LENGTH));
const active = computed(() => Math.min(digits.value.length, LENGTH - 1));
const progressId = `${useId()}-pin-progress`;
const describedBy = computed(() => [control.value.describedBy, progressId].filter(Boolean).join(" "));

function onInput(event: Event): void {
  const target = event.target as HTMLInputElement;
  const next = target.value.replace(/\D/g, "").slice(0, LENGTH);
  if (target.value !== next) target.value = next;
  emit("update:modelValue", next);
  if (next.length === LENGTH && digits.value.length !== LENGTH) emit("complete", next);
}
function onEnter(): void {
  if (digits.value.length === LENGTH && !props.disabled) emit("complete", digits.value);
}
watch(() => props.error, (error, before) => {
  if (!error || before) return;
  emit("update:modelValue", "");
  shaking.value = true;
  clearTimeout(shakeTimer);
  shakeTimer = setTimeout(() => { shaking.value = false; }, 400);
  input.value?.focus({ preventScroll: true });
});
onMounted(() => { if (props.autoFocus && !props.disabled) input.value?.focus({ preventScroll: true }); });
onBeforeUnmount(() => clearTimeout(shakeTimer));
defineExpose({ focus: () => input.value?.focus({ preventScroll: true }) });
</script>

<template>
  <div class="flare-pin" :class="{ 'is-shaking': shaking, 'is-invalid': error || control.invalid, 'is-disabled': disabled }" data-pin="true">
    <input
      :id="control.id"
      ref="input"
      class="flare-pin__input"
      type="password"
      inputmode="numeric"
      pattern="[0-9]*"
      autocomplete="off"
      :maxlength="LENGTH"
      :value="digits"
      :disabled="disabled"
      :aria-label="label"
      :aria-describedby="describedBy"
      :aria-invalid="error || control.invalid || undefined"
      :aria-required="control.required || undefined"
      @input="onInput"
      @keydown.enter.prevent="onEnter"
      @focus="focused = true"
      @blur="focused = false"
    />
    <!-- Read as how many digits are in, never the digits themselves. -->
    <span :id="progressId" class="flare-pin__progress">{{ t('pinInput.progress', { label, count: digits.length }) }}</span>
    <span
      v-for="index in LENGTH"
      :key="index"
      class="flare-pin__cell"
      :class="{ 'is-active': focused && index - 1 === active, 'is-filled': index <= digits.length }"
      aria-hidden="true"
    ><span v-if="index <= digits.length" class="flare-pin__dot" /></span>
  </div>
</template>

<style scoped>
/* §12.19: six cells of pinCellWidth that shrink with a narrow container (320 wide: the sheet's 288), never under 36. */
.flare-pin {
  position: relative;
  display: inline-grid;
  grid-template-columns: repeat(6, minmax(var(--flare-size-component-pin-cell-min-width), var(--flare-size-component-pin-cell-width)));
  gap: var(--flare-size-spacing-sm);
  width: min(100%, calc(var(--flare-size-component-pin-cell-width) * 6 + var(--flare-size-spacing-sm) * 5));
  max-width: 100%;
  box-sizing: border-box;
}
/* The real input covers the cells: every tap lands on it, its caret and text stay invisible. */
.flare-pin__input {
  position: absolute;
  inset: 0;
  z-index: 1;
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 0;
  border: 0;
  opacity: 0;
  font-size: var(--flare-size-font-size-2xl);
  cursor: text;
}
.flare-pin__input:disabled { cursor: not-allowed; }
.flare-pin__progress { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
/* Cells 44 × 52 on the kit radius (spec PinInput). */
.flare-pin__cell {
  box-sizing: border-box;
  display: flex;
  align-items: center;
  justify-content: center;
  height: var(--flare-size-component-pin-cell-height);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
}
.flare-pin__cell.is-active {
  border-color: var(--flare-color-border-selected);
  box-shadow: 0 0 0 2px var(--flare-color-focus-ring);
}
.flare-pin.is-invalid .flare-pin__cell { border-color: var(--flare-color-error); }
.flare-pin.is-disabled .flare-pin__cell { opacity: var(--flare-opacity-disabled); }
.flare-pin__dot {
  width: var(--flare-size-spacing-sm);
  height: var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-text-primary);
}
@media (prefers-reduced-motion: no-preference) {
  .flare-pin.is-shaking { animation: flare-pin-shake 0.4s ease-in-out; }
}
@keyframes flare-pin-shake {
  20%, 60% { transform: translateX(calc(var(--flare-size-spacing-xs) * -1)); }
  40%, 80% { transform: translateX(var(--flare-size-spacing-xs)); }
}
</style>
