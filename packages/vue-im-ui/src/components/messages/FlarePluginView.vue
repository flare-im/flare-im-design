<script setup lang="ts">
import FlarePluginQr from "../scan/FlarePluginQr.vue";
import {
  computed,
  getCurrentInstance,
  h,
  useSlots,
  type FunctionalComponent,
  reactive,
  ref,
  shallowReactive,
  useId,
  watch,
} from "vue";
import FlareAdminHelp from "../data/FlareAdminHelp.vue";
import FlareAdminSection from "../data/FlareAdminSection.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareDrawer from "../general/FlareDrawer.vue";
import FlareScreen from "../layout/FlareScreen.vue";
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
import PluginBannerBlock from "./plugin/blocks/PluginBannerBlock.vue";
import PluginChartBlock from "./plugin/blocks/PluginChartBlock.vue";
import PluginHeroBlock from "./plugin/blocks/PluginHeroBlock.vue";
import PluginImageBlock from "./plugin/blocks/PluginImageBlock.vue";
import PluginQrBlock from "./plugin/blocks/PluginQrBlock.vue";
import PluginSectionBlock from "./plugin/blocks/PluginSectionBlock.vue";
import PluginStatsBlock from "./plugin/blocks/PluginStatsBlock.vue";
import PluginStepsBlock from "./plugin/blocks/PluginStepsBlock.vue";
import PluginTimelineBlock from "./plugin/blocks/PluginTimelineBlock.vue";
import FlarePluginUpgradeNotice from "./FlarePluginUpgradeNotice.vue";
import FlareResultView from "./FlareResultView.vue";
import PluginFieldList from "./plugin/PluginFieldList.vue";
import FlareSettingsRow from "../profile/FlareSettingsRow.vue";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import {
  flarePluginActionPlaces,
  flarePluginActionRole,
  flarePluginBoundInputs,
  flarePluginDrawnInputs,
  flarePluginFormPlacement,
  flarePluginResultBlock,
  flarePluginResultFacts,
  flarePluginResultIcon,
  flarePluginStatusCard,
  flarePluginStatusDraw,
  flarePluginTopLevelActions,
  type FlarePluginActionPlaces,
} from "../../shared/contracts/plugin-experience";
import { flareIcons, type FlareIconName } from "../../shared/icons";
import FlareIconButton from "../general/FlareIconButton.vue";
import { useFlarePluginWarnScope } from "./plugin/warnScope";
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
  flarePluginFlatBlocks,
  flarePluginDateTime,
  flarePluginFormatText,
  flarePluginInlineFormAction,
  flarePluginReasonLine,
  flarePluginShowsDetailKey,
  flarePluginUnavailableKey,
  flarePluginWithinCap,
  type FlarePluginAction,
  type FlarePluginActionPayload,
  type FlarePluginBannerBlock,
  type FlarePluginBlock,
  type FlarePluginChoicesBlock,
  type FlarePluginField,
  type FlarePluginFieldsBlock,
  type FlarePluginFormat,
  type FlarePluginFormError,
  type FlarePluginFormSection,
  type FlarePluginHeroBlock,
  type FlarePluginImageSource,
  type FlarePluginQrBlock,
  type FlarePluginQrRefresh,
  type FlarePluginSectionBlock,
  type FlarePluginStatsBlock,
  type FlarePluginUpgradeStatus,
  type FlarePluginFileState,
  type FlarePluginFileAction,
  type FlarePluginLocationAction,
  type FlarePluginLocationState,
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
    encodeQr?: (token: string) => Promise<string>;
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
    /**
     * `message` is the timeline card (default). `admin` moves the explanations that lead a page into the admin
     * help popover (flow layout: the page head) and the warnings into the list notice, clamped to two lines.
     */
    presentation?: "message" | "admin";
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
    /**
     * Visual grouping only; forms, confirmations and action guards keep the same runner. `roles` is the plugin page's
     * layout (docs/plugin-experience.md R2): each action placed by its role and the page archetype.
     */
    actionLayout?: "inline" | "compact" | "list" | "roles";
    /**
     * Roles layout on a view of actions only (the account appearance, R2.1 / §5.1): place them as an overview page and
     * draw one part — `quick` the quick keys row, `lists` the list cards and the danger card.
     */
    overviewPart?: "quick" | "lists";
    /** The host is offline: every action is disabled (not hidden) and the primary says when it comes back (R8). */
    offline?: boolean;
    /** Page hosts give long action forms their own full-height editor. */
    formPresentation?: "sheet" | "page";
    /** Host-owned grouping for administrative forms; validation and values are unchanged. */
    formSections?: (actionId: string) => readonly FlarePluginFormSection[] | undefined;
    /** Formats timestamps (epoch milliseconds); absent keeps the kit's default. */
    formatTime?: (ms: number) => string;
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
    /** Location inputs: the host's fix, a running locate or a failure, by input id. */
    locationStates?: Record<string, FlarePluginLocationState>;
    /** Initial values for the action/row selected by the user; captured once when opening. */
    formInitialValues?: (
      actionId: string,
      row?: { key: string; input: unknown },
    ) => Record<string, unknown> | undefined;
    /** Lets a host name the form submit button independently of its opening action. */
    formSubmitLabel?: (actionId: string) => string | undefined;
    /** Host presentation for one action form, with the same declared input IDs. */
    actionFormInput?: (actionId: string, input: FlarePluginInput) => FlarePluginInput;
    validateField?: (id: string, values: Readonly<Record<string, unknown>>) => string | undefined;
    formSelections?: Record<string, SchemaSelection>;
    formChangeActions?: ReadonlyArray<string>;
    selectionLabels?: SchemaSelectionLabels;
    /** The scale the host knows for an asset, for a money value whose data holds none. */
    assetScale?: (assetId: string) => number | undefined;
    /** What the host has for each protected media item, by item id. */
    protectedMedia?: Record<string, FlarePluginProtectedMediaState>;
    /** Turns an image block's asset path or private file id into what the host fetched (blob:, https: or data:image). */
    resolveImage?: (source: FlarePluginImageSource) => string | undefined | Promise<string | undefined>;
    /** upgrade_required: update.plugin_upgrade_status for the view's minBuild (FlarePluginUpgradeNotice). */
    upgradeStatus?: FlarePluginUpgradeStatus | null;
    /** upgrade_required: opens the update flow; without it the notice has no update key. */
    onUpdate?: () => void;
    /** The update flow is opening. */
    upgradeBusy?: boolean;
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
    presentation: "message",
    actionsPlacement: "footer",
    actionLayout: "inline",
    overviewPart: undefined,
    formPresentation: "sheet",
    labelRows: false,
    resolveUser: undefined,
    members: () => [],
    formErrors: () => [],
    settleToken: 0,
    resolveImage: undefined,
    upgradeStatus: undefined,
    onUpdate: undefined,
    upgradeBusy: false,
    offline: false,
  },
);
const emit = defineEmits<{
  interactionChange: [active: boolean];
  /** The result view's done key (R7): the host pops back to the page that started the flow, or closes. */
  done: [];
  action: [actionId: string, payload: FlarePluginActionPayload];
  fileAction: [event: FlarePluginFileAction];
  /** A location input's locate or clear key: the host runs the page's locationOnce action into the input. */
  locationAction: [event: FlarePluginLocationAction];
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
  /** An expired QR code's refresh: the host runs the query and passes back a view with the fresh code. */
  qrRefresh: [request: FlarePluginQrRefresh];
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
  seconds: t("pluginView.seconds"),
  countUnits: t("pluginView.countUnits"),
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
  "section",
  "stats",
  "chart",
  "image",
  "qr",
  "hero",
  "steps",
  "banner",
  "timeline",
  "result",
]);
const CHART_KINDS = new Set(["bar", "line", "donut"]);
/** A known kind; a chart of a kind the kit does not draw is skipped too, as in every kit. */
const known = (block: FlarePluginBlock) =>
  KNOWN.has((block as { kind: string }).kind)
  && (block.kind !== "chart" || CHART_KINDS.has((block as { chartKind?: string }).chartKind ?? ""));
