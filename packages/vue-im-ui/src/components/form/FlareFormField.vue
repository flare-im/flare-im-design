<script setup lang="ts">
import { computed, useId } from "vue";
import { NFormItem } from "naive-ui";
import FlareIcon from "../general/FlareIcon.vue";
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
  /** Fill the remaining height of a bounded form with a scrollable picker or long control. */
  fill?: boolean;
  required?: boolean;
  hint?: string;
  hintTone?: "warning";
  /** Informational character count under the control at its end (R6); never part of the control's name. */
  counter?: string;
  error?: string;
  /** Use this id instead of the generated one; a host control of its own renders it and wires `${controlId}-hint` / `${controlId}-error`. */
  controlId?: string;
  /** Keep the visible label alongside compact administrative controls. */
  labelPlacement?: "top" | "left";
  /** A single native query field, measured and folded by FlareAdminList. */
  native?: boolean;
}>();
const uid = useId();
const id = computed(() => props.controlId ?? `flare-field-${uid}`);
const labelId = computed(() => `${id.value}-label`);
const hintId = computed(() => `${id.value}-hint`);
const errorId = computed(() => `${id.value}-error`);
const counterId = computed(() => `${id.value}-counter`);
const describedBy = computed(() => props.error ? errorId.value
  : [props.hint ? hintId.value : undefined, props.counter ? counterId.value : undefined].filter(Boolean).join(' ') || undefined);
const { boundId } = provideFlareFormField({
  id,
  labelId: computed(() => (props.label ? labelId.value : undefined)),
  describedBy,
  invalid: computed(() => Boolean(props.error)),
  required: computed(() => props.required),
});
const labelFor = computed(
  () =>
    boundId.value ?? props.controlId ?? (props.native ? id.value : undefined),
);
</script>

<template>
  <NFormItem
    v-if="native"
    :label="label"
    label-width="max-content"
    :content-style="{ minWidth: '0' }"
    :label-props="{ id: labelId, for: labelFor }"
    :required="required"
    :show-feedback="!!(error || hint || counter)"
    :validation-status="error ? 'error' : undefined"
  >
    <slot
      :control-id="id"
      :label-id="labelId"
      :described-by="describedBy"
      :invalid="!!error"
    />
    <template #feedback>
      <span v-if="error" :id="errorId">{{ error }}</span>
      <template v-else><span v-if="hint" :id="hintId">{{ hint }}</span><span v-if="counter" :id="counterId" class="flare-form-field__counter">{{ counter }}</span></template>
    </template>
  </NFormItem>
  <div
    v-else
    class="flare-form-field"
    :class="{
      'has-error': !!error,
      'is-fill': fill,
      'flare-form-field--inline': labelPlacement === 'left',
    }"
  >
    <div v-if="label" class="flare-form-field__header">
      <!-- The control carries aria-required, which screen readers say as 「必填」; the star is only seen. -->
      <label
        :id="labelId"
        class="flare-form-field__label"
        :for="labelFor"
      >
        {{ label }}<span v-if="required" class="flare-form-field__req" aria-hidden="true">*</span>
      </label>
    </div>
    <div class="flare-form-field__control">
      <slot
        :control-id="id"
        :label-id="labelId"
        :described-by="describedBy"
        :invalid="!!error"
      />
    </div>
    <!-- R6: under the control — the error (icon 16 + caption) or the help, and the counter at the end. -->
    <div v-if="error || hint || counter" class="flare-form-field__footer">
      <p v-if="error" :id="errorId" class="flare-form-field__error">
        <FlareIcon name="error" size="sm" aria-hidden="true" /><span>{{ error }}</span>
      </p>
      <p v-else-if="hint" :id="hintId" class="flare-form-field__hint" :class="{ 'is-warning': hintTone === 'warning' }" :role="hintTone === 'warning' ? 'status' : undefined">
        {{ hint }}
      </p>
      <span v-if="counter" :id="counterId" class="flare-form-field__counter">{{ counter }}</span>
    </div>
  </div>
</template>

<style scoped>
.flare-form-field {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-2xs);
}
.flare-form-field.is-fill { flex: 1 1 auto; min-height: 0; }
.flare-form-field.is-fill > .flare-form-field__control { flex: 1; min-height: 0; }
.flare-form-field__header { display: flex; align-items: baseline; justify-content: space-between; min-width: 0; gap: var(--flare-size-spacing-sm); }
.flare-form-field__footer { display: flex; align-items: flex-start; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-form-field__counter { flex: none; margin-inline-start: auto; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-regular); font-variant-numeric: tabular-nums; }
.flare-form-field__label {
  font-size: var(--flare-component-form-label-size);
  font-weight: var(--flare-component-form-label-weight);
  color: var(--flare-component-form-label-color);
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-form-field__req {
  color: var(--flare-color-error-text);
  margin-inline-start: var(--flare-size-spacing-3xs);
}
.flare-form-field__control {
  display: flex;
  flex-direction: column;
}
.flare-form-field__hint {
  min-width: 0;
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
}
.flare-form-field__hint.is-warning { color: var(--flare-color-warning-text); }
.flare-form-field__error {
  display: flex;
  align-items: flex-start;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-error-text);
}
.flare-form-field__error > .flare-icon { flex: none; }
.flare-form-field--inline {
  display: grid;
  grid-template-columns: fit-content(40%) minmax(0, 1fr);
  align-items: center;
  column-gap: var(--flare-size-spacing-sm);
}
.flare-form-field--inline > .flare-form-field__header {
  grid-column: 1;
  grid-row: 1;
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-form-field--inline > .flare-form-field__control {
  grid-column: 2;
  grid-row: 1;
  min-width: 0;
}
.flare-form-field--inline > .flare-form-field__footer {
  grid-column: 2;
}
</style>
