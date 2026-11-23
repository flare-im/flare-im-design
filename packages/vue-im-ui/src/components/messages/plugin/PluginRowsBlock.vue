<script setup lang="ts">
import { computed, useId, useSlots } from "vue";
import FlareAdminList from "../../data/FlareAdminList.vue";
import type { FlareAdminPagination } from "../../data/admin-list";
import { dataTableIsCursor } from "../../data/data-table";
import FlareUserIdentity from "../../data/FlareUserIdentity.vue";
import FlareDataTable from "../../data/FlareDataTable.vue";
import FlareAdminCardGrid from "../../data/FlareAdminCardGrid.vue";
import FlareAdminPolicyCard from "../../data/FlareAdminPolicyCard.vue";
import FlareAdminRowActions, {
  type FlareAdminRowAction,
} from "../../data/FlareAdminRowActions.vue";
import FlareButton from "../../general/FlareButton.vue";
import FlareEmptyState from "../../general/FlareEmptyState.vue";
import FlareIcon from "../../general/FlareIcon.vue";
import FlareTag from "../../general/FlareTag.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import { flareServerNowMs } from "../../../shared/server-clock";
import { flarePluginAmountSign, flarePluginDisplayAmount, flarePluginRowTap, flarePluginStatusDraw } from "../../../shared/contracts/plugin-experience";
import { flareIcons, type FlareIconName } from "../../../shared/icons";
import { useFlarePluginWarnScope } from "./warnScope";
import { useFlarePluginFilterScope } from "./filterScope";
import {
  flarePluginBadgeTone,
  flarePluginDateTime,
  flarePluginRowDayHeadings,
  flarePluginRecordLine,
  flarePluginRowLines,
  flarePluginRowTexts,
  flarePluginRowsOnce,
  type FlarePluginAction,
  type FlarePluginRow,
  type FlarePluginRowsBlock,
  type FlarePluginRowsLayout,
  type FlarePluginStrings,
} from "../../../shared/contracts/plugin-ui";

// A rows block. `list` (a plugin page, spec rules.pageRows): one item per row — the badge and the first cell, then
// the other cells joined with " · ", then the row's action keys; rows page with the page, so there is no load
// more here. `table` (the console's admin lists, rules.rows): the kit DataTable with the columns, the badge in the
// first cell, each row's actions, a row click for the row's detail and "load more" for the next page. Either way a
// key is drawn once (the first), since rows are identified by it.
const props = withDefaults(
  defineProps<{
    block: FlarePluginRowsBlock;
    strings: FlarePluginStrings;
    busy: boolean;
    busyActionId?: string;
    /** The row whose action is in flight: only its key spins (the others wait through `busy`). */
    busyRow?: string | null;
    layout?: FlarePluginRowsLayout | "admin-list";
    labelRows?: boolean;
    adminLabel?: string;
    detailLabel?: string;
    adminContent?: boolean;
    embedded?: boolean;
    searchText?: string;
    loading?: boolean;
    disabled?: boolean;
    error?: string;
    filtersInvalid?: boolean;
    pagination?: FlareAdminPagination;
    /** Formats a time column's epoch milliseconds; absent keeps the default "M月d日 HH:mm". */
    formatTime?: (ms: number) => string;
  }>(),
  { busyActionId: undefined, busyRow: null, layout: "table", labelRows: false },
);
const emit = defineEmits<{
  (
    e: "rowAction",
    action: FlarePluginAction,
    row: FlarePluginRow,
    input: unknown,
  ): void;
  (e: "openRow", row: FlarePluginRow): void;
  (e: "loadMore", cursor: string): void;
  (e: "search"): void;
  (e: "reset"): void;
  (e: "update:pagination", value: FlareAdminPagination): void;
}>();
const visibleColumnKeys = defineModel<string[] | null>("visibleColumnKeys", {
  default: null,
});
const expandedRowKeys = defineModel<string[] | undefined>("expandedRowKeys");
const slots = useSlots();
const controlSlots = computed(() =>
  [
    "filters",
    "query-actions",
    "actions",
    "tools",
    "error-actions",
    "notice",
    "help",
    "content",
  ].filter((name) => !!slots[name]),
);
const { t } = useFlareI18nOptional();
const warnAt = useFlarePluginWarnScope();
// §5.8: an empty list under the page's filters says so and offers to clear them.
const filters = useFlarePluginFilterScope();
/** R3: a row's badge as its Tag — the unknown status (and one development warning) when unmapped. */
function badgeOf(badge: { text: string; tone: string; unmapped?: boolean }): { label: string; tone: ReturnType<typeof flarePluginBadgeTone> } {
  const drawn = flarePluginStatusDraw(badge, warnAt(`rows:${props.block.source}:badge`));
  return { label: drawn.unknown ? t("pluginView.unknownStatus") : drawn.text, tone: drawn.tone ?? "neutral" };
}
const rowId = useId();
const tableProps = computed(() =>
  props.layout === "admin-list"
    ? {
        label: props.adminLabel || t("pluginView.detail"),
        rowKey: "id",
        loading: props.loading,
        disabled: props.disabled || props.busy,
        error: props.error,
        errorPresentation: "neutral" as const,
        pagination: props.embedded && props.pagination && !dataTableIsCursor(props.pagination) && props.pagination.total !== undefined && props.pagination.total <= props.pagination.pageSize
          ? undefined : props.pagination,
        filtersInvalid: props.filtersInvalid,
        searchText: props.searchText,
        rowActionsWidth: actionsWidth.value,
        embedded: props.embedded,
        controls: !props.embedded,
        layout:
          props.adminContent ? ("content" as const)
            : props.block.presentation === "cards" ? ("cards" as const)
              : ("table" as const),
      }
    : {
        density: "compact" as const,
        responsive: "scroll" as const,
        stickyHeader: true,
        stickyActions: true,
      },
);

