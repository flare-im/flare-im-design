/**
 * The plugin page rules of docs/plugin-experience.md §2 (R1–R12) as pure functions, so every kit tests them against
 * spec/plugin-view-vectors.json (actionRoles, statusValues, references, blockBoundInputs, cardHeader, refreshKey,
 * accountDerivation, formPlacement, formCounter, selectOptions, actionDedupe, result, pageStates, statusCard).
 * Nothing here touches the DOM.
 */
import {
  flarePluginBadgeTone,
  flarePluginFlatBlocks,
  flarePluginInlineFormAction,
  type FlarePluginAction,
  type FlarePluginBlock,
  type FlarePluginField,
  type FlarePluginPageAppearance,
  type FlarePluginResultBlock,
  type FlarePluginTone,
  type FlarePluginViewModel,
} from "./plugin-ui";

// ── development warnings ────────────────────────────────────────────────────

// Only the build mode (as in shared/icons.ts): bundlers write it over process.env.NODE_ENV; a plain script has none.
declare const process: { env: { NODE_ENV?: string } };
function flareDevelopmentBuild(): boolean {
  try {
    return process.env.NODE_ENV !== "production";
  } catch {
    return false;
  }
}
const warned = new Set<string>();
/** One console warning per key in a development build (R3 unmapped values, R9 duplicate labels). */
export function flarePluginWarnOnce(key: string, message: string): boolean {
  if (warned.has(key) || !flareDevelopmentBuild()) return false;
  warned.add(key);
  console.warn(`[flare-im] ${message}`);
  return true;
}

// ── blocks ──────────────────────────────────────────────────────────────────

/** Every block, a section's children after it (sections themselves included). */
const flat = (view: Pick<FlarePluginViewModel, "blocks">): FlarePluginBlock[] =>
  flarePluginFlatBlocks(view.blocks ?? []).map((item) => item.block);
const hasBlock = (view: Pick<FlarePluginViewModel, "blocks">, ...kinds: string[]) =>
  flat(view).some((block) => kinds.includes(block.kind));

/** R6.1: the inputName of every protected-media and choices block (top level or in a section). */
export function flarePluginBoundInputs(view: Pick<FlarePluginViewModel, "blocks">): Set<string> {
  return new Set(flat(view).flatMap((block) =>
    (block.kind === "protected-media" || block.kind === "choices") && block.inputName ? [block.inputName] : []));
}

/** R6.1: an action whose form lists bound inputs only — the block runs it; it is not a top-level action. */
export function flarePluginIsBlockAction(action: FlarePluginAction, bound: ReadonlySet<string>): boolean {
  return Boolean(action.form?.length) && action.form!.every((id) => bound.has(id));
}

/** The inputs an action's form draws: its form without the bound ones. */
export function flarePluginDrawnInputs(action: FlarePluginAction, bound: ReadonlySet<string>): string[] {
  return (action.form ?? []).filter((id) => !bound.has(id));
}

/** Blocks that may sit beside a page's inline form (instructions, progress, and the blocks that fill bound inputs). */
const INLINE_COMPANIONS = new Set(["note", "text", "steps", "banner", "fields", "status", "time", "choices", "protected-media", "section"]);

/**
 * A page that declares exactly one action with drawn inputs and only instructions beside it shows that form in place
 * (spec PluginPage notes, R6.1: block actions never make a page form inline).
 */
export function flarePluginPageInlineForm(view: FlarePluginViewModel): string | undefined {
  if (view.presentation) return undefined;
  const bound = flarePluginBoundInputs(view);
  const forms = view.actions.filter((action) => flarePluginDrawnInputs(action, bound).length > 0);
  if (forms.length !== 1 || flat(view).some((block) => !INLINE_COMPANIONS.has(block.kind))) return undefined;
  return flarePluginInlineFormAction(view, forms[0].id)?.id;
}

// ── R2 roles, archetypes and places ─────────────────────────────────────────

