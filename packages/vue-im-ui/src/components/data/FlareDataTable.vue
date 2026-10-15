<script setup lang="ts">
/**
 * A data table for web consoles: host-owned rows and columns in a real `<table>`, with sorting
 * the host performs (the table only says which column and which way), server-side pagination
 * (counted, or by cursor for a source that only knows whether there is a next page),
 * a tri-state selection that spans pages and surfaces a batch toolbar, and a column chooser
 * whose choice the host keeps. Nothing in here knows what the rows are.
 *
 * Narrow containers do not scroll sideways: each row stacks into labelled lines, the header
 * stays in the accessibility tree as plain titles, and sorting and select-all move into the bar
 * and the batch toolbar (a control inside a visually hidden header would be focusable but
 * invisible). The stacking is a container query; the controls follow the same width, measured
 * once the table is mounted. The roles are explicit on every table element because the stacked
 * form changes their `display`, and an engine drops a table's implicit semantics with it.
 */
import { computed, getCurrentInstance, nextTick, onBeforeUnmount, onMounted, ref, useId, useSlots } from "vue";
import { NPopover } from "naive-ui";
import FlareCheckbox from "../form/FlareCheckbox.vue";
import FlareSelect from "../form/FlareSelect.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import type { FlareActionItem } from "../../shared/contracts/action-menu";
import type { FlareSelectOption } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareIcons } from "../../shared/icons";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import { useFlareContextualLayer } from "../../shared/useContextualLayer";
import {
  dataTableAriaSort,
  dataTableCellText,
  dataTableIsCursor,
  dataTableNextSort,
  dataTablePageCount,
  dataTablePageSteps,
  dataTableRange,
  dataTableRowKey,
  dataTableSelection,
  dataTableToggleAll,
  dataTableToggleColumn,
  dataTableToggleRow,
  dataTableVisibleColumns,
  type FlareDataTableColumn,
  type FlareDataTablePagination,
  type FlareDataTableRow,
  type FlareDataTableSort,
} from "./data-table";

const props = withDefaults(
  defineProps<{
    /** Columns in display order. */
    columns: readonly FlareDataTableColumn[];
    /** The rows of this page, already sorted and paged by the host. */
    rows: readonly FlareDataTableRow[];
    /** Field that identifies a row, or a function of the row. Default `id`. */
    rowKey?: string | ((row: FlareDataTableRow, index: number) => string);
    /** Accessible name of the table. Default: the kit's "Table". */
    label?: string;
    /** Draw placeholder rows (aria-busy) while the host fetches the page. */
    loading?: boolean;
    /** Shown when there are no rows. Default: the kit's "No data yet". */
    emptyText?: string;
    /**
     * Server-side pagination; the table emits the next page or page size and the host fetches. Without
     * `total` it is cursor paging: the page number alone, and `hasNext` enables the next key.
     */
    pagination?: FlareDataTablePagination | null;
    /** The current sort; the table emits the next one and the host sorts. */
    sort?: FlareDataTableSort | null;
    /** A checkbox per row and in the header; the selection is `selectedKeys`. */
    selectable?: boolean;
    /** A control that shows or hides columns; the choice is `visibleColumns`. */
    columnChooser?: boolean;
    /** Pin the header inside the table's own scroll box (`--flare-component-data-table-max-height`). */
    stickyHeader?: boolean;
    /** Row height: `comfortable` for reading, `compact` for scanning. */
    density?: "comfortable" | "compact";
  }>(),
  {
    rowKey: "id",
    label: undefined,
    loading: false,
    emptyText: undefined,
    pagination: null,
    sort: null,
    selectable: false,
    columnChooser: false,
    stickyHeader: false,
    density: "comfortable",
  },
);
/** Keys of the selected rows, across pages. */
const selectedKeys = defineModel<string[]>("selectedKeys", { default: () => [] });
/** Keys of the columns the chooser shows; `null` shows every column. The host persists it. */
const visibleColumns = defineModel<string[] | null>("visibleColumns", { default: null });
const emit = defineEmits<{
  (e: "rowClick", row: FlareDataTableRow, index: number): void;
  (e: "update:pagination", pagination: FlareDataTablePagination): void;
  (e: "update:sort", sort: FlareDataTableSort | null): void;
}>();

