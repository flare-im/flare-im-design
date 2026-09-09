<script setup lang="ts">
import type { FlareSelectOption } from "../../shared/contracts";

const props = withDefaults(
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
.flare-radio-group { display: inline-flex; gap: 18px; flex-wrap: wrap; }
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
  color: var(--flare-color-text-primary, #20232D);
}
.flare-radio.is-disabled { opacity: 0.5; cursor: not-allowed; }
.flare-radio__dot {
  width: 18px;
  height: 18px;
  flex: 0 0 auto;
  border-radius: 50%;
  border: 1.5px solid var(--flare-color-border-hover, #C9CDD7);
  background: var(--flare-color-bg-primary, #FFFFFF);
  position: relative;
  transition: border-color var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1));
}
.flare-radio.is-on .flare-radio__dot { border-color: var(--flare-color-primary, #7047D6); }
.flare-radio.is-on .flare-radio__dot::after {
  content: "";
  position: absolute;
  inset: 3.5px;
  border-radius: 50%;
  background: var(--flare-color-primary, #7047D6);
}
</style>