const nowMs = flareServerNowMs();
const rows = computed(() => flarePluginRowsOnce(props.block.rows));
const actionOf = (id: string) =>
  props.block.actions.find((action) => action.id === id);
const spins = (row: FlarePluginRow, action: FlarePluginAction) =>
  props.busyActionId === action.id && props.busyRow === row.key;
const variantOf = (action: FlarePluginAction) =>
  action.style === "danger"
    ? "danger"
    : action.style === "primary"
      ? "primary"
      : "secondary";
/** The row's actions the block declares, with the input the view bound for each. */
const rowActions = (row: FlarePluginRow) =>
  row.actions.flatMap((ra) => {
    const action = actionOf(ra.id);
    return action ? [{ action, input: ra.input }] : [];
  });

// ── admin row actions: the console's rule (spec 5.1), at most three on the
// row and the rest under "more"; the detail key stands apart ───────────────
const ROW_ACTIONS_MAX = 3;
/** `entries` (a row's actions) as the kit's admin row actions; the one in flight spins. */
function adminActions(
  row: FlarePluginRow,
  entries: readonly { action: FlarePluginAction }[],
  disabled: boolean,
): FlareAdminRowAction[] {
  return entries.map(({ action }) => ({
    key: action.id,
    label: action.label,
    danger: action.style === "danger",
    disabled,
    loading: spins(row, action),
  }));
}
/** The row's first cell: names its "more" menu apart from the other rows'. */
const rowName = (row: FlarePluginRow) =>
  flarePluginRowTexts(props.block, row, nowMs, props.strings, undefined, props.formatTime)[0] ?? "";
/** Runs the row action `key` names, as a click on its own key would. */
function selectRowAction(row: FlarePluginRow, key: string): void {
  const entry = rowActions(row).find((candidate) => candidate.action.id === key);
  if (entry) emit("rowAction", entry.action, row, entry.input);
}
/** The action column fits the most keys a row shows: its detail and at most three more. */
const actionsWidth = computed(() => {
  const most = rows.value.reduce(
    (widest, row) =>
      Math.max(
        widest,
        (row.detailInput !== undefined ? 1 : 0) +
          Math.min(rowActions(row).length, ROW_ACTIONS_MAX),
      ),
    0,
  );
  return most <= 2 ? 140 : most === 3 ? 200 : 240;
});

// ── list ─────────────────────────────────────────────────────────────────
const dayHeadings = computed(() =>
  flarePluginRowDayHeadings(
    { columns: props.block.columns, rows: rows.value, groupByDay: props.block.groupByDay },
    nowMs,
    props.strings,
    { today: t("account.today"), yesterday: t("account.yesterday") },
  ),
);
// R3: a toned (or unmapped) cell is a status — a Tag under the row's lines, left out of the joined text.
const toned = (cell: FlarePluginRow["cells"][number] | undefined) => Boolean(cell && (cell.tone !== undefined || cell.unmapped));
const textRow = (row: FlarePluginRow): FlarePluginRow =>
  row.cells.some(toned) ? { ...row, cells: row.cells.map((cell) => (toned(cell) ? { ...cell, text: "" } : cell)) } : row;
