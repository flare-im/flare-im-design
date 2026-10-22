/**
 * Presentation only. The core SDK resolves declarations, leases, state layers and fallback into a
 * ResolvedPluginView (flare-plugin-protocol ui.rs / blocks.rs / inputs.rs); the kit draws that shape and
 * reads no paths. The pure rules the kit draws from (time and countdown copy, the form's light check and
 * submitted values, issue texts, the fallback name) live here so every kit can test them against
 * spec/plugin-view-vectors.json.
 */

export type FlarePluginTone = "neutral" | "info" | "success" | "warning" | "danger";
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
}

export interface FlarePluginField { label: string; value: string }

export interface FlarePluginTextBlock { kind: "text"; text: string; maxLines?: number; style?: "body" | "title" | "secondary" }
export interface FlarePluginFieldsBlock { kind: "fields"; fields: ReadonlyArray<FlarePluginField> }
export interface FlarePluginChoice { index: number; label: string; selected: boolean; count?: number; percent?: number }
export interface FlarePluginChoicesBlock {
  kind: "choices";
  options: ReadonlyArray<FlarePluginChoice>;
  multiple: boolean;
  voted: boolean;
  closed: boolean;
  showResults: boolean;
  total?: number;
  inputName: string;
  /** The block's submit action, present while the viewer can choose. */
  action?: FlarePluginAction;
}
export interface FlarePluginEntry { index: number; text: string; name?: string; userId?: string }
export interface FlarePluginEntriesBlock {
  kind: "entries";
  items: ReadonlyArray<FlarePluginEntry>;
  numbered: boolean;
  total: number;
  more: boolean;
  emptyText?: string;
}
export interface FlarePluginPeopleGroup { label: string; userIds: ReadonlyArray<string>; count: number; tone?: FlarePluginTone }
export interface FlarePluginPeopleBlock { kind: "people"; groups: ReadonlyArray<FlarePluginPeopleGroup> }
export interface FlarePluginStatusBlock { kind: "status"; label?: string; text: string; tone: FlarePluginTone }
export interface FlarePluginProgressBlock { kind: "progress"; label?: string; value: number; total: number; percent: number }
export interface FlarePluginTimeBlock { kind: "time"; label?: string; atMs: number; endMs?: number; countdown: boolean }
export interface FlarePluginDividerBlock { kind: "divider" }
export interface FlarePluginNoteBlock { kind: "note"; text: string; tone?: FlarePluginTone }
export interface FlarePluginRowCell { text: string; timeMs?: number }
export interface FlarePluginRow {
  key: string;
  cells: ReadonlyArray<FlarePluginRowCell>;
  actions: ReadonlyArray<{ id: string; input: unknown }>;
  detailInput?: unknown;
}
/** Admin pages only (Vue). */
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
  | FlarePluginRowsBlock;

export type FlarePluginInputKind = "text" | "textarea" | "number" | "toggle" | "select" | "datetime" | "options" | "members";
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
  choices?: ReadonlyArray<{ value: string; label: string }>;
}
export type FlarePluginFormIssue =
  | "required" | "unknown" | "invalidType" | "tooLong" | "outOfRange"
  | "notAChoice" | "tooFewItems" | "tooManyItems" | "invalidItem" | "duplicateItem";
export interface FlarePluginFormError { input: string; issue: FlarePluginFormIssue }

/** What the host's resolveUser answers for a user id. */
export interface FlarePluginUser { name: string; avatarUrl?: string }
export type FlarePluginResolveUser = (userId: string) => FlarePluginUser | Promise<FlarePluginUser | undefined> | undefined;
/** A candidate for a members input. */
export interface FlarePluginMember { userId: string; name: string; avatarUrl?: string }
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
  /** The row of a rows action (admin pages). */
  row?: { key: string; input: unknown };
}