const { t } = useFlareI18nOptional();
const slots = useSlots();
const instance = getCurrentInstance();
const platform = useFlarePlatformSafe();
const uid = useId();

const tableLabel = computed(() => props.label ?? t("dataTable.label"));
const shownColumns = computed(() => dataTableVisibleColumns(props.columns, visibleColumns.value));
const hasRowActions = computed(() => Boolean(slots["row-actions"]));
/** Rows are activatable only for a host that listens; otherwise they are plain rows. */
const interactive = computed(() => Boolean(instance?.vnode.props?.onRowClick));
const keys = computed(() => props.rows.map((row, index) => dataTableRowKey(row, props.rowKey, index)));
const selectedSet = computed(() => new Set(selectedKeys.value));
const selection = computed(() => dataTableSelection(keys.value, selectedKeys.value));
const selectedRows = computed(() => props.rows.filter((_, index) => selectedSet.value.has(keys.value[index])));
const selecting = computed(() => props.selectable && selectedKeys.value.length > 0);
const columnCount = computed(() => shownColumns.value.length + (props.selectable ? 1 : 0) + (hasRowActions.value ? 1 : 0));
const sortableColumns = computed(() => props.columns.filter((column) => column.sortable));
const hasToolbar = computed(() => Boolean(slots.toolbar));

// The stacked form (see the container query below) starts under this width; the header's controls
// leave with it, so the measurement and the query must agree.
const NARROW_MAX_WIDTH = 599;
const root = ref<HTMLElement | null>(null);
const narrow = ref(false);
let observer: ResizeObserver | null = null;
onMounted(() => {
  if (!root.value || typeof ResizeObserver === "undefined") return;
  observer = new ResizeObserver((entries) => {
    const width = entries[0]?.contentRect.width ?? 0;
    narrow.value = width > 0 && width <= NARROW_MAX_WIDTH;
  });
  observer.observe(root.value);
});
onBeforeUnmount(() => observer?.disconnect());

const showSortMenu = computed(() => narrow.value && sortableColumns.value.length > 0);
const showBar = computed(() => hasToolbar.value || props.columnChooser || showSortMenu.value);

function cellSlot(column: FlareDataTableColumn): string {
  return column.slot ?? `cell-${column.key}`;
}
function columnStyle(column: FlareDataTableColumn): Record<string, string> {
  const style: Record<string, string> = {};
  if (column.width !== undefined) style.width = typeof column.width === "number" ? `${column.width}px` : column.width;
  if (column.minWidth !== undefined) style.minWidth = typeof column.minWidth === "number" ? `${column.minWidth}px` : column.minWidth;
  return style;
}
function cellTitle(column: FlareDataTableColumn, row: FlareDataTableRow): string | undefined {
  return column.ellipsis ? dataTableCellText(row[column.key]) || undefined : undefined;
}

// ── Sorting: the table reports, the host sorts ─────────────────────────────────
function toggleSort(column: FlareDataTableColumn): void {
  if (!column.sortable) return;
  emit("update:sort", dataTableNextSort(props.sort, column.key));
}
// On a narrow container the header is only in the accessibility tree, so sorting has a menu too.
const sortMenuItems = computed<FlareActionItem[]>(() => sortableColumns.value.map((column) => ({
  id: column.key,
  label: column.title,
  pressed: props.sort?.key === column.key,
  icon: props.sort?.key === column.key ? (props.sort.order === "asc" ? "chevron-up" : "chevron-down") : undefined,
})));
function sortFromMenu(key: string): void {
  const column = props.columns.find((entry) => entry.key === key);
  if (column) toggleSort(column);
}

