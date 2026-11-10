<script setup lang="ts">
import { computed, getCurrentInstance, h, onBeforeUnmount, reactive, ref, useSlots, watch } from "vue";
import PluginFormInput, {
  type PluginFormInputState,
} from "./PluginFormInput.vue";
import type {
  SchemaSelection,
  SchemaSelectionLabels,
} from "./schema-selections";
import FlareButton from "../general/FlareButton.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareContactPicker from "../composer/FlareContactPicker.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import type { FlareContactPickerEntry } from "../../shared/contracts/contact-picker";
import {
  flarePluginCheckInput,
  flarePluginDraft,
  flarePluginFormValues,
  flarePluginIssueText,
  flarePluginMaxItems,
  flarePluginMinRows,
  flarePluginReferenceParents,
  flarePluginFileValue,
  flarePluginNewFileScope,
  flarePluginVisibleInputs,
  type FlarePluginFileAction,
  type FlarePluginFileActionKind,
  type FlarePluginFileState,
  type FlarePluginFormError,
  type FlarePluginInput,
  type FlarePluginMember,
  type FlarePluginReferenceRequest,
  type FlarePluginStrings,
} from "../../shared/contracts/plugin-ui";

// The inputs of a plugin action, put in the kit bottom sheet by the host (or by PluginView for a card
// action). The kit checks only required and length, at once for an input that was edited and for every
// input after a submit attempt; the core SDK's validate_form decides, and its errors (`errors`) show
// under their inputs until that input is edited. Submit hands over the cleaned values
// (spec/plugin-view-vectors.json → form).
const props = withDefaults(
  defineProps<{
    inputs: FlarePluginInput[];
    /** Host-owned directory choices keyed by input id; never enables free-text IDs. */
    selections?: Record<string, SchemaSelection>;
    selectionLabels?: SchemaSelectionLabels;
    /** Initial values by input id; an input without one starts from its default. */
    values?: Record<string, unknown>;
    /** Original record when a host opens a form with a proposed edit already applied. */
    baselineValues?: Record<string, unknown>;
    /** The host's errors (UiFormError). */
    errors?: FlarePluginFormError[];
    submitLabel?: string;
    cancelLabel?: string;
    /** Same typed inputs/validation; compact query presentation for administrative filters. */
    presentation?: "form" | "filters";
    /** Host-only control presentation for administrative action forms; not a plugin wire field. */
    selectPresentation?: "radio" | "dropdown";
    /** Page-owned form: no sheet insets or cancel key; the page owns navigation. */
    embedded?: boolean;
    busy?: boolean;
    /** Editing an existing record may require an actual typed value change. */
    requireChange?: boolean;
    /** A failure line above the keys. */
    error?: string;
    /** Candidates for members inputs. */
    members?: FlarePluginMember[];
    membersLoading?: boolean;
    membersRevision?: number;
    membersError?: string;
    onMemberSearch?: (query: string) => void;
    onMembersRetry?: () => void;
    fileStates?: Record<string, FlarePluginFileState>;
  }>(),
  {
    values: undefined,
    errors: () => [],
    submitLabel: undefined,
    presentation: "form",
    selectPresentation: "radio",
    embedded: false,
    busy: false,
    error: undefined,
    members: () => [],
  },
);
const emit = defineEmits<{
  (e: "submit", values: Record<string, unknown>): void;
  (e: "cancel"): void;
  (e: "selection-search", id: string, query: string): void;
  (e: "selection-retry", id: string): void;
  (e: "selection-more", id: string): void;
  /** A reference request or selected-value update; hosts may retain the same directory's options. */
  (e: "reference-load", request: FlarePluginReferenceRequest): void;
  (e: "file-action", request: FlarePluginFileAction): void;
}>();
const { t } = useFlareI18nOptional();
const slots = useSlots();
const instance = getCurrentInstance();

