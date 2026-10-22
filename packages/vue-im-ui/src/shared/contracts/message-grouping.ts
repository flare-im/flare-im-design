/**
 * Message runs, row presentation and date pills (docs/design/message-surface-and-meta.md C4). Pure rules, tested
 * against spec/message-grouping-vectors.json by all four kits. A run is one sender within five minutes; centered rows
 * (system, recall, delete), a switch between card and the other surfaces, date pills and the unread divider break it.
 */
import type { FlareConversationKind } from "./conversation";
import type { FlareMessageSurface } from "./message-surface";

export type FlareMessageGroupPosition = "single" | "first" | "middle" | "last";

export interface FlareMessageRowPresentation {
  showAvatar: boolean;
  reserveAvatarSpace: boolean;
  showSenderName: boolean;
  avatarPlacement: "leading" | "trailing";
  /** Draw the bubble tail: a bubble surface ending its run. */
  tail: boolean;
}

export interface FlareMessageGroupingOptions {
  timeGapMs?: number;
  showIncomingAvatar?: boolean;
  showSelfAvatar?: boolean;
  showGroupSenderName?: boolean;
}

/** What grouping reads of a message. A missing time joins its neighbours, as an unsent draft does. */
export interface FlareMessageGroupingItem {
  id: string;
  senderId: string;
  atMs: number;
  surface: FlareMessageSurface;
}

export const FLARE_MESSAGE_GROUP_GAP_MS = 5 * 60_000;

/** Whether two neighbouring messages share a run (vectors rules.shareGroup). */
export function messagesShareGroup(
  previous: FlareMessageGroupingItem | undefined,
  current: FlareMessageGroupingItem | undefined,
  timeGapMs = FLARE_MESSAGE_GROUP_GAP_MS,
): boolean {
  if (!previous || !current) return false;
  if (previous.surface === "centered" || current.surface === "centered") return false;
  if ((previous.surface === "card") !== (current.surface === "card")) return false;
  const senderId = previous.senderId?.trim();
  if (!senderId || senderId !== current.senderId?.trim()) return false;
  return !previous.atMs || !current.atMs || Math.abs(current.atMs - previous.atMs) <= timeGapMs;
}

export function messageGroupPosition(
  items: readonly FlareMessageGroupingItem[],
  index: number,
  timeGapMs = FLARE_MESSAGE_GROUP_GAP_MS,
): FlareMessageGroupPosition {
  const current = items[index];
  if (!current || current.surface === "centered") return "single";
  const joinedPrevious = messagesShareGroup(items[index - 1], current, timeGapMs);
  const joinedNext = messagesShareGroup(current, items[index + 1], timeGapMs);
  if (!joinedPrevious && !joinedNext) return "single";
  if (!joinedPrevious) return "first";
  if (!joinedNext) return "last";
  return "middle";
}

export function messageRowPresentation(
  item: { senderId: string; surface?: FlareMessageSurface },
  position: FlareMessageGroupPosition,
  currentUserId: string,
  conversationKind: FlareConversationKind | undefined,
  options: FlareMessageGroupingOptions = {},
): FlareMessageRowPresentation {
  const self = item.senderId === currentUserId;
  const avatarPlacement = self ? "trailing" : "leading";
  const surface = item.surface ?? "bubble";
  if (surface === "centered") {
    return { showAvatar: false, reserveAvatarSpace: false, showSenderName: false, avatarPlacement, tail: false };
  }
  const edge = position === "single" || position === "first";
  const avatarOn = self ? Boolean(options.showSelfAvatar) : (options.showIncomingAvatar ?? true);
  return {
    showAvatar: avatarOn && edge,
    reserveAvatarSpace: avatarOn,
    showSenderName: !self && conversationKind === "group" && (options.showGroupSenderName ?? true) && edge,
    avatarPlacement,
    tail: surface === "bubble" && (position === "single" || position === "last"),
  };
}