// ── Selection and the batch toolbar ────────────────────────────────────────────
function toggleAll(): void {
  selectedKeys.value = dataTableToggleAll(keys.value, selectedKeys.value);
}
function setRow(key: string, on: boolean): void {
  selectedKeys.value = dataTableToggleRow(key, selectedKeys.value, on);
}
function clearSelection(): void {
  if (selectedKeys.value.length) selectedKeys.value = [];
}
const batchRoot = ref<HTMLElement | null>(null);
// A non-empty selection is a contextual layer: Escape, the platform back and the kit's back
// controls leave it, by the same rule as the message and conversation batch toolbars.
useFlareContextualLayer({ active: selecting, root: batchRoot, onDismiss: clearSelection });

// ── Pagination ─────────────────────────────────────────────────────────────────
const cursorPaging = computed(() => (props.pagination ? dataTableIsCursor(props.pagination) : false));
const pageCount = computed(() => (props.pagination ? dataTablePageCount(props.pagination) : 1));
const range = computed(() => (props.pagination ? dataTableRange(props.pagination, props.rows.length) : null));
const steps = computed(() => (props.pagination ? dataTablePageSteps(props.pagination) : { previous: false, next: false }));
/** Unknown to a cursor source: -1 says so (WAI-ARIA), rather than claiming this page is all there is. */
const rowCount = computed(() => {
  if (!props.pagination) return undefined;
  return cursorPaging.value ? -1 : props.pagination.total;
});
const rangeText = computed(() => {
  const pagination = props.pagination;
  const bounds = range.value;
  if (!pagination || !bounds) return "";
  if (cursorPaging.value) {
    if (bounds.to > 0) return t("dataTable.rangeOpen", { from: bounds.from, to: bounds.to });
    return pagination.page <= 1 && !pagination.hasNext ? t("dataTable.rangeEmpty") : "";
  }
  return (pagination.total ?? 0) > 0 ? t("dataTable.range", { from: bounds.from, to: bounds.to, total: pagination.total as number }) : t("dataTable.rangeEmpty");
});
const pageText = computed(() => {
  const pagination = props.pagination;
  if (!pagination) return "";
  if (cursorPaging.value) return t("dataTable.pageOnly", { page: Math.max(1, pagination.page) });
  return t("dataTable.pageOf", { page: Math.min(pagination.page, pageCount.value), pages: pageCount.value });
});
const pageSizeOptions = computed<FlareSelectOption[]>(() => (props.pagination?.pageSizes ?? []).map((size) => ({
  value: String(size),
  label: t("dataTable.perPage", { size }),
})));
function goTo(page: number): void {
  if (!props.pagination) return;
  const current = props.pagination.page;
  // A cursor source only knows the page after this one, so it moves one page at a time.
  if (page > current && !steps.value.next) return;
  if (page < current && !steps.value.previous) return;
  const next = cursorPaging.value ? Math.max(1, current + Math.sign(page - current)) : Math.min(Math.max(1, page), pageCount.value);
  if (next === current) return;
  emit("update:pagination", { ...props.pagination, page: next });
}
function setPageSize(value: string): void {
  const size = Number(value);
  if (!props.pagination || !size || size === props.pagination.pageSize) return;
  emit("update:pagination", { ...props.pagination, pageSize: size, page: 1 });
}

