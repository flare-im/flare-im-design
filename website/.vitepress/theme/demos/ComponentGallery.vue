<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import catalog from "../../../../spec/component-catalog.json";

const props = defineProps({ scope: { type: String, default: "all" }, category: { type: String, default: "" } });
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const loc = computed(() => (en.value ? "en" : "zh"));
const prefix = computed(() => (en.value ? "/en/components" : "/components"));
const query = ref("");
const surface = ref("all");
const platform = ref("all");
const categoryFilter = ref("all");
const t = (zh, english) => (en.value ? english : zh);

const platformLabels = {
  vue: "Vue",
  flutter: "Flutter",
  compose: "Compose",
  ios: "SwiftUI",
};
const surfaces = computed(() => [
  { value: "all", label: t("全部", "All") },
  { value: "general", label: t("通用", "General") },
  { value: "im", label: "IM" },
  { value: "patterns", label: "Patterns" },
]);
const normalizedQuery = computed(() => query.value.trim().toLowerCase());
const scopedComponents = computed(() => catalog.components.filter((component) =>
  (props.scope === "all" || component.layer === props.scope) && (!props.category || component.category === props.category)));
const categoryLabel = (category) => catalog.categoryLabels?.[category]?.[loc.value] ?? category;
const categories = computed(() => catalog.categories.filter((category) => scopedComponents.value.some((component) => component.category === category)));
const filtered = computed(() => scopedComponents.value.filter((component) => {
  if (categoryFilter.value !== "all" && component.category !== categoryFilter.value) return false;
  if (surface.value === "general" && component.layer !== "general-ui") return false;
  if (surface.value === "im" && component.layer !== "im-ui") return false;
  if (surface.value === "patterns" && !["patterns", "workspaces", "appkit"].includes(component.layer)) return false;
  if (platform.value !== "all" && component.platforms[platform.value]?.support !== "supported") return false;
  return !normalizedQuery.value || component.searchText.includes(normalizedQuery.value);
}));
function resetFilters() { query.value = ""; surface.value = "all"; platform.value = "all"; categoryFilter.value = "all"; }
const summary = (component) => component.summary?.[loc.value] ?? component.summary?.en ?? "";
</script>

<template>
  <div class="catalog">
    <div class="catalog__summary" role="status" aria-live="polite">
      <strong>{{ filtered.length }}</strong> / {{ scopedComponents.length }} {{ t("个组件", "components") }}
      <span v-if="scope === 'all' && !category">{{ catalog.counts.general }} General UI · {{ catalog.counts.im }} IM UI</span>
    </div>

    <div class="catalog__filters" role="search">
      <label class="catalog__search">
        <span>{{ t("搜索", "Search") }}</span>
        <input v-model="query" type="search" :placeholder="t('组件、状态、token、交互或 IM 概念', 'Component, state, token, interaction, or IM concept')" />
      </label>
      <div v-if="scope === 'all' && !category" class="catalog__segments" role="group" :aria-label="t('组件类型', 'Component type')">
        <button v-for="item in surfaces" :key="item.value" type="button" :aria-pressed="surface === item.value" @click="surface = item.value">{{ item.label }}</button>
      </div>
      <label v-if="!category" class="catalog__category-filter">
        <span>{{ t("使用场景", "Category") }}</span>
        <select v-model="categoryFilter">
          <option value="all">{{ t("全部分类", "All categories") }}</option>
          <option v-for="item in categories" :key="item" :value="item">{{ categoryLabel(item) }}</option>
        </select>
      </label>
      <label class="catalog__platform-filter">
        <span>{{ t("平台", "Platform") }}</span>
        <select v-model="platform">
          <option value="all">{{ t("全部平台", "All platforms") }}</option>
          <option v-for="(label, key) in platformLabels" :key="key" :value="key">{{ label }}</option>
        </select>
      </label>
    </div>

    <div class="catalog__list">
      <a v-for="component in filtered" :key="component.name" class="catalog__item" :href="`${prefix}/${component.slug}`">
        <span class="catalog__name"><strong>{{ component.name }}</strong><small>{{ categoryLabel(component.category) }}</small></span>
        <span class="catalog__description">{{ summary(component) }}</span>
        <span v-if="component.status !== 'stable'" class="catalog__status" :data-status="component.status">{{ component.status }}</span>
      </a>
      <div v-if="filtered.length === 0" class="catalog__empty" role="status">
        <p>{{ t("没有匹配的组件，请调整搜索、分类或平台。", "No components match. Adjust the search, category, or platform.") }}</p>
        <button type="button" @click="resetFilters">{{ t("重置筛选", "Reset filters") }}</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.catalog { margin-top: 16px; }
