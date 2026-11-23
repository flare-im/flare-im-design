<script setup lang="ts">
import { computed, ref } from "vue";
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
  (e: "focusSearch"): void;
}>();

const { t } = useFlareI18n();
const isEmpty = computed(() => props.groups.every((g) => g.items.length === 0));
const root = ref<HTMLElement | null>(null);
function resultButtons(): HTMLButtonElement[] {
  return Array.from(root.value?.querySelectorAll<HTMLButtonElement>('.flare-search-row, .flare-search-more') ?? [])
    .filter(button => !button.disabled && button.closest<HTMLElement>('.flare-search-group')?.style.display !== 'none');
}
function focusResult(edge: 'first' | 'last'): boolean {
  const buttons = resultButtons();
  const button = edge === 'first' ? buttons[0] : buttons.at(-1);
  if (!button) return false;
  button.focus({ preventScroll: true });
  button.scrollIntoView?.({ block: 'nearest', inline: 'nearest' });
  return true;
}
defineExpose({ focusResult });

function onKeydown(event: KeyboardEvent): void {
  if (event.defaultPrevented || event.isComposing || event.keyCode === 229
    || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
  const buttons = resultButtons();
  const current = buttons.indexOf(event.target as HTMLButtonElement);
  if (current < 0) return;
  if (event.key === 'ArrowUp' && current === 0) {
    event.preventDefault();
    emit('focusSearch');
    return;
  }
  let index: number;
  if (event.key === 'ArrowDown') index = Math.min(current + 1, buttons.length - 1);
  else if (event.key === 'ArrowUp') index = Math.max(current - 1, 0);
  else if (event.key === 'Home') index = 0;
  else if (event.key === 'End') index = buttons.length - 1;
  else return;
  event.preventDefault();
  buttons[index]?.focus({ preventScroll: true });
  buttons[index]?.scrollIntoView?.({ block: 'nearest', inline: 'nearest' });
}

/** Keep the first match visible even near the end of a long message. Use code points so
 * emoji are not cut in half; the accessible name and tooltip retain the original text. */
function excerpt(text: string): string {
  const query = props.query.trim();
  const literal = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = query ? new RegExp(literal, 'iu').exec(text) : null;
  const chars = Array.from(text);
  if (!match || chars.length <= 128) return text;
  const at = Array.from(text.slice(0, match.index)).length;
  const start = Math.max(0, at - 24);
  const end = Math.max(start + 128, at + Array.from(match[0]).length + 24);
  return `${start ? '…' : ''}${chars.slice(start, end).join('')}${end < chars.length ? '…' : ''}`;
}

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
  <div ref="root" class="flare-search-results" @keydown="onKeydown">
    <template v-if="!isEmpty">
      <section v-for="group in groups" v-show="group.items.length" :key="group.kind" class="flare-search-group">
        <div class="flare-search-group__label">{{ group.label }}</div>
        <button
          v-for="item in group.items"
          :key="`${item.kind}:${item.id}`"
          type="button"
          class="flare-search-row"
          :class="{ 'flare-search-row--message': item.kind === 'message' }"
          :aria-label="[item.title, item.subtitle, item.meta].filter(Boolean).join(', ')"
          :title="item.subtitle || item.title"
          @click="emit('open', item)"
        >
          <FlareAvatar aria-hidden="true" :user-id="item.id" :display-name="item.title" :avatar-url="item.avatarUrl" :size="38" />
          <span class="flare-search-row__body">
            <span class="flare-search-row__title">
              <span v-for="(seg, i) in segments(item.title)" :key="i" :class="{ hit: seg.hit }">{{ seg.text }}</span>
            </span>
            <span v-if="item.subtitle" class="flare-search-row__sub">
              <span v-for="(seg, i) in segments(item.kind === 'message' ? excerpt(item.subtitle) : item.subtitle)" :key="i" :class="{ hit: seg.hit }">{{ seg.text }}</span>
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
  box-sizing: border-box;
  width: 100%;
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target-min, 44px);
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
.flare-search-row:focus-visible,
.flare-search-more:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
  background: var(--flare-color-bg-hover);
}
.flare-search-row--message { align-items: flex-start; }
.flare-search-row--message .flare-search-row__sub {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  white-space: normal;
  overflow-wrap: anywhere;
  line-height: var(--flare-size-line-height-normal, 1.5);
  color: var(--flare-color-text-secondary);
}
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
  min-height: var(--flare-size-layout-touch-target-min, 44px);
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