// ── Column chooser: a popover of checkboxes on pointer devices, a sheet on phones ──
const chooserOpen = ref(false);
const chooserId = `flare-data-table-columns-${uid}`;
const chooserTrigger = ref<HTMLElement | null>(null);
const chooserPanel = ref<HTMLElement | null>(null);
const chooserAsSheet = computed(() => platform.capabilities.value.bottomSheet);
function openChooser(): void {
  chooserOpen.value = true;
  void nextTick(() => chooserPanel.value?.querySelector<HTMLElement>('[role="checkbox"]:not(:disabled)')?.focus());
}
function closeChooser(restoreFocus: boolean): void {
  if (!chooserOpen.value) return;
  chooserOpen.value = false;
  if (restoreFocus) chooserTrigger.value?.querySelector<HTMLElement>("button")?.focus({ preventScroll: true });
}
function toggleChooser(): void {
  if (chooserOpen.value) closeChooser(true);
  else openChooser();
}
function onChooserClickOutside(event: MouseEvent): void {
  const target = event.target;
  if (target instanceof Node && chooserTrigger.value?.contains(target)) return;
  closeChooser(false);
}
function onChooserKeydown(event: KeyboardEvent): void {
  if (event.key !== "Escape") return;
  event.preventDefault();
  closeChooser(true);
}
function columnShown(key: string): boolean {
  return shownColumns.value.some((column) => column.key === key);
}
function chooserLocked(column: FlareDataTableColumn): boolean {
  return column.hideable === false || (columnShown(column.key) && shownColumns.value.length === 1);
}
function setColumn(key: string, on: boolean): void {
  visibleColumns.value = dataTableToggleColumn(props.columns, visibleColumns.value, key, on);
}

// ── Rows ───────────────────────────────────────────────────────────────────────
function onRowClick(row: FlareDataTableRow, index: number): void {
  if (interactive.value) emit("rowClick", row, index);
}
function onRowKeydown(event: KeyboardEvent, row: FlareDataTableRow, index: number): void {
  if (!interactive.value || event.target !== event.currentTarget) return;
  if (event.key !== "Enter" && event.key !== " ") return;
  event.preventDefault();
  emit("rowClick", row, index);
}
</script>

