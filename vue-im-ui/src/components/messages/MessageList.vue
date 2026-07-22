<script setup lang="ts">
import FlareIcon from "../general/FlareIcon.vue";
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from "vue";
import MessageBubble from "./MessageBubble.vue";
import TimeStamp from "./TimeStamp.vue";
import type { MessageLike, MessageMediaDownloadUiState } from "./MessageBubble.vue";
import type { MessageMenuConfig } from "../../shared/config/messageMenu";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import {
  countAppendedItems,
  countPrependedItems,
  normalizeMessageRowsForVirtualList,
  restorePrependScrollTop,
  type ScrollAnchorSnapshot,
} from "../../utils";

const BOTTOM_STICKY_PX = 80;
const RESIZE_STICKY_PX = 420;
const MESSAGE_LIST_TOP_PADDING = 22;
const MESSAGE_LIST_BOTTOM_SAFE_PADDING = 18;
// The current virtual window uses fixed row-height estimates, while chat rows
// can contain rich text, media, and quoted content. Keep loaded timelines on
// native layout so paging changes the scrollbar from real DOM height.
const VIRTUALIZATION_THRESHOLD = 25_000;
const VIRTUAL_OVERSCAN_PX = 1400;
const ESTIMATED_MESSAGE_ROW_PX = 76;
const ESTIMATED_TIME_ROW_PX = 34;

const props = defineProps<{
  conversationId?: string;
  conversationType?: "single" | "group" | "ai" | string;
  messages: readonly MessageLike[];
  currentUserId: string;
  multiSelectMode?: boolean;
  selectedIds?: readonly string[];
  loadingOlder?: boolean;
  hasOlder: boolean;
  bottomInset?: number;
  menuConfig?: MessageMenuConfig;
  mediaDownloadStates?: Record<string, MessageMediaDownloadUiState>;
}>();

const { t } = useFlareI18n();

const emit = defineEmits<{
  (event: "react", messageId: string, emoji: string): void;
  (event: "edit", messageId: string): void;
  (event: "delete", messageId: string): void;
  (event: "pin", messageId: string, pinned: boolean, scope: "conversation" | "self"): void;
  (event: "mark", messageId: string): void;
  (event: "preview", messageId: string): void;
  (event: "mediaAction", messageId: string, action: "download" | "openFolder"): void;
  (event: "reply", messageId: string): void;
  (event: "forward", messageId: string): void;
  (event: "recall", messageId: string): void;
  (event: "resend", clientMsgId: string): void;
  (event: "multiSelect", messageId: string): void;
  (event: "toggle-select", messageId: string): void;
  (event: "atBottomChange", atBottom: boolean): void;
  (event: "load-older"): void;
  (event: "locate-message", messageId: string): void;
}>();

const scrollContainerRef = ref<HTMLElement | null>(null);
const scrollContentRef = ref<HTMLElement | null>(null);
const isAtBottom = ref(true);
const followTail = ref(true);
const shortTimelineTopSpacerPx = ref(0);
const historyStartHintVisible = ref(false);
const virtualScrollTopPx = ref(0);
const virtualViewportHeightPx = ref(0);
/** 离开底部时的最后一条消息 id，用于统计下方新增条数 */
const anchorTailId = ref<string | null>(null);
const pendingTimers = new Set<number>();
let loadOlderRequested = false;
let listResizeObserver: ResizeObserver | null = null;
let pendingPrependAnchor: ScrollAnchorSnapshot | null = null;
let preservingPrependAnchor = false;
let bottomScrollGeneration = 0;

type TimelineRow =
  | { kind: "time"; key: string; label: string }
  | {
      kind: "message";
      key: string;
      message: MessageLike;
      groupStart: boolean;
      groupEnd: boolean;
    };

function timelineKey(message: MessageLike): string {
  return message.timelineKey;
}

function messageActionId(message: MessageLike): string {
  return message.clientMsgId || message.serverId;
}

const displayMessages = computed(() =>
  normalizeMessageRowsForVirtualList(props.messages),
);

