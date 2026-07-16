<script setup lang="ts">
// A form field wrapper — label (+ required mark), the control (default slot),
// an optional hint, and an error message that replaces the hint when present.
defineProps<{
  label?: string;
  required?: boolean;
  hint?: string;
  error?: string;
}>();
</script>

<template>
  <div class="flare-form-field" :class="{ 'has-error': !!error }">
    <label v-if="label" class="flare-form-field__label">
      {{ label }}<span v-if="required" class="flare-form-field__req">*</span>
    </label>
    <div class="flare-form-field__control"><slot /></div>
    <p v-if="error" class="flare-form-field__error">{{ error }}</p>
    <p v-else-if="hint" class="flare-form-field__hint">{{ hint }}</p>
  </div>
</template>

<style scoped>
.flare-form-field { display: flex; flex-direction: column; gap: 6px; }
.flare-form-field__label {
  font-size: 13px;
  font-weight: 500;
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-form-field__req { color: var(--flare-color-error, #ef4444); margin-left: 2px; }
.flare-form-field__control { display: flex; flex-direction: column; }
.flare-form-field__hint { margin: 0; font-size: 12px; color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-form-field__error { margin: 0; font-size: 12px; color: var(--flare-color-error, #ef4444); }
</style>
