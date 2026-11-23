<script lang="ts">
import type {
  SchemaSelection,
  SchemaSelectionLabels,
} from "./schema-selections";
import type { FlarePluginInput, FlarePluginFileActionKind, FlarePluginFileState, FlarePluginLocationState } from "../../shared/contracts/plugin-ui";
export interface PluginFormInputState {
  presentation: "form" | "filters";
  selectPresentation: "radio" | "dropdown";
  busy: boolean;
  fileEnabled: boolean;
  fileState(input: FlarePluginInput): FlarePluginFileState;
  fileAction(input: FlarePluginInput, action: FlarePluginFileActionKind): void;
  /** Whether the host listens for location keys (`locationAction`). */
  locationEnabled: boolean;
  locationState(input: FlarePluginInput): FlarePluginLocationState;
  locationAction(input: FlarePluginInput, action: "locate" | "clear"): void;
  selectionLabels?: SchemaSelectionLabels;
  draft: Record<string, unknown>;
  numberText: Record<string, string>;
  dateParts: Record<string, { date: string; time: string }>;
  picking: FlarePluginInput | null;
  selectionOf(input: FlarePluginInput): SchemaSelection | undefined;
  directoryOptions(input: FlarePluginInput): SchemaSelection["options"];
  errorText(input: FlarePluginInput): string | undefined;
  choicesOf(input: FlarePluginInput): { value: string; label: string }[];
  rowsOf(id: string): string[];
  chosenNames(id: string): string;
  set(id: string, value: unknown): void;
  setNumber(id: string, value: string): void;
  setDatePart(id: string, part: "date" | "time", value: string): void;
  setRow(id: string, index: number, value: string): void;
  addRow(input: FlarePluginInput): void;
  removeRow(input: FlarePluginInput, index: number): void;
  selectionSearch(id: string, query: string): void;
  selectionRetry(id: string): void;
  selectionMore(id: string): void;
  /** A PIN got its sixth digit: submit when no required field follows it, else go to the next field. */
  pinComplete?(input: FlarePluginInput): void;
}
</script>
<script setup lang="ts">
import { computed } from "vue";
import { NDatePicker, NSelect } from "naive-ui";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareFormField from "./FlareFormField.vue";
import FlareTextarea from "./FlareTextarea.vue";
import FlareSwitch from "./FlareSwitch.vue";
import FlareRadioGroup from "./FlareRadioGroup.vue";
import FlarePinInput from "./FlarePinInput.vue";
import FlareSelect from "./FlareSelect.vue";
import FlareFileUpload from "../media/FlareFileUpload.vue";
import FlareDocumentSlot from "../messages/FlareDocumentSlot.vue";
import FlareDatePicker from "./FlareDatePicker.vue";
import FlareTimePicker from "./FlareTimePicker.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flarePluginCounterShown, flarePluginSelectControl } from "../../shared/contracts/plugin-experience";
import {
  flarePluginCounter,
  flarePluginMaxLength,
  flarePluginIsUpload,
  flarePluginMaxItems,
  flarePluginMinRows,
  flarePluginMoneyScale,
  flarePluginMoneyTyped,
  flarePluginDecimalSeparator,
  flarePluginLocationText,
  flarePluginLocationValue,
} from "../../shared/contracts/plugin-ui";
const props = defineProps<{
  input: FlarePluginInput;
  state: PluginFormInputState;
  native?: boolean;
}>();
const customDisabled = computed(
  () =>
    props.state.busy ||
    !!props.state.selectionOf(props.input)?.disabled ||
    !!props.state.selectionOf(props.input)?.loading,
);
function setCustomValue(value: unknown): void {
  if (!customDisabled.value) props.state.set(props.input.id, value);
}
const { t } = useFlareI18nOptional();
const allChoiceValues = computed(() => {
  const { input, state } = props;
  if (
    input.kind !== "options" ||
    !input.choices?.length ||
    input.reference ||
    state.presentation !== "form"
  ) return [];
  const selection = state.selectionOf(input);
  if (!selection || selection.remote !== false || selection.hasMore) return [];
  const values = selection.options
    .filter((option) => !option.disabled)
    .map((option) => option.value);
  return values.length > 1 && values.length <= flarePluginMaxItems(input) ? values : [];
});
const selectAllDisabled = computed(() => {
  const selected = props.state.rowsOf(props.input.id);
  return (
    customDisabled.value ||
    !!props.state.selectionOf(props.input)?.error ||
    (selected.length === allChoiceValues.value.length &&
      allChoiceValues.value.every((value) => selected.includes(value)))
  );
});
/** R6: "{length}/{max}" only with a limit of at most 200 and something typed. */
function counterOf(input: FlarePluginInput): string | undefined {
  const draft = props.state.draft[input.id];
  const typed = [...String(draft ?? "")].length;
  return flarePluginCounterShown(flarePluginMaxLength(input), typed) ? flarePluginCounter(input, draft) ?? undefined : undefined;
}
/** R6: a select's control by its choice count (filters keep their dropdown; no choices is always a disabled select). */
const selectControl = computed(() => {
  const rule = flarePluginSelectControl(props.state.choicesOf(props.input).length);
  if (rule.disabled) return "empty" as const;
  if (props.state.presentation === "filters" || props.state.selectPresentation === "dropdown") return "select" as const;
  return rule.control;
});
/** R6: the plugin's help under the field (caption, secondary); filters stay one line. */
const help = computed(() => (props.state.presentation === "filters" ? undefined : props.input.help || undefined));
const moneyRangeHint = computed(() => {
  const money = props.input.money;
  return money?.currency && money.min !== undefined && money.max !== undefined
    ? t("pluginForm.moneyRange", { min: money.min, max: money.max, currency: money.currency }) : undefined;
});
const moneyError = computed(() => {
  const error = props.state.errorText(props.input);
  return error === t("pluginForm.outOfRange") && moneyRangeHint.value ? moneyRangeHint.value : error;
});
/** The keyboard's decimal separator follows the device language, not the kit's (spec moneyInput.typed). */
const decimalSeparator = flarePluginDecimalSeparator(typeof navigator === "undefined" ? undefined : navigator.language);
const removeIcon = flareIcons.close;
const addIcon = flareIcons.add;
/** A document input's name with its side, once (「认证材料 · 证件正面」, but 「证件正面」 alone). */
function documentName(input: FlarePluginInput): string {
  const sideLabel = input.kind === "document" && input.side ? t(`pluginForm.documentSide.${input.side}`) : "";
  const side = sideLabel && !input.label.toLocaleLowerCase().includes(sideLabel.toLocaleLowerCase()) ? ` · ${sideLabel}` : "";
  return `${input.label}${side}`;
}
/** The upload's title: an image or document input names what it takes (the side of a document). */
function uploadTitle(input: FlarePluginInput): string {
  return `${documentName(input)}${input.required ? " *" : ""}`;
}
/** §6.3: a document input is a capture slot — uploaded is captured, in flight uploading, failed failed. */
function slotState(input: FlarePluginInput): "empty" | "captured" | "uploading" | "failed" {
  const phase = props.state.fileState(input).phase;
  return phase === "uploaded" ? "captured" : phase === "failed" ? "failed" : phase === "empty" ? "empty" : "uploading";
}
function uploadPickLabel(input: FlarePluginInput): string {
  if (input.kind === "image") return t("pluginForm.chooseImage");
  if (input.kind === "document") return t("pluginForm.captureDocument");
  return t("pluginFileChoose");
}
/** A location input's fix as drawn: the place, then the precision and accuracy (null: none yet). */
function locationLines(input: FlarePluginInput): { place: string; detail: string } | null {
  const fix = flarePluginLocationValue(props.state.draft[input.id], input.precision);
  if (!fix) return null;
  return {
    place: flarePluginLocationText(fix),
    detail: `${t(`pluginForm.location.${fix.precision}`)} · ${t("pluginForm.location.accuracy", { m: fix.accuracyM })}`,
  };
}
/** "0.00" for a money input of scale 2: the shape of the amount it takes. */
function moneyPlaceholder(input: FlarePluginInput): string {
  const scale = flarePluginMoneyScale(input);
  return input.placeholder || (scale ? `0.${"0".repeat(scale)}` : "0");
}
function filePolicyHint(input: FlarePluginInput): string {
  const policy = input.file;
  if (!policy) return t("pluginFileChoose");
  const size = policy.maxBytes >= 1048576 ? `${+(policy.maxBytes / 1048576).toFixed(1)} MiB` : `${Math.ceil(policy.maxBytes / 1024)} KiB`;
  return `${policy.accept.map((mime) => mime.split("/").at(-1)?.toUpperCase()).join(", ")} · ≤ ${size}`;
}
</script>

