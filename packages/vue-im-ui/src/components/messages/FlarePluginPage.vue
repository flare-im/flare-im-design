<script setup lang="ts">
// A plugin's page contribution (a wallet, a ledger) as a full page (spec PluginPage, rules.page, docs/design/red-
// packet-v5-roles-and-wallet.md §3.2): the kit Screen with the heading and back key, the select filters of its rows
// as FilterTabs, the resolved view drawn by the same document renderer as the detail sheet (PluginView embedded, rows
// as a list), pull to refresh on touch and a refresh key on pointer devices, and load more while the view has a next
// page. Every action run on the page goes out as the page action request ({page, data?, row?, selection?,
// formValues?}). The host fetches: refresh, retry, loadMore and filter are requests; the kit calls nothing and draws
// nothing the view does not declare.
import { computed, getCurrentInstance, nextTick, onBeforeUnmount, onMounted, ref, useId, useSlots, watch } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareFilterTabs from "../general/FlareFilterTabs.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareSegmentedControl from "../general/FlareSegmentedControl.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareScreen from "../layout/FlareScreen.vue";
import FlareAccountView from "./account/FlareAccountView.vue";
import { flareAccountDocument } from "./account/account";
import FlarePluginView from "./FlarePluginView.vue";
import FlareRedPacketPage from "./FlareRedPacketPage.vue";
import { flareRedPacketPagePlan } from "../../shared/contracts/red-packet";
import FlarePluginUpgradeNotice from "./FlarePluginUpgradeNotice.vue";
import { usePluginPaging } from "./plugin/pluginPaging";
import { provideFlarePluginWarnScope } from "./plugin/warnScope";
import { provideFlarePluginFilterScope } from "./plugin/filterScope";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import { flareLayout } from "../../design-system/theme/layout-tokens";
import { flarePluginMayRefresh, type FlarePluginRefreshReason } from "../../shared/contracts/plugin-refresh";
import {
  FLARE_PLUGIN_RESULT_POLL_FOR_MS,
  FLARE_PLUGIN_RESULT_POLL_MS,
  FLARE_PLUGIN_SKELETON_DELAY_MS,
  flarePluginActionPlaces,
  flarePluginPageAppearanceOf,
  flarePluginPageInlineForm,
  flarePluginResultBlock,
  flarePluginShowsRefreshKey,
  flarePluginStatusCard,
} from "../../shared/contracts/plugin-experience";
import {
  flarePluginPageFilters,
  flarePluginPageFilterValues,
  flarePluginPagePayload,
  flarePluginPageState,
  flarePluginUnavailableKey,
  type FlarePluginActionPayload,
  type FlarePluginAction,
  type FlarePluginFormError,
  type FlarePluginFileState,
  type FlarePluginFileAction,
  type FlarePluginLocationAction,
  type FlarePluginProtectedMediaRead,
  type FlarePluginProtectedMediaState,
  type FlarePluginLocationState,
  type FlarePluginMember,
  type FlarePluginPageActionPayload,
  type FlarePluginPageFilter,
  type FlarePluginPageTab,
  type FlarePluginPageRef,
  type FlarePluginPageViewModel,
  type FlarePluginPageAppearance,
  type FlarePluginResolveUser,
  type FlarePluginImageSource,
  type FlarePluginQrRefresh,
  type FlarePluginUpgradeStatus,
} from "../../shared/contracts/plugin-ui";

