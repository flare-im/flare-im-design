<script setup lang="ts">
import { NIcon } from "naive-ui";
import type { Component } from "vue";

withDefaults(
  defineProps<{
    label: string;
    /** Non-interactive spinner state; falls back to `label` when no `loadingLabel`. */
    loading?: boolean;
    loadingLabel?: string;
    disabled?: boolean;
    /** Optional leading glyph (any Vue component, e.g. a `@vicons` icon). */
    icon?: Component;
  }>(),
  { loading: false, disabled: false },
);
const emit = defineEmits<{ (e: "click"): void }>();
</script>

<template>
  <button
    type="button"
    class="flare-primary-button"
    :disabled="disabled || loading"
    @click="emit('click')"
  >
    <span v-if="loading" class="flare-primary-button__spinner" aria-hidden="true" />
    <n-icon v-else-if="icon" :size="18" :component="icon" />
    <span>{{ loading ? loadingLabel || label : label }}</span>
  </button>
</template>

<style scoped>
.flare-primary-button {
  width: 100%;
  min-height: 48px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 0 20px;
  border: none;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: filter var(--flare-transition-fast, 150ms ease), transform var(--flare-transition-fast, 150ms ease), opacity var(--flare-transition-fast, 150ms ease);
}
.flare-primary-button:hover:not(:disabled) { filter: brightness(0.97); }
.flare-primary-button:active:not(:disabled) { transform: scale(0.99); }
.flare-primary-button:disabled { opacity: 0.55; cursor: not-allowed; }
.flare-primary-button__spinner {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, 0.4);
  border-top-color: #fff;
  animation: flare-pb-spin 0.7s linear infinite;
}
@media (prefers-reduced-motion: reduce) {
  .flare-primary-button__spinner { animation: none; }
}
@keyframes flare-pb-spin { to { transform: rotate(360deg); } }
</style>
