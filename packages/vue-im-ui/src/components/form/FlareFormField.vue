<script setup lang="ts">
import { computed, useId } from "vue";
import { provideFlareFormField } from "../../shared/useFlareFormField";
// A form field wrapper — label (+ required mark), the control (default slot),
// an optional hint, and an error message that replaces the hint when present.
//
// The label points at the control: the field mints an id and provides it, with
// the hint / error id and the invalid / required state, to the kit control inside
// (Input, Textarea, Select, Switch, Slider, Stepper), which binds them to its
// native element. The label only gets `for` while such a control owns the id.
const props = defineProps<{
  label?: string;
  required?: boolean;
  hint?: string;
  error?: string;
  /** Use this id instead of the generated one; a host control of its own renders it and wires `${controlId}-hint` / `${controlId}-error`. */
  controlId?: string;
}>();
const uid = useId();
const id = computed(() => props.controlId ?? `flare-field-${uid}`);
const labelId = computed(() => `${id.value}-label`);
const hintId = computed(() => `${id.value}-hint`);
const errorId = computed(() => `${id.value}-error`);
const { boundId } = provideFlareFormField({
  id,
  labelId: computed(() => (props.label ? labelId.value : undefined)),
  describedBy: computed(() => (props.error ? errorId.value : props.hint ? hintId.value : undefined)),
  invalid: computed(() => Boolean(props.error)),
  required: computed(() => props.required),
});
const labelFor = computed(() => boundId.value ?? props.controlId);
</script>

<template>
  <div class="flare-form-field" :class="{ 'has-error': !!error }">
    <label v-if="label" :id="labelId" class="flare-form-field__label" :for="labelFor">
      {{ label }}<span v-if="required" class="flare-form-field__req">*</span>
    </label>
    <div class="flare-form-field__control">
      <slot />
    </div>
    <p v-if="error" :id="errorId" class="flare-form-field__error">{{ error }}</p>
    <p v-else-if="hint" :id="hintId" class="flare-form-field__hint">{{ hint }}</p>
  </div>
</template>

<style scoped>
.flare-form-field { display: flex; flex-direction: column; gap: 6px; }
.flare-form-field__label {
  font-size: var(--flare-component-form-label-size);
  font-weight: var(--flare-component-form-label-weight);
  color: var(--flare-component-form-label-color);
}
.flare-form-field__req { color: var(--flare-color-error-text); margin-left: 2px; }
.flare-form-field__control { display: flex; flex-direction: column; }
.flare-form-field__hint { margin: 0; font-size: 12px; color: var(--flare-color-text-tertiary); }
.flare-form-field__error { margin: 0; font-size: 12px; color: var(--flare-color-error-text); }
</style>
