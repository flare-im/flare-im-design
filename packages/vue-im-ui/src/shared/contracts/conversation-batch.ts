/** Batch actions a host may expose over a multi-selection of conversations. */
export type ConversationBatchAction = "markRead" | "mute" | "archive" | "delete";

/** Display order is stable across platforms; `delete` is always last and rendered as danger. */
export const conversationBatchActions: readonly ConversationBatchAction[] = ["markRead", "mute", "archive", "delete"];

/** Host-declared capabilities; an absent/false entry hides the action entirely. */
export interface ConversationBatchCapabilities {
  markRead?: boolean;
  mute?: boolean;
  archive?: boolean;
  delete?: boolean;
}

/** One failed item of the previous batch, with a user-facing reason mapped by the host. */
export interface ConversationBatchFailure {
  id: string;
  title: string;
  reason: string;
}

/** Outcome of the previous batch as written by the host; `null` means nothing to show. */
export interface ConversationBatchResult {
  succeeded: string[];
  failed: ConversationBatchFailure[];
}

export interface ConversationBatchSummary {
  succeededCount: number;
  failedCount: number;
  /** Unique failed IDs, in failure order — payload of `retryFailed`. */
  retryIds: string[];
}

/** True when the host limit is a positive number and the selection exceeds it. */
export function batchSelectionExceeded(selectedCount: number, maxSelection?: number | null): boolean {
  return typeof maxSelection === "number" && Number.isFinite(maxSelection) && maxSelection > 0 && selectedCount > maxSelection;
}

/**
 * Actions the toolbar may offer right now. Empty while busy, while nothing is selected,
 * or while the selection exceeds `maxSelection`; otherwise the capability-enabled actions
 * in canonical order. Never mutates its inputs.
 */
export function batchActionsAvailable(
  selectedIds: readonly string[],
  capabilities: ConversationBatchCapabilities | null | undefined,
  busy?: boolean,
  maxSelection?: number | null,
): ConversationBatchAction[] {
  if (busy || selectedIds.length === 0 || batchSelectionExceeded(selectedIds.length, maxSelection)) return [];
  return conversationBatchActions.filter((action) => capabilities?.[action] === true);
}

/** Counts of the previous batch and the IDs a retry should target (deduplicated). */
export function summarizeBatchResult(result: ConversationBatchResult | null | undefined): ConversationBatchSummary {
  if (!result) return { succeededCount: 0, failedCount: 0, retryIds: [] };
  const retryIds: string[] = [];
  const seen = new Set<string>();
  for (const failure of result.failed) {
    if (!failure.id || seen.has(failure.id)) continue;
    seen.add(failure.id);
    retryIds.push(failure.id);
  }
  return { succeededCount: result.succeeded.length, failedCount: result.failed.length, retryIds };
}
