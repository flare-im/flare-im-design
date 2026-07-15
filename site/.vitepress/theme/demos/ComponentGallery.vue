<script setup>
import { computed } from "vue";
import { useRoute } from "vitepress";
import spec from "../../../../spec/components.json";

const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const loc = computed(() => (en.value ? "en" : "zh"));

const slug = (name) => name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const prefix = computed(() => (en.value ? "/en/components" : "/components"));

const catLabel = (cat) => spec.categoryLabels?.[cat]?.[loc.value] ?? cat;

const groups = computed(() => {
  const byCat = {};
  for (const c of spec.components) (byCat[c.category] ??= []).push(c);
  return (spec.categories ?? Object.keys(byCat))
    .filter((cat) => byCat[cat]?.length)
    .map((cat) => ({ cat, label: catLabel(cat), items: byCat[cat] }));
});

const total = computed(() => spec.components.length);
const catCount = computed(() => groups.value.length);

const PLATFORMS = [
  { key: "vue", label: "Vue" },
  { key: "flutter", label: "Flutter" },
  { key: "ios", label: "iOS" },
  { key: "compose", label: "Android" },
];
const t = (zh, enText) => (en.value ? enText : zh);
</script>

<template>
  <div class="cg">
    <div class="cg__stats">
      <span><b>{{ total }}</b> {{ t("组件", "components") }}</span>
      <span><b>{{ catCount }}</b> {{ t("分类", "categories") }}</span>
      <span><b>4</b> {{ t("端原生", "platforms") }}</span>
    </div>

    <section v-for="g in groups" :key="g.cat" class="cg__group">
      <h2 :id="g.cat.toLowerCase()" class="cg__cat">
        {{ g.label }}<span class="cg__count">{{ g.items.length }}</span>
      </h2>
      <div class="cg__grid">
        <a v-for="c in g.items" :key="c.name" class="cg__card" :href="`${prefix}/${slug(c.name)}`">
          <div class="cg__name">{{ c.name }}</div>
          <p class="cg__summary">{{ c.summary?.[loc] ?? c.summary?.zh ?? "" }}</p>
          <div class="cg__plats">
            <span v-for="p in PLATFORMS" :key="p.key" class="cg__plat" :class="{ 'is-on': c.platforms?.[p.key] }">{{ p.label }}</span>
          </div>
        </a>
      </div>
    </section>
  </div>
</template>

<style scoped>
.cg { margin-top: 8px; }
.cg__stats {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  padding: 16px 20px;
  border-radius: 14px;
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
  margin-bottom: 28px;
}
.cg__stats span { font-size: 14px; color: var(--vp-c-text-2); }
.cg__stats b { font-size: 22px; color: var(--vp-c-brand-1); font-variant-numeric: tabular-nums; margin-right: 4px; }
.cg__group { margin: 0 0 28px; }
.cg__cat {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 18px;
  font-weight: 600;
  margin: 0 0 14px;
  padding: 0;
  border: none;
}
.cg__count {
  font-size: 12px;
  font-weight: 600;
  color: var(--vp-c-brand-1);
  background: var(--vp-c-brand-soft);
  border-radius: 999px;
  padding: 1px 9px;
  font-variant-numeric: tabular-nums;
}
.cg__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(232px, 1fr));
  gap: 12px;
}
.cg__card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 14px 16px;
  border-radius: 12px;
  border: 1px solid var(--vp-c-divider);
  background: var(--vp-c-bg);
  text-decoration: none;
  transition: border-color 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
}
.cg__card:hover {
  border-color: var(--vp-c-brand-1);
  transform: translateY(-2px);
  box-shadow: 0 8px 22px rgba(0, 0, 0, 0.06);
}
.cg__name { font-size: 15px; font-weight: 600; color: var(--vp-c-text-1); }
.cg__summary {
  margin: 0;
  font-size: 12.5px;
  line-height: 1.5;
  color: var(--vp-c-text-2);
  flex: 1;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.cg__plats { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 2px; }
.cg__plat {
  font-size: 10px;
  font-weight: 500;
  padding: 1px 6px;
  border-radius: 5px;
  color: var(--vp-c-text-3);
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
}
.cg__plat.is-on { color: var(--vp-c-brand-1); border-color: var(--vp-c-brand-soft); background: var(--vp-c-brand-soft); }
</style>
