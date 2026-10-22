<script setup lang="ts">
import { computed } from "vue";
import FlareDataTable from "../../data/FlareDataTable.vue";
import FlareButton from "../../general/FlareButton.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import {
  flarePluginDateTime,
  type FlarePluginAction,
  type FlarePluginRow,
  type FlarePluginRowsBlock,
  type FlarePluginStrings,
} from "../../../shared/contracts/plugin-ui";

// The rows of an admin page (console plugin centre), on the kit DataTable: the columns, time cells in
// the device zone, each row's actions, a row click for the row's detail, "load more" for the next page
// and the empty text. Vue only: admin pages are web.
const props = defineProps<{
  block: FlarePluginRowsBlock;
  strings: FlarePluginStrings;
  busy: boolean;
  busyActionId?: string;
}>();
const emit = defineEmits<{
  (e: "rowAction", action: FlarePluginAction, row: FlarePluginRow, input: unknown): void;
  (e: "openRow", row: FlarePluginRow): void;
  (e: "loadMore", cursor: string): void;
}>();
const { t } = useFlareI18nOptional();

const columns = computed(() => props.block.columns.map((column, index) => ({ key: `c${index}`, title: column.label })));
const nowMs = Date.now();
const tableRows = computed(() => props.block.rows.map((row) => {
  const record: Record<string, unknown> = { id: row.key };
  props.block.columns.forEach((column, index) => {
    const cell = row.cells[index];
    record[`c${index}`] = column.format === "time" && typeof cell?.timeMs === "number"
      ? flarePluginDateTime(cell.timeMs, nowMs, props.strings)
      : cell?.text ?? "";
  });
  return record;
}));
const byKey = computed(() => new Map(props.block.rows.map((row) => [row.key, row])));
const actionOf = (id: string) => props.block.actions.find((action) => action.id === id);
const hasActions = computed(() => props.block.rows.some((row) => row.actions.length));
const opens = computed(() => props.block.rows.some((row) => row.detailInput !== undefined));
const variantOf = (action: FlarePluginAction) => (action.style === "danger" ? "danger" : action.style === "primary" ? "primary" : "secondary");
// The table is a row-click target only when some row opens a detail (it draws rows as controls then).
const rowListeners = computed(() => (opens.value ? { rowClick: onRowClick } : {}));
function onRowClick(record: Record<string, unknown>): void {
  const row = byKey.value.get(String(record.id));
  if (row && row.detailInput !== undefined) emit("openRow", row);
}
</script>

<template>
  <div class="flare-plugin-rows">
    <FlareDataTable
      :columns="columns"
      :rows="tableRows"
      :empty-text="block.emptyText"
      density="compact"
      v-on="rowListeners"
    >
      <template v-if="hasActions" #row-actions="{ row }">
        <template v-for="rowAction in byKey.get(String(row.id))?.actions ?? []" :key="rowAction.id">
          <FlareButton
            v-if="actionOf(rowAction.id)"
            size="sm"
            :variant="variantOf(actionOf(rowAction.id)!)"
            :label="actionOf(rowAction.id)?.label"
            :loading="busyActionId === rowAction.id"
            :disabled="busy"
            :data-row-action="rowAction.id"
            @click="emit('rowAction', actionOf(rowAction.id)!, byKey.get(String(row.id))!, rowAction.input)"
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
</style>