/** Which tier a date pill reads (vectors rules.datePill). */
export type FlareTimelineDateLabel = "today" | "yesterday" | "monthDay" | "yearMonthDay";

export type FlareTimelineRow =
  | { kind: "date"; atMs: number; label: FlareTimelineDateLabel }
  | { kind: "unread"; count: number }
  | { kind: "message"; index: number; position: FlareMessageGroupPosition; presentation: FlareMessageRowPresentation };

interface LocalDay { year: number; month: number; day: number }

/** The local calendar day of an instant: the device zone, or a fixed offset (tests). */
function localDay(ms: number, utcOffsetMinutes?: number): LocalDay {
  if (utcOffsetMinutes === undefined) {
    const d = new Date(ms);
    return { year: d.getFullYear(), month: d.getMonth(), day: d.getDate() };
  }
  const d = new Date(ms + utcOffsetMinutes * 60_000);
  return { year: d.getUTCFullYear(), month: d.getUTCMonth(), day: d.getUTCDate() };
}

const sameDay = (a: LocalDay, b: LocalDay) => a.year === b.year && a.month === b.month && a.day === b.day;

/** The date pill tier of an instant relative to now. */
export function flareTimelineDateLabel(atMs: number, nowMs: number, utcOffsetMinutes?: number): FlareTimelineDateLabel {
  const at = localDay(atMs, utcOffsetMinutes);
  const now = localDay(nowMs, utcOffsetMinutes);
  if (sameDay(at, now)) return "today";
  const yesterday = localDay(nowMs - 86_400_000, utcOffsetMinutes);
  if (sameDay(at, yesterday)) return "yesterday";
  return at.year === now.year ? "monthDay" : "yearMonthDay";
}

/**
 * The timeline's rows: a date pill before the first message and at each new local day, the unread divider right
 * before `unreadFromId` (counting the others' messages from it on), and each message with its run position and
 * presentation — a date pill or the divider ends the run before it.
 */
export function flareTimelineRows(
  items: readonly FlareMessageGroupingItem[],
  context: {
    currentUserId: string;
    conversationKind?: FlareConversationKind;
    unreadFromId?: string;
    options?: FlareMessageGroupingOptions;
    nowMs?: number;
    utcOffsetMinutes?: number;
  },
): FlareTimelineRow[] {
  const { currentUserId, conversationKind, options = {}, utcOffsetMinutes } = context;
  const nowMs = context.nowMs ?? Date.now();
  const gap = options.timeGapMs ?? FLARE_MESSAGE_GROUP_GAP_MS;
  const unreadIndex = context.unreadFromId ? items.findIndex((item) => item.id === context.unreadFromId) : -1;
  const startsDay: boolean[] = [];
  let previous: LocalDay | null = null;
  for (const item of items) {
    if (!item.atMs) {
      startsDay.push(false);
      continue;
    }
    const day = localDay(item.atMs, utcOffsetMinutes);
    startsDay.push(!previous || !sameDay(previous, day));
    previous = day;
  }
  const dividerBefore = (index: number) => index === unreadIndex || startsDay[index] === true;
  const rows: FlareTimelineRow[] = [];
  items.forEach((item, index) => {
    if (startsDay[index]) rows.push({ kind: "date", atMs: item.atMs, label: flareTimelineDateLabel(item.atMs, nowMs, utcOffsetMinutes) });
    if (index === unreadIndex) {
      rows.push({ kind: "unread", count: items.slice(index).filter((other) => other.senderId !== currentUserId).length });
    }
    let position = messageGroupPosition(items, index, gap);
    if (index > 0 && dividerBefore(index)) position = position === "middle" ? "first" : position === "last" ? "single" : position;
    if (index + 1 < items.length && dividerBefore(index + 1)) position = position === "middle" ? "last" : position === "first" ? "single" : position;
    rows.push({ kind: "message", index, position, presentation: messageRowPresentation(item, position, currentUserId, conversationKind, options) });
  });
  return rows;
}
