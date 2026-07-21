import type { MessageLike } from "../shared/contracts/messageRow";

/** 与 proto `MessageStatus` / shared-im-ui `MessageStatus.vue` 一致 */
export function messageStateToNumber(message: MessageLike): number {
  const local = message.localState;
  const hasAuthoritativeIdentity = message.conversationSeq > 0 || message.serverId.trim().length > 0;
  if (!hasAuthoritativeIdentity && local?.failed) return 5;
  if (!hasAuthoritativeIdentity && local?.sending) return 1;

  let rawStatus = message.status;
  if (typeof rawStatus !== "number") return 0;

  /** Web SDK ack 后仍为 status=1，映射为「已发送」单勾 */
  if (rawStatus === 1 && local?.isLocal && !local.sending) {
    rawStatus = 2;
  }

  // proto MESSAGE_STATUS_FAILED(4) 是终态发送失败 —— 恒显失败/重发,勿落入已送达/已读分支。
  if (rawStatus === 4) return 5;
  // RECALLED(5)/DELETED(6) 是终态,由 isRecalled/删除占位接管展示,不显发送状态指示。
  if (rawStatus === 5 || rawStatus === 6) return 0;

  // 对端已读回执:SENT(2)/PERSISTED(3) 且已读 → 双勾。
  if (message.isRead && (rawStatus === 2 || rawStatus === 3)) {
    return 4;
  }

  // 1=发送中 / 2=已发送(单勾) / 3=已送达(单勾)。
  if (rawStatus >= 1 && rawStatus <= 3) {
    return rawStatus;
  }
  return 0;
}