export type FlarePluginActionRole = "primary" | "danger" | "destination" | "command";
export type FlarePluginArchetype = "card" | "overview" | "task" | "records";

/** R2: style danger → danger, style primary → primary, a page target without form → destination, else command. */
export function flarePluginActionRole(action: FlarePluginAction): FlarePluginActionRole {
  if (action.style === "danger") return "danger";
  if (action.style === "primary") return "primary";
  return action.target?.kind === "page" && !action.form?.length ? "destination" : "command";
}

/** R2.3 (spec rules.rowTap): a row's only action when it opens a page (no form, not danger): the whole row runs it. */
export function flarePluginRowTap<T extends { action: FlarePluginAction }>(entries: ReadonlyArray<T>): T | undefined {
  const [only] = entries;
  return entries.length === 1 && only.action.target?.kind === "page" && !only.action.form?.length && only.action.style !== "danger"
    ? only : undefined;
}

/** R9: actions with a label already drawn are dropped (the first stays); a development build warns once. */
export function flarePluginDedupeActions(actions: ReadonlyArray<FlarePluginAction>): { drawn: FlarePluginAction[]; dropped: FlarePluginAction[] } {
  const seen = new Set<string>();
  const drawn: FlarePluginAction[] = [];
  const dropped: FlarePluginAction[] = [];
  for (const action of actions) {
    if (seen.has(action.label)) dropped.push(action);
    else { seen.add(action.label); drawn.push(action); }
  }
  for (const action of dropped)
    flarePluginWarnOnce(`dedupe:${action.id}:${action.label}`, `plugin action "${action.id}" repeats the label "${action.label}"; only the first is drawn`);
  return { drawn, dropped };
}

/** The top-level actions in declared order: view.actions (then menuActions when embedded), block actions left out, deduped. */
export function flarePluginTopLevelActions(view: FlarePluginViewModel, embedded: boolean): FlarePluginAction[] {
  const bound = flarePluginBoundInputs(view);
  const all = [...view.actions, ...(embedded ? view.menuActions ?? [] : [])].filter((action) => !flarePluginIsBlockAction(action, bound));
  return flarePluginDedupeActions(all).drawn;
}

/** R2: card (not embedded), overview, task or records. */
export function flarePluginArchetype(
  view: FlarePluginViewModel,
  options: { embedded: boolean; inlineFormActionId?: string | null },
  actions: ReadonlyArray<FlarePluginAction> = flarePluginTopLevelActions(view, options.embedded),
): FlarePluginArchetype {
  if (!options.embedded) return "card";
  const destinations = actions.filter((action) => flarePluginActionRole(action) === "destination").length;
  if (hasBlock(view, "hero", "stats") && destinations >= 4) return "overview";
  if (options.inlineFormActionId) return "task";
  if (!hasBlock(view, "rows", "entries", "timeline") && actions.length <= 3 && actions.some((action) => flarePluginActionRole(action) === "primary"))
    return "task";
  return "records";
}

export interface FlarePluginListGroup {
  /** null: one untitled card. */
  group: "common" | "records" | null;
  actions: FlarePluginAction[];
}
/** Where each top-level action is drawn (rules.actionRoles); a place left out is empty. */
export interface FlarePluginActionPlaces {
  archetype: FlarePluginArchetype;
  quick: FlarePluginAction[];
  list: FlarePluginListGroup[];
  bar: FlarePluginAction[];
  barSecondary: FlarePluginAction[];
  more: FlarePluginAction[];
  header: FlarePluginAction[];
  commands: FlarePluginAction[];
  danger: FlarePluginAction[];
  footer: FlarePluginAction[];
  menu: FlarePluginAction[];
}

