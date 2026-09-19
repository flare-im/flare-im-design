<script setup lang="ts">
import { NIcon } from "naive-ui";
import { CheckmarkOutline, RemoveOutline } from "../../shared/icon-glyphs";

const props = withDefaults(
  defineProps<{
    label?: string;
    /** Accessible name when no visible label names the box (a checkbox inside a row or a table cell). */
    ariaLabel?: string;
    disabled?: boolean;
    /** Tri-state indeterminate look. */
    indeterminate?: boolean;
  }>(),
  { disabled: false, indeterminate: false },
);
const checked = defineModel<boolean>({ default: false });
const emit = defineEmits<{ (e: "change", value: boolean): void }>();

function toggle(): void {
  if (props.disabled) return;
  checked.value = !checked.value;
  emit("change", checked.value);
}
</script>

<template>
  <label class="flare-checkbox" :class="{ 'is-disabled': disabled }">
    <button
      type="button"
      role="checkbox"
      class="flare-checkbox__box"
      :class="{ 'is-on': checked || indeterminate }"
      :aria-checked="indeterminate ? 'mixed' : checked"
      :aria-label="ariaLabel || label"
      :disabled="disabled"
      @click="toggle"
    >
      <n-icon aria-hidden="true" v-if="indeterminate" :size="13" :component="RemoveOutline" />
      <n-icon aria-hidden="true" v-else-if="checked" :size="13" :component="CheckmarkOutline" />
    </button>
    <span v-if="label || $slots.default" class="flare-checkbox__label"><slot>{{ label }}</slot></span>
  </label>
</template>

<style scoped>
.flare-checkbox {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  cursor: pointer;
}
/* 0.5 的整体透明度把标签压到 3.08:1 —— 禁用不等于读不出来。0.65 仍然明显“灰掉”，文字过 AA。 */
.flare-checkbox.is-disabled { opacity: 0.65; cursor: not-allowed; }
.flare-checkbox__box {
  position: relative;
  width: var(--flare-size-icon-size-md);
  height: var(--flare-size-icon-size-md);
  flex: 0 0 auto;
  border-radius: var(--flare-size-radius-sm);
  border: 1.5px solid var(--flare-color-border-hover);
  background: var(--flare-color-bg-primary);
  color: #fff;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: background var(--flare-transition-fast), border-color var(--flare-transition-fast);
}
.flare-checkbox__box::after { content: ""; position: absolute; width: var(--flare-size-layout-touch-target); height: var(--flare-size-layout-touch-target); }
.flare-checkbox__box:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-checkbox__box.is-on {
  background: var(--flare-color-primary);
  border-color: var(--flare-color-primary);
}
.flare-checkbox__label {
  font-size: 14px;
  color: var(--flare-color-text-primary);
}
@media (prefers-reduced-motion: reduce) { .flare-checkbox__box { transition: none; } }
</style>
