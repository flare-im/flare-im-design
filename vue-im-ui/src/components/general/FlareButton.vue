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
const rsize = computed(() => props.size ?? config.value.size);
</script>

<template>
  <button
    type="button"
    class="flare-button"
    :class="[`flare-button--${variant}`, `flare-button--${rsize}`, { 'is-block': block, 'is-loading': loading }]"
    :disabled="disabled || loading"
    @click="emit('click')"
  >
    <span v-if="loading" class="flare-button__spinner" aria-hidden="true" />
    <n-icon v-else-if="icon" class="flare-button__icon" :component="icon" />
    <span v-if="label || $slots.default" class="flare-button__label"><slot>{{ label }}</slot></span>
  </button>
</template>

<style scoped>
.flare-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  border: 1px solid transparent;
  border-radius: var(--flare-size-radius-lg, 10px);
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
  transition: filter var(--flare-transition-fast, 150ms ease), background var(--flare-transition-fast, 150ms ease),
    border-color var(--flare-transition-fast, 150ms ease), transform var(--flare-transition-fast, 150ms ease),
    opacity var(--flare-transition-fast, 150ms ease);
}
.flare-button.is-block { width: 100%; }
.flare-button:active:not(:disabled) { transform: scale(0.98); }
.flare-button:disabled { opacity: 0.5; cursor: not-allowed; }
.flare-button__icon { font-size: 1.1em; }

/* sizes */
.flare-button--sm { height: 32px; padding: 0 12px; font-size: 13px; }
.flare-button--md { height: 40px; padding: 0 18px; font-size: 14px; }
.flare-button--lg { height: 48px; padding: 0 24px; font-size: 15px; }

/* variants */
.flare-button--primary {
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
}
.flare-button--primary:hover:not(:disabled) { filter: brightness(0.97); }
.flare-button--secondary {
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-primary, #15131c);
  border-color: var(--flare-color-border-primary, #e9e6f1);
}
.flare-button--secondary:hover:not(:disabled) { background: var(--flare-color-bg-selected, #f1eaff); border-color: var(--flare-color-primary, #7c3aed); }
.flare-button--ghost {
  background: transparent;
  color: var(--flare-color-primary, #7c3aed);
  border-color: color-mix(in srgb, var(--flare-color-primary, #7c3aed) 40%, transparent);
}
.flare-button--ghost:hover:not(:disabled) { background: var(--flare-color-bg-selected, #f1eaff); }
.flare-button--danger {
  background: var(--flare-color-error, #ef4444);
  color: #fff;
}
.flare-button--danger:hover:not(:disabled) { filter: brightness(0.95); }
.flare-button--text {
  background: transparent;
  color: var(--flare-color-primary, #7c3aed);
  padding-left: 8px;
  padding-right: 8px;
}
.flare-button--text:hover:not(:disabled) { background: var(--flare-color-bg-secondary, #f6f5fb); }

.flare-button__spinner {
  width: 15px;
  height: 15px;
  border-radius: 50%;
  border: 2px solid currentColor;
  border-top-color: transparent;
  opacity: 0.85;
  animation: flare-btn-spin 0.7s linear infinite;
}
@media (prefers-reduced-motion: reduce) { .flare-button__spinner { animation: none; } }
@keyframes flare-btn-spin { to { transform: rotate(360deg); } }
</style>
