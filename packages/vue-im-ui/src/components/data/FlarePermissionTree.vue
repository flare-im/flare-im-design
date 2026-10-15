<script setup lang="ts">
/**
 * A host-owned permission tree. Default leaves mode derives tri-state parent groups from leaves.
 * Independent mode treats every code, including a parent, as a separate explicit permission;
 * changing a node never changes its ancestors or descendants.
 *
 * It is a WAI-ARIA tree: one focusable item at a time, arrow keys walk and fold it, Space and
 * Enter toggle. The item itself carries the checked state, so the box beside the name is drawn
 * by the item (a second focusable checkbox inside a tree item would be two controls for one thing).
 * The flat list is derived once per change of the data, the search or the fold state — a tree
 * of a thousand nodes costs one pass, not one pass per node.
 */
import { computed, nextTick, ref, watch, type ComponentPublicInstance } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareSearchBar from "../general/FlareSearchBar.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  flattenPermissionNodes,
  permissionTreeRows,
  permissionTreeSearch,
  permissionTreeStates,
  permissionTreeToggle,
  type FlarePermissionCheckState,
  type FlarePermissionNode,
  type FlarePermissionSelectionMode,
  type FlarePermissionTreeEntry,
} from "./permission-tree";

const props = withDefaults(
  defineProps<{
    /** The permission catalogue, nested. */
    nodes: readonly FlarePermissionNode[];
    /** Explicit codes, including parents, are independent; no implicit ancestor/descendant grant. */
    selectionMode?: FlarePermissionSelectionMode;
    /** Accessible name of the tree. Default: the kit's "Permissions". */
    label?: string;
    /** Show the state and ignore every toggle. */
    readonly?: boolean;
    /** Codes that cannot be changed; a grouped leaves-mode toggle leaves them as they are. */
    disabledCodes?: readonly string[];
    /** Draw the search field above the tree. Default true. */
    searchable?: boolean;
    /** Placeholder of the search field. Default: the kit's "Search permissions". */
    searchPlaceholder?: string;
    /** Start with every group open. Default true. */
    defaultExpanded?: boolean;
    /** Shown when the search matches nothing. Default: the kit's "No matching permissions". */
    emptyText?: string;
  }>(),
  {
    label: undefined,
    selectionMode: "leaves",
    readonly: false,
    disabledCodes: () => [],
    searchable: true,
    searchPlaceholder: undefined,
    defaultExpanded: true,
    emptyText: undefined,
  },
);
/** Host-owned explicit codes; leaves mode derives parent groups, independent mode stores parents too. */
const checkedCodes = defineModel<string[]>("checkedCodes", { default: () => [] });

const { t } = useFlareI18nOptional();
const treeLabel = computed(() => props.label ?? t("permissionTree.label"));

const entries = computed(() => flattenPermissionNodes(props.nodes));
const byCode = computed(() => new Map(entries.value.map((entry) => [entry.code, entry])));
const groupCodes = computed(() => entries.value.filter((entry) => !entry.isLeaf).map((entry) => entry.code));
const checkedSet = computed(() => new Set(checkedCodes.value));
const disabledSet = computed(() => new Set(props.disabledCodes));
const states = computed(() => permissionTreeStates(entries.value, checkedSet.value, props.selectionMode));
const countable = computed(() => entries.value.filter((entry) => props.selectionMode === "independent" || entry.isLeaf));
const leafTotal = computed(() => countable.value.length);
const leafChecked = computed(() => countable.value.filter((entry) => checkedSet.value.has(entry.code)).length);

const query = ref("");
const search = computed(() => permissionTreeSearch(entries.value, byCode.value, query.value));

const expanded = ref<ReadonlySet<string>>(new Set());
// New data starts folded the way the host asked; a code that was open stays open across updates.
watch(groupCodes, (codes, previous) => {
  if (!previous) {
    expanded.value = new Set(props.defaultExpanded ? codes : []);
    return;
  }
  const known = new Set(previous);
  const next = new Set([...expanded.value].filter((code) => codes.includes(code)));
  if (props.defaultExpanded) for (const code of codes) if (!known.has(code)) next.add(code);
  expanded.value = next;
}, { immediate: true });

const rows = computed(() => permissionTreeRows(entries.value, expanded.value, search.value));

function stateOf(entry: FlarePermissionTreeEntry): FlarePermissionCheckState {
  return states.value.get(entry.code) ?? "none";
}
function ariaChecked(entry: FlarePermissionTreeEntry): "true" | "false" | "mixed" {
  const state = stateOf(entry);
  return state === "checked" ? "true" : state === "indeterminate" ? "mixed" : "false";
}
function isOpen(entry: FlarePermissionTreeEntry): boolean {
  return !entry.isLeaf && (expanded.value.has(entry.code) || search.value.open.has(entry.code));
}
function isDisabled(entry: FlarePermissionTreeEntry): boolean {
  return props.selectionMode === "independent" || entry.isLeaf ? disabledSet.value.has(entry.code) : entry.leafCodes.every((code) => disabledSet.value.has(code));
}

