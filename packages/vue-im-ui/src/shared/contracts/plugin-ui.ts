/**
 * Presentation only. The core SDK resolves declarations, leases, state layers and fallback into a
 * ResolvedPluginView (flare-plugin-protocol ui.rs / blocks.rs / inputs.rs); the kit draws that shape and
 * reads no paths. The pure rules the kit draws from (time and countdown copy, the form's light check and
 * submitted values, issue texts, the fallback name) live here so every kit can test them against
 * spec/plugin-view-vectors.json.
 */

import { flareIdTail } from "./display-name";

export type FlarePluginTone =
  "neutral" | "info" | "success" | "warning" | "danger";
export type FlarePluginActionStyle = "primary" | "danger";

/** A resolved action. `target`, `input` and `hiddenWhen` may ride along in the JSON; the kit ignores them. */
export interface FlarePluginAction {
  id: string;
  label: string;
  style?: FlarePluginActionStyle;
  /** Asked first in the kit DangerConfirm. */
  confirm?: string;
  /** Input ids collected first in PluginForm. */
  form?: ReadonlyArray<string>;
  /** `menu`: the action lives in the card's ⋯ menu (it arrives in view.menuActions). */
  placement?: "menu";
}

/**
 * What a resolved field or cell adds to its plain text (flare-plugin-protocol ResolvedUiFormat). The text alone is
 * always right to draw: a format from a newer protocol, or on a surface that has no use for it, falls back to it.
 */
export type FlarePluginFormat =
  | { kind: "money"; minor: string; scale?: number; assetId?: string }
  | { kind: "enum"; raw: string }
  | { kind: "person"; userId: string }
  | { kind: "reference"; id: string; labelled: boolean }
  | { kind: "time"; atMs: number };

export interface FlarePluginField {
  label: string;
  value: string;
  format?: FlarePluginFormat;
  user?: import("./user-identity").FlareUserIdentityValue;
}
/**
 * An entry's or a row's enumerated value as words and a tone (the plugin's valueLabels), such as a ledger line's
 * kind; drawn as the kit Tag. The tone may come from a newer protocol: draw it through flarePluginBadgeTone.
 */
export interface FlarePluginBadge {
  text: string;
  tone: FlarePluginTone;
}

export interface FlarePluginTextBlock {
  kind: "text";
  text: string;
  maxLines?: number;
  style?: "body" | "title" | "secondary";
}
export interface FlarePluginFieldsBlock {
  kind: "fields";
  fields: ReadonlyArray<FlarePluginField>;
}
export interface FlarePluginChoice {
  index: number;
  label: string;
  selected: boolean;
  count?: number;
  percent?: number;
}
export interface FlarePluginChoicesBlock {
  kind: "choices";
  options: ReadonlyArray<FlarePluginChoice>;
  multiple: boolean;
  voted: boolean;
  closed: boolean;
  showResults: boolean;
  total?: number;
  inputName: string;
  /** A multiple choice's cap (1..=option count): options outside the draft are disabled once it is full. */
  maxSelections?: number;
  /** The block's submit action, present while the viewer can choose. */
  action?: FlarePluginAction;
}
/** The group an entry opens in a grouped list (the first item of each group carries it). */
export interface FlarePluginEntryGroup {
  key: string;
  label: string;
  count?: number;
  total?: number;
  percent?: number;
}
export interface FlarePluginEntry {
  index: number;
  text: string;
  name?: string;
  userId?: string;
  group?: FlarePluginEntryGroup;
  /** Drawn after the name and the me tag, before the text. */
  badge?: FlarePluginBadge;
}
export interface FlarePluginEntriesBlock {
  kind: "entries";
  items: ReadonlyArray<FlarePluginEntry>;
  numbered: boolean;
  /** One flat list in groups: an item with `group` is preceded by its group header. */
  grouped?: boolean;
  total: number;
  more: boolean;
  emptyText?: string;
}
export interface FlarePluginPeopleGroup {
  label: string;
  userIds: ReadonlyArray<string>;
  count: number;
  tone?: FlarePluginTone;
}
export interface FlarePluginPeopleBlock {
  kind: "people";
  groups: ReadonlyArray<FlarePluginPeopleGroup>;
}
export interface FlarePluginStatusBlock {
  kind: "status";
  label?: string;
  text: string;
  tone: FlarePluginTone;
}
export interface FlarePluginProgressBlock {
  kind: "progress";
  label?: string;
  value: number;
  total: number;
  percent: number;
}
export interface FlarePluginTimeBlock {
  kind: "time";
  label?: string;
  atMs: number;
  endMs?: number;
  countdown: boolean;
}
export interface FlarePluginDividerBlock {
  kind: "divider";
}
export interface FlarePluginNoteBlock {
  kind: "note";
  text: string;
  tone?: FlarePluginTone;
}
export interface FlarePluginRowCell {
  text: string;
  timeMs?: number;
  format?: FlarePluginFormat;
  /** Optional host-owned identity presentation; never sent back as plugin command input. */
  user?: import("./user-identity").FlareUserIdentityValue;
}
export interface FlarePluginRow {
  key: string;
  cells: ReadonlyArray<FlarePluginRowCell>;
  actions: ReadonlyArray<{ id: string; input: unknown }>;
  detailInput?: unknown;
  /** Leads the row: the first line of a list item, the first cell of a table row. */
  badge?: FlarePluginBadge;
}
/**
 * Rows: a plugin page's list (every kit; they page with the page, so nextCursor is absent there) or a Vue console
 * table (FlarePluginRowsLayout).
 */