// §5.8 / R10: a signed first cell reads as money in or out (its tone, the U+2212 minus); never what makes a record.
const signOf = flarePluginAmountSign;
// §5.8: on a ledger row (a signed amount) a success status means completed, which needs no Tag.
const ledgerStatus = (sign: "in" | "out" | undefined) => (status: ReturnType<typeof flarePluginStatusDraw>) =>
  !sign || status.unknown || status.tone !== "success";
// rules.rowsIcon: only a block with an icon draws its rows as records (the ledger line: value and Tags at the end);
// an icon the kit does not know falls back to the sign's glyph.
const recordIcon = (sign: "in" | "out" | undefined): FlareIconName =>
  props.block.icon && props.block.icon in flareIcons ? props.block.icon as FlareIconName
    : sign === "in" ? "arrow-down" : sign === "out" ? "send" : "refresh";
const items = computed(() =>
  rows.value.map((row, index) => ({
    row,
    // rules.rowTap: a row whose only action opens a page is that action's control (no key, a chevron at the end).
    tap: props.labelRows ? undefined : flarePluginRowTap(rowActions(row)),
    day: dayHeadings.value[index],
    // §12.24: rows are records only by the block's icon, never because the first cell is a signed amount.
    record: props.block.icon && props.layout === "list" && !props.labelRows
      ? flarePluginRecordLine(props.block, row, nowMs, props.strings, undefined, props.formatTime) : undefined,
    sign: signOf(row.cells[0]?.text),
    ...flarePluginRowLines(props.block, textRow(row), nowMs, props.strings, undefined, props.formatTime),
    statuses: row.cells.filter(toned).map((cell) => flarePluginStatusDraw(cell, warnAt(`rows:${props.block.source}`)))
      .filter(ledgerStatus(signOf(row.cells[0]?.text))),
    details: flarePluginRowTexts(
      props.block,
      textRow(row),
      nowMs,
      props.strings,
      undefined,
      props.formatTime,
    ).flatMap((value, index) =>
      index > 0 && value.trim()
        ? [{ label: props.block.columns[index]?.label ?? "", value }]
        : [],
    ),
    actions: !props.labelRows && flarePluginRowTap(rowActions(row)) ? [] : rowActions(row),
  })),
);

// ── cards: the first cell titles the card, the second describes it,
// the others are its details and the row's keys are its control ──────────
function currentCard(
  block: FlarePluginRowsBlock,
  row: FlarePluginRow,
): boolean {
  return (
    !props.busy &&
    !props.disabled &&
    !props.loading &&
    props.block === block &&
    rows.value.find((current) => current.key === row.key) === row
  );
}
const cards = computed(() =>
  props.block.presentation === "cards"
    ? rows.value.map((row) => {
        const block = props.block;
        const detailInput = row.detailInput;
        const detailSnapshot = JSON.stringify(detailInput);
        const [title = "", description, ...details] = flarePluginRowTexts(
          props.block,
          row,
          nowMs,
          props.strings,
          undefined,
          props.formatTime,
        );
        return {
          row,
          title,
          description,
          source:
            details.filter((text) => text.trim()).join(" · ") || undefined,
          open: () => {
            if (
              currentCard(block, row) &&
              detailInput !== undefined &&
              row.detailInput === detailInput &&
              JSON.stringify(detailInput) === detailSnapshot
            )
              emit("openRow", row);
          },
          actions: rowActions(row).map((entry) => {
            const inputSnapshot = JSON.stringify(entry.input);
            return {
              ...entry,
              run: () => {
                if (
                  !currentCard(block, row) ||
                  actionOf(entry.action.id) !== entry.action ||
                  !row.actions.some(
                    (current) =>
                      current.id === entry.action.id &&
                      current.input === entry.input,
                  ) ||
                  JSON.stringify(entry.input) !== inputSnapshot
                )
                  return;
                emit("rowAction", entry.action, row, entry.input);
              },
            };
          }),
        };
      })
    : null,
);
const cardsByKey = computed(
  () => new Map((cards.value ?? []).map((card) => [card.row.key, card])),
);
function cardFor(record: Record<string, unknown>) {
  const card = cardsByKey.value.get(String(record.id));
  return card ? [card] : [];
}
const loadMore = computed(() => {
  const block = props.block;
  const cursor = block.nextCursor;
  return () => {
    if (
      !cursor ||
      props.layout !== "admin-list" ||
      props.pagination ||
      props.busy ||
      props.disabled ||
      props.loading ||
      props.block !== block ||
      props.block.nextCursor !== cursor
    )
      return;
    emit("loadMore", cursor);
  };
});

