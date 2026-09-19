<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import FlareSearchBar from './FlareSearchBar.vue';
import FlareFilterTabs, { type FlareFilterTabOption } from './FlareFilterTabs.vue';
import FlareSearchResults from './FlareSearchResults.vue';
import FlareStatusBanner from './FlareStatusBanner.vue';
import { sameSearchCriteria, sameSearchTimeRange, validSearchTimeRange, type FlareSearchRangeOption, type FlareSearchCriteria, type FlareSearchSnapshot, type FlareSearchTimeRange } from '../../shared/contracts/search-panel';
import type { FlareSearchResultItem, FlareSearchResultGroup } from '../../shared/contracts';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

/**
 * Search with filters: a search bar, one row of result types, an optional row of time ranges and the
 * results. The host runs the search and reports it back through `snapshot`. Typing searches after a
 * short pause (never while an IME is composing); Enter, clearing, a type or a time range searches at
 * once. With nothing typed and the first type and no time range chosen the panel rests idle.
 */
const props = withDefaults(defineProps<{
  snapshot: FlareSearchSnapshot;
  filters: Record<string, string>;
  searchText?: string;
  idleText?: string;
  timeRanges?: FlareSearchRangeOption[];
  timeRangeText?: string;
  /** Put the caret in the search field when the panel opens. */
  autofocus?: boolean;
}>(), { timeRanges: () => [], autofocus: false });
const { t } = useFlareI18n();
const strings = computed(() => ({
  searchText: props.searchText ?? t("searchPanel.search"),
  idleText: props.idleText ?? t("searchPanel.idle"),
  timeRangeText: props.timeRangeText ?? t("searchPanel.timeRange"),
  typeText: t("searchPanel.type"),
  searching: t("searchPanel.searching"),
}));
const emit = defineEmits<{ search: [criteria: FlareSearchCriteria]; open: [item: FlareSearchResultItem]; viewAll: [kind: FlareSearchResultGroup['kind']] }>();

const SEARCH_DELAY_MS = 300;

const filterOptions = computed<FlareFilterTabOption[]>(() => Object.entries(props.filters).map(([value, label]) => ({ value, label })));
const defaultFilter = computed(() => filterOptions.value[0]?.value ?? '');
const rangeOptions = computed(() => props.timeRanges.filter((option) => validSearchTimeRange(option)));
const rangeTabs = computed<FlareFilterTabOption[]>(() => rangeOptions.value.map((option) => ({ value: option.id, label: option.label })));

const draft = ref(props.snapshot.criteria.query);
const filter = ref(props.snapshot.criteria.filterId);
const range = ref<FlareSearchTimeRange>({ fromTime: props.snapshot.criteria.fromTime, toTime: props.snapshot.criteria.toTime });
const submitted = ref<FlareSearchCriteria>({ ...props.snapshot.criteria });
const activeRange = computed(() => rangeOptions.value.find((option) => sameSearchTimeRange(range.value, option))?.id ?? '');

function isIdle(criteria: FlareSearchCriteria): boolean {
  return !criteria.query.trim() && (!criteria.filterId || criteria.filterId === defaultFilter.value)
    && criteria.fromTime === undefined && criteria.toTime === undefined;
}
const idle = computed(() => isIdle(submitted.value));
const current = computed(() => sameSearchCriteria(submitted.value, props.snapshot.criteria));
const waiting = computed(() => !idle.value && (!current.value || props.snapshot.state === 'loading'));

// The last results stay on screen while the next query runs, so typing does not blank the list.
const shown = ref<{ groups: FlareSearchResultGroup[]; query: string } | null>(null);
watch(() => props.snapshot, (snapshot) => {
  if (snapshot.state === 'success') shown.value = { groups: snapshot.groups, query: snapshot.criteria.query };
  // A host that resets its search to idle (a closed sheet) resets the panel with it.
  if (snapshot.state === 'idle' && isIdle(snapshot.criteria) && !isIdle(submitted.value)) {
    cancelPending();
    draft.value = snapshot.criteria.query;
    filter.value = snapshot.criteria.filterId;
    range.value = {};
    submitted.value = { ...snapshot.criteria };
    shown.value = null;
  }
}, { immediate: true });

let timer: ReturnType<typeof setTimeout> | undefined;
const composing = ref(false);
function cancelPending(): void {
  if (timer !== undefined) clearTimeout(timer);
  timer = undefined;
}
onBeforeUnmount(cancelPending);

function submit(): void {
  cancelPending();
  const criteria: FlareSearchCriteria = { query: draft.value.trim(), filterId: filter.value, ...range.value };
  if (sameSearchCriteria(criteria, submitted.value) && !isIdle(criteria) && props.snapshot.state !== 'failure') return;
  submitted.value = criteria;
  if (isIdle(criteria)) {
    shown.value = null;
    return;
  }
  emit('search', { ...criteria });
}
function scheduleSubmit(): void {
  cancelPending();
  if (composing.value) return;
  timer = setTimeout(submit, SEARCH_DELAY_MS);
}
watch(draft, scheduleSubmit);
function onCompositionEnd(): void {
  composing.value = false;
  scheduleSubmit();
}
function chooseFilter(id: string): void {
  filter.value = id;
  submit();
}
function chooseRange(id: string): void {
  const option = rangeOptions.value.find((candidate) => candidate.id === id);
  if (!option) return;
  range.value = { fromTime: option.fromTime, toTime: option.toTime };
  submit();
}
function retry(): void {
  emit('search', { ...submitted.value });
}
</script>
<template>
  <section class="flare-search-panel" @compositionstart="composing = true" @compositionend="onCompositionEnd">
    <FlareSearchBar
      v-model="draft"
      :placeholder="strings.searchText"
      :loading="waiting"
      :autofocus="autofocus"
      @submit="submit"
      @clear="submit"
    />
    <FlareFilterTabs
      v-if="filterOptions.length > 1"
      :model-value="filter"
      :options="filterOptions"
      :aria-label="strings.typeText"
      @change="chooseFilter"
    />
    <FlareFilterTabs
      v-if="rangeTabs.length"
      :model-value="activeRange"
      :options="rangeTabs"
      :aria-label="strings.timeRangeText"
      @change="chooseRange"
    />
    <p v-if="idle" class="flare-search-panel__status" role="status">{{ strings.idleText }}</p>
    <FlareStatusBanner v-else-if="current && snapshot.state === 'failure'" :text="snapshot.error || strings.idleText" tone="danger" :action-text="t('common.retry')" @action="retry" />
    <div v-else-if="shown" class="flare-search-panel__results" :aria-busy="waiting">
      <FlareSearchResults :groups="shown.groups" :query="shown.query" @open="emit('open', $event)" @view-all="emit('viewAll', $event)" />
    </div>
    <p v-else class="flare-search-panel__status" role="status">{{ strings.searching }}</p>
  </section>
</template>
<style scoped>
.flare-search-panel { min-width: 0; display: grid; align-content: start; gap: var(--flare-size-spacing-md); color: var(--flare-color-text-primary); }
.flare-search-panel__status { margin: 0; padding: var(--flare-size-spacing-lg) 0; color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-md); text-align: center; }
.flare-search-panel__results[aria-busy="true"] { opacity: 0.6; transition: opacity var(--flare-transition-fast); }
@media (prefers-reduced-motion: reduce) { .flare-search-panel__results[aria-busy="true"] { transition: none; } }
</style>