export interface FlarePluginRowsBlock {
  kind: "rows";
  source: string;
  columns: ReadonlyArray<{ label: string; format: "text" | "time" }>;
  rows: ReadonlyArray<FlarePluginRow>;
  nextCursor?: string;
  actions: ReadonlyArray<FlarePluginAction>;
  emptyText?: string;
  /** Ids of the view's inputs the page shows as its filters; absent: every input (flarePluginFilterInputs). */
  filters?: ReadonlyArray<string>;
  /** `cards`: one card per row where the host draws the table layout; a plugin page's list ignores it. */
  presentation?: "table" | "cards";
}
/** One item of a protected media block; nothing about its content is in the view. */
export interface FlarePluginProtectedItem {
  id: string;
  label: string;
  mediaType?: string;
  input: unknown;
}
/** Private material read one item at a time, with a stated reason, through `action`. Vue console only. */
export interface FlarePluginProtectedMediaBlock {
  kind: "protected-media";
  label?: string;
  items: ReadonlyArray<FlarePluginProtectedItem>;
  action?: FlarePluginAction;
  inputName: string;
  reasonInput?: string;
  /** Reads the action's result: the address the host fetches for the viewer. */
  urlPath: string;
  emptyText?: string;
}
/** What the host has for an item. `url` is what the host fetched: a blob:, https: or data:image address. */
export interface FlarePluginProtectedMediaState {
  url?: string;
  loading?: boolean;
  error?: string;
}
/** What `protectedMediaRead` carries: the action request and the reason, for the host to run and audit. */
export interface FlarePluginProtectedMediaRead {
  action: FlarePluginAction;
  item: FlarePluginProtectedItem;
  reason: string;
  urlPath: string;
  /** The action's form values: the item and, when the operation takes it as input, the reason. */
  formValues: Record<string, unknown>;
}
export type FlarePluginBlock =
  | FlarePluginTextBlock
  | FlarePluginFieldsBlock
  | FlarePluginChoicesBlock
  | FlarePluginEntriesBlock
  | FlarePluginPeopleBlock
  | FlarePluginStatusBlock
  | FlarePluginProgressBlock
  | FlarePluginTimeBlock
  | FlarePluginDividerBlock
  | FlarePluginNoteBlock
  | FlarePluginRowsBlock
  | FlarePluginProtectedMediaBlock;

export type FlarePluginInputKind =
  | "file"
  | "text"
  | "password"
  | "textarea"
  | "number"
  | "toggle"
  | "select"
  | "datetime"
  | "options"
  | "members";
