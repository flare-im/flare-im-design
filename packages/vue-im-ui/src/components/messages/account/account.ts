import { flarePluginRowsOnce, type FlarePluginRow, type FlarePluginRowsBlock, type FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";

export interface AccountEntry { key: string; row: FlarePluginRow; block: FlarePluginRowsBlock; amount: string; title: string; subtitle: string; atMs?: number }
/** Account appearance is explicit: first field is the balance; a rows block's first cell is its display amount. */
export function flareAccountEntries(view: FlarePluginViewModel): AccountEntry[] {
  return (view.blocks ?? []).flatMap(block => block.kind !== "rows" ? [] : flarePluginRowsOnce(block.rows).map(row => ({
    key: `${block.source}/${row.key}`, row, block, amount: row.cells[0]?.text ?? "",
    title: row.badge?.text || row.cells[1]?.text || block.columns[0]?.label || "",
    subtitle: row.cells.slice(1, 3).filter((_, index) => block.columns[index + 1]?.format !== "time" && (row.badge || index !== 0)).map(cell => cell.text).filter(Boolean).join(" · "),
    atMs: row.cells.find((_, index) => block.columns[index]?.format === "time")?.timeMs,
  })));
}
export function flareAccountDayKey(atMs?: number): string {
  if (atMs === undefined || !Number.isFinite(atMs)) return "unknown";
  const d = new Date(atMs);
  return Number.isNaN(d.getTime()) ? "unknown" : `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}
