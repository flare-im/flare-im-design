<script setup lang="ts">
import { computed, ref, watch, type Component } from "vue";
import FlareGlyph from "../general/FlareGlyph.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareIcons } from "../../shared/icons";
import {
  FLARE_COMPOSER_ACTION_ICONS,
  FLARE_DEFAULT_COMPOSER_ACTION_IDS,
  labelComposerActions,
  resolveComposerActionIcon,
  resolveComposerActions,
  type FlareComposerAction,
  type FlareComposerCapabilities,
} from "../../shared/contracts/composer";
/** `icon` is a semantic glyph name (shared with the native kits) or, for Vue hosts, any icon component. */
export type FlareComposerActionItem = FlareComposerAction<string | Component> & { tone?: string };
/** `mobile` pages the grid sideways; `desktop` shows at most `rows` rows and scrolls the rest. */
export type FlareComposerPanelFormFactor = "mobile" | "desktop";

/**
 * The composer's attachment / feature grid (下方功能区). The host either passes
 * its own `actions` (unified `id` table shared with the native kits) or keeps
 * the built-in default set. A unified id without a label is labelled from the
 * strings provider, so built-in items of a composer menu pass through as they
 * come; an icon that is not a registry name draws the generic `plugin` glyph
 * (`resolveComposerActionIcon`). Each tap emits `action(action)`. A composable part: reveal it
 * under the input, or present it in a sheet — this is the one grid; the message
 * long-press sheet is MessageActionSheet.
 *
 * Items are ordered by `order`, then by position. On a phone the grid pages sideways,
 * `rows` × `columns` per page, with page dots; on a desktop it shows at most `rows` rows
 * and scrolls inside the panel. A new list is diffed by id: the page stays where it was,
 * tiles that remain move to their new place, new ones fade in (150 ms) and removed ones go at once.
 */
const props = withDefaults(
  defineProps<{
    actions?: FlareComposerActionItem[];
    capabilities?: FlareComposerCapabilities;
    columns?: number;
    formFactor?: FlareComposerPanelFormFactor;
    /** Rows per page on a phone (default 2), most rows shown on a desktop (default 3). */
    rows?: number;
  }>(),
  { actions: undefined, capabilities: undefined, columns: 4, formFactor: "mobile", rows: undefined },
);
const emit = defineEmits<{ (e: "action", action: FlareComposerActionItem): void }>();
const { t } = useFlareI18nOptional();

const defaults: FlareComposerActionItem[] = FLARE_DEFAULT_COMPOSER_ACTION_IDS.map((id) => ({
  id, icon: FLARE_COMPOSER_ACTION_ICONS[id], kind: "feature",
}));
const isIconName = (name: string): boolean => Object.prototype.hasOwnProperty.call(flareIcons, name);
function glyphFor(action: FlareComposerActionItem): string {
  return resolveComposerActionIcon(action, isIconName);
}
const resolvedActions = computed(() => labelComposerActions<FlareComposerActionItem>(resolveComposerActions<string | Component>({
  defaults,
  actions: props.actions,
  capabilities: props.capabilities,
}), t));

const paged = computed(() => props.formFactor === "mobile");
const rowCount = computed(() => Math.max(1, props.rows ?? (paged.value ? 2 : 3)));
const pages = computed(() => {
  if (!paged.value) return [resolvedActions.value];
  const size = rowCount.value * props.columns;
  const out: FlareComposerActionItem[][] = [];
  for (let start = 0; start < resolvedActions.value.length; start += size) {
    out.push(resolvedActions.value.slice(start, start + size));
  }
  return out;
});

// The scroller owns the position (swipe, a focused tile scrolled into view, a dot); the
// page only mirrors it. A shorter list clamps instead of jumping back to the first page.
const scroller = ref<HTMLElement | null>(null);
const page = ref(0);
watch(() => pages.value.length, (count) => {
  if (page.value > count - 1) page.value = Math.max(0, count - 1);
});
function onScroll(): void {
  const el = scroller.value;
  if (!el || el.clientWidth === 0) return;
  page.value = Math.min(pages.value.length - 1, Math.round(el.scrollLeft / el.clientWidth));
}
function goTo(index: number): void {
  page.value = index;
  const el = scroller.value;
  if (!el) return;
  const reduce = typeof window !== "undefined" && window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
  el.scrollTo?.({ left: index * el.clientWidth, behavior: reduce ? "auto" : "smooth" });
}

function select(action: FlareComposerActionItem): void {
  if (action.enabled === false) return;
  emit("action", action);
}
</script>

