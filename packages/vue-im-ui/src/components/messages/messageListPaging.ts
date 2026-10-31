/**
 * The two ends of the message list and its back-to-latest key (`spec/message-list-paging-vectors.json`, read by
 * the Flutter, SwiftUI and Compose kits too).
 *
 * A window is the run of messages the host hands the list. Its older end (above the timeline) and its newer end
 * (below it) follow one rule: what each end draws, when the list asks for a page by itself, and when the floating key
 * at the bottom takes the reader back to the latest messages instead of to the bottom of the window.
 */

/** How close to an edge the reader must scroll before the list asks for the next page there, in CSS pixels. */
export const FLARE_MESSAGE_LIST_OLDER_WITHIN_PX = 160;
export const FLARE_MESSAGE_LIST_NEWER_WITHIN_PX = 160;

/** One end of the window, as the host describes it. */
export interface FlareMessageListEnd {
  /** There is more to read past this end. */
  has: boolean;
  /** A page past this end is being read. */
  loading: boolean;
  /** The last page past this end failed; null, empty or blank is no error. */
  error?: string | null;
  /** The host takes this end's load intent. */
  handled: boolean;
}

/** What one end draws. */
export interface FlareMessageListEdge {
  spinner: boolean;
  error: boolean;
  button: boolean;
}

function failed(end: FlareMessageListEnd): boolean {
  return typeof end.error === "string" && end.error.trim().length > 0;
}

/**
 * While loading, a spinner and nothing else (the last error is not repeated while it is being retried); otherwise
 * the error when there is one, and the load or retry button while there is more and the host takes the intent.
 */
export function flareMessageListEdge(end: FlareMessageListEnd): FlareMessageListEdge {
  if (end.loading) return { spinner: true, error: false, button: false };
  return { spinner: false, error: failed(end), button: end.has && end.handled };
}

/** Whether one end asks for a page by itself, `distance` from its edge. After a failure only the retry button asks. */
function asks(end: FlareMessageListEnd, distance: number, within: number): boolean {
  return end.handled && end.has && !end.loading && !failed(end) && distance <= within;
}

/**
 * The pages the list asks for as the reader scrolls. `fromTop` is how far the first row's top is above the
 * viewport's top, `fromBottom` how far the end of the timeline is below the viewport's bottom.
 */
export function flareMessageListRequests(
  viewport: { fromTop: number; fromBottom: number },
  older: FlareMessageListEnd,
  newer: FlareMessageListEnd,
): { older: boolean; newer: boolean } {
  return {
    older: asks(older, viewport.fromTop, FLARE_MESSAGE_LIST_OLDER_WITHIN_PX),
    newer: asks(newer, viewport.fromBottom, FLARE_MESSAGE_LIST_NEWER_WITHIN_PX),
  };
}

/** What the floating key at the bottom does. */
export type FlareMessageListLatestAction = "jumpToLatest" | "scrollToBottom";

/**
 * The floating key at the bottom. A window detached from the latest (`hasNewer`) offers the way back to the latest
 * messages, without a count — rows below a detached reader are history read in, not news — when the host takes the
 * jump. Otherwise it is the new-messages key: shown while messages arrived below a reader who scrolled up, counting
 * them, and it scrolls to the bottom.
 */
export function flareMessageListLatestEntry(state: { hasNewer: boolean; handled: boolean; belowCount: number }): {
  shown: boolean;
  count: number;
  action: FlareMessageListLatestAction | null;
} {
  if (state.hasNewer) {
    return state.handled
      ? { shown: true, count: 0, action: "jumpToLatest" }
      : { shown: false, count: 0, action: null };
  }
  return state.belowCount > 0
    ? { shown: true, count: state.belowCount, action: "scrollToBottom" }
    : { shown: false, count: 0, action: null };
}
