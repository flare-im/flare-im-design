<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { flareViewPresentation, type FlareViewState } from "../../shared/contracts/application";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";

const props = withDefaults(defineProps<{
  state?: FlareViewState<readonly unknown[]>;
  loadingMore?: boolean;
  label?: string;
  retryLabel?: string;
  loadMoreLabel?: string;
  /** The container's own words for an empty list; `state.emptyTitle` overrides it per state. */
  emptyTitle?: string;
}>(), { state: () => ({ status: "ready" }), loadingMore: false, label: "", retryLabel: "", loadMoreLabel: "", emptyTitle: "" });
const emit = defineEmits<{ (event: "retry"): void; (event: "loadMore"): void }>();
const instance = getCurrentInstance();
const canRetry = computed(() => Boolean(instance?.vnode.props?.onRetry));
const canLoadMore = computed(() => props.state.hasMore && !props.loadingMore && Boolean(instance?.vnode.props?.onLoadMore));
/** Rows, rows under a banner, or a state of its own — one rule, shared with the other three kits. */
const presentation = computed(() => flareViewPresentation(props.state.status, props.state.stale));
</script>

<template>
  <section class="flare-list-container" :aria-label="label || undefined">
    <header v-if="$slots.header" class="flare-list-container__header"><slot name="header" /></header>
    <div v-if="$slots.search" class="flare-list-container__search"><slot name="search" /></div>
    <div v-if="$slots.filters" class="flare-list-container__filters"><slot name="filters" /></div>
    <div v-if="$slots.status" class="flare-list-container__status"><slot name="status" /></div>
    <div v-if="$slots.pinned && state.status === 'ready'" class="flare-list-container__pinned"><slot name="pinned" /></div>
    <div class="flare-list-container__body">
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
.flare-list-container__body { flex: 1; min-width: 0; min-height: 0; overflow-x: hidden; overflow-y: auto; }
.flare-list-container__more { min-height: var(--flare-size-layout-touch-target); border: 0; border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-text-link); background: var(--flare-color-bg-primary); cursor: pointer; }
.flare-list-container__more:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-list-container__loading-more { flex: none; padding: var(--flare-size-spacing-sm); }
</style>
