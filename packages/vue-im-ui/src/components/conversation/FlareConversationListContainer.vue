<script setup lang="ts">
import { computed, getCurrentInstance, ref, useSlots } from "vue";
import { flareViewPresentation, type FlareViewState } from "../../shared/contracts/application";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";

const props = withDefaults(defineProps<{
  state?: FlareViewState<readonly unknown[]>;
  loadingMore?: boolean;
  label?: string;
  retryLabel?: string;
  loadMoreLabel?: string;
  /** Share the inset for a workbench search entry and its filters. */
  appearance?: "default" | "workspace";
  /** The container's own words for an empty list; `state.emptyTitle` overrides it per state. */
  emptyTitle?: string;
  /**
   * A refresh asked for through `refresh` is running: the indicator stays at the top of the list and neither the
   * pull nor the refresh key asks again until it clears.
   */
  refreshing?: boolean;
}>(), { state: () => ({ status: "ready" }), loadingMore: false, label: "", retryLabel: "", loadMoreLabel: "", emptyTitle: "", refreshing: false });
const emit = defineEmits<{
  (event: "retry"): void;
  (event: "loadMore"): void;
  /**
   * Fresh data, asked for by pulling the top of the list down on touch or by the refresh key pointer devices get.
   * Only while bound, and only over rows (a loading, empty or failed list has its own states). The host reports the
   * running refresh through `refreshing`.
   */
  (event: "refresh"): void;
}>();
const instance = getCurrentInstance();
const slots = useSlots();
const { t } = useFlareI18nOptional();
const platform = useFlarePlatformSafe();
const canRetry = computed(() => Boolean(instance?.vnode.props?.onRetry));
const canLoadMore = computed(() => props.state.hasMore && !props.loadingMore && Boolean(instance?.vnode.props?.onLoadMore));
/** Rows, rows under a banner, or a state of its own — one rule, shared with the other three kits. */
const presentation = computed(() => flareViewPresentation(props.state.status, props.state.stale));

// ── refresh: pull on touch, a key on pointer devices (the same pattern as FlarePluginPage) ────────────────
/** Read at render time, so a host that binds `refresh` later gets the gesture and the key. */
function canRefresh(): boolean {
  return Boolean(instance?.vnode.props?.onRefresh) && presentation.value !== "state";
}
// A touch-only device pulls; anything with a fine pointer (a mouse, a trackpad, a touch laptop) also gets the key.
const coarse = computed(() => platform.capabilities.value.pointer === "coarse");
/** The key sits at the end of the filters row when there is one, else in a slim row of its own above the rows. */
const refreshKeyAt = (): "filters" | "own" | null => {
  if (!canRefresh() || coarse.value) return null;
  return slots.filters ? "filters" : "own";
};
const PULL_THRESHOLD = 64;
const PULL_MAX = 96;
const body = ref<HTMLElement | null>(null);
const pull = ref(0);
let pullStartY: number | null = null;
const armed = computed(() => pull.value >= PULL_THRESHOLD);
const indicatorText = computed(() => {
  if (props.refreshing) return t("listRefresh.refreshing");
  return armed.value ? t("listRefresh.release") : t("listRefresh.pull");
});
function onTouchStart(event: TouchEvent): void {
  pullStartY = null;
  if (!canRefresh() || props.refreshing || event.touches?.length !== 1 || (body.value?.scrollTop ?? 0) > 0) return;
  pullStartY = event.touches[0]?.clientY ?? null;
}
function onTouchMove(event: TouchEvent): void {
  if (pullStartY === null) return;
  const dy = (event.touches?.[0]?.clientY ?? pullStartY) - pullStartY;
  if (dy <= 0) {
    pull.value = 0;
    return;
  }
  // Resist the finger: half its travel, up to the cap.
  pull.value = Math.min(PULL_MAX, dy / 2);
  if (event.cancelable) event.preventDefault();
}
function onTouchEnd(event: TouchEvent): void {
  if (pullStartY === null) return;
  pullStartY = null;
  const fire = armed.value && event.type === "touchend";
  pull.value = 0;
  if (fire && canRefresh() && !props.refreshing) emit("refresh");
}
function refresh(): void {
  if (canRefresh() && !props.refreshing) emit("refresh");
}
</script>

