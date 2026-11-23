<script lang="ts">
/**
 * One row of an activity list: a notification about the viewer (a like, a comment, a mention). Everything is the
 * host's: the words, the time already formatted, the avatar, and whether it is unread.
 */
export interface FlareActivityItem {
  id: string;
  title: string;
  description?: string;
  /** The time, already formatted by the host ("3 分钟前"). */
  time?: string;
  avatarUrl?: string;
  unread?: boolean;
}
export interface FlareActivityListPosition {
  scrollTop: number;
  anchorId?: string;
  anchorOffset: number;
}
</script>

<script setup lang="ts">
import { getCurrentInstance, nextTick, ref, watch } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "./FlareEmptyState.vue";
import FlareUnreadBadge from "./FlareUnreadBadge.vue";
import { flareLayout } from "../../design-system/theme/layout-tokens";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

/**
 * Presentational notification rows (the same contract as the Flutter kit's FlareActivityList): recipients, read state
 * and counts come from the host, and the list keeps no read state of its own. A row is a button only while the host
 * takes `select`; without a listener the rows are text. With no items it shows `emptyText`. The `footer` slot follows
 * the rows (a "load more" sentinel, an end-of-list line).
 */
const props = withDefaults(defineProps<{
  items: readonly FlareActivityItem[];
  emptyText: string;
  /** The list's accessible name (what the activity is about). */
  ariaLabel?: string;
  density?: "normal" | "compact";
  disabled?: boolean;
  emptyDescription?: string;
  emptyActionText?: string;
}>(), { density: "normal", disabled: false });
const emit = defineEmits<{ (event: "select", id: string): void; (event: "emptyAction"): void }>();
const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const root = ref<HTMLElement>();
function rowNodes(): HTMLElement[] { return Array.from(root.value?.querySelectorAll<HTMLElement>("[data-activity-id]") ?? []); }
function capturePosition(): FlareActivityListPosition {
  const node = root.value;
  if (!node) return { scrollTop: 0, anchorOffset: 0 };
  const top = node.getBoundingClientRect().top + node.clientTop;
  const anchor = rowNodes().find(row => row.getBoundingClientRect().bottom > top);
  return { scrollTop: node.scrollTop, anchorId: anchor?.dataset.activityId, anchorOffset: anchor ? anchor.getBoundingClientRect().top - top : 0 };
}
function restorePosition(position: FlareActivityListPosition, focusId?: string): void {
  const node = root.value;
  if (!node) return;
  const nodes = rowNodes(), anchor = nodes.find(row => row.dataset.activityId === position.anchorId);
  node.scrollTop = anchor ? node.scrollTop + anchor.getBoundingClientRect().top - node.getBoundingClientRect().top - node.clientTop - position.anchorOffset : position.scrollTop;
  if (focusId) {
    const row = nodes.find(entry => entry.dataset.activityId === focusId);
    const target = row ?? anchor;
    (target?.tabIndex === 0 && !target.matches(":disabled") ? target : node).focus({ preventScroll: true });
  }
}
watch(() => props.items, async (items) => {
  const position = capturePosition();
  const document = root.value?.ownerDocument;
  const focused = rowNodes().find(row => row === document?.activeElement)?.dataset.activityId;
  await nextTick();
  const removedFocus = focused && !items.some(item => item.id === focused) && document?.activeElement === document?.body;
  restorePosition(position, removedFocus ? focused : undefined);
}, { flush: "pre" });
defineExpose({ capturePosition, restorePosition });
/** Read from the vnode at render time, so a host that binds `select` later gets buttons. */
const selectable = (): boolean => Boolean(instance?.vnode.props?.onSelect);


function select(id: string): void {
  if (selectable() && !props.disabled) emit("select", id);
}
</script>

