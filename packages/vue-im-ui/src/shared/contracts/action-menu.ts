/**
 * Shared action semantics and the action menu. `FlareActionItem` is the one action
 * descriptor of the kit: composer actions and header actions extend it, and every small
 * menu (a row's context menu, a header's add and more menus, a message's dropdown, a
 * host's own "new" or "more" button) draws it. Flutter, SwiftUI and Compose carry the
 * same fields and the same grouping rule.
 */

export type FlareActionIntent = string;

/** Shared action semantics. Domain action types add only fields they genuinely need. */
export interface FlareActionItem<TIcon = string> {
  id: string;
  label: string;
  icon?: TIcon;
  /** Menus draw a separator where the group changes. */
  group?: string;
  order?: number;
  /** False hides the action. */
  visible?: boolean;
  /** False keeps the action visible but unavailable. */
  enabled?: boolean;
  badge?: string;
  intent?: FlareActionIntent;
  accessibilityLabel?: string;
  /** Why the action is unavailable; shown and announced with it. */
  disabledReason?: string;
  /** Set to make the action a toggle; true draws it on (a pressed button, a checked menu item). */
  pressed?: boolean;
  /** Destructive: drawn in the error text colour. */
  danger?: boolean;
}

/** How a menu appears: `auto` is a bottom sheet on phones and a menu anchored to its trigger elsewhere. */
export type FlareActionMenuPresentation = "auto" | "anchored" | "sheet";

/** One drawn entry: an action, or the separator that opens a new group. */
export type FlareActionMenuEntry<TIcon = string> =
  | { kind: "item"; item: FlareActionItem<TIcon> }
  | { kind: "separator"; key: string };

/**
 * The entries to draw, in host order — the kit never sorts. Hidden actions are left
 * out. A separator comes before an action whose `group` is set and differs from the
 * last group seen, unless nothing precedes it; an action without a group stays in the
 * current one.
 */
export function actionMenuEntries<TIcon>(items: readonly FlareActionItem<TIcon>[]): FlareActionMenuEntry<TIcon>[] {
  const entries: FlareActionMenuEntry<TIcon>[] = [];
  let group: string | undefined;
  for (const item of items) {
    if (item.visible === false) continue;
    if (item.group !== undefined && item.group !== group) {
      if (entries.length > 0) entries.push({ kind: "separator", key: `separator:${item.id}` });
      group = item.group;
    }
    entries.push({ kind: "item", item });
  }
  return entries;
}