function toggleCheck(entry: FlarePermissionTreeEntry): void {
  if (props.readonly || isDisabled(entry)) return;
  checkedCodes.value = permissionTreeToggle(entry, checkedCodes.value, disabledSet.value, props.selectionMode);
}
function setOpen(entry: FlarePermissionTreeEntry, open: boolean): void {
  if (entry.isLeaf) return;
  const next = new Set(expanded.value);
  if (open) next.add(entry.code);
  else next.delete(entry.code);
  expanded.value = next;
}
function expandAll(): void {
  expanded.value = new Set(groupCodes.value);
}
function collapseAll(): void {
  expanded.value = new Set();
}

// ── Keyboard: one tab stop, arrows walk the visible rows ───────────────────────
const active = ref<string | null>(null);
const activeCode = computed(() => (active.value && rows.value.some((row) => row.code === active.value) ? active.value : rows.value[0]?.code ?? null));
const items = new Map<string, HTMLElement>();
function register(code: string, el: Element | ComponentPublicInstance | null): void {
  if (el instanceof HTMLElement) items.set(code, el);
  else items.delete(code);
}
function focusCode(code: string | null | undefined): void {
  if (!code) return;
  active.value = code;
  void nextTick(() => items.get(code)?.focus({ preventScroll: false }));
}
function onKeydown(event: KeyboardEvent, entry: FlarePermissionTreeEntry): void {
  const index = rows.value.findIndex((row) => row.code === entry.code);
  switch (event.key) {
    case "ArrowDown":
      focusCode(rows.value[index + 1]?.code);
      break;
    case "ArrowUp":
      focusCode(rows.value[index - 1]?.code);
      break;
    case "Home":
      focusCode(rows.value[0]?.code);
      break;
    case "End":
      focusCode(rows.value[rows.value.length - 1]?.code);
      break;
    case "ArrowRight":
      if (entry.isLeaf) return;
      if (isOpen(entry)) focusCode(rows.value[index + 1]?.code);
      else setOpen(entry, true);
      break;
    case "ArrowLeft":
      if (isOpen(entry) && expanded.value.has(entry.code)) setOpen(entry, false);
      else focusCode(entry.parent);
      break;
    case " ":
    case "Enter":
      toggleCheck(entry);
      break;
    default:
      return;
  }
  event.preventDefault();
}
</script>

<template>
  <div class="flare-permission-tree" :class="{ 'is-readonly': readonly }">
    <div class="flare-permission-tree__bar">
      <FlareSearchBar
        v-if="searchable"
        v-model="query"
        class="flare-permission-tree__search"
        :placeholder="searchPlaceholder ?? t('permissionTree.searchPlaceholder')"
        :debounce="0"
      />
      <div class="flare-permission-tree__tools">
        <span class="flare-permission-tree__summary" aria-live="polite">{{ t("permissionTree.summary", { checked: leafChecked, total: leafTotal }) }}</span>
        <span v-if="readonly" class="flare-permission-tree__hint">
          <FlareIcon name="lock" :size="14" />
          <span>{{ t("permissionTree.readOnlyHint") }}</span>
        </span>
        <FlareButton variant="quiet" size="sm" :label="t('permissionTree.expandAll')" :disabled="groupCodes.length === 0" @click="expandAll" />
        <FlareButton variant="quiet" size="sm" :label="t('permissionTree.collapseAll')" :disabled="groupCodes.length === 0" @click="collapseAll" />
      </div>
    </div>

    <ul v-if="rows.length" class="flare-permission-tree__list" role="tree" :aria-label="treeLabel">
      <li
        v-for="entry in rows"
        :key="entry.code"
        :ref="(el) => register(entry.code, el)"
        class="flare-permission-tree__item"
        :class="{
          'is-leaf': entry.isLeaf,
          'is-matched': search.matched.has(entry.code),
          'is-disabled': isDisabled(entry),
          [`is-${stateOf(entry)}`]: true,
        }"
        :style="{ '--flare-permission-tree-depth': entry.depth }"
        role="treeitem"
        :data-code="entry.code"
        :aria-level="entry.depth + 1"
        :aria-posinset="entry.posInSet"
        :aria-setsize="entry.setSize"
        :aria-expanded="entry.isLeaf ? undefined : isOpen(entry)"
        :aria-checked="ariaChecked(entry)"
        :aria-disabled="readonly || isDisabled(entry) || undefined"
        :tabindex="entry.code === activeCode ? 0 : -1"
        @focus="active = entry.code"
        @keydown="onKeydown($event, entry)"
        @click="toggleCheck(entry)"
      >
        <span
          v-if="!entry.isLeaf"
          class="flare-permission-tree__fold"
          aria-hidden="true"
          @click.stop="setOpen(entry, !isOpen(entry))"
        >
          <FlareIcon :name="isOpen(entry) ? 'chevron-down' : 'chevron-right'" :size="16" />
        </span>
        <span v-else class="flare-permission-tree__fold flare-permission-tree__fold--leaf" aria-hidden="true"></span>
        <span class="flare-permission-tree__box" aria-hidden="true">
          <FlareIcon v-if="stateOf(entry) === 'indeterminate'" name="remove" :size="13" />
          <FlareIcon v-else-if="stateOf(entry) === 'checked'" name="check" :size="13" />
        </span>
        <slot
          name="node"
          :node="entry.node"
          :depth="entry.depth"
          :state="stateOf(entry)"
          :expanded="isOpen(entry)"
          :matched="search.matched.has(entry.code)"
          :disabled="isDisabled(entry)"
        >
          <span class="flare-permission-tree__text">
            <span class="flare-permission-tree__name">{{ entry.node.name }}</span>
            <span v-if="entry.node.description" class="flare-permission-tree__desc">{{ entry.node.description }}</span>
          </span>
        </slot>
      </li>
    </ul>
    <slot v-else name="empty">
      <FlareEmptyState :title="emptyText ?? t('permissionTree.empty')" icon="search" />
    </slot>
  </div>
