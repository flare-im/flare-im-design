export type FlareContentElem = Record<string, unknown> & {
  contentType: string;
};

export type FlareMessageContentLike = {
  contentType?: string;
  data?: Record<string, unknown>;
};

export type FlareBusinessDetailRow = {
  key: string;
  label: string;
  value: string;
  tone?: "default" | "success" | "warning" | "danger" | "info";
};

/** One aggregated emoji reaction under a message bubble. */
export type FlareReactionGroup = {
  /** The emoji / reaction glyph (e.g. "👍"). */
  emoji: string;
  count: number;
  /** Whether the current user is among the reactors — drives the active pill. */
  reactedBySelf?: boolean;
  /** Display names of reactors, newest first — surfaced in the tooltip / popover. */
  users?: string[];
};