const props = withDefaults(
  defineProps<{
    /** The page shown: every page action carries it. */
    page: FlarePluginPageRef;
    /** Absent: derived from the view's structure (R12, rules.accountDerivation); `document` turns that off. */
    appearance?: FlarePluginPageAppearance;
    /** The host is offline (R8): a warning banner, the view as last loaded, every action disabled. */
    offline?: boolean;
    /** Actions owned by trusted content; remaining actions keep the shared guarded renderer. */
    contentActionIds?: readonly string[];
    /** UI memory of the shown page (the host drops it on close or reopen): the red packet composer keeps its draft. */
    contentState?: Record<string, unknown>;
    /** Shared frame for the header and every loading/content state; null opts out. */
    contentMaxWidth?: number | null;
    /** Page title while there is no view (or the view has none); the view's title wins. */
    title?: string;
    providerName?: string;
    /** The page is on screen; absent means visible (a Boolean prop left out would otherwise read false). */
    visible?: boolean;
    encodePluginCode?: (pluginId: string, token: string) => Promise<string>;
    /** The resolved page view (pluginPage's result, with data); absent while the first load runs. */
    view?: FlarePluginPageViewModel;
    /** The applied filter values by input id (what the host passed to pluginPage); the filter tabs show them. */
    filters?: Record<string, unknown>;
    /** The first load runs: a spinner in place of the view. */
    loading?: boolean;
    /** Loading failed. Without a view: the text and a retry key; with one (a refresh failed): a banner above it. */
    error?: string;
    /** A refresh runs: the indicator stays until it clears. */
    refreshing?: boolean;
    /** The next page is loading: the load-more key spins and is disabled. */
    loadingMore?: boolean;
    /** Read-side completion/invalidation signal, independent from financial action settlement. */
    pagingToken?: number;
    /** Draw the back key (emits back); the platform back does the same. */
    back?: boolean;
    resolveUser?: FlarePluginResolveUser;
    /** The viewer's user id (the me tag in entries). */
    viewerId?: string;
    busyActionId?: string;
    /** Failure of an action run on the page (the view's error). */
    actionError?: string;
    formErrors?: FlarePluginFormError[];
    fileStates?: Record<string, FlarePluginFileState>;
    /** Location inputs: the host's fix, a running locate or a failure, by input id. */
    locationStates?: Record<string, FlarePluginLocationState>;
    /** Protected media on the page (an owner's own documents): the host's read address, by item id. */
    protectedMedia?: Record<string, FlarePluginProtectedMediaState>;
    members?: FlarePluginMember[];
    membersLoading?: boolean;
    membersRevision?: number;
    membersError?: string;
    /** The conversation's group size counting the viewer, for the red packet page's 「本群共 N 人」. */
    memberCount?: number;
    onMemberSearch?: (query: string) => void;
    onMembersRetry?: () => void;
    /** The host's settle signal for actions run on the page (PluginView settleToken). */
    settleToken?: number;
    /** Image blocks: what the host fetched for an asset path or private file id (PluginView resolveImage). */
    resolveImage?: (source: FlarePluginImageSource) => string | undefined | Promise<string | undefined>;
    /** An upgrade_required page: update.plugin_upgrade_status for its minBuild. */
    upgradeStatus?: FlarePluginUpgradeStatus | null;
    /** An upgrade_required page: opens the update flow; without it the page has no update key. */
    onUpdate?: () => void;
    upgradeBusy?: boolean;
  }>(),
  {
    visible: true, appearance: undefined, offline: false, contentMaxWidth: flareLayout.directoryContentMaxWidth, title: "", view: undefined, filters: () => ({}), loading: false, error: undefined, refreshing: false, loadingMore: false, pagingToken: 0, back: false,
    resolveUser: undefined, viewerId: undefined, busyActionId: undefined, actionError: undefined, formErrors: () => [],
    members: () => [], settleToken: 0, resolveImage: undefined, upgradeStatus: undefined, onUpdate: undefined, upgradeBusy: false,
  },
);
const emit = defineEmits<{
  back: [];
  fileAction: [event: FlarePluginFileAction];
  /** A location input's locate or clear key: the host runs the page's locationOnce action into the input. */
  locationAction: [event: FlarePluginLocationAction];
  /** A protected media read: the host runs it (the owner-scoped query) and fills `protectedMedia`. */
  protectedMediaRead: [read: FlarePluginProtectedMediaRead];
  /**
   * The host fetches the page again (silently) and passes back the view: pull, key (the header key or a retry
   * banner), timer (refreshMs, a pending result) or action (an action it ran settled cleanly, R4).
   */
  refresh: [reason: FlarePluginRefreshReason];
  /** The result view's done key (R7): the host pops back to the page that started the flow and refreshes it, else closes. */
  done: [];
  surfaceHints: [hints: { secure: boolean; maxBrightness: boolean }];
  /** The first load failed and the reader asked again. */
  retry: [];
  /** The next page after `cursor` (view.nextCursor); the host passes back the merged view. */
  loadMore: [cursor: string];
  /** A filter tab was chosen: the host's filters updated; the host reads the first page with them. */
  filter: [values: Record<string, unknown>];
  /** An action run on the page, as the page action request (invokePageAction). */
  action: [actionId: string, payload: FlarePluginPageActionPayload];
  /** An expired QR code on the page asks for a fresh one (PluginView qrRefresh). */
  qrRefresh: [request: FlarePluginQrRefresh];
  /**
   * A tab other than the shown page was chosen (rules.pageTabs): the host replaces the shown page on its stack with
   * `page` (same plugin, arguments and conversation; no new back step) and reads it.
   */
  tab: [page: string];
}>();

