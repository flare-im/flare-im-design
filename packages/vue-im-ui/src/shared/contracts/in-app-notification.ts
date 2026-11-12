/**
 * InAppNotificationBanner / InAppNotificationHost contract: a message that arrived while the app is open on another
 * screen (the engine's `notification.present` with surface `inApp`), shown as a banner at the top. The host maps the
 * event into {@link FlareInAppNotification} and feeds the presenter; the kit never subscribes to the SDK and never
 * decides whether a message alerts.
 *
 * The queue rules are spec/in-app-notification-vectors.json, which the four kits run.
 */

/** How strongly the message asks for attention: the engine's notification channel. */
export type FlareInAppNotificationChannel = "messages" | "quiet" | "mentions" | "urgent";

export const inAppNotificationChannels: readonly FlareInAppNotificationChannel[] = ["messages", "quiet", "mentions", "urgent"];

export interface FlareInAppNotification {
  /** One banner per collapse id: a newer item with the same id replaces the shown or waiting one in place. */
  collapseId: string;
  /** The conversation the banner opens; also seeds the avatar colour. */
  conversationId: string;
  /** The newest message the banner stands for, handed back on open. */
  messageId?: string;
  /** Conversation or sender name; its initials stand in for a missing avatar. */
  title: string;
  /** The preview, drawn on one line and ellipsised. */
  body: string;
  /** Unread messages the banner stands for (default 1); above 1 the kit's "[3条]" goes before the body. */
  count?: number;
  /** messages (default) and quiet look the same; mentions and urgent carry a tag and an accent. */
  channel?: FlareInAppNotificationChannel;
  /** Conversation avatar the host resolved; the initials of `title` without it. */
  avatarUrl?: string;
}

/** How long a banner stays after it shows or is replaced, and again after a touch, hover or focus on it ends. */
export const IN_APP_NOTIFICATION_DURATION_MS = 4000;
/** Banners waiting behind the visible one; beyond this the oldest waiting one is dropped, so the newest win. */
export const IN_APP_NOTIFICATION_PENDING_LIMIT = 3;
/** How far up a swipe has to travel before it dismisses the banner, in CSS px. */
export const IN_APP_NOTIFICATION_SWIPE_DISMISS_PX = 24;

/** The tag before the body: mentions and urgent name themselves, the other channels draw none. */
export function inAppNotificationEmphasis(channel?: FlareInAppNotificationChannel): "mentions" | "urgent" | null {
  return channel === "mentions" || channel === "urgent" ? channel : null;
}

/** Whether the count goes before the body: only above one message. */
export function inAppNotificationShowsCount(notification: Pick<FlareInAppNotification, "count">): boolean {
  return (notification.count ?? 1) > 1;
}

/** The kit's words a banner is made of, in the reader's language. */
export interface FlareInAppNotificationWords {
  /** "New message". */
  label: string;
  /** "[有人@我]" / "[Mention]". */
  mention: string;
  /** "[加急]" / "[Urgent]". */
  urgent: string;
  /** "[3条]" / "[3 messages]". */
  count: (count: number) => string;
}

/** The tag before the body in the reader's words, or empty. */
export function inAppNotificationTag(notification: Pick<FlareInAppNotification, "channel">, words: FlareInAppNotificationWords): string {
  const emphasis = inAppNotificationEmphasis(notification.channel);
  return emphasis === "mentions" ? words.mention : emphasis === "urgent" ? words.urgent : "";
}

/** What a reader hears: New message, the title, the tag, the count and the body. */
export function inAppNotificationSpoken(notification: FlareInAppNotification, words: FlareInAppNotificationWords): string {
  const count = inAppNotificationShowsCount(notification) ? words.count(notification.count ?? 1) : "";
  return [words.label, notification.title, inAppNotificationTag(notification, words), count, notification.body].filter(Boolean).join(", ");
}

/** The visible banner and the ones waiting, oldest first. */
export interface FlareInAppNotificationQueue {
  readonly current: FlareInAppNotification | null;
  readonly pending: readonly FlareInAppNotification[];
}

/** A step of the queue: the next state, and whether the visible banner's timer starts over. */
export interface FlareInAppNotificationStep {
  readonly queue: FlareInAppNotificationQueue;
  readonly restart: boolean;
}

export const emptyInAppNotificationQueue: FlareInAppNotificationQueue = { current: null, pending: [] };

/** Shows, replaces or queues `item`. */
export function inAppNotificationPresent(queue: FlareInAppNotificationQueue, item: FlareInAppNotification): FlareInAppNotificationStep {
  if (!queue.current) return { queue: { current: item, pending: queue.pending }, restart: true };
  if (queue.current.collapseId === item.collapseId) return { queue: { current: item, pending: queue.pending }, restart: true };
  const waiting = queue.pending.findIndex((entry) => entry.collapseId === item.collapseId);
  if (waiting >= 0) {
    const pending = [...queue.pending];
    pending[waiting] = item;
    return { queue: { current: queue.current, pending }, restart: false };
  }
  const pending = [...queue.pending, item];
  while (pending.length > IN_APP_NOTIFICATION_PENDING_LIMIT) pending.shift();
  return { queue: { current: queue.current, pending }, restart: false };
}

/** The visible banner goes and the first waiting one shows. */
export function inAppNotificationDismiss(queue: FlareInAppNotificationQueue): FlareInAppNotificationStep {
  const [next = null, ...rest] = queue.pending;
  return { queue: { current: next, pending: rest }, restart: next !== null };
}

/** Takes away the banners of these collapse ids; the visible one goes as dismiss says. */
export function inAppNotificationClear(queue: FlareInAppNotificationQueue, collapseIds: readonly string[]): FlareInAppNotificationStep {
  const ids = new Set(collapseIds);
  const kept: FlareInAppNotificationQueue = { current: queue.current, pending: queue.pending.filter((entry) => !ids.has(entry.collapseId)) };
  if (queue.current && ids.has(queue.current.collapseId)) return inAppNotificationDismiss(kept);
  return { queue: kept, restart: false };
}

/** Takes every banner away. */
export function inAppNotificationClearAll(): FlareInAppNotificationStep {
  return { queue: emptyInAppNotificationQueue, restart: false };
}
