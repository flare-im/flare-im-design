<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareFormField from "./FlareFormField.vue";
import FlareTextarea from "./FlareTextarea.vue";
import FlareSwitch from "./FlareSwitch.vue";
import FlareRadioGroup from "./FlareRadioGroup.vue";
import FlareSelect from "./FlareSelect.vue";
import FlareDatePicker from "./FlareDatePicker.vue";
import FlareTimePicker from "./FlareTimePicker.vue";
import FlareContactPicker from "../composer/FlareContactPicker.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import type { FlareContactPickerEntry } from "../../shared/contracts/contact-picker";
import {
  flarePluginCheckInput,
  flarePluginCounter,
  flarePluginDraft,
  flarePluginFormValues,
  flarePluginIssueText,
  flarePluginMaxItems,
  flarePluginMinRows,
  type FlarePluginFormError,
  type FlarePluginInput,
  type FlarePluginMember,
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
    /** Initial values by input id; an input without one starts from its default. */
    values?: Record<string, unknown>;
    /** The host's errors (UiFormError). */
    errors?: FlarePluginFormError[];
    submitLabel?: string;
    cancelLabel?: string;
    /** Same typed inputs/validation; compact query presentation for administrative filters. */
    presentation?: "form" | "filters";
    busy?: boolean;
    /** A failure line above the keys. */
    error?: string;
    /** Candidates for members inputs. */
    members?: FlarePluginMember[];
  }>(),
  { values: undefined, errors: () => [], submitLabel: undefined, presentation: "form", busy: false, error: undefined, members: () => [] },
);
const emit = defineEmits<{ (e: "submit", values: Record<string, unknown>): void; (e: "cancel"): void }>();
const { t } = useFlareI18nOptional();

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
const numberText = reactive<Record<string, string>>({});
const dateParts = reactive<Record<string, { date: string; time: string }>>({});
const pad2 = (n: number) => String(n).padStart(2, "0");
/** A new form (other inputs or initial values, compared by content): start over from them. */
function reset(): void {
  for (const key of Object.keys(draft)) delete draft[key];
  Object.assign(draft, flarePluginDraft(props.inputs, props.values));
  for (const input of props.inputs) {
    const value = draft[input.id];
    if (input.kind === "number") numberText[input.id] = typeof value === "number" ? String(value) : "";
    if (input.kind === "datetime") {
      const d = typeof value === "number" ? new Date(value) : null;
      dateParts[input.id] = d
        ? { date: `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`, time: `${pad2(d.getHours())}:${pad2(d.getMinutes())}` }
        : { date: "", time: "" };
    }
  }
  edited.clear();
  editedSinceErrors.clear();
  attempted.value = false;
}
watch(() => JSON.stringify([props.inputs, props.values ?? null]), reset, { immediate: true });
watch(() => JSON.stringify(props.errors), () => editedSinceErrors.clear());

function set(id: string, value: unknown): void {
  draft[id] = value;
  edited.add(id);
  editedSinceErrors.add(id);
}

/** The text under an input: the host's first error for it, else the client's issue once it may show. */
function errorText(input: FlarePluginInput): string | undefined {
  if (!editedSinceErrors.has(input.id)) {
    const host = props.errors.find((e) => e.input === input.id);
    if (host) return flarePluginIssueText(host.issue, input, strings.value);
  }
  if (!attempted.value && !edited.has(input.id)) return undefined;
  const issue = flarePluginCheckInput(input, draft[input.id]);
  return issue ? flarePluginIssueText(issue, input, strings.value) : undefined;
}

function submit(): void {
  if (props.busy) return;
  attempted.value = true;
  if (props.inputs.some((input) => flarePluginCheckInput(input, draft[input.id]))) return;
  emit("submit", flarePluginFormValues(props.inputs, draft));
}
function cancel(): void {
  if (!props.busy) emit("cancel");
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
  const ms = parts.date && parts.time ? new Date(y, m - 1, d, hh, mm).getTime() : Number.NaN;
  set(id, Number.isFinite(ms) ? ms : null);
}

// ── options ──
const rowsOf = (id: string) => (Array.isArray(draft[id]) ? (draft[id] as string[]) : []);
function setRow(id: string, index: number, value: string): void {
  const rows = [...rowsOf(id)];
  rows[index] = value;
  set(id, rows);
}
function addRow(input: FlarePluginInput): void {
  if (rowsOf(input.id).length < flarePluginMaxItems(input)) set(input.id, [...rowsOf(input.id), ""]);
}
function removeRow(input: FlarePluginInput, index: number): void {
  if (rowsOf(input.id).length > flarePluginMinRows(input)) set(input.id, rowsOf(input.id).filter((_, i) => i !== index));
}