const strings = computed<FlarePluginStrings>(() => ({
  deadlinePassed: t("pluginView.deadlinePassed"),
  remaining: t("pluginView.remaining"),
  dateTime: t("pluginView.dateTime"),
  dateTimeYear: t("pluginView.dateTimeYear"),
  days: t("pluginView.days"),
  hours: t("pluginView.hours"),
  minutes: t("pluginView.minutes"),
  required: t("pluginForm.required"),
  tooLong: t("pluginForm.tooLong"),
  outOfRange: t("pluginForm.outOfRange"),
  tooFewItems: t("pluginForm.tooFewItems"),
  tooManyItems: t("pluginForm.tooManyItems"),
  duplicateItem: t("pluginForm.duplicateItem"),
  invalid: t("pluginForm.invalid"),
}));

const draft = reactive<Record<string, unknown>>({});
const edited = reactive(new Set<string>());
/** Inputs edited since the host's errors arrived: their host error no longer applies. */
const editedSinceErrors = reactive(new Set<string>());
const attempted = ref(false);
const initialValues = ref("");
const unchanged = computed(
  () =>
    props.requireChange &&
    JSON.stringify(flarePluginFormValues(props.inputs, draft)) ===
      initialValues.value,
);
const numberText = reactive<Record<string, string>>({});
const fileScope = ref("");
const fileGenerations = reactive<Record<string, number>>({});
const localFiles = reactive<Record<string, FlarePluginFileState>>({});
const visibleInputs = computed(() => flarePluginVisibleInputs(props.inputs, draft));
function fileState(input: FlarePluginInput): FlarePluginFileState {
  const generation = fileGenerations[input.id] ?? 0;
  const controlled = props.fileStates?.[input.id];
  if (controlled?.scope === fileScope.value && controlled.generation === generation) return controlled;
  const local = localFiles[input.id];
  if (local?.scope === fileScope.value && local.generation === generation) return local;
  const value = draft[input.id];
  return { scope: fileScope.value, generation, phase: flarePluginFileValue(value) ? "uploaded" : "empty",
    ...(flarePluginFileValue(value) ? { value } : {}) };
}
const filesPending = computed(() => visibleInputs.value.some((input) => {
  if (input.kind !== "file") return false;
  const state = fileState(input);
  return state.phase !== "empty" && (state.phase !== "uploaded" || !flarePluginFileValue(state.value ?? draft[input.id]));
}));
function fileAction(input: FlarePluginInput, action: FlarePluginFileActionKind): void {
  if (input.kind !== "file" || (action !== "invalidate" && (props.busy || !visibleInputs.value.includes(input)))) return;
  if (action !== "preview") {
    fileGenerations[input.id] = (fileGenerations[input.id] ?? 0) + 1;
    draft[input.id] = null;
    editedSinceErrors.add(input.id);
    localFiles[input.id] = { scope: fileScope.value, generation: fileGenerations[input.id],
      phase: ["choose", "replace", "retry"].includes(action) ? "selected" : "empty" };
  }
  emit("file-action", { action, inputId: input.id, input, scope: fileScope.value,
    generation: fileGenerations[input.id] ?? 0, formValues: flarePluginFormValues(props.inputs, draft) });
}
const dateParts = reactive<Record<string, { date: string; time: string }>>({});
const pad2 = (n: number) => String(n).padStart(2, "0");
/** A new form (other inputs or initial values, compared by content): start over from them. */
function reset(): void {
  if (fileScope.value) for (const input of props.inputs) if (input.kind === "file") fileAction(input, "invalidate");
  fileScope.value = flarePluginNewFileScope();
  for (const id of Object.keys(fileGenerations)) delete fileGenerations[id];
  for (const id of Object.keys(localFiles)) delete localFiles[id];
  for (const key of Object.keys(draft)) delete draft[key];
  Object.assign(draft, flarePluginDraft(props.inputs, props.values));
  for (const input of props.inputs) {
    if (
      (props.selections?.[input.id] ||
        (input.kind === "options" && input.choices?.length)) &&
      Array.isArray(draft[input.id])
    )
      draft[input.id] = (draft[input.id] as unknown[]).filter(
        (value) => value !== "",
      );
    const value = draft[input.id];
    if (input.kind === "number")
      numberText[input.id] = typeof value === "number" ? String(value) : "";
    if (input.kind === "datetime") {
      const d = typeof value === "number" ? new Date(value) : null;
      dateParts[input.id] = d
        ? {
            date: `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`,
            time: `${pad2(d.getHours())}:${pad2(d.getMinutes())}`,
          }
        : { date: "", time: "" };
    }
  }
  initialValues.value = JSON.stringify(
    flarePluginFormValues(
      props.inputs,
      props.baselineValues
        ? flarePluginDraft(props.inputs, props.baselineValues)
        : draft,
    ),
  );
  edited.clear();
  editedSinceErrors.clear();
  attempted.value = false;
}
watch(
  () =>
    JSON.stringify([
      props.inputs,
      props.values ?? null,
      props.baselineValues ?? null,
    ]),
  reset,
  { immediate: true },
);
watch(() => props.fileStates, () => {
  for (const input of visibleInputs.value) {
    if (input.kind !== "file") continue;
    const state = props.fileStates?.[input.id];
    if (state?.scope !== fileScope.value || state.generation !== (fileGenerations[input.id] ?? 0)) continue;
    const value = state.phase === "uploaded" && flarePluginFileValue(state.value) ? { fileId: state.value.fileId } : undefined;
    draft[input.id] = value ?? null;
    // A normal host refresh may release its upload owner and local preview.
    // Keep only this ticket's completed reference, never its preview capability.
    localFiles[input.id] = { scope: state.scope, generation: state.generation,
      phase: state.phase === "uploaded" && !value ? "failed" : state.phase,
      ...(value ? { value } : {}), fileName: state.fileName, error: state.error, preview: false };
  }
}, { deep: true });
onBeforeUnmount(() => { for (const input of props.inputs) if (input.kind === "file") fileAction(input, "invalidate"); });
watch(
  () => JSON.stringify(props.errors),
  () => editedSinceErrors.clear(),
);

