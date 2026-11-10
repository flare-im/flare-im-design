<script setup lang="ts">
import FlareUserIdentity from "../data/FlareUserIdentity.vue";
import {
  computed,
  getCurrentInstance,
  reactive,
  ref,
  shallowReactive,
  watch,
} from "vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareDangerConfirm from "../scenes/FlareDangerConfirm.vue";
import type {
  SchemaSelection,
  SchemaSelectionLabels,
} from "../form/schema-selections";
import FlarePluginForm from "../form/FlarePluginForm.vue";
import PluginChoicesBlock from "./plugin/PluginChoicesBlock.vue";
import PluginEntriesBlock from "./plugin/PluginEntriesBlock.vue";
import PluginPeopleBlock from "./plugin/PluginPeopleBlock.vue";
import PluginProtectedMediaBlock from "./plugin/PluginProtectedMediaBlock.vue";
import PluginRowsBlock from "./plugin/PluginRowsBlock.vue";
import PluginSimpleBlock from "./plugin/PluginSimpleBlock.vue";
import PluginTextBlock from "./plugin/PluginTextBlock.vue";
import PluginTimeBlock from "./plugin/PluginTimeBlock.vue";
import { flareIcons, type FlareIconName } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  useFlareContentSelection,
  useFlareMessageQuote,
} from "../../shared/message-renderers";
import { flareServerNowMs } from "../../shared/server-clock";
import MessageCardQuote from "./MessageCardQuote.vue";
import FlareResolvedPresentation from "./presentation/FlareResolvedPresentation.vue";
import type { FlareActionItem } from "../../shared/contracts/action-menu";
import {
  flarePluginChoiceCapped,
  flarePluginFallbackName,
  flarePluginFormatText,
  flarePluginInlineFormAction,
  flarePluginReasonLine,
  flarePluginShowsDetailKey,
  flarePluginUnavailableKey,
  flarePluginWithinCap,
  type FlarePluginAction,
  type FlarePluginActionPayload,
  type FlarePluginBlock,
  type FlarePluginChoicesBlock,
  type FlarePluginField,
  type FlarePluginFieldsBlock,
  type FlarePluginFormat,
  type FlarePluginFormError,
  type FlarePluginFileState,
  type FlarePluginFileAction,
  type FlarePluginInput,
  type FlarePluginMember,
  type FlarePluginProtectedItem,
  type FlarePluginProtectedMediaBlock,
  type FlarePluginProtectedMediaRead,
  type FlarePluginProtectedMediaState,
  type FlarePluginReferenceRequest,
  type FlarePluginResolveUser,
  type FlarePluginRow,
  type FlarePluginRowsBlock,
  type FlarePluginRowsLayout,
  type FlarePluginStrings,
  type FlarePluginUser,
  type FlarePluginViewInset,
  type FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";

// A plugin card: the core SDK's resolved view drawn as a kit business card (spec PluginView,
// spec/plugin-view-vectors.json). Inert: nothing here reads paths, evaluates or calls the network;
// actions go out as opaque ids with the viewer's selection or form values, and the host invokes.
// The shell is the message's card surface (the timeline draws no bubble around it); menu actions open
// from the title row's ⋯ key; an unavailable reason adds its line, led by the envelope's displayName.
const props = withDefaults(
  defineProps<{
    view: FlarePluginViewModel;
    /** Kit icon name before the title. */
    icon?: string;
    /** The envelope's displayName (the plugin's name): leads the unavailable reason line. */
    displayName?: string;
    /** The viewer's user id: their entries rows carry the "me" tag. */
    viewerId?: string;
    /** The whole card is busy: every action, choice and submit is disabled. */
    busy?: boolean;
    /** The action in flight: its key spins; leaving the action settles it as a fallback for `settleToken`. */
    busyActionId?: string;
    /** Failure text from the host. */
    error?: string;
    /** Hide only the outer banner; open forms still receive the error and settlement signal. */
    showError?: boolean;
    /** An external host notification may present errors while settlement still uses `error`. */
    errorPresentation?: "inline" | "external";
    /** Render persistent plugin guidance as ordinary text in message-owning hosts. */
    notePresentation?: "tinted" | "plain";
    /** No card shell or title row (detail sheet, admin page). */
    embedded?: boolean;
    /**
     * Where the view sits: `sheet` gives it the bottom-sheet insets (md / lg / xl) for a view put straight into a sheet,
     * `sheetTop` the same without the bottom one for a view with more of the sheet under it (a preface above
     * PluginForm). Pads every state: the embedded body, available or not, and a card shell kept in a sheet.
     */
    inset?: FlarePluginViewInset;
    /** How a rows block draws: the kit DataTable (console admin lists) or one item per row (plugin pages). */
    rowsLayout?: FlarePluginRowsLayout;
    /** Fill an administrative list viewport; ordinary cards and notes keep their natural height. */
    contentLayout?: "flow" | "list";
    /** Administrative row presenters may place the same page actions in their list toolbar. */
    actionsPlacement?: "footer" | "rows";
    /** Visual grouping only; forms, confirmations and action guards keep the same runner. */
    actionLayout?: "inline" | "compact" | "list";
    /** In list rows, pair secondary values with their declared column labels. */
    labelRows?: boolean;
    /** A page may expose one eligible, non-sensitive action form directly in the document. */
    inlineFormActionId?: string;
    /** Optional visual heading for an eligible inline form; never changes action eligibility. */
    inlineFormTitle?: string;
    /** Supporting instructions immediately before the same inline form. */
    inlineFormDescription?: string;
    resolveUser?: FlarePluginResolveUser;
    /** Candidates for members inputs in action forms. */
    members?: FlarePluginMember[];
    membersLoading?: boolean;
    membersRevision?: number;
    membersError?: string;
    onMemberSearch?: (query: string) => void;
    onMembersRetry?: () => void;
    /** The host's validation errors for the open action form. */
    formErrors?: FlarePluginFormError[];
    fileStates?: Record<string, FlarePluginFileState>;
    /** Initial values for the action/row selected by the user; captured once when opening. */
    formInitialValues?: (
      actionId: string,
      row?: { key: string; input: unknown },
    ) => Record<string, unknown> | undefined;
    formSelections?: Record<string, SchemaSelection>;
    formChangeActions?: ReadonlyArray<string>;
    selectionLabels?: SchemaSelectionLabels;
    /** The scale the host knows for an asset, for a money value whose data holds none. */
    assetScale?: (assetId: string) => number | undefined;
    /** What the host has for each protected media item, by item id. */
    protectedMedia?: Record<string, FlarePluginProtectedMediaState>;
    /**
     * The host's settle signal: incremented once per finished action, after that result's `error` / `formErrors`
     * are set. Each change settles the optimistic choice and a submitted form (spec rules.settle).
     */
    settleToken?: number;
  }>(),
  {
    icon: undefined,
    displayName: undefined,
    viewerId: undefined,
    busy: false,
    busyActionId: undefined,
    error: undefined,
    errorPresentation: "inline",
    showError: true,
    embedded: false,
    inset: "none",
    rowsLayout: "table",
    contentLayout: "flow",
    actionsPlacement: "footer",
    actionLayout: "inline",
    labelRows: false,
    resolveUser: undefined,
    members: () => [],
    formErrors: () => [],
    settleToken: 0,
  },
);
const emit = defineEmits<{
  action: [actionId: string, payload: FlarePluginActionPayload];
  fileAction: [event: FlarePluginFileAction];
  /** "See all", the card's view details key (or a row of an admin table, with its key and the detail operation's input). */
  openDetail: [row?: { key: string; input: unknown }];
  /** Admin tables: the next page from `cursor` of operation `source`. */
  loadMore: [cursor: string, source: string];
  selectionSearch: [id: string, query: string];
  selectionRetry: [id: string];
  selectionMore: [id: string];
  /** A reference input of the open form wants its options; answer through `formSelections`. */
  referenceLoad: [request: FlarePluginReferenceRequest];
  /** A protected media read with its stated reason: the host runs and audits it, then fills `protectedMedia`. */
  protectedMediaRead: [read: FlarePluginProtectedMediaRead];
}>();
const { t } = useFlareI18nOptional();

const strings = computed<FlarePluginStrings>(() => ({
  deadlinePassed: t("pluginView.deadlinePassed"),
  remaining: t("pluginView.remaining"),
  dateTime: t("pluginView.dateTime"),
  dateTimeYear: t("pluginView.dateTimeYear"),
  days: t("pluginView.days"),
  hours: t("pluginView.hours"),
  minutes: t("pluginView.minutes"),
  required: t("pluginForm.required"),
  tooLong: t("pluginForm.tooLong"),
  outOfRange: t("pluginForm.outOfRange"),
  tooFewItems: t("pluginForm.tooFewItems"),
  tooManyItems: t("pluginForm.tooManyItems"),
  duplicateItem: t("pluginForm.duplicateItem"),
  invalid: t("pluginForm.invalid"),
}));

const KNOWN = new Set<string>([
  "text",
  "fields",
  "choices",
  "entries",
  "people",
  "status",
  "progress",
  "time",
  "divider",
  "note",
  "rows",
  "protected-media",
]);
/** Blocks the kit knows, in order; a kind from a newer protocol is skipped. */
const blocks = computed<FlarePluginBlock[]>(() =>
  (props.view.blocks ?? []).filter((block) =>
    KNOWN.has((block as { kind: string }).kind),
  ),
);
const titleIcon = computed(() =>
  props.icon && props.icon in flareIcons
    ? (props.icon as FlareIconName)
    : undefined,
);
// A timeline row that replies: the quote goes inside this shell, at the top (the row then draws none).
const rowQuote = useFlareMessageQuote();
const packetOwnsQuote = computed(
  () =>
    props.view.available &&
    props.view.presentation?.renderer === "redPacket.card",
);
if (rowQuote && !props.embedded && !packetOwnsQuote.value) rowQuote.claim();
const quoteShown = computed(() =>
  !props.embedded && !packetOwnsQuote.value && rowQuote?.active()
    ? rowQuote
    : null,
);
// In a selecting timeline row the card is inert: a tap selects the row.
const specialPresentation = computed(
  () =>
    props.view.available &&
    [
      "redPacket.card",
      "redPacket.composer",
      "redPacket.pay",
      "payment.confirm",
      "redPacket.detail",
    ].includes(props.view.presentation?.renderer ?? "") &&
    (props.view.presentation?.renderer !== "redPacket.detail" ||
      Boolean(props.view.presentation.props.details)),
);
function presentationRequest(id: string): void {
  const action = props.view.actions.find((a) => a.id === id);
  if (action) run(action, {});
}
const selecting = useFlareContentSelection();
const inlinePending = ref(false);
const hostLocked = computed(
  () =>
    props.busy ||
    Boolean(props.busyActionId) ||
    selecting() ||
    !props.view.available ||
    props.view.unavailableReason === "unbound_copy",
);
const locked = computed(() => hostLocked.value || inlinePending.value);
// The reason line (spec rules.unavailableReason): the reason's copy, led by the envelope's displayName.
const reasonLine = computed(() => {
  const reason = props.view.unavailableReason;
  if (!reason) return "";
  return flarePluginReasonLine(
    t(flarePluginUnavailableKey(reason)),
    props.displayName,
  );
});
// Menu actions (spec rules.menuActions): the title row's ⋯ key on a card, keys after the actions when embedded.
const menuActions = computed<FlarePluginAction[]>(() =>
  props.view.available ? [...(props.view.menuActions ?? [])] : [],
);
const menuItems = computed<FlareActionItem[]>(() =>
  menuActions.value.map((action) => ({
    id: action.id,
    label: action.label,
    danger: action.style === "danger",
    enabled: !locked.value,
  })),
);
function runMenu(id: string): void {
  const action = menuActions.value.find((candidate) => candidate.id === id);
  if (action) run(action, {});
}
const declaredFooterActions = computed<FlarePluginAction[]>(() =>
  props.embedded
    ? [...props.view.actions, ...menuActions.value]
    : [...props.view.actions],
);
const inlineFormAction = computed(() =>
  instance?.vnode.props?.onAction
    ? flarePluginInlineFormAction(props.view, props.inlineFormActionId)
    : undefined,
);
const hasInlineFormHeading = computed(() =>
  Boolean(props.inlineFormTitle?.trim() || props.inlineFormDescription?.trim()),
);
const footerActions = computed(() =>
  declaredFooterActions.value.filter(
    (action) => action.id !== inlineFormAction.value?.id,
  ),
);
// The card's view details key (spec rules.detailKey): a detail no entries block offers, and a host that listens
// for openDetail (read at render: listeners are not reactive props).
const instance = getCurrentInstance();
const detailKey = () =>
  flarePluginShowsDetailKey(props.view, props.embedded) &&
  Boolean(instance?.vnode.props?.onOpenDetail);

// ── users ────────────────────────────────────────────────────────────────
const users = shallowReactive(new Map<string, FlarePluginUser | null>());
function request(userId: string): void {
  if (users.has(userId) || !props.resolveUser) return;
  users.set(userId, null);
  try {
    const answer = props.resolveUser(userId);
    if (answer && typeof (answer as Promise<unknown>).then === "function") {
      (answer as Promise<FlarePluginUser | undefined>).then(
        (user) => {
          if (user) users.set(userId, user);
        },
        () => undefined,
      );
    } else if (answer) users.set(userId, answer as FlarePluginUser);
  } catch {
    /* the fallback stands */
  }
}
const userIds = computed(() => {
  const ids = new Set<string>();
  for (const block of blocks.value) {
    if (block.kind === "people")
      for (const group of block.groups)
        for (const id of group.userIds) ids.add(id);
    if (block.kind === "entries")
      for (const entry of block.items)
        if (entry.userId && !entry.name) ids.add(entry.userId);
    if (block.kind === "fields")
      for (const field of block.fields) addPerson(ids, field.format);
    if (block.kind === "rows")
      for (const row of block.rows)
        for (const cell of row.cells) addPerson(ids, cell.format);
  }
  for (const field of props.view.fields ?? []) addPerson(ids, field.format);
  return [...ids];
});
function addPerson(
  ids: Set<string>,
  format: FlarePluginFormat | undefined,
): void {
  if (format?.kind === "person" && format.userId) ids.add(format.userId);
}
// Answers are kept per id for the card's life: hosts pass resolvers inline, so a new function is not a
// new directory, and asking again on every render would loop.
watch(
  [userIds, () => Boolean(props.resolveUser)],
  () => {
    for (const id of userIds.value) request(id);
  },
  { immediate: true },
);
/** The resolved user of an id, or the fallback: initials and the id's last 4 characters. */
function userOf(userId: string): FlarePluginUser {
  return users.get(userId) ?? { name: flarePluginFallbackName(userId) };
}

// ── formats: plain text unless the kit knows better ─────────────────────
const formatContext = computed(() => ({
  nowMs: flareServerNowMs(),
  strings: strings.value,
  unavailable: t("pluginView.referenceUnavailable"),
  assetScale: props.assetScale,
}));
const identityOf = (format: FlarePluginFormat | undefined) => {
  if (format?.kind !== "person") return undefined;
  const user = users.get(format.userId);
  return user
    ? { ...user, state: "ready" as const }
    : { name: flarePluginFallbackName(format.userId), state: "ready" as const };
};
const shownField = (field: FlarePluginField): FlarePluginField => ({
  ...field,
  value: flarePluginFormatText(field.value, field.format, formatContext.value),
  user: field.user ?? identityOf(field.format),
});
const shownFields = computed(() => (props.view.fields ?? []).map(shownField));
function shownRows(block: FlarePluginRowsBlock): FlarePluginRowsBlock {
  return {
    ...block,
    rows: block.rows.map((row) => ({
      ...row,
      cells: row.cells.map((cell) => ({
        ...cell,
        text: flarePluginFormatText(
          cell.text,
          cell.format,
          formatContext.value,
        ),
        user: cell.user ?? identityOf(cell.format),
      })),
    })),
  };
}
function shownBlock<T extends { kind: string }>(block: T): T {
  if (block.kind !== "fields") return block;
  const fields = (block as unknown as FlarePluginFieldsBlock).fields;
  return { ...block, fields: fields.map(shownField) };
}

// ── protected media: the reason comes from the block, the read belongs to the host ──
function readProtected(
  block: FlarePluginProtectedMediaBlock,
  item: FlarePluginProtectedItem,
  reason: string,
): void {
  if (!block.action || locked.value) return;
  emit("protectedMediaRead", {
    action: block.action,
    item,
    reason,
    urlPath: block.urlPath,
    formValues: {
      [block.inputName]: item.id,
      ...(block.reasonInput ? { [block.reasonInput]: reason } : {}),
    },
  });
}

// ── choices: drafts (multiple) and the optimistic submit ─────────────────
const drafts = reactive(new Map<number, number[]>());
const pending = ref<{
  block: number;
  actionId: string;
  selection: number[];
} | null>(null);
const viewSelection = (block: FlarePluginChoicesBlock) =>
  block.options.filter((o) => o.selected).map((o) => o.index);
const sameSet = (a: ReadonlyArray<number>, b: ReadonlyArray<number>) =>
  a.length === b.length && [...a].sort().join() === [...b].sort().join();
function choicesInteractive(
  block: FlarePluginChoicesBlock,
  index: number,
): boolean {
  return (
    Boolean(block.action) &&
    !block.closed &&
    !locked.value &&
    pending.value?.block !== index
  );
}
function shownSelection(
  block: FlarePluginChoicesBlock,
  index: number,
): number[] {
  if (pending.value?.block === index) return pending.value.selection;
  if (block.multiple && block.action && !block.closed)
    return drafts.get(index) ?? viewSelection(block);
  return viewSelection(block);
}
function submitEnabled(block: FlarePluginChoicesBlock, index: number): boolean {
  const draft = drafts.get(index) ?? viewSelection(block);
  return (
    draft.length > 0 &&
    !sameSet(draft, viewSelection(block)) &&
    flarePluginWithinCap(block, draft)
  );
}
/** Options the cap holds back (spec rules.maxSelections): the multiple draft is full and does not hold them. */
function cappedOptions(
  block: FlarePluginChoicesBlock,
  index: number,
): number[] {
  if (!block.multiple || pending.value?.block === index) return [];
  const draft = drafts.get(index) ?? viewSelection(block);
  return block.options
    .map((o) => o.index)
    .filter((option) => flarePluginChoiceCapped(block, draft, option));
}
function pick(
  block: FlarePluginChoicesBlock,
  index: number,
  option: number,
): void {
  if (!choicesInteractive(block, index) || !block.action) return;
  if (block.multiple) {
    if (cappedOptions(block, index).includes(option)) return;
    const draft = new Set(drafts.get(index) ?? viewSelection(block));
    if (draft.has(option)) draft.delete(option);
    else draft.add(option);
    drafts.set(
      index,
      [...draft].sort((a, b) => a - b),
    );
    return;
  }
  const current = viewSelection(block);
  if (current.length === 1 && current[0] === option) return;
  submitChoices(block, index, [option]);
}
function submitChoices(
  block: FlarePluginChoicesBlock,
  index: number,
  selection: number[],
): void {
  const action = block.action;
  if (!action) return;
  const sorted = [...selection].sort((a, b) => a - b);
  run(action, { selection: sorted }, () => {
    pending.value = { block: index, actionId: action.id, selection: sorted };
  });
}
function revert(): void {
  if (!pending.value) return;
  drafts.delete(pending.value.block);
  pending.value = null;
}
// A new view is the truth; a failure reverts.
watch(
  () => props.view,
  () => {
    pending.value = null;
    drafts.clear();
  },
);
watch(
  () => props.error,
  (error, before) => {
    if (error && error !== before) revert();
  },
);

// ── actions, confirmation and forms ──────────────────────────────────────
const confirming = ref<{
  action: FlarePluginAction;
  proceed: () => void;
} | null>(null);
const formAction = ref<FlarePluginAction | null>(null);
// What the action already carries when its form opens (a choices selection and its optimistic mark):
// the form adds its values to it, so every platform sends both.
const formCarry = ref<{
  payload: FlarePluginActionPayload;
  before?: () => void;
} | null>(null);
// Keep the displayed row beside its operation form. These are presentation
// snapshots only; the command still sends exactly its declared bound input.
const formRowContext = ref<FlarePluginFieldsBlock | null>(null);
const formSubmitted = ref(false);
const inlineAttempted = ref(false),
  inlineRevision = ref(0);
const inlineInitialValues = ref<Record<string, unknown>>();
const inlineInputs = computed(
  () =>
    inlineFormAction.value?.form?.flatMap(
      (id) => props.view.inputs?.find((input) => input.id === id) ?? [],
    ) ?? [],
);
watch(
  () => inlineFormAction.value?.id,
  (id) => {
    inlineAttempted.value = false;
    inlinePending.value = false;
    inlineRevision.value++;
    inlineInitialValues.value = id
      ? props.formInitialValues?.(id, undefined)
      : undefined;
  },
  { immediate: true },
);
const formValues = ref<Record<string, unknown> | undefined>();
const formBaselineValues = ref<Record<string, unknown> | undefined>();
const formInputs = computed<FlarePluginInput[]>(() => {
  const action = formAction.value;
  if (!action?.form) return [];
  return action.form
    .map((id) => props.view.inputs?.find((input) => input.id === id))
    .filter((input): input is FlarePluginInput => Boolean(input));
});
const formBusy = computed(
  () =>
    props.busy ||
    (Boolean(formAction.value) && props.busyActionId === formAction.value?.id),
);
// The row whose action went out last: only its key spins for busyActionId (spec rules.pageRows); the other rows
// offering the same action wait without spinning.
const rowInFlight = ref<string | null>(null);
function send(actionId: string, payload: FlarePluginActionPayload): void {
  rowInFlight.value = payload.row?.key ?? null;
  emit("action", actionId, payload);
}

/** Confirm, then collect the form, then hand the action over (`before` runs right before it goes out). */
function run(
  action: FlarePluginAction,
  payload: FlarePluginActionPayload,
  before?: () => void,
  initialValues?: Record<string, unknown>,
): void {
  if (locked.value) return;
  const proceed = () => {
    if (action.form?.length) {
      formRowContext.value = null;
      if (payload.row) {
        for (const block of props.view.blocks ?? []) {
          if (block.kind !== "rows") continue;
          const row = block.rows.find((row) => row.key === payload.row?.key);
          if (
            !row ||
            !row.actions.some(
              (a) =>
                a.id === action.id &&
                JSON.stringify(a.input) === JSON.stringify(payload.row?.input),
            )
          )
            continue;
          formRowContext.value = {
            kind: "fields",
            fields: row.cells.map((cell, index) =>
              shownField({
                label: block.columns[index]?.label ?? "",
                value: cell.text,
                format: cell.format,
                user: cell.user,
              }),
            ),
          };
          break;
        }
      }
      formSubmitted.value = false;
      const initial = props.formInitialValues?.(action.id, payload.row);
      formBaselineValues.value = initialValues ? initial : undefined;
      formValues.value = initialValues
        ? { ...initial, ...initialValues }
        : initial;
      formCarry.value = { payload, before };
      formAction.value = action;
      return;
    }
    before?.();
    send(action.id, payload);
  };
  if (action.confirm) confirming.value = { action, proceed };
  else proceed();
}
function confirmed(): void {
  const next = confirming.value;
  confirming.value = null;
  next?.proceed();
}
function submitForm(values: Record<string, unknown>): void {
  const action = formAction.value;
  if (!action || locked.value) return;
  formSubmitted.value = true;
  const carry = formCarry.value;
  dispatchForm(action, carry?.payload ?? {}, values, carry?.before);
}
function dispatchForm(
  action: FlarePluginAction,
  payload: FlarePluginActionPayload,
  values: Record<string, unknown>,
  before?: () => void,
): void {
  if (hostLocked.value) return;
  before?.();
  send(action.id, { ...payload, formValues: values });
}
function submitInlineForm(values: Record<string, unknown>): void {
  const action = inlineFormAction.value;
  if (
    !action ||
    locked.value ||
    inlinePending.value ||
    !instance?.vnode.props?.onAction
  )
    return;
  inlineAttempted.value = true;
  inlinePending.value = true;
  dispatchForm(action, {}, values);
}
function closeForm(): void {
  if (formBusy.value) return;
  formAction.value = null;
  formCarry.value = null;
  formRowContext.value = null;
  formSubmitted.value = false;
}
/**
 * The host finished an action (`actionId` when the fallback knows which one): an optimistic choice reverts when the
 * result carries an error or form errors and otherwise stays until the new view; a submitted form closes unless it
 * came back with errors. Settling twice is the same as once.
 */
function settle(actionId?: string): void {
  const failed = Boolean(props.error) || props.formErrors.length > 0;
  if (
    inlinePending.value &&
    inlineFormAction.value &&
    (!actionId || inlineFormAction.value.id === actionId)
  ) {
    inlinePending.value = false;
    if (!failed) {
      inlineAttempted.value = false;
      inlineRevision.value++;
      inlineInitialValues.value = props.formInitialValues?.(
        inlineFormAction.value.id,
        undefined,
      );
    }
  }
  if (
    failed &&
    pending.value &&
    (!actionId || pending.value.actionId === actionId)
  )
    revert();
  if (
    formAction.value &&
    formSubmitted.value &&
    !failed &&
    (!actionId || formAction.value.id === actionId)
  ) {
    formAction.value = null;
    formCarry.value = null;
    formRowContext.value = null;
    formSubmitted.value = false;
  }
}
// The explicit signal: every change of the token settles (a same-frame busyActionId never shows a change).
watch(
  () => props.settleToken,
  (now, before) => {
    if (now !== before) settle();
  },
);
// The fallback: busyActionId leaving the action.
watch(
  () => props.busyActionId,
  (now, before) => {
    if (!before || now === before) return;
    settle(before);
  },
);

function rowAction(
  action: FlarePluginAction,
  row: FlarePluginRow,
  input: unknown,
  initialValues?: Record<string, unknown>,
): void {
  run(action, { row: { key: row.key, input } }, undefined, initialValues);
}
const firstRowsIndex = computed(
  () => props.view.blocks?.findIndex((block) => block.kind === "rows") ?? -1,
);
const actionsInRows = computed(
  () => props.actionsPlacement === "rows" && firstRowsIndex.value >= 0,
);
function runPageAction(action: FlarePluginAction): void {
  const declared = footerActions.value.find(
    (candidate) => candidate.id === action.id,
  );
  if (declared) run(declared, {});
}
function openRow(row: FlarePluginRow): void {
  if (!locked.value && row.detailInput !== undefined)
    emit("openDetail", { key: row.key, input: row.detailInput });
}
function loadRowsMore(cursor: string, block: FlarePluginRowsBlock): void {
  if (!locked.value && cursor === block.nextCursor)
    emit("loadMore", cursor, block.source);
}
const variantOf = (action: FlarePluginAction) =>
  action.style === "danger"
    ? "danger"
    : action.style === "primary"
      ? "primary"
      : "secondary";
function forwardFileAction(event: FlarePluginFileAction): void { emit("fileAction", event); }
</script>

<template>
  <section
    class="flare-plugin-view"
    :class="{
      'is-presentation': specialPresentation,
      [`has-actions-${actionLayout}`]: actionLayout !== 'inline',
      'is-embedded': embedded,
      'is-list-layout': contentLayout === 'list' && firstRowsIndex >= 0,
      'is-inset-sheet': inset === 'sheet',
      'is-inset-sheet-top': inset === 'sheetTop',
      'is-unavailable': !view.available,
    }"
    :aria-label="view.title || undefined"
    :aria-busy="busy || Boolean(busyActionId)"
  >
    <!-- A quoted reply sits inside the card shell, above the title row. -->
    <div
      v-if="($slots.quote || quoteShown) && !embedded && !packetOwnsQuote"
      class="flare-plugin-view__quote"
      data-plugin-quote="true"
    >
      <slot name="quote"
        ><MessageCardQuote
          v-if="quoteShown"
          :preview="quoteShown.preview()"
          :locate="quoteShown.locate()"
      /></slot>
    </div>
    <header
      v-if="!embedded && !specialPresentation"
      class="flare-plugin-view__head"
    >
      <FlareIcon
        v-if="titleIcon"
        class="flare-plugin-view__icon"
        :name="titleIcon"
        :size="18"
      />
      <strong class="flare-plugin-view__title">{{ view.title }}</strong>
      <FlareButton
        v-if="detailKey() && !footerActions.length"
        class="flare-plugin-view__detail"
        variant="quiet"
        size="sm"
        appearance="text"
        :disabled="locked"
        data-detail-key="true"
        @click="emit('openDetail')"
      >
        <span>{{ t("pluginView.detail") }}</span>
        <FlareIcon name="chevron-right" :size="14" aria-hidden="true" />
      </FlareButton>
      <FlareActionMenu
        v-if="menuItems.length"
        :items="menuItems"
        :label="t('pluginView.more')"
        placement="bottom-end"
        @select="runMenu"
      >
        <button
          type="button"
          class="flare-plugin-view__more"
          :aria-label="t('pluginView.more')"
          :title="t('pluginView.more')"
          :disabled="locked"
          data-plugin-menu="true"
        >
          <FlareIcon name="more" :size="18" />
        </button>
      </FlareActionMenu>
    </header>
    <!-- Embedded there is no title row: an unavailable view still says what it was. -->
    <p
      v-else-if="!view.available && view.title"
      class="flare-plugin-view__unavailable"
      data-unavailable-title="true"
    >
      {{ view.title }}
    </p>
    <p
      v-if="!view.available && reasonLine"
      class="flare-plugin-view__reason"
      data-unavailable-reason="true"
    >
      {{ reasonLine }}
    </p>
    <FlareResolvedPresentation
      v-if="specialPresentation"
      :view="view"
      :file-states="fileStates"
      :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
      :busy="locked"
      :error="error"
      :form-errors="formErrors"
      :settle-token="settleToken"
      :resolve-user="resolveUser"
      :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry"
      @request="presentationRequest"
      @action="send"
    >
      <template v-if="packetOwnsQuote && $slots.quote" #quote
        ><slot name="quote"
      /></template>
    </FlareResolvedPresentation>
    <p
      v-if="specialPresentation && reasonLine"
      class="flare-plugin-view__reason"
      data-unavailable-reason="true"
    >
      {{ reasonLine }}
    </p>
    <template v-if="view.available && !specialPresentation">
      <dl v-if="view.fields.length" class="flare-plugin-view__fields">
        <div v-for="(field, index) in shownFields" :key="index">
          <dt>{{ field.label }}</dt>
          <dd>
            <FlareUserIdentity v-if="field.user" :user="field.user" /><template
              v-else
              >{{ field.value }}</template
            >
          </dd>
        </div>
      </dl>
      <template v-for="(block, index) in blocks" :key="index">
        <PluginTextBlock
          v-if="block.kind === 'text'"
          :block="block"
          data-block="text"
        />
        <PluginChoicesBlock
          v-else-if="block.kind === 'choices'"
          :block="block"
          :selected="shownSelection(block, index)"
          :interactive="choicesInteractive(block, index)"
          :submit-enabled="submitEnabled(block, index)"
          :submit-loading="
            Boolean(block.action) && busyActionId === block.action?.id
          "
          :capped="cappedOptions(block, index)"
          data-block="choices"
          @pick="(option: number) => pick(block, index, option)"
          @submit="submitChoices(block, index, drafts.get(index) ?? [])"
        />
        <PluginEntriesBlock
          v-else-if="block.kind === 'entries'"
          :block="block"
          :user-of="userOf"
          :viewer-id="viewerId"
          data-block="entries"
          @see-all="emit('openDetail')"
        />
        <PluginPeopleBlock
          v-else-if="block.kind === 'people'"
          :block="block"
          :user-of="userOf"
          data-block="people"
        />
        <PluginTimeBlock
          v-else-if="block.kind === 'time'"
          :block="block"
          :strings="strings"
          data-block="time"
        />
        <!-- Host business presenters keep the same form, confirmation and action pipeline. -->
        <div v-else-if="block.kind === 'rows'" class="flare-plugin-view__rows">
          <slot
            name="rows"
            :block="block"
            :shown-block="shownRows(block)"
            :strings="strings"
            :busy="locked"
            :busy-action-id="busyActionId"
            :busy-row="rowInFlight"
            :run="rowAction"
            :actions="
              actionsInRows && index === firstRowsIndex ? footerActions : []
            "
            :run-action="runPageAction"
            :open-row="openRow"
            :load-more="(cursor: string) => loadRowsMore(cursor, block)"
          >
            <PluginRowsBlock
              :block="shownRows(block)"
              :label-rows="labelRows"
              :strings="strings"
              :busy="locked"
              :busy-action-id="busyActionId"
              :busy-row="rowInFlight"
              :layout="rowsLayout"
              data-block="rows"
              @row-action="rowAction"
              @open-row="
                (row: FlarePluginRow) =>
                  emit('openDetail', { key: row.key, input: row.detailInput })
              "
              @load-more="
                (cursor: string) => emit('loadMore', cursor, block.source)
              "
            />
          </slot>
        </div>
        <PluginProtectedMediaBlock
          v-else-if="block.kind === 'protected-media'"
          :block="block"
          :states="protectedMedia"
          :busy="locked"
          data-block="protected-media"
          @read="
            (item: FlarePluginProtectedItem, reason: string) =>
              readProtected(block, item, reason)
          "
        />
        <PluginSimpleBlock
          v-else-if="
            block.kind === 'fields' ||
            block.kind === 'status' ||
            block.kind === 'progress' ||
            block.kind === 'divider' ||
            block.kind === 'note'
          "
          :block="shownBlock(block)"
          :note-presentation="notePresentation"
          :data-block="block.kind"
        />
      </template>
      <section
        v-if="inlineFormAction"
        class="flare-plugin-view__inline-section"
        :class="{ 'has-form-heading': hasInlineFormHeading }"
      >
        <header
          v-if="hasInlineFormHeading"
          class="flare-plugin-view__inline-heading"
          data-inline-form-heading="true"
        >
          <h3 v-if="inlineFormTitle?.trim()">{{ inlineFormTitle }}</h3>
          <p v-if="inlineFormDescription?.trim()">
            {{ inlineFormDescription }}
          </p>
        </header>
        <FlarePluginForm
          :file-states="fileStates"
          :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
          :key="`${inlineFormAction.id}/${inlineRevision}`"
          class="flare-plugin-view__inline-form"
          data-inline-action-form="true"
          :data-inline-action-id="inlineFormAction.id"
          embedded
          :inputs="inlineInputs"
          :select-presentation="actionsPlacement === 'rows' ? 'dropdown' : undefined"
          :values="inlineInitialValues"
          :require-change="formChangeActions?.includes(inlineFormAction.id)"
          :submit-label="inlineFormAction.label"
          :selections="formSelections"
          :selection-labels="selectionLabels"
          :errors="inlineAttempted ? formErrors : []"
          :busy="locked || inlinePending"
          :error="errorPresentation === 'inline' ? error : undefined"
          :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry"
          @submit="submitInlineForm"
          @selection-search="
            (id: string, query: string) => emit('selectionSearch', id, query)
          "
          @selection-retry="(id: string) => emit('selectionRetry', id)"
          @selection-more="(id: string) => emit('selectionMore', id)"
          @reference-load="
            (request: FlarePluginReferenceRequest) =>
              emit('referenceLoad', request)
          "
        />
      </section>
      <footer
        v-if="footerActions.length && !actionsInRows"
        class="flare-plugin-view__footer"
      >
        <div v-if="footerActions.length" class="flare-plugin-view__actions">
          <FlareButton
            v-for="action in footerActions"
            :key="action.id"
            :label="action.label"
            :variant="variantOf(action)"
            size="sm"
            :appearance="actionLayout === 'compact' ? 'default' : 'text'"
            :loading="busyActionId === action.id"
            :disabled="locked"
            :data-action-id="action.id"
            @click="run(action, {})"
          >
            <span
              v-if="actionLayout === 'list'"
              class="flare-plugin-view__service-label"
              >{{ action.label
              }}<FlareIcon name="chevron-right" :size="14" aria-hidden="true"
            /></span>
            <template v-else>{{ action.label }}</template>
          </FlareButton>
        </div>
        <FlareButton
          v-if="detailKey()"
          class="flare-plugin-view__detail"
          variant="quiet"
          size="sm"
          appearance="text"
          :disabled="locked"
          data-detail-key="true"
          @click="emit('openDetail')"
        >
          <span>{{ t("pluginView.detail") }}</span>
          <FlareIcon name="chevron-right" :size="14" aria-hidden="true" />
        </FlareButton>
      </footer>
      <!-- A forwarded or forged copy (unbound_copy): readable, read-only, and it says so. -->
      <p
        v-if="reasonLine"
        class="flare-plugin-view__reason flare-plugin-view__reason--copy"
        data-unavailable-reason="true"
      >
        {{ reasonLine }}
      </p>
    </template>
    <FlareStatusBanner
      v-if="
        showError &&
        error &&
        !inlineFormAction &&
        errorPresentation === 'inline'
      "
      :text="error"
      tone="danger"
    />
    <FlareDangerConfirm
      v-if="confirming"
      :open="Boolean(confirming)"
      :title="confirming?.action.label ?? ''"
      :description="confirming?.action.confirm ?? ''"
      target=""
      :confirm-text="confirming?.action.label"
      @confirm="confirmed"
      @cancel="confirming = null"
    />
    <FlareBottomSheet
      v-if="formAction"
      :open="Boolean(formAction)"
      :title="formAction?.label"
      :dismissible="!formBusy"
      @close="closeForm"
    >
      <PluginSimpleBlock
        v-if="formRowContext"
        data-row-form-context="true"
        :block="formRowContext"
      />
      <FlarePluginForm
          :file-states="fileStates"
          :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
        :inputs="formInputs"
        :select-presentation="actionsPlacement === 'rows' ? 'dropdown' : undefined"
        :values="formValues"
        :baseline-values="formBaselineValues"
        :require-change="
          formAction ? formChangeActions?.includes(formAction.id) : false
        "
        :selections="formSelections"
        :selection-labels="selectionLabels"
        @selection-search="
          (id: string, query: string) => emit('selectionSearch', id, query)
        "
        @selection-retry="(id: string) => emit('selectionRetry', id)"
        @selection-more="(id: string) => emit('selectionMore', id)"
        @reference-load="
          (request: FlarePluginReferenceRequest) =>
            emit('referenceLoad', request)
        "
        :errors="formSubmitted ? formErrors : []"
        :busy="formBusy"
        :error="
          formSubmitted && errorPresentation === 'inline' ? error : undefined
        "
        :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry"
        @submit="submitForm"
        @cancel="closeForm"
      />
    </FlareBottomSheet>
  </section>
