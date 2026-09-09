<script setup lang="ts">
import { computed, ref } from 'vue';
import FlareSearchResults from './FlareSearchResults.vue';
import FlareStatusBanner from './FlareStatusBanner.vue';
import { sameSearchCriteria, sameSearchTimeRange, validSearchTimeRange, type FlareSearchRangeOption, type FlareSearchCriteria, type FlareSearchSnapshot } from '../../shared/contracts/search-panel';
import type { FlareSearchResultItem, FlareSearchResultGroup } from '../../shared/contracts';
const props = withDefaults(defineProps<{ snapshot: FlareSearchSnapshot; filters: Record<string,string>; searchText?: string; idleText?: string; timeRanges?: FlareSearchRangeOption[]; timeRangeText?: string }>(), { searchText: '搜索', idleText: '输入关键词或选择类型', timeRanges: () => [], timeRangeText: '时间范围' });
const emit = defineEmits<{ search: [criteria: FlareSearchCriteria]; open: [item: FlareSearchResultItem]; viewAll: [kind: FlareSearchResultGroup['kind']] }>();
const draft = ref(props.snapshot.criteria.query), filter = ref(props.snapshot.criteria.filterId);
const range = ref({ fromTime: props.snapshot.criteria.fromTime, toTime: props.snapshot.criteria.toTime });
const submitted = ref({ ...props.snapshot.criteria });
const matches = computed(() => sameSearchCriteria(submitted.value, props.snapshot.criteria));
const waiting = computed(() => !matches.value || props.snapshot.state === 'loading');
function submit() {
  submitted.value = { query: draft.value.trim(), filterId: filter.value, ...range.value };
  emit('search', { ...submitted.value });
}
function chooseRange(option: FlareSearchRangeOption) {
  if (!validSearchTimeRange(option)) return;
  range.value = { fromTime: option.fromTime, toTime: option.toTime };
  submit();
}
function choose(id: string) { filter.value = id; submit(); }
</script>
<template>
  <section class="flare-search-panel">
    <form class="flare-search-panel__form" @submit.prevent="submit">
      <input v-model="draft" type="search" :aria-label="searchText" :placeholder="searchText" />
      <button type="submit">{{ searchText }}</button>
    </form>
    <div class="flare-search-panel__filters" role="group" :aria-label="searchText">
      <button v-for="(label,id) in filters" :key="id" type="button" :aria-pressed="filter === id" @click="choose(String(id))">{{ label }}</button>
    </div>
    <div v-if="timeRanges.length" class="flare-search-panel__filters" role="group" :aria-label="timeRangeText">
      <button v-for="option in timeRanges" :key="option.id" type="button" :disabled="!validSearchTimeRange(option)" :aria-pressed="sameSearchTimeRange(range, option)" @click="chooseRange(option)">{{ option.label }}</button>
    </div>
    <div v-if="waiting" role="status" :aria-label="searchText" class="flare-search-panel__waiting"><progress :aria-label="searchText" /></div>
    <FlareStatusBanner v-else-if="snapshot.state === 'failure'" :text="snapshot.error || idleText" tone="danger" :action-text="searchText" @action="emit('search', { ...submitted })" />
    <FlareSearchResults v-else-if="snapshot.state === 'success'" :groups="snapshot.groups" :query="submitted.query" @open="emit('open', $event)" @view-all="emit('viewAll', $event)" />
    <p v-else role="status">{{ idleText }}</p>
  </section>
</template>
<style scoped>
.flare-search-panel { min-width: 0; display: grid; gap: 12px; color: var(--flare-color-text-primary); }
.flare-search-panel__form { display: flex; flex-wrap: wrap; gap: 8px; }
input { flex: 1; min-width: 120px; width: 0; padding: 10px 12px; font: inherit; font-size: 16px; color: inherit; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); }
button { min-height: 48px; min-width: 48px; padding: 8px 12px; border-radius: 8px; border: 1px solid var(--flare-color-border-primary); color: inherit; background: var(--flare-color-bg-primary); font: inherit; cursor: pointer; }
button:disabled { opacity: .5; cursor: not-allowed; }
button[aria-pressed="true"] { background: var(--flare-color-bg-selected); border-color: var(--flare-color-primary); }
button:focus-visible, input:focus-visible { outline: 2px solid var(--flare-color-primary); outline-offset: 2px; }
.flare-search-panel__filters { display: flex; flex-wrap: wrap; gap: 8px; }
.flare-search-panel__waiting { padding: 16px; text-align: center; }
</style>