const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const platform = useFlarePlatformSafe();
const automatic = ref(false);
const interacting = ref(false);
const lastRefreshMs = ref<number>();
const pageVisible = ref(typeof document === "undefined" || !document.hidden);
let refreshTimer: ReturnType<typeof setInterval> | undefined;
function visibility() { pageVisible.value = !document.hidden; }
watch(() => `${props.page.pluginId}/${props.page.page}`, () => { lastRefreshMs.value = undefined; automatic.value = false; });
watch(() => props.view?.refreshMs, value => { if (typeof value === "number" && value >= 3000 && value <= 60000) lastRefreshMs.value = value; }, { immediate: true });
watch(lastRefreshMs, value => {
  clearInterval(refreshTimer);
  if (value) refreshTimer = setInterval(() => {
    if (!flarePluginMayRefresh({ visible: props.visible !== false, foreground: pageVisible.value, loading: props.loading, refreshing: props.refreshing, busy: props.loadingMore || Boolean(props.busyActionId), interaction: interacting.value })) return;
    automatic.value = true; emit("refresh", "timer");
  }, value);
}, { immediate: true });
// R7: a pending result reads itself every 3 s for at most 60 s, and stops at any other state.
let pollTimer: ReturnType<typeof setInterval> | undefined;
let pollFrom: { key: string; at: number } | undefined;
const resultPending = computed(() => {
  const result = props.view?.available ? flarePluginResultBlock(props.view) : undefined;
  return Boolean(result && !result.unmapped && result.state === "pending");
});
watch(() => [resultPending.value, `${props.page.pluginId}/${props.page.page}`] as const, ([pending, key]) => {
  clearInterval(pollTimer);
  if (!pending) { pollFrom = undefined; return; }
  if (pollFrom?.key !== key) pollFrom = { key, at: Date.now() };
  const started = pollFrom.at;
  pollTimer = setInterval(() => {
    if (Date.now() - started >= FLARE_PLUGIN_RESULT_POLL_FOR_MS) { clearInterval(pollTimer); return; }
    if (!flarePluginMayRefresh({ visible: props.visible !== false, foreground: pageVisible.value, loading: props.loading, refreshing: props.refreshing, busy: props.loadingMore || Boolean(props.busyActionId), interaction: interacting.value })) return;
    automatic.value = true; emit("refresh", "timer");
  }, FLARE_PLUGIN_RESULT_POLL_MS);
}, { immediate: true });
watch(() => props.refreshing, (value, previous) => { if (previous && !value) automatic.value = false; });
watch(() => [props.view, props.visible, pageVisible.value] as const, () => {
  const qr = props.visible !== false && pageVisible.value && props.view?.available && props.view.presentation?.renderer === "flare.qr";
  emit("surfaceHints", { secure: Boolean(qr && typeof props.view?.presentation?.props.ttlMs === "number"), maxBrightness: Boolean(qr) });
}, { immediate: true });
onMounted(() => document.addEventListener("visibilitychange", visibility));
onBeforeUnmount(() => { clearInterval(refreshTimer); clearInterval(pollTimer); clearTimeout(skeletonTimer); document.removeEventListener("visibilitychange", visibility); emit("surfaceHints", { secure: false, maxBrightness: false }); });
const visibleRefreshing = computed(() => props.refreshing && !automatic.value);
const encodeQr = computed(() => props.encodePluginCode ? (token: string) => props.encodePluginCode!(props.page.pluginId, token) : undefined);
const heading = computed(() => props.view?.title || props.title);
// R12: the account layout follows the view's structure unless the host names one (never by plugin id).
const appearance = computed(() => flarePluginPageAppearanceOf(props.view, props.appearance));
// The account appearance composes vocabulary-2 wallet heads and rows through the Kit account grid. Other block
// documents keep their declared hierarchy.
const accountView = computed(() => appearance.value === "account" && props.view ? flareAccountDocument(props.view) : props.view);
const isAccount = computed(() => {
  const presentation = accountView.value?.presentation;
  // Payment confirmation and QR projections keep their dedicated renderer,
  // including the guarded native payment boundary.
  return appearance.value === "account" && (
    presentation?.renderer === "account"
    || (!presentation && Boolean(props.view?.fields.length)
      && props.view?.blocks?.some(block => block.kind === "rows"))
  );
});
const emptyDocument = computed(() => Boolean(props.view && !props.view.fields.length && !props.view.blocks?.length && !props.view.actions.length && !props.view.presentation));
// A page that declares only one editable form (block-bound inputs aside, R6.1) is already its editor: no blank page
// with a button that opens another editor of the same name. Confirmation/password flows keep their sheet.
const inlineFormActionId = computed(() => props.view?.available ? flarePluginPageInlineForm(props.view) : undefined);
// R2.3 records: the page's first primary is a key in the header; the view's runner runs it.
const pluginView = ref<{ runAction: (id: string) => void } | null>(null);
const headerActions = computed(() => {
  const view = props.view;
  if (!view?.available || isAccount.value || instance?.vnode.props?.onAction === undefined || flarePluginStatusCard(view) || flarePluginResultBlock(view)) return [];
  return flarePluginActionPlaces(view, { embedded: true, inlineFormActionId: inlineFormActionId.value }).header;
});
const headerLocked = computed(() => Boolean(props.busyActionId) || props.offline || props.refreshing || props.loadingMore);
const upgradeRequired = computed(() => props.view?.unavailableReason === "upgrade_required");
const state = computed(() => flarePluginPageState(props.view, props.loading, props.error));
// An unavailable page (spec rules.page) says why; only an unreachable catalog is worth asking again.
const unavailableText = computed(() => {
  const reason = props.view?.unavailableReason;
  return reason ? t(flarePluginUnavailableKey(reason)) : t("pluginView.empty");
});
const unavailableRetry = computed(() => props.view?.unavailableReason === "catalog_unreachable");
// R1: the refresh key and pull only on a data page (rules.refreshKey).
const canRefresh = computed(() => Boolean(instance?.vnode.props?.onRefresh) && state.value === "loaded"
  && Boolean(props.view && flarePluginShowsRefreshKey(props.view, inlineFormActionId.value)));
