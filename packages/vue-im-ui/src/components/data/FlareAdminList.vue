<script setup lang="ts">
/** Naive UI operational list composition. No business queries, role rules or client-side paging. */
import {
  computed,
  getCurrentInstance,
  h,
  ref,
  useId,
  useSlots,
  watch,
  type HTMLAttributes,
} from "vue";
import {
  NAlert,
  NButton,
  NCheckbox,
  NDataTable,
  NEmpty,
  NForm,
  NIcon,
  NPagination,
  NPopover,
  NSelect,
  NSpin,
  NText,
  useThemeVars,
  type DataTableColumns,
  type DataTableRowData,
  type DataTableRowKey,
  type SelectProps,
} from "naive-ui";
import { ChevronDown, ChevronUp, Settings2 } from "@lucide/vue";
import {
  flattenQueryFields,
  useFirstRowCollapse,
} from "../../composables/useFirstRowCollapse";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import type { FlareAdminColumn, FlareAdminPagination } from "./admin-list";
import FlareAdminActions from "./FlareAdminActions.vue";
import FlareAdminCardGrid from "./FlareAdminCardGrid.vue";
import FlareAdminHelp from "./FlareAdminHelp.vue";
import {
  dataTableSelection,
  dataTableToggleAll,
  dataTableToggleRow,
  dataTableRowKey,
  dataTableIsCursor,
  dataTablePageCount,
} from "./data-table";

const props = withDefaults(
  defineProps<{
    label: string;
    columns: readonly FlareAdminColumn[];
    rows: readonly DataTableRowData[];
    rowKey: string | ((row: DataTableRowData, index: number) => string);
    loading?: boolean;
    error?: string;
    /** Hosts using external notifications retain read failures as neutral, actionable content. */
    errorPresentation?: "inline" | "neutral";
    /** A pending write locks query, selection and paging, but leaves current rows visible. */
    disabled?: boolean;
    paginationDisabled?: boolean;
    selectionDisabled?: boolean;
    searchDisabled?: boolean;
    /** Reveal invalid advanced fields without discarding their drafts or measured nodes. */
    filtersInvalid?: boolean;
    rowSelectable?: (row: DataTableRowData, index: number) => boolean;
    /** Detail sections own a bounded, natural-height list, not another full viewport. */
    embedded?: boolean;
    tableVisible?: boolean;
    /**
     * Resource cards use the item slot; query, remote paging and busy guards stay shared.
     * `content` keeps the same query bar, notice and toolbar for a page that is not a list
     * (settings, charts, grouped sections) and renders the `content` slot in the body.
     */
    layout?: "table" | "cards" | "content";
    /** Resource collections may sit directly on the page without a second enclosing panel. */
    surface?: "panel" | "plain";
    /** Give filters and actions a joined theme surface on a plain resource collection. */
    controlsSurface?: "inherit" | "panel";
    selectable?: boolean;
    pagination?: FlareAdminPagination;
    searchText?: string;
    resetText?: string;
    expandText?: string;
    collapseText?: string;
    settingsText?: string;
    emptyText?: string;
  }>(),
  {
    loading: false,
    error: "",
    errorPresentation: "inline",
    disabled: false,
    selectable: false,
    tableVisible: true,
    layout: "table",
    surface: "panel",
    controlsSurface: "inherit",
  },
);
const emit = defineEmits<{
  search: [];
  reset: [];
  rowClick: [row: DataTableRowData, index: number];
  "update:pagination": [value: FlareAdminPagination];
}>();
const checkedRowKeys = defineModel<string[]>("checkedRowKeys", {
  default: () => [],
});
const visibleColumnKeys = defineModel<string[] | null>("visibleColumnKeys", {
  default: null,
});
/** Native Naive tree expansion only; hierarchy does not imply row selection. */
const expandedRowKeys = defineModel<string[] | undefined>("expandedRowKeys");
const expanded = ref(false);
watch(
  () => props.filtersInvalid,
  (invalid) => {
    if (invalid) expanded.value = true;
  },
  { immediate: true },
);
const chooserOpen = ref(false);
const chooserTrigger = ref<HTMLElement | null>(null);
function closeChooserByKeyboard(event: KeyboardEvent) {
  // Native click popovers leave focus on the trigger. Consume Escape there
  // as well as in the teleported menu, before a parent drawer/modal sees it.
  if (!chooserOpen.value) return;
  event.preventDefault();
  event.stopPropagation();
  chooserOpen.value = false;
  chooserTrigger.value?.querySelector("button")?.focus();
}
const root = ref<HTMLElement | null>(null);
const fields = ref<HTMLElement | null>(null);
const { firstRowCount, firstRowHeight, overflowing, width } =
  useFirstRowCollapse(fields, expanded, root);
