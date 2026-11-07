<script lang="ts">
export interface FlareAdminHeatAxis {
  key: string;
  label: string;
}
export type FlareAdminHeatTone = "good" | "warn" | "bad";
export interface FlareAdminHeatCell {
  row: string;
  column: string;
  /** The reading in words; the tint never carries it alone. */
  text: string;
  tone: FlareAdminHeatTone;
  /** A longer reading for the cell's tooltip: sample size, latency. */
  detail?: string;
}
</script>

<script setup lang="ts">
/**
 * A reading per row and column, tinted by how good it is: availability by access point and probe
 * site, for example. The host computes every reading and its tone. A pair with no cell is drawn as
 * `emptyText` in a neutral cell, never as a zero. It is a real table, so a screen reader announces
 * the row and column of each reading.
 */
import { computed } from "vue";

const props = defineProps<{
  /** Names the table for assistive technology. */
  label: string;
  /** Heading of the row-label column. */
  rowHeader: string;
  rows: readonly FlareAdminHeatAxis[];
  columns: readonly FlareAdminHeatAxis[];
  cells: readonly FlareAdminHeatCell[];
  emptyText: string;
}>();
const byPair = computed(
  () => new Map(props.cells.map((cell) => [JSON.stringify([cell.row, cell.column]), cell])),
);
const cellOf = (row: string, column: string) => byPair.value.get(JSON.stringify([row, column]));
</script>

<template>
  <div class="flare-admin-heat-grid">
    <table class="flare-admin-heat-grid__table" :aria-label="label">
      <thead>
        <tr>
          <th scope="col" class="flare-admin-heat-grid__corner">{{ rowHeader }}</th>
          <th v-for="column in columns" :key="column.key" scope="col">{{ column.label }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="row in rows" :key="row.key">
          <th scope="row">{{ row.label }}</th>
          <td
            v-for="column in columns"
            :key="column.key"
            :class="
              cellOf(row.key, column.key)
                ? `flare-admin-heat-grid__cell--${cellOf(row.key, column.key)!.tone}`
                : 'flare-admin-heat-grid__cell--empty'
            "
            :title="cellOf(row.key, column.key)?.detail"
          >
            {{ cellOf(row.key, column.key)?.text ?? emptyText }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
.flare-admin-heat-grid {
  min-width: 0;
  overflow-x: auto;
}
.flare-admin-heat-grid__table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 2px;
  font-size: var(--flare-text-caption-font-size);
  color: var(--flare-color-text-primary);
}
.flare-admin-heat-grid__table th {
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  font-weight: var(--flare-size-font-weight-medium);
  text-align: start;
  white-space: nowrap;
  color: var(--flare-color-text-secondary);
}
.flare-admin-heat-grid__table tbody th {
  position: sticky;
  inset-inline-start: 0;
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-admin-heat-grid__table td {
  min-width: 72px;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-xs);
  text-align: center;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
.flare-admin-heat-grid__cell--good {
  background: color-mix(in srgb, var(--flare-color-success) 18%, transparent);
}
.flare-admin-heat-grid__cell--warn {
  background: color-mix(in srgb, var(--flare-color-warning) 24%, transparent);
}
.flare-admin-heat-grid__cell--bad {
  background: color-mix(in srgb, var(--flare-color-error) 24%, transparent);
}
.flare-admin-heat-grid__cell--empty {
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-tertiary);
}
</style>
