import type { MessageLike } from "./messageRow";
import type { FlareConversationKind } from "./conversation";

export type FlareMessageGroupPosition = "single" | "first" | "middle" | "last";

export interface FlareMessageRowPresentation {
  showAvatar: boolean;
  reserveAvatarSpace: boolean;
  showSenderName: boolean;
  avatarPlacement: "leading" | "trailing";
}

export interface FlareMessageGroupingOptions {
  timeGapMs?: number;
  showIncomingAvatar?: boolean;
  showSelfAvatar?: boolean;
  showGroupSenderName?: boolean;
}

const DEFAULT_TIME_GAP_MS = 5 * 60_000;

export function isSystemMessageForGrouping(message: MessageLike | undefined): boolean {
  const type = message?.content?.contentType;
  return type === "system" || type === "notification";
}

export function messagesShareGroup(
  previous: MessageLike | undefined,
  current: MessageLike | undefined,
  timeGapMs = DEFAULT_TIME_GAP_MS,
): boolean {
  if (!previous || !current) return false;
  if (isSystemMessageForGrouping(previous) || isSystemMessageForGrouping(current)) return false;
  const senderId = previous.senderId?.trim();
  if (!senderId || senderId !== current.senderId?.trim()) return false;
  const previousTs = Number(previous.createdAt || previous.clientCreatedAt || 0);
  const currentTs = Number(current.createdAt || current.clientCreatedAt || 0);
  return !previousTs || !currentTs || Math.abs(currentTs - previousTs) <= timeGapMs;
}

export function messageGroupPosition(
  messages: readonly MessageLike[],
  index: number,
  timeGapMs = DEFAULT_TIME_GAP_MS,
): FlareMessageGroupPosition {
  const current = messages[index];
  if (!current || isSystemMessageForGrouping(current)) return "single";
  const joinedPrevious = messagesShareGroup(messages[index - 1], current, timeGapMs);
  const joinedNext = messagesShareGroup(current, messages[index + 1], timeGapMs);
  if (!joinedPrevious && !joinedNext) return "single";
  if (!joinedPrevious) return "first";
  if (!joinedNext) return "last";
  return "middle";
}

export function messageRowPresentation(
  message: MessageLike,
  position: FlareMessageGroupPosition,
  currentUserId: string,
  conversationKind: FlareConversationKind | undefined,
  options: FlareMessageGroupingOptions = {},
): FlareMessageRowPresentation {
  const self = message.senderId === currentUserId;
  const edge = position === "single" || position === "first";
  const showAvatar = self
    ? Boolean(options.showSelfAvatar) && edge
    : (options.showIncomingAvatar ?? true) && edge;
  return {
    showAvatar,
    reserveAvatarSpace: self ? Boolean(options.showSelfAvatar) : (options.showIncomingAvatar ?? true),
    showSenderName:
      !self
      && conversationKind === "group"
      && (options.showGroupSenderName ?? true)
      && edge,
    avatarPlacement: self ? "trailing" : "leading",
  };
}