// A reference input is a directory the host fills: closed until the host answers and its parents hold values, so
// a viewer without the permission never gets a free-text or stale control.
const CLOSED: SchemaSelection = { options: [], disabled: true };
const referenceParents = (input: FlarePluginInput) =>
  input.reference
    ? flarePluginReferenceParents(input.reference, (id) => draft[id])
    : null;
function selectionOf(input: FlarePluginInput): SchemaSelection | undefined {
  const selection = props.selections?.[input.id];
  // Options that declare their choices pick from them: nothing to load, nothing to type.
  if (input.kind === "options" && input.choices?.length)
    return selection ?? { options: [...input.choices], remote: false };
  if (!input.reference) return selection;
  return referenceParents(input) ? (selection ?? CLOSED) : CLOSED;
}
const referenceRequests = computed<FlarePluginReferenceRequest[]>(() =>
  props.inputs.flatMap((input) => {
    const parents = referenceParents(input);
    if (!input.reference || !parents) return [];
    const selected =
      typeof draft[input.id] === "string" && draft[input.id]
        ? (draft[input.id] as string)
        : undefined;
    return [{ id: input.id, reference: input.reference, parents, selected }];
  }),
);
const askedFor = new Map<string, string>();
// Keep the host's selected value current for search/hydration; it decides when options need a read.
watch(
  referenceRequests,
  (requests) => {
    for (const request of requests) {
      const key = JSON.stringify([
        request.reference,
        request.parents,
        request.selected,
      ]);
      if (askedFor.get(request.id) === key) continue;
      askedFor.set(request.id, key);
      emit("reference-load", request);
    }
  },
  { immediate: true },
);