// One-shot entrance for messages that arrive at the tail (just sent/received) —
// NOT history prepends and NOT the initial mount, so the virtualized list never
// re-animates a bubble that merely scrolls back into view. Ids clear after the
// animation window.
const freshIds = ref<Set<string>>(new Set());
watch(
  () => props.messages,
  (next, prev) => {
    if (!prev || prev.length === 0 || next.length <= prev.length) return;
    const prevIds = new Set(prev.map((m) => messageActionId(m)));
    const appended: string[] = [];
    for (let index = next.length - 1; index >= 0; index -= 1) {
      const id = messageActionId(next[index]);
      if (prevIds.has(id)) break; // reached the pre-existing tail → stop
      appended.push(id);
    }
    if (!appended.length) return; // new ids were prepended (history) → skip
    freshIds.value = new Set([...freshIds.value, ...appended]);
    const timer = window.setTimeout(() => {
      const cleared = new Set(freshIds.value);
      appended.forEach((id) => cleared.delete(id));
      freshIds.value = cleared;
      pendingTimers.delete(timer);
    }, 460);
    pendingTimers.add(timer);
  },
);

const timelineRows = computed<TimelineRow[]>(() => {
  const rows: TimelineRow[] = [];
  const messages = displayMessages.value;
  let previousTs = 0;
  for (let index = 0; index < messages.length; index += 1) {
    const message = messages[index];
    const ts = Number(message.createdAt || message.clientCreatedAt || 0);
    if (shouldShowTime(previousTs, ts)) {
      rows.push({
        kind: "time",
        key: `time-${timelineKey(message)}`,
        label: timeLabel(ts),
      });
    }
    rows.push({
      kind: "message",
      key: timelineKey(message),
      message,
      groupStart: !isSameSenderGroup(messages[index - 1], message),
      groupEnd: !isSameSenderGroup(message, messages[index + 1]),
    });
    previousTs = ts || previousTs;
  }
  return rows;
});

function estimatedRowHeight(row: TimelineRow): number {
  return row.kind === "time" ? ESTIMATED_TIME_ROW_PX : ESTIMATED_MESSAGE_ROW_PX;
}

const virtualOffsets = computed(() => {
  const rows = timelineRows.value;
  const offsets = new Array<number>(rows.length + 1);
  let cursor = 0;
  offsets[0] = 0;
  for (let index = 0; index < rows.length; index += 1) {
    cursor += estimatedRowHeight(rows[index]);
    offsets[index + 1] = cursor;
  }
  return offsets;
});

const estimatedTimelineHeight = computed(() => {
  const offsets = virtualOffsets.value;
  return offsets[offsets.length - 1] ?? 0;
});

const virtualEnabled = computed(
  () => timelineRows.value.length > VIRTUALIZATION_THRESHOLD,
);

function lowerBoundOffset(offsets: readonly number[], value: number): number {
  let low = 0;
  let high = Math.max(0, offsets.length - 1);
  while (low < high) {
    const mid = Math.floor((low + high) / 2);
    if ((offsets[mid] ?? 0) < value) low = mid + 1;
    else high = mid;
  }
  return low;
}

const virtualWindow = computed(() => {
  const rows = timelineRows.value;
  if (!virtualEnabled.value || rows.length === 0) {
    return {
      start: 0,
      end: rows.length,
      top: 0,
      bottom: 0,
    };
  }

  const offsets = virtualOffsets.value;
  const viewport = Math.max(virtualViewportHeightPx.value, 1);
  const windowTop = Math.max(0, virtualScrollTopPx.value - VIRTUAL_OVERSCAN_PX);
  const windowBottom = virtualScrollTopPx.value + viewport + VIRTUAL_OVERSCAN_PX;
  const start = Math.max(0, lowerBoundOffset(offsets, windowTop) - 1);
  const end = Math.min(
    rows.length,
    lowerBoundOffset(offsets, windowBottom) + 1,
  );
  const top = offsets[start] ?? 0;
  const bottom = Math.max(0, estimatedTimelineHeight.value - (offsets[end] ?? 0));
  return { start, end, top, bottom };
});

