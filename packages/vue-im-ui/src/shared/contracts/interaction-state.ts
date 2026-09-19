import type { MessageLifecycle } from "./message-lifecycle";

export type ComposerInteractionMode =
  | "idle" | "typing" | "mentioning" | "replying" | "editing" | "uploading"
  | "recording" | "sending" | "sendBlocked" | "offline" | "readOnly"
  | "slowMode" | "permissionDenied";

export type ComposerInteractionAction =
  | "type" | "send" | "newline" | "attach" | "mention" | "reply" | "edit"
  | "record" | "cancel" | "retry";

export interface ComposerInteractionInput {
  hasText?: boolean;
  mentioning?: boolean;
  replying?: boolean;
  editing?: boolean;
  uploading?: boolean;
  recording?: boolean;
  sending?: boolean;
  sendBlocked?: boolean;
  online?: boolean;
  readOnly?: boolean;
  slowMode?: boolean;
  permissionGranted?: boolean;
}

export function resolveComposerMode(input: ComposerInteractionInput): ComposerInteractionMode {
  if (input.readOnly) return "readOnly";
  if (input.permissionGranted === false) return "permissionDenied";
  if (input.online === false) return "offline";
  if (input.slowMode) return "slowMode";
  if (input.sendBlocked) return "sendBlocked";
  if (input.sending) return "sending";
  if (input.recording) return "recording";
  if (input.uploading) return "uploading";
  if (input.editing) return "editing";
  if (input.mentioning) return "mentioning";
  if (input.replying) return "replying";
  return input.hasText ? "typing" : "idle";
}

const BASE_COMPOSER_ACTIONS: ComposerInteractionAction[] = ["type", "newline", "send", "attach", "mention", "reply", "edit", "record"];

export function composerAllowedActions(mode: ComposerInteractionMode): ReadonlySet<ComposerInteractionAction> {
  switch (mode) {
    case "readOnly": return new Set();
    case "permissionDenied": return new Set(["cancel"]);
    case "offline": return new Set(["type", "newline", "attach", "cancel", "retry"]);
    case "slowMode":
    case "sendBlocked": return new Set(["type", "newline", "attach", "mention", "cancel"]);
    case "sending": return new Set(["cancel"]);
    case "recording": return new Set(["send", "cancel"]);
    case "uploading": return new Set(["type", "newline", "attach", "cancel"]);
    case "editing":
    case "mentioning":
    case "replying": return new Set(["type", "newline", "send", "attach", "mention", "cancel"]);
    default: return new Set(BASE_COMPOSER_ACTIONS);
  }
}

export type MessageInteractionMode =
  | "normal" | "hover" | "selected" | "multiSelected" | "sending" | "sent"
  | "delivered" | "read" | "failed" | "retrying" | "edited" | "recalled"
  | "deleted" | "ephemeral" | "expired";

export interface MessageInteractionInput {
  lifecycle: MessageLifecycle;
  hovered?: boolean;
  selected?: boolean;
  multiSelect?: boolean;
  retrying?: boolean;
}

export function resolveMessageMode(input: MessageInteractionInput): MessageInteractionMode {
  const { lifecycle } = input;
  if (lifecycle.mutation === "deleted") return "deleted";
  if (lifecycle.ephemeral === "expired") return "expired";
  if (lifecycle.mutation === "recalled") return "recalled";
  if (input.retrying) return "retrying";
  if (lifecycle.send === "failed" || lifecycle.transfer === "failed") return "failed";
  if (lifecycle.ephemeral !== "none") return "ephemeral";
  if (lifecycle.mutation === "edited") return "edited";
  if (input.multiSelect && input.selected) return "multiSelected";
  if (input.selected) return "selected";
  if (input.hovered) return "hover";
  if (lifecycle.send === "sending" || lifecycle.send === "draft") return "sending";
  if (lifecycle.read === "read") return "read";
  if (lifecycle.delivery === "delivered" || lifecycle.delivery === "partiallyDelivered") return "delivered";
  return lifecycle.send === "sent" ? "sent" : "normal";
}

export type MessageCapability =
  | "reply" | "reaction" | "copy" | "forward" | "mergeForward" | "multiSelect" | "edit"
  | "delete" | "recall" | "pin" | "unpin" | "save" | "translate" | "report"
  | "retry" | "openThread" | "jumpToQuote";

export interface MessageCapabilityInput {
  lifecycle: MessageLifecycle;
  own: boolean;
  canModerate?: boolean;
  supportsCopy?: boolean;
  supportsSave?: boolean;
  supportsTranslate?: boolean;
  supportsMergeForward?: boolean;
  reportable?: boolean;
  pinned?: boolean;
  hasThread?: boolean;
  hasQuote?: boolean;
}

/** Product-neutral action capability projection. Hosts still own permissions and commands. */
export function resolveMessageCapabilities(input: MessageCapabilityInput): ReadonlySet<MessageCapability> {
  const { lifecycle } = input;
  const terminal = lifecycle.mutation === "deleted"
    || lifecycle.mutation === "recalled"
    || lifecycle.ephemeral === "expired";
  const failed = lifecycle.send === "failed" || lifecycle.transfer === "failed";
  if (terminal) return new Set(input.canModerate ? ["delete"] : []);
  const capabilities = new Set<MessageCapability>(["multiSelect", "delete"]);
  if (failed) {
    if (input.own) capabilities.add("retry");
  } else {
    ["reply", "reaction", "forward"].forEach((action) => capabilities.add(action as MessageCapability));
    capabilities.add(input.pinned ? "unpin" : "pin");
    if (input.supportsMergeForward) capabilities.add("mergeForward");
    if (input.hasThread) capabilities.add("openThread");
    if (input.hasQuote) capabilities.add("jumpToQuote");
    if (input.supportsCopy !== false) capabilities.add("copy");
    if (input.supportsSave) capabilities.add("save");
    if (input.supportsTranslate) capabilities.add("translate");
    if (input.own && lifecycle.send === "sent") {
      capabilities.add("edit");
      capabilities.add("recall");
    }
    if (!input.own && input.reportable !== false) capabilities.add("report");
  }
  if (!input.own && !input.canModerate) capabilities.delete("delete");
  return capabilities;
}

