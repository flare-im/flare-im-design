<script setup lang="ts">
import {
  computed,
  getCurrentInstance,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from "vue";
import type { FlareConversationKind } from "../../shared/contracts/conversation";
import MessageBubble from "./MessageBubble.vue";
import FlareDatePill from "./FlareDatePill.vue";
import FlareScrollToLatest from "./FlareScrollToLatest.vue";
import FlareUnreadDivider from "./FlareUnreadDivider.vue";
import TimelineGalleryPreview from "./TimelineGalleryPreview.vue";
import { provideTimelineImageGallery } from "./timelineImageGallery";
import { TIMELINE_FOCUS_KEYS, messageTakesFocus, provideTimelineFocus } from "./timelineFocus";
import type { MessageLike, MessageMediaDownloadUiState } from "./MessageBubble.vue";
import { mergeMessageMenuConfig, unhandledMessageMenuActions, type MessageMenuConfig } from "../../shared/config/messageMenu";
import { messageMatchesId, resolveMessageId } from "../../shared/contracts/messageRow";
import type { MessageMenuExtension } from "../../utils/buildMessageMenuOptions";
import { startsTimelineDay, timelineDateLabel } from "../../shared/timeline-label";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { previewTextFromMessageContent } from "../../utils/messagePreview";
import {
  countAppendedItems,
  countPrependedItems,
  normalizeMessageRowsForVirtualList,
  restorePrependScrollTop,
  type ScrollAnchorSnapshot,
} from "../../utils";
import {
  messageGroupPosition,
  messageRowPresentation,
  type FlareMessageGroupPosition,
  type FlareMessageRowPresentation,
} from "../../shared/contracts/message-grouping";

const BOTTOM_STICKY_PX = 80;
const RESIZE_STICKY_PX = 420;
const MESSAGE_LIST_TOP_PADDING = 22;
/** How long the start-of-history hint stays; it floats where the first date separator sits. */
const HISTORY_START_HINT_MS = 2400;
const MESSAGE_LIST_BOTTOM_SAFE_PADDING = 18;
// The current virtual window uses fixed row-height estimates, while chat rows
// can contain rich text, media, and quoted content. Keep loaded timelines on
// native layout so paging changes the scrollbar from real DOM height.
const VIRTUALIZATION_THRESHOLD = 25_000;
const VIRTUAL_OVERSCAN_PX = 1400;
const ESTIMATED_MESSAGE_ROW_PX = 76;
const ESTIMATED_TIME_ROW_PX = 34;
const ESTIMATED_UNREAD_ROW_PX = 34;

const props = withDefaults(defineProps<{
  conversationId?: string;
  conversationKind?: FlareConversationKind;
  messages: readonly MessageLike[];
  currentUserId: string;
  multiSelectMode?: boolean;
  selectedIds?: readonly string[];
  loadingOlder?: boolean;
  olderError?: string;
  loadOlderText?: string;
  hasOlder: boolean;
  bottomInset?: number;
  menuConfig?: MessageMenuConfig;
  /**
   * Host actions (report, translate, ...) listed in every message menu, filtered per message by
   * `available`; selecting one emits `action` with the action id and the message id.
   */
  actions?: readonly MessageMenuExtension[];
  mediaDownloadStates?: Record<string, MessageMediaDownloadUiState>;
  showIncomingAvatar?: boolean;
  showSelfAvatar?: boolean;
  showGroupSenderName?: boolean;
  /**
   * Id (`resolveMessageId`) of the first unread message. The list draws the unread
   * divider above it, counting the messages from others below; keep it fixed while
   * the conversation stays open.
   */
  unreadFromId?: string;
}>(), {
  showIncomingAvatar: true,
  showSelfAvatar: false,
  showGroupSenderName: true,
});

const { t, locale } = useFlareI18n();

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
  (event: "action", actionId: string, messageId: string): void;
  /** After Copy: `copied` is false when the clipboard refused the text. */
  (event: "copy", messageId: string, copied: boolean): void;
  /** A tapped poll option, by its index. Without a listener polls are read-only. */
  (event: "vote", messageId: string, optionIndex: number): void;
  /** A tapped task checkbox, with the done state asked for. Without a listener tasks are read-only. */
  (event: "taskToggle", messageId: string, done: boolean): void;
}>();

