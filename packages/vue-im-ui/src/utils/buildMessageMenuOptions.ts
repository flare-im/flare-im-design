import type { Component } from "vue";
import { messageContentTypeForUi } from "./messageContent";
import {
  DEFAULT_MESSAGE_MENU_ACTIONS,
  isMessageMenuActionEnabled,
  mergeMessageMenuConfig,
  type MessageMenuActionId,
  type MessageMenuConfig,
  type MessageMenuResolveContext,
} from "../shared/config/messageMenu";
import { resolveMessageId, type MessageLike } from "../shared/contracts/messageRow";
import { resolveMessageStatus } from "./messageStatus";
import { messageMenuGlyph } from "./messageMenuIcons";
import type { FlareActionItem } from "../shared/contracts/action-menu";
import { hasDownloadableMessageMedia } from "./messageMedia";
import { messageActionAvailability } from "./messageActionAvailability";
import { translateFlare } from "../shared/i18n/messages";
import { resolveMessageActionExtensions, type FlareMessageActionExtension } from "../shared/contracts/application";

/** A host action appended to the message menu (report, translate, ...); `available` and `enabled` receive the menu context. */
export type MessageMenuExtension = FlareMessageActionExtension<MessageMenuResolveContext>;

/** Menu keys of host actions; the rest of the key is the action id. */
const EXTENSION_KEY_PREFIX = "action:";

export type MessageMenuSheetIcon =
  | "reply"
  | "forward"
  | "recall"
  | "resend"
  | "multi-select"
  | "mark"
  | "pin"
  | "pin-self"
  | "unpin"
  | "copy"
  | "edit"
  | "preview"
  | "download"
  | "folder"
  | "delete";

export type MessageMenuSheetItem = {
  key: string;
  label: string;
  /** A built-in menu icon, or a semantic Flare icon name for a host action. */
  icon?: MessageMenuSheetIcon | (string & {});
  danger?: boolean;
  disabled?: boolean;
};

export type MessageContextSheetModel = {
  showReactions: boolean;
  quickActions: MessageMenuSheetItem[];
  listActions: MessageMenuSheetItem[];
};

const EDITABLE_TYPES = new Set([1, 30, 31]);

export type MessageMenuTranslator = (
  key: string,
  params?: Record<string, string | number>,
) => string;

const MENU_LABEL_KEY: Record<string, string> = {
  reply: "messageMenu.reply",
  forward: "messageMenu.forward",
  recall: "messageMenu.recall",
  resend: "messageMenu.resend",
  "multi-select": "messageMenu.multiSelect",
  mark: "messageMenu.mark",
  pin: "messageMenu.pin",
  pinSelf: "messageMenu.pinSelf",
  unpin: "messageMenu.unpin",
  copy: "messageMenu.copy",
  edit: "messageMenu.edit",
  preview: "messageMenu.preview",
  downloadMedia: "messageMenu.downloadMedia",
  openMediaFolder: "messageMenu.openMediaFolder",
  delete: "messageMenu.delete",
  noop: "messageMenu.noActions",
};

function menuLabel(key: string, t?: MessageMenuTranslator): string {
  const i18nKey = MENU_LABEL_KEY[key];
  if (!i18nKey) return key;
  if (t) {
    const resolved = t(i18nKey);
    if (resolved !== i18nKey) return resolved;
  }
  return translateFlare(i18nKey);
}

function isPinned(message: MessageLike): boolean {
  return message.pinned === true;
}


function iconForKey(key: string): MessageMenuSheetIcon | undefined {
  const map: Record<string, MessageMenuSheetIcon> = {
    reply: "reply",
    forward: "forward",
    recall: "recall",
    "multi-select": "multi-select",
    mark: "mark",
    pin: "pin",
    pinSelf: "pin-self",
    unpin: "unpin",
    copy: "copy",
    edit: "edit",
    preview: "preview",
    downloadMedia: "download",
    openMediaFolder: "folder",
    delete: "delete",
    resend: "resend",
  };
  return map[key];
}

