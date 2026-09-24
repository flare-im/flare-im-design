<script setup lang="ts">
import { useFlareFormControl } from "../../shared/useFlareFormField";

const props = withDefaults(defineProps<{ disabled?: boolean }>(), { disabled: false });
const on = defineModel<boolean>({ default: false });
const emit = defineEmits<{ (e: "change", value: boolean): void }>();
// Inside FlareFormField the switch takes the field id, so the field label names it.
const control = useFlareFormControl({});

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
    :id="control.id"
    :aria-checked="on"
    :aria-describedby="control.describedBy"
    :aria-invalid="control.invalid || undefined"
    :disabled="disabled"
    @click="toggle"
  >
    <span class="flare-switch__knob" />
  </button>
</template>

<style scoped>
/* 视觉盒子自己钉住，命中区交给 ::after —— accessibility.css 在粗指针下给
   :where(button) 兜的是 min-width/min-height，而 min-* 会盖过 width/height，所以
   凡是「画出来小于一个触达单位」的控件都会在手机上被撑成 44，几何随之崩掉。
   `:where()` 把特异性压成 0 正是为了让组件能自己说话（见 accessibility.css 顶部注释）。 */
.flare-switch {
  width: var(--flare-component-switch-width);
  height: var(--flare-component-switch-height);
  min-width: var(--flare-component-switch-width);
  min-height: var(--flare-component-switch-height);
  border: none;
  border-radius: 999px;
  padding: 0;
  cursor: pointer;
  background: var(--flare-color-border-hover);
  position: relative;
  transition: background var(--flare-transition-fast);
}
.flare-switch::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: max(100%, var(--flare-size-layout-touch-target));
  height: max(100%, var(--flare-size-layout-touch-target));
}
.flare-switch.is-on { background: var(--flare-color-primary); }
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
  transition: transform var(--flare-transition-normal);
}
.flare-switch.is-on .flare-switch__knob { transform: translateX(18px); }
</style>
