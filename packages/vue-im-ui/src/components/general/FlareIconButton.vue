<script setup lang="ts">
import { computed, type Component } from "vue";
import { NIcon } from "naive-ui";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";

const props = withDefaults(
  defineProps<{
    icon: Component;
    ariaLabel: string;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Visual weight. */
    variant?: "plain" | "tinted" | "solid";
    shape?: "circle" | "square";
    disabled?: boolean;
    /** Toggle-active look (e.g. a selected filter). */
    active?: boolean;
    /** Exposes aria-pressed for controls that genuinely toggle state. */
    toggle?: boolean;
    /** Foreground/icon color override (overrides variant/active colors, incl. hover). */
    tint?: string;
    /** Background color override (overrides variant/active background). */
    background?: string;
    /** Dimension override in px; glyph size = round(customSize * 0.46). */
    customSize?: number;
  }>(),
  { variant: "plain", shape: "circle", disabled: false, active: false, toggle: false },
);
const emit = defineEmits<{ (e: "click"): void }>();
const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
const ariaPressed = computed(() => props.toggle || props.active ? props.active : undefined);
const overrideStyle = computed(() => {
  const s: Record<string, string> = {};
  if (props.tint) s.color = props.tint;
  if (props.background) s.background = props.background;
  if (props.customSize != null) {
    s.width = `${props.customSize}px`;
    s.height = `${props.customSize}px`;
    s.fontSize = `${Math.round(props.customSize * 0.46)}px`;
  }
  return s;
});
</script>

<template>
  <button
    type="button"
    class="flare-icon-button"
    :class="[`flare-icon-button--${rsize}`, `flare-icon-button--${variant}`, `is-${shape}`, { 'is-active': active }]"
    :style="overrideStyle"
    :aria-label="ariaLabel"
    :aria-pressed="ariaPressed"
    :disabled="disabled"
    @click="emit('click')"
  >
    <n-icon aria-hidden="true" :component="icon" />
  </button>
</template>

<style scoped>
.flare-icon-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  cursor: pointer;
  color: var(--flare-color-text-secondary);
  background: transparent;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast), transform var(--flare-transition-fast);
}
.flare-icon-button::after { content: ""; position: absolute; width: max(100%, var(--flare-size-layout-touch-target)); height: max(100%, var(--flare-size-layout-touch-target)); }
.flare-icon-button:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-icon-button:active:not(:disabled) { transform: scale(0.92); }
.flare-icon-button:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.is-circle { border-radius: 50%; }
.is-square { border-radius: var(--flare-size-radius-md); }

.flare-icon-button--sm { width: var(--flare-size-layout-control-height-sm); height: var(--flare-size-layout-control-height-sm); font-size: var(--flare-size-icon-size-sm); }
.flare-icon-button--md { width: var(--flare-size-layout-control-height-md); height: var(--flare-size-layout-control-height-md); font-size: var(--flare-size-icon-size-md); }
.flare-icon-button--lg { width: var(--flare-size-layout-control-height-lg); height: var(--flare-size-layout-control-height-lg); font-size: var(--flare-size-icon-size-lg); }

.flare-icon-button--plain:hover:not(:disabled) { background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary); }
.flare-icon-button--tinted { background: var(--flare-color-bg-secondary); }
.flare-icon-button--tinted:hover:not(:disabled) { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
.flare-icon-button--solid { background: var(--flare-color-primary); color: #fff; }
.flare-icon-button--solid:hover:not(:disabled) { background: var(--flare-color-primary-hover); }
.flare-icon-button.is-active { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
@media (prefers-reduced-motion: reduce) {
  .flare-icon-button { transition: none; }
  .flare-icon-button:active:not(:disabled) { transform: none; }
}
</style>