export function buildMessageMenuContext(
  message: MessageLike,
  currentUserId: string,
): MessageMenuResolveContext {
  const isSelf = message.senderId === currentUserId;
  return {
    message,
    currentUserId,
    isSelf,
    isRecalled: message.isRecalled,
    // The callback receives this presentation fact; authoritative permission
    // still belongs to the host.
    canEdit: false,
    isPinned: isPinned(message),
    isFailed: resolveMessageStatus(message) === "failed",
    hasDownloadableMedia: hasDownloadableMessageMedia(message),
  };
}

function enabled(
  config: MessageMenuConfig,
  actionId: MessageMenuActionId,
  ctx: MessageMenuResolveContext,
): boolean {
  return isMessageMenuActionEnabled(config, actionId, ctx);
}

export function buildMessageContextSheetModel(
  message: MessageLike,
  currentUserId: string,
  config?: MessageMenuConfig,
  t?: MessageMenuTranslator,
  extensions: readonly MessageMenuExtension[] = [],
): MessageContextSheetModel {
  const merged = mergeMessageMenuConfig(config);
  const ctx = buildMessageMenuContext(message, currentUserId);
  const quickActions: MessageMenuSheetItem[] = [];
  const listActions: MessageMenuSheetItem[] = [];

  const pushQuick = (key: string, danger = false) => {
    quickActions.push({
      key,
      label: menuLabel(key, t),
      icon: iconForKey(key),
      danger,
    });
  };

  const pushList = (key: string, danger = false) => {
    listActions.push({
      key,
      label: menuLabel(key, t),
      icon: iconForKey(key),
      danger,
    });
  };

  // Availability is resolved by the package-owned presentation policy and
  // pinned by spec/scenarios/message-action-availability.json.
  // menuConfig 仍可**关掉**某个动作（宿主定制），但不能打开规则不允许的动作。
  const can = messageActionAvailability(message, {
    currentUserId,
    isConnected: true,
    isPending: ["pending", "sending", "retrying"].includes(resolveMessageStatus(message)),
    isPinned: ctx.isPinned,
    isFailed: ctx.isFailed,
    multiSelectMode: false,
  });

  if (can.canReply && enabled(merged, "reply", ctx)) pushQuick("reply");
  if (can.canForward && enabled(merged, "forward", ctx)) pushQuick("forward");
  if (can.canRecall && enabled(merged, "recall", ctx)) pushQuick("recall", true);
  if (can.canResend && enabled(merged, "resend", ctx)) pushQuick("resend");

  if (can.canMultiSelect && enabled(merged, "multiSelect", ctx)) pushList("multi-select");
  if (can.canDelete && enabled(merged, "mark", ctx)) pushList("mark");
  if (can.canPin && enabled(merged, "pin", ctx)) pushList("pin");
  if (can.canPin && enabled(merged, "pinSelf", ctx)) pushList("pinSelf");
  if (can.canUnpin && enabled(merged, "unpin", ctx)) pushList("unpin");
  if (can.canCopy && enabled(merged, "copy", ctx)) pushList("copy");
  if (can.canMultiSelect && enabled(merged, "preview", ctx)) pushList("preview");
  const mediaAction = can.canSave && ctx.hasDownloadableMedia
    ? merged.resolveMediaAction?.(ctx)
    : null;
  if (mediaAction && enabled(merged, mediaAction, ctx)) pushList(mediaAction);
  if (can.canEdit && enabled(merged, "edit", ctx)) pushList("edit");
  if (can.canDelete && enabled(merged, "delete", ctx)) pushList("delete", true);

  // Host actions join the list: ordinary ones before delete, destructive ones after it.
  const hostItems: MessageMenuSheetItem[] = resolveMessageActionExtensions(extensions, ctx).map((action) => ({
    key: `${EXTENSION_KEY_PREFIX}${action.id}`,
    label: action.label,
    icon: action.icon,
    danger: Boolean(action.destructive || action.group === "destructive"),
    disabled: action.enabled === false,
  }));
  const deleteIndex = listActions.findIndex((item) => item.key === "delete");
  listActions.splice(deleteIndex < 0 ? listActions.length : deleteIndex, 0, ...hostItems.filter((item) => !item.danger));
  listActions.push(...hostItems.filter((item) => item.danger));

  if (quickActions.length === 0 && listActions.length === 0) {
    listActions.push({
      key: "noop",
      label: menuLabel("noop", t),
      disabled: true,
    });
  }

  return {
    showReactions: !ctx.isRecalled && enabled(merged, "react", ctx),
    quickActions,
    listActions,
  };
}

