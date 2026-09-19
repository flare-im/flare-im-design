<script setup lang="ts">
// Time-range filter for search. Host-supplied presets are chips; "custom" expands a
// start/end pair built from the shared DatePicker. The component owns no clock — it
// never computes "today" itself — and emits one `FlareSearchTimeRange` in inclusive
// UTC epoch milliseconds that the host folds into its search criteria.
import { computed, ref, useId, watch } from 'vue';
import FlareIcon from './FlareIcon.vue';
import FlareDatePicker from '../form/FlareDatePicker.vue';
import {
  sameSearchTimeRange, validSearchTimeRange,
  type FlareSearchRangeOption, type FlareSearchTimeRange,
} from '../../shared/contracts/search-panel';
import {
  datesFromRange, matchedOptionId, rangeFromDates, shouldOpenCustomRange, unrestrictedRange,
} from '../../shared/contracts/search-date-range';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  /** Current range, controlled by the host. */
  value: FlareSearchTimeRange;
  /** Preset chips. The host computes them (today / last 7 days / …) so time zones stay its business. */
  options?: FlareSearchRangeOption[];
  /** Offer the custom start/end area. */
  allowCustom?: boolean;
  /** Force the custom area open (e.g. restoring a saved filter). */
  customActive?: boolean;
  /** Earliest / latest selectable day, "YYYY-MM-DD", passed straight to the DatePicker. */
  minDate?: string;
  maxDate?: string;
  /** Minutes east of UTC (UTC+8 → 480). Omitted: the viewer's own zone. */
  tzOffsetMinutes?: number;
  disabled?: boolean;
  /** Host can clear the range (binds `@clear`); false hides the button. Native derives this from `onClear != null`. */
  hasClear?: boolean;
  title?: string;
  customText?: string;
  fromLabel?: string;
  toLabel?: string;
  clearText?: string;
  unlimitedText?: string;
  invalidText?: string;
}>(), {
  options: () => [],
  allowCustom: true,
  customActive: false,
  disabled: false,
  hasClear: true,
});
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("searchDateRangeFilter.title"),
  customText: props.customText ?? t("searchDateRangeFilter.custom"),
  fromLabel: props.fromLabel ?? t("searchDateRangeFilter.from"),
  toLabel: props.toLabel ?? t("searchDateRangeFilter.to"),
  clearText: props.clearText ?? t("searchDateRangeFilter.clear"),
  unlimitedText: props.unlimitedText ?? t("searchDateRangeFilter.unlimited"),
  invalidText: props.invalidText ?? t("searchDateRangeFilter.invalid"),
}));
const emit = defineEmits<{ change: [range: FlareSearchTimeRange]; clear: [] }>();

const draft = ref(datesFromRange(props.value, props.tzOffsetMinutes));
// Re-seed the pickers only when the host pushes a range the current draft does not
// already describe — an in-progress illegal draft must survive until it is fixed.
watch(() => [props.value, props.tzOffsetMinutes] as const, ([value, tz]) => {
  const current = rangeFromDates(draft.value.from, draft.value.to, tz);
  if (!current || !sameSearchTimeRange(current, value)) draft.value = datesFromRange(value, tz);
}, { deep: true });

const forcedOpen = computed(() =>
  shouldOpenCustomRange(props.value, props.options, props.allowCustom, props.customActive));
const customOpen = ref(forcedOpen.value);
watch(forcedOpen, (open) => { if (open) customOpen.value = true; });
const showCustom = computed(() => props.allowCustom && customOpen.value);
const customId = useId();

const selectedId = computed(() => matchedOptionId(props.value, props.options));
const unrestricted = computed(() => unrestrictedRange(props.value));
const draftRange = computed(() => rangeFromDates(draft.value.from, draft.value.to, props.tzOffsetMinutes));
const invalid = computed(() => props.allowCustom && draftRange.value === null);

const summary = computed(() => {
  if (unrestricted.value) return strings.value.unlimitedText;
  const preset = props.options.find((option) => option.id === selectedId.value);
  if (preset) return preset.label;
  const dates = datesFromRange(props.value, props.tzOffsetMinutes);
  const parts: string[] = [];
  if (dates.from) parts.push(`${strings.value.fromLabel} ${dates.from}`);
  if (dates.to) parts.push(`${strings.value.toLabel} ${dates.to}`);
  return parts.join(' · ') || strings.value.unlimitedText;
});

function chooseOption(option: FlareSearchRangeOption): void {
  if (props.disabled || !validSearchTimeRange(option)) return;
  const next: FlareSearchTimeRange = { fromTime: option.fromTime, toTime: option.toTime };
  if (sameSearchTimeRange(next, props.value)) return;
  emit('change', next);
}
function commit(): void {
  const range = draftRange.value;
  if (!range) return; // illegal draft: keep what the user picked, emit nothing
  if (sameSearchTimeRange(range, props.value)) return;
  emit('change', range);
}
function pickFrom(date: string): void {
  if (props.disabled) return;
  draft.value = { ...draft.value, from: date };
  commit();
}
function pickTo(date: string): void {
  if (props.disabled) return;
  draft.value = { ...draft.value, to: date };
  commit();
}
</script>

