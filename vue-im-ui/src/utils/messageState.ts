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

  if (message.isRead && rawStatus >= 2 && rawStatus < 6) {
    return 4;
  }

  if (rawStatus >= 4 && rawStatus < 6 && !message.isRead) {
    return 3;
  }

  if (rawStatus >= 1 && rawStatus <= 6) {
    return rawStatus;
  }
  return 0;
}
