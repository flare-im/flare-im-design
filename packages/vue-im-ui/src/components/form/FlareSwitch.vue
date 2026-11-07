<script setup lang="ts">
import { useFlareFormControl } from "../../shared/useFlareFormField";
import type { FlareControlSize } from "../../shared/contracts";

const props = withDefaults(defineProps<{
  disabled?: boolean;
  size?: FlareControlSize;
  /** A parent settings row owns focus, state and activation. */
  decorative?: boolean;
}>(), { disabled: false, size: "md", decorative: false });
const on = defineModel<boolean>({ default: false });
const emit = defineEmits<{ (e: "change", value: boolean): void }>();
// Inside FlareFormField the switch takes the field id, so the field label names it.
const control = useFlareFormControl({});

function toggle(): void {
  if (props.disabled || props.decorative) return;
  on.value = !on.value;
  emit("change", on.value);
}
</script>

<template>
  <component
    :is="decorative ? 'span' : 'button'"
    :type="decorative ? undefined : 'button'"
    :role="decorative ? undefined : 'switch'"
    class="flare-switch"
    :class="[`flare-switch--${size}`, { 'is-on': on, 'is-disabled': disabled, 'is-decorative': decorative }]"
    :id="decorative ? undefined : control.id"
    :aria-hidden="decorative || undefined"
    :aria-checked="decorative ? undefined : on"
    :aria-describedby="decorative ? undefined : control.describedBy"
    :aria-invalid="decorative ? undefined : control.invalid || undefined"
    :disabled="decorative ? undefined : disabled"
    v-on="decorative ? {} : { click: toggle }"
  >
    <span class="flare-switch__knob" />
  </component>
</template>

<style scoped>
/* 视觉盒子自己钉住，命中区交给 ::after —— accessibility.css 在粗指针下给
   :where(button) 兜的是 min-width/min-height，而 min-* 会盖过 width/height，所以
   凡是「画出来小于一个触达单位」的控件都会在手机上被撑成 44，几何随之崩掉。
   `:where()` 把特异性压成 0 正是为了让组件能自己说话（见 accessibility.css 顶部注释）。 */
.flare-switch {
  --switch-width: var(--flare-size-component-switch-width-md);
  --switch-height: var(--flare-size-component-switch-height-md);
  --switch-thumb: var(--flare-size-component-switch-thumb-md);
  --switch-inset: calc((var(--switch-height) - var(--switch-thumb)) / 2);
  display: inline-block;
  flex: none;
  width: var(--switch-width);
  height: var(--switch-height);
  min-width: var(--switch-width);
  min-height: var(--switch-height);
  border: none;
  border-radius: 999px;
  padding: 0;
  cursor: pointer;
  background: var(--flare-color-border-hover);
  position: relative;
  transition: background var(--flare-transition-fast);
}
.flare-switch--sm {
  --switch-width: var(--flare-size-component-switch-width-sm);
  --switch-height: var(--flare-size-component-switch-height-sm);
  --switch-thumb: var(--flare-size-component-switch-thumb-sm);
}
.flare-switch--lg {
  --switch-width: var(--flare-size-component-switch-width-lg);
  --switch-height: var(--flare-size-component-switch-height-lg);
  --switch-thumb: var(--flare-size-component-switch-thumb-lg);
}
.flare-switch.is-decorative { cursor: inherit; }
.flare-switch:not(.is-decorative)::after {
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
  inset-block-start: var(--switch-inset);
  inset-inline-start: var(--switch-inset);
  width: var(--switch-thumb);
  height: var(--switch-thumb);
  border-radius: 50%;
  background: #fff;
  box-shadow: 0 1px 3px rgba(21, 18, 32, 0.28);
  transition: inset-inline-start var(--flare-transition-normal);
}
.flare-switch.is-on .flare-switch__knob {
  inset-inline-start: calc(var(--switch-width) - var(--switch-thumb) - var(--switch-inset));
}
@media (prefers-reduced-motion: reduce) {
  .flare-switch, .flare-switch__knob { transition: none; }
}
</style>