/** List cards: two titled cards (common, then records) when any item declares a group, else one untitled card. */
function groups(actions: FlarePluginAction[]): FlarePluginListGroup[] {
  if (!actions.length) return [];
  if (!actions.some((action) => action.group)) return [{ group: null, actions }];
  const records = actions.filter((action) => action.group === "records");
  const common = actions.filter((action) => action.group !== "records");
  return [{ group: "common" as const, actions: common }, { group: "records" as const, actions: records }].filter((g) => g.actions.length);
}

/** `archetype` forces the page's archetype (the account appearance draws its overview places on a view of actions only). */
export function flarePluginActionPlaces(
  view: FlarePluginViewModel,
  options: { embedded: boolean; inlineFormActionId?: string | null; archetype?: FlarePluginArchetype },
): FlarePluginActionPlaces {
  const actions = flarePluginTopLevelActions(view, options.embedded);
  const archetype = options.archetype ?? flarePluginArchetype(view, options, actions);
  const places: FlarePluginActionPlaces = { archetype, quick: [], list: [], bar: [], barSecondary: [], more: [], header: [], commands: [], danger: [], footer: [], menu: [] };
  const role = flarePluginActionRole;
  if (archetype === "card") {
    const ordered = [...actions.filter((a) => role(a) === "primary"), ...actions.filter((a) => role(a) !== "primary")];
    places.footer = ordered.slice(0, 3);
    places.menu = [...(view.menuActions ?? []), ...ordered.slice(3)];
    return places;
  }
  // §6.3: a capture action writing `into` an input of the page's inline form is that input's slot, not a key.
  const inline = options.inlineFormActionId ? view.actions.find((a) => a.id === options.inlineFormActionId) : undefined;
  const drawn = actions.filter((a) => !(a.target?.kind === "native" && a.target.into && inline?.form?.includes(a.target.into)));
  places.danger = drawn.filter((a) => role(a) === "danger");
  const rest = drawn.filter((a) => role(a) !== "danger");
  // A command that declares a group is always a list item (more on task and records pages), never a quick,
  // barSecondary or commands key — the same rule as the other kits.
  const key = (a: FlarePluginAction) => role(a) === "primary" || (role(a) === "command" && !a.group);
  if (archetype === "overview") {
    const quick = new Set([...rest.filter((a) => role(a) === "primary").slice(0, 2), ...rest.filter((a) => role(a) === "command" && !a.group).slice(0, 2)]);
    places.quick = [...quick];
    places.list = groups(rest.filter((a) => !quick.has(a)));
  } else if (archetype === "task") {
    const bar = rest.find((a) => role(a) === "primary");
    places.bar = bar ? [bar] : [];
    places.barSecondary = rest.filter((a) => a !== bar && key(a)).slice(0, 2);
    places.more = rest.filter((a) => a !== bar && !places.barSecondary.includes(a));
  } else {
    const header = rest.find((a) => role(a) === "primary");
    places.header = header ? [header] : [];
    places.commands = rest.filter((a) => a !== header && key(a));
    places.more = rest.filter((a) => !places.header.includes(a) && !places.commands.includes(a));
  }
  return places;
}

// ── R1 refresh key, R12 account appearance ──────────────────────────────────

/** R1: a data page that is not a task, a result or a custom presentation (rules.refreshKey). */
export function flarePluginShowsRefreshKey(view: FlarePluginViewModel, inlineFormActionId?: string | null): boolean {
  if (!view.available) return false;
  if (view.presentation && view.presentation.renderer !== "account") return false;
  if (hasBlock(view, "result")) return false;
  const data = view.fields.length > 0 || hasBlock(view, "rows", "entries", "stats", "hero", "timeline", "people", "status")
    || flat(view).some((block) => block.kind === "fields" && block.fields.length > 0);
  return data && flarePluginArchetype(view, { embedded: true, inlineFormActionId }) !== "task";
}

