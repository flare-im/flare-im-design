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
import { provideFlareRenderConversation, useFlareMessageRenderers } from "../../shared/message-renderers";
import type { MessageLike, MessageMediaDownloadUiState } from "./MessageBubble.vue";
import { mergeMessageMenuConfig, unhandledMessageMenuActions, type MessageMenuConfig } from "../../shared/config/messageMenu";
import { messageMatchesId, resolveMessageId } from "../../shared/contracts/messageRow";
import type { MessageMenuExtension } from "../../utils/buildMessageMenuOptions";
import { timelineDateLabel } from "../../shared/timeline-label";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareLocationValue } from "../../shared/contracts/location";
import { previewTextFromMessageContent } from "../../utils/messagePreview";
import {
  countAppendedItems,
  countPrependedItems,
  normalizeMessageRowsForVirtualList,
  restorePrependScrollTop,
  type ScrollAnchorSnapshot,
} from "../../utils";
import {
  flareTimelineRows,
  type FlareMessageGroupPosition,
  type FlareMessageRowPresentation,
} from "../../shared/contracts/message-grouping";
import type { FlareMessageSurface } from "../../shared/contracts/message-surface";
import { messageSurfaceOf } from "../../utils/messageSurface";
import {
  flareMessageListEdge,
  flareMessageListLatestEntry,
  flareMessageListRequests,
  flareMessageListWindowReplaced,
  type FlareMessageListEnd,
} from "./messageListPaging";

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
  /**
   * The window is detached from the latest messages (it was opened around a message): there is newer history
   * past its last row. The list then draws its newer end below the timeline, asks for newer pages as the reader
   * nears the bottom (`load-newer`) and offers the way back to the latest (`jump-to-latest`).
   */
  hasNewer?: boolean;
  loadingNewer?: boolean;
  newerError?: string;
  /**
   * The host's name for the window it hands the list (the core timeline view's `viewId`). When it changes from one
   * name to another the window was replaced as a whole, even where the two share rows: the list opens it at its
   * newest row, keeps nothing of the reader's place in the old one, and asks for no page by itself until the reader
   * moves it (`spec/message-list-paging-vectors.json` `windows`). Without it a window is replaced when no row is left
   * in common.
   */
  windowId?: string;
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
  /** The reader neared the bottom of a detached window, or tapped its load button: read the next newer page. */
  (event: "load-newer"): void;
  /** The back-to-latest key of a detached window: replace the window with the latest messages. */
  (event: "jump-to-latest"): void;
  (event: "locate-message", messageId: string): void;
  (event: "action", actionId: string, messageId: string): void;
  /** After Copy: `copied` is false when the clipboard refused the text. */
  (event: "copy", messageId: string, copied: boolean): void;
  /** A tapped poll option, by its index. Without a listener polls are read-only. */
  (event: "vote", messageId: string, optionIndex: number): void;
  /** A tapped task checkbox, with the done state asked for. Without a listener tasks are read-only. */
  (event: "taskToggle", messageId: string, done: boolean): void;
  /** A tapped person's card, with its user id: the host opens the profile. Without a listener cards only display. */
  (event: "cardOpen", messageId: string, userId: string): void;
  /** A tapped location card. Without a listener the card links to the web map of its provider. */
  (event: "locationOpen", messageId: string, location: FlareLocationValue): void;
  /** A tapped group read summary ("3 unread"): the host fills ReadReceiptSheet. Without a listener it is text. */
  (event: "readReceiptOpen", messageId: string): void;
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
  ...(instance?.vnode.props?.onCardOpen
    ? { cardOpen: (id: string, userId: string) => emit("cardOpen", id, userId) }
    : {}),
  ...(instance?.vnode.props?.onLocationOpen
    ? { locationOpen: (id: string, location: FlareLocationValue) => emit("locationOpen", id, location) }
    : {}),
  // Retry and the read summary are keys only while the host takes them.
  ...(instance?.vnode.props?.onResend ? { resend: (clientMsgId: string) => emit("resend", clientMsgId) } : {}),
  ...(instance?.vnode.props?.onReadReceiptOpen
    ? { readReceiptOpen: (id: string) => emit("readReceiptOpen", id) }
    : {}),
}));

