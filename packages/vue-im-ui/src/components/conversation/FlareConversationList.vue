<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import type { FlareConversationListSection, FlareConversationRowModel } from "../../shared/contracts/conversation";
import type { ConversationActionCapabilities, FlareConversationAction } from "../../shared/contracts/conversation-actions";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareConversationRow from "./FlareConversationRow.vue";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  items?: FlareConversationRowModel[];
  sections?: FlareConversationListSection[];
  activeId?: string;
  loading?: boolean;
  /** Conversation actions the host implements; rows offer a menu only for these. */
  capabilities?: ConversationActionCapabilities;
  /** Batch selection: rows become checkboxes and emit toggleSelect. */
  selectable?: boolean;
  selectedIds?: readonly string[];
  virtualizeAbove?: number;
  estimatedRowHeight?: number;
  estimatedSectionHeight?: number;
  overscan?: number;
}>(), {
  items: () => [],
  sections: () => [],
  selectable: false,
  selectedIds: () => [],
  virtualizeAbove: 200,
  estimatedSectionHeight: 34,
  overscan: 8,
});

const { t } = useFlareI18n();
const { isH5 } = useFlareAdaptiveSafe();
const rowHeight = computed(() => props.estimatedRowHeight ?? (isH5.value ? 80 : 72));
const emit = defineEmits<{
  (event: "select", id: string): void;
  (event: "action", action: FlareConversationAction, id: string): void;
  (event: "toggleSelect", id: string): void;
}>();
const selectedSet = computed(() => new Set(props.selectedIds));
const root = ref<HTMLElement | null>(null);
const scrollTop = ref(0);
const viewportHeight = ref(0);
let observer: ResizeObserver | undefined;

type ConversationListEntry =
  | { key: string; kind: "section"; section: FlareConversationListSection }
  | { key: string; kind: "item"; item: FlareConversationRowModel };

const entries = computed<ConversationListEntry[]>(() => {
  if (!props.sections.length) {
    // Host order is the order: the core already lists pinned conversations first.
    return props.items.map((item) => ({ key: `item:${item.id}`, kind: "item", item }));
  }
  return props.sections.flatMap((section) => {
    if (!section.items.length) return [];
    const rows: ConversationListEntry[] = section.items.map((item) => ({
      key: `item:${item.id}`,
      kind: "item",
      item,
    }));
    if (!section.label) return rows;
    return [{ key: `section:${section.id}`, kind: "section", section }, ...rows];
  });
});
const itemCount = computed(() => entries.value.filter((entry) => entry.kind === "item").length);
const virtualized = computed(() => itemCount.value >= props.virtualizeAbove);
const entryOffsets = computed(() => {
  const offsets = [0];
  for (const entry of entries.value) {
    const height = entry.kind === "section" ? props.estimatedSectionHeight : rowHeight.value;
    offsets.push(offsets[offsets.length - 1] + height);
  }
  return offsets;
});
const totalHeight = computed(() => entryOffsets.value.at(-1) ?? 0);

function indexAt(offset: number): number {
  const offsets = entryOffsets.value;
  let low = 0;
  let high = Math.max(0, entries.value.length - 1);
  while (low < high) {
    const mid = Math.floor((low + high + 1) / 2);
    if (offsets[mid] <= offset) low = mid;
    else high = mid - 1;
  }
  return low;
}

const overscanPixels = computed(() => props.overscan * rowHeight.value);
const startIndex = computed(() => virtualized.value
  ? indexAt(Math.max(0, scrollTop.value - overscanPixels.value))
  : 0);
const endIndex = computed(() => {
  if (!virtualized.value) return entries.value.length;
  const viewportBottom = scrollTop.value + viewportHeight.value + overscanPixels.value;
  return Math.min(entries.value.length, indexAt(viewportBottom) + 1);
});
const visibleEntries = computed(() => entries.value.slice(startIndex.value, endIndex.value));
const topSpacer = computed(() => virtualized.value ? entryOffsets.value[startIndex.value] ?? 0 : 0);
const bottomSpacer = computed(() => virtualized.value
  ? Math.max(0, totalHeight.value - (entryOffsets.value[endIndex.value] ?? totalHeight.value))
  : 0);

function measure(): void {
  viewportHeight.value = root.value?.clientHeight ?? 0;
}

function onScroll(): void {
  scrollTop.value = root.value?.scrollTop ?? 0;
}