/** Blocks the kit knows, in order; a kind from a newer protocol is skipped (in sections too). */
const blocks = computed<FlarePluginBlock[]>(() =>
  (props.view.blocks ?? []).filter(known).map((block) =>
    block.kind === "section"
      ? { ...block, blocks: (block.blocks ?? []).filter(known) }
      : block,
  ),
);
/**
 * What the body draws, in reading order: every block, a section's heading followed by its children (spec
 * blocks2.flatten). `index` keys the per-block state (choices drafts, the first rows block); `section` is the index
 * of the heading a child belongs to.
 */
const items = computed(() =>
  flarePluginFlatBlocks(blocks.value).map((item, index) => ({ ...item, index })),
);
// A section's fold: the reader's choice, else what the plugin declared. Kept across new views of the same card.
const folded = reactive(new Map<number, boolean>());
function sectionCollapsed(index: number): boolean {
  const block = items.value[index]?.block as FlarePluginSectionBlock | undefined;
  if (!block || block.kind !== "section" || !block.label) return false;
  return folded.get(index) ?? Boolean(block.collapsed);
}
function toggleSection(index: number): void {
  folded.set(index, !sectionCollapsed(index));
}

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
const SPECIAL_RENDERERS = new Set(["redPacket.card", "redPacket.review"]);
const specialPresentation = computed(
  () =>
    props.view.available &&
    SPECIAL_RENDERERS.has(props.view.presentation?.renderer ?? ""),
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
    props.offline ||
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
// A message card's ⋯ menu also takes the actions past its third footer key (R2.4).
const menuSource = computed<FlarePluginAction[]>(() =>
  places.value?.archetype === "card" ? places.value.menu : menuActions.value,
);
const menuItems = computed<FlareActionItem[]>(() =>
  menuSource.value.map((action) => ({
    id: action.id,
    label: action.label,
    danger: action.style === "danger",
    enabled: !locked.value && !action.disabledReason,
  })),
);
function runMenu(id: string): void {
  const action = menuSource.value.find((candidate) => candidate.id === id);
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
const footerActionGroups = computed(() => {
  const isService = (action: FlarePluginAction) => Boolean(action.target?.kind === "page" || action.form?.length);
  return props.actionLayout === "list"
    ? [{ service: true, actions: footerActions.value.filter(isService) }, { service: false, actions: footerActions.value.filter(action => !isService(action)) }].filter(group => group.actions.length)
    : [{ service: false, actions: footerActions.value }].filter(group => group.actions.length);
});
// ── R2 roles: where each action goes on a plugin page (`roles`) or a message card (docs/plugin-experience.md) ──
const platform = useFlarePlatformSafe();
/** The phone form factor: pinned action bar, full-width keys. */
const phone = computed(() => platform.capabilities.value.bottomSheet);
const bound = computed(() => flarePluginBoundInputs(props.view));
const rolesLayout = computed(() => props.actionLayout === "roles");
const cardLayout = computed(() => !props.embedded && props.presentation === "message" && props.actionsPlacement === "footer" && !specialPresentation.value);
// R7: a result block leads the page; its fields are the details and its actions secondary keys.
const result = computed(() => (props.embedded && props.view.available ? flarePluginResultBlock(props.view) : undefined));
const warnAt = useFlarePluginWarnScope();
const resultFacts = computed(() => result.value && flarePluginResultFacts(
  result.value.amount ? { ...result.value, amount: flarePluginFormatText(result.value.amount, result.value.format, formatContext.value) } : result.value,
  t("pluginView.unknownStatus"), warnAt(`result:${result.value.state}`)));
const resultActions = computed(() => (result.value ? flarePluginTopLevelActions(props.view, true) : []));
const places = computed<FlarePluginActionPlaces | null>(() =>
  props.view.available && (rolesLayout.value || cardLayout.value) && !result.value
    ? flarePluginActionPlaces(props.view, { embedded: props.embedded, inlineFormActionId: inlineFormAction.value?.id, ...(props.overviewPart ? { archetype: "overview" as const } : {}) })
    : null,
);
// 6.1 status card: the status field as title, the first text or note as description, the steps across, the first
// primary as its key; what it replaces is not drawn again.
const statusCard = computed(() => {
  if (!rolesLayout.value || !places.value || !flarePluginStatusCard(props.view)) return null;
  const field = props.view.fields.find((candidate) => candidate.tone !== undefined || candidate.unmapped);
  const draw = field ? flarePluginStatusDraw(field, warnAt(`statusCard:${field.label}`)) : undefined;
  const blocks = props.view.blocks ?? [];
  const steps = blocks.find((block) => block.kind === "steps");
  const lead = blocks.find((block) => block.kind === "text" || block.kind === "note");
  const tone = draw?.tone ?? "neutral";
  const all = places.value;
  return {
    field, tone, icon: flarePluginResultIcon(tone),
    title: draw?.unknown ? t("pluginView.unknownStatus") : field?.value || props.view.title,
    description: lead && (lead.kind === "text" || lead.kind === "note") ? lead.text : undefined,
    steps: steps?.kind === "steps" ? steps : undefined,
    primary: [...all.bar, ...all.header, ...all.quick].find((action) => flarePluginActionRole(action) === "primary"),
    // 6.1: a banner with its own key (the unconfirmed operation's 「处理」) leads, above the card; the others it replaces.
    lead: blocks.filter((block): block is FlarePluginBannerBlock => block.kind === "banner" && Boolean(block.action)),
    hidden: new Set<FlarePluginBlock>([steps, lead, ...blocks.filter((block) => block.kind === "banner")].filter((block) => block !== undefined)),
  };
});
/** A place's actions as drawn: the status card's key and the inline form's own submit are not drawn twice. */
const placed = (actions: ReadonlyArray<FlarePluginAction>) =>
  actions.filter((action) => action !== statusCard.value?.primary && action.id !== inlineFormAction.value?.id);
const footerKeys = computed(() => (places.value?.archetype === "card" ? places.value.footer : footerActions.value));
/**
 * R2.1: the overview card holds the section that carries the hero/stats (else the first run of top-level hero/stats
 * blocks) and closes with the quick keys. The body is drawn in groups so that only this range gets a container.
 */
const overviewRange = computed<[number, number] | null>(() => {
  if (places.value?.archetype !== "overview") return null;
  const all = items.value;
  const first = all.find(({ block }) => block.kind === "hero" || block.kind === "stats");
  if (!first) return null;
  if (first.section !== undefined) return [first.section, all.filter((item) => item.section === first.section).at(-1)!.index];
  let end = first.index;
  while (all[end + 1] && all[end + 1].section === undefined && ["hero", "stats"].includes(all[end + 1].block.kind)) end++;
  return [first.index, end];
});
const itemGroups = computed(() => {
  const range = overviewRange.value;
  if (!range) return [{ key: "all", card: false, items: items.value }];
  return [
    { key: "before", card: false, items: items.value.slice(0, range[0]) },
    { key: "overview", card: true, items: items.value.slice(range[0], range[1] + 1) },
    { key: "after", card: false, items: items.value.slice(range[1] + 1) },
  ];
});
// A container only for the overview group; every other group renders its children in place (a fragment).
const OverviewCard: FunctionalComponent<{ card: boolean }> = (props, { slots }) =>
  props.card ? h("div", { class: "flare-plugin-view__overview", "data-overview-card": "true" }, slots.default?.()) : slots.default?.();
OverviewCard.props = ["card"];
/** The first primary of the page: under an empty data block it offers to create (R8). */
const createAction = computed(() => (rolesLayout.value ? flarePluginTopLevelActions(props.view, true).find((action) => flarePluginActionRole(action) === "primary") : undefined));
/** R8 offline: the line under the first primary key group. */
const offlineCaption = computed(() => {
  if (!props.offline || !places.value) return undefined;
  const all = places.value;
  return all.quick.length ? "quick" : all.bar.length ? "bar" : all.footer.length ? "footer" : all.commands.length ? "commands" : undefined;
});
/** R2.5: a disabled action's reason line under its key group; the key names it with aria-describedby. */
const whyPrefix = useId();
const whyId = (action: FlarePluginAction) => (action.disabledReason ? `${whyPrefix}-why-${action.id}` : undefined);
const whyOf = (actions: ReadonlyArray<FlarePluginAction>) => actions.filter((action) => action.disabledReason);
/** A top-level action by id, for a key the page host draws in its own header (records: the header place). */
function runAction(id: string): void {
  const action = flarePluginTopLevelActions(props.view, props.embedded).find((candidate) => candidate.id === id);
  if (action) run(action, {});
}
defineExpose({ runAction });
// The card's view details key (spec rules.detailKey): a detail no entries block offers, and a host that listens
// for openDetail (read at render: listeners are not reactive props).
const instance = getCurrentInstance();
const detailKey = () =>
  flarePluginShowsDetailKey(props.view, props.embedded) &&
  Boolean(instance?.vnode.props?.onOpenDetail);

// ── vocabulary 2 actions: hero and banner own theirs; a QR code asks the host to refresh ─────────────────
function runOwned(action: FlarePluginAction): void {
  run(action, {});
}
const canRefreshQr = () => Boolean(instance?.vnode.props?.onQrRefresh);
function refreshQr(block: FlarePluginQrBlock): void {
  if (locked.value || !block.refreshOperation) return;
  emit("qrRefresh", {
    operation: block.refreshOperation,
    valuePath: block.valuePath,
    ...(block.expiresAtPath ? { expiresAtPath: block.expiresAtPath } : {}),
  });
}
const upgradeRequired = computed(
  () => !props.view.available && props.view.unavailableReason === "upgrade_required",
);

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
  for (const { block } of items.value) {
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
  formatTime: props.formatTime,
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
const shownFields = computed(() => (props.view.fields ?? []).filter((field) => field !== statusCard.value?.field).map(shownField));
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
  if (block.kind === "stats") {
    const stats = block as unknown as FlarePluginStatsBlock;
    return {
      ...block,
      items: stats.items.map((item) => ({
        ...item,
        value: flarePluginFormatText(item.value, item.format, formatContext.value),
      })),
    };
  }
  if (block.kind === "hero") {
    const hero = block as unknown as FlarePluginHeroBlock;
    return { ...block, value: flarePluginFormatText(hero.value, hero.format, formatContext.value) };
  }
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
watch(() => Boolean(confirming.value || formAction.value || inlineFormAction.value), active => emit("interactionChange", active), { immediate: true });
// The forms on this view: a page action whose native target writes into one of their inputs runs through it.
const inlineForm = ref<InstanceType<typeof FlarePluginForm> | null>(null);
const sheetForm = ref<InstanceType<typeof FlarePluginForm> | null>(null);
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
function actionInput(actionId: string, id: string): FlarePluginInput[] {
  const input = props.view.inputs?.find((input) => input.id === id);
  return input ? [props.actionFormInput?.(actionId, input) ?? input] : [];
}
const inlineInputs = computed(() => {
  const action = inlineFormAction.value;
  return action ? flarePluginDrawnInputs(action, bound.value).flatMap(id => actionInput(action.id, id)) : [];
});
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
  return flarePluginDrawnInputs(action, bound.value).flatMap(id => actionInput(action.id, id));
});
/** Where an action form opens: `roles` pages follow R6 (a short form is a sheet), others keep formPresentation. */
const formPlacement = computed<"sheet" | "page">(() =>
  rolesLayout.value
    ? flarePluginFormPlacement(formInputs.value.map((input) => input.kind), false)
    : props.presentation === "admin" && formInputs.value.length > 6 && props.formSections?.(formAction.value?.id ?? "")?.length
      ? "page" : props.formPresentation,
);
const formSelectPresentation = computed(() =>
  props.actionsPlacement === "rows" || (!rolesLayout.value && formPlacement.value === "page") ? "dropdown" as const : undefined,
);
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
  if (locked.value || action.disabledReason) return;
  // A page action sends back the input the view bound for it; a row's comes with the row.
  if (!payload.row && action.values) payload = { ...payload, input: action.values };
  // A native target writing `into` an input of a form on this view runs through that input's own key, so the
  // host's answer is written into the form's current scope (no earlier touch of the input needed).
  if (
    !payload.row &&
    action.target?.kind === "native" &&
    action.target.into &&
    (inlineForm.value?.nativeInto(action.target) || sheetForm.value?.nativeInto(action.target))
  )
    return;
  const proceed = () => {
    if (flarePluginDrawnInputs(action, bound.value).length) {
      formRowContext.value = null;
      let rowValues: Record<string, unknown> | undefined;
      if (payload.row) {
        for (const block of props.view.blocks ?? []) {
          if (block.kind !== "rows") continue;
          const row = block.rows.find((row) => row.key === payload.row?.key);
          const bound = row?.actions.find(
            (a) =>
              a.id === action.id &&
              JSON.stringify(a.input) === JSON.stringify(payload.row?.input),
          );
          if (!row || !bound) continue;
          rowValues = bound.values;
          formRowContext.value = {
            kind: "fields",
            fields: row.cells.map((cell, index) =>
              shownField({
                label: block.columns[index]?.label ?? "",
                value: cell.text,
                format: block.columns[index]?.format === "time" && typeof cell.timeMs === "number"
                  ? { kind: "time", atMs: cell.timeMs }
                  : cell.format,
                user: cell.user,
              }),
            ),
          };
          break;
        }
      }
      formSubmitted.value = false;
      // The row's own values (resolved per row by the view); the host's win.
      const hostInitial = props.formInitialValues?.(action.id, payload.row);
      const initial = rowValues ? { ...rowValues, ...hostInitial } : hostInitial;
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
  // R2: on a page a danger action always asks first, declared confirm text or not.
  if (action.confirm || (rolesLayout.value && action.style === "danger")) confirming.value = { action, proceed };
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
  dispatchForm(action, action.values ? { input: action.values } : {}, values);
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
  () => items.value.find((item) => item.block.kind === "rows")?.index ?? -1,
);
const actionsInRows = computed(
  () => props.actionsPlacement === "rows" && firstRowsIndex.value >= 0,
);
// Admin presentation: which explanation blocks leave the page body, and where they go. A list page that has a
// `rows` slot sends the ones before its first rows there (help / notices); without the slot nothing moves, so
// no text can vanish. Any other page gathers its long calm notes and its leading body text into the page-head
// help; short label-like notes, headings, text after content and warnings stay in place.
const slots = useSlots();
const ADMIN_NOTE_HELP_MIN = 30;
const isLoudNote = (block: FlarePluginBlock) =>
  block.kind === "note" && (block.tone === "warning" || block.tone === "danger");
const adminLayout = computed(() => {
  const out = {
    hidden: new Set<number>(),
    help: [] as FlarePluginBlock[],
    notices: [] as FlarePluginBlock[],
    sections: new Map<number, string>(),
    header: [] as FlarePluginBlock[],
  };
  if (props.presentation !== "admin") return out;
  // A host without a list presenter has no help/notices destination for leading explanations.
  // Keep that fallback list's content inline, as the list contract requires.
  if (props.contentLayout === "list" && !slots.rows) return out;
  // A flow page: a title line straight above a fields block becomes that block's section title.
  if (props.contentLayout === "flow") {
    const all = items.value;
    all.forEach((item, at) => {
      const next = all[at + 1];
      if (
        item.section === undefined && item.block.kind === "text" && item.block.style === "title" &&
        next?.block.kind === "fields" && next.section === undefined
      ) {
        out.hidden.add(item.index);
        out.sections.set(next.index, item.block.text);
      }
    });
  }
  const list =
    props.contentLayout === "list" && firstRowsIndex.value >= 0 && !!slots.rows;
  let contentStarted = false;
  for (const { block, index, section } of items.value) {
    if (section !== undefined) continue;
    if (list && index >= firstRowsIndex.value) break;
    if (block.kind !== "note" && block.kind !== "text") {
      if (block.kind !== "divider") contentStarted = true;
      continue;
    }
    const loud = isLoudNote(block);
    if (list) {
      out.hidden.add(index);
      (loud ? out.notices : out.help).push(block);
      continue;
    }
    const style = block.kind === "text" ? (block.style as string | undefined) : undefined;
    const toHelp =
      block.kind === "note"
        ? !loud && block.text.length > ADMIN_NOTE_HELP_MIN
        : !contentStarted && style !== "title" && style !== "heading";
    if (toHelp) {
      out.hidden.add(index);
      out.header.push(block);
    }
  }
  return out;
});
// Admin flow page: sections, a primary save with secondary companions, md text, a readable line width.
const adminFlow = computed(() => props.presentation === "admin" && props.contentLayout === "flow");
const adminPrimaryId = computed(() => footerActions.value.find((action) => action.style === "primary")?.id);
const adminClamp = (block: FlarePluginBlock) =>
  props.presentation === "admin" && isLoudNote(block) ? 2 : undefined;
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
const footerVariant = (action: FlarePluginAction) =>
  adminFlow.value && action.style !== "danger"
    ? action.id === adminPrimaryId.value ? "primary" : "secondary"
    : variantOf(action);
const variantOf = (action: FlarePluginAction) =>
  action.style === "danger"
    ? "danger"
    : action.style === "primary"
      ? "primary"
      : "secondary";
function forwardFileAction(event: FlarePluginFileAction): void { emit("fileAction", event); }
function forwardLocationAction(event: FlarePluginLocationAction): void { emit("locationAction", event); }
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
      'is-admin-flow': adminFlow,
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
        size="sm"
      />
      <strong class="flare-plugin-view__title">{{ view.title }}</strong>
      <FlareButton
        v-if="detailKey() && !footerKeys.length"
        class="flare-plugin-view__detail"
        variant="quiet"
        size="sm"
        appearance="text"
        :disabled="locked"
        data-detail-key="true"
        @click="emit('openDetail')"
      >
        <span>{{ t("pluginView.detail") }}</span>
        <FlareIcon name="chevron-right" size="sm" aria-hidden="true" />
      </FlareButton>
      <FlareActionMenu
        v-if="menuItems.length"
        :items="menuItems"
        :label="t('pluginView.more')"
        placement="bottom-end"
        @select="runMenu"
      >
        <FlareIconButton
          class="flare-plugin-view__more"
          :icon="flareIcons.more"
          :ariaLabel="t('pluginView.more')"
          :title="t('pluginView.more')"
          size="sm"
          :disabled="locked"
          data-plugin-menu="true"
        />
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
    <!-- A contribution this build cannot draw: the line and, when a newer build is offered, the update key. -->
    <FlarePluginUpgradeNotice
      v-if="upgradeRequired"
      variant="card"
      :status="upgradeStatus"
      :on-update="onUpdate"
      :busy="upgradeBusy"
    />
    <p
      v-else-if="!view.available && reasonLine"
      class="flare-plugin-view__reason"
      data-unavailable-reason="true"
    >
      {{ reasonLine }}
    </p>
    <FlareResolvedPresentation
      v-if="specialPresentation"
      :view="view"
      :busy="locked"
      @request="presentationRequest"
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
    <FlarePluginQr v-if="view.available && view.presentation?.renderer === 'flare.qr'" :token="typeof view.presentation.props.token === 'string' ? view.presentation.props.token : undefined" :ttl-ms="typeof view.presentation.props.ttlMs === 'number' ? view.presentation.props.ttlMs : undefined" :caption="typeof view.presentation.props.caption === 'string' ? view.presentation.props.caption : undefined" :encode-qr="encodeQr" />
    <template v-if="view.available && !specialPresentation">
      <div
        v-if="adminLayout.header.length"
        class="flare-plugin-view__help"
        data-admin-help="true"
      >
        <FlareAdminHelp :label="t('plugin.admin.help')">
          <div class="flare-plugin-view__help-body">
            <template v-for="(helpBlock, helpIndex) in adminLayout.header" :key="helpIndex">
              <PluginTextBlock v-if="helpBlock.kind === 'text'" :block="helpBlock" />
              <PluginSimpleBlock v-else-if="helpBlock.kind === 'note'" :block="helpBlock" />
            </template>
          </div>
        </FlareAdminHelp>
      </div>
      <FlareResultView
        v-if="result && resultFacts"
        class="flare-plugin-view__result"
        :title="resultFacts.title"
        :tone="resultFacts.tone"
        :amount="resultFacts.amount"
        :description="resultFacts.description"
        :details="shownFields"
        :busy="locked"
        :data-result-unknown="resultFacts.unknown ? 'true' : undefined"
        data-block="result"
        @done="emit('done')"
      >
        <template #actions>
        <FlareButton
          v-for="action in resultActions"
          :key="action.id"
          class="flare-plugin-view__result-key"
          variant="secondary"
          :block="phone"
          :label="action.label"
          :loading="busyActionId === action.id"
          :disabled="locked || Boolean(action.disabledReason)"
          :aria-describedby="whyId(action)"
          :data-action-id="action.id"
          :data-action-variant="variantOf(action)"
          @click="run(action, {})"
        />
        <p v-for="action in whyOf(resultActions)" :id="whyId(action)" :key="`why-${action.id}`" class="flare-plugin-view__why" data-disabled-reason="true">{{ action.disabledReason }}</p>
        </template>
      </FlareResultView>
      <PluginBannerBlock v-for="(banner, bannerIndex) in statusCard?.lead ?? []" :key="`lead-${bannerIndex}`" :block="banner" :busy="locked" data-block="banner" @action="runOwned" />
      <section v-if="statusCard" class="flare-plugin-view__status-card" :class="`is-${statusCard.tone}`" data-status-card="true">
        <div class="flare-plugin-view__status-head">
          <span class="flare-plugin-view__status-icon" aria-hidden="true"><FlareIcon :name="statusCard.icon" size="lg" /></span>
          <h2 class="flare-plugin-view__status-title">{{ statusCard.title }}</h2>
        </div>
        <p v-if="statusCard.description" class="flare-plugin-view__status-description">{{ statusCard.description }}</p>
        <PluginStepsBlock v-if="statusCard.steps" :block="statusCard.steps" />
        <FlareButton
          v-if="statusCard.primary"
          :block="phone"
          :label="statusCard.primary.label"
          :loading="busyActionId === statusCard.primary.id"
          :disabled="locked || Boolean(statusCard.primary.disabledReason)"
          :aria-describedby="whyId(statusCard.primary)"
          :data-action-id="statusCard.primary.id"
          data-action-variant="primary"
          @click="run(statusCard.primary, {})"
        />
        <p v-for="action in whyOf(statusCard.primary ? [statusCard.primary] : [])" :id="whyId(action)" :key="action.id" class="flare-plugin-view__why" data-disabled-reason="true">{{ action.disabledReason }}</p>
        <p v-if="offline && statusCard.primary" class="flare-plugin-view__offline" data-offline-caption="true">{{ t("pluginView.availableOnline") }}</p>
      </section>
      <PluginFieldList v-if="!result && shownFields.length" list-class="flare-plugin-view__fields" :fields="shownFields" />
      <template v-for="group in itemGroups" :key="group.key">
      <OverviewCard :card="group.card">
      <template v-for="{ block, index, section } in group.items" :key="index">
        <template v-if="(section === undefined || !sectionCollapsed(section)) && !adminLayout.hidden.has(index) && block.kind !== 'result' && !statusCard?.hidden.has(block)">
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
          :show-all="Boolean(instance?.vnode.props?.onOpenDetail)"
          :time-text="formatTime ?? ((ms: number) => flarePluginDateTime(ms, formatContext.nowMs, strings))"
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
          :format-time="formatTime"
          data-block="time"
        />
        <!-- Host business presenters keep the same form, confirmation and action pipeline. -->
        <div v-else-if="block.kind === 'rows'" class="flare-plugin-view__rows">
          <slot
            name="rows"
            :block="block"
            :shown-block="shownRows(block)"
            :strings="strings"
            :format-time="formatTime"
            :busy="locked"
            :busy-action-id="busyActionId"
            :busy-row="rowInFlight"
            :run="rowAction"
            :actions="
              actionsInRows && index === firstRowsIndex ? footerActions : []
            "
            :run-action="runPageAction"
            :help="adminLayout.help"
            :notices="adminLayout.notices"
            :open-row="openRow"
            :load-more="(cursor: string) => loadRowsMore(cursor, block)"
          >
            <PluginRowsBlock
              :block="shownRows(block)"
              :label-rows="labelRows"
              :strings="strings"
              :format-time="formatTime"
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
          <!-- R8: an empty data block offers the page's create action under its empty state. -->
          <FlareButton
            v-if="createAction && !block.rows.length && rowsLayout === 'list'"
            class="flare-plugin-view__create"
            :label="createAction.label"
            :loading="busyActionId === createAction.id"
            :disabled="locked"
            :data-empty-action="createAction.id"
            @click="run(createAction, {})"
          />
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
        <PluginSectionBlock
          v-else-if="block.kind === 'section'"
          :block="block"
          :collapsed="sectionCollapsed(index)"
          data-block="section"
          @toggle="toggleSection(index)"
        />
        <PluginStatsBlock
          v-else-if="block.kind === 'stats'"
          :block="shownBlock(block)"
          data-block="stats"
        />
        <PluginChartBlock
          v-else-if="block.kind === 'chart'"
          :block="block"
          data-block="chart"
        />
        <PluginImageBlock
          v-else-if="block.kind === 'image'"
          :block="block"
          :resolve="resolveImage"
          data-block="image"
        />
        <PluginQrBlock
          v-else-if="block.kind === 'qr'"
          :block="block"
          :can-refresh="canRefreshQr()"
          :busy="locked"
          data-block="qr"
          @refresh="refreshQr(block)"
        />
        <PluginHeroBlock
          v-else-if="block.kind === 'hero'"
          :block="shownBlock(block)"
          :busy="locked"
          :busy-action-id="busyActionId"
          data-block="hero"
          @action="runOwned"
        />
        <PluginStepsBlock
          v-else-if="block.kind === 'steps'"
          :block="block"
          data-block="steps"
        />
        <PluginBannerBlock
          v-else-if="block.kind === 'banner'"
          :block="block"
          :busy="locked"
          data-block="banner"
          @action="runOwned"
        />
        <PluginTimelineBlock
          v-else-if="block.kind === 'timeline'"
          :block="block"
          :strings="strings"
          :format-time="formatTime"
          data-block="timeline"
        />
        <FlareAdminSection
          v-else-if="block.kind === 'fields' && adminLayout.sections.has(index)"
          :title="adminLayout.sections.get(index) ?? ''"
        >
          <PluginSimpleBlock :block="shownBlock(block)" data-block="fields" />
        </FlareAdminSection>
        <PluginSimpleBlock
          v-else-if="
            block.kind === 'fields' ||
            block.kind === 'status' ||
            block.kind === 'progress' ||
            block.kind === 'divider' ||
            block.kind === 'note'
          "
          :block="shownBlock(block)"
          :note-presentation="presentation === 'admin' ? 'tinted' : notePresentation"
          :clamp="adminClamp(block)"
          :data-block="block.kind"
        />
        </template>
      </template>
        <!-- R2.1 overview: the quick keys close the overview card, inside it. -->
        <template v-if="(group.card || (overviewPart === 'quick' && group.key === 'all')) && places?.quick.length">
        <div class="flare-plugin-view__quick" :class="{ 'is-phone': phone }" data-place="quick">
          <FlareButton
            v-for="action in placed(places.quick)"
            :key="action.id"
            :variant="flarePluginActionRole(action) === 'primary' ? 'primary' : 'secondary'"
            :size="phone ? 'lg' : 'md'"
            :label="action.label"
            :loading="busyActionId === action.id"
            :disabled="locked || Boolean(action.disabledReason)"
            :aria-describedby="whyId(action)"
            :data-action-id="action.id"
            :data-action-variant="variantOf(action)"
            @click="run(action, {})"
          />
        </div>
        <p v-for="action in whyOf(placed(places.quick))" :id="whyId(action)" :key="`why-${action.id}`" class="flare-plugin-view__why" data-disabled-reason="true">{{ action.disabledReason }}</p>
        <p v-if="offlineCaption === 'quick'" class="flare-plugin-view__offline" data-offline-caption="true">{{ t("pluginView.availableOnline") }}</p>
        </template>
      </OverviewCard>
      </template>
      <section
        v-if="inlineFormAction"
        class="flare-plugin-view__inline-section"
        :class="{ 'has-form-heading': hasInlineFormHeading, 'is-form-column': rolesLayout }"
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
          ref="inlineForm"
          :file-states="fileStates"
          :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
          :location-states="locationStates"
          :onLocationAction="instance?.vnode.props?.onLocationAction ? forwardLocationAction : undefined"
          :key="`${inlineFormAction.id}/${inlineRevision}`"
          class="flare-plugin-view__inline-form"
          data-inline-action-form="true"
          :data-inline-action-id="inlineFormAction.id"
          embedded
          :inputs="inlineInputs"
          :validate-field="validateField"
          :select-presentation="actionsPlacement === 'rows' ? 'dropdown' : undefined"
          :values="inlineInitialValues"
          :require-change="formChangeActions?.includes(inlineFormAction.id)"
          :submit-label="formSubmitLabel?.(inlineFormAction.id) ?? inlineFormAction.label"
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
      <!-- R2.2–R2.3 page places: the task bar, the command row, then the list cards and the danger card last. -->
      <template v-if="places && places.archetype !== 'card' && overviewPart !== 'quick'">
        <div
          v-if="placed(places.bar).length || placed(places.barSecondary).length"
          class="flare-plugin-view__bar"
          :class="{ 'is-phone': phone }"
          data-place="bar"
        >
          <div v-if="phone && placed(places.barSecondary).length" class="flare-plugin-view__bar-quiet">
            <FlareButton
              v-for="action in placed(places.barSecondary)"
              :key="action.id"
              variant="quiet"
              appearance="text"
              :label="action.label"
              :loading="busyActionId === action.id"
            :disabled="locked || Boolean(action.disabledReason)"
            :aria-describedby="whyId(action)"
            :data-action-id="action.id"
            :data-action-variant="variantOf(action)"
            @click="run(action, {})"
            />
          </div>
          <FlareButton
            v-for="action in placed(places.bar)"
            :key="action.id"
            :variant="variantOf(action)"
            :size="phone ? 'lg' : 'md'"
            :block="phone"
            class="flare-plugin-view__bar-primary"
            :label="action.label"
            :loading="busyActionId === action.id"
            :disabled="locked || Boolean(action.disabledReason)"
            :aria-describedby="whyId(action)"
            :data-action-id="action.id"
            :data-action-variant="variantOf(action)"
            @click="run(action, {})"
          />
          <template v-if="!phone">
            <FlareButton
              v-for="action in placed(places.barSecondary)"
              :key="action.id"
              variant="secondary"
              class="flare-plugin-view__bar-primary"
              :label="action.label"
              :loading="busyActionId === action.id"
            :disabled="locked || Boolean(action.disabledReason)"
            :aria-describedby="whyId(action)"
            :data-action-id="action.id"
            :data-action-variant="variantOf(action)"
            @click="run(action, {})"
            />
          </template>
          <p v-for="action in whyOf([...placed(places.bar), ...placed(places.barSecondary)])" :id="whyId(action)" :key="`why-${action.id}`" class="flare-plugin-view__why" data-disabled-reason="true">{{ action.disabledReason }}</p>
          <p v-if="offlineCaption === 'bar'" class="flare-plugin-view__offline" data-offline-caption="true">{{ t("pluginView.availableOnline") }}</p>
        </div>
        <div v-if="placed(places.commands).length" class="flare-plugin-view__commands" data-place="commands">
          <FlareButton
            v-for="action in placed(places.commands)"
            :key="action.id"
            variant="secondary"
            :label="action.label"
            :loading="busyActionId === action.id"
            :disabled="locked || Boolean(action.disabledReason)"
            :aria-describedby="whyId(action)"
            :data-action-id="action.id"
            :data-action-variant="variantOf(action)"
            @click="run(action, {})"
          />
          <p v-for="action in whyOf(placed(places.commands))" :id="whyId(action)" :key="`why-${action.id}`" class="flare-plugin-view__why" data-disabled-reason="true">{{ action.disabledReason }}</p>
          <p v-if="offlineCaption === 'commands'" class="flare-plugin-view__offline" data-offline-caption="true">{{ t("pluginView.availableOnline") }}</p>
        </div>
        <section
          v-for="group in [...places.list.map((item) => ({ key: item.group ?? 'list', title: item.group === 'common' ? t('pluginView.groupCommon') : item.group === 'records' ? t('pluginView.groupRecords') : '', actions: placed(item.actions) })), { key: 'more', title: t('pluginView.moreActions'), actions: placed(places.more) }].filter((item) => item.actions.length)"
          :key="group.key"
          class="flare-plugin-view__list"
          :data-place="group.key === 'more' ? 'more' : 'list'"
          :data-group="group.key"
        >
          <h2 v-if="group.title" class="flare-plugin-view__list-title">{{ group.title }}</h2>
          <div class="flare-plugin-view__list-card" role="group" :aria-label="group.title || undefined">
            <FlareSettingsRow
              v-for="action in group.actions"
              :key="action.id"
              :item="{ key: action.id, label: action.label, icon: action.icon, kind: flarePluginActionRole(action) === 'destination' ? 'navigation' : 'action', detail: action.disabledReason, detailBelow: true, disabled: locked || Boolean(action.disabledReason) }"
              :loading="busyActionId === action.id"
              :data-action-id="action.id"
              :data-action-variant="variantOf(action)"
              :data-chevron="flarePluginActionRole(action) === 'destination' ? 'true' : undefined"
              @select="run(action, {})"
            />
          </div>
        </section>
        <div v-if="places.danger.length" class="flare-plugin-view__list-card is-danger" role="group" data-place="danger">
          <FlareSettingsRow
            v-for="action in places.danger"
            :key="action.id"
            :item="{ key: action.id, label: action.label, kind: 'action', danger: true, detail: action.disabledReason, detailBelow: true, disabled: locked || Boolean(action.disabledReason) }"
            :loading="busyActionId === action.id"
            :data-action-id="action.id"
            data-action-variant="danger"
            @select="run(action, {})"
          />
        </div>
      </template>
      <!-- R2.4 message card: primary solid first, three keys at most, the rest in the ⋯ menu. -->
      <footer v-if="places?.archetype === 'card' && places.footer.length" class="flare-plugin-view__footer is-card" data-place="footer">
        <div class="flare-plugin-view__actions">
          <FlareButton
            v-for="action in places.footer"
            :key="action.id"
            size="sm"
            :variant="variantOf(action)"
            :label="action.label"
            :loading="busyActionId === action.id"
            :disabled="locked || Boolean(action.disabledReason)"
            :aria-describedby="whyId(action)"
            :data-action-id="action.id"
            :data-action-variant="variantOf(action)"
            @click="run(action, {})"
          />
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
          <FlareIcon name="chevron-right" size="sm" aria-hidden="true" />
        </FlareButton>
        <p v-for="action in whyOf(places.footer)" :id="whyId(action)" :key="`why-${action.id}`" class="flare-plugin-view__why" data-disabled-reason="true">{{ action.disabledReason }}</p>
        <p v-if="offlineCaption === 'footer'" class="flare-plugin-view__offline" data-offline-caption="true">{{ t("pluginView.availableOnline") }}</p>
      </footer>
      <footer
        v-if="footerActions.length && !actionsInRows && !places && !result"
        class="flare-plugin-view__footer"
      >
        <div v-for="(group, index) in footerActionGroups" :key="index" class="flare-plugin-view__actions" :class="{ 'is-service-group': group.service }">
          <FlareButton
            v-for="action in group.actions"
            :key="action.id"
            :label="action.label"
            :variant="footerVariant(action)"
            size="sm"
            :appearance="!adminFlow && group.service ? 'text' : 'default'"
            :loading="busyActionId === action.id"
            :disabled="locked || Boolean(action.disabledReason)"
            :title="action.disabledReason"
            :data-action-id="action.id"
            @click="run(action, {})"
          >
            <span
              v-if="group.service"
              class="flare-plugin-view__service-label"
              >{{ action.label
              }}<FlareIcon name="chevron-right" size="sm" aria-hidden="true"
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
          <FlareIcon name="chevron-right" size="sm" aria-hidden="true" />
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
    <component
      :is="formPlacement === 'page' ? FlareDrawer : FlareBottomSheet"
      v-if="formAction"
      :open="Boolean(formAction)"
      :title="formAction?.label"
      :dismissible="!formBusy"
      v-bind="formPlacement === 'page' ? { titleHidden: true, showClose: false, contentPadding: 'none', ...(formSections?.(formAction.id)?.length ? { width: 'calc(var(--flare-size-component-form-column-width) + 4 * var(--flare-size-spacing-lg))' } : {}) } : { dialogWidth: 'var(--flare-size-component-sheet-dialog-width)' }"
      @close="closeForm"
    >
      <component :is="formPlacement === 'page' ? FlareScreen : 'div'" v-bind="formPlacement === 'page' ? { title: formAction.label, back: true, scroll: false, surface: 'surface' } : {}" @back="closeForm">
      <div :class="{ 'flare-plugin-view__page-form': formPlacement === 'page' }">
      <PluginSimpleBlock
        v-if="formRowContext"
        data-row-form-context="true"
        :block="formRowContext"
      />
      <FlarePluginForm
          ref="sheetForm"
          :file-states="fileStates"
          :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
          :location-states="locationStates"
          :onLocationAction="instance?.vnode.props?.onLocationAction ? forwardLocationAction : undefined"
        :inputs="formInputs"
        :sections="formSections?.(formAction.id)"
        :columns="formPlacement === 'page' ? 2 : 1"
        :layout="formPlacement === 'page' ? 'page' : 'content'"
        :autofocus="formPlacement === 'page'"
        :submit-label="formSubmitLabel?.(formAction.id) ?? formAction.label"
        :select-presentation="formSelectPresentation"
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
      </div>
      </component>
    </component>
  </section>
</template>

<style scoped>
.flare-plugin-view__page-form { display: flex; flex-direction: column; height: 100%; min-height: 0; }
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
/* R1 / §12.7: on a plugin page (roles layout) blocks sit 16 apart; sections 24 (PluginSectionBlock). */
.flare-plugin-view.has-actions-roles { gap: var(--flare-size-spacing-lg); }
.flare-plugin-view.is-admin-flow {
  --flare-plugin-body-size: var(--flare-size-font-size-md);
}
.flare-plugin-view.is-admin-flow [data-block="text"],
.flare-plugin-view.is-admin-flow [data-block="note"] {
  max-width: 72ch;
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
.flare-plugin-view__help {
  display: flex;
  justify-content: flex-end;
}
.flare-plugin-view__help-body {
  display: grid;
  gap: var(--flare-size-spacing-sm);
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
/* R5 / §12.6: icon 16, title, details 13 eight after the title, the more key (IconButton sm) four after the details. */
.flare-plugin-view__head {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
/* R5: the title takes the remaining width on one line; details and more stay at the trailing edge. */
.flare-plugin-view__head .flare-plugin-view__title {
  flex: 1 1 auto;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}
.flare-plugin-view__head .flare-plugin-view__detail + * { margin-inline-start: calc(var(--flare-size-spacing-xs) - var(--flare-size-spacing-sm)); }
.flare-plugin-view__more { flex: none; }
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
.flare-plugin-view__inline-section:first-child {
  margin-block-start: 0;
  padding-block-start: 0;
  border-block-start: 0;
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
.flare-plugin-view__actions.is-service-group {
  display: grid;
  width: 100%;
  gap: 0;
}
.flare-plugin-view.has-actions-list .flare-plugin-view__footer {
  gap: var(--flare-size-spacing-md);
}
.flare-plugin-view__actions.is-service-group > * {
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-md) 0;
  justify-content: flex-start;
  border-radius: 0;
  text-align: start;
}
.flare-plugin-view__actions.is-service-group > * + * {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-plugin-view__actions.is-service-group
  :deep(.flare-button__label) {
  width: 100%;
}
.flare-plugin-view__service-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  font-size: var(--flare-size-font-size-md);
}
.flare-plugin-view__service-label > .flare-icon {
  flex: none;
  color: var(--flare-color-text-tertiary);
}
.flare-plugin-view__detail {
  flex: none;
  margin-inline-start: auto;
  padding-inline: var(--flare-size-spacing-2xs);
  font-size: var(--flare-size-font-size-md);
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
/* ── R2 page places (actionLayout roles) ── */
.flare-plugin-view__quick,
.flare-plugin-view__commands,
.flare-plugin-view__bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-plugin-view__quick { margin-top: var(--flare-size-spacing-lg); }
/* R2.1 overview card: the hero/stats and the quick keys at its bottom; the hero gives up its own surface inside it.
   The container comes from a render function (no scope attribute), hence :deep. */
.flare-plugin-view :deep(.flare-plugin-view__overview) {
  display: grid;
  gap: var(--flare-size-spacing-lg);
  min-width: 0;
  padding: var(--flare-size-spacing-lg);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-secondary);
}
.flare-plugin-view :deep(.flare-plugin-view__overview .flare-plugin-hero) { padding: 0; background: transparent; }
.flare-plugin-view__overview .flare-plugin-view__quick { margin-top: 0; }
.flare-plugin-view__quick > *,
.flare-plugin-view__bar > .flare-plugin-view__bar-primary,
.flare-plugin-view__commands > .flare-button { min-width: var(--flare-size-component-action-min-width); }
.flare-plugin-view__quick.is-phone { flex-wrap: nowrap; }
.flare-plugin-view__quick.is-phone > * { flex: 1 1 0; min-width: 0; }
.flare-plugin-view__bar { margin-top: var(--flare-size-spacing-2xl); }
/* Phone: the primary is pinned over the safe area at the bottom of the page's scroller. */
.flare-plugin-view__bar.is-phone {
  position: sticky;
  bottom: 0;
  z-index: var(--flare-z-index-sticky);
  display: grid;
  gap: var(--flare-size-spacing-sm);
  margin-inline: calc(var(--flare-size-spacing-lg) * -1);
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) calc(var(--flare-size-spacing-md) + env(safe-area-inset-bottom, 0px));
  border-top: 1px solid var(--flare-color-border-secondary);
  background: var(--flare-color-bg-primary);
}
.flare-plugin-view__bar-quiet { display: flex; justify-content: center; gap: var(--flare-size-spacing-sm); }
.flare-plugin-view__bar-quiet .flare-button { color: var(--flare-color-text-secondary); }
.flare-plugin-view__commands { margin-top: var(--flare-size-spacing-lg); }
.flare-plugin-view__offline {
  flex-basis: 100%;
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-view__list { display: grid; gap: var(--flare-size-spacing-sm); margin-top: var(--flare-size-spacing-2xl); }
.flare-plugin-view__list-title {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-view__list-card {
  overflow: hidden;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
}
.flare-plugin-view__list-card.is-danger { margin-top: var(--flare-size-spacing-2xl); }
.flare-plugin-view__list-card.is-danger :deep(.flare-settings__label) { text-align: center; color: var(--flare-color-error-text); }
.flare-plugin-view__create { justify-self: start; }
.flare-plugin-view__inline-section.is-form-column { max-width: var(--flare-size-component-form-column-width); }
.flare-plugin-view__result { margin-bottom: var(--flare-size-spacing-lg); }
/* ── 6.1 status card ── */
.flare-plugin-view__status-card {
  --flare-status-tone: var(--flare-color-text-secondary);
  --flare-status-ink: var(--flare-color-text-secondary);
  display: grid;
  justify-items: start;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-lg);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
}
.flare-plugin-view__status-card.is-info { --flare-status-tone: var(--flare-color-info); --flare-status-ink: var(--flare-color-info-text); }
.flare-plugin-view__status-card.is-success { --flare-status-tone: var(--flare-color-success); --flare-status-ink: var(--flare-color-success-text); }
.flare-plugin-view__status-card.is-warning { --flare-status-tone: var(--flare-color-warning); --flare-status-ink: var(--flare-color-warning-text); }
.flare-plugin-view__status-card.is-danger { --flare-status-tone: var(--flare-color-error); --flare-status-ink: var(--flare-color-error-text); }
.flare-plugin-view__status-card > .flare-button { justify-self: stretch; }
/* 6.1: the tone circle (48) beside the title. */
.flare-plugin-view__status-head { display: flex; align-items: center; gap: var(--flare-size-spacing-md); min-width: 0; }
.flare-plugin-view__status-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-layout-control-height-lg);
  height: var(--flare-size-layout-control-height-lg);
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-status-ink);
  background: color-mix(in srgb, var(--flare-status-tone) calc(var(--flare-opacity-tint-weak) * 100%), transparent);
}
.flare-plugin-view__status-title { margin: 0; font-size: var(--flare-size-font-size-4xl); font-weight: var(--flare-size-font-weight-bold); }
.flare-plugin-view__status-description { margin: 0; font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-secondary); }
.flare-plugin-view__why {
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
}
</style>