export type MessageActionGroup = "primary" | "organize" | "message" | "destructive";
export type MessageActionPresentation = "contextMenu" | "hoverToolbar" | "commandPalette" | "actionSheet" | "bottomSheet";
export interface MessageAction { id: MessageCapability; group: MessageActionGroup; destructive: boolean; promoted: boolean }

const primaryActions = new Set<MessageCapability>(["reply", "reaction", "copy", "forward", "openThread"]);
const organizeActions = new Set<MessageCapability>(["pin", "unpin", "save", "translate", "multiSelect", "mergeForward"]);
const destructiveActions = new Set<MessageCapability>(["recall", "delete", "report"]);

/** Presentation projects one capability result; it never owns availability. */
export function resolveMessageActions(input: MessageCapabilityInput, presentation: MessageActionPresentation): MessageAction[] {
  return [...resolveMessageCapabilities(input)].map((id) => ({
    id,
    group: destructiveActions.has(id) ? "destructive" : organizeActions.has(id) ? "organize" : primaryActions.has(id) ? "primary" : "message",
    destructive: destructiveActions.has(id),
    promoted: presentation === "hoverToolbar" && primaryActions.has(id),
  }));
}

export interface SelectionState { selectedIds: ReadonlySet<string>; anchorId?: string }
export type SelectionEvent =
  | { type: "toggle"; id: string }
  | { type: "replace"; id: string }
  | { type: "extend"; id: string; orderedIds: readonly string[] }
  | { type: "clear" };

export function reduceSelection(state: SelectionState, event: SelectionEvent): SelectionState {
  if (event.type === "clear") return { selectedIds: new Set() };
  if (event.type === "replace") return { selectedIds: new Set([event.id]), anchorId: event.id };
  if (event.type === "toggle") {
    const selectedIds = new Set(state.selectedIds);
    selectedIds.has(event.id) ? selectedIds.delete(event.id) : selectedIds.add(event.id);
    return { selectedIds, anchorId: event.id };
  }
  const anchorIndex = state.anchorId ? event.orderedIds.indexOf(state.anchorId) : -1;
  const targetIndex = event.orderedIds.indexOf(event.id);
  if (anchorIndex < 0 || targetIndex < 0) return { selectedIds: new Set([event.id]), anchorId: event.id };
  const [start, end] = anchorIndex <= targetIndex ? [anchorIndex, targetIndex] : [targetIndex, anchorIndex];
  return { selectedIds: new Set(event.orderedIds.slice(start, end + 1)), anchorId: state.anchorId };
}

export type DesktopShortcutAction =
  | "search" | "commandPalette" | "newConversation" | "focusComposer" | "send"
  | "newline" | "closeOverlay" | "previousConversation" | "nextConversation"
  | "toggleDetails" | "reply" | "edit" | "delete" | "copy" | "forward" | "openThread";

export interface DesktopShortcutInput {
  key: string;
  primary?: boolean;
  alt?: boolean;
  shift?: boolean;
  scope?: "global" | "composer" | "conversation";
}

export function resolveDesktopShortcut(input: DesktopShortcutInput): DesktopShortcutAction | undefined {
  const key = input.key.toLowerCase();
  if (key === "escape") return "closeOverlay";
  if (input.primary && key === "k") return "commandPalette";
  if (input.primary && key === "f") return "search";
  if (input.primary && key === "n") return "newConversation";
  if (input.primary && input.shift && key === "d") return "toggleDetails";
  if (input.alt && key === "arrowup") return "previousConversation";
  if (input.alt && key === "arrowdown") return "nextConversation";
  if (input.scope === "composer" && key === "enter") return input.primary ? "send" : "newline";
  if (input.scope === "conversation" && input.primary && key === "c") return "copy";
  if (input.scope === "conversation" && !input.primary && !input.alt && key === "r") return "reply";
  if (input.scope === "conversation" && !input.primary && !input.alt && key === "e") return "edit";
  if (input.scope === "conversation" && !input.primary && !input.alt && key === "f") return "forward";
  if (input.scope === "conversation" && !input.primary && !input.alt && key === "t") return "openThread";
  if (input.scope === "conversation" && (key === "delete" || key === "backspace")) return "delete";
  return undefined;
}

export type SwipeIntent = "none" | "reply" | "conversationLeading" | "conversationTrailing";

export function resolveSwipeIntent(input: {
  deltaX: number;
  deltaY: number;
  target: "message" | "conversation";
  rtl?: boolean;
  multiSelect?: boolean;
  threshold?: number;
}): SwipeIntent {
  if (input.multiSelect) return "none";
  const threshold = input.threshold ?? 56;
  if (Math.abs(input.deltaX) < threshold || Math.abs(input.deltaX) < Math.abs(input.deltaY) * 1.25) return "none";
  const leading = input.rtl ? input.deltaX < 0 : input.deltaX > 0;
  if (input.target === "message") return leading ? "reply" : "none";
  return leading ? "conversationLeading" : "conversationTrailing";
}
