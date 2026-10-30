<script setup lang="ts">
// A plugin's page contribution (a wallet, a ledger) as a full page (spec PluginPage, rules.page, docs/design/red-
// packet-v5-roles-and-wallet.md §3.2): the kit Screen with the heading and back key, the select filters of its rows
// as FilterTabs, the resolved view drawn by the same document renderer as the detail sheet (PluginView embedded, rows
// as a list), pull to refresh on touch and a refresh key on pointer devices, and load more while the view has a next
// page. Every action run on the page goes out as the page action request ({page, data?, row?, selection?,
// formValues?}). The host fetches: refresh, retry, loadMore and filter are requests; the kit calls nothing and draws
// nothing the view does not declare.
import { computed, getCurrentInstance, ref } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareFilterTabs from "../general/FlareFilterTabs.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareScreen from "../layout/FlareScreen.vue";
import FlareAccountView from "./account/FlareAccountView.vue";
import FlarePluginView from "./FlarePluginView.vue";
import { usePluginPaging } from "./plugin/pluginPaging";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import {
  flarePluginPageFilters,
  flarePluginPageFilterValues,
  flarePluginPagePayload,
  flarePluginPageState,
  flarePluginUnavailableKey,
  type FlarePluginActionPayload,
  type FlarePluginFormError,
  type FlarePluginMember,
  type FlarePluginPageActionPayload,
  type FlarePluginPageFilter,
  type FlarePluginPageRef,
  type FlarePluginPageViewModel,
  type FlarePluginPageAppearance,
  type FlarePluginResolveUser,
} from "../../shared/contracts/plugin-ui";

const props = withDefaults(
  defineProps<{
    /** The page shown: every page action carries it. */
    page: FlarePluginPageRef;
    appearance?: FlarePluginPageAppearance;
    /** Page title while there is no view (or the view has none); the view's title wins. */
    title?: string;
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
    /** Draw the back key (emits back); the platform back does the same. */
    back?: boolean;
    resolveUser?: FlarePluginResolveUser;
    /** The viewer's user id (the me tag in entries). */
    viewerId?: string;
    busyActionId?: string;
    /** Failure of an action run on the page (the view's error). */
    actionError?: string;
    formErrors?: FlarePluginFormError[];
    members?: FlarePluginMember[];
    /** The host's settle signal for actions run on the page (PluginView settleToken). */
    settleToken?: number;
  }>(),
  {
    appearance: "document", title: "", view: undefined, filters: () => ({}), loading: false, error: undefined, refreshing: false, loadingMore: false, back: false,
    resolveUser: undefined, viewerId: undefined, busyActionId: undefined, actionError: undefined, formErrors: () => [],
    members: () => [], settleToken: 0,
  },
);
const emit = defineEmits<{
  back: [];
  /** Pull to refresh or the refresh key: the host fetches the page again and passes back the view. */
  refresh: [];
  /** The first load failed and the reader asked again. */
  retry: [];
  /** The next page after `cursor` (view.nextCursor); the host passes back the merged view. */
  loadMore: [cursor: string];
  /** A filter tab was chosen: the host's filters updated; the host reads the first page with them. */
  filter: [values: Record<string, unknown>];
  /** An action run on the page, as the page action request (invokePageAction). */
  action: [actionId: string, payload: FlarePluginPageActionPayload];
}>();

const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const platform = useFlarePlatformSafe();
const heading = computed(() => props.view?.title || props.title);
const state = computed(() => flarePluginPageState(props.view, props.loading, props.error));
// An unavailable page (spec rules.page) says why; only an unreachable catalog is worth asking again.
const unavailableText = computed(() => {
  const reason = props.view?.unavailableReason;
  return reason ? t(flarePluginUnavailableKey(reason)) : t("pluginView.empty");
});
const unavailableRetry = computed(() => props.view?.unavailableReason === "catalog_unreachable");
const canRefresh = computed(() => Boolean(instance?.vnode.props?.onRefresh) && state.value === "loaded");
// Pointer devices get a refresh key in the header; touch pulls the page down.
const coarse = computed(() => platform.capabilities.value.pointer === "coarse");

const { nextCursor, pageBusy, loadMore } = usePluginPaging({
  view: () => props.view,
  loadingMore: () => props.loadingMore,
  settleToken: () => props.settleToken,
  actionError: () => props.actionError,
  refreshing: () => props.refreshing,
  request: (cursor) => emit("loadMore", cursor),
});