const { t } = useFlareI18nOptional();
const theme = useThemeVars();
const slots = useSlots();
const instance = getCurrentInstance();
const fieldsId = `flare-admin-filters-${useId()}`;
const compact = computed(() => width.value > 0 && width.value < 600);
// A content page has no column chooser; draw the toolbar only when it holds something.
const toolbarVisible = computed(
  () =>
    props.layout !== "content" ||
    ["actions", "tools", "help"].some(
      (name) => flattenQueryFields(slots[name]?.() ?? []).length > 0,
    ),
);
const locked = computed(() => props.disabled || props.loading);
const pagingLocked = computed(() => locked.value || props.paginationDisabled);
const selectionLocked = computed(() => locked.value || props.selectionDisabled);
const shownColumns = computed(() => {
  const result = props.columns.filter(
    (column) =>
      column.hideable === false ||
      visibleColumnKeys.value === null ||
      visibleColumnKeys.value.includes(String(column.key)),
  );
  return result.length ? result : props.columns.slice(0, 1);
});
const tableColumns = computed<DataTableColumns>(() => {
  const base: DataTableColumns = shownColumns.value.map((column) => ({
    ...column,
    ellipsis: column.ellipsis === true ? { tooltip: true } : column.ellipsis,
    align:
      column.align === "start"
        ? "left"
        : column.align === "end"
          ? "right"
          : column.align,
    render: (row, index) => {
      const render = () =>
        slots[column.slot ?? `cell-${column.key}`]?.({
          row,
          index,
          value: row[column.key],
        }) ??
        column.render?.(row, index) ??
        String(row[column.key] ?? "—");
      // `actions` is the shared operational-column convention; an audit column
      // named `action` is ordinary data and must not acquire button semantics.
      return column.key === "actions"
        ? h(
            FlareAdminActions,
            { label: String(column.title ?? t("dataTable.actions")) },
            render,
          )
        : render();
    },
  }));
  let actionKey = "__flare_actions__";
  while (base.some((column) => "key" in column && column.key === actionKey))
    actionKey += "_";
  if (slots["row-actions"])
    base.push({
      key: actionKey,
      title: t("dataTable.actions"),
      width: 140,
      render: (row, index) =>
        h(FlareAdminActions, { label: t("dataTable.actions") }, () =>
          slots["row-actions"]?.({ row, index }),
        ),
    });
  if (!props.selectable) return base;
  const update = selectionHandler.value;
  const keys = props.rows
    .filter((row, index) => props.rowSelectable?.(row, index) !== false)
    .map((row) => rowIdentity(row));
  const state = dataTableSelection(keys, checkedRowKeys.value);
  let key = "__flare_selection__";
  while (props.columns.some((column) => String(column.key) === key)) key += "_";
  return [
    {
      key,
      fixed: "left",
      width: 44,
      title: () =>
        h(NCheckbox, {
          checked: state === "all",
          indeterminate: state === "some",
          disabled: selectionLocked.value || !keys.length,
          "aria-disabled": selectionLocked.value || !keys.length,
          "aria-label": t("dataTable.selectAll"),
          "onUpdate:checked": () =>
            update(dataTableToggleAll(keys, checkedRowKeys.value)),
        }),
      render: (row, index) =>
        h(NCheckbox, {
          checked: checkedRowKeys.value.includes(rowIdentity(row)),
          disabled:
            selectionLocked.value ||
            props.rowSelectable?.(row, index) === false,
          "aria-disabled":
            selectionLocked.value ||
            props.rowSelectable?.(row, index) === false,
          "aria-label": t("dataTable.selectRow", { index: index + 1 }),
          "onUpdate:checked": (on) =>
            update(
              dataTableToggleRow(rowIdentity(row), checkedRowKeys.value, on),
            ),
        }),
    },
    ...base,
  ];
});
const tableRows = computed(() => [...props.rows]);
const scrollX = computed(() =>
  shownColumns.value.reduce(
    (sum, column) =>
      sum + (Number(column.width) || Number(column.minWidth) || 160),
    (props.selectable ? 44 : 0) + (slots["row-actions"] ? 140 : 0),
  ),
);
const selectionHandler = computed(() => {
  const snapshot = props.rows;
  return (keys: DataTableRowKey[]) => {
    if (selectionLocked.value || !props.selectable || props.rows !== snapshot)
      return;
    const allowed = new Set(
      props.rows
        .filter((row, index) => props.rowSelectable?.(row, index) !== false)
        .map((row) => rowIdentity(row)),
    );
    const existing = new Set(checkedRowKeys.value);
    if (
      keys.some(
        (key) => !allowed.has(String(key)) && !existing.has(String(key)),
      )
    )
      return;
    checkedRowKeys.value = [...new Set(keys.map(String))];
  };
});
function rowIdentity(row: Record<string, unknown>) {
  return dataTableRowKey(row, props.rowKey, props.rows.indexOf(row));
}
function rowProps(row: DataTableRowData, index: number) {
  if (!instance?.vnode.props?.onRowClick) return {};
  const snapshot = props.rows;
  const activate = () => {
    if (!locked.value && props.rows === snapshot && props.rows.includes(row))
      emit("rowClick", row, index);
  };
  return {
    tabindex: 0,
    onClick: (event: MouseEvent) => {
      if (
        !(event.target as Element)?.closest(
          "button,a,input,select,textarea,[role=button]",
        )
      )
        activate();
    },
    onKeydown: (event: KeyboardEvent) => {
      if (
        event.target === event.currentTarget &&
        (event.key === "Enter" || event.key === " ")
      ) {
        event.preventDefault();
        activate();
      }
    },
  };
}
function columnChecked(key: string) {
  return shownColumns.value.some((column) => String(column.key) === key);
}
function columnLocked(column: FlareAdminColumn) {
  return (
    column.hideable === false ||
    (columnChecked(String(column.key)) && shownColumns.value.length <= 1)
  );
}
function toggleColumn(column: FlareAdminColumn, checked: boolean) {
  if (columnLocked(column)) return;
  const keys = new Set(shownColumns.value.map((entry) => String(entry.key)));
  if (checked) keys.add(String(column.key));
  else keys.delete(String(column.key));
  visibleColumnKeys.value = props.columns
    .filter((entry) => keys.has(String(entry.key)))
    .map((entry) => String(entry.key));
}
const rangeText = computed(() => {
  const p = props.pagination;
  if (!p) return "";
  if (props.loading) return t("dataTable.loading");
  if (dataTableIsCursor(p))
    return t("dataTable.pageItems", { count: props.rows.length });
  if (!p.total)
    return t(
      p.totalKind === "loaded"
        ? "dataTable.loadedEmpty"
        : "dataTable.rangeEmpty",
    );
  if (!props.rows.length) return t("dataTable.pageItems", { count: 0 });
  const from = (p.page - 1) * p.pageSize + 1;
  return t(
    p.totalKind === "loaded" ? "dataTable.loadedRange" : "dataTable.range",
    {
      from,
      to: Math.min(p.total, from + props.rows.length - 1),
      total: p.total,
    },
  );
});
const pageHandler = computed(() => {
  const snapshot = props.pagination;
  return (page: number) => {
    if (
      !snapshot ||
      pagingLocked.value ||
      snapshot !== props.pagination ||
      !Number.isSafeInteger(page) ||
      page < 1 ||
      (dataTableIsCursor(snapshot)
        ? page !== snapshot.page - 1 &&
          !(snapshot.hasNext && page === snapshot.page + 1)
        : page > dataTablePageCount(snapshot)) ||
      page === snapshot.page
    )
      return;
    emit("update:pagination", { ...snapshot, page });
  };
});
const pageSizeHandler = computed(() => {
  const snapshot = props.pagination;
  return (pageSize: number) => {
    if (
      !snapshot ||
      pagingLocked.value ||
      snapshot !== props.pagination ||
      !(snapshot.pageSizes ?? []).includes(pageSize) ||
      pageSize === snapshot.pageSize
    )
      return;
    emit("update:pagination", { ...snapshot, page: 1, pageSize });
  };
});
const previousPageHandler = computed(() => {
  const snapshot = props.pagination,
    change = pageHandler.value;
  return () => {
    if (snapshot) change(snapshot.page - 1);
  };
});
const nextPageHandler = computed(() => {
  const snapshot = props.pagination,
    change = pageHandler.value;
  return () => {
    if (snapshot) change(snapshot.page + 1);
  };
});
const pageSizeSelectProps = computed<SelectProps & HTMLAttributes>(() => ({
  "aria-label": t("dataTable.pageSize"),
  inputProps: { "aria-label": t("dataTable.pageSize") },
  placement: "top-end",
}));
const QueryCells = () =>
  flattenQueryFields(slots.filters?.() ?? []).map((node, index) => {
    const folded =
      !expanded.value && overflowing.value && index >= firstRowCount.value;
    return h(
      "div",
      {
        key: node.key ?? index,
        class: ["flare-admin-list__field", { "is-folded": folded }],
        inert: folded ? true : undefined,
        "aria-hidden": folded ? "true" : undefined,
      },
      [node],
    );
  });
