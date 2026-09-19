<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import tokens from "../../../../tokens/tokens.json";

const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const t = (zh, english) => (en.value ? english : zh);
const query = ref("");
const category = ref("all");
const kebab = (value) => value.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const cap = (value) => value.charAt(0).toUpperCase() + value.slice(1);

function flatten(group, value, prefix = []) {
  const rows = [];
  for (const [key, item] of Object.entries(value ?? {})) {
    if (item && typeof item === "object") rows.push(...flatten(group, item, [...prefix, key]));
    else rows.push({ group, path: [...prefix, key], value: item });
  }
  return rows;
}

function atPath(value, path) {
  return path.reduce((current, key) => current?.[key], value);
}

function fieldName(row) {
  if (row.group === "colors") return row.path[0] + row.path.slice(1).map(cap).join("");
  if (row.group === "sizes") {
    const [sizeGroup, name] = row.path;
    return sizeGroup === "layout" ? name : sizeGroup + cap(name);
  }
  return row.path.join("");
}

function cssName(row) {
  if (row.group === "colors") return `--flare-color-${row.path.map(kebab).join("-")}`;
  if (row.group === "sizes") return `--flare-size-${row.path.map(kebab).join("-")}`;
  const singular = row.group === "transitions" ? "transition" : row.group === "shadows" ? "shadow" : row.group === "breakpoints" ? "breakpoint" : row.group === "zIndex" ? "z-index" : row.group;
  return `--flare-${singular}-${row.path.map(kebab).join("-")}`;
}

function purpose(row) {
  const name = `${row.group}.${row.path.join(".")}`;
  const known = {
    "colors.messageStatus.read": t("已读回执的语义色；必须与双勾几何和可访问名称同时出现。", "Semantic read-receipt color; pair it with double-check geometry and an accessible name."),
    "colors.messageStatus.delivered": t("已送达但未读的中性色。", "Neutral color for delivered but unread messages."),
    "colors.messageStatus.failed": t("发送失败及可恢复错误。", "Send failure and recoverable error."),
    "colors.focusRing": t("键盘焦点的可见轮廓。", "Visible keyboard-focus outline."),
    "breakpoints.compact": t("单窗格和触控优先布局边界。", "Boundary for single-pane, touch-first layout."),
  };
  return known[name] ?? t(`${row.group} 系统中的 ${row.path.join(" / ")} 语义值。`, `Semantic ${row.path.join(" / ")} value in the ${row.group} system.`);
}

const rows = computed(() => {
  const all = Object.entries(tokens)
    .filter(([group]) => group !== "dark")
    .flatMap(([group, value]) => flatten(group, value))
    .map((row) => ({
      ...row,
      name: `${row.group}.${row.path.join(".")}`,
      dark: atPath(tokens.dark?.[row.group], row.path) ?? row.value,
      css: cssName(row),
      field: fieldName(row),
      purpose: purpose(row),
    }));
  const needle = query.value.trim().toLowerCase();
  return all.filter((row) =>
    (category.value === "all" || row.group === category.value) &&
    (!needle || `${row.name} ${row.css} ${row.field} ${row.purpose}`.toLowerCase().includes(needle)),
  );
});
const categories = Object.keys(tokens).filter((key) => key !== "dark");
</script>

<template>
  <div class="token-explorer">
    <div class="token-explorer__controls">
      <label><span>{{ t("搜索 token", "Search tokens") }}</span><input v-model="query" type="search" placeholder="messageStatus.read" /></label>
      <label><span>{{ t("类别", "Category") }}</span><select v-model="category"><option value="all">{{ t("全部", "All") }}</option><option v-for="item in categories" :key="item" :value="item">{{ item }}</option></select></label>
    </div>
    <p role="status">{{ rows.length }} {{ t("个 token", "tokens") }}</p>
    <div class="token-explorer__table-wrap">
      <table>
        <thead><tr><th>Token</th><th>{{ t("语义", "Purpose") }}</th><th>Light</th><th>Dark</th><th>CSS</th><th>Dart / Kotlin / Swift</th></tr></thead>
        <tbody>
          <tr v-for="row in rows" :key="row.name">
            <td><code>{{ row.name }}</code></td>
            <td>{{ row.purpose }}</td>
            <td><span v-if="row.group === 'colors'" class="token-explorer__swatch" :style="{ background: row.value }" aria-hidden="true" /><code>{{ row.value }}</code></td>
            <td><span v-if="row.group === 'colors'" class="token-explorer__swatch" :style="{ background: row.dark }" aria-hidden="true" /><code>{{ row.dark }}</code></td>
            <td><code>{{ row.css }}</code></td>
            <td><code>Flare{{ row.group === 'colors' ? 'Colors' : row.group === 'sizes' ? 'Sizes' : '' }}.{{ row.field }}</code></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<style scoped>
.token-explorer__controls { display: grid; grid-template-columns: minmax(240px, 1fr) 180px; gap: 12px; margin: 20px 0; }
.token-explorer__controls label { display: grid; gap: 5px; color: var(--vp-c-text-2); font-size: 12px; }
.token-explorer input,
.token-explorer select { min-height: 40px; padding: 7px 10px; border: 1px solid var(--vp-c-divider); border-radius: 6px; background: var(--vp-c-bg); color: var(--vp-c-text-1); }
.token-explorer input:focus-visible,
.token-explorer select:focus-visible { outline: 2px solid var(--vp-c-brand-1); outline-offset: 2px; }
.token-explorer__table-wrap { overflow-x: auto; }
.token-explorer table { min-width: 1040px; font-size: 12px; }
.token-explorer td { vertical-align: top; }
.token-explorer__swatch { display: inline-block; width: 16px; height: 16px; margin-right: 6px; border: 1px solid var(--vp-c-divider); border-radius: 3px; vertical-align: middle; }
@media (max-width: 640px) { .token-explorer__controls { grid-template-columns: 1fr; } }
</style>
