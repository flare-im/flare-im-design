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
