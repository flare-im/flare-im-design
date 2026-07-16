<script setup lang="ts">
const props = withDefaults(defineProps<{ disabled?: boolean }>(), { disabled: false });
const on = defineModel<boolean>({ default: false });
const emit = defineEmits<{ (e: "change", value: boolean): void }>();

function toggle(): void {
  if (props.disabled) return;
  on.value = !on.value;
  emit("change", on.value);
}
</script>

<template>
  <button
    type="button"
    role="switch"
    class="flare-switch"
    :class="{ 'is-on': on, 'is-disabled': disabled }"
    :aria-checked="on"
    :disabled="disabled"
    @click="toggle"
  >
    <span class="flare-switch__knob" />
  </button>
</template>

<style scoped>
.flare-switch {
  width: 44px;
  height: 26px;
  border: none;
  border-radius: 999px;
  padding: 0;
  cursor: pointer;
  background: var(--flare-color-border-hover, #d5d1e0);
  position: relative;
  transition: background var(--flare-transition-fast, 150ms ease);
}
.flare-switch.is-on { background: var(--flare-color-primary, #7c3aed); }
.flare-switch.is-disabled { opacity: 0.5; cursor: not-allowed; }
.flare-switch__knob {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #fff;
  box-shadow: 0 1px 3px rgba(21, 18, 32, 0.28);
  transition: transform var(--flare-transition-base, 200ms cubic-bezier(0.22, 1, 0.36, 1));
}
.flare-switch.is-on .flare-switch__knob { transform: translateX(18px); }
</style>
