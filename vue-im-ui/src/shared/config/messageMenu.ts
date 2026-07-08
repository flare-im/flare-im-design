import type { MessageLike } from "../contracts/messageRow";

export type MessageMenuActionId =
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

export interface MessageMenuConfig {
  actions?: MessageMenuActionsConfig;
  resolveVisible?: (ctx: MessageMenuResolveContext) => MessageMenuActionsConfig | void;
  resolveMediaAction?: (
    ctx: MessageMenuResolveContext,
  ) => MessageMenuMediaAction | null | void;
}

export const DEFAULT_MESSAGE_MENU_ACTIONS: Record<MessageMenuActionId, boolean> = {
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
  let resolveMediaAction: MessageMenuConfig["resolveMediaAction"];

  for (const layer of layers) {
    if (!layer) continue;
    if (layer.actions) Object.assign(actions, layer.actions);
    if (layer.resolveVisible) resolveVisibleList.push(layer.resolveVisible);
    if (layer.resolveMediaAction) resolveMediaAction = layer.resolveMediaAction;
  }

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

  return { actions, resolveVisible, resolveMediaAction };
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