function set(id: string, value: unknown): void {
  const changed = !Object.is(draft[id], value);
  draft[id] = value;
  edited.add(id);
  editedSinceErrors.add(id);
  const dependents = changed ? props.inputs.filter((input) => input.showWhen?.field === id) : [];
  for (const dependent of dependents) {
    draft[dependent.id] = null;
    delete numberText[dependent.id];
    dateParts[dependent.id] = { date: "", time: "" };
    edited.delete(dependent.id);
    editedSinceErrors.add(dependent.id);
  }
  for (const dependent of dependents) if (dependent.kind === "file") fileAction(dependent, "invalidate");
}

/** The text under an input: the host's first error for it, else the client's issue once it may show. */
function errorText(input: FlarePluginInput): string | undefined {
  if (!editedSinceErrors.has(input.id)) {
    const host = props.errors.find((e) => e.input === input.id);
    if (host) return flarePluginIssueText(host.issue, input, strings.value);
  }
  const directory = selectionOf(input);
  if (directory?.error || directory?.invalid)
    return directory.error || directory.invalid;
  if (!attempted.value && !edited.has(input.id)) return undefined;
  if (directory && !directory.loading && !validSelection(input))
    return props.selectionLabels?.unavailable || strings.value.invalid;
  const issue = flarePluginCheckInput(input, draft[input.id]);
  return issue ? flarePluginIssueText(issue, input, strings.value) : undefined;
}

function submit(): void {
  if (props.busy || unchanged.value || filesPending.value) return;
  attempted.value = true;
  if (
    visibleInputs.value.some(
      (input) =>
        flarePluginCheckInput(input, draft[input.id]) || !validSelection(input),
    )
  )
    return;
  const values = flarePluginFormValues(props.inputs, draft);
  for (const input of props.inputs)
    if (input.kind === "password") draft[input.id] = "";
  emit("submit", values);
}
function cancel(): void {
  if (!props.busy) {
    for (const input of props.inputs)
      if (input.kind === "password") draft[input.id] = "";
    emit("cancel");
  }
}
/** A query reset also discards unapplied edits when the controlled values were already empty. */
function resetFilters(): void {
  if (props.busy) return;
  reset();
  cancel();
}

function validSelection(input: FlarePluginInput): boolean {
  const selection = selectionOf(input);
  if (!selection) return true;
  const values = Array.isArray(draft[input.id])
    ? (draft[input.id] as unknown[])
    : draft[input.id]
      ? [draft[input.id]]
      : [];
  // An optional reference the viewer cannot read stays empty and does not hold the form back.
  if (input.reference && selection.disabled && !values.length)
    return !input.required;
  if (
    selection.loading ||
    selection.error ||
    selection.invalid ||
    selection.disabled
  )
    return false;
  return values.every((value) =>
    selection.options.some(
      (option) => option.value === value && !option.disabled,
    ),
  );
}
function directoryOptions(input: FlarePluginInput) {
  const selection = selectionOf(input);
  const options = [...(selection?.options ?? [])];
  const values = Array.isArray(draft[input.id])
    ? (draft[input.id] as unknown[])
    : draft[input.id]
      ? [draft[input.id]]
      : [];
  for (const value of values)
    if (
      typeof value === "string" &&
      !options.some((option) => option.value === value)
    )
      options.push({
        value,
        label: props.selectionLabels?.unavailable || input.label,
        disabled: true,
      });
  return options;
}

// ── number ──
function setNumber(id: string, text: string): void {
  numberText[id] = text;
  const value = text.trim() === "" ? null : Number(text);
  set(id, value === null || Number.isNaN(value) ? null : value);
}

// ── datetime: the kit's date and time pickers in the device zone; a value once both are set ──
function setDatePart(id: string, part: "date" | "time", value: string): void {
  const parts = { ...(dateParts[id] ?? { date: "", time: "" }), [part]: value };
  dateParts[id] = parts;
  const [y, m, d] = parts.date.split("-").map(Number);
  const [hh, mm] = parts.time.split(":").map(Number);
  const ms =
    parts.date && parts.time
      ? new Date(y, m - 1, d, hh, mm).getTime()
      : Number.NaN;
  set(id, Number.isFinite(ms) ? ms : null);
}