export interface FlarePluginInput {
  id: string;
  kind: FlarePluginInputKind;
  label: string;
  required?: boolean;
  placeholder?: string;
  maxLength?: number;
  min?: number;
  max?: number;
  default?: unknown;
  /** select: what it picks from. options: when present, the items are picked from these. */
  choices?: ReadonlyArray<{ value: string; label: string }>;
  /** The host loads the choices, with the viewer's own permission, on `referenceLoad`. */
  reference?: FlarePluginReference;
  file?: FlarePluginFilePolicy;
  showWhen?: FlarePluginInputCondition;
}
/** Declarative form dependency; only an earlier unconditional select controls it. */
export interface FlarePluginInputCondition { field: string; anyOf: ReadonlyArray<string> }
export interface FlarePluginFilePolicy {
  accept: ReadonlyArray<string>;
  maxBytes: number;
  upload: { prepareOperation: string; completeOperation: string; purpose: string };
}
/** The only file value that may enter a plugin command. Never bytes, URLs or read grants. */
export interface FlarePluginFileValue { fileId: string }
export type FlarePluginFilePhase = "empty" | "selected" | "uploading" | "uploaded" | "failed";
/** Host-only state. Both tickets must match the current form field. */
export interface FlarePluginFileState {
  scope: string;
  generation: number;
  phase: FlarePluginFilePhase;
  value?: FlarePluginFileValue;
  fileName?: string;
  progress?: number;
  error?: string;
  /** Offers a host-owned private preview, never a URL. */
  preview?: boolean;
  previewLoading?: boolean;
}
export type FlarePluginFileActionKind = "choose" | "retry" | "cancel" | "replace" | "remove" | "preview" | "invalidate";
export interface FlarePluginFileAction {
  action: FlarePluginFileActionKind;
  inputId: string;
  input: FlarePluginInput;
  scope: string;
  generation: number;
  formValues: Record<string, unknown>;
}
let fileScopeSequence = 0;
export function flarePluginNewFileScope(): string {
  return `plugin-form-${Date.now().toString(36)}-${++fileScopeSequence}`;
}
export function flarePluginFileValue(value: unknown): value is FlarePluginFileValue {
  if (!value || typeof value !== "object" || Array.isArray(value)) return false;
  const object = value as Record<string, unknown>;
  return Object.keys(object).length === 1 && typeof object.fileId === "string" &&
    /^[A-Za-z0-9_:-]{1,128}$/.test(object.fileId) && object.fileId === object.fileId.trim();
}
export function flarePluginInputVisible(input: FlarePluginInput, inputs: ReadonlyArray<FlarePluginInput>, draft: Record<string, unknown>): boolean {
  const condition = input.showWhen;
  if (!condition) return true;
  const index = inputs.indexOf(input);
  const controller = inputs.findIndex((item) => item.id === condition.field);
  return controller >= 0 && controller < index && inputs[controller].kind === "select" &&
    !inputs[controller].showWhen && Array.isArray(condition.anyOf) &&
    typeof draft[condition.field] === "string" && condition.anyOf.includes(draft[condition.field] as string);
}
export function flarePluginVisibleInputs(inputs: ReadonlyArray<FlarePluginInput>, draft: Record<string, unknown>): FlarePluginInput[] {
  return inputs.filter((input) => flarePluginInputVisible(input, inputs, draft));
}
/** A declared source of choices (flare-plugin-protocol UiReference). The kit reads only `parents`. */
export interface FlarePluginReference {
  /** The owning plugin; this plugin when absent (the wire may send null). */
  plugin?: string | null;
  operation: string;
  valuePath: string;
  labelPath: string;
  search?: string | null;
  params?: Record<string, unknown>;
  /** Operation input name to the sibling control that holds its value. */
  parents?: Record<string, string>;
}
/** A reference request or current-selection update; hosts may reuse options for the same directory. */
export interface FlarePluginReferenceRequest {
  /** The input id, or the absolute pointer of a configuration field. */
  id: string;
  reference: FlarePluginReference;
  /** The values of the reference's parents, by operation input name. */
  parents: Record<string, unknown>;
  /** The value already chosen, so the host can have it named. */
  selected?: string;
}
export type FlarePluginFormIssue =
  | "required"
  | "unknown"
  | "invalidType"
  | "tooLong"
  | "outOfRange"
  | "notAChoice"
  | "tooFewItems"
  | "tooManyItems"
  | "invalidItem"
  | "duplicateItem";
export interface FlarePluginFormError {
  input: string;
  issue: FlarePluginFormIssue;
}

/** What the host's resolveUser answers for a user id. */
export interface FlarePluginUser {
  name: string;
  avatarUrl?: string;
}
export type FlarePluginResolveUser = (
  userId: string,
) => FlarePluginUser | Promise<FlarePluginUser | undefined> | undefined;
/** A candidate for a members input. */
export interface FlarePluginMember {
  userId: string;
  name: string;
  avatarUrl?: string;
}
/**
 * Where the view sits (spec rules.inset): none (the host's surface pads it); sheet — straight in a kit sheet (md / lg /
 * xl); sheetTop — at the top of a sheet with more under it, e.g. a preface above PluginForm (md / lg / 0).
 */
export type FlarePluginViewInset = "none" | "sheet" | "sheetTop";
/** What `action(id, payload)` carries. */
export interface FlarePluginActionPayload {
  /** Chosen option indices of a choices block, ascending. */
  selection?: number[];
  /** Submitted form values by input id. */
  formValues?: Record<string, unknown>;
  /** The row of a rows action. */
  row?: { key: string; input: unknown };
}
/** How a Vue PluginView draws a rows block: the kit DataTable (console admin lists) or a list (plugin pages). */
/** Explicit account layouts: wallet cards use row display amounts, flow fields are labeled data, and legacy/ledger fields keep their headline semantics. */
export type FlarePluginPageAppearance = "document" | "account";
export type FlarePluginRowsLayout = "table" | "list";

/** Why a view is unavailable, or (unbound_copy) read-only (ResolvedPluginView.unavailableReason). */
export type FlarePluginUnavailableReason =
  | "disabled"
  | "not_installed"
  | "no_permission"
  | "unsupported_platform"
  | "incompatible_version"
  | "catalog_unreachable"
  | "unbound_copy";

export interface FlarePluginPresentation {
  renderer: string;
  props: Record<string, unknown>;
  actions: Record<string, string>;
}

