import type { DataTableBaseColumn } from "naive-ui";

/** Flat operational columns; render functions remain owned by the host business page. */
export type FlareAdminColumn = Omit<DataTableBaseColumn, "align"> & {
  hideable?: boolean;
  slot?: string;
  align?: "left" | "right" | "center" | "start" | "end";
};
export interface FlareAdminPagination {
  page: number;
  pageSize: number;
  total?: number;
  /** A bounded loaded snapshot is not an authoritative server-wide total. */
  totalKind?: "server" | "loaded";
  /** Unknown totals remain cursor paging: never invent a last page or global range. */
  hasNext?: boolean;
  pageSizes?: readonly number[];
}
