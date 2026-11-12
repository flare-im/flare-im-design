/**
 * The two ends of the message list and its back-to-latest key (`spec/message-list-paging-vectors.json`, read by
 * the Flutter, SwiftUI and Compose kits too).
 *
 * A window is the run of messages the host hands the list. Its older end (above the timeline) and its newer end
 * (below it) follow one rule: what each end draws, when the list asks for a page by itself, and when the floating key
 * at the bottom takes the reader back to the latest messages instead of to the bottom of the window. A window the host
 * replaces as a whole is a new one (`windows`), and what that does to the list is `locateAfterReplace`. Whether the
 * reader is at the bottom of the window, as the list tells the host, is `atBottom`.
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

/**
 * Whether a window overflows the viewport by no more than the paging distance (`fill`): `fromTop + fromBottom` is that
 * overflow wherever the reader is. Such a window cannot be scrolled far enough to move either end into or out of reach
 * (one that fits does not scroll at all), so the list asks for its pages by itself until it overflows, or there is
 * nothing more. A missing report (null) decides nothing.
 */
export function flareMessageListFillsViewport(viewport: { fromTop: number | null; fromBottom: number | null }): boolean {
  const { fromTop, fromBottom } = viewport;
  if (fromTop === null || fromBottom === null) return false;
  return fromTop + fromBottom <= Math.min(FLARE_MESSAGE_LIST_OLDER_WITHIN_PX, FLARE_MESSAGE_LIST_NEWER_WITHIN_PX);
}

/** What the list knows about one change of its window besides the rows. */
export interface FlareMessageListWindowChange {
  /** The reader asked for the latest messages (the back-to-latest key) and the host has not answered yet. */
  jumpRequested?: boolean;
  /** The new window is detached from the latest. */
  hasNewer?: boolean;
  /** The host's name for the window before and after the change (the core timeline view's `viewId`); empty is none. */
  previousWindowId?: string | null;
  windowId?: string | null;
}

/**
 * Whether the host replaced the window as a whole rather than grew or edited the one the reader is in
 * (`spec/message-list-paging-vectors.json` `windows`). `previous` and `next` are row keys in timeline order. Both
 * must have rows, and then any of: the host's name for the window changed from one name to another; the latest window
 * the reader asked for arrived (attached); no row of the new window was in the old one.
 */
export function flareMessageListWindowReplaced(
  previous: readonly string[],
  next: readonly string[],
  change: FlareMessageListWindowChange = {},
): boolean {
  if (previous.length === 0 || next.length === 0) return false;
  const before = change.previousWindowId ?? "";
  const after = change.windowId ?? "";
  if (before && after && before !== after) return true;
  if (change.jumpRequested && !change.hasNewer) return true;
  const kept = new Set(previous);
  return !next.some((key) => kept.has(key));
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

/** How far the end of the timeline may be below the viewport's bottom with the reader still at the bottom, in CSS pixels. */
export const FLARE_MESSAGE_LIST_BOTTOM_WITHIN_PX = 80;

/** The reader is at the bottom: the end of the timeline is at most `FLARE_MESSAGE_LIST_BOTTOM_WITHIN_PX` below it. */
export function flareMessageListAtBottom(fromBottom: number): boolean {
  return fromBottom <= FLARE_MESSAGE_LIST_BOTTOM_WITHIN_PX;
}

/**
 * What the list tells the host about the reader being at the bottom of the window (`atBottom` in
 * `spec/message-list-paging-vectors.json`). Each method is one step and answers what to tell the host after it: true,
 * false, or null for nothing. The list tells the host only when the answer changes, and once after its first layout.
 * A window replaced without the reader asking for it and a locate hold the answer at not at the bottom until the reader
 * moves the list, the list goes to its newest row for the reader, the latest window the reader asked for arrives or the
 * window empties; ending a hold answers from the last layout.
 */
export class FlareMessageListBottomReport {
  private reported: boolean | null = null;
  private held = false;
  private last: number | null = null;

  /** The answer last told to the host; null before the first one. */
  get value(): boolean | null {
    return this.reported;
  }

  /** A layout or a scroll the list measured: `fromBottom` is how far the end of the timeline is below the viewport. */
  layout(fromBottom: number): boolean | null {
    this.last = fromBottom;
    return this.tell(!this.held && flareMessageListAtBottom(fromBottom));
  }

  /** The host handed a window that replaces the one shown, without the reader asking for it. */
  replaced(): boolean | null {
    return this.hold();
  }

  /** The latest window the reader asked for (the back-to-latest key) arrived. */
  jumpedToLatest(): boolean | null {
    return this.release();
  }

  /** A locate took the reading position. */
  located(): boolean | null {
    return this.hold();
  }

  /** The reader moved the list themselves. */
  readerMoved(): boolean | null {
    return this.release();
  }

  /** The list went to its newest row for the reader: the new-messages key, or a message of the reader's own. */
  wentToLatest(): boolean | null {
    return this.release();
  }

  /** The window lost all its rows: an empty list is at its bottom. */
  emptied(): boolean | null {
    this.held = false;
    return this.layout(0);
  }

  /** Another conversation: the list starts over and answers once more after its first layout. */
  anotherConversation(): void {
    this.reported = null;
    this.held = false;
    this.last = null;
  }

  private hold(): boolean | null {
    this.held = true;
    return this.reported === true ? this.tell(false) : null;
  }

  private release(): boolean | null {
    this.held = false;
    return this.last === null ? null : this.layout(this.last);
  }

  private tell(atBottom: boolean): boolean | null {
    if (this.reported === atBottom) return null;
    this.reported = atBottom;
    return atBottom;
  }
}
