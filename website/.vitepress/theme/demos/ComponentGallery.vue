<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import catalog from "../../../../spec/component-catalog.json";

const props = defineProps({ scope: { type: String, default: "all" } });
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const loc = computed(() => (en.value ? "en" : "zh"));
const prefix = computed(() => (en.value ? "/en/components" : "/components"));
const query = ref("");
const surface = ref("all");
const platform = ref("all");
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
const filtered = computed(() => catalog.components.filter((component) => {
  if (props.scope !== "all" && component.layer !== props.scope) return false;
  if (surface.value === "general" && component.layer !== "general-ui") return false;
  if (surface.value === "im" && component.layer !== "im-ui") return false;
  if (surface.value === "patterns" && !["patterns", "workspaces", "appkit"].includes(component.layer)) return false;
  if (platform.value !== "all" && component.platforms[platform.value]?.support !== "supported") return false;
  return !normalizedQuery.value || component.searchText.includes(normalizedQuery.value);
}));
const summary = (component) => component.summary?.[loc.value] ?? component.summary?.en ?? "";
</script>

<template>
  <div class="catalog">
    <div class="catalog__summary" role="status" aria-live="polite">
      <strong>{{ filtered.length }}</strong> / {{ catalog.counts.total }} {{ t("个组件", "components") }}
      <span>{{ catalog.counts.general }} General UI</span>
      <span>{{ catalog.counts.im }} IM UI</span>
    </div>

    <div class="catalog__filters" role="search">
      <label class="catalog__search">
        <span>{{ t("搜索", "Search") }}</span>
        <input v-model="query" type="search" :placeholder="t('组件、状态、token、交互或 IM 概念', 'Component, state, token, interaction, or IM concept')" />
      </label>
      <div v-if="scope === 'all'" class="catalog__segments" role="group" :aria-label="t('组件类型', 'Component type')">
        <button v-for="item in surfaces" :key="item.value" type="button" :aria-pressed="surface === item.value" @click="surface = item.value">{{ item.label }}</button>
      </div>
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
        <span class="catalog__name"><strong>{{ component.name }}</strong><small>{{ component.category }}</small></span>
        <span class="catalog__description">{{ summary(component) }}</span>
        <span v-if="component.status !== 'stable'" class="catalog__status" :data-status="component.status">{{ component.status }}</span>
      </a>
      <p v-if="filtered.length === 0" class="catalog__empty">{{ t("没有匹配项。尝试 custom action、composer plus、自定义消息或 capability。", "No matches. Try custom action, composer plus, custom message, or capability.") }}</p>
    </div>
  </div>
</template>

<style scoped>
.catalog { margin-top: 16px; }
.catalog__summary { display: flex; flex-wrap: wrap; align-items: baseline; gap: 8px 20px; padding-block: 12px; border-block: 1px solid var(--vp-c-divider); color: var(--vp-c-text-2); }
.catalog__summary strong { color: var(--vp-c-text-1); font-size: 20px; font-variant-numeric: tabular-nums; }
.catalog__filters { display: grid; grid-template-columns: minmax(240px, 1fr) auto minmax(140px, 180px); align-items: end; gap: 12px; margin: 20px 0 12px; }
.catalog__filters label { display: grid; gap: 5px; color: var(--vp-c-text-2); font-size: 12px; }
.catalog__filters input,
.catalog__filters select { width: 100%; min-height: 40px; padding: 7px 10px; border: 1px solid var(--vp-c-divider); border-radius: 6px; background: var(--vp-c-bg); color: var(--vp-c-text-1); font: inherit; }
.catalog__filters input:focus-visible,
.catalog__filters select:focus-visible,
.catalog__segments button:focus-visible { outline: 2px solid var(--vp-c-brand-1); outline-offset: 2px; }
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
.catalog__empty { padding: 24px 4px; color: var(--vp-c-text-2); }
@media (max-width: 720px) {
  .catalog__filters { grid-template-columns: 1fr; align-items: stretch; }
  .catalog__segments { overflow-x: auto; }
  .catalog__segments button { flex: 1 0 auto; }
  .catalog__item { grid-template-columns: 1fr; gap: 6px; }
  .catalog__status { justify-self: start; }
}
</style>
