/**
 * The 我 page's menu as settings sections (spec SettingsList notes, spec/me-menu-vectors.json): the social SDK's
 * `features.meMenu` result goes in as given, with the host's labels for built-in items and the subtitles by item id
 * (the summaries it read for plugin items, its own copy for built-in pages); the kit owns the copy, the icon fallback,
 * the grouping and what to drop. Order is the SDK's.
 */
import type { FlareSettingsItem, FlareSettingsSection } from "../shared/contracts";
import { FLARE_ICON_FALLBACK, flareIconNameOrFallback } from "../shared/icons";
import { currentFlareRuntimeLocale, resolveFlareMessage, type FlareLocale } from "../shared/i18n/messages";

/** A built-in 我 page destination; its id is also the host's route name. */
export type FlareMeMenuBuiltinId = "moments" | "reports" | "invite" | "settings";

/** One item of `features.meMenu` as the kit reads it (the SDK's MeMenuItem fits it). */
export interface FlareMeMenuItem {
  kind: "builtin" | "plugin" | (string & {});
  id: string;
  icon?: string | null;
  /** A plugin item's title. */
  title?: string | null;
  order?: number;
}

/** The `features.meMenu` result. */
export interface FlareMeMenu {
  items: ReadonlyArray<FlareMeMenuItem>;
  complete?: boolean;
}

const BUILTIN_KEYS: Readonly<Record<FlareMeMenuBuiltinId, string>> = {
  moments: "meMenu.moments",
  reports: "meMenu.reports",
  invite: "meMenu.invite",
  settings: "meMenu.settings",
};

const isBuiltin = (id: string): id is FlareMeMenuBuiltinId => Object.prototype.hasOwnProperty.call(BUILTIN_KEYS, id);

function summaryOf(summaries: FlareMeMenuSummaries | undefined, id: string): string | undefined {
  const raw = summaries instanceof Map
    ? summaries.get(id)
    : (summaries as Readonly<Record<string, string>> | undefined)?.[id];
  const text = typeof raw === "string" ? raw.trim() : "";
  return text || undefined;
}

/** Item subtitles by item id (built-in or plugin): a record or a Map. */
export type FlareMeMenuSummaries = Readonly<Record<string, string>> | ReadonlyMap<string, string>;

/**
 * The menu as sections: every item but settings in the SDK's order, then settings alone. A built-in item reads
 * `labels[id]`, else the kit copy (`meMenu.*`) in `locale` (the runtime locale by default); a plugin item reads its
 * title, else `meMenu.pluginFallback`. Any item reads `summaries[id]` as the row's detail. Icons go through
 * {@link flareIconNameOrFallback} (no name draws the fallback too). Unknown kinds and built-in ids are dropped, and of two items with one id the first
 * is kept. Every row is a navigation row keyed by the item id.
 */
export function flareMeMenuSections(
  menu: FlareMeMenu | null | undefined,
  labels?: Partial<Record<FlareMeMenuBuiltinId, string>>,
  summaries?: FlareMeMenuSummaries,
  locale: FlareLocale = currentFlareRuntimeLocale(),
): FlareSettingsSection[] {
  const destinations: FlareSettingsItem[] = [];
  const settings: FlareSettingsItem[] = [];
  const seen = new Set<string>();
  for (const item of menu?.items ?? []) {
    if (!item || typeof item.id !== "string" || seen.has(item.id)) continue;
    let row: FlareSettingsItem;
    if (item.kind === "builtin") {
      if (!isBuiltin(item.id)) continue;
      const label = labels?.[item.id]?.trim() || resolveFlareMessage(locale, BUILTIN_KEYS[item.id]);
      row = { key: item.id, label, kind: "navigation" };
    } else if (item.kind === "plugin") {
      const label = item.title?.trim() || resolveFlareMessage(locale, "meMenu.pluginFallback");
      row = { key: item.id, label, kind: "navigation" };
    } else continue;
    const detail = summaryOf(summaries, item.id);
    if (detail) row.detail = detail;
    seen.add(item.id);
    // Every entry carries a glyph: an item without a usable name draws the fallback too.
    row.icon = flareIconNameOrFallback(item.icon) ?? FLARE_ICON_FALLBACK;
    (item.kind === "builtin" && item.id === "settings" ? settings : destinations).push(row);
  }
  return [destinations, settings].filter((items) => items.length > 0).map((items) => ({ items }));
}
