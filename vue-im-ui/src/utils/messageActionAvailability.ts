import type { MessageLike } from "../shared/contracts/messageRow";


/** 与核心 `domain::message_actions` 的 `MessageActionContext` 一一对应。 */
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

const STATUS_FAILED = 4;
const STATUS_RECALLED = 5;
const STATUS_DELETED = 6;
const TYPE_TEXT = 1;
const TYPE_RICH_TEXT = 15;
const MEDIA_TYPES = new Set([2, 3, 4, 5, 16]);

/**
 * 一条消息此刻可用的动作。
 *
 * **这条规则的真源是核心 `domain::message_actions`**；这里是它在 kit 侧的实现，
 * 由 `sdk-spec/message-action-vectors.json` 逐位钉住（见
 * `messageActionAvailability.vectors.test.ts`）。kit 的组件是纯展示的、不碰 SDK，
 * 所以不能直接调核心；规则允许有第二份实现，但不允许与核心漂移。
 *
 * 之前 kit 的判定散在 buildMessageMenuOptions 里，与核心有多处实打实的分歧：
 * 纯图片消息上显示"复制"（点了什么都不会发生）、对发送失败的消息显示"撤回"、
 * 断线时显示"重发"、对还没发出去的消息显示编辑/置顶/转发。
 */
export function messageActionAvailability(
  message: MessageLike,
  ctx: MessageActionContext,
): MessageActionAvailability {
  const status = message.status ?? 0;
  const recalled = status === STATUS_RECALLED || message.isRecalled === true;
  const deleted = status === STATUS_DELETED;
  const active = !recalled && !deleted;

  const isFailed = ctx.isFailed || status === STATUS_FAILED;
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
  const contentData = (message.content as { data?: Record<string, unknown> } | undefined)?.data;
  const rawText = contentData?.text ?? contentData?.title ?? contentData?.description;
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
