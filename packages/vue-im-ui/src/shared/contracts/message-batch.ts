/** Batch actions a host may expose over a multi-selection of messages. */
export type MessageBatchAction = "forwardEach" | "forwardMerged" | "pin" | "pinSelf" | "delete";

/** Display order is stable across platforms; `delete` is always last and rendered as danger. */
export const messageBatchActions: readonly MessageBatchAction[] = ["forwardEach", "forwardMerged", "pin", "pinSelf", "delete"];

/** Host-declared capabilities; an absent/false entry hides the action entirely. */
export interface MessageBatchCapabilities {
  forwardEach?: boolean;
  forwardMerged?: boolean;
  pin?: boolean;
  pinSelf?: boolean;
  delete?: boolean;
}

/** What an action needs to mean anything: merging two messages into one card needs two. */
export const messageBatchMinimumSelection: Partial<Record<MessageBatchAction, number>> = { forwardMerged: 2 };

/**
 * Actions the toolbar may offer right now (`spec/message-batch-vectors.json`, the same table on four
 * kits). Empty while busy or while nothing is selected; otherwise the capability-enabled actions in
 * canonical order, minus the ones the selection is too small for. Never mutates its inputs.
 */
export function messageBatchActionsAvailable(
  selectedIds: readonly string[],
  capabilities: MessageBatchCapabilities | null | undefined,
  busy?: boolean,
): MessageBatchAction[] {
  if (busy || selectedIds.length === 0) return [];
  return messageBatchActions.filter(
    (action) => capabilities?.[action] === true && selectedIds.length >= (messageBatchMinimumSelection[action] ?? 1),
  );
}
