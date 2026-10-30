<script setup lang="ts">
// 群消息已读名单 —— 已读 / 未读两栏，各自分页（spec ReadReceiptSheet、spec/read-receipt-vectors.json）。
//
// 标签上的数字只取宿主传的摘要人数（receipt.readSummary），不取已经取到的名单长度：名单可能只是第一页。
// 组件只画：两栏的名单由宿主持有并按页追加，`loadMore(column)` 请宿主取下一页；整张名单的读取状态是
// `state`。放进 Kit 的底部面板时不画自己的卡片外壳，并声明自带标题（宿主用面板的 fill 模式打开），
// 面板标题只作可及名称、不画第二遍。
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareFilterTabs, { type FlareFilterTabOption } from "../general/FlareFilterTabs.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareInsideSheet, useFlareSheetOwnHeader } from "../../shared/sheetHeader";
import type { FlareContact } from "../../shared/contracts";
import {
  flareReadReceiptPresentation,
  type FlareReadReceiptColumn,
  type FlareReadReceiptState,
} from "../../shared/contracts/read-receipt";

const props = withDefaults(
  defineProps<{
    /** Members of the read column loaded so far (one page or more). */
    readers: FlareContact[];
    /** Members of the unread column loaded so far. */
    unread: FlareContact[];
    /** The summary's read count: the read tab's number. Absent: no number (never the list's length). */
    readCount?: number | null;
    /** The summary's unread count: the unread tab's number. */
    unreadCount?: number | null;
    /** ready, loading (a spinner), error (a notice with retry) or unavailable (a notice, no retry). */
    state?: FlareReadReceiptState;
    /** The read column has a next page. */
    readHasMore?: boolean;
    /** The unread column has a next page. */
    unreadHasMore?: boolean;
    /** The column whose next page is being read. */
    loadingMore?: FlareReadReceiptColumn | null;
    /** The column whose last next-page read failed. */
    loadMoreFailed?: FlareReadReceiptColumn | null;
    /** The column shown first. */
    initialTab?: FlareReadReceiptColumn;
    /** Show the header dismiss control. */
    dismissible?: boolean;
  }>(),
  {
    readCount: null,
    unreadCount: null,
    state: "ready",
    readHasMore: false,
    unreadHasMore: false,
    loadingMore: null,
    loadMoreFailed: null,
    initialTab: "read",
    dismissible: false,
  },
);
const emit = defineEmits<{
  (e: "select", id: string): void;
  (e: "close"): void;
  /** Read the next page of a column. */
  (e: "loadMore", column: FlareReadReceiptColumn): void;
  /** Read the list again after it failed. */
  (e: "retry"): void;
}>();

const { t } = useFlareI18n();
// In a kit sheet the sheet is the surface and the title row here is its header.
const inSheet = useFlareInsideSheet();
useFlareSheetOwnHeader();

const active = ref<FlareReadReceiptColumn>(props.initialTab);
const view = computed(() =>
  flareReadReceiptPresentation({
    state: props.state,
    readers: props.readers.length,
    unread: props.unread.length,
    readCount: props.readCount,
    unreadCount: props.unreadCount,
    readHasMore: props.readHasMore,
    unreadHasMore: props.unreadHasMore,
    loadingMore: props.loadingMore,
    loadMoreFailed: props.loadMoreFailed,
    tab: active.value,
  }),
);

const tabs = computed<FlareFilterTabOption[]>(() =>
  (view.value.tabs ?? []).map((tab) => ({
    value: tab.value,
    label: tab.count === null
      ? t(tab.value === "read" ? "readReceipt.read" : "readReceipt.unread")
      : t(tab.value === "read" ? "readReceipt.readTab" : "readReceipt.unreadTab", { count: tab.count }),
  })),
);
const list = computed(() => (active.value === "read" ? props.readers : props.unread));
const emptyTitle = computed(() =>
  view.value.empty === "unread" ? t("readReceipt.emptyUnread") : t("readReceipt.emptyRead"),
);

function selectTab(value: string): void {
  if (value === "read" || value === "unread") active.value = value;
}
function pressTail(): void {
  const tail = view.value.tail;
  if (tail === "loadMore" || tail === "retry") emit("loadMore", active.value);
}
</script>