/** Whether the host takes an intent: an end or a key with no listener is never offered and never asks. */
function listens(handler: "onLoadOlder" | "onLoadNewer" | "onJumpToLatest"): boolean {
  return Boolean(instance?.vnode.props?.[handler]);
}
// The two ends of the window (spec/message-list-paging-vectors.json): the same rule above and below the timeline.
const olderEnd = computed<FlareMessageListEnd>(() => ({
  has: props.hasOlder, loading: Boolean(props.loadingOlder), error: props.olderError, handled: listens("onLoadOlder"),
}));
const newerEnd = computed<FlareMessageListEnd>(() => ({
  has: Boolean(props.hasNewer), loading: Boolean(props.loadingNewer), error: props.newerError, handled: listens("onLoadNewer"),
}));
const olderEdge = computed(() => flareMessageListEdge(olderEnd.value));
const newerEdge = computed(() => flareMessageListEdge(newerEnd.value));
const newerBandShown = computed(() => newerEdge.value.spinner || newerEdge.value.error || newerEdge.value.button);

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
let loadNewerRequested = false;
/** The reader asked for the latest messages: the window the host replaces this one with opens at its bottom. */
let jumpToLatestRequested = false;
/**
 * Whether the window has been detached since each watcher last saw the rows change: rows appended then are a newer
 * page. Sticky, so a host that clears `hasNewer` a tick before it hands over the page that attached the window still
 * has that page kept in place.
 */
let rowsDetached = false;
let tailDetached = false;
/** The rows the tail watcher last saw, to tell a newer page from a message that arrived. */
let tailSeenMessages: readonly MessageLike[] = [];
let listResizeObserver: ResizeObserver | null = null;
let footerResizeObserver: ResizeObserver | null = null;
type ReadingAnchor = ScrollAnchorSnapshot & { messageId?: string; offset?: number; generation: number };
let anchorGeneration = 0;
let pendingPrependAnchor: ReadingAnchor | null = null;
let preservingPrependAnchor = false;
let bottomScrollGeneration = 0;
/**
 * The window was replaced and the reader has not moved since: the list asks for no page by itself. The scroll the
 * swap itself causes is not the reader's — a browser may leave the offset at 0 (Chromium does when the tapped quote
 * leaves with the old rows: focus fixup recalculates style, and inside the timeline's size container that lays it out
 * while it is empty) or at the new end — and neither is the list placing the window or a locate landing near an end.
 */
let requestsHeld = false;
/**
 * The row a locate took the reader to, until the reader moves: the list's own moves keep it where the locate put it —
 * a page that lands is anchored on it, and a resize does not pull the reader to the bottom.
 */
let locatedRowId: string | null = null;