/** R12: the page's appearance — explicit, else the account structure (rules.accountDerivation). */
export function flarePluginPageAppearanceOf(
  view: FlarePluginViewModel | undefined,
  appearance?: FlarePluginPageAppearance,
): FlarePluginPageAppearance {
  if (appearance) return appearance;
  if (!view) return "document";
  if (view.presentation) return view.presentation.renderer === "account" ? "account" : "document";
  const head = (view.blocks ?? []).some((block) => block.kind === "section"
    && block.blocks.some((child) => child.kind === "hero" && child.amount && child.maskable && !child.actions?.length));
  const rows = (view.blocks ?? []).filter((block) => block.kind === "rows");
  return head && rows.length === 1 && rows[0].kind === "rows" && rows[0].columns.length >= 2 ? "account" : "document";
}

// ── R6 forms ────────────────────────────────────────────────────────────────

const PAGE_INPUTS = new Set(["file", "document", "image", "members"]);
/** R6: at most 4 drawn fields and no file, document, image or members → a sheet; else (or inline) a page form. */
export function flarePluginFormPlacement(kinds: ReadonlyArray<string>, inline: boolean): "sheet" | "page" {
  return !inline && kinds.length <= 4 && !kinds.some((kind) => PAGE_INPUTS.has(kind)) ? "sheet" : "page";
}

/** R6: the counter shows with a limit of at most 200 and something typed. */
export function flarePluginCounterShown(maxLength: number | null | undefined, length: number): boolean {
  return typeof maxLength === "number" && maxLength <= 200 && length > 0;
}

/** R6: no choices → a disabled select that blocks submit; at most 4 → cards; more → a select. */
export function flarePluginSelectControl(choices: number): { control: "select" | "cards"; disabled: boolean } {
  if (choices === 0) return { control: "select", disabled: true };
  return { control: choices <= 4 ? "cards" : "select", disabled: false };
}

// ── R3 status values and references ─────────────────────────────────────────

export interface FlarePluginStatusDraw {
  draw: "tag" | "text";
  /** The words to draw; empty when `unknown` (the kit draws pluginView.unknownStatus). */
  text: string;
  tone?: FlarePluginTone;
  unknown?: boolean;
}

/**
 * R3: how a field, a row cell, a status block, a badge or a timeline status draws. Unmapped → the unknown Tag, neutral,
 * and one development warning per `context` and raw value; a tone → a Tag (brand draws info, other unknown tones
 * neutral); no tone → the text.
 */
export function flarePluginStatusDraw(
  item: { text?: string; value?: string; tone?: string; unmapped?: boolean },
  context = "",
): FlarePluginStatusDraw {
  const text = item.text ?? item.value ?? "";
  if (item.unmapped) {
    flarePluginWarnOnce(`unmapped:${context}:${text}`, `plugin value "${text}"${context ? ` at ${context}` : ""} is not among its declared values; drawing the unknown status`);
    return { draw: "tag", text: "", tone: "neutral", unknown: true };
  }
  if (item.tone !== undefined && item.tone !== null) return { draw: "tag", text, tone: flarePluginBadgeTone(item.tone) };
  return { draw: "text", text };
}

/** R3: fields whose format is reference leave the main fields for the folded References group, in order. */
export function flarePluginSplitReferences<T extends Pick<FlarePluginField, "format">>(fields: ReadonlyArray<T>): { main: T[]; references: T[] } {
  return {
    main: fields.filter((field) => field.format?.kind !== "reference"),
    references: fields.filter((field) => field.format?.kind === "reference"),
  };
}

// ── R5 card head ────────────────────────────────────────────────────────────

/** R5: what the card head draws in order, and whether the details key moved to the footer end. */
export function flarePluginCardHead(card: { detail: boolean; footerActions: number; menuActions: number }): {
  order: Array<"icon" | "title" | "detail" | "more">; detailInFooter: boolean;
} {
  const detailInFooter = card.detail && card.footerActions > 0;
  return {
    order: ["icon", "title", ...(card.detail && !detailInFooter ? ["detail" as const] : []), ...(card.menuActions > 0 ? ["more" as const] : [])],
    detailInFooter,
  };
}

