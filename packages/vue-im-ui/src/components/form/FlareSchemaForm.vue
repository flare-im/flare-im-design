<script setup lang="ts">
import { computed, useId } from "vue";
import {
  NButton,
  NFormItem,
  NInput,
  NInputNumber,
  NSelect,
  NSwitch,
} from "naive-ui";
import {
  schemaFields,
  schemaFieldValue,
  updateSchemaField,
  type SchemaField,
  type SchemaHint,
  type SchemaPresentation,
} from "./schema-fields";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";
import {
  schemaFieldPath,
  type SchemaSelection,
  type SchemaSelectionLabels,
} from "./schema-selections";
const props = defineProps<{
  selections?: Record<string, SchemaSelection>;
  selectionLabels?: SchemaSelectionLabels;
  path?: string;
  schema: Record<string, unknown>;
  modelValue: Record<string, unknown>;
  disabled?: boolean;
  uiHints?: Record<string, SchemaHint>;
  presentation?: Record<string, SchemaPresentation>;
  groupLabels?: Record<string, string>;
  resetLabel?: string;
  /** Two columns only when the form itself has enough room; defaults to one. */
  columns?: 1 | 2;
  /** Bounded nested object / object-array editing over a local schema. */
  depth?: number;
  addLabel?: string;
  removeLabel?: string;
}>();
const emit = defineEmits<{
  "update:modelValue": [value: Record<string, unknown>];
  "selection-search": [path: string, search: string];
  "selection-more": [path: string];
  "selection-retry": [path: string];
}>();
const fieldPrefix = useId();
const fields = computed(() =>
  schemaFields(props.schema, props.uiHints, props.presentation),
);
const groups = computed(() => [
  ...new Set(fields.value.map((field) => field.group ?? "")),
]);
const value = (field: SchemaField) => schemaFieldValue(props.modelValue, field);
const options = (field: SchemaField) =>
  (field.options ?? []).map((option) => ({
    label: props.presentation?.[field.id]?.options?.[option] ?? option,
    value: option,
  }));
function set(field: SchemaField, next: unknown) {
  if (!props.disabled)
    emit("update:modelValue", updateSchemaField(props.modelValue, field, next));
}
const path = (field: SchemaField) =>
  schemaFieldPath(props.path ?? "", field.id);
const selection = (field: SchemaField) => props.selections?.[path(field)];
function selectionOptions(field: SchemaField) {
  const state = selection(field)!;
  const list = [...state.options];
  if (state.emptyOptionLabel && !field.required)
    list.unshift({ value: "", label: state.emptyOptionLabel });
  const current = value(field);
  if (
    typeof current === "string" &&
    current &&
    !list.some((o) => o.value === current)
  )
    list.unshift({
      value: current,
      label: state.loading
        ? (props.selectionLabels?.loading ??
          props.selectionLabels?.placeholder ??
          field.title)
        : (props.selectionLabels?.unavailable ?? "Unavailable selection"),
      disabled: true,
    });
  return list;
}
function select(field: SchemaField, next: string) {
  const state = selection(field);
  if (!state || state.loading || state.error || state.disabled) return;
  if (next === "" && !field.required) set(field, undefined);
  else if (state.options.some((o) => o.value === next && !o.disabled))
    set(field, next);
}
const rows = (field: SchemaField) =>
  Array.isArray(value(field))
    ? (value(field) as Record<string, unknown>[]).slice(0, 32)
    : [];
