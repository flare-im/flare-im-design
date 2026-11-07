<script setup lang="ts">
import type { FlareSelectOption } from "../../shared/contracts";

withDefaults(
  defineProps<{
    options: FlareSelectOption[];
    /** Stack vertically instead of inline. */
    vertical?: boolean;
  }>(),
  { vertical: false },
);
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

function select(o: FlareSelectOption): void {
  if (o.disabled) return;
  value.value = o.value;
  emit("change", o.value);
}
</script>

<template>
  <div class="flare-radio-group" :class="{ 'is-vertical': vertical }" role="radiogroup">
    <button
      v-for="o in options"
      :key="o.value"
      type="button"
      role="radio"
      class="flare-radio"
      :class="{ 'is-on': value === o.value, 'is-disabled': o.disabled }"
      :aria-checked="value === o.value"
      :disabled="o.disabled"
      @click="select(o)"
    >
      <span class="flare-radio__dot" />
      <span class="flare-radio__label">{{ o.label }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-radio-group { display: inline-flex; gap: var(--flare-size-component-radio-indicator); flex-wrap: wrap; }
.flare-radio-group.is-vertical { flex-direction: column; gap: 12px; align-items: flex-start; }
.flare-radio {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: none;
  background: none;
  padding: 0;
  cursor: pointer;
  font-size: 14px;
  color: var(--flare-color-text-primary);
}
.flare-radio.is-disabled { opacity: 0.5; cursor: not-allowed; }
.flare-radio__dot {
  box-sizing: border-box;
  width: var(--flare-size-component-radio-indicator);
  height: var(--flare-size-component-radio-indicator);
  flex: 0 0 auto;
  border-radius: 50%;
  border: 1.5px solid var(--flare-color-border-hover);
  background: var(--flare-color-bg-primary);
  position: relative;
  transition: border-color var(--flare-transition-fast);
}
.flare-radio.is-on .flare-radio__dot { border-color: var(--flare-color-primary); }
.flare-radio.is-on .flare-radio__dot::after {
  content: "";
  position: absolute;
  inset: 50% auto auto 50%;
  width: var(--flare-size-component-radio-dot);
  height: var(--flare-size-component-radio-dot);
  transform: translate(-50%, -50%);
  border-radius: 50%;
  background: var(--flare-color-primary);
}
@media (pointer: coarse) {
  .flare-radio {
    min-width: var(--flare-size-layout-touch-target);
    min-height: var(--flare-size-layout-touch-target);
  }
}
</style>
