<script setup lang="ts">
import { computed } from "vue";
import FlareDataTable from "../../data/FlareDataTable.vue";
import FlareButton from "../../general/FlareButton.vue";
import FlareTag from "../../general/FlareTag.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import {
  flarePluginBadgeTone,
  flarePluginDateTime,
  flarePluginRowLines,
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
const props = withDefaults(defineProps<{
  block: FlarePluginRowsBlock;
  strings: FlarePluginStrings;
  busy: boolean;
  busyActionId?: string;
  /** The row whose action is in flight: only its key spins (the others wait through `busy`). */
  busyRow?: string | null;
  layout?: FlarePluginRowsLayout;
}>(), { busyActionId: undefined, busyRow: null, layout: "table" });
const emit = defineEmits<{
  (e: "rowAction", action: FlarePluginAction, row: FlarePluginRow, input: unknown): void;
  (e: "openRow", row: FlarePluginRow): void;
  (e: "loadMore", cursor: string): void;
}>();
const { t } = useFlareI18nOptional();

const nowMs = Date.now();
const rows = computed(() => flarePluginRowsOnce(props.block.rows));
const actionOf = (id: string) => props.block.actions.find((action) => action.id === id);
const spins = (row: FlarePluginRow, action: FlarePluginAction) => props.busyActionId === action.id && props.busyRow === row.key;
const variantOf = (action: FlarePluginAction) => (action.style === "danger" ? "danger" : action.style === "primary" ? "primary" : "secondary");
/** The row's actions the block declares, with the input the view bound for each. */
const rowActions = (row: FlarePluginRow) => row.actions.flatMap((ra) => {
  const action = actionOf(ra.id);
  return action ? [{ action, input: ra.input }] : [];
});

// ── list ─────────────────────────────────────────────────────────────────
const items = computed(() => rows.value.map((row) => ({ row, ...flarePluginRowLines(props.block, row, nowMs, props.strings), actions: rowActions(row) })));

// ── table ────────────────────────────────────────────────────────────────
const columns = computed(() => props.block.columns.map((column, index) => ({ key: `c${index}`, title: column.label })));
const tableRows = computed(() => rows.value.map((row) => {
  const record: Record<string, unknown> = { id: row.key };
  props.block.columns.forEach((column, index) => {
    const cell = row.cells[index];
    record[`c${index}`] = column.format === "time" && typeof cell?.timeMs === "number"
      ? flarePluginDateTime(cell.timeMs, nowMs, props.strings)
      : cell?.text ?? "";
  });
  return record;
}));
const byKey = computed(() => new Map(rows.value.map((row) => [row.key, row])));
const hasActions = computed(() => rows.value.some((row) => row.actions.length));
const hasBadges = computed(() => rows.value.some((row) => row.badge));
const opens = computed(() => rows.value.some((row) => row.detailInput !== undefined));
// The table is a row-click target only when some row opens a detail (it draws rows as controls then).
const rowListeners = computed(() => (opens.value ? { rowClick: onRowClick } : {}));
function onRowClick(record: Record<string, unknown>): void {
  const row = byKey.value.get(String(record.id));
  if (row && row.detailInput !== undefined) emit("openRow", row);
}
</script>

<template>
  <div v-if="layout === 'list'" class="flare-plugin-rows flare-plugin-rows--list">
    <ul v-if="items.length" class="flare-plugin-rows__list">
      <li v-for="item in items" :key="item.row.key" class="flare-plugin-rows__item" :data-row-key="item.row.key">
        <div class="flare-plugin-rows__main">
          <div class="flare-plugin-rows__primary">
            <FlareTag
              v-if="item.row.badge"
              class="flare-plugin-rows__badge"
              :label="item.row.badge.text"
              :tone="flarePluginBadgeTone(item.row.badge.tone)"
              data-row-badge="true"
            />
            <span class="flare-plugin-rows__text" data-row-primary="true">{{ item.primary }}</span>
          </div>
          <p v-if="item.secondary" class="flare-plugin-rows__secondary" data-row-secondary="true">{{ item.secondary }}</p>
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
    <p v-else class="flare-plugin-rows__empty" data-rows-empty="true">{{ block.emptyText || t("pluginView.empty") }}</p>
  </div>
  <div v-else class="flare-plugin-rows">
    <FlareDataTable
      :columns="columns"
      :rows="tableRows"
      :empty-text="block.emptyText"
      density="compact"
      v-on="rowListeners"
    >
      <template v-if="hasBadges" #cell-c0="{ row, value }">
        <span class="flare-plugin-rows__cell">
          <FlareTag
            v-if="byKey.get(String(row.id))?.badge"
            :label="byKey.get(String(row.id))!.badge!.text"
            :tone="flarePluginBadgeTone(byKey.get(String(row.id))!.badge!.tone)"
            data-row-badge="true"
          />
          <span>{{ value }}</span>
        </span>
      </template>
      <template v-if="hasActions" #row-actions="{ row }">
        <template v-for="entry in rowActions(byKey.get(String(row.id))!)" :key="entry.action.id">
          <FlareButton
            size="sm"
            :variant="variantOf(entry.action)"
            :label="entry.action.label"
            :loading="spins(byKey.get(String(row.id))!, entry.action)"
            :disabled="busy"
            :data-row-action="entry.action.id"
            @click="emit('rowAction', entry.action, byKey.get(String(row.id))!, entry.input)"
          />
        </template>
      </template>
    </FlareDataTable>
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
</template>

<style scoped>
.flare-plugin-rows { display: grid; gap: var(--flare-size-spacing-md); justify-items: center; min-width: 0; }
.flare-plugin-rows > :first-child { width: 100%; }
.flare-plugin-rows__cell { display: inline-flex; align-items: baseline; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-rows--list { display: block; }
.flare-plugin-rows__list { display: grid; width: 100%; margin: 0; padding: 0; list-style: none; }
.flare-plugin-rows__item {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  padding: var(--flare-size-spacing-sm) 0;
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-plugin-rows__item:first-child { padding-top: 0; }
.flare-plugin-rows__item:last-child { padding-bottom: 0; border-bottom: 0; }
.flare-plugin-rows__main { flex: 1 1 auto; display: grid; gap: var(--flare-size-spacing-2xs); min-width: 0; }
.flare-plugin-rows__primary { display: flex; align-items: baseline; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-rows__badge { flex: none; max-width: 50%; }
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
.flare-plugin-rows__actions { flex: none; display: flex; flex-wrap: wrap; justify-content: flex-end; gap: var(--flare-size-spacing-xs); }
.flare-plugin-rows__empty { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-tertiary); }
</style>