<template>
  <FlareFormField
    v-if="$slots.default"
    :native="native"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <template #default="field">
      <slot
        :input="input"
        :value="state.draft[input.id]"
        :set-value="setCustomValue"
        :disabled="customDisabled"
        :error="state.errorText(input)"
        v-bind="field"
      />
    </template>
  </FlareFormField>
  <FlareFormField
    v-else-if="input.kind === 'location'"
    :native="native"
    :label="input.label"
    :required="input.required"
    :error="state.locationState(input).error || state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
    data-input-kind="location"
  >
    <div class="flare-plugin-form__location" :aria-busy="state.locationState(input).locating || undefined">
      <span class="flare-plugin-form__location-icon" aria-hidden="true"><FlareIcon name="location" /></span>
      <div class="flare-plugin-form__location-text" role="status">
        <template v-if="state.locationState(input).locating">{{ t("pluginForm.location.locating") }}</template>
        <template v-else-if="locationLines(input)">
          <span class="flare-plugin-form__location-place" data-location-place="true">{{ locationLines(input)!.place }}</span>
          <span class="flare-plugin-form__location-detail">{{ locationLines(input)!.detail }}</span>
        </template>
        <span v-else class="flare-plugin-form__location-detail" data-location-empty="true">{{ t("pluginForm.location.empty") }}</span>
      </div>
      <div class="flare-plugin-form__location-keys">
        <FlareButton
          v-if="locationLines(input) && !state.locationState(input).locating"
          size="sm"
          variant="quiet"
          :label="t('pluginForm.location.clear')"
          :disabled="state.busy"
          data-location-clear="true"
          @click="state.locationAction(input, 'clear')"
        />
        <FlareButton
          size="sm"
          variant="secondary"
          :label="locationLines(input) ? t('pluginForm.location.relocate') : t('pluginForm.location.locate')"
          :loading="state.locationState(input).locating"
          :disabled="state.busy || !state.locationEnabled"
          data-location-locate="true"
          @click="state.locationAction(input, 'locate')"
        />
      </div>
    </div>
  </FlareFormField>
  <!-- §6.3: a document input is its capture slot (the native capture action's entry, the host takes the photo). -->
  <FlareFormField
    v-else-if="input.kind === 'document' && state.presentation !== 'filters'"
    :error="state.fileState(input).error || state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
    data-input-kind="document"
  >
    <FlareDocumentSlot
      :label="documentName(input)"
      :side="input.side ?? 'front'"
      :state="slotState(input)"
      :image-url="state.fileState(input).previewUrl"
      :progress="state.fileState(input).progress"
      :disabled="state.busy || !state.fileEnabled || !input.file"
      @capture="state.fileAction(input, state.fileState(input).phase === 'empty' ? 'choose' : 'replace')"
      @retry="state.fileAction(input, 'retry')"
    />
  </FlareFormField>
  <FlareFormField
    v-else-if="flarePluginIsUpload(input.kind)"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
    :data-input-kind="input.kind"
  >
    <FlareFileUpload
      host-picker
      :title="uploadTitle(input)"
      :state="state.fileState(input).phase"
      :file-name="state.fileState(input).fileName"
      :image="input.kind !== 'file' || !!input.file?.accept.every((mime) => mime.startsWith('image/'))"
      :accept="input.file?.accept.join(',')"
      :progress="state.fileState(input).progress"
      :status-text="state.fileState(input).error || (state.fileState(input).phase === 'empty' ? filePolicyHint(input) : t(`pluginFile${state.fileState(input).phase[0].toUpperCase()}${state.fileState(input).phase.slice(1)}`))"
      :pick-label="uploadPickLabel(input)"
      :replace-label="t('pluginFileReplace')"
      :retry-label="t('common.retry')"
      :cancel-label="t('common.cancel')"
      :remove-label="t('pluginFileRemove')"
      :preview-label="state.fileState(input).preview ? t('pluginFilePreview') : undefined"
      :preview-loading="state.fileState(input).previewLoading"
      :disabled="state.busy || !state.fileEnabled || !input.file"
      @choose="state.fileAction(input, 'choose')"
      @replace="state.fileAction(input, 'replace')"
      @retry="state.fileAction(input, 'retry')"
      @cancel="state.fileAction(input, 'cancel')"
      @remove="state.fileAction(input, 'remove')"
      @preview="state.fileAction(input, 'preview')"
    />
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="state.selectionOf(input)"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <div class="flare-plugin-form__selection" :class="{ 'has-bulk-action': allChoiceValues.length }">
      <FlareAdminEntitySelect
        :label="input.label"
        :multiple="input.kind === 'options' || input.kind === 'members'"
        :value="
          typeof state.draft[input.id] === 'string'
            ? (state.draft[input.id] as string)
            : ''
        "
        :values="
          Array.isArray(state.draft[input.id])
            ? (state.draft[input.id] as string[])
            : []
        "
        :options="state.directoryOptions(input)"
        :remote="state.selectionOf(input)!.remote ?? true"
        :clearable="!input.required"
        :max="flarePluginMaxItems(input)"
        :loading="state.selectionOf(input)!.loading"
        :disabled="state.busy || state.selectionOf(input)!.disabled"
        :error="
          state.selectionOf(input)!.error || state.selectionOf(input)!.invalid
        "
        :has-more="state.selectionOf(input)!.hasMore"
        :placeholder="state.selectionLabels?.placeholder || input.label"
        :empty-text="state.selectionLabels?.empty || ''"
        :more-text="state.selectionLabels?.more || ''"
        :retry-text="state.selectionLabels?.retry || ''"
        @update:value="state.set(input.id, $event)"
        @update:values="state.set(input.id, $event)"
        @search="state.selectionSearch(input.id, $event)"
        @retry="state.selectionRetry(input.id)"
        @more="state.selectionMore(input.id)"
      />
      <FlareButton
        v-if="allChoiceValues.length"
        size="sm"
        appearance="text"
        :label="t('batch.selectAll')"
        :aria-label="`${t('batch.selectAll')} · ${input.label}`"
        :disabled="selectAllDisabled"
        @click="state.set(input.id, allChoiceValues)"
      />
    </div>
  </FlareFormField>
  <!-- §5.10: a 6-digit password (a payment PIN) is six cells; the value is still the typed string. -->
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'password' && input.maxLength === 6 && state.presentation !== 'filters'"
    :label="input.label"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <FlarePinInput
      :model-value="String(state.draft[input.id] ?? '')"
      :label="input.label"
      :disabled="state.busy"
      :error="Boolean(state.errorText(input))"
      @update:model-value="(v: string) => state.set(input.id, v)"
      @complete="state.pinComplete?.(input)"
    />
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'text' || input.kind === 'password'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :counter="state.presentation === 'filters' ? undefined : counterOf(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <FlareInput
      :size="state.presentation === 'filters' ? 'sm' : undefined"
      :model-value="String(state.draft[input.id] ?? '')"
      :placeholder="input.placeholder"
      :secure="input.kind === 'password'"
      :autocomplete="input.kind === 'password' ? 'off' : undefined"
      :max-length="input.kind === 'password' ? input.maxLength : undefined"
      :disabled="state.busy"
      @update:model-value="(v: string) => state.set(input.id, v)"
    />
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'money'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :hint="help ?? moneyRangeHint"
    :error="moneyError"
    :data-input-id="input.id"
  >
    <div class="flare-plugin-form__money" data-money-input="true">
      <FlareInput
        :model-value="String(state.draft[input.id] ?? '')"
        :placeholder="moneyPlaceholder(input)"
        :aria-label="input.money?.currency ? `${input.label} (${input.money.currency})` : undefined"
        inputmode="decimal"
        autocomplete="off"
        :disabled="state.busy || !input.money?.currency"
        @update:model-value="(v: string) => state.set(input.id, flarePluginMoneyTyped(v, decimalSeparator))"
      >
        <template v-if="input.money?.currency" #suffix>
          <span class="flare-plugin-form__currency" data-money-currency="true">{{ input.money.currency }}</span>
        </template>
      </FlareInput>
    </div>
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'textarea'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :counter="counterOf(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <FlareTextarea
      :model-value="String(state.draft[input.id] ?? '')"
      :placeholder="input.placeholder"
      :disabled="state.busy"
      :max-rows="6"
      @update:model-value="(v: string) => state.set(input.id, v)"
    />
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'number'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <FlareInput
      :model-value="state.numberText[input.id] ?? ''"
      :placeholder="input.placeholder"
      :inputmode="input.min !== undefined && Number.isInteger(input.min) && input.max !== undefined && Number.isInteger(input.max) ? 'numeric' : 'decimal'"
      :disabled="state.busy"
      @update:model-value="(v: string) => state.setNumber(input.id, v)"
    />
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'toggle'"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <label class="flare-plugin-form__toggle">
      <span>{{ input.label }}</span>
      <FlareSwitch
        :model-value="Boolean(state.draft[input.id])"
        :disabled="state.busy"
        @update:model-value="(v: boolean) => state.set(input.id, v)"
      />
    </label>
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'select'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="selectControl === 'empty' && state.presentation !== 'filters' ? t('pluginView.noOptionsHelp') : help"
    :data-input-id="input.id"
    :data-select-control="selectControl"
  >
    <!-- R6: nothing to choose — a disabled select that says so (the form keeps submit off). -->
    <FlareSelect
      v-if="selectControl === 'empty' && state.presentation !== 'filters'"
      model-value=""
      :options="[]"
      :placeholder="t('pluginView.noOptions')"
      :title="input.label"
      disabled
      data-select-empty="true"
    />
    <!-- Native admin filters sit in a clipped, collapsible query region.
         Naive's teleported menu shares the wallet filters' popup behavior. -->
    <NSelect
      v-else-if="native && state.presentation === 'filters'"
      :value="String(state.draft[input.id] ?? '')"
      :options="
        input.required
          ? state.choicesOf(input)
          : [
              { value: '', label: t('pluginView.all') },
              ...state.choicesOf(input),
            ]
      "
      :placeholder="input.placeholder || input.label"
      :aria-label="input.label"
      :input-props="{ 'aria-label': input.label }"
      :disabled="state.busy"
      size="small"
      @update:value="(v: string) => state.set(input.id, v)"
    />
    <FlareSelect
      v-else-if="selectControl !== 'cards'"
      :model-value="String(state.draft[input.id] ?? '')"
      :options="
        state.presentation === 'filters' && !input.required
          ? [
              { value: '', label: t('pluginView.all') },
              ...state.choicesOf(input),
            ]
          : state.choicesOf(input)
      "
      :placeholder="input.placeholder || input.label"
      :title="input.label"
      :disabled="state.busy"
      :size="state.presentation === 'filters' ? 'sm' : undefined"
      :menu-placement="state.presentation === 'filters' ? 'overlay' : 'inline'"
      @update:model-value="(v: string) => state.set(input.id, v)"
    />
    <FlareRadioGroup
      v-else
      :aria-label="input.label"
      :model-value="String(state.draft[input.id] ?? '')"
      :options="state.choicesOf(input)"
      option-layout="cards"
      data-select-cards="true"
      @update:model-value="(v: string) => state.set(input.id, v)"
    />
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'datetime'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <NDatePicker
      v-if="native && state.presentation === 'filters'"
      class="flare-plugin-form__datetime-control"
      type="datetime"
      size="small"
      format="yyyy-MM-dd HH:mm"
      clearable
      :value="
        typeof state.draft[input.id] === 'number'
          ? (state.draft[input.id] as number)
          : null
      "
      :input-props="{ 'aria-label': input.label }"
      :placeholder="input.label"
      :disabled="state.busy"
      @update:value="(v: number | null) => state.set(input.id, v)"
    />
    <div v-else class="flare-plugin-form__datetime">
      <FlareDatePicker
        :size="state.presentation === 'filters' ? 'sm' : undefined"
        :model-value="state.dateParts[input.id]?.date ?? ''"
        :placeholder="t('pluginForm.date')"
        :title="input.label"
        :disabled="state.busy"
        @update:model-value="
          (v: string) => state.setDatePart(input.id, 'date', v)
        "
      />
      <FlareTimePicker
        :size="state.presentation === 'filters' ? 'sm' : undefined"
        :model-value="state.dateParts[input.id]?.time ?? ''"
        :placeholder="t('pluginForm.time')"
        :title="input.label"
        :disabled="state.busy"
        @update:model-value="
          (v: string) => state.setDatePart(input.id, 'time', v)
        "
      />
    </div>
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'options'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <div class="flare-plugin-form__options">
      <div
        v-for="(row, index) in state.rowsOf(input.id)"
        :key="index"
        class="flare-plugin-form__option"
        data-option-row="true"
      >
        <FlareInput
          :model-value="row"
          :placeholder="input.placeholder"
          :aria-label="`${input.label} ${index + 1}`"
          :disabled="state.busy"
          @update:model-value="(v: string) => state.setRow(input.id, index, v)"
        />
        <FlareIconButton
          :icon="removeIcon"
          :ariaLabel="t('pluginForm.removeOption')"
          :disabled="
            state.busy ||
            state.rowsOf(input.id).length <= flarePluginMinRows(input)
          "
          data-option-remove="true"
          @click="state.removeRow(input, index)"
        />
      </div>
      <FlareButton
        variant="text"
        :icon="addIcon"
        :label="t('pluginForm.addOption')"
        :disabled="
          state.busy ||
          state.rowsOf(input.id).length >= flarePluginMaxItems(input)
        "
        data-option-add="true"
        @click="state.addRow(input)"
      />
    </div>
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'members'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="help"
    :data-input-id="input.id"
  >
    <div class="flare-plugin-form__members">
      <span
        v-if="state.chosenNames(input.id)"
        class="flare-plugin-form__chosen"
        data-members-chosen="true"
        >{{ state.chosenNames(input.id) }}</span
      >
      <FlareButton
        variant="secondary"
        size="sm"
        :label="input.placeholder || t('pluginForm.chooseMembers')"
        :disabled="state.busy"
        data-members-choose="true"
        @click="state.picking = input"
      />
    </div>
  </FlareFormField>
</template>

<style scoped>
.flare-plugin-form__selection {
  display: contents;
}
.flare-plugin-form__selection.has-bulk-action {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  width: 100%;
}
.flare-plugin-form__toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-primary);
}
.flare-plugin-form__datetime {
  display: grid;
  width: 100%;
  min-width: 0;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 150px), 1fr));
  gap: var(--flare-size-spacing-sm);
}
.flare-plugin-form__datetime-control {
  width: 100%;
  min-width: 0;
}
.flare-plugin-form__datetime > * {
  width: 100%;
  min-width: 0;
}
.flare-plugin-form__options {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  justify-items: start;
}
.flare-plugin-form__option {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  width: 100%;
}
.flare-plugin-form__option > :first-child {
  flex: 1;
  min-width: 0;
}
.flare-plugin-form__money {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  width: 100%;
  min-width: 0;
}

.flare-plugin-form__money > :first-child {
  flex: 1;
  min-width: 0;
}
.flare-plugin-form__currency {
  flex: none;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-lg);
}
.flare-plugin-form__location {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  width: 100%;
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target);
}
.flare-plugin-form__location-icon { display: inline-flex; flex: none; color: var(--flare-color-text-secondary); }
.flare-plugin-form__location-text { display: grid; flex: 1; min-width: 0; gap: 2px; }
.flare-plugin-form__location-place { font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-plugin-form__location-detail { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
.flare-plugin-form__location-keys { display: flex; flex: none; gap: var(--flare-size-spacing-xs); }
.flare-plugin-form__members {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
.flare-plugin-form__chosen {
  min-width: 0;
  overflow-wrap: anywhere;
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-primary);
}
</style>
