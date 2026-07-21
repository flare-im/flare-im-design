<script setup lang="ts">
import { NIcon } from "naive-ui";
import { CheckmarkOutline, RemoveOutline } from "../../shared/icon-glyphs";

const props = withDefaults(
  defineProps<{
    label?: string;
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
      :disabled="disabled"
      @click="toggle"
    >
      <n-icon v-if="indeterminate" :size="13" :component="RemoveOutline" />
      <n-icon v-else-if="checked" :size="13" :component="CheckmarkOutline" />
    </button>
    <span v-if="label || $slots.default" class="flare-checkbox__label" @click="toggle"><slot>{{ label }}</slot></span>
  </label>
</template>

<style scoped>
.flare-checkbox {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}
.flare-checkbox.is-disabled { opacity: 0.5; cursor: not-allowed; }
.flare-checkbox__box {
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  border-radius: var(--flare-size-radius-sm, 6px);
  border: 1.5px solid var(--flare-color-border-hover, #d5d1e0);
  background: var(--flare-color-bg-primary, #fff);
  color: #fff;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: background var(--flare-transition-fast, 150ms ease), border-color var(--flare-transition-fast, 150ms ease);
}
.flare-checkbox__box.is-on {
  background: var(--flare-color-primary, #7c3aed);
  border-color: var(--flare-color-primary, #7c3aed);
}
.flare-checkbox__label {
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
}
</style>