const phone = computed(() => platform.capabilities.value.bottomSheet);
const headerWhy = useId();
// R8: the first load draws nothing for 300 ms, then the skeleton.
const skeletonShown = ref(false);
let skeletonTimer: ReturnType<typeof setTimeout> | undefined;
watch(() => state.value === "loading", (loading) => {
  clearTimeout(skeletonTimer);
  skeletonShown.value = false;
  if (loading) skeletonTimer = setTimeout(() => { skeletonShown.value = true; }, FLARE_PLUGIN_SKELETON_DELAY_MS);
}, { immediate: true });
// R8: an action failure is a dismissible banner at the top; a new failure shows again.
const dismissedError = ref<string>();
watch(() => props.actionError, () => { dismissedError.value = undefined; });
// Pointer devices get a refresh key in the header; touch pulls the page down.
const coarse = computed(() => platform.capabilities.value.pointer === "coarse");

const { nextCursor, pageBusy, loadMore } = usePluginPaging({
  view: () => props.view,
  loadingMore: () => props.loadingMore,
  settleToken: () => props.settleToken,
  actionError: () => props.actionError,
  pageError: () => props.error,
  pagingToken: () => props.pagingToken,
  refreshing: () => props.refreshing,
  request: (cursor) => emit("loadMore", cursor),
});

// ── pull to refresh ──────────────────────────────────────────────────────
const PULL_THRESHOLD = 64;
const PULL_MAX = 96;
const scroller = ref<HTMLElement | null>(null);
// One host reuses this page for its navigation stack. A fresh destination starts
// at its heading; returning restores its list position and the action that opened it.
const pageKey = computed(() => `${props.page.pluginId}/${props.page.page}`);
// R3: the blocks' development warnings name this plugin and page.
provideFlarePluginWarnScope(() => pageKey.value);
// §5.8: after the reader paged, the list's end says so; a new page starts over.
const paged = ref(false);
watch(pageKey, () => { paged.value = false; });
function more(): void {
  paged.value = true;
  loadMore();
}
const positions = new Map<string, { top: number; action?: string }>();
let pendingPosition: string | undefined;
watch(pageKey, (next, previous) => {
  const node = scroller.value;
  if (node) {
    const focused = document.activeElement;
    positions.set(previous, { top: node.scrollTop, action: focused instanceof Element && node.contains(focused) ? focused.closest('[data-action-id]')?.getAttribute('data-action-id') ?? undefined : undefined });
    if (positions.size > 64) positions.delete(positions.keys().next().value!);
  }
  pendingPosition = next;
});
watch([pageKey, () => props.loading, () => props.view], async () => {
  const key = pendingPosition;
  if (!key || props.loading) return;
  await nextTick();
  if (key !== pendingPosition || key !== pageKey.value || !scroller.value) return;
  const position = positions.get(key);
  const action = position?.action && [...scroller.value.querySelectorAll<HTMLElement>('[data-action-id]')].find(node => node.dataset.actionId === position.action);
  (action || scroller.value).focus({ preventScroll: true });
  scroller.value.scrollTop = position?.top ?? 0;
  pendingPosition = undefined;
}, { flush: 'post' });
const pull = ref(0);
let startY: number | null = null;
const armed = computed(() => pull.value >= PULL_THRESHOLD);
const indicatorText = computed(() => {
  return armed.value ? t("pluginView.releaseToRefresh") : t("pluginView.pullToRefresh");
});
function onTouchStart(event: TouchEvent): void {
  if (!canRefresh.value || props.refreshing || (scroller.value?.scrollTop ?? 0) > 0) return;
  startY = event.touches[0]?.clientY ?? null;
}
function onTouchMove(event: TouchEvent): void {
  if (startY === null) return;
  const dy = (event.touches[0]?.clientY ?? startY) - startY;
  if (dy <= 0) {
    pull.value = 0;
    return;
  }
  // Resist the finger: half its travel, up to the cap.
  pull.value = Math.min(PULL_MAX, dy / 2);
  if (event.cancelable) event.preventDefault();
}
function onTouchEnd(): void {
  if (startY === null) return;
  startY = null;
  const fire = armed.value;
  pull.value = 0;
  if (fire) emit("refresh", "pull");
}
function refresh(): void {
  if (!props.refreshing) emit("refresh", "key");
}
// R4: an action this page sent that settles cleanly (no error, no form errors) on this page, while it is visible and
// loaded, reads the page again once. A cancelled confirm or form never sends, so it never settles.
let sentFrom: string | undefined;
function runAction(actionId: string, payload: FlarePluginActionPayload): void {
  sentFrom = pageKey.value;
  emit("action", actionId, flarePluginPagePayload(props.page, props.view, payload));
}
watch(() => props.settleToken, (now, before) => {
  const from = sentFrom;
  if (now === before || from === undefined) return;
  sentFrom = undefined;
  if (props.actionError || props.formErrors.length || from !== pageKey.value || props.visible === false || props.loading || !props.view?.available) return;
  emit("refresh", "action");
});
// The compiled-in red packet pages (redPacket.compose / redPacket.detail, §11) take the content place when the view
// maps onto them; otherwise the plain document draws. Host content wins.
const slots = useSlots();
const packetPlan = computed(() => (slots.content || !props.view ? undefined : flareRedPacketPagePlan(props.view)));
const hasContent = computed(() => Boolean(slots.content || packetPlan.value));
// A red packet page that does not map (an unconfirmed original command, no send key) reads as its plain document:
// the generic view must not draw the review over its warning and recovery action.
const RED_PACKET_PAGES = new Set(["redPacket.compose", "redPacket.detail", "redPacket.review"]);
const documentView = computed(() => props.view && RED_PACKET_PAGES.has(props.view.presentation?.renderer ?? "")
  ? { ...props.view, presentation: undefined } : props.view);