// ── members: the kit ContactPicker over the host's candidates ──
const picking = ref<FlarePluginInput | null>(null);
const memberEntries = computed<FlareContactPickerEntry[]>(() => props.members.map((m) => ({ userId: m.userId, name: m.name, avatarUrl: m.avatarUrl })));
const chosenNames = (id: string) => {
  const ids = Array.isArray(draft[id]) ? (draft[id] as string[]) : [];
  return ids.map((userId) => props.members.find((m) => m.userId === userId)?.name ?? userId).join("、");
};
function pickMembers(entries: FlareContactPickerEntry[]): void {
  const input = picking.value;
  picking.value = null;
  if (input) set(input.id, entries.map((entry) => entry.userId).slice(0, flarePluginMaxItems(input)));
}

const choicesOf = (input: FlarePluginInput) => (input.choices ?? []).map((c) => ({ value: c.value, label: c.label }));
const removeIcon = flareIcons.close;
const addIcon = flareIcons.add;
defineExpose({ submit });
</script>

<template>
  <form class="flare-plugin-form" :class="{ 'flare-plugin-form--filters': presentation === 'filters' }" :aria-busy="busy" novalidate @submit.prevent="submit">
    <fieldset class="flare-plugin-form__fields" :disabled="busy">
      <template v-for="input in inputs" :key="input.id">
        <FlareFormField
          v-if="input.kind === 'text'"
          :label="input.label"
          :required="input.required"
          :error="errorText(input)"
          :hint="presentation === 'filters' ? undefined : flarePluginCounter(input, draft[input.id]) ?? undefined"
          :data-input-id="input.id"
        >
          <FlareInput
            :size="presentation === 'filters' ? 'sm' : undefined"
            :model-value="String(draft[input.id] ?? '')"
            :placeholder="input.placeholder"
            :disabled="busy"
            @update:model-value="(v: string) => set(input.id, v)"
          />
        </FlareFormField>
        <FlareFormField
          v-else-if="input.kind === 'textarea'"
          :label="input.label"
          :required="input.required"
          :error="errorText(input)"
          :hint="flarePluginCounter(input, draft[input.id]) ?? undefined"
          :data-input-id="input.id"
        >
          <FlareTextarea
            :model-value="String(draft[input.id] ?? '')"
            :placeholder="input.placeholder"
            :disabled="busy"
            :max-rows="6"
            @update:model-value="(v: string) => set(input.id, v)"
          />
        </FlareFormField>
        <FlareFormField
          v-else-if="input.kind === 'number'"
          :label="input.label"
          :required="input.required"
          :error="errorText(input)"
          :data-input-id="input.id"
        >
          <FlareInput
            :model-value="numberText[input.id] ?? ''"
            :placeholder="input.placeholder"
            inputmode="decimal"
            :disabled="busy"
            @update:model-value="(v: string) => setNumber(input.id, v)"
          />
        </FlareFormField>
        <FlareFormField v-else-if="input.kind === 'toggle'" :error="errorText(input)" :data-input-id="input.id">
          <label class="flare-plugin-form__toggle">
            <span>{{ input.label }}</span>
            <FlareSwitch :model-value="Boolean(draft[input.id])" :disabled="busy" @update:model-value="(v: boolean) => set(input.id, v)" />
          </label>
        </FlareFormField>
        <FlareFormField
          v-else-if="input.kind === 'select'"
          :label="input.label"
          :required="input.required"
          :error="errorText(input)"
          :data-input-id="input.id"
        >
          <FlareSelect
            v-if="presentation === 'filters'"
            :model-value="String(draft[input.id] ?? '')"
            :options="input.required ? choicesOf(input) : [{ value: '', label: t('pluginView.all') }, ...choicesOf(input)]"
            :placeholder="input.placeholder || input.label"
            :title="input.label"
            :disabled="busy"
            size="sm"
            @update:model-value="(v: string) => set(input.id, v)"
          />
          <FlareRadioGroup
            v-else
            :model-value="String(draft[input.id] ?? '')"
            :options="choicesOf(input)"
            vertical
            @update:model-value="(v: string) => set(input.id, v)"
          />
        </FlareFormField>
        <FlareFormField
          v-else-if="input.kind === 'datetime'"
          :label="input.label"
          :required="input.required"
          :error="errorText(input)"
          :data-input-id="input.id"
        >
          <div class="flare-plugin-form__datetime">
            <FlareDatePicker
              :model-value="dateParts[input.id]?.date ?? ''"
              :placeholder="t('pluginForm.date')"
              :title="input.label"
              :disabled="busy"
              @update:model-value="(v: string) => setDatePart(input.id, 'date', v)"
            />
            <FlareTimePicker
              :model-value="dateParts[input.id]?.time ?? ''"
              :placeholder="t('pluginForm.time')"
              :title="input.label"
              :disabled="busy"
              @update:model-value="(v: string) => setDatePart(input.id, 'time', v)"
            />
          </div>
        </FlareFormField>
        <FlareFormField
          v-else-if="input.kind === 'options'"
          :label="input.label"
          :required="input.required"
          :error="errorText(input)"
          :data-input-id="input.id"
        >
          <div class="flare-plugin-form__options">
            <div v-for="(row, index) in rowsOf(input.id)" :key="index" class="flare-plugin-form__option" data-option-row="true">
              <FlareInput
                :model-value="row"
                :placeholder="input.placeholder"
                :aria-label="`${input.label} ${index + 1}`"
                :disabled="busy"
                @update:model-value="(v: string) => setRow(input.id, index, v)"
              />
              <FlareIconButton
                :icon="removeIcon"
                :ariaLabel="t('pluginForm.removeOption')"
                :disabled="busy || rowsOf(input.id).length <= flarePluginMinRows(input)"
                data-option-remove="true"
                @click="removeRow(input, index)"
              />
            </div>
            <FlareButton
              variant="text"
              :icon="addIcon"
              :label="t('pluginForm.addOption')"
              :disabled="busy || rowsOf(input.id).length >= flarePluginMaxItems(input)"
              data-option-add="true"
              @click="addRow(input)"
            />
          </div>
        </FlareFormField>
        <FlareFormField
          v-else-if="input.kind === 'members'"
          :label="input.label"
          :required="input.required"
          :error="errorText(input)"
          :data-input-id="input.id"
        >
          <div class="flare-plugin-form__members">
            <span v-if="chosenNames(input.id)" class="flare-plugin-form__chosen" data-members-chosen="true">{{ chosenNames(input.id) }}</span>
            <FlareButton
              variant="secondary"
              size="sm"
              :label="input.placeholder || t('pluginForm.chooseMembers')"
              :disabled="busy"
              data-members-choose="true"
              @click="picking = input"
            />
          </div>
        </FlareFormField>
      </template>
    </fieldset>
    <p v-if="error" class="flare-plugin-form__error" role="alert">{{ error }}</p>
    <footer class="flare-plugin-form__actions">
      <FlareButton variant="secondary" :size="presentation === 'filters' ? 'sm' : undefined" :appearance="presentation === 'filters' ? 'text' : 'default'" :label="cancelLabel ?? t('pluginForm.cancel')" :disabled="busy" data-form-cancel="true" @click="cancel" />
      <FlareButton :size="presentation === 'filters' ? 'sm' : undefined" :label="submitLabel ?? t('pluginView.submit')" :loading="busy" :disabled="busy" data-form-submit="true" @click="submit" />
    </footer>
    <!-- fill: the picker takes the sheet's height and brings its own header, so the sheet's title is its name only. -->
    <FlareBottomSheet :open="Boolean(picking)" :title="picking?.label" fill max-height="min(80vh, 600px)" @close="picking = null">
      <FlareContactPicker
        v-if="picking"
        :groups="[{ id: 'members', label: picking.label, entries: memberEntries }]"
        :multiple="flarePluginMaxItems(picking) !== 1"
        :title="picking.label"
        @select="pickMembers"
        @cancel="picking = null"
      />
    </FlareBottomSheet>
  </form>