const virtualItems = computed<TimelineRow[]>(() => {
  const rows = timelineRows.value;
  const window = virtualWindow.value;
  return rows.slice(window.start, window.end);
});

const virtualTopSpacerPx = computed(() =>
  virtualEnabled.value ? virtualWindow.value.top : 0,
);

const virtualBottomSpacerPx = computed(() =>
  virtualEnabled.value ? virtualWindow.value.bottom : 0,
);

const messageListBottomPadding = computed(() =>
  Math.max(
    MESSAGE_LIST_BOTTOM_SAFE_PADDING,
    Math.ceil(props.bottomInset ?? MESSAGE_LIST_BOTTOM_SAFE_PADDING),
  ),
);

const messageListTopPadding = computed(
  () => MESSAGE_LIST_TOP_PADDING + shortTimelineTopSpacerPx.value,
);

function shouldShowTime(previous: number, current: number): boolean {
  if (!current) return false;
  if (!previous) return true;
  const prevDate = new Date(previous);
  const curDate = new Date(current);
  if (prevDate.toDateString() !== curDate.toDateString()) return true;
  return current - previous > 5 * 60_000;
}

function isSystemTimelineMessage(message: MessageLike | undefined): boolean {
  const type = message?.content?.contentType;
  return type === "system" || type === "notification";
}

function isSameSenderGroup(
  previous: MessageLike | undefined,
  current: MessageLike | undefined,
): boolean {
  if (!previous || !current) return false;
  if (isSystemTimelineMessage(previous) || isSystemTimelineMessage(current)) {
    return false;
  }
  const senderId = previous.senderId?.trim();
  if (!senderId || senderId !== current.senderId?.trim()) return false;
  const previousTs = Number(previous.createdAt || previous.clientCreatedAt || 0);
  const currentTs = Number(current.createdAt || current.clientCreatedAt || 0);
  return !shouldShowTime(previousTs, currentTs);
}

function timeLabel(timestamp: number): string {
  const date = new Date(timestamp);
  const now = Date.now();
  const diffMs = Math.max(0, now - timestamp);
  if (diffMs < 60_000) return "Just now";
  if (diffMs < 60 * 60_000) {
    return `${Math.floor(diffMs / 60_000)} min ago`;
  }

  const today = new Date(now);
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);
  const time = date.toLocaleTimeString("zh-CN", {
    hour: "2-digit",
    minute: "2-digit",
  });
  if (date.toDateString() === today.toDateString()) return time;
  if (date.toDateString() === yesterday.toDateString()) return `Yesterday ${time}`;
  const datePart =
    date.getFullYear() === today.getFullYear()
      ? `${date.getMonth() + 1}/${date.getDate()}`
      : `${date.getFullYear()}/${date.getMonth() + 1}/${date.getDate()}`;
  return `${datePart} ${time}`;
}

function getScrollContainer(): HTMLElement | null {
  return scrollContainerRef.value;
}

function getScrollContent(): HTMLElement | null {
  return scrollContentRef.value;
}

function updateVirtualViewport(root?: HTMLElement | null): void {
  const el = root ?? getScrollContainer();
  if (!el) return;
  virtualScrollTopPx.value = el.scrollTop;
  virtualViewportHeightPx.value = el.clientHeight;
}

function updateShortTimelineSpacer(): void {
  const root = getScrollContainer();
  const content = getScrollContent();
  if (!root || !content || timelineRows.value.length === 0 || virtualEnabled.value) {
    shortTimelineTopSpacerPx.value = 0;
    return;
  }

  const topPadding = messageListTopPadding.value;
  const bottomPadding = messageListBottomPadding.value;
  const contentHeight = Math.max(
    content.scrollHeight,
    content.getBoundingClientRect().height,
  );
  const rowsHeight = Math.max(0, contentHeight - topPadding - bottomPadding);
  const nextSpacer = Math.max(
    0,
    Math.floor(
      root.clientHeight -
        rowsHeight -
        MESSAGE_LIST_TOP_PADDING -
        bottomPadding,
    ),
  );

  if (Math.abs(nextSpacer - shortTimelineTopSpacerPx.value) > 1) {
    shortTimelineTopSpacerPx.value = nextSpacer;
  }
}