function contentOwns(action: FlarePluginAction): boolean {
  return Boolean((props.contentActionIds ?? packetPlan.value?.ownedActionIds)?.includes(action.id) && !action.confirm && action.target?.kind !== 'native'
    && !action.form?.some(id => props.view?.inputs?.find(input => input.id === id)?.kind === 'password'));
}
const contentActionsView = computed<FlarePluginPageViewModel | undefined>(() => props.view && ({...props.view,
  fields: [], blocks: [], presentation: undefined,
  actions: props.view.actions.filter(action => !contentOwns(action)),
  menuActions: props.view.menuActions?.filter(action => !contentOwns(action)),
}));
function contentAction(actionId: string, payload: FlarePluginActionPayload = {}): void {
  const action = props.view?.actions.find(action => action.id === actionId);
  if (!instance?.vnode.props?.onAction || !props.view?.available || props.view.unavailableReason === 'unbound_copy' || props.busyActionId || props.refreshing || props.loadingMore
    || props.offline || !action || !contentOwns(action)) return;
  runAction(actionId, {
    ...(payload.formValues ? {formValues: payload.formValues} : {}),
    ...(payload.selection ? {selection: payload.selection} : {}),
  });
}

// ── tabs (spec rules.pageTabs) ───────────────────────────────────────────
// Sibling pages as a segmented control. Until the chosen page has a view, the tabs last drawn stay, with it selected.
const lastTabs = ref<ReadonlyArray<FlarePluginPageTab>>([]);
const pageTabsOf = (view: FlarePluginPageViewModel | undefined) => (view?.available && (view.tabs?.length ?? 0) >= 2 ? view.tabs! : []);
watch(() => props.view, (view) => { if (pageTabsOf(view).length) lastTabs.value = pageTabsOf(view); }, { immediate: true });
const tabs = computed<ReadonlyArray<FlarePluginPageTab>>(() => {
  if (props.view) return pageTabsOf(props.view);
  return lastTabs.value.some((tab) => tab.page === props.page.page)
    ? lastTabs.value.map((tab) => ({ ...tab, selected: tab.page === props.page.page })) : [];
});
const tabIndex = computed(() => tabs.value.findIndex((tab) => tab.selected));
function chooseTab(index: number): void {
  const tab = tabs.value[index];
  if (tab && !tab.selected) emit("tab", tab.page);
}

// ── filters (spec rules.pageFilters) ─────────────────────────────────────
const filterRows = computed<FlarePluginPageFilter[]>(() => (props.view?.available ? flarePluginPageFilters(props.view, props.filters, t("pluginView.all")) : []));
const filtersBusy = computed(() => visibleRefreshing.value || props.loadingMore);
// FilterTabs keys its options by a string: all is the empty key (choice values are never empty).
const tabsOf = (filter: FlarePluginPageFilter) => filter.tabs.map((tab) => ({ value: tab.value ?? "", label: tab.label }));
function choose(filter: FlarePluginPageFilter, key: string): void {
  if (filtersBusy.value) return;
  const value = key === "" ? null : key;
  if (value === filter.selected) return;
  emit("filter", flarePluginPageFilterValues(props.filters, filter.input.id, value));
}
// §5.8: an empty record list under a filter says so and offers to clear every filter back to all.
provideFlarePluginFilterScope({
  active: () => filterRows.value.some((filter) => filter.selected !== null && filter.selected !== undefined),
  clear: () => {
    if (filtersBusy.value) return;
    let values: Record<string, unknown> = { ...(props.filters ?? {}) };
    for (const filter of filterRows.value) values = flarePluginPageFilterValues(values, filter.input.id, null);
    emit("filter", values);
  },
});
function forwardFileAction(event: FlarePluginFileAction): void { emit("fileAction", event); }
function forwardLocationAction(event: FlarePluginLocationAction): void { emit("locationAction", event); }
function forwardProtectedMediaRead(read: FlarePluginProtectedMediaRead): void { emit("protectedMediaRead", read); }
function forwardQrRefresh(request: FlarePluginQrRefresh): void { emit("qrRefresh", request); }
</script>