<template>
  <div
    ref="root"
    class="flare-data-table"
    :class="[`flare-data-table--${density}`, { 'is-sticky': stickyHeader, 'is-interactive': interactive, 'is-selecting': selecting, 'is-narrow': narrow }]"
    :aria-busy="loading || undefined"
  >
    <div v-if="showBar" class="flare-data-table__bar">
      <div class="flare-data-table__bar-lead"><slot name="toolbar" /></div>
      <div class="flare-data-table__bar-trail">
        <span v-if="showSortMenu" class="flare-data-table__sort-menu">
          <FlareActionMenu :items="sortMenuItems" :label="t('dataTable.sortBy')" placement="bottom-end" @select="sortFromMenu">
            <FlareIconButton :icon="flareIcons['arrow-down']" :ariaLabel="t('dataTable.sortBy')" size="sm" shape="square" />
          </FlareActionMenu>
        </span>
        <template v-if="columnChooser">
          <NPopover
            v-if="!chooserAsSheet"
            :show="chooserOpen"
            trigger="manual"
            raw
            :show-arrow="false"
            placement="bottom-end"
            class="flare-data-table__chooser-popover"
            @clickoutside="onChooserClickOutside"
          >
            <template #trigger>
              <span ref="chooserTrigger" class="flare-data-table__chooser-trigger">
                <FlareIconButton
                  :icon="flareIcons.settings"
                  :ariaLabel="t('dataTable.columns')"
                  size="sm"
                  shape="square"
                  aria-haspopup="dialog"
                  :aria-expanded="chooserOpen"
                  :aria-controls="chooserOpen ? chooserId : undefined"
                  @click="toggleChooser"
                />
              </span>
            </template>
            <div
              :id="chooserId"
              ref="chooserPanel"
              class="flare-data-table__chooser"
              role="dialog"
              :aria-label="t('dataTable.columns')"
              @keydown="onChooserKeydown"
            >
              <FlareCheckbox
                v-for="column in columns"
                :key="column.key"
                class="flare-data-table__chooser-row"
                :label="column.title"
                :model-value="columnShown(column.key)"
                :disabled="chooserLocked(column)"
                @update:model-value="(on) => setColumn(column.key, on)"
              />
            </div>
          </NPopover>
          <template v-else>
            <span ref="chooserTrigger" class="flare-data-table__chooser-trigger">
              <FlareIconButton
                :icon="flareIcons.settings"
                :ariaLabel="t('dataTable.columns')"
                size="sm"
                shape="square"
                aria-haspopup="dialog"
                :aria-expanded="chooserOpen"
                @click="toggleChooser"
              />
            </span>
            <FlareBottomSheet :open="chooserOpen" presentation="sheet" :title="t('dataTable.columns')" @close="closeChooser(true)">
              <div ref="chooserPanel" class="flare-data-table__chooser flare-data-table__chooser--sheet" role="group" :aria-label="t('dataTable.columns')">
                <FlareCheckbox
                  v-for="column in columns"
                  :key="column.key"
                  class="flare-data-table__chooser-row"
                  :label="column.title"
                  :model-value="columnShown(column.key)"
                  :disabled="chooserLocked(column)"
                  @update:model-value="(on) => setColumn(column.key, on)"
                />
              </div>
            </FlareBottomSheet>
          </template>
        </template>
      </div>
    </div>

    <div v-if="selecting" ref="batchRoot" class="flare-data-table__batch" role="toolbar" :aria-label="t('dataTable.batchTitle')">
      <span class="flare-data-table__batch-count" aria-live="polite" aria-atomic="true">{{ t("dataTable.selected", { count: selectedKeys.length }) }}</span>
      <div class="flare-data-table__batch-actions">
        <FlareButton
          v-if="selection !== 'all'"
          variant="quiet"
          size="sm"
          :label="t('dataTable.selectAll')"
          @click="toggleAll"
        />
        <FlareButton variant="quiet" size="sm" :label="t('dataTable.clearSelection')" @click="clearSelection" />
        <slot name="batch" :selected-keys="selectedKeys" :selected-rows="selectedRows" :clear="clearSelection" />
      </div>
      <FlareIconButton
        class="flare-data-table__batch-exit"
        :icon="flareIcons.close"
        :ariaLabel="t('dataTable.exitSelection')"
        aria-keyshortcuts="Escape"
        size="sm"
        @click="clearSelection"
      />
    </div>

    <div class="flare-data-table__scroll">
      <table class="flare-data-table__table" role="table" :aria-label="tableLabel" :aria-rowcount="rowCount">
        <thead role="rowgroup" class="flare-data-table__head">
          <tr role="row">
            <th v-if="selectable" role="columnheader" scope="col" class="flare-data-table__th flare-data-table__th--select">
              <FlareCheckbox
                v-if="!narrow"
                :model-value="selection === 'all'"
                :indeterminate="selection === 'some'"
                :ariaLabel="t('dataTable.selectAll')"
                :disabled="loading || rows.length === 0"
                @update:model-value="toggleAll"
              />
              <span v-else class="flare-data-table__title">{{ t("dataTable.selectColumn") }}</span>
            </th>
            <th
              v-for="column in shownColumns"
              :key="column.key"
              role="columnheader"
              scope="col"
              class="flare-data-table__th"
              :class="{ 'is-sortable': column.sortable, 'is-sorted': sort?.key === column.key }"
              :data-align="column.align ?? 'start'"
              :aria-sort="dataTableAriaSort(sort, column)"
              :style="columnStyle(column)"
            >
              <button v-if="column.sortable && !narrow" type="button" class="flare-data-table__sort" @click="toggleSort(column)">
                <span class="flare-data-table__title">{{ column.title }}</span>
                <FlareIcon class="flare-data-table__sort-icon" :name="sort?.key === column.key && sort.order === 'asc' ? 'chevron-up' : 'chevron-down'" :size="16" />
              </button>
              <span v-else class="flare-data-table__title">{{ column.title }}</span>
            </th>
            <th v-if="hasRowActions" role="columnheader" scope="col" class="flare-data-table__th flare-data-table__th--actions">
              <span class="flare-data-table__title">{{ t("dataTable.actions") }}</span>
            </th>
          </tr>
        </thead>
        <tbody role="rowgroup" class="flare-data-table__body">
          <tr v-if="loading" role="row" class="flare-data-table__state-row">
            <td role="cell" :colspan="columnCount" class="flare-data-table__state">
              <FlareSkeleton variant="text" :rows="4" />
              <span class="flare-data-table__spoken" role="status">{{ t("dataTable.loading") }}</span>
            </td>
          </tr>
          <tr v-else-if="rows.length === 0" role="row" class="flare-data-table__state-row">
            <td role="cell" :colspan="columnCount" class="flare-data-table__state">
              <slot name="empty"><FlareEmptyState :title="emptyText ?? t('dataTable.empty')" /></slot>
            </td>
          </tr>
          <template v-else>
          <tr
            v-for="(row, index) in rows"
            :key="keys[index]"
            role="row"
            class="flare-data-table__row"
            :class="{ 'is-selected': selectedSet.has(keys[index]) }"
            :aria-selected="selectable ? selectedSet.has(keys[index]) : undefined"
            :tabindex="interactive ? 0 : undefined"
            @click="onRowClick(row, index)"
            @keydown="onRowKeydown($event, row, index)"
          >
            <td v-if="selectable" role="cell" class="flare-data-table__td flare-data-table__td--select" @click.stop>
              <FlareCheckbox
                :model-value="selectedSet.has(keys[index])"
                :ariaLabel="t('dataTable.selectRow', { index: index + 1 })"
                @update:model-value="(on) => setRow(keys[index], on)"
              />
            </td>
            <td
              v-for="column in shownColumns"
              :key="column.key"
              role="cell"
              class="flare-data-table__td"
              :class="{ 'is-ellipsis': column.ellipsis }"
              :data-align="column.align ?? 'start'"
              :data-label="column.title"
              :title="cellTitle(column, row)"
            >
              <slot :name="cellSlot(column)" :row="row" :value="row[column.key]" :index="index" :column="column">{{ dataTableCellText(row[column.key]) }}</slot>
            </td>
            <td v-if="hasRowActions" role="cell" class="flare-data-table__td flare-data-table__td--actions" :data-label="t('dataTable.actions')" @click.stop @keydown.stop>
              <div class="flare-data-table__row-actions"><slot name="row-actions" :row="row" :index="index" /></div>
            </td>
          </tr>
          </template>
        </tbody>
      </table>
    </div>

    <nav v-if="pagination && range" class="flare-data-table__pagination" :aria-label="t('dataTable.pagination')">
      <span class="flare-data-table__range">
        {{ rangeText }}
      </span>
      <div class="flare-data-table__pager">
        <FlareSelect
          v-if="pageSizeOptions.length"
          class="flare-data-table__page-size"
          size="sm"
          :options="pageSizeOptions"
          :model-value="String(pagination.pageSize)"
          :title="t('dataTable.pageSize')"
          @update:model-value="setPageSize"
        />
        <FlareIconButton
          :icon="flareIcons['chevron-left']"
          :ariaLabel="t('dataTable.previous')"
          size="sm"
          shape="square"
          :disabled="loading || !steps.previous"
          @click="goTo(pagination.page - 1)"
        />
        <span class="flare-data-table__page" aria-live="polite">{{ pageText }}</span>
        <FlareIconButton
          :icon="flareIcons['chevron-right']"
          :ariaLabel="t('dataTable.next')"
          size="sm"
          shape="square"
          :disabled="loading || !steps.next"
          @click="goTo(pagination.page + 1)"
        />
      </div>
    </nav>
  </div>
