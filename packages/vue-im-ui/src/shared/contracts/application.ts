import { flareLayout } from "../../design-system/theme/layout-tokens";
import type { WorkspaceBanner, WorkspacePaneState } from "./conversation-workspace";
import {
  FLARE_BREAKPOINT_DESKTOP_MIN,
  FLARE_BREAKPOINT_TABLET_MIN,
  FLARE_BREAKPOINT_WIDE_DESKTOP_MIN,
} from "./layout";

export type FlareApplicationResponsiveMode = "mobile" | "tablet" | "desktop" | "wideDesktop";
export type FlareNavigationPresentation = "bottom" | "rail" | "sidebar" | "expandedSidebar";
export type FlareNavigationBadgeKind = "dot" | "count" | "mention";

export interface FlareNavigationBadge {
  kind: FlareNavigationBadgeKind;
  count?: number;
  label?: string;
}

export interface FlareNavigationItem {
  id: string;
  label: string;
  icon?: string;
  badge?: FlareNavigationBadge;
  disabled?: boolean;
  visible?: boolean;
  order?: number;
  capability?: string;
  intent?: FlareNavigationIntent;
  accessibilityLabel?: string;
}

export interface FlareNavigationGroup {
  id: string;
  label?: string;
  items: readonly FlareNavigationItem[];
}

export type FlareWorkspacePane = "primary" | "content" | "detail";
/** Keyboard commands a desktop shell emits; the host decides what each one does. */
export type FlareDesktopShellCommand =
  | "closeOverlay"
  | "openCommandPalette"
  | "openSearch"
  | "newConversation"
  | "toggleDetails"
  | "openSettings"
  | "moreActions";
export interface FlareWorkspaceState {
  activePane?: FlareWorkspacePane;
  primary?: WorkspacePaneState;
  content?: WorkspacePaneState;
  detail?: WorkspacePaneState;
  banner?: WorkspaceBanner;
}

/** How many panes a layout shows side by side: one vocabulary for every layout in the kit. */
export type FlareWorkspacePaneMode = "singlePane" | "dualPane" | "triplePane";
/** Where a detail goes: beside the panes, over them, in a pane's place (a page the host routes to), or nowhere. */
export type FlareWorkspaceDetailPresentation = "hidden" | "inline" | "overlay" | "route";

export interface FlareWorkspacePresentation {
  paneMode: FlareWorkspacePaneMode;
  navigation: FlareNavigationPresentation;
  detail: FlareWorkspaceDetailPresentation;
}

/** What a layout reports through `layoutChange` once it knows its width. */
export interface FlareLayoutChange {
  paneMode: FlareWorkspacePaneMode;
  detailMode: FlareWorkspaceDetailPresentation;
}

export type FlareIMFeatureId =
  | "conversations" | "contacts" | "groups" | "calls" | "search"
  | "media" | "savedMessages" | "settings" | "threads" | "reactions";

export interface FlareFeatureSet {
  enabled: readonly (FlareIMFeatureId | string)[];
}

export interface FlareCapabilitySet {
  enabled: readonly string[];
}

export interface FlareGroupCapabilities {
  invite?: boolean;
  remove?: boolean;
  promote?: boolean;
  demote?: boolean;
  mute?: boolean;
  leave?: boolean;
  dismiss?: boolean;
  rename?: boolean;
  changeAvatar?: boolean;
  editAnnouncement?: boolean;
}

export interface FlareConversationCapabilities {
  message?: boolean;
  call?: boolean;
  video?: boolean;
  mute?: boolean;
  pin?: boolean;
  search?: boolean;
  media?: boolean;
  details?: boolean;
}

export interface FlareContactCapabilities {
  message?: boolean;
  call?: boolean;
  video?: boolean;
  viewProfile?: boolean;
  block?: boolean;
  delete?: boolean;
}

export interface FlareCallCapabilities {
  mute?: boolean;
  speaker?: boolean;
  camera?: boolean;
  switchCamera?: boolean;
  hangup?: boolean;
  minimize?: boolean;
  restore?: boolean;
}

export type FlareViewStatus = "loading" | "ready" | "empty" | "error" | "offline";
export interface FlareViewState<T> {
  status: FlareViewStatus;
  data?: T;
  /** What went wrong, for `error` and `offline`; never the empty state's words (FR-057). */
  error?: string;
  /** What an empty list should say. Without it the container falls back to its own words. */
  emptyTitle?: string;
  /**
   * A failed refresh over content that is still worth showing: the rows stay and the failure is a
   * banner above them, instead of replacing everything a person was reading (FR-057).
   */
  stale?: boolean;
  hasMore?: boolean;
}

/** What a container draws for a state: the rows, the rows under a banner, or a state of its own. */
export type FlareViewPresentation = "content" | "contentWithNotice" | "state";

/**
 * How a list container presents a state (`spec/view-state-vectors.json`, the same table on four kits):
 * a failure keeps the content when the host marks it stale, and only replaces it when there is
 * nothing to keep.
 */
