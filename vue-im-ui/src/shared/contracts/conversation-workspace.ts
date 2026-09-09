/**
 * ConversationWorkspace — the one place where the inbox / timeline / detail panes
 * decide between host content, a skeleton, an empty explanation and a failure with
 * recovery. Pure logic only: no data ownership, no network, no timers.
 */

/** Which pane a state / retry belongs to. */
export type WorkspacePaneKey = "list" | "chat" | "detail";
export const workspacePaneKeys: readonly WorkspacePaneKey[] = ["list", "chat", "detail"];

/**
 * Host-reported load status of a single pane. Panes are independent: a failing
 * timeline never degrades an inbox that already loaded.
 */
export type WorkspacePaneStatus = "ready" | "loading" | "empty" | "failure";
export const workspacePaneStatuses: readonly WorkspacePaneStatus[] = ["ready", "loading", "empty", "failure"];

export interface WorkspacePaneState {
  /** Defaults to "ready"; an unknown value degrades to the host content. */
  status?: WorkspacePaneStatus;
  /** User-facing text: the empty explanation, or the failure cause. */
  message?: string;
  /** Recovery action label. Without it no button is offered, only the reason. */
  actionLabel?: string;
}

/** What a pane actually renders. */
export type WorkspacePaneRender = "content" | "skeleton" | "empty" | "failure";

/**
 * Map a host pane state onto what to render.
 *
 * A missing state, "ready", and any status string the host made up all fall back
 * to the content slot: an unrecognised status must never blank a pane, throw, or
 * fake an empty list.
 */
export function paneRender(state?: WorkspacePaneState | null): WorkspacePaneRender {
  switch (state?.status) {
    case "loading":
      return "skeleton";
    case "empty":
      return "empty";
    case "failure":
      return "failure";
    default:
      return "content";
  }
}

/**
 * Whether the pane failure offers a recovery button.
 * Needs all three: an actual failure, a non-blank label, and a host handler —
 * a button the host cannot service is worse than no button.
 */
export function paneRetryVisible(state: WorkspacePaneState | null | undefined, hasRetry: boolean): boolean {
  if (!hasRetry) return false;
  if (paneRender(state) !== "failure") return false;
  const label = state?.actionLabel;
  return typeof label === "string" && label.trim().length > 0;
}

/** Tone of the workspace-wide banner (offline / reconnecting / session expired). */
export type WorkspaceBannerTone = "info" | "warning" | "error" | "success";

export interface WorkspaceBanner {
  tone?: WorkspaceBannerTone;
  message: string;
  actionLabel?: string;
}

/**
 * Whether the cross-pane banner shows at all. Blank or whitespace-only messages
 * are not a banner — they would render an empty coloured strip above the panes.
 * The banner is independent of pane state: an offline banner can sit above a
 * list that still reads fine from cache.
 */
export function workspaceBannerVisible(banner?: WorkspaceBanner | null): boolean {
  const message = banner?.message;
  return typeof message === "string" && message.trim().length > 0;
}

/** Whether the banner's inline action renders (non-blank label + host handler). */
export function workspaceBannerActionVisible(banner: WorkspaceBanner | null | undefined, hasAction: boolean): boolean {
  if (!hasAction || !workspaceBannerVisible(banner)) return false;
  const label = banner?.actionLabel;
  return typeof label === "string" && label.trim().length > 0;
}

/** StatusBanner tone for a workspace tone; "error" is StatusBanner's "danger". */
export function workspaceBannerTone(tone?: WorkspaceBannerTone): "info" | "success" | "warning" | "danger" {
  switch (tone) {
    case "warning":
      return "warning";
    case "error":
      return "danger";
    case "success":
      return "success";
    default:
      return "info";
  }
}

/** Skeleton shape per pane: rows for the inbox, bubbles for the timeline, a card for details. */
export function paneSkeletonVariant(pane: WorkspacePaneKey): "conversation" | "message" | "profile" {
  switch (pane) {
    case "chat":
      return "message";
    case "detail":
      return "profile";
    default:
      return "conversation";
  }
}