// ── table ────────────────────────────────────────────────────────────────
const columns = computed(() =>
  props.block.columns.map((column, index) => ({
    key: `c${index}`,
    title: column.label,
    minWidth:
      index === 0
        ? 180
        : column.format === "time"
          ? 136
          : rows.value.some((row) => row.cells[index]?.user)
            ? 200
            : 120,
    ellipsis: false,
  })),
);
const tableRows = computed(() =>
  rows.value.map((row) => {
    const record: Record<string, unknown> = { id: row.key };
    props.block.columns.forEach((column, index) => {
      const cell = row.cells[index];
      record[`c${index}`] =
        column.format === "time" && typeof cell?.timeMs === "number"
          ? (props.formatTime?.(cell.timeMs) ??
            flarePluginDateTime(cell.timeMs, nowMs, props.strings))
          : (cell?.text ?? "");
    });
    return record;
  }),
);
const byKey = computed(() => new Map(rows.value.map((row) => [row.key, row])));
const hasActions = computed(() => rows.value.some((row) => row.actions.length));
const opens = computed(() =>
  rows.value.some((row) => row.detailInput !== undefined),
);
// The table is a row-click target only when some row opens a detail (it draws rows as controls then).
const rowListeners = computed(() =>
  opens.value ? { rowClick: onRowClick } : {},
);
function onRowClick(record: Record<string, unknown>): void {
  if (props.busy || props.disabled || props.loading) return;
  const row = byKey.value.get(String(record.id));
  if (row && row.detailInput !== undefined) emit("openRow", row);
}
</script>