</template>

<style scoped>
.flare-data-table {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  color: var(--flare-color-text-primary);
  container-type: inline-size;
  container-name: flare-data-table;
}
.flare-data-table__bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-data-table__bar-lead {
  display: flex;
  flex: 1 1 auto;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
/* The bar's 32px keys sit 14px apart. Each key's hit halo is 48px (8px past its edge) and a later key
   paints over an earlier one, so with a smaller gap the next key's halo swallows a tap 5px past this
   key's edge — the gap has to exceed 8 + 5. */
.flare-data-table__bar-trail {
  display: inline-flex;
  flex: none;
  align-items: center;
  gap: var(--flare-size-spacing-2md);
}
.flare-data-table__sort-menu,
.flare-data-table__chooser-trigger { display: inline-flex; }
.flare-data-table__chooser {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-3xs);
  min-width: 200px;
  padding: var(--flare-size-spacing-sm);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-md);
}
.flare-data-table__chooser--sheet {
  min-width: 0;
  padding: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
  border: none;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
}
.flare-data-table__chooser-row {
  min-height: var(--flare-size-layout-control-height-md);
  padding: 0 var(--flare-size-spacing-xs);
  border-radius: var(--flare-size-radius-sm);
}
@media (hover: hover) {
  .flare-data-table__chooser-row:not(.is-disabled):hover { background: var(--flare-color-bg-hover); }
}