export function flareViewPresentation(status: FlareViewStatus, stale?: boolean): FlareViewPresentation {
  if (status === "ready") return "content";
  if (stale && (status === "error" || status === "offline")) return "contentWithNotice";
  return "state";
}

export interface FlareDataSource<TQuery, TResult> {
  read(query: TQuery): Promise<FlareViewState<TResult>>;
}

export interface FlareIMHostAdapter {
  conversations?: FlareDataSource<unknown, readonly unknown[]>;
  messages?: FlareDataSource<unknown, readonly unknown[]>;
  contacts?: FlareDataSource<unknown, readonly unknown[]>;
  groups?: FlareDataSource<unknown, readonly unknown[]>;
  presence?: FlareDataSource<unknown, unknown>;
  uploads?: FlareDataSource<unknown, unknown>;
  calls?: FlareDataSource<unknown, unknown>;
}

export type FlareNavigationIntent =
  | { type: "openConversation"; conversationId: string }
  | { type: "openContact"; contactId: string }
  | { type: "openGroup"; groupId: string }
  | { type: "openSearch"; query?: string }
  | { type: "openSettings"; sectionId?: string }
  | { type: "custom"; id: string; payload?: unknown };

export interface FlareIMAppConfiguration {
  features: FlareFeatureSet;
  navigation: readonly FlareNavigationGroup[];
  capabilities?: FlareCapabilitySet;
}

export interface FlareMessageActionExtension<TContext = unknown> {
  id: string;
  label: string;
  icon?: string;
  group?: "primary" | "organize" | "message" | "destructive";
  order?: number;
  visible?: boolean;
  enabled?: boolean | ((context: TContext) => boolean);
  capability?: string;
  intent?: string;
  accessibilityLabel?: string;
  disabledReason?: string;
  destructive?: boolean;
  available?: (context: TContext) => boolean;
}

export const FLARE_DEFAULT_IM_NAVIGATION: readonly FlareNavigationItem[] = [
  { id: "chats", label: "Chats", icon: "chats", order: 0 },
  { id: "contacts", label: "Contacts", icon: "people", order: 1 },
  { id: "profile", label: "Profile", icon: "person", order: 2 },
];

export const FLARE_DEFAULT_CONTACT_NAVIGATION: readonly FlareNavigationItem[] = [
  { id: "friends", label: "Friends", icon: "person", order: 0 },
  { id: "groups", label: "Groups", icon: "people", order: 1 },
  { id: "newFriends", label: "New Friends", icon: "person-add", order: 2 },
  { id: "favorites", label: "Favorites", icon: "star", order: 3 },
];

/** Defaults -> capabilities -> host configuration. A host list is a full replacement. */
export function resolveNavigationItems(
  defaults: readonly FlareNavigationItem[],
  items?: readonly FlareNavigationItem[],
  capabilities?: FlareCapabilitySet,
): FlareNavigationItem[] {
  const seen = new Set<string>();
  return (items ?? defaults)
    .map((item, index) => ({ item, index }))
    .filter(({ item }) => {
      if (!item.id || item.visible === false || seen.has(item.id)) return false;
      if (item.capability && !flareCapabilityEnabled(capabilities, item.capability)) return false;
      seen.add(item.id);
      return true;
    })
    .sort((left, right) =>
      (left.item.order ?? left.index) - (right.item.order ?? right.index)
      || left.index - right.index)
    .map(({ item }) => item);
}

export function flareFeatureEnabled(features: FlareFeatureSet, id: string): boolean {
  return features.enabled.includes(id);
}

export function flareCapabilityEnabled(capabilities: FlareCapabilitySet | undefined, id: string): boolean {
  return capabilities?.enabled.includes(id) ?? false;
}

export function resolveApplicationResponsiveMode(width: number, textScale = 1): FlareApplicationResponsiveMode {
  const safeWidth = Number.isFinite(width) ? Math.max(0, width) : 0;
  const scale = Number.isFinite(textScale) ? Math.max(1, textScale) : 1;
  const effectiveWidth = safeWidth / scale;
  if (effectiveWidth < FLARE_BREAKPOINT_TABLET_MIN) return "mobile";
  if (effectiveWidth < FLARE_BREAKPOINT_DESKTOP_MIN) return "tablet";
  if (effectiveWidth < FLARE_BREAKPOINT_WIDE_DESKTOP_MIN) return "desktop";
  return "wideDesktop";
}

export function resolveNavigationPresentation(mode: FlareApplicationResponsiveMode): FlareNavigationPresentation {
  switch (mode) {
    case "mobile": return "bottom";
    case "tablet": return "rail";
    case "wideDesktop": return "expandedSidebar";
    default: return "sidebar";
  }
}