function add(field: SchemaField) {
  set(field, [...rows(field), {}]);
}
function changeRow(
  field: SchemaField,
  index: number,
  row: Record<string, unknown>,
) {
  set(
    field,
    rows(field).map((v, i) => (i === index ? row : v)),
  );
}
function removeRow(field: SchemaField, index: number) {
  set(
    field,
    rows(field).filter((_, i) => i !== index),
  );
}
</script>
<template>
  <div
    class="flare-schema-form"
    :class="{ 'flare-schema-form--adaptive': columns === 2 }"
  >
    <section
      v-for="group in groups"
      :key="group"
      class="flare-schema-form-group"
    >
      <h3 v-if="group" class="flare-schema-form-heading">
        {{ groupLabels?.[group] ?? group }}
      </h3>
      <div class="flare-schema-form-fields">
        <NFormItem
          v-for="field in fields.filter((item) => (item.group ?? '') === group)"
          :key="field.id"
          :class="{
            'flare-schema-form-field--wide':
              !!field.childSchema || !!field.itemSchema,
          }"
          :label="field.title"
          :label-for="`${fieldPrefix}-${field.id}`"
          :required="field.required"
          :feedback="field.description"
        >
          <div class="flare-schema-form-control">
            <FlareSchemaForm
              v-if="field.childSchema && (depth ?? 0) < 4"
              :schema="field.childSchema"
              :model-value="(value(field) ?? {}) as Record<string, unknown>"
              :path="path(field)"
              :selections="selections"
              :selection-labels="selectionLabels"
              :ui-hints="uiHints"
              :group-labels="groupLabels"
              @selection-search="(p, q) => emit('selection-search', p, q)"
              @selection-more="emit('selection-more', $event)"
              @selection-retry="emit('selection-retry', $event)"
              :columns="columns"
              :depth="(depth ?? 0) + 1"
              :disabled="disabled"
              :presentation="presentation"
              :add-label="addLabel"
              :remove-label="removeLabel"
              :reset-label="resetLabel"
              @update:model-value="set(field, $event)"
            />
            <div
              v-else-if="field.itemSchema && (depth ?? 0) < 4"
              class="flare-schema-form-array"
            >
              <div
                v-for="(row, index) in rows(field)"
                :key="index"
                class="flare-schema-form-array-item"
              >
                <FlareSchemaForm
                  :schema="field.itemSchema"
                  :model-value="row"
                  :columns="columns"
                  :depth="(depth ?? 0) + 1"
                  :disabled="disabled"
                  :presentation="presentation"
                  :reset-label="resetLabel"
                  :add-label="addLabel"
                  :remove-label="removeLabel"
                  :path="schemaFieldPath(path(field), index)"
                  :selections="selections"
                  :selection-labels="selectionLabels"
                  :ui-hints="uiHints"
                  :group-labels="groupLabels"
                  @selection-search="(p, q) => emit('selection-search', p, q)"
                  @selection-more="emit('selection-more', $event)"
                  @selection-retry="emit('selection-retry', $event)"
                  @update:model-value="changeRow(field, index, $event)"
                />
                <NButton
                  :disabled="
                    disabled || rows(field).length <= (field.minItems ?? 0)
                  "
                  @click="removeRow(field, index)"
                  >{{ removeLabel ?? "−" }} {{ index + 1 }}</NButton
                >
              </div>
              <NButton
                :disabled="
                  disabled || rows(field).length >= (field.maxItems ?? 32)
                "
                @click="add(field)"
                >{{ addLabel ?? "+" }}</NButton
              >
            </div>
            <FlareAdminEntitySelect
              v-else-if="selection(field)"
              :label="field.title"
              :clearable="!field.required"
              :value="
                typeof value(field) === 'string' ? (value(field) as string) : ''
              "
              :options="selectionOptions(field)"
              :loading="selection(field)?.loading"
              :disabled="disabled || selection(field)?.disabled"
              :error="selection(field)?.error ?? selection(field)?.invalid"
              :has-more="selection(field)?.hasMore"
              :placeholder="
                selection(field)?.emptyOptionLabel ??
                selectionLabels?.placeholder ??
                field.title
              "
              :empty-text="selectionLabels?.empty ?? ''"
              :more-text="selectionLabels?.more ?? ''"
              :retry-text="selectionLabels?.retry ?? ''"
              @update:value="select(field, $event)"
              @search="emit('selection-search', path(field), $event)"
              @more="emit('selection-more', path(field))"
              @retry="emit('selection-retry', path(field))"
            />
            <NSelect
              v-else-if="field.options"
              :aria-label="field.title"
              :multiple="field.type === 'array'"
              :value="
                (value(field) ?? (field.type === 'array' ? [] : null)) as
                  string | string[] | null
              "
              :options="options(field)"
              :clearable="!field.required"
              :disabled="disabled"
              @update:value="set(field, $event)"
            />
            <!-- No step buttons: naive-ui draws them as unlabeled, unfocusable <button>s (axe button-name,
                 critical). The field is still a spinbutton; the arrow keys step it within minimum and maximum. -->
            <NInputNumber
              v-else-if="field.type === 'integer'"
              :show-button="false"
              :input-props="{
                id: `${fieldPrefix}-${field.id}`,
                'aria-label': field.title,
              }"
              :value="
                typeof value(field) === 'number'
                  ? (value(field) as number)
                  : null
              "
              :min="field.minimum"
              :max="field.maximum"
              :precision="0"
              :disabled="disabled"
              @update:value="set(field, $event)"
            />
            <NSwitch
              v-else-if="field.type === 'boolean'"
              :aria-label="field.title"
              :value="value(field) === true"
              :disabled="disabled"
              @update:value="set(field, $event)"
            />
            <NInput
              v-else
              :input-props="{
                id: `${fieldPrefix}-${field.id}`,
                'aria-label': field.title,
                ...(field.secret ? { autocomplete: 'off' } : {}),
              }"
              :type="field.secret ? 'password' : 'text'"
              :value="
                typeof value(field) === 'string' ? (value(field) as string) : ''
              "
              :disabled="disabled"
              :maxlength="field.maxLength ?? 4096"
              @update:value="set(field, $event)"
            />
            <NButton
              v-if="
                resetLabel &&
                !field.required &&
                !selection(field)?.emptyOptionLabel &&
                Object.hasOwn(modelValue, field.id)
              "
              text
              size="small"
              :disabled="disabled"
              :aria-label="`${resetLabel}: ${field.title}`"
              @click="set(field, undefined)"
              >{{ resetLabel }}</NButton
            >
          </div>
        </NFormItem>
      </div>
    </section>
  </div>
</template>
<style scoped>
.flare-schema-form,
.flare-schema-form-group,
.flare-schema-form-fields {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-schema-form {
  container: flare-schema-form / inline-size;
}
.flare-schema-form--adaptive .flare-schema-form-fields {
  column-gap: var(--flare-size-spacing-xl);
}
@container flare-schema-form (min-width: 600px) {
  .flare-schema-form--adaptive .flare-schema-form-fields {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
.flare-schema-form-fields {
  align-items: start;
}
.flare-schema-form-field--wide {
  grid-column: 1 / -1;
}
.flare-schema-form-heading {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
}
.flare-schema-form-control {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  width: 100%;
  min-width: 0;
  justify-items: start;
}
.flare-schema-form-array {
  display: grid;
  width: 100%;
  gap: var(--flare-size-spacing-md);
}
.flare-schema-form-array-item {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-md);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-md);
}
.flare-schema-form-control > :first-child:not(.n-switch) {
  width: 100%;
}
</style>
