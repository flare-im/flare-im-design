<script setup lang="ts">
import { computed, type Component } from "vue";
import { NIcon } from "naive-ui";
import type { FlareButtonVariant, FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";

const props = withDefaults(
  defineProps<{
    label?: string;
    variant?: FlareButtonVariant;
    /** Falls back to the global config size (default "md") when omitted. */
    size?: FlareControlSize;
    loading?: boolean;
    disabled?: boolean;
    /** Full-width. */
    block?: boolean;
    /** Optional leading glyph. */
    icon?: Component;
  }>(),
  { variant: "primary", loading: false, disabled: false, block: false },
);
const emit = defineEmits<{ (e: "click"): void }>();
const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
</script>

<template>
  <button
    type="button"
    class="flare-button"
    :class="[`flare-button--${variant}`, `flare-button--${rsize}`, { 'is-block': block, 'is-loading': loading }]"
    :disabled="disabled || loading"
    :aria-busy="loading"
    @click="emit('click')"
  >
    <span v-if="loading" class="flare-button__spinner" aria-hidden="true" />
    <n-icon aria-hidden="true" v-else-if="icon" class="flare-button__icon" :component="icon" />
    <span v-if="label || $slots.default" class="flare-button__label"><slot>{{ label }}</slot></span>
  </button>
</template>

<style scoped>
.flare-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-xs);
  border: 1px solid transparent;
  /* radius-lg (10px) — Flutter/Compose/SwiftUI all draw the button at radiusLg;
     the Vue box was the only one still at radius-md (8px). */
  border-radius: var(--flare-size-radius-lg);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: filter var(--flare-transition-fast), background var(--flare-transition-fast),
    border-color var(--flare-transition-fast), transform var(--flare-transition-fast),
    opacity var(--flare-transition-fast);
}
.flare-button::after { content: ""; position: absolute; width: max(100%, var(--flare-size-layout-touch-target)); height: max(100%, var(--flare-size-layout-touch-target)); }
.flare-button:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-button.is-block { width: 100%; }
.flare-button:active:not(:disabled) { transform: scale(0.98); }
.flare-button:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.flare-button__icon { font-size: 1.1em; }

/* sizes */
.flare-button--sm { height: var(--flare-size-layout-control-height-sm); padding: 0 var(--flare-size-layout-control-pad-xsm); font-size: var(--flare-size-font-size-md); }
.flare-button--md { height: var(--flare-size-layout-control-height-md); padding: 0 var(--flare-size-layout-control-pad-xmd); font-size: var(--flare-size-font-size-lg); }
.flare-button--lg { height: var(--flare-size-layout-control-height-lg); padding: 0 var(--flare-size-layout-control-pad-xlg); font-size: var(--flare-size-font-size-xl); }

/* variants */
.flare-button--primary {
  background: var(--flare-color-primary);
  color: #fff;
}
.flare-button--primary:hover:not(:disabled) { background: var(--flare-color-primary-hover); }
.flare-button--primary:active:not(:disabled) { background: var(--flare-color-primary-active); }
.flare-button--secondary {
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  border-color: var(--flare-color-border-primary);
}
.flare-button--secondary:hover:not(:disabled) { background: var(--flare-color-bg-selected); border-color: var(--flare-color-primary); }
.flare-button--ghost {
  background: transparent;
  color: var(--flare-color-primary-text);
  border-color: color-mix(in srgb, var(--flare-color-primary) 40%, transparent);
}
.flare-button--ghost:hover:not(:disabled) { background: var(--flare-color-bg-selected); }
.flare-button--danger {
  background: var(--flare-color-error);
  color: #fff;
}
.flare-button--danger:hover:not(:disabled) { filter: brightness(0.95); }
.flare-button--text {
  background: transparent;
  color: var(--flare-color-primary-text);
  padding-left: 8px;
  padding-right: 8px;
}
.flare-button--text:hover:not(:disabled) { background: var(--flare-color-bg-secondary); }

.flare-button__spinner {
  width: 15px;
  height: 15px;
  border-radius: 50%;
  border: 2px solid currentColor;
  border-top-color: transparent;
  opacity: 0.85;
  animation: flare-btn-spin 0.7s linear infinite;
}
@media (prefers-reduced-motion: reduce) {
  .flare-button { transition: none; }
  .flare-button:active:not(:disabled) { transform: none; }
  .flare-button__spinner { animation: none; }
}
@keyframes flare-btn-spin { to { transform: rotate(360deg); } }
</style>