export interface FlarePluginViewModel {
  presentation?: FlarePluginPresentation;
  available: boolean;
  /** Why it is unavailable; unbound_copy keeps it available but read-only (a forwarded or forged copy). */
  unavailableReason?: FlarePluginUnavailableReason;
  title: string;
  fields: ReadonlyArray<FlarePluginField>;
  actions: ReadonlyArray<FlarePluginAction>;
  /** Actions of the card's ⋯ menu, in order (spec rules.menuActions); absent when there are none. */
  menuActions?: ReadonlyArray<FlarePluginAction>;
  blocks?: ReadonlyArray<FlarePluginBlock>;
  inputs?: ReadonlyArray<FlarePluginInput>;
  /** The contribution has a detail view ("see all"). */
  detail?: boolean;
  /**
   * Detail views only: the cursor of the next page. While it is set PluginDetailSheet offers load more; the host
   * fetches that page and passes back the merged view (the core SDK appends pages).
   */
  nextCursor?: string;
}

/** Page data-entry only. Passwords, confirmations and incomplete bindings retain their guarded sheet. */
export function flarePluginInlineFormAction(
  view: FlarePluginViewModel,
  actionId?: string,
): FlarePluginAction | undefined {
  if (!view.available || view.unavailableReason === "unbound_copy" || !actionId)
    return undefined;
  const action = view.actions.find((candidate) => candidate.id === actionId);
  if (!action?.form?.length || action.confirm) return undefined;
  const inputs = action.form.map((id) =>
    view.inputs?.find((input) => input.id === id),
  );
  return inputs.every((input) => input && input.kind !== "password")
    ? action
    : undefined;
}

/** The page a PluginPage shows, as invokePageAction names it. */
export interface FlarePluginPageRef {
  pluginId: string;
  page: string;
}
/**
 * A resolved plugin page (the core SDK's pluginPage result): a view plus `data`, what the page was resolved against
 * (the first page's source result, or a source-less page's arguments; only while available). An unavailable page is
 * `{available: false, title: "", unavailableReason}`.
 */
export interface FlarePluginPageViewModel extends FlarePluginViewModel {
  data?: Record<string, unknown>;
}
/** What PluginPage's action(id, payload) carries: the request invokePageAction takes, without platform and gesture. */
export interface FlarePluginPageActionPayload extends FlarePluginActionPayload {
  page: FlarePluginPageRef;
  /** view.data, when the view has it. */
  data?: Record<string, unknown>;
}
/** A page's state (spec rules.page). */
export type FlarePluginPageState =
  "loading" | "error" | "unavailable" | "loaded";
/** One select filter of a page (spec rules.pageFilters): its tabs, all first (value null), and the selected value. */
export interface FlarePluginPageFilter {
  input: FlarePluginInput;
  tabs: ReadonlyArray<{ value: string | null; label: string }>;
  selected: string | null;
}

/** The copy the pure rules need; the components fill it from the active locale. */
export interface FlarePluginStrings {
  deadlinePassed: string;
  remaining: string;
  dateTime: string;
  dateTimeYear: string;
  days: string;
  hours: string;
  minutes: string;
  required: string;
  tooLong: string;
  outOfRange: string;
  tooFewItems: string;
  tooManyItems: string;
  duplicateItem: string;
  invalid: string;
}

const MONTHS = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];
const pad2 = (n: number) => String(n).padStart(2, "0");

interface WallClock {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
}

/** Local wall clock of an instant: the device zone, or a fixed offset (tests). */
function wallClock(ms: number, utcOffsetMinutes?: number): WallClock {
  if (utcOffsetMinutes === undefined) {
    const d = new Date(ms);
    return {
      year: d.getFullYear(),
      month: d.getMonth() + 1,
      day: d.getDate(),
      hour: d.getHours(),
      minute: d.getMinutes(),
    };
  }
  const d = new Date(ms + utcOffsetMinutes * 60_000);
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
    hour: d.getUTCHours(),
    minute: d.getUTCMinutes(),
  };
}

/** Renders a date-time pattern: y year, M month, MMM Jan..Dec, d day, HH hour, mm minute; the rest is literal. */
export function flarePluginRenderPattern(
  pattern: string,
  at: WallClock,
): string {
  let out = "";
  for (let i = 0; i < pattern.length;) {
    const c = pattern[i];
    if ("yMdHm".includes(c)) {
      let j = i;
      while (j < pattern.length && pattern[j] === c) j += 1;
      const run = pattern.slice(i, j);
      out +=
        run === "y"
          ? String(at.year)
          : run === "M"
            ? String(at.month)
            : run === "MMM"
              ? MONTHS[at.month - 1]
              : run === "d"
                ? String(at.day)
                : run === "HH"
                  ? pad2(at.hour)
                  : run === "mm"
                    ? pad2(at.minute)
                    : run;
      i = j;
    } else {
      out += c;
      i += 1;
    }
  }
  return out;
}

/** One instant as the plugin time blocks write it (the year only outside the current one). */
export function flarePluginDateTime(
  ms: number,
  nowMs: number,
  strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">,
  utcOffsetMinutes?: number,
): string {
  const at = wallClock(ms, utcOffsetMinutes);
  const now = wallClock(nowMs, utcOffsetMinutes);
  return flarePluginRenderPattern(
    at.year === now.year ? strings.dateTime : strings.dateTimeYear,
    at,
  );
}

