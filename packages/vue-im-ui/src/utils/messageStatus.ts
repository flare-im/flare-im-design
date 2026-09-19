import type { MessageStatusState } from "../shared/contracts/message-lifecycle";
import { lifecycleToMessageStatus } from "../shared/contracts/message-lifecycle";
import type { MessageLike } from "../shared/contracts/messageRow";

/** Resolve the semantic receipt state used by message presentation. */
export function resolveMessageStatus(message: MessageLike): MessageStatusState {
  return message.lifecycle
    ? lifecycleToMessageStatus(message.lifecycle)
    : message.status;
}
