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

/** The actions that forward the selection: they count and report only its forwardable ids. */
export const messageBatchForwardActions: readonly MessageBatchAction[] = ["forwardEach", "forwardMerged"];

/**
 * The ids an action works on (`spec/message-batch-vectors.json` forward): for a forward action the selection minus
 * `unforwardableIds` — the ids the core answers canForward false for — in selection order; for any other action the
 * whole selection. Never mutates its inputs.
 */
export function messageBatchActionIds(
  action: MessageBatchAction,
  selectedIds: readonly string[],
  unforwardableIds: readonly string[] = [],
): string[] {
  if (!messageBatchForwardActions.includes(action) || unforwardableIds.length === 0) return [...selectedIds];
  const unforwardable = new Set(unforwardableIds);
  return selectedIds.filter((id) => !unforwardable.has(id));
}

/** How many of the selected ids cannot be forwarded: the count the toolbar's hint shows. */
export function messageBatchUnforwardableCount(
  selectedIds: readonly string[],
  unforwardableIds: readonly string[] = [],
): number {
  if (unforwardableIds.length === 0) return 0;
  const unforwardable = new Set(unforwardableIds);
  return new Set(selectedIds.filter((id) => unforwardable.has(id))).size;
}

/**
 * Actions the toolbar may offer right now (`spec/message-batch-vectors.json`, the same table on four
 * kits). Empty while busy or while nothing is selected; otherwise the capability-enabled actions in
 * canonical order, minus the ones too few ids are left for: a forward action counts only the forwardable
 * ids (the selection minus `unforwardableIds`), every other action the whole selection. Never mutates
 * its inputs.
 */
export function messageBatchActionsAvailable(
  selectedIds: readonly string[],
  capabilities: MessageBatchCapabilities | null | undefined,
  busy?: boolean,
  unforwardableIds: readonly string[] = [],
): MessageBatchAction[] {
  if (busy || selectedIds.length === 0) return [];
  return messageBatchActions.filter(
    (action) =>
      capabilities?.[action] === true &&
      messageBatchActionIds(action, selectedIds, unforwardableIds).length >= (messageBatchMinimumSelection[action] ?? 1),
  );
}