/** A time block's text: an instant, a range on one day ("…14:00–15:00") or across days ("… – …"). */
export function flarePluginTimeText(
  atMs: number,
  endMs: number | undefined | null,
  nowMs: number,
  strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">,
  utcOffsetMinutes?: number,
): string {
  const start = flarePluginDateTime(atMs, nowMs, strings, utcOffsetMinutes);
  if (endMs === undefined || endMs === null) return start;
  const a = wallClock(atMs, utcOffsetMinutes);
  const b = wallClock(endMs, utcOffsetMinutes);
  if (a.year === b.year && a.month === b.month && a.day === b.day)
    return `${start}–${pad2(b.hour)}:${pad2(b.minute)}`;
  return `${start} – ${flarePluginDateTime(endMs, nowMs, strings, utcOffsetMinutes)}`;
}

/** The countdown to `atMs` and when to draw it again (null once it has passed). */
export function flarePluginCountdown(
  atMs: number,
  nowMs: number,
  strings: FlarePluginStrings,
): { text: string; refreshMs: number | null } {
  const r = atMs - nowMs;
  if (r <= 0) return { text: strings.deadlinePassed, refreshMs: null };
  const unit = (template: string, n: number) =>
    template.replace("{n}", String(n));
  let time: string;
  if (r < 3_600_000) {
    const s = Math.floor(r / 1000);
    return {
      text: strings.remaining.replace(
        "{time}",
        `${pad2(Math.floor(s / 60))}:${pad2(s % 60)}`,
      ),
      refreshMs: 1000,
    };
  }
  if (r < 86_400_000) {
    const h = Math.floor(r / 3_600_000);
    const m = Math.floor((r % 3_600_000) / 60_000);
    time = unit(strings.hours, h) + (m ? ` ${unit(strings.minutes, m)}` : "");
  } else {
    const d = Math.floor(r / 86_400_000);
    const h = Math.floor((r % 86_400_000) / 3_600_000);
    time = unit(strings.days, d) + (h ? ` ${unit(strings.hours, h)}` : "");
  }
  return { text: strings.remaining.replace("{time}", time), refreshMs: 60_000 };
}

/**
 * An admin page's filter inputs, in the view's input order: the ones its rows block lists in `filters`, or every
 * input when the block lists none; the other inputs belong to row action forms (spec rules.rows, filterInputs).
 */
export function flarePluginFilterInputs(
  view: FlarePluginViewModel,
): FlarePluginInput[] {
  const inputs = [...(view.inputs ?? [])];
  const rows = (view.blocks ?? []).find(
    (block): block is FlarePluginRowsBlock => block.kind === "rows",
  );
  if (!rows?.filters) return inputs;
  const listed = new Set(rows.filters);
  return inputs.filter((input) => listed.has(input.id));
}

/**
 * Whether a card draws its own view details key (spec rules.detailKey): the view has a detail, is available and is
 * not embedded, no entries block shows its see all and it has no rows block (an admin page opens the detail from its
 * rows). The component also needs a host that handles openDetail.
 */
export function flarePluginShowsDetailKey(
  view: FlarePluginViewModel,
  embedded: boolean,
): boolean {
  if (!view.detail || !view.available || embedded) return false;
  return !(view.blocks ?? []).some(
    (block) =>
      block.kind === "rows" || (block.kind === "entries" && block.more),
  );
}

/**
 * The values of a reference's parents read through `value`, or null while one is empty: the control stays disabled
 * and nothing is asked for.
 */
export function flarePluginReferenceParents(
  reference: FlarePluginReference,
  value: (id: string) => unknown,
): Record<string, unknown> | null {
  const parents: Record<string, unknown> = {};
  for (const [name, id] of Object.entries(reference.parents ?? {})) {
    const parent = value(id);
    if (parent === undefined || parent === null || parent === "") return null;
    parents[name] = parent;
  }
  return parents;
}

/** The address of `url` the kit may draw: what the host fetched, never a page or a script. */
export function flarePluginProtectedMediaSource(
  url: string | undefined,
): string | undefined {
  return url && /^(blob:|https:|data:image\/)/.test(url) ? url : undefined;
}

/** The address at `urlPath` (a JSON pointer) of a protected media action's result. */
export function flarePluginProtectedMediaUrl(
  result: unknown,
  urlPath: string,
): string | undefined {
  let value = result;
  for (const key of urlPath.split("/").slice(1)) {
    if (value === null || typeof value !== "object") return undefined;
    value = (value as Record<string, unknown>)[key];
  }
  return typeof value === "string" && value ? value : undefined;
}

/** A minor amount at `scale`: the text the protocol writes when the scale is in the data. */
export function flarePluginMoneyText(minor: string, scale: number): string {
  if (
    !/^-?\d+$/.test(minor) ||
    !Number.isInteger(scale) ||
    scale < 0 ||
    scale > 18
  )
    return minor;
  if (scale === 0) return minor;
  const negative = minor.startsWith("-");
  const digits = (negative ? minor.slice(1) : minor).padStart(scale + 1, "0");
  return `${negative ? "-" : ""}${digits.slice(0, -scale)}.${digits.slice(-scale)}`;
}