const instance = getCurrentInstance();
// Host policy first, then the handled-intent mask: an entry with no listener is never offered.
const effectiveMenuConfig = computed(() =>
  mergeMessageMenuConfig(props.menuConfig, { actions: unhandledMessageMenuActions(instance?.vnode.props) }),
);
const effectiveActions = computed(() => (instance?.vnode.props?.onAction ? props.actions ?? [] : []));
// A poll or a task is a control only while the host takes its intent.
const bodyIntentListeners = computed(() => ({
  ...(instance?.vnode.props?.onVote
    ? { vote: (id: string, optionIndex: number) => emit("vote", id, optionIndex) }
    : {}),
  ...(instance?.vnode.props?.onTaskToggle
    ? { taskToggle: (id: string, done: boolean) => emit("taskToggle", id, done) }
    : {}),
}));

const scrollContainerRef = ref<HTMLElement | null>(null);
const footerRef = ref<HTMLElement | null>(null);
const isAtBottom = ref(true);
const followTail = ref(true);
const shortTimelineTopSpacerPx = ref(0);
const historyStartHintVisible = ref(false);
let historyStartHintTimer = 0;
/** Set once the hint has been shown for this visit to the top; cleared when the reader scrolls away. */
let historyStartHintShown = false;
const virtualScrollTopPx = ref(0);
const virtualViewportHeightPx = ref(0);
/** 离开底部时的最后一条消息 id，用于统计下方新增条数 */
const anchorTailId = ref<string | null>(null);
const pendingTimers = new Set<number>();
let loadOlderRequested = false;
let listResizeObserver: ResizeObserver | null = null;
let footerResizeObserver: ResizeObserver | null = null;
type ReadingAnchor = ScrollAnchorSnapshot & { messageId?: string; offset?: number; generation: number };
let anchorGeneration = 0;
let pendingPrependAnchor: ReadingAnchor | null = null;
let preservingPrependAnchor = false;
let bottomScrollGeneration = 0;

type TimelineRow =
  | { kind: "time"; key: string; label: string }
  | { kind: "unread"; key: string; count: number }
  | {
      kind: "message";
      key: string;
      message: MessageLike;
      groupPosition: FlareMessageGroupPosition;
      presentation: FlareMessageRowPresentation;
    };

function timelineKey(message: MessageLike): string {
  // A row keeps the client id it was optimistically inserted with after ACK. The
  // core's timelineKey deliberately switches to the authoritative server id, but
  // using that value as Vue's vnode key would destroy the live bubble (and an open
  // context menu) exactly when the ACK arrives. This is the same two-id contract
  // used by the Flutter, iOS and Compose lists: row id first, server id for core
  // actions/quote lookup.
  return resolveMessageId(message) || message.timelineKey;
}

const displayMessages = computed(() =>
  normalizeMessageRowsForVirtualList(props.messages),
);

// One message takes Tab: the one focus was last in while it is still listed, else the newest.
const focusedMessageId = ref("");
const keyboardTargetId = computed(() => {
  if (props.multiSelectMode) return "";
  const rows = displayMessages.value;
  const wanted = focusedMessageId.value;
  let newest = "";
  for (let index = rows.length - 1; index >= 0; index -= 1) {
    if (!messageTakesFocus(rows[index])) continue;
    const id = resolveMessageId(rows[index]);
    if (!wanted || id === wanted) return id;
    newest ||= id;
  }
  return newest;
});
// A picture tapped in the timeline opens the conversation's gallery (spec/image-gallery-vectors.json).
const imageGallery = provideTimelineImageGallery(() => props.messages);

provideTimelineFocus({
  target: keyboardTargetId,
  activate: (id) => {
    focusedMessageId.value = id;
  },
});

