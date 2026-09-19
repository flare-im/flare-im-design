import type { TransferState } from "./transfer";

export type MessageSendState = "draft" | "sending" | "sent" | "failed";
export type MessageDeliveryState = "serverAccepted" | "delivered" | "partiallyDelivered";
export type MessageReadState = "unread" | "partiallyRead" | "read";
export type MessageMutationState = "normal" | "edited" | "recalled" | "deleted";
export type MessageEphemeralState = "none" | "readOnce" | "burnAfterRead" | "expired";

/** UI-facing lifecycle projection. Hosts map authoritative state into this model. */
export interface MessageLifecycle {
  transfer: TransferState;
  send: MessageSendState;
  delivery: MessageDeliveryState;
  read: MessageReadState;
  mutation: MessageMutationState;
  ephemeral: MessageEphemeralState;
}

/** Visual projection only. The orthogonal lifecycle remains the source model. */
export type MessageStatusState =
  | "pending"
  | "sending"
  | "sent"
  | "delivered"
  | "read"
  | "failed"
  | "retrying";

export const defaultMessageLifecycle: MessageLifecycle = {
  transfer: "idle",
  send: "sent",
  delivery: "serverAccepted",
  read: "unread",
  mutation: "normal",
  ephemeral: "none",
};

/** Maps lifecycle dimensions into the final receipt glyph without collapsing the model. */
export function lifecycleToMessageStatus(lifecycle: MessageLifecycle): MessageStatusState {
  if (lifecycle.send === "failed" || lifecycle.transfer === "failed") return "failed";
  if (lifecycle.send === "draft" || lifecycle.transfer === "queued") return "pending";
  if (
    lifecycle.send === "sending" ||
    lifecycle.transfer === "transferring" ||
    lifecycle.transfer === "paused"
  ) return "sending";
  if (lifecycle.read === "read") return "read";
  if (
    lifecycle.delivery === "delivered" ||
    lifecycle.delivery === "partiallyDelivered"
  ) return "delivered";
  return "sent";
}