/**
 * The text of a value with its format (spec of the console formats, docs/plugin-components.md): a time in the viewer's
 * zone, a money value by the scale the host knows for its asset, a reference without a label as `unavailable`
 * (a console does not show a bare id). Everything else, an unknown format included, is the plain text.
 */
export function flarePluginFormatText(
  text: string,
  format: FlarePluginFormat | undefined,
  context: {
    nowMs: number;
    strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">;
    unavailable: string;
    assetScale?: (assetId: string) => number | undefined;
    utcOffsetMinutes?: number;
  },
): string {
  switch (format?.kind) {
    case "time":
      return flarePluginDateTime(
        format.atMs,
        context.nowMs,
        context.strings,
        context.utcOffsetMinutes,
      );
    case "reference":
      return format.labelled ? text : context.unavailable;
    case "money": {
      if (format.scale !== undefined || !format.assetId) return text;
      const scale = context.assetScale?.(format.assetId);
      return scale === undefined
        ? text
        : flarePluginMoneyText(format.minor, scale);
    }
    default:
      return text;
  }
}

/** The next page's cursor of a detail view, or undefined on the last page (absent or blank). */
export function flarePluginNextCursor(
  view: FlarePluginViewModel | undefined,
): string | undefined {
  const cursor = view?.nextCursor;
  return typeof cursor === "string" && cursor.trim() ? cursor : undefined;
}

/**
 * A grouped list's header row (spec rules.entriesGrouped, entryGroupHeaders): the label, then the votes ("{count}
 * votes", in the plural form for the count) and "{percent}%" when present, joined with " · ".
 */
export function flarePluginEntryGroupHeader(
  group: FlarePluginEntryGroup,
  votes: (count: number) => string,
): string {
  const parts = [group.label];
  if (typeof group.count === "number") parts.push(votes(group.count));
  if (typeof group.percent === "number") parts.push(`${group.percent}%`);
  return parts.join(" · ");
}

/** The kit copy key of an unavailable reason: `pluginView.unavailable.<reason in camel case>`. */
export function flarePluginUnavailableKey(
  reason: FlarePluginUnavailableReason,
): string {
  return `pluginView.unavailable.${reason.replace(/_(\w)/g, (_, c: string) => c.toUpperCase())}`;
}

/** The reason line: the reason's copy, led by the envelope's displayName when the host has one. */
export function flarePluginReasonLine(
  reasonText: string,
  displayName?: string,
): string {
  const name = displayName?.trim();
  return name ? `${name} · ${reasonText}` : reasonText;
}

/** The name drawn for a user id the host could not resolve: the id's tail, {@link flareIdTail} (its last 4 scalars). */
export function flarePluginFallbackName(userId: string): string {
  return flareIdTail(userId);
}

// ── badges and the choices limit ─────────────────────────────────────────────

const TONES: ReadonlySet<string> = new Set<FlarePluginTone>([
  "neutral",
  "info",
  "success",
  "warning",
  "danger",
]);
/** A badge's tone as drawn: one of PluginTone, anything else neutral (spec rules.badge). */
export function flarePluginBadgeTone(tone: unknown): FlarePluginTone {
  return typeof tone === "string" && TONES.has(tone)
    ? (tone as FlarePluginTone)
    : "neutral";
}

/** A multiple choice's cap, or undefined (single choice, absent or not a positive count). */
export function flarePluginChoiceCap(
  block: FlarePluginChoicesBlock,
): number | undefined {
  const max = block.maxSelections;
  return block.multiple &&
    typeof max === "number" &&
    Number.isInteger(max) &&
    max > 0
    ? max
    : undefined;
}

/** Whether option `index` is disabled by the cap: the draft is full and does not hold it (spec rules.maxSelections). */
export function flarePluginChoiceCapped(
  block: FlarePluginChoicesBlock,
  draft: ReadonlyArray<number>,
  index: number,
): boolean {
  const cap = flarePluginChoiceCap(block);
  return cap !== undefined && draft.length >= cap && !draft.includes(index);
}

/** Whether a draft fits the cap (always without one). */
export function flarePluginWithinCap(
  block: FlarePluginChoicesBlock,
  draft: ReadonlyArray<number>,
): boolean {
  const cap = flarePluginChoiceCap(block);
  return cap === undefined || draft.length <= cap;
}

// ── plugin pages ─────────────────────────────────────────────────────────────

/** The rows to draw: in order, each key once, the first kept (spec rules.pageRows). */
export function flarePluginRowsOnce(
  rows: ReadonlyArray<FlarePluginRow>,
): FlarePluginRow[] {
  const seen = new Set<string>();
  return rows.filter((row) =>
    seen.has(row.key) ? false : (seen.add(row.key), true),
  );
}

/**
 * A list item's two lines (spec rules.pageRows): the first cell, and the other cells in column order (time columns
 * formatted as in `time`, blank cells skipped) joined with " · ", or null when none is left.
 */