function search() {
  if (!locked.value && !props.searchDisabled) emit("search");
}
function reset() {
  if (!locked.value && !props.searchDisabled) emit("reset");
}
function onQueryKey(event: KeyboardEvent) {
  if (
    event.key !== "Enter" ||
    event.defaultPrevented ||
    event.isComposing ||
    event.keyCode === 229 ||
    event.shiftKey ||
    event.ctrlKey ||
    event.altKey ||
    event.metaKey
  )
    return;
  const target = event.target;
  if (
    !(target instanceof HTMLInputElement) ||
    !["text", "search", "email", "tel", "url", "number"].includes(
      target.type,
    ) ||
    target.getAttribute("aria-expanded") === "true"
  )
    return;
  event.preventDefault();
  search();
}
</script>

<template>
  <section
    ref="root"
    class="flare-admin-list"
    :class="{
      'flare-admin-list--embedded': embedded,
      'flare-admin-list--plain': surface === 'plain',
      'flare-admin-list--controls-panel': controlsSurface === 'panel',
    }"
    :aria-label="label"
    :style="{
      '--flare-admin-surface': theme.cardColor,
      '--flare-admin-line': theme.dividerColor,
    }"
  >
    <NAlert
      v-if="error && errorPresentation === 'inline'"
      type="error"
      :bordered="false"
      class="flare-admin-list__error"
      >{{ error }}<slot name="error-actions"
    /></NAlert>
    <div
      v-else-if="error"
      class="flare-admin-list__error flare-admin-list__error--neutral"
      role="status"
    >
      <span>{{ error }}</span
      ><slot name="error-actions" />
    </div>
    <div
      v-if="slots.notice && flattenQueryFields(slots.notice()).length"
      class="flare-admin-list__notice"
    >
      <slot name="notice" />
    </div>
    <NForm
      v-if="slots.filters && flattenQueryFields(slots.filters()).length"
      class="flare-admin-list__query"
      :label-placement="compact ? 'top' : 'left'"
      :label-width="compact ? undefined : 'auto'"
      label-align="left"
      :show-feedback="false"
      size="small"
      :disabled="disabled"
      role="search"
      :aria-label="t('filterBar.label')"
      @submit.prevent
      @keydown="onQueryKey"
    >
      <div class="flare-admin-list__query-layout">
        <div
          class="flare-admin-list__query-viewport"
          :style="
            !expanded && overflowing
              ? { maxHeight: firstRowHeight + 'px' }
              : undefined
          "
        >
          <div :id="fieldsId" ref="fields" class="flare-admin-list__fields">
            <QueryCells />
          </div>
        </div>
        <div class="flare-admin-list__query-actions">
          <slot name="query-actions">
            <NButton
              size="small"
              type="primary"
              :loading="loading"
              :disabled="locked"
              @click="search"
              >{{ searchText ?? t("filterBar.search") }}</NButton
            >
            <NButton size="small" :disabled="locked" @click="reset">{{
              resetText ?? t("filterBar.reset")
            }}</NButton>
          </slot>
          <NButton
            size="small"
            text
            type="primary"
            class="flare-admin-list__expand"
            :class="{ 'is-unneeded': !overflowing }"
            :disabled="disabled || !overflowing"
            :aria-expanded="expanded"
            :aria-controls="fieldsId"
            :aria-hidden="!overflowing ? true : undefined"
            :tabindex="!overflowing ? -1 : undefined"
            @click="expanded = !expanded"
          >
            {{
              expanded
                ? (collapseText ?? t("filterBar.less"))
                : (expandText ?? t("filterBar.more"))
            }}
            <template #icon
              ><NIcon :component="expanded ? ChevronUp : ChevronDown"
            /></template>
          </NButton>
        </div>
      </div>
    </NForm>
    <div
      v-if="toolbarVisible"
      class="flare-admin-list__toolbar"
      role="group"
      :aria-label="t('dataTable.actions')"
    >
      <FlareAdminActions class="flare-admin-list__actions"
        ><slot name="actions"
      /></FlareAdminActions>
      <div class="flare-admin-list__settings">
        <slot name="tools" />
        <FlareAdminHelp v-if="slots.help" :label="t('dataTable.help')">
          <slot name="help" />
        </FlareAdminHelp>
        <NPopover
          v-if="layout === 'table'"
          v-model:show="chooserOpen"
          trigger="click"
          placement="bottom-end"
          :width="220"
        >
          <template #trigger
            ><span
              ref="chooserTrigger"
              class="flare-admin-list__settings-trigger"
              @keydown.esc="closeChooserByKeyboard"
              ><NButton
                size="small"
                :aria-expanded="chooserOpen"
                :aria-label="settingsText ?? t('dataTable.columns')"
              >
                <template #icon><NIcon :component="Settings2" /></template
                >{{ settingsText ?? t("dataTable.columns") }}
              </NButton></span
            ></template
          >
          <div
            class="flare-admin-list__columns"
            role="group"
            :aria-label="t('dataTable.columns')"
            @keydown.esc="closeChooserByKeyboard"
          >
            <NCheckbox
              v-for="column in columns"
              :key="String(column.key)"
              :checked="columnChecked(String(column.key))"
              :disabled="columnLocked(column)"
              :aria-disabled="columnLocked(column)"
              @update:checked="(value) => toggleColumn(column, value)"
              >{{ column.title }}</NCheckbox
            >
          </div>
        </NPopover>
      </div>
    </div>
    <div
      v-if="tableVisible && layout === 'cards'"
      class="flare-admin-list__cards"
      role="region"
      :aria-label="label"
      :aria-busy="loading"
    >
      <NSpin :show="loading">
        <FlareAdminCardGrid v-if="rows.length" density="compact">
          <template
            v-for="(item, index) in rows"
            :key="dataTableRowKey(item, rowKey, index)"
          >
            <slot name="item" :row="item" :index="index" :disabled="locked" />
          </template>
        </FlareAdminCardGrid>
        <div v-else class="flare-admin-list__card-empty">
          <span v-if="loading" role="status">{{ t("dataTable.loading") }}</span>
          <slot v-else name="empty"
            ><NEmpty :description="emptyText ?? t('dataTable.empty')"
          /></slot>
        </div>
      </NSpin>
    </div>
    <div
      v-if="tableVisible && layout === 'content'"
      class="flare-admin-list__content"
      role="region"
      :aria-label="label"
      :aria-busy="loading"
    >
      <slot name="content" />
    </div>
    <div
      v-if="tableVisible && layout === 'table'"
      class="flare-admin-list__table"
    >
      <NDataTable
        remote
        flex-height
        size="small"
        striped
        :bordered="false"
        :bottom-bordered="false"
        :columns="tableColumns"
        :data="tableRows"
        :row-key="rowIdentity"
        :row-props="rowProps"
        :loading="loading"
        :aria-busy="loading"
        :scroll-x="scrollX"
        :checked-row-keys="checkedRowKeys"
        @update:checked-row-keys="selectionHandler"
        :expanded-row-keys="expandedRowKeys"
        @update:expanded-row-keys="
          (keys) => {
            if (!locked) expandedRowKeys = keys.map(String);
          }
        "
      >
        <template #empty>
          <span v-if="loading" role="status">{{ t("dataTable.loading") }}</span>
          <slot v-else name="empty"
            ><NEmpty :description="emptyText ?? t('dataTable.empty')"
          /></slot>
        </template>
      </NDataTable>
    </div>
    <footer
      v-if="
        (pagination && tableVisible) ||
        slots['footer-extra'] ||
        slots['footer-summary']
      "
      class="flare-admin-list__footer"
      :aria-label="t('dataTable.pagination')"
    >
      <NText depth="3" class="flare-admin-list__total" aria-live="polite">
        <slot name="footer-summary">{{ rangeText }}</slot>
      </NText>
      <slot name="footer-extra" />
      <NSelect
        v-if="
          pagination &&
          !dataTableIsCursor(pagination) &&
          compact &&
          pagination.pageSizes?.length
        "
        class="flare-admin-list__compact-page-size"
        size="small"
        :aria-label="t('dataTable.pageSize')"
        :input-props="{ 'aria-label': t('dataTable.pageSize') }"
        :value="pagination.pageSize"
        :options="
          pagination.pageSizes.map((value) => ({
            value,
            label: t('dataTable.perPage', { size: value }),
          }))
        "
        :disabled="pagingLocked"
        style="width: 112px"
        @update:value="pageSizeHandler"
      />
      <div
        v-if="pagination && dataTableIsCursor(pagination)"
        class="flare-admin-list__cursor"
        :aria-label="t('dataTable.pagination')"
      >
        <NSelect
          v-if="pagination.pageSizes?.length && !compact"
          size="small"
          :aria-label="t('dataTable.pageSize')"
          :value="pagination.pageSize"
          :options="
            pagination.pageSizes.map((value) => ({
              value,
              label: String(value),
            }))
          "
          :disabled="pagingLocked"
          style="width: 90px"
          @update:value="pageSizeHandler"
        />
        <NButton
          size="small"
          :disabled="pagingLocked || pagination.page <= 1"
          :aria-label="t('dataTable.previous')"
          @click="previousPageHandler"
          >‹</NButton
        >
        <NText aria-live="polite">{{
          t("dataTable.pageOnly", { page: pagination.page })
        }}</NText>
        <NButton
          size="small"
          :disabled="pagingLocked || !pagination.hasNext"
          :aria-label="t('dataTable.next')"
          @click="nextPageHandler"
          >›</NButton
        >
      </div>
      <NPagination
        v-else-if="pagination"
        size="small"
        :page="pagination.page"
        :page-size="pagination.pageSize"
        :page-sizes="
          pagination.pageSizes ? [...pagination.pageSizes] : undefined
        "
        :show-size-picker="!compact && !!pagination.pageSizes?.length"
        :page-slot="width > 1000 ? 7 : 5"
        :simple="compact || dataTableIsCursor(pagination)"
        :page-count="
          dataTableIsCursor(pagination)
            ? pagination.page + (pagination.hasNext ? 1 : 0)
            : undefined
        "
        :item-count="pagination.total"
        :show-quick-jumper="
          !compact &&
          !dataTableIsCursor(pagination) &&
          (pagination.total ?? 0) > pagination.pageSize * 7
        "
        :display-order="['size-picker', 'pages', 'quick-jumper']"
        :disabled="pagingLocked"
        :select-props="pageSizeSelectProps"
        @update:page="pageHandler"
        @update:page-size="pageSizeHandler"
      />
    </footer>
  </section>