</template>

<style scoped>
.flare-plugin-form { display: flex; flex-direction: column; gap: var(--flare-size-spacing-lg); width: 100%; box-sizing: border-box; padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl); }
.flare-plugin-form__fields { display: flex; flex-direction: column; gap: var(--flare-size-spacing-md); min-width: 0; margin: 0; padding: 0; border: 0; }
.flare-plugin-form__toggle { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-md); font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); }
.flare-plugin-form__datetime { display: grid; grid-template-columns: minmax(0, 3fr) minmax(0, 2fr); gap: var(--flare-size-spacing-sm); }
.flare-plugin-form__options { display: grid; gap: var(--flare-size-spacing-xs); justify-items: start; }
.flare-plugin-form__option { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); width: 100%; }
.flare-plugin-form__option > :first-child { flex: 1; min-width: 0; }
.flare-plugin-form__members { display: flex; flex-wrap: wrap; align-items: center; gap: var(--flare-size-spacing-sm); }
.flare-plugin-form__chosen { min-width: 0; overflow-wrap: anywhere; font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); }
.flare-plugin-form__error { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-error-text); }
.flare-plugin-form__actions { display: flex; gap: var(--flare-size-spacing-md); }
.flare-plugin-form__actions > * { flex: 1; }
.flare-plugin-form--filters {
  flex-direction: row;
  flex-wrap: wrap;
  align-items: flex-start;
  padding: var(--flare-size-spacing-md) 0;
  gap: var(--flare-size-spacing-md);
}
.flare-plugin-form--filters .flare-plugin-form__fields {
  flex: 1 1 320px;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 180px), 1fr));
}
.flare-plugin-form--filters .flare-plugin-form__actions {
  align-self: flex-end;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
}
.flare-plugin-form--filters .flare-plugin-form__actions > * { flex: none; }
.flare-plugin-form--filters .flare-plugin-form__error { flex-basis: 100%; }
</style>