export function flarePluginRowTexts(
  block: Pick<FlarePluginRowsBlock, "columns">,
  row: FlarePluginRow,
  nowMs: number,
  strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">,
  utcOffsetMinutes?: number,
): string[] {
  return block.columns.map((column, index) => {
    const cell = row.cells[index];
    if (column.format === "time" && typeof cell?.timeMs === "number")
      return flarePluginDateTime(cell.timeMs, nowMs, strings, utcOffsetMinutes);
    return cell?.text ?? "";
  });
}
export function flarePluginRowLines(
  block: Pick<FlarePluginRowsBlock, "columns">,
  row: FlarePluginRow,
  nowMs: number,
  strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">,
  utcOffsetMinutes?: number,
): { primary: string; secondary: string | null } {
  const texts = flarePluginRowTexts(
    block,
    row,
    nowMs,
    strings,
    utcOffsetMinutes,
  );
  const rest = texts.slice(1).filter((text) => text.trim());
  return {
    primary: texts[0] ?? "",
    secondary: rest.length ? rest.join(" · ") : null,
  };
}

/** A page's state from what the host passes (spec rules.page). */
export function flarePluginPageState(
  view: FlarePluginViewModel | undefined,
  loading: boolean,
  error: string | undefined,
): FlarePluginPageState {
  if (view) return view.available ? "loaded" : "unavailable";
  return error && !loading ? "error" : "loading";
}

/**
 * A page's select filters (spec rules.pageFilters): with a rows block, the filter inputs of kind select, each with
 * all (value null, labelled `all`) and its choices; selected is the host's value when it is a choice, else null.
 */
export function flarePluginPageFilters(
  view: FlarePluginViewModel,
  filters: Record<string, unknown> | undefined,
  all: string,
): FlarePluginPageFilter[] {
  if (!(view.blocks ?? []).some((block) => block.kind === "rows")) return [];
  return flarePluginFilterInputs(view)
    .filter((input) => input.kind === "select" && input.choices?.length)
    .map((input) => {
      const choices = input.choices ?? [];
      const value = filters?.[input.id];
      const selected =
        typeof value === "string" &&
        choices.some((choice) => choice.value === value)
          ? value
          : null;
      return {
        input,
        tabs: [
          { value: null, label: all },
          ...choices.map((choice) => ({
            value: choice.value,
            label: choice.label,
          })),
        ],
        selected,
      };
    });
}

/** The host's filters with one input set to `value`, or without it for all (null). */
export function flarePluginPageFilterValues(
  filters: Record<string, unknown> | undefined,
  inputId: string,
  value: string | null,
): Record<string, unknown> {
  const next = { ...(filters ?? {}) };
  if (value === null) delete next[inputId];
  else next[inputId] = value;
  return next;
}

/** The payload of an action run on a page: the page, the view's data when it has one, and what the action carries. */
export function flarePluginPagePayload(
  page: FlarePluginPageRef,
  view: FlarePluginPageViewModel | undefined,
  payload: FlarePluginActionPayload,
): FlarePluginPageActionPayload {
  return {
    page: { pluginId: page.pluginId, page: page.page },
    ...(view?.data ? { data: view.data } : {}),
    ...payload,
  };
}

// ── forms ──────────────────────────────────────────────────────────────────

/** Characters as the core SDK counts them: Unicode code points. */
const codePoints = (s: string) => [...s].length;
const DEFAULT_MAX_LENGTH: Partial<Record<FlarePluginInputKind, number>> = {
  text: 256,
  password: 256,
  textarea: 2000,
  options: 100,
};
const DEFAULT_MAX_ITEMS: Partial<Record<FlarePluginInputKind, number>> = {
  options: 50,
  members: 500,
};

export function flarePluginMaxLength(
  input: FlarePluginInput,
): number | undefined {
  return input.maxLength ?? DEFAULT_MAX_LENGTH[input.kind];
}

/** Most option rows / members of an input. */
export function flarePluginMaxItems(input: FlarePluginInput): number {
  return input.max ?? DEFAULT_MAX_ITEMS[input.kind] ?? 1;
}

/** Fewest option rows the editor keeps. */
export function flarePluginMinRows(input: FlarePluginInput): number {
  return Math.max(input.min ?? 1, 1);
}

/** The editable draft of one input: `values[id]`, else its default. */
export function flarePluginDraftValue(
  input: FlarePluginInput,
  values: Record<string, unknown> | undefined,
): unknown {
  const raw = values && input.id in values ? values[input.id] : input.default;
  switch (input.kind) {
    case "file":
      return flarePluginFileValue(raw) ? { fileId: raw.fileId } : null;
    case "password":
      return "";
    case "toggle":
      return raw === undefined || raw === null ? false : Boolean(raw);
    case "options":
      return Array.isArray(raw)
        ? raw.map((x) => (typeof x === "string" ? x : String(x ?? "")))
        : Array.from({ length: flarePluginMinRows(input) }, () => "");
    case "members":
      return Array.isArray(raw)
        ? raw.filter((x): x is string => typeof x === "string")
        : [];
    case "text":
    case "textarea":
      return typeof raw === "string" ? raw : "";
    case "select":
      return typeof raw === "string" ? raw : "";
    case "number":
    case "datetime":
      return typeof raw === "number" && Number.isFinite(raw) ? raw : null;
  }
  return raw;
}