.catalog__summary { display: flex; flex-wrap: wrap; align-items: baseline; gap: 8px 20px; padding-block: 12px; border-block: 1px solid var(--vp-c-divider); color: var(--vp-c-text-2); }
.catalog__summary strong { color: var(--vp-c-text-1); font-size: 20px; font-variant-numeric: tabular-nums; }
.catalog__filters { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); align-items: end; gap: 12px; margin: 20px 0 12px; }
.catalog__search { grid-column: 1 / -1; }
.catalog__segments { grid-column: 1 / -1; }
.catalog__filters label { min-width: 0; display: grid; gap: 5px; color: var(--vp-c-text-2); font-size: 12px; }
.catalog__filters input,
.catalog__filters select { width: 100%; min-height: 40px; padding: 7px 10px; border: 1px solid var(--vp-c-divider); border-radius: 6px; background: var(--vp-c-bg); color: var(--vp-c-text-1); font: inherit; }
.catalog__filters input:focus-visible,
.catalog__filters select:focus-visible,
.catalog__segments button:focus-visible,
.catalog__empty button:focus-visible { outline: 2px solid var(--vp-c-brand-1); outline-offset: 2px; }
.catalog__segments { display: inline-flex; min-height: 40px; overflow: hidden; border: 1px solid var(--vp-c-divider); border-radius: 6px; }
.catalog__segments button { min-width: 68px; padding: 7px 10px; border: 0; border-inline-end: 1px solid var(--vp-c-divider); color: var(--vp-c-text-2); background: var(--vp-c-bg); font: inherit; font-size: 12px; cursor: pointer; }
.catalog__segments button:last-child { border-inline-end: 0; }
.catalog__segments button[aria-pressed="true"] { color: var(--vp-c-brand-1); background: var(--vp-c-brand-soft); font-weight: 650; }
.catalog__list { border-top: 1px solid var(--vp-c-divider); }
.catalog__item { display: grid; grid-template-columns: minmax(170px, 0.7fr) minmax(260px, 2fr) auto; gap: 18px; align-items: start; padding: 14px 4px; border-bottom: 1px solid var(--vp-c-divider); color: var(--vp-c-text-1); text-decoration: none; }
.catalog__item:hover .catalog__name strong { color: var(--vp-c-brand-1); }
.catalog__name { display: grid; gap: 3px; min-width: 0; }
.catalog__name strong { overflow-wrap: anywhere; font-size: 14px; }
.catalog__name small { color: var(--vp-c-text-3); font-size: 11px; }
.catalog__description { color: var(--vp-c-text-2); font-size: 13px; line-height: 1.55; }
.catalog__status { font-family: var(--vp-font-family-mono); }
.catalog__status[data-status="stable"] { color: var(--flare-color-success-text, #15803d); }
.catalog__empty button { min-height: 44px; padding: 8px 12px; color: var(--vp-c-brand-1); border: 1px solid var(--vp-c-divider); border-radius: 6px; cursor: pointer; }
.catalog__empty { padding: 24px 4px; color: var(--vp-c-text-2); }
@media (max-width: 720px) {
  .catalog__filters { grid-template-columns: 1fr; align-items: stretch; }
  .catalog__segments { overflow-x: auto; }
  .catalog__segments button { flex: 1 0 auto; }
  .catalog__item { grid-template-columns: 1fr; gap: 6px; }
  .catalog__status { justify-self: start; }
}
</style>