// ── pull to refresh ──────────────────────────────────────────────────────
const PULL_THRESHOLD = 64;
const PULL_MAX = 96;
const scroller = ref<HTMLElement | null>(null);
const pull = ref(0);
let startY: number | null = null;
const armed = computed(() => pull.value >= PULL_THRESHOLD);
const indicatorText = computed(() => {
  if (props.refreshing) return t("pluginView.refreshing");
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
  if (fire) emit("refresh");
}
function refresh(): void {
  if (!props.refreshing) emit("refresh");
}
function runAction(actionId: string, payload: FlarePluginActionPayload): void {
  emit("action", actionId, flarePluginPagePayload(props.page, props.view, payload));
}

// ── filters (spec rules.pageFilters) ─────────────────────────────────────
const filterRows = computed<FlarePluginPageFilter[]>(() => (props.view?.available ? flarePluginPageFilters(props.view, props.filters, t("pluginView.all")) : []));
const filtersBusy = computed(() => props.refreshing || props.loadingMore);
// FilterTabs keys its options by a string: all is the empty key (choice values are never empty).
const tabsOf = (filter: FlarePluginPageFilter) => filter.tabs.map((tab) => ({ value: tab.value ?? "", label: tab.label }));
function choose(filter: FlarePluginPageFilter, key: string): void {
  if (filtersBusy.value) return;
  const value = key === "" ? null : key;
  if (value === filter.selected) return;
  emit("filter", flarePluginPageFilterValues(props.filters, filter.input.id, value));
}
</script>

<template>
  <FlareScreen
    class="flare-plugin-page"
    :title="heading"
    :class="{ 'is-account': appearance === 'account' }"
    :back="back"
    :scroll="false"
    :aria-label="heading || undefined"
    :data-state="state"
    @back="emit('back')"
  >
    <template v-if="canRefresh && !coarse" #actions>
      <FlareIconButton
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
      :aria-busy="state === 'loading' || refreshing"
      @touchstart="onTouchStart"
      @touchmove="onTouchMove"
      @touchend="onTouchEnd"
      @touchcancel="onTouchEnd"
    >
      <div
        v-if="canRefresh && (pull > 0 || refreshing)"
        class="flare-plugin-page__pull"
        :class="{ 'is-armed': armed, 'is-refreshing': refreshing }"
        :style="{ height: `${refreshing ? PULL_THRESHOLD / 1.5 : pull}px` }"
        role="status"
        data-page-pull="true"
      >{{ indicatorText }}</div>
      <FlareEmptyState v-if="state === 'loading'" :title="t('pluginView.loading')" loading />
      <div v-else-if="state === 'error'" class="flare-plugin-page__error">
        <p role="alert">{{ error }}</p>
        <FlareButton variant="secondary" :label="t('pluginView.retry')" data-page-retry="true" @click="emit('retry')" />
      </div>
      <FlareEmptyState v-else-if="state === 'unavailable'" :title="unavailableText" icon="info" data-page-unavailable="true">
        <template v-if="unavailableRetry" #actions>
          <FlareButton variant="secondary" :label="t('pluginView.retry')" data-page-retry="true" @click="emit('retry')" />
        </template>
      </FlareEmptyState>
      <template v-else-if="view">
        <FlareStatusBanner v-if="error" class="flare-plugin-page__banner" :text="error" tone="danger" />
        <div v-if="filterRows.length" class="flare-plugin-page__filters" data-page-filters="true">
          <FlareFilterTabs
            v-for="filter in filterRows"
            :key="filter.input.id"
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
        <div class="flare-plugin-page__body">
          <FlareAccountView
            v-if="appearance === 'account' || view.presentation?.renderer === 'account'"
            :view="view" :resolve-user="resolveUser" :viewer-id="viewerId"
            :busy-action-id="busyActionId" :error="actionError" :form-errors="formErrors"
            :members="members" :settle-token="settleToken" @action="runAction"
          />
          <FlarePluginView
            v-else
            :view="view"
            embedded
            rows-layout="list"
            :resolve-user="resolveUser"
            :viewer-id="viewerId"
            :busy-action-id="busyActionId"
            :error="actionError"
            :form-errors="formErrors"
            :members="members"
            :settle-token="settleToken"
            @action="runAction"
          />
        </div>
        <div v-if="nextCursor" class="flare-plugin-page__more">
          <FlareButton
            variant="ghost"
            size="sm"
            block
            :label="t('pluginView.loadMore')"
            :loading="pageBusy"
            :disabled="pageBusy"
            data-page-load-more="true"
            @click="loadMore"
          />
        </div>
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
  padding: 0 var(--flare-size-spacing-lg) max(var(--flare-size-spacing-xl), env(safe-area-inset-bottom));
  box-sizing: border-box;
}
.flare-plugin-page.is-account .flare-plugin-page__scroll { max-width: 760px; width: 100%; margin-inline: auto; padding-top: var(--flare-size-spacing-lg); }
.flare-plugin-page.is-account .flare-plugin-page__body { padding: 0; background: transparent; border-radius: 0; }
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
.flare-plugin-page__body {
  padding: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
}
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
.flare-plugin-page__more { padding-top: var(--flare-size-spacing-md); }
.flare-plugin-page__error {
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-xl) 0;
  text-align: center;
}
.flare-plugin-page__error p { margin: 0; font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-secondary); }
@media (prefers-reduced-motion: no-preference) {
  .flare-plugin-page__pull:not(.is-refreshing) { transition: height var(--flare-transition-fast); }
}
</style>