<template>
  <section
    class="flare-read-receipt"
    :class="{ 'is-in-sheet': inSheet }"
    :aria-label="t('readReceipt.title')"
    :data-state="state"
  >
    <header class="flare-read-receipt__head">
      <div class="flare-read-receipt__title">
        <n-icon aria-hidden="true" :size="16" :component="flareIcons.read" />
        <span>{{ t("readReceipt.title") }}</span>
      </div>
      <FlareIconButton
        v-if="dismissible"
        class="flare-read-receipt__close"
        :icon="flareIcons.close"
        :ariaLabel="t('readReceipt.close')"
        @click="emit('close')"
      />
    </header>

    <FlareFilterTabs
      v-if="view.tabs"
      :model-value="active"
      :options="tabs"
      :aria-label="t('readReceipt.title')"
      @update:model-value="selectTab"
    />

    <div class="flare-read-receipt__body">
      <FlareEmptyState v-if="view.body === 'spinner'" :title="t('readReceipt.loading')" loading />
      <FlareEmptyState
        v-else-if="view.body === 'error'"
        tone="error"
        icon="error"
        :title="t('readReceipt.loadFailed')"
        :action-text="t('common.retry')"
        @action="emit('retry')"
      />
      <FlareEmptyState v-else-if="view.body === 'unavailable'" icon="info" :title="t('readReceipt.unavailable')" />
      <FlareEmptyState v-else-if="view.body === 'empty'" icon="success" :title="emptyTitle" />
      <ul v-else class="flare-read-receipt__list">
        <li v-for="c in list" :key="c.id">
          <button type="button" class="flare-read-receipt__row" @click="emit('select', c.id)">
            <FlareAvatar :user-id="c.id" :display-name="c.name" :avatar-url="c.avatarUrl" :size="36" />
            <span class="flare-read-receipt__name">{{ c.name }}</span>
          </button>
        </li>
        <li v-if="view.tail === 'busy'" class="flare-read-receipt__tail is-busy" role="status" aria-live="polite">
          <span class="flare-read-receipt__spinner" aria-hidden="true" />
          <span>{{ t("common.loading") }}</span>
        </li>
        <li v-else-if="view.tail !== 'none'">
          <button
            type="button"
            class="flare-read-receipt__tail"
            :class="{ 'is-failed': view.tail === 'retry' }"
            :data-tail="view.tail"
            @click="pressTail"
          >
            {{ view.tail === "retry" ? t("readReceipt.loadMoreFailed") : t("readReceipt.loadMore") }}
          </button>
        </li>
      </ul>
    </div>
  </section>
</template>

<style scoped>
/* Outside a kit overlay: a card of its own, as wide as the container allows up to the popover width. */
.flare-read-receipt {
  box-sizing: border-box;
  width: 100%;
  max-width: 320px;
  min-width: 0;
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
  overflow: hidden;
}
/* In a kit sheet the sheet is the surface: no shell, the full width, the rows take the height left. */
.flare-read-receipt.is-in-sheet {
  max-width: none;
  border: none;
  border-radius: 0;
  box-shadow: none;
  background: transparent;
  min-height: 0;
}
.flare-read-receipt__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-touch-target);
  /* 右侧留 spacing.sm,与下面名单行的内缩对齐:只留 xs 时关闭键(40,命中区 48)挤进卡片的圆角,
     卡片的 overflow: hidden 把命中区的右上角裁掉,粗指针下点关闭键的右上沿会落空。 */
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm) var(--flare-size-spacing-xs) var(--flare-size-spacing-lg);
}
.flare-read-receipt__title {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  font-size: var(--flare-size-font-size-lg);
  font-weight: 600;
  color: var(--flare-color-text-primary);
}
.flare-read-receipt__close { flex: 0 0 auto; color: var(--flare-color-text-tertiary); }
.flare-read-receipt__body {
  display: flex;
  flex-direction: column;
  min-height: 0;
  max-height: 320px;
  overflow-y: auto;
  overscroll-behavior: contain;
}
.flare-read-receipt.is-in-sheet .flare-read-receipt__body { flex: 1 1 auto; max-height: none; }
.flare-read-receipt__list {
  list-style: none;
  margin: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm) var(--flare-size-spacing-sm);
}
.flare-read-receipt__row {
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-sm);
  border: none;
  border-radius: var(--flare-size-radius-lg);
  background: transparent;
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-md);
  text-align: start;
  cursor: pointer;
  transition: background var(--flare-transition-fast);
}
@media (hover: hover) {
  .flare-read-receipt__row:hover { background: var(--flare-color-bg-secondary); }
}
.flare-read-receipt__row:focus-visible,
.flare-read-receipt__tail:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
.flare-read-receipt__name {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-read-receipt__tail {
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-sm);
  border: none;
  border-radius: var(--flare-size-radius-lg);
  background: transparent;
  color: var(--flare-color-primary-text);
  font-size: var(--flare-size-font-size-sm);
  cursor: pointer;
}
.flare-read-receipt__tail.is-failed { color: var(--flare-color-error-text); }
.flare-read-receipt__tail.is-busy { color: var(--flare-color-text-tertiary); cursor: default; }
.flare-read-receipt__spinner {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid var(--flare-color-border-primary);
  border-top-color: var(--flare-color-primary);
  animation: flare-read-receipt-spin 0.8s linear infinite;
}
@keyframes flare-read-receipt-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) {
  .flare-read-receipt__spinner { animation: none; }
}
</style>
