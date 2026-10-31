/**
 * The trip a tapped quote takes when the message it names is not loaded yet: ask the list, read a page of
 * older history, ask again, and stop with one of three answers.
 *
 * The rule is shared with the Flutter, SwiftUI and Compose kits and tested against
 * `spec/locate-orchestration-vectors.json`. It lives here rather than in each app because all four were
 * writing it, and writing it differently: the page budgets were 24, 20, 5 and 24, only one of them waited
 * for the list to draw the page it had just read, and only one stopped when the reader left the
 * conversation.
 */
export type FlareLocateOutcome = "shown" | "notInHistory" | "cancelled";

export interface FlareLocateOptions {
  /** Asks the list to show the message; answers whether the list had it. */
  showInList: () => boolean | Promise<boolean>;
  /** Whether there is older history left to read. */
  hasOlder: () => boolean;
  /** Reads one older page; answers whether it brought anything in. A page that failed answers false. */
  readOlder: () => void | Promise<void> | boolean | Promise<boolean>;
  /** Lets the list draw one pass, so a row that has just arrived can be found. */
  settle: () => void | Promise<void>;
  /** False once the reader has left this conversation: the trip then ends without a word. */
  isCurrent: () => boolean;
}

/** Older pages one locate may read before it gives up. */
export const flareLocateMaxPages = 24;

/**
 * How many more times the list is asked after the history is spent. The rows of the last page read may not
 * be drawn yet, and a list answers for the pass it last drew.
 */
export const flareLocateSettleAttempts = 6;

export async function flareLocateMessage(options: FlareLocateOptions): Promise<FlareLocateOutcome> {
  let advanced = true;
  let pages = 0;
  for (;;) {
    if (!options.isCurrent()) return "cancelled";
    if (await options.showInList()) return "shown";
    if (!(options.hasOlder() && advanced && pages < flareLocateMaxPages)) break;
    // A reader that answers nothing is read as "the page arrived": only an explicit false ends the search.
    advanced = (await options.readOlder()) !== false;
    pages += 1;
    await options.settle();
  }
  for (let attempt = 0; attempt < flareLocateSettleAttempts; attempt += 1) {
    if (!options.isCurrent()) return "cancelled";
    await options.settle();
    if (await options.showInList()) return "shown";
  }
  return "notInHistory";
}

/** The message a locate opens a window around: its id (server or client), and its seq when the caller has it. */
export interface FlareLocateAnchor {
  messageId: string;
  seq?: number;
}

export interface FlareLocateAroundOptions {
  /** The message to show. */
  anchor: FlareLocateAnchor;
  /** Asks the list to show the message with this id; answers whether the list had it. */
  showInList: (messageId: string) => boolean | Promise<boolean>;
  /**
   * Opens the timeline around the anchor (a timeline view opened with an anchor). Answers the anchor key — the row
   * key the list will draw the message with — or nothing (null, empty or blank) when the message is not in the
   * history. A failed open answers nothing too.
   */
  openAround: (anchor: FlareLocateAnchor) => string | null | undefined | Promise<string | null | undefined>;
  /** Lets the list draw one pass, so the window the host has just opened can be found. */
  settle: () => void | Promise<void>;
  /** False once the reader has left this conversation: the trip then ends without a word. */
  isCurrent: () => boolean;
}

/**
 * The same trip when the host can open a window around the message instead of paging back to it: ask the list,
 * open once around the anchor, then let the list draw and ask for the anchor key up to `flareLocateSettleAttempts`
 * times (`spec/locate-orchestration-vectors.json` `around`). The list scrolls to the row and marks it itself.
 */
export async function flareLocateMessageAround(options: FlareLocateAroundOptions): Promise<FlareLocateOutcome> {
  if (!options.isCurrent()) return "cancelled";
  if (await options.showInList(options.anchor.messageId)) return "shown";
  if (!options.isCurrent()) return "cancelled";
  const key = String((await options.openAround(options.anchor)) ?? "").trim();
  if (!options.isCurrent()) return "cancelled";
  if (!key) return "notInHistory";
  for (let attempt = 0; attempt < flareLocateSettleAttempts; attempt += 1) {
    if (!options.isCurrent()) return "cancelled";
    await options.settle();
    if (await options.showInList(key)) return "shown";
  }
  return "notInHistory";
}