</template>

<style scoped>
.flare-admin-list {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 0;
  min-width: 0;
  border: 1px solid var(--flare-admin-line);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-admin-surface);
  overflow: hidden;
  container-type: inline-size;
}
.flare-admin-list__cards {
  flex: 1;
  min-height: 0;
  overflow: auto;
  scrollbar-width: thin;
  scrollbar-color: var(--flare-admin-line) var(--flare-admin-surface);
  padding: var(--flare-size-spacing-md);
}
.flare-admin-list--plain {
  border: 0;
  border-radius: 0;
  background: transparent;
}
.flare-admin-list--plain .flare-admin-list__query {
  padding: 0 0 var(--flare-size-spacing-sm);
  border-bottom: 0;
}
.flare-admin-list--plain .flare-admin-list__toolbar {
  padding: var(--flare-size-spacing-sm) 0 var(--flare-size-spacing-md);
  border-bottom: 0;
}
.flare-admin-list--plain.flare-admin-list--controls-panel
  .flare-admin-list__query,
.flare-admin-list--plain.flare-admin-list--controls-panel
  .flare-admin-list__toolbar {
  padding: var(--flare-size-spacing-md);
  border: 1px solid var(--flare-admin-line);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-admin-surface);
}
.flare-admin-list--plain.flare-admin-list--controls-panel
  .flare-admin-list__query {
  padding-bottom: var(--flare-size-spacing-sm);
  border-bottom: 0;
  border-end-start-radius: 0;
  border-end-end-radius: 0;
}
.flare-admin-list--plain.flare-admin-list--controls-panel
  .flare-admin-list__toolbar {
  margin-bottom: var(--flare-size-spacing-md);
}
.flare-admin-list--plain.flare-admin-list--controls-panel
  .flare-admin-list__query
  + .flare-admin-list__toolbar {
  padding-top: var(--flare-size-spacing-sm);
  border-top: 0;
  border-start-start-radius: 0;
  border-start-end-radius: 0;
}
.flare-admin-list--plain .flare-admin-list__cards {
  padding: 0;
}
.flare-admin-list--plain .flare-admin-list__footer {
  padding-inline: 0;
  border-top: 0;
}
.flare-admin-list__content {
  flex: 1;
  min-height: 0;
  min-width: 0;
  overflow: auto;
  overscroll-behavior: contain;
  scrollbar-width: thin;
  scrollbar-color: var(--flare-admin-line) var(--flare-admin-surface);
  padding: var(--flare-size-spacing-md);
}
.flare-admin-list--plain .flare-admin-list__content {
  padding: 0;
}
.flare-admin-list__cards::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}
.flare-admin-list__cards::-webkit-scrollbar-track {
  background: var(--flare-admin-surface);
}
.flare-admin-list__cards::-webkit-scrollbar-thumb {
  background: var(--flare-admin-line);
  border-radius: var(--flare-size-radius-sm);
}
.flare-admin-list__card-empty {
  min-height: 160px;
  display: grid;
  place-items: center;
}
.flare-admin-list__error {
  flex: none;
  max-height: 100px;
  overflow: auto;
}
.flare-admin-list__error--neutral {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  color: var(--flare-color-text-secondary);
}
.flare-admin-list__notice {
  flex: none;
  max-height: 20%;
  overflow: auto;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
}
.flare-admin-list--embedded {
  height: min(32rem, calc(100dvh - 10rem));
  min-height: 18rem;
  flex: none;
}
.flare-admin-list__query {
  flex: none;
  padding: var(--flare-size-spacing-md);
  max-height: 40%;
  overflow-y: auto;
  border-bottom: 1px solid var(--flare-admin-line);
}
.flare-admin-list__query-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--flare-size-spacing-md);
  align-items: start;
}
.flare-admin-list__query-viewport {
  min-width: 0;
  overflow: hidden;
}
.flare-admin-list__fields {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(100%, 280px), 1fr));
  gap: var(--flare-size-spacing-md);
}
.flare-admin-list__fields :deep(.flare-admin-list__field) {
  min-width: 0;
}
.flare-admin-list__fields :deep(.is-folded) {
  visibility: hidden;
  pointer-events: none;
}
.flare-admin-list__query-actions,
.flare-admin-list__cursor,
.flare-admin-list__toolbar,
.flare-admin-list__actions,
.flare-admin-list__settings {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
.flare-admin-list__query-actions {
  min-height: 28px;
}
.flare-admin-list__expand.is-unneeded {
  visibility: hidden;
  pointer-events: none;
}
.flare-admin-list__toolbar {
  flex: none;
  justify-content: space-between;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border-bottom: 1px solid var(--flare-admin-line);
  max-height: 25%;
  overflow: auto;
}
.flare-admin-list__actions {
  flex-wrap: wrap;
  min-width: 0;
}
.flare-admin-list__settings {
  flex: 0 1 auto;
  min-width: 0;
  flex-wrap: wrap;
  justify-content: flex-end;
  overflow-wrap: anywhere;
  margin-inline-start: auto;
}
.flare-admin-list__columns {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  max-height: 50vh;
  overflow-y: auto;
}
.flare-admin-list__table {
  flex: 1;
  min-height: 0;
  overflow: hidden;
}
.flare-admin-list__table > :deep(.n-data-table) {
  height: 100%;
}
.flare-admin-list__footer {
  flex: none;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  padding-bottom: var(--flare-size-spacing-lg);
  border-top: 1px solid var(--flare-admin-line);
}
.flare-admin-list__total {
  font-size: var(--flare-text-caption-font-size);
  white-space: nowrap;
}
@container (max-width: 599px) {
  .flare-admin-list__query-layout {
    grid-template-columns: minmax(0, 1fr);
  }
  .flare-admin-list__query-actions {
    justify-content: flex-start;
  }
  .flare-admin-list__toolbar {
    flex-wrap: wrap;
    align-items: flex-start;
  }
  .flare-admin-list__footer {
    flex-wrap: wrap;
  }
}
</style>