// ── options ──
const rowsOf = (id: string) =>
  Array.isArray(draft[id]) ? (draft[id] as string[]) : [];
function setRow(id: string, index: number, value: string): void {
  const rows = [...rowsOf(id)];
  rows[index] = value;
  set(id, rows);
}
function addRow(input: FlarePluginInput): void {
  if (rowsOf(input.id).length < flarePluginMaxItems(input))
    set(input.id, [...rowsOf(input.id), ""]);
}
function removeRow(input: FlarePluginInput, index: number): void {
  if (rowsOf(input.id).length > flarePluginMinRows(input))
    set(
      input.id,
      rowsOf(input.id).filter((_, i) => i !== index),
    );
}

// ── members: the kit ContactPicker over the host's candidates ──
const picking = ref<FlarePluginInput | null>(null);
let pickingRevision = props.membersRevision ?? 0;
const chosenMembers = ref<Record<string, FlarePluginMember>>({});
watch(() => props.membersRevision ?? 0, () => {
  picking.value = null;
  chosenMembers.value = {};
  for (const input of props.inputs) if (input.kind === "members") set(input.id, []);
});
watch(picking, input => { if (input) { pickingRevision = props.membersRevision ?? 0; props.onMemberSearch?.(""); } });
const memberEntries = computed<FlareContactPickerEntry[]>(() =>
  props.members.map((m) => ({
    userId: m.userId,
    name: m.name,
    avatarUrl: m.avatarUrl,
  })),
);
const chosenNames = (id: string) => {
  const ids = Array.isArray(draft[id]) ? (draft[id] as string[]) : [];
  return ids
    .map(
      (userId) =>
        props.members.find((m) => m.userId === userId)?.name ?? chosenMembers.value[userId]?.name ?? userId,
    )
    .join("、");
};
function pickMembers(entries: FlareContactPickerEntry[]): void {
  if (pickingRevision !== (props.membersRevision ?? 0) || props.membersLoading || props.membersError) return;
  const input = picking.value;
  picking.value = null;
  if (input) {
    const selected = entries.flatMap(entry => props.members.find(member => member.userId === entry.userId) ?? []).slice(0, flarePluginMaxItems(input));
    for (const member of selected) chosenMembers.value[member.userId] = member;
    set(
      input.id,
      selected.map(member => member.userId),
    );
  }
}

const choicesOf = (input: FlarePluginInput) =>
  (input.choices ?? []).map((c) => ({ value: c.value, label: c.label }));
const fieldState: PluginFormInputState = {
  get presentation() {
    return props.presentation;
  },
  get selectPresentation() {
    return props.selectPresentation;
  },
  get busy() {
    return props.busy;
  },
  get fileEnabled() { return !!instance?.vnode.props?.onFileAction; },
  fileState,
  fileAction,
  get selectionLabels() {
    return props.selectionLabels;
  },
  draft,
  numberText,
  dateParts,
  get picking() {
    return picking.value;
  },
  set picking(value) {
    picking.value = value;
  },
  selectionOf,
  directoryOptions,
  errorText,
  choicesOf,
  rowsOf,
  chosenNames,
  set,
  setNumber,
  setDatePart,
  setRow,
  addRow,
  removeRow,
  selectionSearch: (id, query) => emit("selection-search", id, query),
  selectionRetry: (id) => emit("selection-retry", id),
  selectionMore: (id) => emit("selection-more", id),
};
const bareFields = computed(() =>
  visibleInputs.value.map((input) => {
    const override = slots[`field-${input.id}`] ?? slots.field;
    return h(
      PluginFormInput,
      { key: input.id, input, state: fieldState, native: true },
      override ? { default: override } : undefined,
    );
  }),
);
const invalid = computed(() =>
  filesPending.value || visibleInputs.value.some((input) => !!errorText(input)),
);
defineOptions({ inheritAttrs: false });
defineExpose({ submit });
</script>