<template>
  <div ref="root" class="flare-activity-list" :class="{ 'is-compact': density === 'compact' }" tabindex="-1" :aria-label="ariaLabel" :role="ariaLabel ? 'region' : undefined">
    <FlareEmptyState v-if="!props.items.length" class="flare-activity-list__empty" :title="emptyText" :description="emptyDescription" :action-text="emptyActionText" @action="emit('emptyAction')" />
    <ul v-else class="flare-activity-list__rows" role="list" :aria-label="ariaLabel || undefined">
      <li v-for="item in props.items" :key="item.id" class="flare-activity-list__item">
        <component
          :is="selectable() ? 'button' : 'div'"
          :type="selectable() ? 'button' : undefined"
          :disabled="selectable() ? disabled : undefined"
          class="flare-activity-list__row"
          :class="{ 'is-unread': item.unread, 'is-interactive': selectable() }"
          :data-activity-id="item.id"
          @click="select(item.id)"
        >
          <FlareAvatar
            class="flare-activity-list__avatar"
            aria-hidden="true"
            :user-id="item.id"
            :display-name="item.title"
            :avatar-url="item.avatarUrl"
            :size="density === 'compact' ? flareLayout.controlHeightSm : flareLayout.avatarSize"
          />
          <span class="flare-activity-list__text">
            <span class="flare-activity-list__title">{{ item.title }}<span v-if="item.unread" class="flare-activity-list__spoken">{{ t("activityList.unreadSuffix") }}</span></span>
            <span v-if="item.description" class="flare-activity-list__description">{{ item.description }}</span>
            <span v-if="item.time" class="flare-activity-list__time">{{ item.time }}</span>
          </span>
          <FlareUnreadBadge v-if="item.unread" class="flare-activity-list__badge" :count="0" dot />
        </component>
      </li>
    </ul>
    <div v-if="$slots.footer" class="flare-activity-list__footer"><slot name="footer" /></div>
  </div>
</template>

<style scoped>
.flare-activity-list {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  overflow-y: auto;
  overscroll-behavior-y: contain;
  container: flare-activity / inline-size;
}
.flare-activity-list__empty { flex: 1; }
.flare-activity-list__rows {
  margin: 0;
  padding: 0;
  list-style: none;
}
.flare-activity-list__item + .flare-activity-list__item .flare-activity-list__row {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-activity-list__row {
  display: flex;
  align-items: flex-start;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  box-sizing: border-box;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-lg);
  border: 0;
  background: transparent;
  color: var(--flare-color-text-primary);
  font: inherit;
  text-align: start;
}
.flare-activity-list__row.is-interactive { cursor: pointer; }
.flare-activity-list__row:disabled { cursor: default; }
.flare-activity-list.is-compact .flare-activity-list__row { gap: var(--flare-size-spacing-sm); padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md); }
.flare-activity-list.is-compact .flare-activity-list__title { font-size: var(--flare-size-font-size-md); }
@media (hover: hover) {
  .flare-activity-list__row.is-interactive:not(:disabled):hover { background: var(--flare-color-bg-hover); }
}
.flare-activity-list__row.is-interactive:not(:disabled):active { background: var(--flare-color-bg-selected); }
.flare-activity-list__row:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
.flare-activity-list__avatar { flex: none; }
.flare-activity-list__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: var(--flare-size-spacing-3xs);
  min-width: 0;
}
.flare-activity-list__title,
.flare-activity-list__description {
  display: -webkit-box;
  overflow: hidden;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  overflow-wrap: anywhere;
}
.flare-activity-list__title {
  font-size: var(--flare-size-font-size-lg);
  font-weight: 400;
  line-height: 1.4;
}
.flare-activity-list__row.is-unread .flare-activity-list__title { font-weight: 600; }
.flare-activity-list__description {
  font-size: var(--flare-size-font-size-md);
  line-height: 1.4;
  color: var(--flare-color-text-secondary);
}
.flare-activity-list__time {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
@container flare-activity (min-width: 400px) {
  .flare-activity-list.is-compact .flare-activity-list__text {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: baseline;
    column-gap: var(--flare-size-spacing-sm);
  }
  .flare-activity-list.is-compact .flare-activity-list__title { grid-area: 1 / 1; }
  .flare-activity-list.is-compact .flare-activity-list__time { grid-area: 1 / 2; }
  .flare-activity-list.is-compact .flare-activity-list__description { grid-column: 1 / -1; }
}
.flare-activity-list__badge {
  margin-top: var(--flare-size-spacing-xs);
  margin-inline-start: var(--flare-size-spacing-sm);
}
/* Heard, not seen: the dot is the sighted half of "unread". Clipped rather than hidden, so it stays in the name. */
.flare-activity-list__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}
.flare-activity-list__footer { flex: none; }
@media (prefers-reduced-motion: no-preference) {
  .flare-activity-list__row.is-interactive { transition: background-color var(--flare-component-motion-fast); }
}
</style>
