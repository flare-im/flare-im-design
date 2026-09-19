import type { MessageLike } from "../shared/contracts/messageRow";
import { normalizeToContentElem, textBodyFromContent } from "./contentElem";


/** Host-supplied facts used to resolve available message actions. */
export interface MessageActionContext {
  currentUserId: string;
  isConnected: boolean;
  isPending: boolean;
  isPinned: boolean;
  isFailed: boolean;
  multiSelectMode: boolean;
}

export interface MessageActionAvailability {
  canReply: boolean;
  canForward: boolean;
  canCopy: boolean;
  canEdit: boolean;
  canDelete: boolean;
  canRecall: boolean;
  canPin: boolean;
  canUnpin: boolean;
  canReact: boolean;
  canMultiSelect: boolean;
  canSave: boolean;
  canResend: boolean;
}

const TYPE_TEXT = 1;
const TYPE_RICH_TEXT = 15;
const MEDIA_TYPES = new Set([2, 3, 4, 5, 16]);

/**
 * 一条消息此刻可用的动作。
 *
 * The package-owned scenario fixture pins this presentation policy. Hosts remain
 * responsible for authoritative permissions and may disable any action.
 *
 * The policy prevents invalid UI such as:
 * 纯图片消息上显示"复制"（点了什么都不会发生）、对发送失败的消息显示"撤回"、
 * 断线时显示"重发"、对还没发出去的消息显示编辑/置顶/转发。
 */
export function messageActionAvailability(
  message: MessageLike,
  ctx: MessageActionContext,
): MessageActionAvailability {
  const status = message.status;
  const mutation = message.lifecycle?.mutation ?? "normal";
  const recalled = mutation === "recalled" || message.isRecalled === true;
  const deleted = mutation === "deleted";
  const active = !recalled && !deleted;

  const isFailed = ctx.isFailed || status === "failed";
  const selfSent = ctx.currentUserId !== "" && message.senderId === ctx.currentUserId;
  const messageType = message.messageType ?? 0;
  const editableType = messageType === TYPE_TEXT || messageType === TYPE_RICH_TEXT;
  const mediaType = MEDIA_TYPES.has(messageType);
  const single = !ctx.multiSelectMode;
  // 复制看的是"有没有可复制的正文"，而不是消息类型。
  //
  // ⚠️ 不能用 getMessageText：那是**预览**辅助，会一路回退到 "[图片]" 乃至
  // serverId，对任何消息都非空 —— 用它判断等于"永远可复制"，
  // 正是图片消息上出现无效"复制"入口的成因。这里只认真正的正文字段。
  // The body is read the way the renderer reads it, so the core's flattened
  // `{ contentType, text }` counts the same as a `{ contentType, data }` bag.
  const element = normalizeToContentElem(message.content);
  const body = element ? textBodyFromContent(element) : "";
  const contentData = (message.content as { data?: Record<string, unknown> } | undefined)?.data;
  const rawText = body || (contentData?.text ?? contentData?.title ?? contentData?.description);
  const hasText = typeof rawText === "string" && rawText.trim() !== "";

  return {
    canReply: single && active,
    canForward: active && !ctx.isPending,
    canCopy: active && hasText,
    canEdit: single && selfSent && active && !ctx.isPending && !isFailed && editableType,
    canDelete: active,
    canRecall: single && selfSent && active && !isFailed,
    canPin: active && !ctx.isPending && !ctx.isPinned,
    canUnpin: active && !ctx.isPending && ctx.isPinned,
    canReact: active && !ctx.isPending,
    canMultiSelect: active,
    canSave: mediaType && active && !ctx.isPending,
    canResend: isFailed && selfSent && ctx.isConnected,
  };
}

/** Delivery state projected for the message metadata UI. */
export type MessageDeliveryState = "none" | "sending" | "failed" | "delivered" | "read";

/**
 * 自己发出的消息该显示什么送达状态。
 *
 * 视觉约定：单勾=已送达（SENT/PERSISTED 不区分）、双勾=已读；
 * 撤回/删除由占位气泡接管；对方发来的消息不显示。
 */
export function messageDeliveryState(
  message: MessageLike,
  ctx: Pick<MessageActionContext, "currentUserId" | "isPending" | "isFailed">,
): MessageDeliveryState {
  const selfSent = ctx.currentUserId !== "" && message.senderId === ctx.currentUserId;
  if (!selfSent) return "none";
  const status = message.status;
  const mutation = message.lifecycle?.mutation ?? "normal";
  if (mutation === "recalled" || mutation === "deleted" || message.isRecalled === true) {
    return "none";
  }
  if (ctx.isFailed || status === "failed") return "failed";
  if (ctx.isPending || status === "pending" || status === "sending" || status === "retrying") return "sending";
  return status === "read" || message.isRead === true ? "read" : "delivered";
}
