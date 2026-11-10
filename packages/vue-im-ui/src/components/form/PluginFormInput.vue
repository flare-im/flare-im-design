<script lang="ts">
import type {
  SchemaSelection,
  SchemaSelectionLabels,
} from "./schema-selections";
import type { FlarePluginInput, FlarePluginFileActionKind, FlarePluginFileState } from "../../shared/contracts/plugin-ui";
export interface PluginFormInputState {
  presentation: "form" | "filters";
  selectPresentation: "radio" | "dropdown";
  busy: boolean;
  fileEnabled: boolean;
  fileState(input: FlarePluginInput): FlarePluginFileState;
  fileAction(input: FlarePluginInput, action: FlarePluginFileActionKind): void;
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
}
</script>
<script setup lang="ts">
import { computed } from "vue";
import { NDatePicker, NSelect } from "naive-ui";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareFormField from "./FlareFormField.vue";
import FlareTextarea from "./FlareTextarea.vue";
import FlareSwitch from "./FlareSwitch.vue";
import FlareRadioGroup from "./FlareRadioGroup.vue";
import FlareSelect from "./FlareSelect.vue";
import FlareFileUpload from "../media/FlareFileUpload.vue";
import FlareDatePicker from "./FlareDatePicker.vue";
import FlareTimePicker from "./FlareTimePicker.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  flarePluginCounter,
  flarePluginMaxItems,
  flarePluginMinRows,
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
const removeIcon = flareIcons.close;
const addIcon = flareIcons.add;
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
    v-else-if="input.kind === 'file'"
    :error="state.errorText(input)"
    :data-input-id="input.id"
  >
    <FlareFileUpload
      host-picker
      :title="`${input.label}${input.required ? ' *' : ''}`"
      :state="state.fileState(input).phase"
      :file-name="state.fileState(input).fileName"
      :image="!!input.file?.accept.every((mime) => mime.startsWith('image/'))"
      :accept="input.file?.accept.join(',')"
      :progress="state.fileState(input).progress"
      :status-text="state.fileState(input).error || (state.fileState(input).phase === 'empty' ? filePolicyHint(input) : t(`pluginFile${state.fileState(input).phase[0].toUpperCase()}${state.fileState(input).phase.slice(1)}`))"
      :pick-label="t('pluginFileChoose')"
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
    :data-input-id="input.id"
  >
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
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'text' || input.kind === 'password'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="
      state.presentation === 'filters'
        ? undefined
        : (flarePluginCounter(input, state.draft[input.id]) ?? undefined)
    "
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
    v-else-if="input.kind === 'textarea'"
    :label="input.label"
    :label-placement="state.presentation === 'filters' ? 'left' : undefined"
    :required="input.required"
    :error="state.errorText(input)"
    :hint="flarePluginCounter(input, state.draft[input.id]) ?? undefined"
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
    :data-input-id="input.id"
  >
    <FlareInput
      :model-value="state.numberText[input.id] ?? ''"
      :placeholder="input.placeholder"
      inputmode="decimal"
      :disabled="state.busy"
      @update:model-value="(v: string) => state.setNumber(input.id, v)"
    />
  </FlareFormField>
  <FlareFormField
    :native="native"
    v-else-if="input.kind === 'toggle'"
    :error="state.errorText(input)"
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
    :data-input-id="input.id"
  >
    <!-- Native admin filters sit in a clipped, collapsible query region.
         Naive's teleported menu shares the wallet filters' popup behavior. -->
    <NSelect
      v-if="native && state.presentation === 'filters'"
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
      v-else-if="state.presentation === 'filters' || state.selectPresentation === 'dropdown'"
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
      :model-value="String(state.draft[input.id] ?? '')"
      :options="state.choicesOf(input)"
      vertical
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
.flare-plugin-form__toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-lg);
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
