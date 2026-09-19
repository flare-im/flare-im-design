/**
 * UnknownMessage contract — pure logic shared by all four platforms.
 *
 * A message whose content type this client cannot render must still say
 * something a person can act on. Printing the raw type token (`[flare.poll.v2]`)
 * as the message body tells the reader nothing and looks like a rendering bug.
 * So the presentation is split in three: a human title, a human body, and the
 * raw type kept as a secondary diagnostic line for support and bug reports.
 *
 * The host owns every string: it knows which extension it shipped, whether the
 * sender attached a plain-text fallback, and what an upgrade path looks like.
 */

export interface UnknownMessageInput {
  /** Raw wire content type, e.g. "flare.poll.v2". Shown as diagnostic, never as the body. */
  contentType?: string;
  /** Human name for the type when the host knows it, e.g. "投票". */
  label?: string;
  /** Plain-text fallback the sender's client attached; the most useful body when present. */
  summary?: string;
  /** Generic explanation used when there is no summary. */
  hint: string;
  /** Title used when the host has no human name for the type. */
  unsupportedText: string;
}

export interface UnknownMessagePresentation {
  /** Human title: the host's label, else the generic "unsupported type" wording. */
  title: string;
  /** Human body: the sender's fallback text, else the generic hint. */
  body: string;
  /** Raw content type for the diagnostic row; empty means render no diagnostic. */
  diagnostic: string;
  /** True when `body` is the sender's real fallback rather than the generic hint. */
  hasSummary: boolean;
}

function clean(value: string | null | undefined): string {
  return (value ?? "").trim();
}

/**
 * Derives what to show. Deterministic and side-effect free, so the four
 * platforms cannot drift on which string wins.
 */
export function unknownMessagePresentation(input: UnknownMessageInput): UnknownMessagePresentation {
  const label = clean(input.label);
  const summary = clean(input.summary);
  return {
    title: label || clean(input.unsupportedText),
    body: summary || clean(input.hint),
    diagnostic: clean(input.contentType),
    hasSummary: summary.length > 0,
  };
}