<template>
  <section class="flare-list-container" :data-appearance="appearance" :aria-label="label || undefined">
    <div v-if="$slots.header" class="flare-list-container__header"><slot name="header" /></div>
    <div v-if="$slots.search" class="flare-list-container__search"><slot name="search" /></div>
    <div v-if="$slots.filters" class="flare-list-container__filters" :class="{ 'has-refresh': refreshKeyAt() === 'filters' }">
      <template v-if="refreshKeyAt() === 'filters'">
        <div class="flare-list-container__filters-slot"><slot name="filters" /></div>
        <FlareIconButton
          class="flare-list-container__refresh-key"
          :icon="flareIcons.refresh"
          :ariaLabel="t('listRefresh.refresh')"
          :title="t('listRefresh.refresh')"
          size="sm"
          :disabled="refreshing"
          data-list-refresh="true"
          @click="refresh"
        />
      </template>
      <slot v-else name="filters" />
    </div>
    <div v-if="$slots.status" class="flare-list-container__status"><slot name="status" /></div>
    <div v-if="refreshKeyAt() === 'own'" class="flare-list-container__refresh">
      <FlareIconButton
        class="flare-list-container__refresh-key"
        :icon="flareIcons.refresh"
        :ariaLabel="t('listRefresh.refresh')"
        :title="t('listRefresh.refresh')"
        size="sm"
        :disabled="refreshing"
        data-list-refresh="true"
        @click="refresh"
      />
    </div>
    <div v-if="$slots.pinned && state.status === 'ready'" class="flare-list-container__pinned"><slot name="pinned" /></div>
    <div
      ref="body"
      class="flare-list-container__body"
      :aria-busy="state.status === 'loading' || refreshing || undefined"
      @touchstart.passive="onTouchStart"
      @touchmove="onTouchMove"
      @touchend.passive="onTouchEnd"
      @touchcancel.passive="onTouchEnd"
    >
      <div
        v-if="canRefresh() && (pull > 0 || refreshing)"
        class="flare-list-container__pull"
        :class="{ 'is-armed': armed, 'is-refreshing': refreshing }"
        :style="{ height: `${refreshing ? PULL_THRESHOLD / 1.5 : pull}px` }"
        role="status"
        data-list-pull="true"
      >{{ indicatorText }}</div>
      <template v-if="presentation === 'state'">
        <FlareSkeleton v-if="state.status === 'loading'" variant="conversation" :rows="8" role="status" />
        <FlareEmptyState v-else-if="state.status === 'empty'" :title="state.emptyTitle || emptyTitle" />
        <!-- 一条都没有、而且是失败：这一屏上没有别的东西了，所以失败本身就是这一屏的内容。
             改前这里只画一条横幅，下面留一整片空白 —— 空列表有完整空态，彻底加载不出来
             反而只有一条细带，更严重的状态给了更弱的表达，而且恢复入口是带子右端的一个小链接。 -->
        <FlareEmptyState
          v-else-if="state.status === 'error'"
          tone="error"
          icon="warning"
          :title="state.error || ''"
          :action-text="canRetry ? retryLabel : undefined"
          @action="emit('retry')"
        />
        <FlareStatusBanner v-else :tone="'neutral'" :text="state.error || ''" :action-text="canRetry ? retryLabel : undefined" @action="emit('retry')" />
      </template>
      <template v-else>
        <!-- A failed refresh over rows worth keeping: the failure is a banner, the rows stay readable. -->
        <FlareStatusBanner
          v-if="presentation === 'contentWithNotice'"
          class="flare-list-container__stale"
          :tone="state.status === 'error' ? 'danger' : 'neutral'"
          :text="state.error || ''"
          :action-text="canRetry ? retryLabel : undefined"
          @action="emit('retry')"
        />
        <slot />
      </template>
    </div>
    <div v-if="$slots.archived && state.status === 'ready'" class="flare-list-container__archived"><slot name="archived" /></div>
    <button v-if="canLoadMore" type="button" class="flare-list-container__more" @click="emit('loadMore')"><slot name="loadMore">{{ loadMoreLabel }}</slot></button>
    <div v-if="loadingMore" class="flare-list-container__loading-more" role="status"><FlareSkeleton variant="conversation" :rows="1" /></div>
    <footer v-if="$slots.footer" class="flare-list-container__footer"><slot name="footer" /></footer>
  </section>
</template>

<style scoped>
.flare-list-container { display: flex; flex-direction: column; width: 100%; height: 100%; min-width: 0; min-height: 0; overflow: hidden; box-sizing: border-box; background: var(--flare-color-bg-primary); }
.flare-list-container__header,
.flare-list-container__search,
.flare-list-container__filters,
.flare-list-container__status,
.flare-list-container__pinned,
.flare-list-container__archived,
.flare-list-container__footer { flex: none; }
.flare-list-container__filters { padding-inline: var(--flare-size-spacing-sm); }
.flare-list-container[data-appearance="workspace"] .flare-list-container__search {
  margin: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-sm);
}
.flare-list-container[data-appearance="workspace"] .flare-list-container__filters {
  padding-inline: var(--flare-size-spacing-lg);
  padding-block-end: var(--flare-size-spacing-xs);
  border-block-end: 1px solid var(--flare-color-border-secondary);
}
.flare-list-container__body { flex: 1; min-width: 0; min-height: 0; overflow-x: hidden; overflow-y: auto; overscroll-behavior-y: contain; }
/* The refresh key on pointer devices: at the end of the filters row, or a slim row of its own above the rows. */
.flare-list-container__filters.has-refresh { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); }
.flare-list-container__filters-slot { flex: 1; min-width: 0; }
.flare-list-container__refresh { display: flex; flex: none; justify-content: flex-end; padding-inline: var(--flare-size-spacing-sm); }
.flare-list-container__refresh-key { flex: none; }
/* Pull to refresh: the band grows with the finger and says what letting go will do. */
.flare-list-container__pull {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  overflow: hidden;
  padding-bottom: var(--flare-size-spacing-xs);
  box-sizing: border-box;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
.flare-list-container__pull.is-armed,
.flare-list-container__pull.is-refreshing { color: var(--flare-color-text-secondary); }
@media (prefers-reduced-motion: no-preference) {
  .flare-list-container__pull:not(.is-refreshing) { transition: height var(--flare-transition-fast); }
}
.flare-list-container__more { min-height: var(--flare-size-layout-touch-target); border: 0; border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-text-link); background: var(--flare-color-bg-primary); cursor: pointer; }
.flare-list-container__more:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-list-container__loading-more { flex: none; padding: var(--flare-size-spacing-sm); }
</style>
