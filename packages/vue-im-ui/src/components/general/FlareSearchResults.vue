<script setup lang="ts">
import { computed } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "./FlareEmptyState.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareSearchResultGroup, FlareSearchResultItem } from "../../shared/contracts";

const props = defineProps<{
  groups: FlareSearchResultGroup[];
  /** The active query — matched runs are highlighted in titles / subtitles. */
  query: string;
}>();
const emit = defineEmits<{
  (e: "open", item: FlareSearchResultItem): void;
  (e: "viewAll", kind: FlareSearchResultGroup["kind"]): void;
}>();

const { t } = useFlareI18n();
const isEmpty = computed(() => props.groups.every((g) => g.items.length === 0));

/** Split `text` into plain/highlighted runs around case-insensitive `query`. */
function segments(text: string): { text: string; hit: boolean }[] {
  const q = props.query.trim();
  if (!q) return [{ text, hit: false }];
  const out: { text: string; hit: boolean }[] = [];
  const literal = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  let i = 0;
  for (const match of text.matchAll(new RegExp(literal, 'giu'))) {
    const at = match.index!;
    if (at > i) out.push({ text: text.slice(i, at), hit: false });
    out.push({ text: match[0], hit: true });
    i = at + match[0].length;
  }
  if (i < text.length) out.push({ text: text.slice(i), hit: false });
  return out;
}
</script>

<template>
  <div class="flare-search-results">
    <template v-if="!isEmpty">
      <section v-for="group in groups" v-show="group.items.length" :key="group.kind" class="flare-search-group">
        <div class="flare-search-group__label">{{ group.label }}</div>
        <button
          v-for="item in group.items"
          :key="`${item.kind}:${item.id}`"
          type="button"
          class="flare-search-row"
          @click="emit('open', item)"
        >
          <FlareAvatar :user-id="item.id" :display-name="item.title" :avatar-url="item.avatarUrl" :size="38" />
          <span class="flare-search-row__body">
            <span class="flare-search-row__title">
              <span v-for="(seg, i) in segments(item.title)" :key="i" :class="{ hit: seg.hit }">{{ seg.text }}</span>
            </span>
            <span v-if="item.subtitle" class="flare-search-row__sub">
              <span v-for="(seg, i) in segments(item.subtitle)" :key="i" :class="{ hit: seg.hit }">{{ seg.text }}</span>
            </span>
          </span>
          <span v-if="item.meta" class="flare-search-row__meta">{{ item.meta }}</span>
        </button>
        <button
          v-if="(group.total && group.total > group.items.length) || group.hasMore"
          type="button"
          class="flare-search-more"
          @click="emit('viewAll', group.kind)"
        >
          {{ group.total && group.total > group.items.length ? t("search.viewAll", { count: group.total }) : t("search.viewMore") }}
        </button>
      </section>
    </template>
    <FlareEmptyState v-else :title="t('search.empty')" :description="t('search.emptyHint')" icon="search" />
  </div>
</template>

<style scoped>
.flare-search-results {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.flare-search-group { padding: 4px 0; }
/* `--flare-search-gutter`: a panel that is the page sets it, so labels, rows and the more row share the
   page's edge; anywhere else they keep their own. */
.flare-search-group__label {
  padding: 6px var(--flare-search-gutter, 12px);
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-text-tertiary);
}
.flare-search-row {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px var(--flare-search-gutter, 12px);
  border: none;
  background: transparent;
  cursor: pointer;
  text-align: left;
  transition: background var(--flare-transition-fast);
}
.flare-search-row:hover { background: var(--flare-color-bg-secondary); }
.flare-search-row__body {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.flare-search-row__title {
  font-size: 14px;
  color: var(--flare-color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-search-row__sub {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-search-row__title .hit,
.flare-search-row__sub .hit {
  color: var(--flare-color-primary-text);
  font-weight: 600;
}
.flare-search-row__meta {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  flex: 0 0 auto;
}
.flare-search-more {
  width: 100%;
  padding: 8px var(--flare-search-gutter, 12px);
  border: none;
  background: transparent;
  color: var(--flare-color-primary-text);
  font-size: 13px;
  text-align: left;
  cursor: pointer;
}
.flare-search-more:hover { text-decoration: underline; }
</style>