/** The columns beside the chat, and the reader's text size. All in CSS px. */
export interface FlarePaneMetrics {
  /** Reader text size as a factor of the default; only the chat's minimum grows with it. */
  textScale?: number;
  /** Width of a navigation rail or sidebar drawn beside the panes. Default 0. */
  navigationWidth?: number;
  /** The list (primary) column. Default `primaryPaneDefaultWidth`. */
  primaryWidth?: number;
  /** The detail column. Default `detailPaneDefaultWidth`. */
  detailWidth?: number;
}

/** Measured container facts for a workspace: the pane metrics plus the width they are compared with. */
export interface FlareWorkspaceLayoutMetrics extends FlarePaneMetrics {
  /** Container width. When omitted the presentation is width-blind (desktop always inline). */
  width?: number;
}

/** Width the navigation presentation for `mode` occupies beside the panes. */
export function resolveNavigationWidth(mode: FlareApplicationResponsiveMode): number {
  switch (mode) {
    case "mobile": return 0;
    case "tablet": return flareLayout.navigationRailWidth;
    case "wideDesktop": return flareLayout.primaryPaneDefaultWidth;
    default: return flareLayout.primaryPaneMinWidth;
  }
}

/**
 * Width that `paneMode` needs side by side — the one pane rule of every layout in the kit (FR-110).
 * Two panes: navigation + list + a usable chat (`chatMinWidth` times the text scale, never less than
 * `chatMinWidth`); three: that plus the detail. Navigation, list and detail are drawn at fixed widths, so
 * only the chat grows with the text. A 72 px rail + 320 px list + 360 px chat = 752 px.
 */
export function paneModeMinWidth(paneMode: "dualPane" | "triplePane", metrics: FlarePaneMetrics = {}): number {
  const scale = Number.isFinite(metrics.textScale) ? Math.max(1, metrics.textScale as number) : 1;
  const two = Math.max(0, metrics.navigationWidth ?? 0)
    + Math.max(0, metrics.primaryWidth ?? flareLayout.primaryPaneDefaultWidth)
    + flareLayout.chatMinWidth * scale;
  return paneMode === "dualPane" ? two : two + Math.max(0, metrics.detailWidth ?? flareLayout.detailPaneDefaultWidth);
}

/** The most panes that fit side by side in `width` (a third only when there is a detail to show). */
export function resolvePaneMode(width: number, hasDetail = false, metrics: FlarePaneMetrics = {}): FlareWorkspacePaneMode {
  if (!(width >= paneModeMinWidth("dualPane", metrics))) return "singlePane";
  return hasDetail && width >= paneModeMinWidth("triplePane", metrics) ? "triplePane" : "dualPane";
}

export function resolveWorkspacePresentation(
  mode: FlareApplicationResponsiveMode,
  hasDetail = false,
  metrics?: FlareWorkspaceLayoutMetrics,
): FlareWorkspacePresentation {
  const width = metrics?.width;
  const measured = typeof width === "number" && Number.isFinite(width);
  const paneMetrics = { ...metrics, navigationWidth: metrics?.navigationWidth ?? resolveNavigationWidth(mode) };
  switch (mode) {
    case "mobile":
      return { paneMode: "singlePane", navigation: "bottom", detail: hasDetail ? "route" : "hidden" };
    case "tablet": {
      // A tablet's layout has no detail column: two panes at most, and a detail over them.
      if (measured && resolvePaneMode(width, false, paneMetrics) === "singlePane") {
        return { paneMode: "singlePane", navigation: "rail", detail: hasDetail ? "route" : "hidden" };
      }
      return { paneMode: "dualPane", navigation: "rail", detail: hasDetail ? "overlay" : "hidden" };
    }
    default: {
      const navigation = mode === "wideDesktop" ? "expandedSidebar" : "sidebar";
      const paneMode = measured ? resolvePaneMode(width, hasDetail, paneMetrics) : hasDetail ? "triplePane" : "dualPane";
      if (paneMode === "triplePane") return { paneMode, navigation, detail: "inline" };
      // Two panes: a detail opens over the chat rather than crushing the navigation column.
      if (paneMode === "dualPane") return { paneMode, navigation, detail: hasDetail ? "overlay" : "hidden" };
      return { paneMode, navigation, detail: hasDetail ? "route" : "hidden" };
    }
  }
}

export function resolveMessageActionExtensions<TContext>(
  extensions: readonly FlareMessageActionExtension<TContext>[],
  context: TContext,
  capabilities?: FlareCapabilitySet,
): FlareMessageActionExtension<TContext>[] {
  return extensions
    .map((action, index) => ({ action, index }))
    .filter(({ action }) =>
      action.visible !== false
      && (!action.capability || flareCapabilityEnabled(capabilities, action.capability))
      && (action.available?.(context) ?? true))
    .sort((left, right) =>
      (left.action.order ?? left.index) - (right.action.order ?? right.index)
      || left.index - right.index)
    .map(({ action }) => ({
      ...action,
      enabled: typeof action.enabled === "function" ? action.enabled(context) : action.enabled,
    }));
}