function scheduleShortTimelineMeasure(): void {
  const measure = () => updateShortTimelineSpacer();
  scheduleTimer(measure, 80);
  scheduleTimer(measure, 220);
  scheduleTimer(measure, 520);
}

function forceScrollContainerToBottom(): void {
  updateShortTimelineSpacer();
  const root = getScrollContainer();
  if (!root) return;
  root.scrollTop = Math.max(0, root.scrollHeight - root.clientHeight);
}

function isNearBottom(el: HTMLElement): boolean {
  return el.scrollHeight - el.scrollTop - el.clientHeight <= BOTTOM_STICKY_PX;
}

function isResizeNearBottom(el: HTMLElement): boolean {
  return el.scrollHeight - el.scrollTop - el.clientHeight <= RESIZE_STICKY_PX;
}

function clearBrowseAnchor(): void {
  anchorTailId.value = null;
}

function cancelPendingBottomScroll(): void {
  bottomScrollGeneration += 1;
}

function enableTailFollow(): void {
  followTail.value = true;
  clearBrowseAnchor();
}

function captureBrowseAnchor(): void {
  const list = displayMessages.value;
  const last = list[list.length - 1];
  anchorTailId.value = last ? timelineKey(last) : null;
}

function enterBrowseMode(): void {
  followTail.value = false;
  cancelPendingBottomScroll();
  if (!anchorTailId.value) {
    captureBrowseAnchor();
  }
}

const pendingBelowCount = computed(() => {
  if (isAtBottom.value || !anchorTailId.value) return 0;
  const list = displayMessages.value;
  let anchorIndex = -1;
  for (let i = list.length - 1; i >= 0; i -= 1) {
    if (timelineKey(list[i]) === anchorTailId.value) {
      anchorIndex = i;
      break;
    }
  }
  if (anchorIndex === -1) return 0;
  return list.length - 1 - anchorIndex;
});

const showNewMessagesButton = computed(() => pendingBelowCount.value > 0);

const showHistoryStartHint = computed(
  () =>
    historyStartHintVisible.value &&
    !props.loadingOlder &&
    !props.hasOlder &&
    displayMessages.value.length > 0,
);

const newMessagesButtonLabel = computed(() => {
  const count = pendingBelowCount.value;
  if (count > 99) return t("chat.newMessagesCount", { count: "99+" });
  if (count > 1) return t("chat.newMessagesCount", { count });
  return t("chat.newMessages");
});

function syncAtBottomState(el?: HTMLElement | null): void {
  const root = el ?? getScrollContainer();
  if (!root) return;
  const next = isNearBottom(root);
  const changed = next !== isAtBottom.value;
  isAtBottom.value = next;
  if (next) {
    enableTailFollow();
  } else {
    enterBrowseMode();
  }
  if (changed) emit("atBottomChange", next);
}

function onScroll(event: Event): void {
  const root = event.target as HTMLElement;
  updateVirtualViewport(root);
  syncAtBottomState(root);
  const reachedTop = root.scrollTop <= 72;
  if (!reachedTop) {
    if (root.scrollTop > 120) {
      historyStartHintVisible.value = false;
    }
    return;
  }
  if (!props.loadingOlder && !props.hasOlder && displayMessages.value.length > 0) {
    historyStartHintVisible.value = true;
    return;
  }
  if (!loadOlderRequested) {
    loadOlderRequested = true;
    capturePrependAnchor(root);
    emit("load-older");
    scheduleTimer(() => {
      loadOlderRequested = false;
    }, 600);
  }
}

function scheduleTimer(fn: () => void, ms: number): void {
  const timer = window.setTimeout(() => {
    pendingTimers.delete(timer);
    fn();
  }, ms);
  pendingTimers.add(timer);
}

function shouldAutoScrollForBatch(batch: readonly MessageLike[]): boolean {
  if (!batch.length) return false;
  return batch.some((message) => message.senderId === props.currentUserId);
}