export interface FlarePluginViewModel {
  available: boolean;
  title: string;
  fields: ReadonlyArray<FlarePluginField>;
  actions: ReadonlyArray<FlarePluginAction>;
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

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const pad2 = (n: number) => String(n).padStart(2, "0");

interface WallClock { year: number; month: number; day: number; hour: number; minute: number }

/** Local wall clock of an instant: the device zone, or a fixed offset (tests). */
function wallClock(ms: number, utcOffsetMinutes?: number): WallClock {
  if (utcOffsetMinutes === undefined) {
    const d = new Date(ms);
    return { year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate(), hour: d.getHours(), minute: d.getMinutes() };
  }
  const d = new Date(ms + utcOffsetMinutes * 60_000);
  return { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate(), hour: d.getUTCHours(), minute: d.getUTCMinutes() };
}

/** Renders a date-time pattern: y year, M month, MMM Jan..Dec, d day, HH hour, mm minute; the rest is literal. */
export function flarePluginRenderPattern(pattern: string, at: WallClock): string {
  let out = "";
  for (let i = 0; i < pattern.length;) {
    const c = pattern[i];
    if ("yMdHm".includes(c)) {
      let j = i;
      while (j < pattern.length && pattern[j] === c) j += 1;
      const run = pattern.slice(i, j);
      out += run === "y" ? String(at.year)
        : run === "M" ? String(at.month)
        : run === "MMM" ? MONTHS[at.month - 1]
        : run === "d" ? String(at.day)
        : run === "HH" ? pad2(at.hour)
        : run === "mm" ? pad2(at.minute)
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
export function flarePluginDateTime(ms: number, nowMs: number, strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">, utcOffsetMinutes?: number): string {
  const at = wallClock(ms, utcOffsetMinutes);
  const now = wallClock(nowMs, utcOffsetMinutes);
  return flarePluginRenderPattern(at.year === now.year ? strings.dateTime : strings.dateTimeYear, at);
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
  if (a.year === b.year && a.month === b.month && a.day === b.day) return `${start}–${pad2(b.hour)}:${pad2(b.minute)}`;
  return `${start} – ${flarePluginDateTime(endMs, nowMs, strings, utcOffsetMinutes)}`;
}

/** The countdown to `atMs` and when to draw it again (null once it has passed). */
export function flarePluginCountdown(atMs: number, nowMs: number, strings: FlarePluginStrings): { text: string; refreshMs: number | null } {
  const r = atMs - nowMs;
  if (r <= 0) return { text: strings.deadlinePassed, refreshMs: null };
  const unit = (template: string, n: number) => template.replace("{n}", String(n));
  let time: string;
  if (r < 3_600_000) {
    const s = Math.floor(r / 1000);
    return { text: strings.remaining.replace("{time}", `${pad2(Math.floor(s / 60))}:${pad2(s % 60)}`), refreshMs: 1000 };
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
export function flarePluginFilterInputs(view: FlarePluginViewModel): FlarePluginInput[] {
  const inputs = [...(view.inputs ?? [])];
  const rows = (view.blocks ?? []).find((block): block is FlarePluginRowsBlock => block.kind === "rows");
  if (!rows?.filters) return inputs;
  const listed = new Set(rows.filters);
  return inputs.filter((input) => listed.has(input.id));
}

/**
 * Whether a card draws its own view details key (spec rules.detailKey): the view has a detail, is available and is
 * not embedded, no entries block shows its see all and it has no rows block (an admin page opens the detail from its
 * rows). The component also needs a host that handles openDetail.
 */
export function flarePluginShowsDetailKey(view: FlarePluginViewModel, embedded: boolean): boolean {
  if (!view.detail || !view.available || embedded) return false;
  return !(view.blocks ?? []).some((block) => block.kind === "rows" || (block.kind === "entries" && block.more));
}

/** The next page's cursor of a detail view, or undefined on the last page (absent or blank). */
export function flarePluginNextCursor(view: FlarePluginViewModel | undefined): string | undefined {
  const cursor = view?.nextCursor;
  return typeof cursor === "string" && cursor.trim() ? cursor : undefined;
}

/** The name drawn for a user id the host could not resolve: its last 4 characters. */
export function flarePluginFallbackName(userId: string): string {
  return userId.length > 4 ? userId.slice(-4) : userId;
}

// ── forms ──────────────────────────────────────────────────────────────────

/** Characters as the core SDK counts them: Unicode code points. */
const codePoints = (s: string) => [...s].length;
const DEFAULT_MAX_LENGTH: Partial<Record<FlarePluginInputKind, number>> = { text: 256, textarea: 2000, options: 100 };
const DEFAULT_MAX_ITEMS: Partial<Record<FlarePluginInputKind, number>> = { options: 50, members: 500 };

export function flarePluginMaxLength(input: FlarePluginInput): number | undefined {
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
export function flarePluginDraftValue(input: FlarePluginInput, values: Record<string, unknown> | undefined): unknown {
  const raw = values && input.id in values ? values[input.id] : input.default;
  switch (input.kind) {
    case "toggle": return raw === undefined || raw === null ? false : Boolean(raw);
    case "options": return Array.isArray(raw) ? raw.map((x) => (typeof x === "string" ? x : String(x ?? ""))) : Array.from({ length: flarePluginMinRows(input) }, () => "");
    case "members": return Array.isArray(raw) ? raw.filter((x): x is string => typeof x === "string") : [];
    case "text":
    case "textarea": return typeof raw === "string" ? raw : "";
    case "select": return typeof raw === "string" ? raw : "";
    case "number":
    case "datetime": return typeof raw === "number" && Number.isFinite(raw) ? raw : null;
  }
  return raw;
}

export function flarePluginDraft(inputs: ReadonlyArray<FlarePluginInput>, values: Record<string, unknown> | undefined): Record<string, unknown> {
  return Object.fromEntries(inputs.map((input) => [input.id, flarePluginDraftValue(input, values)]));
}

const optionItems = (value: unknown) => (Array.isArray(value) ? value : []).map((x) => String(x ?? "").trim()).filter(Boolean);

/** The client's light check of one input: required and length. */
export function flarePluginCheckInput(input: FlarePluginInput, draft: unknown): FlarePluginFormIssue | null {
  const limit = flarePluginMaxLength(input);
  switch (input.kind) {
    case "text":
    case "textarea": {
      const text = String(draft ?? "").trim();
      if (input.required && !text) return "required";
      if (limit !== undefined && codePoints(text) > limit) return "tooLong";
      return null;
    }
    case "number":
    case "datetime": return input.required && (draft === null || draft === undefined) ? "required" : null;
    case "select": return input.required && !draft ? "required" : null;
    case "options": {
      const items = optionItems(draft);
      if (input.required && !items.length) return "required";
      if (limit !== undefined && items.some((item) => codePoints(item) > limit)) return "tooLong";
      return null;
    }
    case "members": return input.required && !(Array.isArray(draft) && draft.length) ? "required" : null;
    default: return null;
  }
}

export function flarePluginCheckForm(inputs: ReadonlyArray<FlarePluginInput>, draft: Record<string, unknown>): FlarePluginFormError[] {
  const errors: FlarePluginFormError[] = [];
  for (const input of inputs) {
    const issue = flarePluginCheckInput(input, draft[input.id]);
    if (issue) errors.push({ input: input.id, issue });
  }
  return errors;
}

/** What submit hands over: trimmed text, cleaned option rows, only the inputs with a value. */
export function flarePluginFormValues(inputs: ReadonlyArray<FlarePluginInput>, draft: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const input of inputs) {
    const value = draft[input.id];
    switch (input.kind) {
      case "text":
      case "textarea": {
        const text = String(value ?? "").trim();
        if (text) out[input.id] = text;
        break;
      }
      case "number":
      case "datetime":
        if (typeof value === "number" && Number.isFinite(value)) out[input.id] = value;
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
export function flarePluginIssueText(issue: FlarePluginFormIssue, input: FlarePluginInput | undefined, strings: FlarePluginStrings): string {
  switch (issue) {
    case "required": return strings.required;
    case "tooLong": return strings.tooLong;
    case "outOfRange": return strings.outOfRange;
    case "duplicateItem": return strings.duplicateItem;
    case "tooFewItems": return strings.tooFewItems.replace("{n}", String(input?.min ?? 1));
    case "tooManyItems": return strings.tooManyItems.replace("{n}", String(input ? flarePluginMaxItems(input) : 1));
    default: return strings.invalid;
  }
}

/** "{length}/{max}" under a text or textarea: what was typed, in code points. */
export function flarePluginCounter(input: FlarePluginInput, draft: unknown): string | null {
  if (input.kind !== "text" && input.kind !== "textarea") return null;
  const limit = flarePluginMaxLength(input);
  return limit === undefined ? null : `${codePoints(String(draft ?? ""))}/${limit}`;
}
