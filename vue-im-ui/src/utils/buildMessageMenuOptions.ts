import type { DropdownOption } from "naive-ui";
import { messageContentTypeForUi } from "./messageContent";
import {
  DEFAULT_MESSAGE_MENU_ACTIONS,
  isMessageMenuActionEnabled,
  mergeMessageMenuConfig,
  type MessageMenuActionId,
  type MessageMenuConfig,
  type MessageMenuResolveContext,
} from "../shared/config/messageMenu";
import type { MessageLike } from "../shared/contracts/messageRow";
import { messageStateToNumber } from "./messageState";
import { renderMessageMenuIcon } from "./messageMenuIcons";
import { hasDownloadableMessageMedia } from "./messageMedia";
import { messageActionAvailability } from "./messageActionAvailability";
import { translateFlare } from "../shared/i18n/messages";

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
  icon?: MessageMenuSheetIcon;
  danger?: boolean;
  disabled?: boolean;
};

export type MessageContextSheetModel = {
  showReactions: boolean;
  quickActions: MessageMenuSheetItem[];
  listActions: MessageMenuSheetItem[];
};

const EDITABLE_TYPES = new Set([1, 30, 31]);

const DROPDOWN_OMITTED_QUICK_ACTION_KEYS = new Set(["reply", "forward"]);

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

function messageKey(message: MessageLike): string {
  return message.clientMsgId || message.serverId;
}

function isPinned(message: MessageLike): boolean {
  return message.attributes?.pinned === "true";
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
    // canEdit 保留在 context 里只为兼容宿主的 resolveVisible 回调签名，
    // 判定本身已收敛到 messageActionAvailability。
    canEdit: false,
    isPinned: isPinned(message),
    isFailed: messageStateToNumber(message) === 5,
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

  // 可用性统一由 messageActionAvailability 判定（真源是核心 domain::message_actions，
  // 由 sdk-spec/message-action-vectors.json 逐位钉住）。
  // menuConfig 仍可**关掉**某个动作（宿主定制），但不能打开规则不允许的动作。
  const can = messageActionAvailability(message, {
    currentUserId,
    isConnected: true,
    isPending: messageStateToNumber(message) === 1,
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

  if (quickActions.length === 0 && listActions.length === 0) {
    listActions.push({
      key: "noop",
      label: menuLabel("noop", t),
      disabled: true,
    });
  }

  return {
    showReactions: !ctx.isRecalled,
    quickActions,
    listActions,
  };
}

export function buildMessageMenuSheetItems(
  message: MessageLike,
  currentUserId: string,
  config?: MessageMenuConfig,
  t?: MessageMenuTranslator,
): MessageMenuSheetItem[] {
  const model = buildMessageContextSheetModel(
    message,
    currentUserId,
    config,
    t,
  );
  return [...model.quickActions, ...model.listActions];
}

export function buildMessageMenuDropdownOptions(
  message: MessageLike,
  currentUserId: string,
  config?: MessageMenuConfig,
  t?: MessageMenuTranslator,
): DropdownOption[] {
  const options: DropdownOption[] = [];
  for (const item of buildMessageMenuSheetItems(
    message,
    currentUserId,
    config,
    t,
  )) {
    if (DROPDOWN_OMITTED_QUICK_ACTION_KEYS.has(item.key)) continue;
    if (item.key === "delete" && options.length > 0) {
      options.push({ type: "divider", key: "__menu_delete_divider__" });
    }
    options.push({
      label: item.label,
      key: item.key,
      disabled: item.disabled,
      icon: renderMessageMenuIcon(item.icon, item.danger),
      props: {
        class: [
          "message-menu-option",
          item.danger ? "message-menu-option--danger" : "",
        ]
          .filter(Boolean)
          .join(" "),
      },
    });
  }
  return options;
}

export function resolveMessageMenuAction(
  message: MessageLike,
  key: string,
): { type: "noop" } | { type: "emit"; event: string; payload?: unknown } {
  const id = messageKey(message);
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
        payload: message.clientMsgId || id,
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
