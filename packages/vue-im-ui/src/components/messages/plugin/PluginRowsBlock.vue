<script setup lang="ts">
import { computed, useSlots } from "vue";
import FlareAdminList from "../../data/FlareAdminList.vue";
import type { FlareAdminPagination } from "../../data/admin-list";
import FlareUserIdentity from "../../data/FlareUserIdentity.vue";
import FlareDataTable from "../../data/FlareDataTable.vue";
import FlareAdminCardGrid from "../../data/FlareAdminCardGrid.vue";
import FlareAdminPolicyCard from "../../data/FlareAdminPolicyCard.vue";
import FlareButton from "../../general/FlareButton.vue";
import FlareTag from "../../general/FlareTag.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import { flareServerNowMs } from "../../../shared/server-clock";
import {
  flarePluginBadgeTone,
  flarePluginDateTime,
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
    loading?: boolean;
    disabled?: boolean;
    error?: string;
    filtersInvalid?: boolean;
    pagination?: FlareAdminPagination;
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
  ].filter((name) => !!slots[name]),
);
const { t } = useFlareI18nOptional();
const tableProps = computed(() =>
  props.layout === "admin-list"
    ? {
        label: props.adminLabel || t("pluginView.detail"),
        rowKey: "id",
        loading: props.loading,
        disabled: props.disabled || props.busy,
        error: props.error,
        errorPresentation: "neutral" as const,
        pagination: props.pagination,
        filtersInvalid: props.filtersInvalid,
        layout:
          props.block.presentation === "cards"
            ? ("cards" as const)
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

// ── list ─────────────────────────────────────────────────────────────────
const items = computed(() =>
  rows.value.map((row) => ({
    row,
    ...flarePluginRowLines(props.block, row, nowMs, props.strings),
    details: flarePluginRowTexts(
      props.block,
      row,
      nowMs,
      props.strings,
    ).flatMap((value, index) =>
      index > 0 && value.trim()
        ? [{ label: props.block.columns[index]?.label ?? "", value }]
        : [],
    ),
    actions: rowActions(row),
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
          ? flarePluginDateTime(cell.timeMs, nowMs, props.strings)
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
      <li
        v-for="item in items"
        :key="item.row.key"
        class="flare-plugin-rows__item"
        :data-row-key="item.row.key"
      >
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
              :label="item.row.badge.text"
              :tone="flarePluginBadgeTone(item.row.badge.tone)"
              data-row-badge="true"
            />
            <span class="flare-plugin-rows__text" data-row-primary="true">{{
              item.primary
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
            class="flare-plugin-rows__secondary"
            data-row-secondary="true"
          >
            {{ item.secondary }}
          </p>
        </div>
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
            @click="emit('rowAction', entry.action, item.row, entry.input)"
          />
        </div>
      </li>
    </ul>
    <p v-else class="flare-plugin-rows__empty" data-rows-empty="true">
      {{ block.emptyText || t("pluginView.empty") }}
    </p>
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
            :label="t('pluginView.detail')"
            :disabled="busy"
            data-row-detail="true"
            @click="emit('openRow', card.row)"
          />
          <FlareButton
            v-for="entry in card.actions"
            :key="entry.action.id"
            size="sm"
            appearance="text"
            :variant="variantOf(entry.action)"
            :label="entry.action.label"
            :loading="spins(card.row, entry.action)"
            :disabled="busy"
            :data-row-action="entry.action.id"
            @click="emit('rowAction', entry.action, card.row, entry.input)"
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
    :class="{ 'flare-plugin-rows--admin-list': layout === 'admin-list' }"
  >
    <component
      :is="layout === 'admin-list' ? FlareAdminList : FlareDataTable"
      v-bind="tableProps"
      :columns="columns"
      :rows="tableRows"
      :empty-text="block.emptyText"
      v-model:visible-column-keys="visibleColumnKeys"
      v-on="rowListeners"
      @search="emit('search')"
      @reset="emit('reset')"
      @update:pagination="emit('update:pagination', $event)"
    >
      <template v-for="name in controlSlots" :key="name" #[name]
        ><slot :name="name"
      /></template>
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
              :label="t('pluginView.detail')"
              :disabled="'disabled' in item ? item.disabled : true"
              data-row-detail="true"
              @click="card.open"
            />
            <FlareButton
              v-for="entry in card.actions"
              :key="entry.action.id"
              size="sm"
              appearance="text"
              :variant="variantOf(entry.action)"
              :label="entry.action.label"
              :loading="spins(card.row, entry.action)"
              :disabled="'disabled' in item ? item.disabled : true"
              :data-row-action="entry.action.id"
              @click="entry.run"
            />
          </template>
        </FlareAdminPolicyCard>
      </template>
      <template v-if="layout === 'admin-list' && !pagination" #footer-summary>
        {{ t("dataTable.loadedItems", { count: rows.length }) }}
      </template>
      <template
        v-if="layout === 'admin-list' && !pagination && block.nextCursor"
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
          :label="t('pluginView.detail')"
          :disabled="busy"
          data-row-detail="true"
          @click="onRowClick(row)"
        />
        <template
          v-for="entry in rowActions(byKey.get(String(row.id))!)"
          :key="entry.action.id"
        >
          <FlareButton
            size="sm"
            appearance="text"
            :variant="variantOf(entry.action)"
            :label="entry.action.label"
            :loading="spins(byKey.get(String(row.id))!, entry.action)"
            :disabled="busy"
            :data-row-action="entry.action.id"
            @click="
              emit(
                'rowAction',
                entry.action,
                byKey.get(String(row.id))!,
                entry.input,
              )
            "
          />
        </template>
      </template>
    </component>
    <FlareButton
      v-if="block.nextCursor && layout !== 'admin-list'"
      class="flare-plugin-rows__more"
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
.flare-plugin-rows--admin-list > .flare-admin-list {
  flex: 1;
  min-height: 0;
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
}
.flare-plugin-rows__list {
  display: grid;
  width: 100%;
  margin: 0;
  padding: 0;
  list-style: none;
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
.flare-plugin-rows__item:last-child {
  padding-bottom: 0;
  border-bottom: 0;
}
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
</style>