<template>
  <FlareScreen
    class="flare-plugin-page"
    :title="heading"
    :class="{ 'is-account': isAccount, 'is-phone': phone }"
    :surface="isAccount ? 'surface' : 'canvas'"
    :back="back"
    :scroll="false"
    :content-max-width="contentMaxWidth"
    :aria-label="heading || undefined"
    :data-state="state"
    @back="emit('back')"
  >
    <template v-if="(canRefresh && !coarse) || (headerActions.length && !hasContent)" #actions>
      <FlareButton
        v-for="action in hasContent ? [] : headerActions"
        :key="action.id"
        size="sm"
        :variant="phone ? 'quiet' : 'secondary'"
        :appearance="phone ? 'text' : 'default'"
        :label="action.label"
        :loading="busyActionId === action.id"
        :disabled="headerLocked || Boolean(action.disabledReason)"
        :title="action.disabledReason"
        :aria-describedby="action.disabledReason ? `${headerWhy}-${action.id}` : undefined"
        :data-action-id="action.id"
        data-action-variant="primary"
        @click="pluginView?.runAction(action.id)"
      />
      <FlareIconButton
        v-if="canRefresh && !coarse"
        :icon="flareIcons.refresh"
        :ariaLabel="t('pluginView.refresh')"
        :disabled="refreshing"
        data-page-refresh="true"
        @click="refresh"
      />
    </template>
    <div
      ref="scroller"
      class="flare-plugin-page__scroll"
      tabindex="-1"
      :aria-label="heading || undefined"
      :aria-busy="state === 'loading' || visibleRefreshing"
      @touchstart="onTouchStart"
      @touchmove="onTouchMove"
      @touchend="onTouchEnd"
      @touchcancel="onTouchEnd"
    >
      <!-- R1: a refresh keeps the body and runs a thin bar under the header. -->
      <div v-if="visibleRefreshing" class="flare-plugin-page__progress" role="progressbar" :aria-label="t('pluginView.refreshing')" data-page-progress="true" />
      <div
        v-if="canRefresh && pull > 0 && !visibleRefreshing"
        class="flare-plugin-page__pull"
        :class="{ 'is-armed': armed }"
        :style="{ height: `${pull}px` }"
        role="status"
        data-page-pull="true"
      >{{ indicatorText }}</div>
      <FlareSegmentedControl
        v-if="tabs.length"
        class="flare-plugin-page__tabs"
        :options="tabs.map((tab) => tab.label)"
        :model-value="tabIndex"
        :aria-label="heading || undefined"
        data-page-tabs="true"
        @update:model-value="chooseTab"
      />
      <!-- R8: nothing for 300 ms, then the records skeleton (the archetype is unknown before a view). -->
      <div v-if="state === 'loading'" class="flare-plugin-page__loading" role="status" :aria-label="t('pluginView.loading')" data-page-loading="true">
        <FlareSkeleton v-if="skeletonShown" variant="list" :rows="6" data-page-skeleton="records" />
      </div>
      <FlareEmptyState
        v-else-if="state === 'error'"
        class="flare-plugin-page__error"
        icon="error"
        :title="t('pluginView.loadFailedTitle')"
        :description="error"
        data-page-error="true"
      >
        <template #actions>
          <FlareButton size="sm" variant="secondary" :label="t('pluginView.retry')" data-page-retry="true" @click="emit('retry')" />
        </template>
      </FlareEmptyState>
      <FlarePluginUpgradeNotice
        v-else-if="state === 'unavailable' && upgradeRequired"
        variant="page"
        :title="view?.title"
        :status="upgradeStatus"
        :on-update="onUpdate"
        :busy="upgradeBusy"
      />
      <FlareEmptyState v-else-if="state === 'unavailable'" :title="unavailableText" icon="info" data-page-unavailable="true">
        <template v-if="unavailableRetry" #actions>
          <FlareButton size="sm" variant="secondary" :label="t('pluginView.retry')" data-page-retry="true" @click="emit('retry')" />
        </template>
      </FlareEmptyState>
      <template v-else-if="view">
        <FlareStatusBanner v-if="offline" class="flare-plugin-page__banner" :text="t('pluginView.offline')" tone="warning" data-page-offline="true" />
        <!-- The account view draws the action error itself; the page does not repeat it above. -->
        <FlareStatusBanner
          v-if="actionError && dismissedError !== actionError && !packetPlan && !(isAccount && !hasContent)"
          class="flare-plugin-page__banner"
          :text="actionError"
          tone="danger"
          dismissible
          data-page-action-error="true"
          @dismiss="dismissedError = actionError"
        />
        <FlareStatusBanner v-if="error" class="flare-plugin-page__banner" :text="error" tone="danger" :action-text="canRefresh && !refreshing ? t('pluginView.retry') : undefined" @action="refresh" />
        <!-- R2.5 / R8: the header key's reason, or that it waits for the network, as a caption under the header. -->
        <template v-if="!hasContent">
          <p v-for="action in headerActions.filter((item) => item.disabledReason)" :id="`${headerWhy}-${action.id}`" :key="`why-${action.id}`" class="flare-plugin-page__why" data-disabled-reason="true">{{ action.disabledReason }}</p>
          <p v-if="offline && headerActions.length" class="flare-plugin-page__why" data-offline-caption="true">{{ t("pluginView.availableOnline") }}</p>
        </template>
        <div v-if="filterRows.length" class="flare-plugin-page__filters" data-page-filters="true">
          <div v-for="filter in filterRows" :key="filter.input.id" class="flare-plugin-page__filter-row">
          <span class="flare-plugin-page__filter-label">{{ filter.input.label }}</span>
          <FlareFilterTabs
            :options="tabsOf(filter)"
            :model-value="filter.selected ?? ''"
            :aria-label="filter.input.label"
            :enabled="!filtersBusy"
            size="sm"
            :data-page-filter="filter.input.id"
            @update:model-value="() => undefined"
            @change="(key: string) => choose(filter, key)"
          />
          </div>
        </div>
        <FlareStatusBanner v-if="providerName" :text="t('scan.providedBy', { name: providerName })" />
        <div class="flare-plugin-page__body" :class="{ 'has-content': hasContent }">
          <slot v-if="$slots.content" name="content" v-bind="{
            page, view, busyActionId, refreshing, error: actionError, formErrors, settleToken,
            members, membersLoading, membersRevision, membersError, resolveUser, viewerId,
            onMemberSearch, onMembersRetry, onAction: contentAction, onRefresh: refresh, onBack: () => emit('back'),
          }" />
          <FlareRedPacketPage
            v-else-if="packetPlan" :view="view" :busy-action-id="busyActionId" :refreshing="refreshing"
            :error="actionError" :form-errors="formErrors" :settle-token="settleToken" :content-state="contentState"
            :members="members" :member-count="memberCount" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError"
            :resolve-user="resolveUser" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry"
            :on-action="contentAction" :on-refresh="instance?.vnode.props?.onRefresh ? refresh : undefined" :on-back="() => emit('back')"
          />
          <FlarePluginView
            v-if="hasContent && contentActionsView && (contentActionsView.actions.length || contentActionsView.menuActions?.length)"
            :view="contentActionsView" embedded action-layout="list" form-presentation="page" :show-error="false" :offline="offline"
            :location-states="locationStates" :onLocationAction="instance?.vnode.props?.onLocationAction ? forwardLocationAction : undefined"
            :protected-media="protectedMedia" :onProtectedMediaRead="instance?.vnode.props?.onProtectedMediaRead ? forwardProtectedMediaRead : undefined"
            :resolve-user="resolveUser" :viewer-id="viewerId" :resolve-image="resolveImage"
            :busy-action-id="busyActionId" :error="actionError" :form-errors="formErrors" :settle-token="settleToken"
            :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
            :members="members" :members-loading="membersLoading" :members-error="membersError" :members-revision="membersRevision"
            :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry"
            :onAction="instance?.vnode.props?.onAction ? runAction : undefined"
          />
          <FlareEmptyState v-if="emptyDocument && !hasContent" :title="t('pluginView.empty')" icon="info" data-page-empty="true" />
          <FlareAccountView
            :file-states="fileStates"
            :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
          v-else-if="!hasContent && isAccount"
            style="max-width: none"
            :offline="offline"
            :view="accountView ?? view" :resolve-user="resolveUser" :viewer-id="viewerId"
            :busy-action-id="busyActionId" :error="actionError" :form-errors="formErrors"
            :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry" :settle-token="settleToken" :onAction="instance?.vnode.props?.onAction ? runAction : undefined"
          />
          <FlarePluginView
            ref="pluginView"
            :file-states="fileStates"
            :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined"
            :location-states="locationStates"
            :protected-media="protectedMedia"
            :onProtectedMediaRead="instance?.vnode.props?.onProtectedMediaRead ? forwardProtectedMediaRead : undefined"
            :onLocationAction="instance?.vnode.props?.onLocationAction ? forwardLocationAction : undefined"
            v-else-if="!hasContent"
            :view="documentView!"
            :encode-qr="encodeQr"
            @interaction-change="value => interacting = value"
            embedded
            rows-layout="list"
            action-layout="roles"
            :offline="offline"
            :show-error="false"
            form-presentation="page"
            :inline-form-action-id="inlineFormActionId"
            :resolve-user="resolveUser"
            :viewer-id="viewerId"
            :busy-action-id="busyActionId"
            :error="actionError"
            :form-errors="formErrors"
            :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry"
            :settle-token="settleToken"
            :resolve-image="resolveImage"
            :onAction="instance?.vnode.props?.onAction ? runAction : undefined"
            :onQrRefresh="instance?.vnode.props?.onQrRefresh ? forwardQrRefresh : undefined"
            @done="emit('done')"
          />
        </div>
        <!-- §5.8: load more is a full-width secondary key; once paged to the end, the list says so. -->
        <div v-if="nextCursor" class="flare-plugin-page__more">
          <FlareButton
            variant="secondary"
            block
            :label="t('pluginView.loadMore')"
            :loading="pageBusy"
            :disabled="pageBusy"
            data-page-load-more="true"
            @click="more"
          />
        </div>
        <p v-else-if="paged" class="flare-plugin-page__end" data-page-end="true">{{ t("pluginView.endOfList") }}</p>
      </template>
    </div>
  </FlareScreen>