</template>

<style scoped>
.flare-permission-tree {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  color: var(--flare-color-text-primary);
}
.flare-permission-tree__bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
.flare-permission-tree__search {
  flex: 1 1 240px;
  min-width: 0;
}
.flare-permission-tree__tools {
  display: inline-flex;
  flex: none;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  margin-inline-start: auto;
}
.flare-permission-tree__summary {
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  font-variant-numeric: tabular-nums;
}
.flare-permission-tree__hint {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-caption-font-size);
}
.flare-permission-tree__list {
  margin: 0;
  padding: 0;
  list-style: none;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
}
.flare-permission-tree__item {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-component-permission-tree-row-height);
  padding-block: var(--flare-size-spacing-3xs);
  padding-inline: calc(var(--flare-size-spacing-sm) + var(--flare-permission-tree-depth) * var(--flare-size-spacing-xl)) var(--flare-size-spacing-md);
  cursor: pointer;
  user-select: none;
}
.flare-permission-tree__item:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
  border-radius: var(--flare-size-radius-sm);
}
.flare-permission-tree__item.is-disabled { cursor: not-allowed; }
.flare-permission-tree__item.is-disabled .flare-permission-tree__text { opacity: var(--flare-opacity-muted); }
.is-readonly .flare-permission-tree__item { cursor: default; }
@media (hover: hover) {
  .flare-permission-tree__item:not(.is-disabled):hover { background: var(--flare-color-bg-hover); }
  .is-readonly .flare-permission-tree__item:hover { background: transparent; }
}
@media (pointer: coarse) {
  .flare-permission-tree__item { min-height: var(--flare-size-layout-touch-target-min); }
}
.flare-permission-tree__fold {
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-icon-size-lg);
  height: var(--flare-size-icon-size-lg);
  border-radius: var(--flare-size-radius-sm);
  color: var(--flare-color-text-secondary);
}
@media (hover: hover) {
  .flare-permission-tree__fold:not(.flare-permission-tree__fold--leaf):hover { background: var(--flare-color-bg-selected); color: var(--flare-color-text-primary); }
}
/* The box is the item's own check mark: the same geometry and tokens as Checkbox, without a second control. */
.flare-permission-tree__box {
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-icon-size-md);
  height: var(--flare-size-icon-size-md);
  border: 1.5px solid var(--flare-color-border-hover);
  border-radius: var(--flare-size-radius-sm);
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-bg-primary);
  transition: background var(--flare-transition-fast), border-color var(--flare-transition-fast);
}
.is-checked .flare-permission-tree__box,
.is-indeterminate .flare-permission-tree__box {
  border-color: var(--flare-color-primary);
  background: var(--flare-color-primary);
}
.flare-permission-tree__text {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: var(--flare-size-spacing-3xs) var(--flare-size-spacing-sm);
  min-width: 0;
  font-size: var(--flare-text-body-font-size);
  line-height: var(--flare-text-body-line-height);
}
.flare-permission-tree__name { overflow-wrap: anywhere; }
.is-leaf .flare-permission-tree__name { font-weight: var(--flare-size-font-weight-regular); }
.flare-permission-tree__item:not(.is-leaf) .flare-permission-tree__name { font-weight: var(--flare-size-font-weight-medium); }
.is-matched .flare-permission-tree__name { color: var(--flare-color-primary-text); }
.flare-permission-tree__desc {
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-caption-font-size);
  overflow-wrap: anywhere;
}
@media (prefers-reduced-motion: reduce) {
  .flare-permission-tree__box { transition: none; }
}
</style>