<template>
  <div
    v-if="layout === 'list'"
    class="flare-plugin-rows flare-plugin-rows--list"
    :class="{ 'has-labels': labelRows }"
  >
    <ul v-if="items.length" class="flare-plugin-rows__list">
      <template v-for="(item, index) in items" :key="item.row.key">
      <li
        v-if="item.day"
        class="flare-plugin-rows__day"
        role="presentation"
        data-row-day="true"
      >{{ item.day }}</li>
      <li
        class="flare-plugin-rows__item"
        :class="{ 'is-single-action': item.actions.length === 1 && !labelRows, 'is-record': Boolean(item.record), 'is-tap': Boolean(item.tap) }"
        :data-row-key="item.row.key"
      >
        <!-- rules.rowTap: the row's content is its only action's button; any other row keeps a layout-neutral wrapper. -->
        <component
          :is="item.tap ? 'button' : 'div'"
          :class="item.tap ? 'flare-plugin-rows__tap' : 'flare-plugin-rows__body'"
          v-bind="item.tap ? { type: 'button', disabled: busy, 'aria-busy': spins(item.row, item.tap.action) || undefined, 'data-row-tap': item.tap.action.id } : {}"
          v-on="item.tap ? { click: () => emit('rowAction', item.tap!.action, item.row, item.tap!.input) } : {}"
        >
        <template v-if="item.record">
          <span class="flare-plugin-rows__icon" :class="item.sign && `is-${item.sign}`" aria-hidden="true" data-row-icon="true" :data-icon="recordIcon(item.sign)">
            <FlareIcon :name="recordIcon(item.sign)" size="md" />
          </span>
          <div class="flare-plugin-rows__main">
            <div class="flare-plugin-rows__primary">
              <span :id="`${rowId}-primary-${index}`" class="flare-plugin-rows__text is-title" data-row-title="true">{{ item.record.title }}</span>
              <FlareTag
                v-if="item.row.badge"
                class="flare-plugin-rows__badge"
                v-bind="badgeOf(item.row.badge)"
                data-row-badge="true"
              />
            </div>
            <p v-if="item.record.line" :id="`${rowId}-secondary-${index}`" class="flare-plugin-rows__secondary is-line" data-row-line="true">{{ item.record.line }}</p>
          </div>
          <div class="flare-plugin-rows__end">
            <span class="flare-plugin-rows__text is-amount" :class="item.sign && `is-${item.sign}`" data-row-value="true" data-row-primary="true">{{ flarePluginDisplayAmount(item.record.value) }}</span>
            <FlareTag
              v-for="(status, statusIndex) in item.statuses"
              :key="statusIndex"
              :label="status.unknown ? t('pluginView.unknownStatus') : status.text"
              :tone="status.tone"
              :data-tone="status.tone"
              :data-unknown="status.unknown ? 'true' : undefined"
              data-row-status="true"
            />
          </div>
        </template>
        <template v-else>
        <div class="flare-plugin-rows__main">
          <span
            v-if="labelRows && block.columns[0]?.label"
            class="flare-plugin-rows__primary-label"
            data-row-primary-label="true"
            >{{ block.columns[0].label }}</span
          >
          <div class="flare-plugin-rows__primary">
            <FlareTag
              v-if="item.row.badge"
              class="flare-plugin-rows__badge"
              v-bind="badgeOf(item.row.badge)"
              data-row-badge="true"
            />
            <span :id="`${rowId}-primary-${index}`" class="flare-plugin-rows__text" :class="item.sign && `is-amount is-${item.sign}`" data-row-primary="true">{{
              item.sign ? flarePluginDisplayAmount(item.primary) : item.primary
            }}</span>
          </div>
          <dl
            v-if="labelRows && item.details.length"
            class="flare-plugin-rows__details"
            data-row-details="true"
          >
            <div v-for="(field, index) in item.details" :key="index">
              <dt>{{ field.label }}</dt>
              <dd>{{ field.value }}</dd>
            </div>
          </dl>
          <p
            v-else-if="item.secondary && !labelRows"
            :id="`${rowId}-secondary-${index}`"
            class="flare-plugin-rows__secondary"
            data-row-secondary="true"
          >
            {{ item.secondary }}
          </p>
          <div v-if="item.statuses.length" class="flare-plugin-rows__statuses">
            <FlareTag
              v-for="(status, statusIndex) in item.statuses"
              :key="statusIndex"
              :label="status.unknown ? t('pluginView.unknownStatus') : status.text"
              :tone="status.tone"
              :data-tone="status.tone"
              :data-unknown="status.unknown ? 'true' : undefined"
              data-row-status="true"
            />
          </div>
        </div>
        </template>
        <template v-if="item.tap">
          <span v-if="spins(item.row, item.tap.action)" class="flare-plugin-rows__spinner" aria-hidden="true" data-row-spinner="true" />
          <FlareIcon v-else class="flare-plugin-rows__chevron" name="chevron-right" size="sm" aria-hidden="true" data-row-chevron="true" />
        </template>
        </component>
        <div v-if="item.actions.length" class="flare-plugin-rows__actions">
          <FlareButton
            v-for="entry in item.actions"
            :key="entry.action.id"
            size="sm"
            :variant="variantOf(entry.action)"
            :label="entry.action.label"
            :loading="spins(item.row, entry.action)"
            :disabled="busy"
            :data-row-action="entry.action.id"
            :aria-describedby="`${rowId}-primary-${index}${(item.record ? item.record.line : item.secondary) && !labelRows ? ` ${rowId}-secondary-${index}` : ''}`"
            @click="emit('rowAction', entry.action, item.row, entry.input)"
          />
        </div>
      </li>
      </template>
    </ul>
    <!-- R8: an empty data block is a compact empty state; the page puts its create action under it. -->
    <FlareEmptyState v-else-if="filters?.active()" class="flare-plugin-rows__empty" compact icon="search" :title="t('pluginView.filterEmpty')" data-rows-empty="true" data-rows-filter-empty="true">
      <template #actions>
        <FlareButton size="sm" variant="secondary" :label="t('pluginView.clearFilter')" data-rows-clear-filter="true" @click="filters?.clear()" />
      </template>
    </FlareEmptyState>
    <FlareEmptyState v-else class="flare-plugin-rows__empty" compact :icon="block.icon && block.icon in flareIcons ? block.icon : 'clock'" :title="block.emptyText || t('pluginView.empty')" data-rows-empty="true" />
  </div>
  <div
    v-else-if="layout === 'table' && cards"
    class="flare-plugin-rows flare-plugin-rows--cards"
  >
    <FlareAdminCardGrid v-if="cards.length" density="compact">
      <FlareAdminPolicyCard
        v-for="card in cards"
        :key="card.row.key"
        :title="card.title"
        :description="card.description"
        :source="card.source"
        :data-row-key="card.row.key"
      >
        <template
          v-if="card.actions.length || card.row.detailInput !== undefined"
          #control
        >
          <FlareButton
            v-if="card.row.detailInput !== undefined"
            size="sm"
            appearance="text"
            variant="secondary"
            :label="detailLabel ?? t('pluginView.detail')"
            :disabled="busy"
            data-row-detail="true"
            @click="emit('openRow', card.row)"
          />
          <FlareAdminRowActions
            v-if="card.actions.length"
            :actions="adminActions(card.row, card.actions, busy)"
            :max="ROW_ACTIONS_MAX"
            :label="card.title"
            @select="(key: string) => selectRowAction(card.row, key)"
          />
        </template>
      </FlareAdminPolicyCard>
    </FlareAdminCardGrid>
    <p v-else class="flare-plugin-rows__empty" data-rows-empty="true">
      {{ block.emptyText || t("pluginView.empty") }}
    </p>
    <FlareButton
      v-if="block.nextCursor"
      class="flare-plugin-rows__more"
      size="sm"
      variant="secondary"
      :label="t('pluginView.loadMore')"
      :disabled="busy"
      data-rows-load-more="true"
      @click="emit('loadMore', block.nextCursor)"
    />
  </div>
  <div
    v-else
    class="flare-plugin-rows"
    :class="{ 'flare-plugin-rows--admin-list': layout === 'admin-list', 'flare-plugin-rows--embedded': embedded }"
  >
    <component
      :is="layout === 'admin-list' ? FlareAdminList : FlareDataTable"
      v-bind="tableProps"
      :columns="columns"
      :rows="tableRows"
      :empty-text="block.emptyText"
      v-model:visible-column-keys="visibleColumnKeys"
      v-model:expanded-row-keys="expandedRowKeys"
      v-on="rowListeners"
      @search="emit('search')"
      @reset="emit('reset')"
      @update:pagination="emit('update:pagination', $event)"
    >
      <template v-for="name in controlSlots" :key="name" #[name]
        ><slot :name="name"
      /></template>
      <template v-if="layout === 'admin-list' && slots['expanded-row']" #expanded-row="{ row }">
        <slot name="expanded-row" :row="byKey.get(String(row.id))!" />
      </template>
      <template v-if="layout === 'admin-list' && cards" #item="item">
        <FlareAdminPolicyCard
          v-for="card in cardFor(item.row)"
          :key="card.row.key"
          :title="card.title"
          :description="card.description"
          :source="card.source"
          :data-row-key="card.row.key"
        >
          <template
            v-if="card.actions.length || card.row.detailInput !== undefined"
            #control
          >
            <FlareButton
              v-if="card.row.detailInput !== undefined"
              size="sm"
              appearance="text"
              variant="secondary"
              :label="detailLabel ?? t('pluginView.detail')"
              :disabled="'disabled' in item ? item.disabled : true"
              data-row-detail="true"
              @click="card.open"
            />
            <FlareAdminRowActions
              v-if="card.actions.length"
              :actions="
                adminActions(
                  card.row,
                  card.actions,
                  'disabled' in item ? !!item.disabled : true,
                )
              "
              :max="ROW_ACTIONS_MAX"
              :label="card.title"
              @select="
                (key: string) =>
                  card.actions.find((entry) => entry.action.id === key)?.run()
              "
            />
          </template>
        </FlareAdminPolicyCard>
      </template>
      <template v-if="layout === 'admin-list' && !adminContent && !pagination && !embedded" #footer-summary>
        {{ t("dataTable.loadedItems", { count: rows.length }) }}
      </template>
      <template
        v-if="layout === 'admin-list' && !adminContent && !pagination && block.nextCursor"
        #footer-extra
      >
        <FlareButton
          size="sm"
          variant="secondary"
          :label="t('pluginView.loadMore')"
          :disabled="busy || disabled || loading"
          data-rows-load-more="true"
          @click="loadMore"
        />
      </template>
      <template
        v-for="(_column, index) in block.columns"
        :key="index"
        #[`cell-c${index}`]="{ row, value }"
      >
        <span class="flare-plugin-rows__cell">
          <FlareTag
            v-if="index === 0 && byKey.get(String(row.id))?.badge"
            :label="byKey.get(String(row.id))!.badge!.text"
            :tone="flarePluginBadgeTone(byKey.get(String(row.id))!.badge!.tone)"
            data-row-badge="true"
          />
          <FlareUserIdentity
            v-if="byKey.get(String(row.id))?.cells[index]?.user"
            :user="byKey.get(String(row.id))!.cells[index]!.user!"
          />
          <span v-else>{{ value }}</span>
        </span>
      </template>
      <template v-if="hasActions || opens" #row-actions="{ row }">
        <FlareButton
          v-if="byKey.get(String(row.id))?.detailInput !== undefined"
          size="sm"
          appearance="text"
          variant="secondary"
          :label="detailLabel ?? t('pluginView.detail')"
          :disabled="busy"
          data-row-detail="true"
          @click="onRowClick(row)"
        />
        <FlareAdminRowActions
          v-if="rowActions(byKey.get(String(row.id))!).length"
          :actions="
            adminActions(
              byKey.get(String(row.id))!,
              rowActions(byKey.get(String(row.id))!),
              busy,
            )
          "
          :max="ROW_ACTIONS_MAX"
          :label="rowName(byKey.get(String(row.id))!)"
          @select="
            (key: string) => selectRowAction(byKey.get(String(row.id))!, key)
          "
        />
      </template>
    </component>
    <FlareButton
      v-if="block.nextCursor && layout !== 'admin-list'"
      class="flare-plugin-rows__more"
      size="sm"
      variant="secondary"
      :label="t('pluginView.loadMore')"
      :disabled="busy"
      data-rows-load-more="true"
      @click="emit('loadMore', block.nextCursor)"
    />
  </div>