<template>
  <slot
    v-if="$slots.layout"
    name="layout"
    :fields="bareFields"
    :submit="submit"
    :reset="resetFilters"
    :busy="busy"
    :unchanged="unchanged"
    :invalid="invalid"
  />
  <form
    v-else
    v-bind="$attrs"
    class="flare-plugin-form"
    :class="{
      'flare-plugin-form--filters': presentation === 'filters',
      'is-embedded': embedded,
    }"
    :aria-busy="busy"
    novalidate
    @submit.prevent="submit"
  >
    <fieldset class="flare-plugin-form__fields" :disabled="busy">
      <PluginFormInput
        v-for="input in visibleInputs"
        :key="input.id"
        :input="input"
        :state="fieldState"
      >
        <template
          v-if="slots[`field-${input.id}`] || slots.field"
          #default="field"
        >
          <slot
            :name="slots[`field-${input.id}`] ? `field-${input.id}` : 'field'"
            v-bind="field"
          />
        </template>
      </PluginFormInput>
    </fieldset>
    <p v-if="error" class="flare-plugin-form__error" role="alert">
      {{ error }}
    </p>
    <footer class="flare-plugin-form__actions">
      <FlareButton
        v-if="!embedded"
        variant="secondary"
        :size="presentation === 'filters' ? 'sm' : undefined"
        :appearance="presentation === 'filters' ? 'text' : 'default'"
        :label="cancelLabel ?? t('pluginForm.cancel')"
        :disabled="busy"
        data-form-cancel="true"
        @click="cancel"
      />
      <FlareButton
        :size="presentation === 'filters' ? 'sm' : undefined"
        :label="submitLabel ?? t('pluginView.submit')"
        :loading="busy"
        :disabled="busy || unchanged || filesPending"
        data-form-submit="true"
        @click="submit"
      />
      <slot name="actions" />
    </footer>
  </form>
  <!-- fill: the picker takes the sheet's height and brings its own header, so the sheet's title is its name only. -->
  <FlareBottomSheet
    :open="Boolean(picking)"
    :title="picking?.label"
    fill
    max-height="min(80vh, 600px)"
    @close="picking = null"
  >
    <FlareContactPicker
      v-if="picking"
      :groups="[
        { id: 'members', label: picking.label, entries: memberEntries },
      ]"
      :multiple="flarePluginMaxItems(picking) !== 1"
      :loading="membersLoading"
      :error="membersError"
      :on-search="onMemberSearch"
      :on-retry="onMembersRetry"
      :title="picking.label"
      @select="pickMembers"
      @cancel="picking = null"
    />
  </FlareBottomSheet>
</template>

<style scoped>
.flare-plugin-form {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-lg);
  width: 100%;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg)
    var(--flare-size-spacing-xl);
}
.flare-plugin-form__fields {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  margin: 0;
  padding: 0;
  border: 0;
}
.flare-plugin-form.is-embedded {
  padding: 0;
}
.flare-plugin-form__error {
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-error-text);
}
.flare-plugin-form__actions {
  display: flex;
  gap: var(--flare-size-spacing-md);
}
.flare-plugin-form__actions > * {
  flex: 1;
}
.flare-plugin-form--filters {
  flex-direction: row;
  flex-wrap: wrap;
  align-items: flex-start;
  padding: var(--flare-size-spacing-xs) 0;
  gap: var(--flare-size-spacing-md);
}
.flare-plugin-form--filters .flare-plugin-form__fields {
  flex: 1 1 320px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 260px), 1fr));
}
.flare-plugin-form--filters .flare-plugin-form__actions {
  align-self: flex-end;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
}
.flare-plugin-form--filters .flare-plugin-form__actions > * {
  flex: none;
}
.flare-plugin-form--filters .flare-plugin-form__error {
  flex-basis: 100%;
}
</style>