/* Selection mode: a tinted band above the rows, the count read aloud, the host's actions beside the kit's. */
.flare-data-table__batch {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm) var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  border: 1px solid var(--flare-color-border-selected);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-selected);
}
.flare-data-table__batch-count {
  flex: none;
  color: var(--flare-color-primary-text);
  font-size: var(--flare-text-body-font-size);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
}
.flare-data-table__batch-actions {
  display: flex;
  flex: 1 1 auto;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-data-table__batch-exit { flex: none; }

.flare-data-table__scroll {
  min-width: 0;
  overflow-x: auto;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
}
.is-sticky .flare-data-table__scroll {
  max-height: var(--flare-component-data-table-max-height);
  overflow-y: auto;
}
.flare-data-table__table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  table-layout: auto;
  font-size: var(--flare-text-body-font-size);
  line-height: var(--flare-text-body-line-height);
}
.flare-data-table__th {
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border-bottom: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-section-font-size);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-text-section-line-height);
  text-align: start;
  white-space: nowrap;
  vertical-align: middle;
}
.is-sticky .flare-data-table__th {
  position: sticky;
  top: 0;
  z-index: 1;
}
.flare-data-table__th.is-sorted { color: var(--flare-color-text-primary); }
.flare-data-table__th--select,
.flare-data-table__td--select {
  width: var(--flare-size-layout-control-height-md);
  padding-inline: var(--flare-size-spacing-sm);
}
[data-align="center"] { text-align: center; }
[data-align="end"] { text-align: end; }
.flare-data-table__sort {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  margin: calc(-1 * var(--flare-size-spacing-xs)) 0;
  padding: var(--flare-size-spacing-xs) 0;
  border: none;
  border-radius: var(--flare-size-radius-sm);
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.flare-data-table__sort:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-data-table__sort-icon {
  opacity: 0;
  transition: opacity var(--flare-transition-fast);
}
.is-sorted .flare-data-table__sort-icon { opacity: 1; }
@media (hover: hover) {
  .flare-data-table__sort:hover .flare-data-table__sort-icon { opacity: var(--flare-opacity-muted); }
  .is-sorted .flare-data-table__sort:hover .flare-data-table__sort-icon { opacity: 1; }
}
.flare-data-table__td {
  height: var(--flare-component-data-table-row-height);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  border-bottom: 1px solid var(--flare-color-border-secondary);
  vertical-align: middle;
  overflow-wrap: anywhere;
}
.flare-data-table--compact .flare-data-table__td { height: var(--flare-component-data-table-row-height-compact); }
.flare-data-table__row:last-child .flare-data-table__td { border-bottom: none; }
.flare-data-table__td.is-ellipsis {
  max-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-data-table__row.is-selected .flare-data-table__td { background: var(--flare-color-bg-selected); }
.is-interactive .flare-data-table__row { cursor: pointer; }
.is-interactive .flare-data-table__row:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
@media (hover: hover) {
  .is-interactive .flare-data-table__row:hover .flare-data-table__td { background: var(--flare-color-bg-hover); }
  .is-interactive .flare-data-table__row.is-selected:hover .flare-data-table__td { background: var(--flare-color-bg-selected); }
}
.flare-data-table__td--actions { white-space: nowrap; }
.flare-data-table__row-actions {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
.flare-data-table__state {
  padding: var(--flare-size-spacing-lg);
  text-align: center;
}
.flare-data-table__state :deep(.flare-skeleton) { text-align: start; }

.flare-data-table__pagination {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
}
.flare-data-table__range { font-variant-numeric: tabular-nums; }
.flare-data-table__pager {
  display: inline-flex;
  flex: none;
  flex-wrap: wrap;
  min-width: 0;
  max-width: 100%;
  justify-content: flex-end;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
.flare-data-table__page {
  min-width: var(--flare-size-layout-control-height-lg);
  color: var(--flare-color-text-primary);
  font-variant-numeric: tabular-nums;
  text-align: center;
}
/* Heard, not seen. */
.flare-data-table__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}

/* Narrow container: rows stack into labelled lines instead of scrolling sideways. The header stays
   for assistive technology as titles; sorting is the menu in the bar and select-all the batch toolbar.
   Nothing can overflow sideways any more, so the scroll box stops clipping — a checkbox's hit halo
   in the first row reaches above the row. */
@container flare-data-table (max-width: 599px) {
  .flare-data-table__range { flex-basis: 100%; }
  .flare-data-table__pager { margin-inline-start: auto; }
  .flare-data-table__scroll {
    max-height: none;
    overflow: visible;
  }
  .flare-data-table__head {
    position: absolute;
    width: 1px;
    height: 1px;
    margin: -1px;
    padding: 0;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
    border: 0;
  }
  .flare-data-table__table,
  .flare-data-table__body,
  .flare-data-table__row,
  .flare-data-table__state-row {
    display: block;
    width: 100%;
  }
  .flare-data-table__row {
    display: grid;
    grid-template-columns: auto minmax(0, 1fr);
    gap: 0 var(--flare-size-spacing-sm);
    padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
    border-bottom: 1px solid var(--flare-color-border-secondary);
  }
  .flare-data-table__row:last-child { border-bottom: none; }
  .flare-data-table__row.is-selected { background: var(--flare-color-bg-selected); }
  .flare-data-table__td {
    display: flex;
    grid-column: 2;
    gap: var(--flare-size-spacing-sm);
    align-items: baseline;
    width: auto;
    height: auto;
    min-height: 0;
    padding: var(--flare-size-spacing-3xs) 0;
    border-bottom: none;
    background: transparent;
    text-align: start;
  }
  .flare-data-table__td[data-label]::before {
    content: attr(data-label);
    flex: 0 0 38%;
    color: var(--flare-color-text-secondary);
    font-size: var(--flare-text-caption-font-size);
  }
  /* The checkbox sits beside the whole stack; the span covers any column count (empty implicit rows have
     no height). Its padding keeps the 48px hit halo clear of the row above and of the first line of text. */
  .flare-data-table__td--select {
    grid-column: 1;
    grid-row: 1 / span 99;
    align-self: start;
    padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md) var(--flare-size-spacing-xs) 0;
  }
  .flare-data-table__td.is-ellipsis {
    max-width: none;
    white-space: normal;
  }
  .flare-data-table__td--actions { white-space: normal; }
  .flare-data-table__row.is-selected .flare-data-table__td { background: transparent; }
  @media (hover: hover) {
    .is-interactive .flare-data-table__row:hover .flare-data-table__td { background: transparent; }
  }
  .flare-data-table__state { display: block; grid-column: 1 / -1; }
}
@media (prefers-reduced-motion: reduce) {
  .flare-data-table__sort-icon { transition: none; }
}
</style>