function shouldFollowAppendedBatch(batch: readonly MessageLike[]): boolean {
  return followTail.value || isAtBottom.value || shouldAutoScrollForBatch(batch);
}

function capturePrependAnchor(root?: HTMLElement | null): void {
  const el = root ?? getScrollContainer();
  if (!el) return;
  enterBrowseMode();
  pendingPrependAnchor = {
    scrollTop: el.scrollTop,
    scrollHeight: el.scrollHeight,
  };
}

function restorePrependAnchorPosition(snapshot: ScrollAnchorSnapshot): void {
  const root = getScrollContainer();
  if (!root) return;
  root.scrollTop = restorePrependScrollTop(snapshot, root.scrollHeight);
  syncAtBottomState(root);
}

async function preservePrependAnchor(): Promise<void> {
  const snapshot = pendingPrependAnchor;
  pendingPrependAnchor = null;
  if (!snapshot) return;
  preservingPrependAnchor = true;
  await nextTick();
  await nextTick();
  updateShortTimelineSpacer();
  restorePrependAnchorPosition(snapshot);
  await new Promise<void>((resolve) => {
    requestAnimationFrame(() => {
      updateShortTimelineSpacer();
      restorePrependAnchorPosition(snapshot);
      requestAnimationFrame(() => {
        updateShortTimelineSpacer();
        restorePrependAnchorPosition(snapshot);
        resolve();
      });
    });
  });
  scheduleTimer(() => {
    updateShortTimelineSpacer();
    restorePrependAnchorPosition(snapshot);
  }, 90);
  scheduleTimer(() => {
    updateShortTimelineSpacer();
    restorePrependAnchorPosition(snapshot);
    preservingPrependAnchor = false;
  }, 260);
}

function countAppendedMessages(
  prev: readonly MessageLike[],
  next: readonly MessageLike[],
): number {
  return countAppendedItems(prev, next, timelineKey);
}

function countPrependedMessages(
  prev: readonly MessageLike[],
  next: readonly MessageLike[],
): number {
  return countPrependedItems(prev, next, timelineKey);
}

function messageTailSignature(message: MessageLike | undefined): string {
  if (!message) return "";
  return [
    timelineKey(message),
    message.senderId,
    message.conversationSeq || "",
    message.createdAt || message.clientCreatedAt || 0,
    message.localState?.sending ? "sending" : "settled",
    JSON.stringify(message.content ?? {}),
  ].join(":");
}

async function scrollToBottom(): Promise<void> {
  const generation = ++bottomScrollGeneration;
  const scrollLast = () => {
    if (generation !== bottomScrollGeneration) return;
    updateShortTimelineSpacer();
    forceScrollContainerToBottom();
  };

  await nextTick();
  await nextTick();
  updateShortTimelineSpacer();
  scrollLast();
  await new Promise<void>((resolve) => {
    requestAnimationFrame(() => {
      scrollLast();
      requestAnimationFrame(() => {
        scrollLast();
        resolve();
      });
    });
  });
  if (generation !== bottomScrollGeneration) return;
  scheduleTimer(scrollLast, 80);
  scheduleTimer(() => {
    if (generation !== bottomScrollGeneration) return;
    scrollLast();
    syncAtBottomState(getScrollContainer() ?? null);
  }, 200);
  scheduleTimer(scrollLast, 420);
  scheduleTimer(scrollLast, 760);
  scheduleShortTimelineMeasure();
  if (generation !== bottomScrollGeneration) return;
  enableTailFollow();
  isAtBottom.value = true;
  emit("atBottomChange", true);
}