<template>
  <section class="flare-search-date-range" :aria-label="strings.title" :aria-disabled="disabled || undefined">
    <h3 class="flare-search-date-range__title">{{ strings.title }}</h3>

    <div class="flare-search-date-range__chips" role="group" :aria-label="strings.title">
      <button
        v-for="option in options" :key="option.id" type="button"
        class="flare-search-date-range__chip"
        :aria-pressed="selectedId === option.id"
        :disabled="disabled || !validSearchTimeRange(option)"
        @click="chooseOption(option)"
      >{{ option.label }}</button>
      <button
        v-if="allowCustom" type="button"
        class="flare-search-date-range__chip"
        :aria-pressed="showCustom" :aria-expanded="showCustom" :aria-controls="customId"
        :disabled="disabled"
        @click="customOpen = !customOpen"
      >
        <FlareIcon name="calendar" :size="16" aria-hidden="true" />
        <span>{{ strings.customText }}</span>
      </button>
    </div>

    <div v-if="showCustom" :id="customId" class="flare-search-date-range__custom">
      <div class="flare-search-date-range__field">
        <span :id="`${customId}-from`" class="flare-search-date-range__label">{{ strings.fromLabel }}</span>
        <div class="flare-search-date-range__control">
          <FlareDatePicker
            :model-value="draft.from" :placeholder="strings.fromLabel" :title="strings.fromLabel"
            :min="minDate" :max="maxDate" :disabled="disabled" @change="pickFrom"
          />
          <button
            v-if="draft.from" type="button" class="flare-search-date-range__reset"
            :disabled="disabled" :aria-label="`${strings.clearText} ${strings.fromLabel}`" @click="pickFrom('')"
          ><FlareIcon name="close" :size="14" aria-hidden="true" /></button>
        </div>
      </div>
      <div class="flare-search-date-range__field">
        <span :id="`${customId}-to`" class="flare-search-date-range__label">{{ strings.toLabel }}</span>
        <div class="flare-search-date-range__control">
          <FlareDatePicker
            :model-value="draft.to" :placeholder="strings.toLabel" :title="strings.toLabel"
            :min="minDate" :max="maxDate" :disabled="disabled" @change="pickTo"
          />
          <button
            v-if="draft.to" type="button" class="flare-search-date-range__reset"
            :disabled="disabled" :aria-label="`${strings.clearText} ${strings.toLabel}`" @click="pickTo('')"
          ><FlareIcon name="close" :size="14" aria-hidden="true" /></button>
        </div>
      </div>
    </div>

    <p v-if="invalid" class="flare-search-date-range__invalid" role="alert">
      <FlareIcon name="warning" :size="16" aria-hidden="true" />
      <span>{{ strings.invalidText }}</span>
    </p>

    <div class="flare-search-date-range__footer">
      <p class="flare-search-date-range__summary" role="status">{{ summary }}</p>
      <button
        v-if="hasClear && !unrestricted" type="button"
        class="flare-search-date-range__clear" :disabled="disabled" @click="emit('clear')"
      >{{ strings.clearText }}</button>
    </div>
  </section>
</template>

<style scoped>
.flare-search-date-range {
  display: grid;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  color: var(--flare-color-text-primary);
}
.flare-search-date-range__title { margin: 0; font-size: var(--flare-size-font-size-xl); font-weight: 600; }

.flare-search-date-range__chips { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); }
.flare-search-date-range__chip {
  display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs);
  min-height: var(--flare-size-layout-touch-target); min-width: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  font: inherit; font-size: var(--flare-size-font-size-lg); cursor: pointer;
  color: var(--flare-color-text-primary); background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-full);
  overflow-wrap: anywhere;
}
.flare-search-date-range__chip:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-search-date-range__chip[aria-pressed="true"] {
  color: var(--flare-color-primary-text);
  background: var(--flare-color-bg-selected);
  border-color: var(--flare-color-primary);
}
.flare-search-date-range__chip:disabled,
.flare-search-date-range__reset:disabled,
.flare-search-date-range__clear:disabled {
  cursor: not-allowed; color: var(--flare-color-text-disabled);
  background: var(--flare-color-bg-disabled); border-color: var(--flare-color-border-primary);
}
.flare-search-date-range__chip:focus-visible,
.flare-search-date-range__reset:focus-visible,
.flare-search-date-range__clear:focus-visible {
  outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px;
}

.flare-search-date-range__custom {
  display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-md);
  background: var(--flare-color-bg-secondary); border-radius: var(--flare-size-radius-lg);
}
.flare-search-date-range__field { flex: 1 1 180px; min-width: 0; display: grid; gap: var(--flare-size-spacing-xs); }
.flare-search-date-range__label { font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
.flare-search-date-range__control { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-search-date-range__control > :first-child { flex: 1; min-width: 0; }
.flare-search-date-range__reset {
  flex: none; display: inline-flex; align-items: center; justify-content: center;
  min-width: var(--flare-size-layout-touch-target); min-height: var(--flare-size-layout-touch-target);
  color: var(--flare-color-text-secondary); background: none; border: none; cursor: pointer;
}
.flare-search-date-range__reset:hover:not(:disabled) { color: var(--flare-color-text-primary); }

.flare-search-date-range__invalid {
  display: flex; align-items: flex-start; gap: var(--flare-size-spacing-xs);
  margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-warning-text);
  overflow-wrap: anywhere;
}

.flare-search-date-range__footer {
  display: flex; flex-wrap: wrap; align-items: center; gap: var(--flare-size-spacing-sm);
}
.flare-search-date-range__summary {
  flex: 1; min-width: 0; margin: 0;
  font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-search-date-range__clear {
  min-height: var(--flare-size-layout-touch-target); min-width: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  font: inherit; font-size: var(--flare-size-font-size-md); cursor: pointer;
  color: var(--flare-color-text-primary); background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md);
}
.flare-search-date-range__clear:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
</style>