export function flarePluginDraft(
  inputs: ReadonlyArray<FlarePluginInput>,
  values: Record<string, unknown> | undefined,
): Record<string, unknown> {
  const draft = Object.fromEntries(
    inputs.map((input) => [input.id, flarePluginDraftValue(input, values)]),
  );
  // Defaults seed once at initialization. A later discriminator change never
  // falls back to these defaults, including ali -> wechat while still visible.
  for (const input of inputs) if (!flarePluginInputVisible(input, inputs, draft)) delete draft[input.id];
  return draft;
}

const optionItems = (value: unknown) =>
  (Array.isArray(value) ? value : [])
    .map((x) => String(x ?? "").trim())
    .filter(Boolean);

/** The client's light check of one input: required and length. */
export function flarePluginCheckInput(
  input: FlarePluginInput,
  draft: unknown,
): FlarePluginFormIssue | null {
  const limit = flarePluginMaxLength(input);
  switch (input.kind) {
    case "file":
      return draft == null ? (input.required ? "required" : null) : flarePluginFileValue(draft) ? null : "invalidType";
    case "password":
    case "text":
    case "textarea": {
      const text = String(draft ?? "").trim();
      if (input.required && !text) return "required";
      if (limit !== undefined && codePoints(text) > limit) return "tooLong";
      return null;
    }
    case "number":
    case "datetime":
      return input.required && (draft === null || draft === undefined)
        ? "required"
        : null;
    case "select":
      return input.required && !draft ? "required" : null;
    case "options": {
      const items = optionItems(draft);
      if (input.required && !items.length) return "required";
      if (limit !== undefined && items.some((item) => codePoints(item) > limit))
        return "tooLong";
      return null;
    }
    case "members":
      return input.required && !(Array.isArray(draft) && draft.length)
        ? "required"
        : null;
    default:
      return null;
  }
}

export function flarePluginCheckForm(
  inputs: ReadonlyArray<FlarePluginInput>,
  draft: Record<string, unknown>,
): FlarePluginFormError[] {
  const errors: FlarePluginFormError[] = [];
  for (const input of flarePluginVisibleInputs(inputs, draft)) {
    const issue = flarePluginCheckInput(input, draft[input.id]);
    if (issue) errors.push({ input: input.id, issue });
  }
  return errors;
}

/** What submit hands over: trimmed text, cleaned option rows, only the inputs with a value. */
export function flarePluginFormValues(
  inputs: ReadonlyArray<FlarePluginInput>,
  draft: Record<string, unknown>,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const input of flarePluginVisibleInputs(inputs, draft)) {
    const value = draft[input.id];
    switch (input.kind) {
      case "file":
        if (flarePluginFileValue(value)) out[input.id] = { fileId: value.fileId };
        break;
      case "password":
        if (typeof value === "string" && value) out[input.id] = value;
        break;
      case "text":
      case "textarea": {
        const text = String(value ?? "").trim();
        if (text) out[input.id] = text;
        break;
      }
      case "number":
      case "datetime":
        if (typeof value === "number" && Number.isFinite(value))
          out[input.id] = value;
        break;
      case "toggle":
        out[input.id] = Boolean(value);
        break;
      case "select":
        if (typeof value === "string" && value) out[input.id] = value;
        break;
      case "options": {
        const items = optionItems(value);
        if (items.length) out[input.id] = items;
        break;
      }
      case "members":
        if (Array.isArray(value) && value.length) out[input.id] = [...value];
        break;
    }
  }
  return out;
}

/** The words for one form error under its input. */
export function flarePluginIssueText(
  issue: FlarePluginFormIssue,
  input: FlarePluginInput | undefined,
  strings: FlarePluginStrings,
): string {
  switch (issue) {
    case "required":
      return strings.required;
    case "tooLong":
      return strings.tooLong;
    case "outOfRange":
      return strings.outOfRange;
    case "duplicateItem":
      return strings.duplicateItem;
    case "tooFewItems":
      return strings.tooFewItems.replace("{n}", String(input?.min ?? 1));
    case "tooManyItems":
      return strings.tooManyItems.replace(
        "{n}",
        String(input ? flarePluginMaxItems(input) : 1),
      );
    default:
      return strings.invalid;
  }
}

/** "{length}/{max}" under a text or textarea: what was typed, in code points. */
export function flarePluginCounter(
  input: FlarePluginInput,
  draft: unknown,
): string | null {
  if (input.kind !== "text" && input.kind !== "textarea") return null;
  const limit = flarePluginMaxLength(input);
  return limit === undefined
    ? null
    : `${codePoints(String(draft ?? ""))}/${limit}`;
}