function escapeSelectorValue(value: string): string {
  if (typeof CSS !== "undefined" && CSS.escape) return CSS.escape(value);
  return value.replace(/["\\]/g, "\\$&");
}

async function scrollToMessage(
  targetMessageId: string,
  smooth = true,
): Promise<boolean> {
  await nextTick();
  const targetId = String(targetMessageId ?? "").trim();
  if (!targetId) return false;
  const targetIndex = virtualItems.value.findIndex(
    (item) => item.kind === "message" && messageActionId(item.message) === targetId,
  );
  if (targetIndex < 0) {
    const fullIndex = timelineRows.value.findIndex(
      (item) => item.kind === "message" && messageActionId(item.message) === targetId,
    );
    const root = getScrollContainer();
    if (fullIndex < 0 || !root) return false;
    const offsets = virtualOffsets.value;
    root.scrollTop = Math.max(
      0,
      (offsets[fullIndex] ?? 0) - Math.floor(root.clientHeight / 2),
    );
    updateVirtualViewport(root);
    await nextTick();
  }
  await nextTick();
  const root = getScrollContainer();
  const el = root?.querySelector<HTMLElement>(
    `[data-message-id="${escapeSelectorValue(targetId)}"]`,
  );
  if (!el) return false;
  el.scrollIntoView({ block: "center", behavior: smooth ? "smooth" : "auto" });
  el.classList.remove("message-row--locating");
  void el.offsetWidth;
  el.classList.add("message-row--locating");
  scheduleTimer(() => {
    el.classList.remove("message-row--locating");
  }, 1600);
  return true;
}

async function handleMessagesGrowth(
  prev: readonly MessageLike[],
  next: readonly MessageLike[],
): Promise<void> {
  const prepended = countPrependedMessages(prev, next);
  const appended = countAppendedMessages(prev, next);
  if (prepended > 0) {
    const hasPrependAnchor = Boolean(pendingPrependAnchor);
    await preservePrependAnchor();
    if (!hasPrependAnchor && (followTail.value || isAtBottom.value)) {
      await scrollToBottom();
      return;
    }
    if (appended > 0) {
      syncAtBottomState(getScrollContainer() ?? null);
    }
    return;
  }

  if (appended <= 0) return;

  await nextTick();
  const batch = next.slice(-appended);
  if (shouldFollowAppendedBatch(batch)) {
    await scrollToBottom();
    return;
  }
  enterBrowseMode();
  syncAtBottomState(getScrollContainer() ?? null);
}

watch(
  () => props.conversationId,
  async (conversationId, previousConversationId) => {
    if (!conversationId || conversationId === previousConversationId) return;
    enableTailFollow();
    historyStartHintVisible.value = false;
    isAtBottom.value = true;
    await nextTick();
    await scrollToBottom();
  },
  { flush: "post" },
);

watch(
  () => displayMessages.value,
  async (next, prev) => {
    const previous = prev ?? [];
    await nextTick();
    updateShortTimelineSpacer();
    if (previous.length === 0 && next.length > 0) {
      await scrollToBottom();
      return;
    }
    await handleMessagesGrowth(previous, next);
  },
  { deep: false },
);

watch(
  () => displayMessages.value.length,
  async (length, prevLength) => {
    if (length === 0) {
      clearBrowseAnchor();
      shortTimelineTopSpacerPx.value = 0;
      return;
    }
    if (length > 0 && (prevLength ?? 0) === 0) {
      await scrollToBottom();
    }
  },
);

watch(
  () => {
    const list = displayMessages.value;
    return messageTailSignature(list[list.length - 1]);
  },
  async (nextKey, prevKey) => {
    if (!nextKey || nextKey === prevKey) return;
    const list = displayMessages.value;
    const last = list[list.length - 1];
    if (followTail.value || isAtBottom.value || last?.senderId === props.currentUserId) {
      await scrollToBottom();
    }
  },
);

watch(
  [() => props.hasOlder, () => props.loadingOlder],
  () => {
    if (props.hasOlder) {
      historyStartHintVisible.value = false;
      return;
    }
    const root = getScrollContainer();
    if (
      root &&
      root.scrollTop <= 72 &&
      !props.loadingOlder &&
      displayMessages.value.length > 0
    ) {
      historyStartHintVisible.value = true;
    }
  },
);

onMounted(() => {
  updateVirtualViewport();
  if (displayMessages.value.length > 0) {
    void scrollToBottom();
  }
  const root = getScrollContainer();
  if (root && typeof ResizeObserver !== "undefined") {
    listResizeObserver = new ResizeObserver(() => {
      updateVirtualViewport(root);
      updateShortTimelineSpacer();
      if (preservingPrependAnchor) return;
      if (followTail.value || isAtBottom.value || isResizeNearBottom(root)) {
        void scrollToBottom();
      }
    });
    listResizeObserver.observe(root);
  }
});

onBeforeUnmount(() => {
  listResizeObserver?.disconnect();
  listResizeObserver = null;
  pendingTimers.forEach((timer) => window.clearTimeout(timer));
  pendingTimers.clear();
});

defineExpose({
  scrollToBottom,
  scrollToMessage,
  isAtBottom,
  followTail,
});
</script>

<template>
  <div class="message-list-root" role="log">
    <div v-if="loadingOlder" class="message-list-load-older" aria-live="polite">
      <span class="runtime-status-dot runtime-status-dot--busy" />
      {{ t("chat.loadOlder") }}
    </div>
    <div
      v-else-if="showHistoryStartHint"
      class="message-list-history-end"
      aria-live="polite"
    >
      {{ t("chat.noMoreMessages") }}
    </div>
    <div
      ref="scrollContainerRef"
      class="message-list message-list-virtual"
      @scroll="onScroll"
    >
      <div
        ref="scrollContentRef"
        class="message-list-content"
        :style="{
          paddingTop: `${messageListTopPadding}px`,
          paddingBottom: `${messageListBottomPadding}px`,
        }"
      >
        <div
          v-if="virtualTopSpacerPx > 0"
          aria-hidden="true"
          class="message-list-virtual-spacer"
          :style="{ height: `${virtualTopSpacerPx}px` }"
        />
        <template v-for="item in virtualItems" :key="item.key">
          <TimeStamp v-if="item.kind === 'time'" :label="item.label" />
          <MessageBubble
            v-else
            :message="item.message"
            :current-user-id="currentUserId"
            :self="item.message.senderId === currentUserId"
            :multi-select-mode="multiSelectMode"
            :selected="selectedIds?.includes(messageActionId(item.message))"
            :menu-config="menuConfig"
            :media-download-state="mediaDownloadStates?.[messageActionId(item.message)] ?? 'idle'"
            :conversation-type="conversationType"
            :group-start="item.groupStart"
            :group-end="item.groupEnd"
            :fresh="freshIds.has(messageActionId(item.message))"
            @react="(id: string, emoji: string) => $emit('react', id, emoji)"
            @edit="$emit('edit', $event)"
            @delete="$emit('delete', $event)"
            @pin="(id: string, pinned: boolean, scope: 'conversation' | 'self') => $emit('pin', id, pinned, scope)"
            @mark="$emit('mark', $event)"
            @preview="$emit('preview', $event)"
            @media-action="(id: string, action: 'download' | 'openFolder') => $emit('mediaAction', id, action)"
            @reply="$emit('reply', $event)"
            @forward="$emit('forward', $event)"
            @recall="$emit('recall', $event)"
            @resend="$emit('resend', $event)"
            @multi-select="$emit('multiSelect', $event)"
            @toggle-select="$emit('toggle-select', $event)"
            @locate-message="$emit('locate-message', $event)"
          />
        </template>
        <div
          v-if="virtualBottomSpacerPx > 0"
          aria-hidden="true"
          class="message-list-virtual-spacer"
          :style="{ height: `${virtualBottomSpacerPx}px` }"
        />
      </div>
    </div>
    <Transition name="message-list-scroll-bottom-fade">
      <button
        v-if="showNewMessagesButton"
        type="button"
        class="message-list-scroll-bottom"
        :aria-label="newMessagesButtonLabel"
        @click="scrollToBottom"
      >
        <span class="message-list-scroll-bottom__icon" aria-hidden="true"
          ><FlareIcon name="arrow-down" :size="16" /></span
        >
        {{ newMessagesButtonLabel }}
      </button>
    </Transition>
  </div>
</template>