type TimelineRow =
  | { kind: "time"; key: string; label: string }
  | { kind: "unread"; key: string; count: number }
  | {
      kind: "message";
      key: string;
      message: MessageLike;
      surface: FlareMessageSurface;
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
// Custom content renderers learn which conversation they draw in without each row carrying it.
provideFlareRenderConversation(() => props.conversationId);

provideTimelineFocus({
  target: keyboardTargetId,
  activate: (id) => {
    focusedMessageId.value = id;
  },
});

/** Keys that move a focused scroller or the reading cursor: the reader moving the list as much as a wheel is. */
const READER_SCROLL_KEYS: ReadonlySet<string> = new Set([...TIMELINE_FOCUS_KEYS, "PageUp", "PageDown", " "]);

function onTimelineKeydown(event: KeyboardEvent): void {
  if (READER_SCROLL_KEYS.has(event.key)) onReaderMoves();
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
    if (appended.length === next.length) return; // a window replaced as a whole is not news → skip
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

const messageRenderers = useFlareMessageRenderers();
// The rows (spec/message-grouping-vectors.json): date pills at each local day, the unread divider, and every message
// with its surface (C1), run position and presentation. The surface is decided here once so grouping and the bubble
// agree on it.
const timelineRows = computed<TimelineRow[]>(() => {
  const messages = displayMessages.value;
  const surfaces = messages.map((message) => messageSurfaceOf(message, messageRenderers));
  const layout = flareTimelineRows(
    messages.map((message, index) => ({
      id: resolveMessageId(message),
      senderId: message.senderId,
      atMs: Number(message.createdAt || message.clientCreatedAt || 0),
      surface: surfaces[index],
    })),
    {
      currentUserId: props.currentUserId,
      conversationKind: props.conversationKind,
      unreadFromId: props.unreadFromId,
      options: {
        showIncomingAvatar: props.showIncomingAvatar,
        showSelfAvatar: props.showSelfAvatar,
        showGroupSenderName: props.showGroupSenderName,
      },
    },
  );
  const rows: TimelineRow[] = [];
  let next = 0;
  for (const row of layout) {
    if (row.kind === "date") {
      const message = messages[next];
      rows.push({ kind: "time", key: `time-${timelineKey(message)}`, label: timeLabel(row.atMs) });
    } else if (row.kind === "unread") {
      rows.push({ kind: "unread", key: `unread-${timelineKey(messages[next])}`, count: row.count });
    } else {
      const message = messages[row.index];
      next = row.index + 1;
      rows.push({
        kind: "message",
        key: timelineKey(message),
        message,
        surface: surfaces[row.index],
        groupPosition: row.position,
        presentation: row.presentation,
      });
    }
  }
  return rows;
});

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

// The floating key: back to the latest messages for a detached window, else the count of new ones below.
const latestEntry = computed(() =>
  flareMessageListLatestEntry({
    hasNewer: Boolean(props.hasNewer),
    handled: listens("onJumpToLatest"),
    belowCount: pendingBelowCount.value,
  }),
);

function onLatestEntry(): void {
  if (latestEntry.value.action === "jumpToLatest") requestJumpToLatest();
  else void scrollToBottom();
}

function requestJumpToLatest(): void {
  jumpToLatestRequested = true;
  emit("jump-to-latest");
}

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
  // The bottom of a detached window is not the latest message: nothing arrives there to follow.
  if (next && !props.hasNewer) {
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
  if (root.scrollTop > 120) {
    hideHistoryStartHint();
  } else if (root.scrollTop <= 72 && !props.loadingOlder && !props.hasOlder && displayMessages.value.length > 0) {
    revealHistoryStartHint(root);
  }
  // Pages are asked for within the shared distance of either edge (spec/message-list-paging-vectors.json), once the
  // reader has moved a replaced window.
  if (requestsHeld) return;
  const wanted = flareMessageListRequests(
    { fromTop: root.scrollTop, fromBottom: Math.max(0, root.scrollHeight - root.scrollTop - root.clientHeight) },
    olderEnd.value,
    newerEnd.value,
  );
  if (wanted.older) requestOlder(false);
  if (wanted.newer) requestNewer(false);
}

function requestOlder(retry = false): void {
  if (loadOlderRequested || props.loadingOlder || !props.hasOlder || (!retry && props.olderError)) return;
  loadOlderRequested = true;
  capturePrependAnchor();
  emit("load-older");
}

/** Rows read in below the window grow under the reader, so nothing has to be anchored first. */
function requestNewer(retry = false): void {
  if (loadNewerRequested || props.loadingNewer || !props.hasNewer || (!retry && props.newerError)) return;
  loadNewerRequested = true;
  emit("load-newer");
}

function cancelAnchorRestore(): void {
  anchorGeneration += 1;
  pendingPrependAnchor = null;
  preservingPrependAnchor = false;
}

/** The reader moves the list (wheel, touch, pointer, key): their place is theirs again, and so is paging. */
function onReaderMoves(): void {
  requestsHeld = false;
  locatedRowId = null;
  cancelAnchorRestore();
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
  // Under a locate the located row is the anchor, at the place the locate puts it (the middle), even while the scroll
  // that takes it there is still running: the row on screen at this instant is only on the way.
  const located = locatedRowId
    ? el.querySelector<HTMLElement>(`[data-message-id="${escapeSelectorValue(locatedRowId)}"]`)
    : null;
  if (located) {
    pendingPrependAnchor = {
      messageId: locatedRowId!,
      offset: (el.clientHeight - located.getBoundingClientRect().height) / 2,
      generation: ++anchorGeneration,
      scrollTop: el.scrollTop,
      scrollHeight: el.scrollHeight,
    };
    return;
  }
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

/**
 * Rows appended to a window that was detached are a newer page read in, not messages that arrived: the core appends
 * nothing to a detached window, and a message sent from one comes back as a new latest window.
 */
function isNewerPage(prev: readonly MessageLike[], next: readonly MessageLike[], hadNewer: boolean): boolean {
  return hadNewer && countPrependedMessages(prev, next) === 0 && countAppendedMessages(prev, next) > 0;
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
  // Going to the newest message leaves the located row: a page that lands later keeps the reader's own place.
  locatedRowId = null;
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
  // And it takes the reading position (`locateAfterReplace`): a restore anchored before it would pull the reader back
  // to rows they have left, so it is cancelled, and until the reader moves the located row is what the list keeps.
  cancelAnchorRestore();
  locatedRowId = targetId;
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
  newerPage = false,
): Promise<void> {
  const prepended = countPrependedMessages(prev, next);
  const appended = countAppendedMessages(prev, next);
  if (newerPage) {
    // A newer page read into a detached window keeps the reader on the rows they are reading, even when it ends in
    // one of their own messages; what arrives later is counted from its last row.
    enterBrowseMode();
    captureBrowseAnchor();
    await nextTick();
    syncAtBottomState(getScrollContainer() ?? null);
    return;
  }
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
    locatedRowId = null;
    loadOlderRequested = false;
    loadNewerRequested = false;
    jumpToLatestRequested = false;
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
watch([() => props.loadingNewer, () => props.newerError], ([loading, error], [wasLoading, oldError]) => {
  if ((wasLoading && !loading) || error !== oldError) loadNewerRequested = false;
});

rowsDetached = Boolean(props.hasNewer);
tailDetached = rowsDetached;
watch(
  () => Boolean(props.hasNewer),
  (hasNewer) => {
    if (!hasNewer) return;
    rowsDetached = true;
    tailDetached = true;
  },
  { flush: "sync" },
);
watch(
  () => [displayMessages.value, Boolean(props.hasNewer), props.windowId] as const,
  async ([next, hasNewer, windowId], previousState) => {
    const [prev, , previousWindowId] = previousState ?? [[], false, undefined];
    const previous = prev ?? [];
    if (flareMessageListWindowReplaced(previous.map(timelineKey), next.map(timelineKey), {
      jumpRequested: jumpToLatestRequested, hasNewer, previousWindowId, windowId,
    })) {
      // A new window (spec/message-list-paging-vectors.json `windows`), and the latest one the reader asked for is
      // one: nothing of the reader's place in the old window applies. Decided before the swap is drawn, so the scroll
      // the swap causes already finds the requests held.
      jumpToLatestRequested = false;
      cancelAnchorRestore();
      locatedRowId = null;
      requestsHeld = true;
      loadOlderRequested = false;
      loadNewerRequested = false;
      rowsDetached = hasNewer;
      enableTailFollow();
      // The bottom of a detached window is not the latest message: nothing arrives there to follow.
      if (hasNewer) followTail.value = false;
      await nextTick();
      // It opens at its newest row; a locate that follows takes the reader on from there.
      await scrollToBottom();
      return;
    }
    if (next === previous) return;
    const newerPage = isNewerPage(previous, next, rowsDetached);
    rowsDetached = hasNewer;
    if (countPrependedMessages(previous, next) > 0 && !pendingPrependAnchor) capturePrependAnchor();
    if (timelineKeyOrEmpty(previous[0]) !== timelineKeyOrEmpty(next[0])) loadOlderRequested = false;
    if (timelineKeyOrEmpty(previous[previous.length - 1]) !== timelineKeyOrEmpty(next[next.length - 1])) loadNewerRequested = false;
    await nextTick();
    updateShortTimelineSpacer();
    if (previous.length === 0 && next.length > 0) {
      await scrollToBottom();
      return;
    }
    await handleMessagesGrowth(previous, next, newerPage);
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

tailSeenMessages = displayMessages.value;
watch(
  () => {
    const list = displayMessages.value;
    return messageTailSignature(list[list.length - 1]);
  },
  async (nextKey, prevKey) => {
    const seen = tailSeenMessages;
    const hadNewer = tailDetached;
    tailSeenMessages = displayMessages.value;
    tailDetached = Boolean(props.hasNewer);
    if (!nextKey || nextKey === prevKey) return;
    // Nothing arrives at the end of a detached window, and a newer page read into one keeps the reader in place.
    if (props.hasNewer || isNewerPage(seen, displayMessages.value, hadNewer)) return;
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
      // A located row stays where the locate put it: a band or a banner that changes the list's height is not the
      // reader asking for the bottom.
      if (preservingPrependAnchor || locatedRowId) return;
      if (followTail.value || isAtBottom.value || isResizeNearBottom(root)) {
        void scrollToBottom();
      }
    });
    listResizeObserver.observe(root);
    // A footer (typing row) that appears or grows keeps a reader at the latest message.
    footerResizeObserver = new ResizeObserver(() => {
      if (!preservingPrependAnchor && !locatedRowId && (followTail.value || isAtBottom.value)) void scrollToBottom();
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
    <div v-if="olderEdge.spinner" class="message-list-load-older" aria-live="polite">
      <span class="runtime-status-dot runtime-status-dot--busy" />
      {{ t("chat.loadOlder") }}
    </div>
    <div v-else-if="olderEdge.error || olderEdge.button" class="message-list-pagination">
      <span v-if="olderEdge.error" role="status">{{ olderError }}</span>
      <button v-if="olderEdge.button" type="button" @click="requestOlder(true)">{{ loadOlderText || t("chat.loadOlder") }}</button>
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
      @wheel.passive="onReaderMoves"
      @touchstart.passive="onReaderMoves"
      @pointerdown="onReaderMoves"
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
            :surface="item.surface"
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
    <div v-if="newerEdge.spinner" class="message-list-load-newer" aria-live="polite">
      <span class="runtime-status-dot runtime-status-dot--busy" />
      {{ t("chat.loadingNewer") }}
    </div>
    <div v-else-if="newerEdge.error || newerEdge.button" class="message-list-pagination message-list-pagination--newer">
      <span v-if="newerEdge.error" role="status">{{ newerError }}</span>
      <button v-if="newerEdge.button" type="button" @click="requestNewer(true)">{{ t("chat.loadNewer") }}</button>
    </div>
    <Transition name="message-list-scroll-latest-fade">
      <div
        v-if="latestEntry.shown"
        class="message-list-scroll-latest"
        :class="{ 'message-list-scroll-latest--above-newer': newerBandShown }"
      >
        <FlareScrollToLatest :count="latestEntry.count" @click="onLatestEntry" />
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
/* 往新的那一端在时间线下方：浮动键抬到它上面，不压住按钮。 */
.message-list-scroll-latest--above-newer { bottom: calc(12px + var(--flare-size-layout-touch-target)); }
/* 文字按钮而不是描边盒子：描边圆角盒子与消息气泡是同一套表面语言，
   放在时间线顶部会被读成一条消息。触达区靠带子的 min-height 给满。 */
.message-list-pagination button { align-self: stretch; min-width: var(--flare-size-layout-touch-target); padding-inline: var(--flare-size-spacing-sm); color: var(--flare-color-primary-text); background: transparent; border: 0; font-size: inherit; font-weight: 600; cursor: pointer; }
/* 悬停只加下划线,不换色:--flare-color-primary 是「填充」色,暗色主题下它是深紫 #7047D6,
   而静息态用的 --flare-color-primary-text 在暗色下是浅紫 #A78BFA —— 拿填充色去画文字,
   一悬停就把可读的浅紫换成压在深底上的深紫。 */
.message-list-pagination button:hover { text-decoration: underline; }
.message-list-pagination button:focus-visible { outline: 2px solid var(--flare-color-border-selected); }
</style>
