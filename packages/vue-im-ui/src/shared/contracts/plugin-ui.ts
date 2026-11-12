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
  | { kind: "time"; atMs: number }
  /** The value in percent (a ratio already multiplied by 100); the text is already "12.5%". */
  | { kind: "percent"; percent: number; decimals: number }
  /** Milliseconds: the kit writes them in the viewer's language (flarePluginDurationText). */
  | { kind: "duration"; ms: number }
  /** A count: the kit writes it compact in the viewer's language (flarePluginCompactCount). */
  | { kind: "count"; count: number }
  /** A size in bytes; the text is already "1.5 MB". */
  | { kind: "bytes"; bytes: number };

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
  /** When it happened (epoch ms), drawn after the text (flarePluginDateTime). */
  timeMs?: number;
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
  /** A page list puts its rows under day headings by the first time column (flarePluginRowDayHeadings). */
  groupByDay?: boolean;
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
/** Blocks under a heading, collapsible (vocabulary 2). Never holds a section, rows or protected media. */
export interface FlarePluginSectionBlock {
  kind: "section";
  label?: string;
  collapsed: boolean;
  blocks: ReadonlyArray<FlarePluginBlock>;
}
export type FlarePluginTrendDirection = "up" | "down" | "flat";
/** How a figure moved: the text as sent and its direction. */
export interface FlarePluginTrend {
  text: string;
  direction: FlarePluginTrendDirection;
}
export interface FlarePluginStat {
  label: string;
  /** The plain text, whatever `format` says. */
  value: string;
  format?: FlarePluginFormat;
  trend?: FlarePluginTrend;
  tone?: FlarePluginTone;
}
/** 2 to 6 figures side by side. */
export interface FlarePluginStatsBlock {
  kind: "stats";
  items: ReadonlyArray<FlarePluginStat>;
}
export type FlarePluginChartKind = "bar" | "line" | "donut";
export interface FlarePluginChartPoint {
  label: string;
  value: number;
  /** The value as text, through the block's format. */
  text: string;
}
export interface FlarePluginChartSeries {
  label?: string;
  points: ReadonlyArray<FlarePluginChartPoint>;
}
/** Up to 3 series (one for a donut) of up to 60 points, drawn from kit tokens with no chart library. */
export interface FlarePluginChartBlock {
  kind: "chart";
  chartKind: FlarePluginChartKind;
  series: ReadonlyArray<FlarePluginChartSeries>;
  /** Shown instead of a chart when no series has a point. */
  emptyText?: string;
}
export type FlarePluginImageAspect = "1:1" | "4:3" | "16:9" | "3:4";
/** A picture: a package asset, or a privately uploaded file of the plugin. The host turns either into an address. */
export interface FlarePluginImageBlock {
  kind: "image";
  asset?: string;
  fileId?: string;
  aspect: FlarePluginImageAspect;
  alt: string;
}
/** What `resolveImage` is asked for. */
export interface FlarePluginImageSource {
  asset?: string;
  fileId?: string;
}
/** A QR code of `value`; `refreshOperation` (a query) returns a fresh one, read at the block's own paths. */
export interface FlarePluginQrBlock {
  kind: "qr";
  value: string;
  label?: string;
  caption?: string;
  refreshOperation?: string;
  valuePath: string;
  expiresAtPath?: string;
  expiresAtMs?: number;
}
/** What `qrRefresh` carries: the host runs the query and passes back a view with the fresh code. */
export interface FlarePluginQrRefresh {
  operation: string;
  valuePath: string;
  expiresAtPath?: string;
}
export type FlarePluginHeroTone = "neutral" | "positive" | "warning" | "brand";
/** The page's lead figure (one per document): a balance, an amount, with up to 3 owned actions. */
export interface FlarePluginHeroBlock {
  kind: "hero";
  label?: string;
  value: string;
  /** The value is an amount. */
  amount: boolean;
  format?: FlarePluginFormat;
  subtitle?: string;
  tone: FlarePluginHeroTone;
  actions?: ReadonlyArray<FlarePluginAction>;
  /** The viewer may hide the value: the hero offers an eye toggle and draws dots while hidden. */
  maskable?: boolean;
}
export type FlarePluginStepState = "pending" | "current" | "done" | "failed";
export interface FlarePluginStepsBlock {
  kind: "steps";
  items: ReadonlyArray<{ label: string; state: FlarePluginStepState }>;
}
export type FlarePluginBannerTone = "info" | "success" | "warning" | "danger";
/** A prominent notice (at most 2 per document) with an optional owned action. */
export interface FlarePluginBannerBlock {
  kind: "banner";
  tone: FlarePluginBannerTone;
  text: string;
  action?: FlarePluginAction;
}
export interface FlarePluginTimelineItem {
  atMs: number;
  title: string;
  detail?: string;
  status?: FlarePluginBadge;
}
/** Up to 50 dated items, newest as the plugin ordered them. */
export interface FlarePluginTimelineBlock {
  kind: "timeline";
  items: ReadonlyArray<FlarePluginTimelineItem>;
  emptyText?: string;
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
  | FlarePluginProtectedMediaBlock
  | FlarePluginSectionBlock
  | FlarePluginStatsBlock
  | FlarePluginChartBlock
  | FlarePluginImageBlock
  | FlarePluginQrBlock
  | FlarePluginHeroBlock
  | FlarePluginStepsBlock
  | FlarePluginBannerBlock
  | FlarePluginTimelineBlock;

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
  | "members"
  | "money"
  | "image"
  | "document";
/** The amount rules of a money input, read by the core SDK: no paths are left. */
export interface FlarePluginMoneyRules {
  currency?: string;
  /** Fraction digits the amount may have; 2 when absent. */
  scale?: number;
  /** Bounds as decimal strings. */
  min?: string;
  max?: string;
}
/** A money input's value: a decimal string without sign or exponent, and the currency. */
export interface FlarePluginMoneyValue {
  amount: string;
  currency: string;
}
export type FlarePluginDocumentSide = "front" | "back" | "holding";
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
  /** file, image and document: what may be uploaded and how. */
  file?: FlarePluginFilePolicy;
  /** money only. */
  money?: FlarePluginMoneyRules;
  /** document only: which side of the document. */
  side?: FlarePluginDocumentSide;
  showWhen?: FlarePluginInputCondition;
}
/** Inputs whose value is an uploaded file's `{fileId}`: file, image and document. */
export function flarePluginIsUpload(kind: FlarePluginInputKind | string): boolean {
  return kind === "file" || kind === "image" || kind === "document";
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
  | "unbound_copy"
  /** This build cannot draw it; `minBuild` names the first one that can, when known (FlarePluginUpgradeNotice). */
  | "upgrade_required";

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
  /** upgrade_required: the first build that draws it, when the plugin declared one. */
  minBuild?: number;
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
  /** "{n} 秒": the smallest unit of a duration. */
  seconds?: string;
  /** The count format's compact units, `exponent:suffix` pairs joined by `|` ("4:万|8:亿"). */
  countUnits?: string;
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

/** What a hidden value reads as (a maskable hero). */
export const FLARE_PLUGIN_MASKED_VALUE = "••••";

/** The date part of a date-time pattern ("M月d日 HH:mm" → "M月d日"). */
function datePattern(pattern: string): string {
  return pattern.replace(/[\s,]*HH:mm[\s,]*/, " ").replace(/[\s,]+$/, "").trim();
}

/**
 * The day headings of a page list grouped by day (spec rules.rowsGroupByDay): one per row, present on the first row
 * of each day — "today", "yesterday", else the date (the year only outside the current one) — by the row's first
 * time column; a row without a time starts no group.
 */
export function flarePluginRowDayHeadings(
  block: Pick<FlarePluginRowsBlock, "columns" | "rows" | "groupByDay">,
  nowMs: number,
  strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">,
  labels: { today: string; yesterday: string },
  utcOffsetMinutes?: number,
): ReadonlyArray<string | undefined> {
  const column = block.columns.findIndex((c) => c.format === "time");
  if (!block.groupByDay || column < 0) return block.rows.map(() => undefined);
  const key = (c: WallClock) => `${c.year}-${c.month}-${c.day}`;
  const now = wallClock(nowMs, utcOffsetMinutes);
  const today = key(now);
  const yesterday = key(wallClock(nowMs - 86_400_000, utcOffsetMinutes));
  let previous: string | undefined;
  return block.rows.map((row) => {
    const ms = row.cells[column]?.timeMs;
    if (typeof ms !== "number") return undefined;
    const at = wallClock(ms, utcOffsetMinutes);
    const day = key(at);
    if (day === previous) return undefined;
    previous = day;
    if (day === today) return labels.today;
    if (day === yesterday) return labels.yesterday;
    return flarePluginRenderPattern(
      datePattern(at.year === now.year ? strings.dateTime : strings.dateTimeYear),
      at,
    );
  });
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

/**
 * A Tauri desktop host's local file address, as `convertFileSrc` writes it: `asset://localhost/<path>` (macOS, Linux)
 * or `http://asset.localhost/<path>` (Windows). The webview serves these only inside the app's asset scope, so they
 * read a file the host chose; any other host, a port or credentials is not one.
 */
export function flareIsTauriAssetAddress(url: string): boolean {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  if (parsed.username || parsed.password || parsed.port) return false;
  return (parsed.protocol === "asset:" && parsed.hostname === "localhost")
    || ((parsed.protocol === "http:" || parsed.protocol === "https:") && parsed.hostname === "asset.localhost");
}

/**
 * The address of `url` the kit may draw: what the host fetched (blob:, https:, data:image) or a Tauri host's local
 * file address ({@link flareIsTauriAssetAddress}), never a page or a script.
 */
export function flarePluginProtectedMediaSource(
  url: string | undefined,
): string | undefined {
  if (!url) return undefined;
  return /^(blob:|https:|data:image\/)/.test(url) || flareIsTauriAssetAddress(url) ? url : undefined;
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
    strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear"> &
      Partial<Pick<FlarePluginStrings, "days" | "hours" | "minutes" | "seconds" | "countUnits">>;
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
    case "count":
      return context.strings.countUnits !== undefined && Number.isFinite(format.count)
        ? flarePluginCompactCount(format.count, context.strings.countUnits)
        : text;
    case "duration": {
      const { days, hours, minutes, seconds } = context.strings;
      return days && hours && minutes && seconds && Number.isFinite(format.ms)
        ? flarePluginDurationText(format.ms, { days, hours, minutes, seconds })
        : text;
    }
    default:
      return text;
  }
}

/**
 * A count written compact (spec formats2.count): the largest unit of `units` ("4:万|8:亿", "3:K|6:M|9:B": exponent and
 * suffix pairs) the count reaches, with one decimal cut (never rounded up) and a trailing ".0" dropped; below every
 * unit, the count itself.
 */
export function flarePluginCompactCount(count: number, units: string): string {
  const whole = Math.trunc(count);
  const sign = whole < 0 ? "-" : "";
  const n = Math.abs(whole);
  const parsed = units
    .split("|")
    .map((pair) => {
      const at = pair.indexOf(":");
      return { exponent: Number(pair.slice(0, at)), suffix: pair.slice(at + 1) };
    })
    .filter((unit) => Number.isInteger(unit.exponent) && unit.exponent > 0 && unit.suffix)
    .sort((a, b) => b.exponent - a.exponent);
  const unit = parsed.find((candidate) => n >= 10 ** candidate.exponent);
  if (!unit) return `${sign}${n}`;
  const tenths = Math.floor((n * 10) / 10 ** unit.exponent);
  const text = tenths % 10 === 0 ? String(tenths / 10) : `${Math.floor(tenths / 10)}.${tenths % 10}`;
  return `${sign}${text}${unit.suffix}`;
}

/**
 * A duration in the viewer's words (spec formats2.duration): whole seconds; under a minute the seconds alone, else
 * the largest unit that is not zero and, when it is not zero, the next one ("2 小时 5 分钟", "1 天").
 */
export function flarePluginDurationText(
  ms: number,
  units: { days: string; hours: string; minutes: string; seconds: string },
): string {
  const total = Math.floor(Math.max(0, ms) / 1000);
  const unit = (template: string, n: number) => template.replace("{n}", String(n));
  if (total < 60) return unit(units.seconds, total);
  const parts: [number, string][] = [
    [Math.floor(total / 86_400), units.days],
    [Math.floor((total % 86_400) / 3_600), units.hours],
    [Math.floor((total % 3_600) / 60), units.minutes],
    [total % 60, units.seconds],
  ];
  const first = parts.findIndex(([n]) => n > 0);
  const [n, template] = parts[first];
  const next = parts[first + 1];
  return unit(template, n) + (next && next[0] > 0 ? ` ${unit(next[1], next[0])}` : "");
}

// ── vocabulary 2 blocks ─────────────────────────────────────────────────────

const STEP_STATES: ReadonlySet<string> = new Set(["pending", "current", "done", "failed"]);
/** A step's state as drawn: one of the four, anything else pending (spec blocks2.steps). */
export function flarePluginStepState(state: unknown): FlarePluginStepState {
  return typeof state === "string" && STEP_STATES.has(state) ? (state as FlarePluginStepState) : "pending";
}

/** A trend's direction as drawn: up, down, anything else flat. */
export function flarePluginTrendDirection(direction: unknown): FlarePluginTrendDirection {
  return direction === "up" || direction === "down" ? direction : "flat";
}

/** A banner's tone as drawn: one of the four, anything else info. */
export function flarePluginBannerTone(tone: unknown): FlarePluginBannerTone {
  return tone === "success" || tone === "warning" || tone === "danger" ? tone : "info";
}

/** A hero's tone as drawn: one of the four, anything else neutral. */
export function flarePluginHeroTone(tone: unknown): FlarePluginHeroTone {
  return tone === "positive" || tone === "warning" || tone === "brand" ? tone : "neutral";
}

/** Width over height of an image block's aspect; an unknown one is square. */
export function flarePluginImageRatio(aspect: unknown): number {
  switch (aspect) {
    case "4:3":
      return 4 / 3;
    case "16:9":
      return 16 / 9;
    case "3:4":
      return 3 / 4;
    default:
      return 1;
  }
}

/** Whether a QR code has expired: it names an expiry and that instant has come (spec blocks2.qr). */
export function flarePluginQrExpired(block: Pick<FlarePluginQrBlock, "expiresAtMs">, nowMs: number): boolean {
  return typeof block.expiresAtMs === "number" && block.expiresAtMs <= nowMs;
}

/** How long until the code expires, to draw it again then; null without an expiry or once expired. */
export function flarePluginQrRefreshMs(block: Pick<FlarePluginQrBlock, "expiresAtMs">, nowMs: number): number | null {
  return typeof block.expiresAtMs === "number" && block.expiresAtMs > nowMs ? block.expiresAtMs - nowMs : null;
}

/**
 * A donut's slices (spec blocks2.donut): every point with a positive finite value, its start and sweep as fractions
 * of the sum of those values, in point order; nothing when no value is positive.
 */
export function flarePluginDonutSlices(
  points: ReadonlyArray<Pick<FlarePluginChartPoint, "value">>,
): { index: number; start: number; sweep: number }[] {
  const shown = points
    .map((point, index) => ({ index, value: point.value }))
    .filter((point) => Number.isFinite(point.value) && point.value > 0);
  const total = shown.reduce((sum, point) => sum + point.value, 0);
  if (!(total > 0)) return [];
  let start = 0;
  return shown.map((point) => {
    const sweep = point.value / total;
    const slice = { index: point.index, start, sweep };
    start += sweep;
    return slice;
  });
}

/** Whether a chart has anything to draw: some series has a point. */
export function flarePluginChartHasPoints(block: Pick<FlarePluginChartBlock, "series">): boolean {
  return block.series.some((series) => series.points.length > 0);
}

/**
 * The blocks in reading order with every section's children after it (spec blocks2.flatten): what the kit walks to
 * find users, rows and the first rows block. `section` is the index of the section a child belongs to.
 */
export function flarePluginFlatBlocks(
  blocks: ReadonlyArray<FlarePluginBlock>,
): { block: FlarePluginBlock; section?: number }[] {
  const out: { block: FlarePluginBlock; section?: number }[] = [];
  for (const block of blocks) {
    out.push({ block });
    if (block.kind === "section") {
      const at = out.length - 1;
      for (const child of block.blocks ?? []) if (child.kind !== "section") out.push({ block: child, section: at });
    }
  }
  return out;
}

// ── the upgrade notice ──────────────────────────────────────────────────────

/** What the engine's update.plugin_upgrade_status answers for a placeholder's minBuild. */
export interface FlarePluginUpgradeStatus {
  /** A build at least `minBuild` is offered to this device. */
  available: boolean;
  build?: number;
}
/** Where an upgrade notice sits: a message card's line, a "+" or "Me" entry's mark, or a whole page. */
export type FlarePluginUpgradeVariant = "card" | "entry" | "page";
/**
 * What an upgrade notice offers (spec upgradeNotice): `update` — the host has a newer build for this device and an
 * update handler, so the notice shows the update key; `notAvailable` — no build for this device yet (also while it is
 * still rolling out elsewhere), only the copy; `description` — the status is not known yet, or there is no handler.
 */
export function flarePluginUpgradeMode(
  status: FlarePluginUpgradeStatus | null | undefined,
  canUpdate: boolean,
): "update" | "notAvailable" | "description" {
  if (status?.available) return canUpdate ? "update" : "description";
  return status ? "notAvailable" : "description";
}

// ── money input ─────────────────────────────────────────────────────────────

/** Fraction digits of a money input: its scale, 2 when absent. */
export function flarePluginMoneyScale(input: Pick<FlarePluginInput, "money">): number {
  const scale = input.money?.scale;
  return typeof scale === "number" && Number.isInteger(scale) && scale >= 0 && scale <= 18 ? scale : 2;
}

/**
 * The amount typed, as the protocol writes decimals (spec moneyInput.normalize): spaces gone, leading zeros of the
 * whole part dropped (one kept), a leading "." gets a "0", a trailing "." goes. Anything else is left as typed for
 * the check to refuse.
 */
export function flarePluginMoneyAmount(typed: string): string {
  let text = typed.replace(/\s+/g, "");
  if (text.startsWith(".")) text = `0${text}`;
  if (text.endsWith(".")) text = text.slice(0, -1);
  const at = text.indexOf(".");
  const whole = at < 0 ? text : text.slice(0, at);
  const rest = at < 0 ? "" : text.slice(at);
  const trimmed = /^\d+$/.test(whole) ? whole.replace(/^0+(?=\d)/, "") : whole;
  return `${trimmed}${rest}`;
}

/** A decimal the protocol accepts: no sign or exponent, no leading zero, ≤30 whole and ≤`scale` fraction digits. */
export function flarePluginIsDecimal(amount: string, scale: number): boolean {
  const match = /^(\d+)(?:\.(\d+))?$/.exec(amount);
  if (!match) return false;
  const [, whole, fraction] = match;
  return whole.length <= 30 && (whole === "0" || !whole.startsWith("0")) && (fraction === undefined || fraction.length <= scale);
}

/** The order of two decimals {@link flarePluginIsDecimal} accepts: -1, 0 or 1. */
export function flarePluginCompareDecimal(a: string, b: string): number {
  const split = (s: string) => {
    const at = s.indexOf(".");
    return at < 0 ? [s, ""] : [s.slice(0, at), s.slice(at + 1).replace(/0+$/, "")];
  };
  const [aw, af] = split(a);
  const [bw, bf] = split(b);
  if (aw.length !== bw.length) return aw.length < bw.length ? -1 : 1;
  if (aw !== bw) return aw < bw ? -1 : 1;
  const width = Math.max(af.length, bf.length);
  const ap = af.padEnd(width, "0");
  const bp = bf.padEnd(width, "0");
  return ap === bp ? 0 : ap < bp ? -1 : 1;
}

/** The light check of a money draft (spec moneyInput.check): what the core SDK will say about the amount. */
export function flarePluginCheckMoney(input: FlarePluginInput, draft: unknown): FlarePluginFormIssue | null {
  const amount = flarePluginMoneyAmount(typeof draft === "string" ? draft : "");
  if (!amount) return input.required ? "required" : null;
  if (!flarePluginIsDecimal(amount, flarePluginMoneyScale(input)) || !input.money?.currency) return "invalidType";
  const { min, max } = input.money;
  if (min !== undefined && flarePluginCompareDecimal(amount, min) < 0) return "outOfRange";
  if (max !== undefined && flarePluginCompareDecimal(amount, max) > 0) return "outOfRange";
  return null;
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
    case "image":
    case "document":
      return flarePluginFileValue(raw) ? { fileId: raw.fileId } : null;
    case "money":
      // The draft is the amount as typed; the currency comes from the input.
      if (typeof raw === "string") return raw;
      return raw && typeof raw === "object" && typeof (raw as FlarePluginMoneyValue).amount === "string"
        ? (raw as FlarePluginMoneyValue).amount
        : "";
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
    case "image":
    case "document":
      return draft == null ? (input.required ? "required" : null) : flarePluginFileValue(draft) ? null : "invalidType";
    case "money":
      return flarePluginCheckMoney(input, draft);
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
      case "image":
      case "document":
        if (flarePluginFileValue(value)) out[input.id] = { fileId: value.fileId };
        break;
      case "money": {
        const amount = flarePluginMoneyAmount(typeof value === "string" ? value : "");
        const currency = input.money?.currency;
        if (amount && currency) out[input.id] = { amount, currency } satisfies FlarePluginMoneyValue;
        break;
      }
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
