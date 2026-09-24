<script setup lang="ts">
import { computed, useId } from "vue";
import FlareButton from "./FlareButton.vue";
import FlareIcon from "./FlareIcon.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

/**
 * Recent searches — what a search page shows before anything is typed: the terms the reader used
 * last, one tap from searching again, and one way to forget them all. The host owns the list (it is
 * per signed-in user and lives in the host's storage; `flareRememberSearch` is the rule for keeping
 * it); this draws it and reports `pick` and `clear`. With no items it draws nothing, so the page's
 * idle line shows instead.
 *
 * The terms are rows, not capsules: on a search page they sit right under the type row, which already
 * is a row of tinted capsules, and a second row that looks the same but means something else (history,
 * not a filter) cannot be told apart from it. A row is also its own hit area — no pseudo-element to be
 * clipped by the ellipsis' `overflow`.
 *
 * Inside a page-layout `FlareSearchPanel` it takes the panel's gutter (`--flare-search-gutter`).
 */
const props = withDefaults(defineProps<{
  items: readonly string[];
  /** Section heading. Default: the kit's "最近搜索". */
  title?: string;
  /** The clear key's words. Default: the kit's "清除". */
  clearText?: string;
}>(), { title: undefined, clearText: undefined });
const emit = defineEmits<{ (e: "pick", term: string): void; (e: "clear"): void }>();

const { t } = useFlareI18nOptional();
const titleId = `flare-recent-searches-${useId()}`;
const strings = computed(() => ({
  title: props.title ?? t("recentSearches.title"),
  clear: props.clearText ?? t("recentSearches.clear"),
  clearLabel: t("recentSearches.clearLabel"),
}));
</script>

<template>
  <section v-if="items.length" class="flare-recent-searches" :aria-labelledby="titleId">
    <header class="flare-recent-searches__head">
      <h3 :id="titleId" class="flare-recent-searches__title">{{ strings.title }}</h3>
      <FlareButton variant="quiet" size="sm" :aria-label="strings.clearLabel" @click="emit('clear')">{{ strings.clear }}</FlareButton>
    </header>
    <ul class="flare-recent-searches__list" role="list">
      <li v-for="(term, index) in items" :key="`${index}:${term}`">
        <button type="button" class="flare-recent-searches__term" @click="emit('pick', term)">
          <FlareIcon class="flare-recent-searches__icon" name="clock" :size="16" aria-hidden="true" />
          <span class="flare-recent-searches__text">{{ term }}</span>
        </button>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.flare-recent-searches { min-width: 0; }
.flare-recent-searches__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-control-height-sm);
  padding-inline: var(--flare-search-gutter, 0);
}
/* The same rung as a result group's label: a caption over a list, not a page title. */
.flare-recent-searches__title {
  margin: 0;
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-semibold);
}
.flare-recent-searches__list { margin: 0; padding: 0; list-style: none; }
/* What is drawn is what is hit: a full-width row a touch target tall. */
.flare-recent-searches__term {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: 0 var(--flare-search-gutter, 0);
  border: 0;
  color: var(--flare-color-text-primary);
  background: transparent;
  font: inherit;
  font-size: var(--flare-size-font-size-lg);
  text-align: start;
  cursor: pointer;
}
.flare-recent-searches__icon { flex: none; color: var(--flare-color-text-tertiary); }
/* The ellipsis lives on the words, not on the button. */
.flare-recent-searches__text { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
@media (hover: hover) {
  .flare-recent-searches__term:hover { background: var(--flare-color-bg-hover); }
}
.flare-recent-searches__term:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
</style>