export function buildMessageMenuSheetItems(
  message: MessageLike,
  currentUserId: string,
  config?: MessageMenuConfig,
  t?: MessageMenuTranslator,
  extensions: readonly MessageMenuExtension[] = [],
): MessageMenuSheetItem[] {
  const model = buildMessageContextSheetModel(
    message,
    currentUserId,
    config,
    t,
    extensions,
  );
  return [...model.quickActions, ...model.listActions];
}

/**
 * The message menu as action items for a dropdown. It lists every available action; `omit`
 * names the ones the surface hosting the menu already shows as its own controls (the
 * desktop hover toolbar has a reply button), and nothing else is left out. Delete and the
 * destructive host actions after it form the trailing danger group, which the menu separates
 * from the rest; recall stays red in the main group.
 */
export function buildMessageMenuItems(
  message: MessageLike,
  currentUserId: string,
  config?: MessageMenuConfig,
  t?: MessageMenuTranslator,
  omit: readonly string[] = [],
  extensions: readonly MessageMenuExtension[] = [],
): FlareActionItem<Component>[] {
  const items: FlareActionItem<Component>[] = [];
  let dangerTail = false;
  for (const item of buildMessageMenuSheetItems(
    message,
    currentUserId,
    config,
    t,
    extensions,
  )) {
    if (omit.includes(item.key)) continue;
    if (!dangerTail && (item.key === "delete" || (item.danger && item.key.startsWith(EXTENSION_KEY_PREFIX)))) dangerTail = true;
    items.push({
      id: item.key,
      label: item.label,
      icon: messageMenuGlyph(item.icon),
      danger: item.danger,
      enabled: item.disabled ? false : undefined,
      group: dangerTail ? "danger" : undefined,
    });
  }
  return items;
}

export function resolveMessageMenuAction(
  message: MessageLike,
  key: string,
): { type: "noop" } | { type: "emit"; event: string; payload?: unknown } {
  const id = resolveMessageId(message);
  if (key.startsWith(EXTENSION_KEY_PREFIX)) {
    return { type: "emit", event: "action", payload: { id, actionId: key.slice(EXTENSION_KEY_PREFIX.length) } };
  }
  switch (key) {
    case "noop":
      return { type: "noop" };
    case "reply":
      return { type: "emit", event: "reply", payload: id };
    case "forward":
      return { type: "emit", event: "forward", payload: id };
    case "multi-select":
      return { type: "emit", event: "multiSelect", payload: id };
    case "edit":
      return { type: "emit", event: "edit", payload: id };
    case "recall":
      return { type: "emit", event: "recall", payload: id };
    case "resend":
      return {
        type: "emit",
        event: "resend",
        payload: id,
      };
    case "pin":
      return { type: "emit", event: "pin", payload: { id, pinned: true, scope: "conversation" } };
    case "pinSelf":
      return { type: "emit", event: "pin", payload: { id, pinned: true, scope: "self" } };
    case "unpin":
      return { type: "emit", event: "pin", payload: { id, pinned: false, scope: "conversation" } };
    case "preview":
      return { type: "emit", event: "preview", payload: id };
    case "downloadMedia":
      return {
        type: "emit",
        event: "mediaAction",
        payload: { id, action: "download" },
      };
    case "openMediaFolder":
      return {
        type: "emit",
        event: "mediaAction",
        payload: { id, action: "openFolder" },
      };
    case "copy":
      return { type: "emit", event: "copy", payload: id };
    case "mark":
      return { type: "emit", event: "mark", payload: id };
    case "delete":
      return { type: "emit", event: "delete", payload: id };
    default:
      return { type: "noop" };
  }
}

export { DEFAULT_MESSAGE_MENU_ACTIONS };
