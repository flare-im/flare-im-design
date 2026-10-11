<script setup lang="ts">
/**
 * A filter bar — the query form above a console list: labelled fields (a FlareFormField around a
 * kit control each), a Search key, a Reset key, and the less used fields folded behind "More
 * filters" so a list with eight conditions does not open on a wall of inputs. The host owns every
 * value and runs the query; the bar only says when (`search`, `reset`) and lays the fields out in a
 * grid that wraps by the bar's own width, with the keys at the end of the last row.
 *
 * Enter in a one-line text field searches — what a person expects of a query form, and what a
 * console otherwise wires by hand on every input. A control that acts on its own Enter keeps it: an
 * open combobox picking an option (it marks the key handled, or says it is expanded), a textarea's
 * new line, an IME composition's commit, a button.
 *
 * It is a `search` landmark, not a `<form>`: a host button in the `actions` slot is then never a
 * submit button by accident, and nothing posts anywhere.
 */
import { computed, onBeforeUnmount, onMounted, ref, useId, useSlots } from "vue";
import FlareButton from "./FlareButton.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareIcons } from "../../shared/icons";

const props = withDefaults(
  defineProps<{
    /** Accessible name of the search region. Default: the kit's "Filters". */
    label?: string;
    /** A line above the fields — what the query needs, what it searches. */
    hint?: string;
    /** The host is running the query: the Search key shows progress and Enter waits. */
    loading?: boolean;
    /** Search key text. Default: the kit's "Search". */
    searchText?: string;
    /** Reset key text. Default: the kit's "Reset". */
    resetText?: string;
    /** Draw the Reset key. */
    resettable?: boolean;
    /** How many of the folded fields hold a value: shown on the "More filters" key while they are folded. */
    moreActiveCount?: number;
  }>(),
  {
    label: undefined,
    hint: undefined,
    loading: false,
    searchText: undefined,
    resetText: undefined,
    resettable: true,
    moreActiveCount: 0,
  },
);
/** Whether the `more` fields are shown (v-model:expanded). */
const expanded = defineModel<boolean>("expanded", { default: false });
const emit = defineEmits<{
  (e: "search"): void;
  (e: "reset"): void;
}>();

const { t } = useFlareI18nOptional();
const slots = useSlots();
const uid = useId();
const hintId = `flare-filter-bar-hint-${uid}`;
const moreId = `flare-filter-bar-more-${uid}`;

const name = computed(() => props.label || t("filterBar.label"));
const hasMore = computed(() => Boolean(slots.more));
const toggleText = computed(() => {
  if (expanded.value) return t("filterBar.less");
  const count = Math.max(0, Math.floor(props.moreActiveCount));
  return count > 0 ? t("filterBar.moreCount", { count }) : t("filterBar.more");
});

// The keys take the last two cells of the last row, or the whole row when the grid is one column
// wide. The column count is the grid's own (it depends on the host's minimum field width), so it is
// read off the laid-out grid rather than guessed from a breakpoint.
const fields = ref<HTMLElement | null>(null);
const columnCount = ref(0);
let observer: ResizeObserver | null = null;
function measure(): void {
  const grid = fields.value;
  if (!grid || typeof getComputedStyle === "undefined") return;
  const template = getComputedStyle(grid).gridTemplateColumns;
  columnCount.value = template && template !== "none" ? template.trim().split(/\s+/).length : 0;
}
onMounted(() => {
  measure();
  if (!fields.value || typeof ResizeObserver === "undefined") return;
  observer = new ResizeObserver(measure);
  observer.observe(fields.value);
});
onBeforeUnmount(() => observer?.disconnect());
const actionsStyle = computed(() => ({ gridColumn: columnCount.value >= 2 ? "span 2 / -1" : "1 / -1" }));

/** One-line fields whose Enter means "run the query". */
const SEARCHING_INPUT_TYPES = new Set(["text", "search", "email", "tel", "url", "number", "password"]);

function search(): void {
  if (!props.loading) emit("search");
}
function reset(): void {
  emit("reset");
}
function toggleMore(): void {
  expanded.value = !expanded.value;
}
function onKeydown(event: KeyboardEvent): void {
  if (event.key !== "Enter" || event.defaultPrevented) return;
  if (event.isComposing || event.keyCode === 229) return;
  if (event.shiftKey || event.altKey || event.ctrlKey || event.metaKey) return;
  const target = event.target;
  if (!(target instanceof HTMLInputElement) || !SEARCHING_INPUT_TYPES.has(target.type)) return;
  if (target.getAttribute("aria-expanded") === "true") return;
  event.preventDefault();
  search();
}
</script>

<template>
  <div
    class="flare-filter-bar"
    role="search"
    :aria-label="name"
    :aria-describedby="hint ? hintId : undefined"
    @keydown="onKeydown"
  >
    <p v-if="hint" :id="hintId" class="flare-filter-bar__hint">{{ hint }}</p>
    <div ref="fields" class="flare-filter-bar__fields">
      <slot />
      <div v-if="hasMore && expanded" :id="moreId" class="flare-filter-bar__more"><slot name="more" /></div>
      <div class="flare-filter-bar__actions" :style="actionsStyle">
        <FlareButton
          class="flare-filter-bar__search"
          :label="searchText ?? t('filterBar.search')"
          :loading="loading"
          @click="search"
        />
        <FlareButton
          v-if="resettable"
          class="flare-filter-bar__reset"
          variant="secondary"
          :label="resetText ?? t('filterBar.reset')"
          @click="reset"
        />
        <FlareButton
          v-if="hasMore"
          class="flare-filter-bar__toggle"
          variant="text"
          :icon="expanded ? flareIcons['chevron-up'] : flareIcons['chevron-down']"
          :label="toggleText"
          :aria-expanded="expanded ? 'true' : 'false'"
          :aria-controls="expanded ? moreId : undefined"
          @click="toggleMore"
        />
        <slot name="actions" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-filter-bar {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-filter-bar__hint {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
}
/* As many columns as fields of the minimum width fit; the keys take the last two cells of the last row
   (the whole row on a one-column grid), so Search, Reset and More sit on one line beside the fields. */
.flare-filter-bar__fields {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(100%, var(--flare-component-filter-bar-field-min-width)), 1fr));
  align-items: end;
  gap: var(--flare-size-spacing-md) var(--flare-size-spacing-lg);
  min-width: 0;
}
.flare-filter-bar__fields > :deep(*) { min-width: 0; }
/* The folded fields are grid cells like the others, not a nested block. */
.flare-filter-bar__more { display: contents; }
.flare-filter-bar__actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
</style>