function onTimelineKeydown(event: KeyboardEvent): void {
  if (!TIMELINE_FOCUS_KEYS.has(event.key) || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
  const current = event.target as HTMLElement | null;
  const container = scrollContainerRef.value;
  if (!container || !current?.classList.contains("message-bubble--focusable")) return;
  const bubbles = Array.from(container.querySelectorAll<HTMLElement>(".message-bubble--focusable"));
  const index = bubbles.indexOf(current);
  if (index < 0) return;
  event.preventDefault();
  const nextIndex = event.key === "Home" ? 0
    : event.key === "End" ? bubbles.length - 1
      : index + (event.key === "ArrowUp" ? -1 : 1);
  const next = bubbles[nextIndex];
  if (!next || next === current) return;
  next.focus({ preventScroll: true });
  next.scrollIntoView({ block: "nearest" });
}

// One-shot entrance for messages that arrive at the tail (just sent/received) —
// NOT history prepends and NOT the initial mount, so the virtualized list never
// re-animates a bubble that merely scrolls back into view. Ids clear after the
// animation window.
const freshIds = ref<Set<string>>(new Set());
watch(
  () => props.messages,
  (next, prev) => {
    if (!prev || prev.length === 0 || next.length <= prev.length) return;
    const prevIds = new Set(prev.map((m) => resolveMessageId(m)));
    const appended: string[] = [];
    for (let index = next.length - 1; index >= 0; index -= 1) {
      const id = resolveMessageId(next[index]);
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
  const unreadIndex = props.unreadFromId
    ? messages.findIndex((message) => resolveMessageId(message) === props.unreadFromId)
    : -1;
  // Where a date separator goes: before the first message and wherever the day changes.
  const startsDay: boolean[] = [];
  let previousTs = 0;
  for (const message of messages) {
    const ts = Number(message.createdAt || message.clientCreatedAt || 0);
    startsDay.push(startsTimelineDay(previousTs, ts));
    previousTs = ts || previousTs;
  }
  // A sender run ends at a date separator and at the unread divider.
  const dividerBefore = (index: number) => index === unreadIndex || (index > 0 && startsDay[index] === true);
  for (let index = 0; index < messages.length; index += 1) {
    const message = messages[index];
    const ts = Number(message.createdAt || message.clientCreatedAt || 0);
    // The day comes first, then where the unread messages start inside it.
    if (startsDay[index]) {
      rows.push({
        kind: "time",
        key: `time-${timelineKey(message)}`,
        label: timeLabel(ts),
      });
    }
    if (index === unreadIndex) {
      rows.push({
        kind: "unread",
        key: `unread-${timelineKey(message)}`,
        count: messages.slice(index).filter((item) => item.senderId !== props.currentUserId).length,
      });
    }
    const groupPosition = breakRunAtDividers(messageGroupPosition(messages, index), dividerBefore(index), dividerBefore(index + 1));
    rows.push({
      kind: "message",
      key: timelineKey(message),
      message,
      groupPosition,
      presentation: messageRowPresentation(
        message,
        groupPosition,
        props.currentUserId,
        props.conversationKind,
        {
          showIncomingAvatar: props.showIncomingAvatar,
          showSelfAvatar: props.showSelfAvatar,
          showGroupSenderName: props.showGroupSenderName,
        },
      ),
    });
  }
  return rows;
});

/** The unread divider ends a sender run: the row above closes it and the first unread row opens a new one. */
/** A divider right before a message starts a new run there; one right after ends the run. */
function breakRunAtDividers(position: FlareMessageGroupPosition, dividerBefore: boolean, dividerAfter: boolean): FlareMessageGroupPosition {
  let next = position;
  if (dividerBefore) next = next === "middle" ? "first" : next === "last" ? "single" : next;
  if (dividerAfter) next = next === "middle" ? "last" : next === "first" ? "single" : next;
  return next;
}

function estimatedRowHeight(row: TimelineRow): number {
  if (row.kind === "time") return ESTIMATED_TIME_ROW_PX;
  return row.kind === "unread" ? ESTIMATED_UNREAD_ROW_PX : ESTIMATED_MESSAGE_ROW_PX;
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

function timeLabel(timestamp: number): string {
  return timelineDateLabel(timestamp, locale.value, { today: t("timeline.today"), yesterday: t("timeline.yesterday") });
}

function getScrollContainer(): HTMLElement | null {
  return scrollContainerRef.value;
}

function updateVirtualViewport(root?: HTMLElement | null): void {
  const el = root ?? getScrollContainer();
  if (!el) return;
  virtualScrollTopPx.value = el.scrollTop;
  virtualViewportHeightPx.value = el.clientHeight;
}

function updateShortTimelineSpacer(): void {
  // Sparse timelines stay top anchored. Artificial bottom alignment made a
  // short conversation look detached from its header and changed on resize.
  shortTimelineTopSpacerPx.value = 0;
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

function hideHistoryStartHint(): void {
  window.clearTimeout(historyStartHintTimer);
  historyStartHintVisible.value = false;
  historyStartHintShown = false;
}

/**
 * Tells a reader who scrolled back to the start of a long history that nothing older
 * exists, once per visit to the top, then leaves so it does not keep covering the first
 * date separator. A timeline that fits on screen gets no hint: its first message is in view.
 */
function revealHistoryStartHint(root: HTMLElement): void {
  if (historyStartHintShown || root.scrollHeight <= root.clientHeight + 1) return;
  historyStartHintShown = true;
  historyStartHintVisible.value = true;
  window.clearTimeout(historyStartHintTimer);
  historyStartHintTimer = window.setTimeout(() => {
    historyStartHintVisible.value = false;
  }, HISTORY_START_HINT_MS);
}

function onScroll(event: Event): void {
  const root = event.target as HTMLElement;
  updateVirtualViewport(root);
  syncAtBottomState(root);
  const reachedTop = root.scrollTop <= 72;
  if (!reachedTop) {
    if (root.scrollTop > 120) {
      hideHistoryStartHint();
    }
    return;
  }
  if (!props.loadingOlder && !props.hasOlder && displayMessages.value.length > 0) {
    revealHistoryStartHint(root);
    return;
  }
  requestOlder(false);
}

function requestOlder(retry = false): void {
  if (loadOlderRequested || props.loadingOlder || !props.hasOlder || (!retry && props.olderError)) return;
  loadOlderRequested = true;
  capturePrependAnchor();
  emit("load-older");
}

function cancelAnchorRestore(): void {
  anchorGeneration += 1;
  pendingPrependAnchor = null;
  preservingPrependAnchor = false;
}

/**
 * The mark a located row wears (`spec/locate-highlight-vectors.json`): one row at a time, for one
 * window. A second locate inside that window clears the first at once — two marked rows would say
 * the jump landed twice. The window is the table's; the ring itself is drawn by
 * `.message-row--locating` in `chat/message-bubble.css`, which holds the same three stops.
 */
const LOCATE_HIGHLIGHT_MS = 1600;
let locatedEl: HTMLElement | null = null;

function clearLocated(): void {
  locatedEl?.classList.remove("message-row--locating");
  locatedEl = null;
}

/**
 * What a screen reader is told when a jump lands. The ring tells everyone else; a reader who cannot see
 * it gets the same fact in words — which row, and what it says — from the one summary a reply strip
 * would show, so the message reads the same wherever it is named.
 */
const locateAnnouncement = ref("");

function announceLocated(message: MessageLike): void {
  const sender = String(message.senderDisplayName ?? "").trim() || t("quote.originalMessage");
  const summary = previewTextFromMessageContent(message.content, locale.value).trim()
    || t("preview.message");
  // Repeating the same string leaves a live region silent, so it is cleared first.
  locateAnnouncement.value = "";
  void nextTick(() => {
    locateAnnouncement.value = t("quote.jumpedTo", { sender, summary });
  });
}

/**
 * Takes the reading cursor to the row the jump landed on. The timeline already keeps one message in the
 * Tab sequence at a time (roving tabindex), so this moves within a model the list already has rather than
 * inventing one; a pointer-driven jump shows no focus ring, because a programmatic focus does not match
 * `:focus-visible`. A row that cannot take focus — a notice, a recalled message — keeps the cursor where
 * it was, and the announcement is then the whole answer.
 */
function focusLocated(el: HTMLElement, message: MessageLike): void {
  if (!messageTakesFocus(message)) return;
  focusedMessageId.value = resolveMessageId(message);
  void nextTick(() => {
    el.querySelector<HTMLElement>(".message-bubble--focusable")?.focus();
  });
}

function markLocated(el: HTMLElement, message: MessageLike): void {
  announceLocated(message);
  focusLocated(el, message);
  clearLocated();
  locatedEl = el;
  // Restart the animation when the same row is located twice in a row.
  void el.offsetWidth;
  el.classList.add("message-row--locating");
  scheduleTimer(() => {
    if (locatedEl === el) clearLocated();
  }, LOCATE_HIGHLIGHT_MS);
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
  const bounds = el.getBoundingClientRect();
  const row = Array.from(el.querySelectorAll<HTMLElement>('[data-message-id]'))
    .find(row => row.getBoundingClientRect().bottom > bounds.top && row.getBoundingClientRect().top < bounds.bottom);
  pendingPrependAnchor = {
    messageId: row?.dataset.messageId,
    offset: row ? row.getBoundingClientRect().top - bounds.top : undefined,
    generation: ++anchorGeneration,
    scrollTop: el.scrollTop,
    scrollHeight: el.scrollHeight,
  };
}

function restorePrependAnchorPosition(snapshot: ReadingAnchor): void {
  if (snapshot.generation !== anchorGeneration) return;
  const root = getScrollContainer();
  if (!root) return;
  const row = snapshot.messageId ? root.querySelector<HTMLElement>(`[data-message-id="${escapeSelectorValue(snapshot.messageId)}"]`) : null;
  root.scrollTop = row && snapshot.offset !== undefined
    ? root.scrollTop + row.getBoundingClientRect().top - root.getBoundingClientRect().top - snapshot.offset
    : restorePrependScrollTop(snapshot, root.scrollHeight);
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

/**
 * A tap on a quote. The list shows the message itself when it is drawing it — the same jump a host
 * would ask for — and only asks the host (`locate-message`) for one it does not have, which is the
 * case that needs history read. The three native kits split it the same way.
 */
function onLocateMessage(messageId: string): void {
  const id = String(messageId ?? "").trim();
  if (!id) return;
  if (locatableRow(id)) void scrollToMessage(id);
  else emit("locate-message", id);
}

/**
 * Will tapping this message's quote do anything? Either the list is drawing the quoted message, or
 * the host listens for the ones it is not. A quote that can reach neither is text, not a control.
 */
function quoteLocatable(message: MessageLike): boolean {
  const quoted = String((message.content as { quote?: { quotedMessageId?: unknown } } | undefined)?.quote?.quotedMessageId
    ?? (message.content as { quotedMessageId?: unknown } | undefined)?.quotedMessageId ?? "").trim();
  if (!quoted) return false;
  return locatableRow(quoted) || Boolean(instance?.vnode.props?.onLocateMessage);
}

/** Is `id` a row this list is drawing (by the row's own id or the core's id for it)? */
function locatableRow(id: string): boolean {
  return timelineRows.value.some((item) => item.kind === "message" && messageMatchesId(item.message, id));
}

async function scrollToMessage(
  targetMessageId: string,
  smooth = true,
): Promise<boolean> {
  const askedId = String(targetMessageId ?? "").trim();
  if (!askedId) return false;
  // A locate intent may name the row's own id or the core's id for it (a quote carries the latter),
  // so the row is found by either and then addressed by the id it is drawn with.
  const row = timelineRows.value.find((item) => item.kind === "message" && messageMatchesId(item.message, askedId));
  if (!row || row.kind !== "message") return false;
  const targetId = resolveMessageId(row.message);
  // Locating a message is reading history: stop following the tail and cancel the re-scrolls a
  // just-opened conversation scheduled, or they pull the view back to the bottom within 760 ms.
  enterBrowseMode();
  await nextTick();
  const targetIndex = virtualItems.value.findIndex(
    (item) => item.kind === "message" && resolveMessageId(item.message) === targetId,
  );
  if (targetIndex < 0) {
    const fullIndex = timelineRows.value.findIndex(
      (item) => item.kind === "message" && resolveMessageId(item.message) === targetId,
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
  markLocated(el, row.message);
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
    if (conversationId === previousConversationId) return;
    cancelAnchorRestore();
    loadOlderRequested = false;
    cancelPendingBottomScroll();
    enableTailFollow();
    hideHistoryStartHint();
    isAtBottom.value = true;
    await nextTick();
    await scrollToBottom();
  },
  { flush: "post" },
);

function timelineKeyOrEmpty(message: MessageLike | undefined): string { return message?.timelineKey ?? ""; }
watch([() => props.loadingOlder, () => props.olderError], ([loading, error], [wasLoading, oldError]) => {
  if ((wasLoading && !loading) || error !== oldError) loadOlderRequested = false;
});

watch(
  () => displayMessages.value,
  async (next, prev) => {
    const previous = prev ?? [];
    if (countPrependedMessages(previous, next) > 0 && !pendingPrependAnchor) capturePrependAnchor();
    if (timelineKeyOrEmpty(previous[0]) !== timelineKeyOrEmpty(next[0])) loadOlderRequested = false;
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
      hideHistoryStartHint();
      return;
    }
    const root = getScrollContainer();
    if (
      root &&
      root.scrollTop <= 72 &&
      !props.loadingOlder &&
      displayMessages.value.length > 0
    ) {
      revealHistoryStartHint(root);
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
    // A footer (typing row) that appears or grows keeps a reader at the latest message.
    footerResizeObserver = new ResizeObserver(() => {
      if (!preservingPrependAnchor && (followTail.value || isAtBottom.value)) void scrollToBottom();
    });
    if (footerRef.value) footerResizeObserver.observe(footerRef.value);
  }
});
watch(footerRef, (next, previous) => {
  if (previous) footerResizeObserver?.unobserve(previous);
  if (next) footerResizeObserver?.observe(next);
});

onBeforeUnmount(() => {
  cancelAnchorRestore();
  cancelPendingBottomScroll();
  listResizeObserver?.disconnect();
  listResizeObserver = null;
  footerResizeObserver?.disconnect();
  footerResizeObserver = null;
  pendingTimers.forEach((timer) => window.clearTimeout(timer));
  pendingTimers.clear();
  window.clearTimeout(historyStartHintTimer);
  clearLocated();
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
    <div v-else-if="hasOlder || olderError" class="message-list-pagination">
      <span v-if="olderError" role="status">{{ olderError }}</span>
      <button v-if="hasOlder" type="button" @click="requestOlder(true)">{{ loadOlderText || t("chat.loadOlder") }}</button>
    </div>
    <div
      v-else-if="showHistoryStartHint"
      class="message-list-history-end"
      aria-live="polite"
    >
      {{ t("chat.noMoreMessages") }}
    </div>
    <span class="message-list__locate-announcement" role="status" aria-live="polite">{{ locateAnnouncement }}</span>
    <div
      ref="scrollContainerRef"
      class="message-list message-list-virtual"
      @scroll="onScroll"
      @keydown="onTimelineKeydown"
      @wheel.passive="cancelAnchorRestore"
      @touchstart.passive="cancelAnchorRestore"
      @pointerdown="cancelAnchorRestore"
    >
      <div
        class="message-list-content"
        :class="{ 'message-list-content--empty': !displayMessages.length && $slots.empty }"
        :style="{
          paddingTop: `${messageListTopPadding}px`,
          paddingBottom: `${messageListBottomPadding}px`,
        }"
      >
        <slot name="header" />
        <div v-if="!displayMessages.length && $slots.empty" class="message-list-empty">
          <slot name="empty" />
        </div>
        <div
          v-if="virtualTopSpacerPx > 0"
          aria-hidden="true"
          class="message-list-virtual-spacer"
          :style="{ height: `${virtualTopSpacerPx}px` }"
        />
        <template v-for="item in virtualItems" :key="item.key">
          <FlareDatePill v-if="item.kind === 'time'" :label="item.label" />
          <slot v-else-if="item.kind === 'unread'" name="unread-divider" :count="item.count">
            <FlareUnreadDivider :count="item.count" />
          </slot>
          <MessageBubble
            v-else
            :message="item.message"
            :current-user-id="currentUserId"
            :self="item.message.senderId === currentUserId"
            :multi-select-mode="multiSelectMode"
            :selected="selectedIds?.includes(resolveMessageId(item.message))"
            :menu-config="effectiveMenuConfig"
            :actions="effectiveActions"
            :media-download-state="mediaDownloadStates?.[resolveMessageId(item.message)] ?? 'idle'"
            :conversation-kind="conversationKind"
            :group-position="item.groupPosition"
            :row-presentation="item.presentation"
            :fresh="freshIds.has(resolveMessageId(item.message))"
            :quote-locatable="quoteLocatable(item.message)"
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
            @locate-message="onLocateMessage"
            @action="(actionId: string, id: string) => $emit('action', actionId, id)"
            @copy="(id: string, copied: boolean) => $emit('copy', id, copied)"
            v-on="bodyIntentListeners"
          />
        </template>
        <div
          v-if="virtualBottomSpacerPx > 0"
          aria-hidden="true"
          class="message-list-virtual-spacer"
          :style="{ height: `${virtualBottomSpacerPx}px` }"
        />
        <div v-if="$slots.footer" ref="footerRef" class="message-list-footer">
          <slot name="footer" />
        </div>
      </div>
    </div>
    <Transition name="message-list-scroll-latest-fade">
      <div v-if="showNewMessagesButton" class="message-list-scroll-latest">
        <FlareScrollToLatest :count="pendingBelowCount" @click="scrollToBottom" />
      </div>
    </Transition>
    <TimelineGalleryPreview :gallery="imageGallery" />
  </div>
</template>

<style scoped>
/* Heard, never seen: the ring is the sighted half of the same fact. Clipped rather than hidden, because
   `display: none` and `visibility: hidden` take a live region out of the accessibility tree with it. */
.message-list__locate-announcement {
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

.message-list-content--empty { display: flex; flex-direction: column; box-sizing: border-box; min-height: 100%; }
.message-list-empty { display: grid; flex: 1; place-items: center; }
/* 版面在 design-system/styles/message-workspace.css 上，与另外两个顶部状态同一条带子。
   这里只留这一态独有的部分：它是三态中唯一可点的。 */
.message-list-pagination { flex-wrap: wrap; }
/* 文字按钮而不是描边盒子：描边圆角盒子与消息气泡是同一套表面语言，
   放在时间线顶部会被读成一条消息。触达区靠带子的 min-height 给满。 */
.message-list-pagination button { align-self: stretch; min-width: var(--flare-size-layout-touch-target); padding-inline: var(--flare-size-spacing-sm); color: var(--flare-color-primary-text); background: transparent; border: 0; font-size: inherit; font-weight: 600; cursor: pointer; }
/* 悬停只加下划线,不换色:--flare-color-primary 是「填充」色,暗色主题下它是深紫 #7047D6,
   而静息态用的 --flare-color-primary-text 在暗色下是浅紫 #A78BFA —— 拿填充色去画文字,
   一悬停就把可读的浅紫换成压在深底上的深紫。 */
.message-list-pagination button:hover { text-decoration: underline; }
.message-list-pagination button:focus-visible { outline: 2px solid var(--flare-color-border-selected); }
</style>