</template>

<style scoped>
.flare-plugin-rows {
  display: grid;
  gap: var(--flare-size-spacing-md);
  justify-items: center;
  min-width: 0;
}
.flare-plugin-rows > :first-child {
  width: 100%;
}
.flare-plugin-rows--admin-list {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  align-items: stretch;
}
.flare-plugin-rows--admin-list > .flare-admin-list:not(.flare-admin-list--embedded) {
  flex: 1;
  min-height: 0;
}
.flare-plugin-rows--admin-list.flare-plugin-rows--embedded {
  flex: none;
}
.flare-plugin-rows__cell {
  display: inline-flex;
  flex-wrap: wrap;
  overflow-wrap: anywhere;
  white-space: normal;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-plugin-rows--list {
  display: block;
  container-type: inline-size;
  container-name: flare-plugin-records;
}
.flare-plugin-rows__list {
  display: grid;
  width: 100%;
  margin: 0;
  padding: 0;
  list-style: none;
}
/* Day headings stay visible while their records scroll under them (§5.8). */
.flare-plugin-rows__day {
  position: sticky;
  top: 0;
  z-index: 1;
  background: var(--flare-color-bg-primary);
  padding-block: var(--flare-size-spacing-sm) var(--flare-size-spacing-xs);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-rows__day:first-child {
  padding-top: 0;
}
.flare-plugin-rows__item {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  padding: var(--flare-size-spacing-sm) 0;
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-plugin-rows__item:first-child {
  padding-top: 0;
}
/* §5.8: a record line is 64 high (36 icon, title 15, line 12, amount 16). */
.flare-plugin-rows__item.is-record { min-height: var(--flare-size-component-record-row-height); box-sizing: border-box; }
.flare-plugin-rows__item:last-child {
  padding-bottom: 0;
  border-bottom: 0;
}
/* rules.rowTap: a non-tap row's wrapper leaves the item's layout as it was. */
.flare-plugin-rows__body { display: contents; }
.flare-plugin-rows__tap {
  flex: 1 1 auto;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  margin: 0;
  padding: 0;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  text-align: start;
  cursor: pointer;
}
.flare-plugin-rows__tap:disabled { cursor: default; }
.flare-plugin-rows__tap:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; border-radius: var(--flare-size-radius-sm); }
.flare-plugin-rows__chevron { flex: none; color: var(--flare-color-text-tertiary); }
.flare-plugin-rows__spinner {
  flex: none;
  box-sizing: border-box;
  width: var(--flare-size-icon-size-sm);
  height: var(--flare-size-icon-size-sm);
  border: 2px solid var(--flare-color-text-tertiary);
  border-top-color: transparent;
  border-radius: var(--flare-size-radius-full);
  animation: flare-plugin-rows-spin 0.7s linear infinite;
}
@media (prefers-reduced-motion: reduce) { .flare-plugin-rows__spinner { animation: none; } }
@keyframes flare-plugin-rows-spin { to { transform: rotate(360deg); } }
.flare-plugin-rows__main {
  flex: 1 1 auto;
  display: grid;
  gap: var(--flare-size-spacing-2xs);
  min-width: 0;
}
.flare-plugin-rows__primary {
  display: flex;
  align-items: baseline;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-plugin-rows__primary-label {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-rows__badge {
  flex: none;
  max-width: 50%;
}
.flare-plugin-rows__text {
  min-width: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-primary);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-plugin-rows__text.is-amount {
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-semibold);
}
.flare-plugin-rows__text.is-in { color: var(--flare-color-success-text); }
.flare-plugin-rows__icon {
  flex: none;
  display: grid;
  place-items: center;
  width: var(--flare-size-component-record-icon-size);
  height: var(--flare-size-component-record-icon-size);
  border-radius: var(--flare-size-radius-full);
  /* bg.tertiary, as the Flutter kit: bg.secondary vanishes on a page body that is bg.secondary itself (red packet records). */
  background: var(--flare-color-bg-tertiary);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-rows__icon.is-in {
  background: color-mix(in srgb, var(--flare-color-success) calc(var(--flare-opacity-tint-weak) * 100%), var(--flare-color-bg-primary));
  color: var(--flare-color-success-text);
}
.flare-plugin-rows__text.is-title { font-size: var(--flare-size-font-size-xl); overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
.flare-plugin-rows__secondary.is-line { color: var(--flare-color-text-tertiary); }
/* rules.rowsIcon: the record's value at the end, its status Tags under it. */
.flare-plugin-rows__end {
  flex: none;
  display: grid;
  justify-items: end;
  gap: var(--flare-size-spacing-3xs);
  max-width: 50%;
  text-align: end;
}
.flare-plugin-rows__secondary {
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-plugin-rows__details {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  margin: var(--flare-size-spacing-sm) 0 0;
  font-size: var(--flare-size-font-size-sm);
}
.flare-plugin-rows__details > div {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 2fr);
  gap: var(--flare-size-spacing-md);
}
.flare-plugin-rows__details dt {
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-plugin-rows__details dd {
  margin: 0;
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
  font-variant-numeric: tabular-nums;
}
.flare-plugin-rows.has-labels .flare-plugin-rows__item {
  align-items: stretch;
  flex-direction: column;
}
.flare-plugin-rows.has-labels .flare-plugin-rows__actions {
  align-self: flex-end;
  max-width: 100%;
}
.flare-plugin-rows__actions {
  flex: none;
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-xs);
}
.flare-plugin-rows__empty {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-tertiary);
}
/* A narrow detail drawer needs the same reading width as a phone. Keep row
   actions below the record rather than letting two long labels squeeze it. */
@container flare-plugin-records (max-width: 560px) {
  .flare-plugin-rows__item {
    flex-direction: column;
    align-items: stretch;
  }
  .flare-plugin-rows__item > .flare-plugin-rows__actions {
    align-self: stretch;
    justify-content: flex-start;
    max-width: 100%;
  }
  .flare-plugin-rows__item.is-single-action,
  .flare-plugin-rows__item.is-record {
    flex-direction: row;
    align-items: center;
  }
  .flare-plugin-rows__item.is-single-action > .flare-plugin-rows__actions {
    align-self: center;
    flex: none;
  }
  .flare-plugin-rows__item.is-single-action > .flare-plugin-rows__actions :deep(button) {
    min-height: var(--flare-size-layout-touch-target-min);
  }
}
.flare-plugin-rows__statuses { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-xs); margin-top: var(--flare-size-spacing-3xs); }
</style>