<template>
  <div
    class="flare-action-panel"
    role="group"
    :aria-label="t('composer.features')"
    :data-form-factor="formFactor"
    :style="{ '--flare-action-panel-columns': columns, '--flare-action-panel-rows': rowCount }"
  >
    <div
      ref="scroller"
      class="flare-action-panel__pages"
      @scroll.passive="onScroll"
    >
      <TransitionGroup
        v-for="(items, index) in pages"
        :key="index"
        tag="div"
        name="flare-action-panel"
        class="flare-action-panel__grid"
        :role="paged ? 'group' : undefined"
        :aria-label="paged && pages.length > 1 ? t('composer.page', { page: index + 1 }) : undefined"
      >
        <button
          v-for="a in items"
          :key="a.id"
          type="button"
          class="flare-action-panel__tile"
          :data-action-id="a.id"
          :data-tone="a.tone || undefined"
          :disabled="a.enabled === false"
          :title="a.disabledReason || a.label"
          :aria-label="a.accessibilityLabel || a.label"
          @click="select(a)"
        >
          <span class="flare-action-panel__ico">
            <component :is="a.icon" v-if="a.icon && typeof a.icon !== 'string'" />
            <FlareGlyph v-else :icon="glyphFor(a)" :size="24" />
          </span>
          <span class="flare-action-panel__label">{{ a.label }}</span>
          <span v-if="a.badge" class="flare-action-panel__badge">{{ a.badge }}</span>
          <small v-if="a.hint" class="flare-action-panel__hint">{{ a.hint }}</small>
        </button>
      </TransitionGroup>
    </div>
    <nav v-if="paged && pages.length > 1" class="flare-action-panel__dots">
      <button
        v-for="(_, index) in pages"
        :key="index"
        type="button"
        :aria-label="t('composer.page', { page: index + 1 })"
        :aria-current="page === index ? 'page' : undefined"
        @click="goTo(index)"
      ><span /></button>
    </nav>
  </div>
</template>

<style scoped>
.flare-action-panel {
  --flare-action-panel-gap: 16px;
  --flare-action-panel-row: 76px;
  padding: 16px;
  background: var(--flare-color-bg-primary);
}
.flare-action-panel__grid {
  display: grid;
  grid-template-columns: repeat(var(--flare-action-panel-columns), minmax(0, 1fr));
  grid-auto-rows: var(--flare-action-panel-row);
  gap: var(--flare-action-panel-gap);
}
/* Desktop: at most `rows` rows, the rest scrolls inside the panel. */
.flare-action-panel[data-form-factor="desktop"] .flare-action-panel__pages {
  max-height: calc(var(--flare-action-panel-rows) * var(--flare-action-panel-row) + (var(--flare-action-panel-rows) - 1) * var(--flare-action-panel-gap));
  overflow-y: auto;
  overscroll-behavior: contain;
}
/* Phone: one page per snap point; every page keeps the full height so the panel never jumps. */
.flare-action-panel[data-form-factor="mobile"] .flare-action-panel__pages {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  overscroll-behavior-x: contain;
  scrollbar-width: none;
}
.flare-action-panel[data-form-factor="mobile"] .flare-action-panel__pages::-webkit-scrollbar { display: none; }
.flare-action-panel[data-form-factor="mobile"] .flare-action-panel__grid {
  flex: 0 0 100%;
  grid-template-rows: repeat(var(--flare-action-panel-rows), var(--flare-action-panel-row));
  scroll-snap-align: start;
  scroll-snap-stop: always;
}
.flare-action-panel__tile {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  min-width: 0;
  min-height: 44px;
  border: none;
  background: none;
  cursor: pointer;
}
.flare-action-panel__tile:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.flare-action-panel__ico {
  width: 52px;
  height: 52px;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--flare-size-font-size-5xl);
}
.flare-action-panel__label {
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  color: var(--flare-color-text-secondary);
}
.flare-action-panel__ico :deep(svg) { width: 24px; height: 24px; }
.flare-action-panel__badge,
.flare-action-panel__hint { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); }
.flare-action-panel__tile:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-action-panel__dots { display: flex; justify-content: center; height: var(--flare-size-icon-size-lg); margin-top: var(--flare-size-spacing-xs); }
.flare-action-panel__dots button { width: 28px; height: var(--flare-size-icon-size-lg); padding: var(--flare-size-spacing-sm); border: 0; background: transparent; cursor: pointer; }
.flare-action-panel__dots span { display: block; width: 5px; height: 5px; border-radius: var(--flare-size-radius-full, 999px); background: var(--flare-color-border-primary); transition: width 150ms ease; }
.flare-action-panel__dots [aria-current] span { width: 12px; background: var(--flare-color-primary); }
.flare-action-panel__dots button:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
/* Diff by id: tiles that stay move, new ones fade in, removed ones leave at once. */
.flare-action-panel-move,
.flare-action-panel-enter-active { transition: transform 150ms ease, opacity 150ms ease; }
.flare-action-panel-enter-from { opacity: 0; transform: scale(0.96); }
/* A tile's own transitions (hover colour) would keep a removed tile in place until they end. */
.flare-action-panel-leave-active { display: none; }
@media (prefers-reduced-motion: reduce) {
  .flare-action-panel-move,
  .flare-action-panel-enter-active,
  .flare-action-panel__dots span { transition: none; }
}
</style>
