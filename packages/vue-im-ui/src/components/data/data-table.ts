/**
 * The host-owned contract of FlareDataTable and the pure rules it draws from: which columns show,
 * what the next sort is, how many pages there are, what the header checkbox means. Nothing here
 * touches the DOM, so every rule is a unit-tested function and the component only maps them onto
 * headers, rows and controls.
 */

export type FlareDataTableAlign = "start" | "center" | "end";
export type FlareDataTableSortOrder = "asc" | "desc";
export type FlareDataTableRow = Record<string, unknown>;

export interface FlareDataTableColumn {
  /** Field of the row this column reads; also names the `cell-<key>` slot. */
  key: string;
  /** Header text. */
  title: string;
  /** Fixed width (a number is px). */
  width?: number | string;
  /** Lower bound when the table shares the space out. */
  minWidth?: number | string;
  /** Draws a sort control in the header; the host sorts and passes `sort` back. */
  sortable?: boolean;
  /** Horizontal alignment of the header and the cells. Default `start`. */
  align?: FlareDataTableAlign;
  /** Keep the cell on one line and cut it with an ellipsis; the full text stays in `title`. */
  ellipsis?: boolean;
  /** Slot that renders this column's cells. Default `cell-<key>`. */
  slot?: string;
  /** False keeps the column out of the column chooser: it is always visible. Default true. */
  hideable?: boolean;
}

export interface FlareDataTableSort {
  key: string;
  order: FlareDataTableSortOrder;
}

export interface FlareDataTablePagination {
  /** 1-based current page. */
  page: number;
  pageSize: number;
  /** Rows on the server, not on this page. */
  total: number;
  /** Page sizes the person may pick; omitted draws no page-size control. */
  pageSizes?: readonly number[];
}

export type FlareDataTableSelection = "none" | "some" | "all";

/** The key a row is identified by: a field name, or the host's own function. */
export function dataTableRowKey(
  row: FlareDataTableRow,
  rowKey: string | ((row: FlareDataTableRow, index: number) => string),
  index: number,
): string {
  if (typeof rowKey === "function") return String(rowKey(row, index));
  const value = row[rowKey];
  return value === undefined || value === null ? String(index) : String(value);
}

/** Activating a sortable header cycles ascending, descending, then back to the host's default order. */
export function dataTableNextSort(current: FlareDataTableSort | null | undefined, key: string): FlareDataTableSort | null {
  if (!current || current.key !== key) return { key, order: "asc" };
  if (current.order === "asc") return { key, order: "desc" };
  return null;
}

/** `aria-sort` of a header: only sortable columns carry it, and only one column is sorted. */
export function dataTableAriaSort(
  sort: FlareDataTableSort | null | undefined,
  column: FlareDataTableColumn,
): "ascending" | "descending" | "none" | undefined {
  if (!column.sortable) return undefined;
  if (!sort || sort.key !== column.key) return "none";
  return sort.order === "asc" ? "ascending" : "descending";
}

export function dataTablePageCount(pagination: FlareDataTablePagination): number {
  const size = Math.max(1, Math.floor(pagination.pageSize));
  return Math.max(1, Math.ceil(Math.max(0, pagination.total) / size));
}

/** 1-based inclusive bounds of the rows on this page; `{ from: 0, to: 0 }` when there are none. */
export function dataTableRange(pagination: FlareDataTablePagination): { from: number; to: number } {
  const total = Math.max(0, pagination.total);
  if (total === 0) return { from: 0, to: 0 };
  const size = Math.max(1, Math.floor(pagination.pageSize));
  const page = Math.min(Math.max(1, pagination.page), dataTablePageCount(pagination));
  const from = (page - 1) * size + 1;
  return { from, to: Math.min(total, from + size - 1) };
}

/**
 * The columns to draw, in the host's column order. `visible` is the chooser's list of keys;
 * `null` (nothing chosen yet) shows every column. A column that cannot be hidden is always in.
 */
export function dataTableVisibleColumns(
  columns: readonly FlareDataTableColumn[],
  visible: readonly string[] | null | undefined,
): FlareDataTableColumn[] {
  if (!visible) return [...columns];
  const chosen = new Set(visible);
  return columns.filter((column) => column.hideable === false || chosen.has(column.key));
}

/**
 * The chooser's next list after one column is switched. The last visible column and a column
 * that cannot be hidden stay: a table with no columns is not a state a person can recover from.
 */
export function dataTableToggleColumn(
  columns: readonly FlareDataTableColumn[],
  visible: readonly string[] | null | undefined,
  key: string,
  on: boolean,
): string[] {
  const shown = new Set(dataTableVisibleColumns(columns, visible).map((column) => column.key));
  const column = columns.find((entry) => entry.key === key);
  if (!column) return [...shown];
  if (on) shown.add(key);
  else if (column.hideable !== false && shown.size > 1) shown.delete(key);
  return columns.filter((entry) => shown.has(entry.key)).map((entry) => entry.key);
}

/** What the header checkbox means for the rows on this page. */
export function dataTableSelection(pageKeys: readonly string[], selected: readonly string[]): FlareDataTableSelection {
  if (pageKeys.length === 0) return "none";
  const chosen = new Set(selected);
  const count = pageKeys.reduce((sum, key) => sum + (chosen.has(key) ? 1 : 0), 0);
  if (count === 0) return "none";
  return count === pageKeys.length ? "all" : "some";
}

/**
 * The header checkbox: every row of this page selected clears them; otherwise it adds the missing
 * ones. Keys from other pages are kept either way — a selection spans pages.
 */
export function dataTableToggleAll(pageKeys: readonly string[], selected: readonly string[]): string[] {
  const page = new Set(pageKeys);
  if (dataTableSelection(pageKeys, selected) === "all") return selected.filter((key) => !page.has(key));
  const chosen = new Set(selected);
  return [...selected, ...pageKeys.filter((key) => !chosen.has(key))];
}

export function dataTableToggleRow(key: string, selected: readonly string[], on: boolean): string[] {
  const has = selected.includes(key);
  if (on === has) return [...selected];
  return on ? [...selected, key] : selected.filter((entry) => entry !== key);
}

/** The default cell: a value as text, nothing for a missing one (never "null" or "undefined"). */
export function dataTableCellText(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "object") return JSON.stringify(value);
  return String(value);
}
