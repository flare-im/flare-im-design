import type { MessageLike } from "../contracts/messageRow";
import type { MessageActionAvailability } from "../../utils/messageActionAvailability";

export type MessageMenuActionId =
  | "react"
  | "reply"
  | "forward"
  | "multiSelect"
  | "edit"
  | "recall"
  | "resend"
  | "pin"
  | "pinSelf"
  | "unpin"
  | "preview"
  | "downloadMedia"
  | "openMediaFolder"
  | "copy"
  | "mark"
  | "delete";

export type MessageMenuMediaAction = "downloadMedia" | "openMediaFolder";

export type MessageMenuActionsConfig = Partial<Record<MessageMenuActionId, boolean>>;

export interface MessageHoverToolbarConfig {
  reactions?: boolean;
  quickReply?: boolean;
  moreMenu?: boolean;
}

export const DEFAULT_MESSAGE_HOVER_TOOLBAR_CONFIG: Required<MessageHoverToolbarConfig> = {
  reactions: true,
  quickReply: true,
  moreMenu: true,
};

export interface MessageMenuResolveContext {
  message: MessageLike;
  currentUserId: string;
  isSelf: boolean;
  isRecalled: boolean;
  canEdit: boolean;
  isPinned: boolean;
  isFailed: boolean;
  hasDownloadableMedia: boolean;
}

/**
 * The host's snapshot of the core's action availability for a message (message.action_availability, what the native
 * kits' FlareMessageMenuSource.availability reads), or null/undefined while the host has none. A field it gives can
 * only switch an action off: the menu offers an action when the kit's own rule and the snapshot both allow it, so a
 * plugin card the core will not forward has no "forward". A field it leaves out keeps the kit's rule.
 */
export type MessageMenuAvailability = (message: MessageLike) => Partial<MessageActionAvailability> | null | undefined;

export interface MessageMenuConfig {
  actions?: MessageMenuActionsConfig;
  resolveVisible?: (ctx: MessageMenuResolveContext) => MessageMenuActionsConfig | void;
  resolveMediaAction?: (
    ctx: MessageMenuResolveContext,
  ) => MessageMenuMediaAction | null | void;
  /** The core's availability for a message ({@link MessageMenuAvailability}). */
  availability?: MessageMenuAvailability;
}

export const DEFAULT_MESSAGE_MENU_ACTIONS: Record<MessageMenuActionId, boolean> = {
  react: true,
  reply: true,
  forward: true,
  multiSelect: true,
  edit: true,
  recall: true,
  resend: true,
  pin: true,
  pinSelf: true,
  unpin: true,
  preview: true,
  downloadMedia: true,
  openMediaFolder: true,
  copy: true,
  mark: true,
  delete: true,
};

export function mergeMessageMenuConfig(...layers: Array<MessageMenuConfig | undefined | null>): MessageMenuConfig {
  const actions: MessageMenuActionsConfig = { ...DEFAULT_MESSAGE_MENU_ACTIONS };
  const resolveVisibleList: NonNullable<MessageMenuConfig["resolveVisible"]>[] = [];
  const availabilityList: MessageMenuAvailability[] = [];
  let resolveMediaAction: MessageMenuConfig["resolveMediaAction"];

  for (const layer of layers) {
    if (!layer) continue;
    if (layer.actions) Object.assign(actions, layer.actions);
    if (layer.resolveVisible) resolveVisibleList.push(layer.resolveVisible);
    if (layer.resolveMediaAction) resolveMediaAction = layer.resolveMediaAction;
    if (layer.availability) availabilityList.push(layer.availability);
  }

  // Every layer's snapshot narrows: an action one of them switches off stays off.
  const availability: MessageMenuAvailability | undefined =
    availabilityList.length === 0
      ? undefined
      : availabilityList.length === 1
        ? availabilityList[0]
        : (message) => {
            let merged: Partial<MessageActionAvailability> | undefined;
            for (const fn of availabilityList) {
              const snapshot = fn(message);
              if (!snapshot) continue;
              merged ??= {};
              for (const [key, allowed] of Object.entries(snapshot) as [keyof MessageActionAvailability, boolean][]) {
                if (typeof allowed === "boolean") merged[key] = (merged[key] ?? true) && allowed;
              }
            }
            return merged;
          };

  const resolveVisible =
    resolveVisibleList.length === 0
      ? undefined
      : (ctx: MessageMenuResolveContext) => {
          const merged: MessageMenuActionsConfig = {};
          for (const fn of resolveVisibleList) {
            const partial = fn(ctx);
            if (partial) Object.assign(merged, partial);
          }
          return Object.keys(merged).length > 0 ? merged : undefined;
        };

  return { actions, resolveVisible, resolveMediaAction, availability };
}

/**
 * The kit's own availability narrowed by a host snapshot: each field the snapshot gives as false switches that action
 * off; nothing switches an action on that the kit's rule leaves off. Never mutates its inputs.
 */
export function narrowMessageActionAvailability(
  own: MessageActionAvailability,
  snapshot: Partial<MessageActionAvailability> | null | undefined,
): MessageActionAvailability {
  if (!snapshot) return own;
  const narrowed = { ...own };
  for (const key of Object.keys(narrowed) as (keyof MessageActionAvailability)[]) {
    if (snapshot[key] === false) narrowed[key] = false;
  }
  return narrowed;
}

export function isMessageMenuActionEnabled(
  config: MessageMenuConfig,
  actionId: MessageMenuActionId,
  ctx: MessageMenuResolveContext,
): boolean {
  const base = config.actions?.[actionId] ?? DEFAULT_MESSAGE_MENU_ACTIONS[actionId] ?? false;
  if (!base) return false;
  const resolved = config.resolveVisible?.(ctx);
  if (resolved && actionId in resolved) {
    return resolved[actionId] !== false;
  }
  return true;
}

/** The host listener each menu action needs; `copy` is handled inside the kit. */
const MENU_ACTION_LISTENERS: Partial<Record<MessageMenuActionId, string>> = {
  react: "onReact",
  reply: "onReply",
  forward: "onForward",
  multiSelect: "onMultiSelect",
  edit: "onEdit",
  recall: "onRecall",
  resend: "onResend",
  pin: "onPin",
  pinSelf: "onPin",
  unpin: "onPin",
  preview: "onPreview",
  downloadMedia: "onMediaAction",
  openMediaFolder: "onMediaAction",
  mark: "onMark",
  delete: "onDelete",
};

/**
 * Actions whose intent no host listener handles, switched off. A menu entry
 * nobody handles is a control that does nothing, so it is not offered — the same
 * rule the kit applies to retry and empty-state actions. `listeners` are the
 * component's vnode props (`onReply`, `onPin`, …).
 */
export function unhandledMessageMenuActions(listeners: Readonly<Record<string, unknown>> | null | undefined): MessageMenuActionsConfig {
  const unhandled: MessageMenuActionsConfig = {};
  for (const [action, listener] of Object.entries(MENU_ACTION_LISTENERS) as [MessageMenuActionId, string][]) {
    if (!listeners?.[listener]) unhandled[action] = false;
  }
  return unhandled;
}