</template>

<style scoped>
.flare-plugin-view {
  display: grid;
  gap: var(--flare-size-spacing-2sm);
  --flare-plugin-title-size: var(--flare-size-font-size-xl);
  --flare-plugin-body-size: var(--flare-size-font-size-lg);
  --flare-plugin-meta-size: var(--flare-size-font-size-sm);
  width: var(--flare-component-rich-card-width);
  max-width: 100%;
  min-width: 0;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-md);
  border: 1px solid
    color-mix(in srgb, var(--flare-color-border-secondary) 60%, transparent);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  box-shadow: none;
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-plugin-view.is-presentation {
  grid-template-columns: minmax(0, 1fr);
  width: auto;
  padding: 0;
  border: 0;
  background: transparent;
  box-shadow: none;
}
.flare-plugin-view.is-embedded {
  --flare-plugin-title-size: var(--flare-size-font-size-2xl);
  --flare-plugin-body-size: var(--flare-size-font-size-lg);
  --flare-plugin-meta-size: var(--flare-size-font-size-md);
  width: auto;
  padding: 0;
  border: 0;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
}
.flare-plugin-view__rows {
  display: contents;
}
.flare-plugin-view.is-list-layout {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  overflow: hidden;
}
.flare-plugin-view.is-list-layout > :not(.flare-plugin-view__rows) {
  flex: none;
}
.flare-plugin-view.is-list-layout > .flare-plugin-view__rows {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  min-width: 0;
  overflow: hidden;
}
/* Straight into a bottom sheet: the sheet's insets, the same as PluginForm; sheetTop leaves the bottom one to what follows. */
.flare-plugin-view.is-embedded.is-inset-sheet {
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg)
    var(--flare-size-spacing-xl);
}
.flare-plugin-view.is-embedded.is-inset-sheet-top {
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) 0;
}
/* A card shell kept in a sheet: the insets go around the shell, which keeps its own padding. */
.flare-plugin-view.is-inset-sheet:not(.is-embedded),
.flare-plugin-view.is-inset-sheet-top:not(.is-embedded) {
  max-width: calc(100% - 2 * var(--flare-size-spacing-lg));
  margin: var(--flare-size-spacing-md) var(--flare-size-spacing-lg)
    var(--flare-size-spacing-xl);
}
.flare-plugin-view.is-inset-sheet-top:not(.is-embedded) {
  margin-bottom: 0;
}
.flare-plugin-view__unavailable {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-view__head {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-plugin-view__head .flare-plugin-view__title {
  flex: 1 1 auto;
}
/* The ⋯ key: an icon-sized glyph whose target reaches the touch target around it. */
.flare-plugin-view__more {
  position: relative;
  flex: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-inline-end: calc(var(--flare-size-spacing-xs) * -1);
  padding: var(--flare-size-spacing-2xs);
  border: 0;
  border-radius: var(--flare-size-radius-sm);
  background: transparent;
  color: var(--flare-color-text-secondary);
  cursor: pointer;
}
.flare-plugin-view__more::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
  transform: translate(-50%, -50%);
}
.flare-plugin-view__more:disabled {
  cursor: default;
  opacity: 0.5;
}
@media (hover: hover) {
  .flare-plugin-view__more:not(:disabled):hover {
    background: var(--flare-color-bg-hover);
    color: var(--flare-color-text-primary);
  }
}
.flare-plugin-view__more:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-plugin-view__reason {
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-view__reason--copy {
  color: var(--flare-color-text-tertiary);
}
.flare-plugin-view__quote {
  min-width: 0;
}
.flare-plugin-view__icon {
  flex: none;
  color: var(--flare-color-primary-text);
}
.flare-plugin-view__title {
  min-width: 0;
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-medium);
  line-height: var(--flare-size-line-height-snug);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-view__fields {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  margin: 0;
  font-size: var(--flare-size-font-size-md);
}
.flare-plugin-view__fields > div {
  display: grid;
  grid-template-columns: minmax(4em, 1fr) minmax(0, 2fr);
  gap: var(--flare-size-spacing-md);
}
.flare-plugin-view__fields dt {
  color: var(--flare-color-text-secondary);
}
.flare-plugin-view__fields dd {
  margin: 0;
}
.flare-plugin-view__footer {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  column-gap: var(--flare-size-spacing-sm);
  row-gap: var(--flare-size-spacing-2sm);
  min-width: 0;
  padding-block-start: var(--flare-size-spacing-2xs);
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-plugin-view__inline-section {
  display: grid;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-width: 0;
  margin-top: var(--flare-size-spacing-lg);
  padding-top: var(--flare-size-spacing-lg);
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-plugin-view__inline-section.has-form-heading {
  max-width: var(--flare-size-layout-primary-pane-max-width);
}
.flare-plugin-view__inline-heading {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-plugin-view__inline-heading h3 {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  font-weight: var(--flare-size-font-weight-semibold);
  overflow-wrap: anywhere;
}
.flare-plugin-view__inline-heading p {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-md);
  line-height: var(--flare-size-line-height-relaxed);
  overflow-wrap: anywhere;
}
.flare-plugin-view__inline-form {
  min-width: 0;
}
.flare-plugin-view__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
}
.flare-plugin-view__actions > * {
  flex: 0 1 auto;
  max-width: 100%;
  white-space: normal;
  height: auto;
}
.flare-plugin-view.has-actions-compact .flare-plugin-view__actions {
  gap: var(--flare-size-spacing-sm);
}
.flare-plugin-view.has-actions-compact .flare-plugin-view__actions > * {
  min-height: var(--flare-size-layout-control-height-sm);
}
.flare-plugin-view.has-actions-list .flare-plugin-view__footer,
.flare-plugin-view.has-actions-list .flare-plugin-view__actions {
  display: grid;
  width: 100%;
  gap: 0;
}
.flare-plugin-view.has-actions-list .flare-plugin-view__actions > * {
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-md) 0;
  justify-content: flex-start;
  border-radius: 0;
  text-align: start;
}
.flare-plugin-view.has-actions-list .flare-plugin-view__actions > * + * {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-plugin-view.has-actions-list
  .flare-plugin-view__actions
  :deep(.flare-button__label) {
  width: 100%;
}
.flare-plugin-view__service-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  width: 100%;
}
.flare-plugin-view__service-label > .flare-icon {
  flex: none;
  color: var(--flare-color-text-tertiary);
}
.flare-plugin-view__detail {
  flex: none;
  margin-inline-start: auto;
  padding-inline: var(--flare-size-spacing-2xs);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-medium);
}
.flare-plugin-view__detail :deep(.flare-button__label) {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
}
.flare-plugin-view.is-embedded .flare-plugin-view__footer {
  border-top: 0;
  padding-block-start: 0;
}
@media (pointer: coarse) {
  .flare-plugin-view__footer {
    row-gap: var(--flare-size-spacing-md);
  }
}
</style>