async function onKeydown(event: KeyboardEvent): Promise<void> {
  if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) return;
  const button = (event.target as HTMLElement).closest<HTMLButtonElement>(".im-conv-item__select");
  if (!button) return;
  event.preventDefault();
  const id = button.closest<HTMLElement>("[data-conversation-id]")?.dataset.conversationId;
  const rows = entries.value.filter((entry) => entry.kind === "item");
  const current = rows.findIndex((entry) => entry.item.id === id);
  const index = event.key === "Home" ? 0 : event.key === "End" ? rows.length - 1 : Math.min(rows.length - 1, Math.max(0, current + (event.key === "ArrowDown" ? 1 : -1)));
  const entry = rows[index];
  if (!entry || !root.value) return;
  const targetIndex = entries.value.indexOf(entry);
  const top = entryOffsets.value[targetIndex];
  if (virtualized.value && (targetIndex < startIndex.value || targetIndex >= endIndex.value)) {
    root.value.scrollTop = top;
    onScroll();
    await nextTick();
  }
  const row = Array.from(root.value.querySelectorAll<HTMLElement>("[data-conversation-id]")).find((node) => node.dataset.conversationId === entry.item.id);
  row?.querySelector<HTMLButtonElement>(".im-conv-item__select")?.focus();
}

// Keep the first visible conversation anchored when pin/unread projections reorder.
watch(entries, async (next, previous) => {
  if (!root.value || scrollTop.value === 0) return;
  let offset = 0;
  const anchor = previous.find((entry) => {
    const height = entry.kind === "section" ? props.estimatedSectionHeight : rowHeight.value;
    if (offset + height > scrollTop.value) return true;
    offset += height;
    return false;
  });
  const index = next.findIndex((entry) => entry.key === anchor?.key);
  if (index < 0) return;
  const target = entryOffsets.value[index] + scrollTop.value - offset;
  await nextTick();
  if (root.value) { root.value.scrollTop = target; onScroll(); }
});

onMounted(() => {
  measure();
  if (typeof ResizeObserver !== "undefined" && root.value) {
    observer = new ResizeObserver(measure);
    observer.observe(root.value);
  }
});
onBeforeUnmount(() => observer?.disconnect());
</script>

<template>
  <div ref="root" class="im-conv-list" role="list" @scroll.passive="onScroll" @keydown="onKeydown">
    <FlareEmptyState v-if="loading" class="im-conv-list__state" loading :title="t('conversation.loading')" />
    <div v-else-if="!itemCount" class="im-conv-list__state">
      <slot name="empty"><FlareEmptyState icon="chats" :title="t('conversation.emptyTitle')" /></slot>
    </div>
    <template v-else>
      <!-- key 必须挂在 <template> 上，不能挂在 <slot> 上。挂在 slot 出口上时
           Vue 无法对它做带 key 的 diff：items 每换一次引用，整个列表的 DOM
           就被销毁重建一遍。表现是列表闪、点击落空（元素在点击落地前已被换掉）。 -->
      <div v-if="topSpacer" class="im-conv-list__spacer" aria-hidden="true" :style="{ height: `${topSpacer}px` }" />
      <template v-for="entry in visibleEntries" :key="entry.key">
        <div v-if="entry.kind === 'section'" class="im-conv-list__section" role="separator">
          <slot name="section" :section="entry.section">{{ entry.section.label }}</slot>
        </div>
        <slot
          v-else
          name="item"
          :item="entry.item"
          :active="entry.item.id === activeId"
          :selected="selectedSet.has(entry.item.id)"
        >
          <FlareConversationRow
            :item="entry.item"
            :active="entry.item.id === activeId"
            :capabilities="capabilities"
            :selectable="selectable"
            :selected="selectedSet.has(entry.item.id)"
            @select="emit('select', $event)"
            @action="(action: FlareConversationAction) => emit('action', action, entry.item.id)"
            @toggle-select="emit('toggleSelect', $event)"
          />
        </slot>
      </template>
      <div v-if="bottomSpacer" class="im-conv-list__spacer" aria-hidden="true" :style="{ height: `${bottomSpacer}px` }" />
    </template>
  </div>
</template>

<style scoped>
.im-conv-list {
  display: flex;
  flex-direction: column;
  width: 100%;
  /* A scroll container that never bounds its own height cannot scroll, and the
     virtual window (which measures clientHeight) then covers the whole list —
     1000 rows rendered eagerly instead of a screenful. `100%` resolves to auto
     inside an auto-height parent, so this only takes effect where the host
     actually gave the list a box to live in. */
  height: 100%;
  min-width: 0;
  min-height: 0;
  box-sizing: border-box;
  overflow-x: hidden;
  overflow-y: auto;
  background: var(--flare-color-bg-primary);
}

/* Spacers stand in for the rows outside the window; a shrinkable flex item would
   collapse to 0 px in this fixed-height column and cut the list off. */
.im-conv-list__spacer {
  flex: none;
}

.im-conv-list__state {
  padding: 18px 0;
  color: var(--flare-color-text-secondary);
  font-size: 13px;
  text-align: center;
}

.im-conv-list__section {
  min-height: 34px;
  display: flex;
  align-items: end;
  padding: 8px 6px 6px;
  box-sizing: border-box;
  color: var(--flare-color-text-tertiary);
  font-size: 12px;
  font-weight: 600;
  line-height: 1.2;
}
</style>