// ── R7 result ───────────────────────────────────────────────────────────────

export const FLARE_PLUGIN_RESULT_POLL_MS = 3000;
export const FLARE_PLUGIN_RESULT_POLL_FOR_MS = 60000;
const RESULT_ICONS: Record<FlarePluginTone, "success" | "clock" | "warning" | "error" | "info"> = {
  success: "success", info: "clock", warning: "warning", danger: "error", neutral: "info",
};

/** The icon of a result tone. */
export function flarePluginResultIcon(tone: FlarePluginTone): "success" | "clock" | "warning" | "error" | "info" {
  return RESULT_ICONS[tone];
}

/** R7: what a result block draws, whether the page polls and what is announced (title then description).
 * `context` names where an unmapped state is warned from (a page leads it with its plugin id and page). */
export function flarePluginResultFacts(block: FlarePluginResultBlock, unknownTitle = "", context = `result:${block.state}`): {
  icon: "success" | "clock" | "warning" | "error" | "info"; tone: FlarePluginTone; title: string; unknown: boolean;
  amount?: string; description?: string; poll: boolean; announce: string;
} {
  const drawn = flarePluginStatusDraw({ text: block.title, tone: block.tone, unmapped: block.unmapped }, context);
  const tone = drawn.tone ?? "neutral";
  const title = drawn.unknown ? unknownTitle : block.title;
  return {
    icon: flarePluginResultIcon(tone), tone, title, unknown: Boolean(drawn.unknown),
    ...(block.amount ? { amount: block.amount } : {}),
    ...(block.description ? { description: block.description } : {}),
    poll: !block.unmapped && block.state === "pending",
    announce: [title, block.description].filter(Boolean).join(" "),
  };
}

/** The result block a view leads with, if any (top level). */
export function flarePluginResultBlock(view: Pick<FlarePluginViewModel, "blocks">): FlarePluginResultBlock | undefined {
  return (view.blocks ?? []).find((block): block is FlarePluginResultBlock => block.kind === "result");
}

// ── R8 page states ──────────────────────────────────────────────────────────

/** R8: nothing is drawn for this long before the first load's skeleton. */
export const FLARE_PLUGIN_SKELETON_DELAY_MS = 300;
/** R8: the first load's skeleton; before a view the archetype is unknown, so the records list (6 rows). */
export function flarePluginLoadingFace(elapsedMs: number): { state: "blank" } | { state: "skeleton"; skeleton: "records"; rows: number } {
  return elapsedMs < FLARE_PLUGIN_SKELETON_DELAY_MS ? { state: "blank" } : { state: "skeleton", skeleton: "records", rows: 6 };
}

// ── 6.1 status card ─────────────────────────────────────────────────────────

/** 6.1: the status.card renderer, or (structure fallback) a first steps block and a field carrying a tone. */
export function flarePluginStatusCard(view: Pick<FlarePluginViewModel, "presentation" | "blocks" | "fields">): boolean {
  if (view.presentation) return view.presentation.renderer === "status.card";
  return view.blocks?.[0]?.kind === "steps" && view.fields.some((field) => field.tone !== undefined || field.unmapped === true);
}

/**
 * R10: what a ledger row's amount shows — core's data keeps the ASCII hyphen ("-¥5.00"), the display draws the minus
 * sign (U+2212) before the digits. Anything that is not a negative amount is returned as it is.
 */
export function flarePluginDisplayAmount(text: string): string {
  return text.replace(/^(\s*)-(?=\D*\d)/, "$1−");
}
/** §5.8: a signed amount's direction (a leading + is income, a hyphen or U+2212 is expense); undefined when unsigned. */
export function flarePluginAmountSign(text: string | undefined): "in" | "out" | undefined {
  return /^\s*\+\D*\d/.test(text ?? "") ? "in" : /^\s*[-\u2212]\D*\d/.test(text ?? "") ? "out" : undefined;
}