</template>

<style scoped>
.flare-plugin-page__scroll {
  height: 100%;
  min-height: 0;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  overscroll-behavior-y: contain;
  /* R1: PC gutters 24, phone 16. */
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-2xl) calc(var(--flare-size-spacing-xl) + env(safe-area-inset-bottom, 0px));
  box-sizing: border-box;
}
.flare-plugin-page.is-phone .flare-plugin-page__scroll { padding-inline: var(--flare-size-spacing-lg); }
.flare-plugin-page__progress {
  position: sticky;
  top: calc(var(--flare-size-spacing-md) * -1);
  z-index: var(--flare-z-index-sticky);
  height: 2px;
  margin: calc(var(--flare-size-spacing-md) * -1) 0 var(--flare-size-spacing-md);
  overflow: hidden;
  /* §12.8: reduced motion keeps a still half bar; otherwise it loops every 1.2 s. */
  background: linear-gradient(90deg, var(--flare-color-primary) 0 50%, transparent 50%);
}
@media (prefers-reduced-motion: no-preference) {
  .flare-plugin-page__progress { background-size: 200% 100%; animation: flare-plugin-page-progress var(--flare-transition-refresh-loop) infinite; }
}
@keyframes flare-plugin-page-progress { from { background-position: 100% 0; } to { background-position: -100% 0; } }
.flare-plugin-page__loading { min-height: var(--flare-size-layout-touch-target); }
.flare-plugin-page__pull {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  overflow: hidden;
  padding-bottom: var(--flare-size-spacing-xs);
  box-sizing: border-box;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
.flare-plugin-page__pull.is-armed,
.flare-plugin-page__pull.is-refreshing { color: var(--flare-color-text-secondary); }
/* §5.8: a stuck day heading meets the scroller's top edge, as the refresh bar does; at top 0 it stopped under the
   scroller's top padding and the records scrolled visibly through that strip above it. */
.flare-plugin-page__scroll :deep(.flare-plugin-rows__day) { top: calc(var(--flare-size-spacing-md) * -1); }
/* R1: the body sits on the page itself (gutters 24 / 16 from the scroller), no card around it. */
.flare-plugin-page__body { min-width: 0; }
.flare-plugin-page__banner { margin-bottom: var(--flare-size-spacing-md); }
/* The tab rows, one per select filter; they wait (FilterTabs enabled false) while the page refreshes or loads more.
   The top padding keeps the first row's hit areas, which reach past its pills, inside the scroll area. */
.flare-plugin-page__filters {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  margin: 0 0 var(--flare-size-spacing-md);
  padding-top: var(--flare-size-spacing-sm);
}
.flare-plugin-page__more { padding-top: var(--flare-size-spacing-lg); }
.flare-plugin-page__end { margin: 0; padding-top: var(--flare-size-spacing-lg); text-align: center; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.flare-plugin-page__why { margin: 0 0 var(--flare-size-spacing-md); font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
/* rules.pageTabs: the full content width, above banners, filters and blocks. */
.flare-plugin-page__tabs { display: flex; width: 100%; box-sizing: border-box; margin-bottom: var(--flare-size-spacing-lg); }
.flare-plugin-page__filter-row { display: grid; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-plugin-page__filter-label { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
@media (prefers-reduced-motion: no-preference) {
  .flare-plugin-page__pull:not(.is-refreshing) { transition: height var(--flare-transition-fast); }
}
</style>
