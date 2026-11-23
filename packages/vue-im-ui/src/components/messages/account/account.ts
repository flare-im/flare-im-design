import { flarePluginMoneyFormatted, flarePluginRowsOnce, type FlarePluginRow, type FlarePluginRowsBlock, type FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";

export interface AccountEntry { key: string; row: FlarePluginRow; block: FlarePluginRowsBlock; amount: string; title: string; subtitle: string; atMs?: number }
/** Host-selected account layout for vocabulary-2 documents. Keep the original
 * rows, bindings and commands; only the balance head becomes the Kit wallet grid.
 * Documents without an explicit maskable amount head retain their own hierarchy. */
export function flareAccountDocument(view: FlarePluginViewModel): FlarePluginViewModel {
  if (view.presentation) return view;
  const head = view.blocks?.find(block => block.kind === "section" && block.blocks.some(child => child.kind === "hero" && child.amount && child.maskable));
  if (head?.kind !== "section") return view;
  const hero = head.blocks.find(block => block.kind === "hero" && block.amount && block.maskable);
  if (hero?.kind !== "hero" || hero.actions?.length) return view;
  const rows = view.blocks?.filter((block): block is FlarePluginRowsBlock => block.kind === "rows") ?? [];
  if (rows.length !== 1 || rows[0].columns.length < 2) return view;
  const stats = head.blocks.flatMap(block => block.kind === "stats" ? block.items : []);
  const primary = view.actions.filter(action => action.style === "primary" && action.target?.kind === "page" && !action.confirm && !action.form?.length).slice(0, 2);
  const entry = rows[0].actions.length === 1 ? rows[0].actions[0] : undefined;
  return { ...view,
    fields: [{label: hero.label ?? "", value: flarePluginMoneyFormatted(hero.value, hero.format)}, ...stats.map(item => ({label: item.label, value: flarePluginMoneyFormatted(item.value, item.format)})), ...view.fields],
    blocks: [...head.blocks.filter(block => block !== hero && block.kind !== "stats"), ...(view.blocks ?? []).filter(block => block !== head)],
    presentation: {renderer: "account", props: {layout: "wallet", summaryTitle: head.label || view.title,
      ...(entry?.target?.kind === "page" && !entry.confirm && !entry.form?.length ? {rowEntryAction: entry.id} : {})},
      actions: Object.fromEntries(primary.map((action, index) => [index ? "secondary" : "primary", action.id]))},
  };
}
/**
 * Account appearance is explicit: first field is the balance; a rows block's first cell is its display amount.
 * R3: a badge or cell outside its declared values reads `unknown` (pluginView.unknownStatus), never its raw value.
 */
export function flareAccountEntries(view: FlarePluginViewModel, unknown = ""): AccountEntry[] {
  const separateBadge = view.presentation?.props.rowBadgePlacement === "separate";
  const text = (item?: { text: string; unmapped?: boolean }) => item?.unmapped ? unknown : item?.text;
  return (view.blocks ?? []).flatMap(block => block.kind !== "rows" ? [] : flarePluginRowsOnce(block.rows).map(row => ({
    key: `${block.source}/${row.key}`, row, block, amount: flarePluginMoneyFormatted(row.cells[0]?.text ?? "", row.cells[0]?.format),
    title: (!separateBadge && text(row.badge)) || text(row.cells[1]) || block.columns[0]?.label || "",
    subtitle: row.cells.slice(1, 3).filter((_, index) => block.columns[index + 1]?.format !== "time" && ((!separateBadge && row.badge) || index !== 0)).map(cell => text(cell)).filter(Boolean).join(" · "),
    atMs: row.cells.find((_, index) => block.columns[index]?.format === "time")?.timeMs,
  })));
}
export function flareAccountDayKey(atMs?: number): string {
  if (atMs === undefined || !Number.isFinite(atMs)) return "unknown";
  const d = new Date(atMs);
  return Number.isNaN(d.getTime()) ? "unknown" : `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}
