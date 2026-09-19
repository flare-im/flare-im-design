#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";

const specPath = new URL("./components.json", import.meta.url);
const maturityPath = new URL("./component-maturity.json", import.meta.url);
const interactionsPath = new URL("./interaction-contracts.json", import.meta.url);
const patternsPath = new URL("./composition-patterns.json", import.meta.url);
const spec = JSON.parse(readFileSync(specPath, "utf8"));

const generalNames = `CommandPalette
Combobox
Autocomplete
SegmentedControl
SplitButton
Toolbar
Breadcrumb
Stepper
Accordion
Collapsible
Tree
TreeSelect
VirtualList
InfiniteList
ResizablePane
SplitView
AdaptivePane
Dock
FloatingPanel
ContextMenu
MenuBar
ShortcutHint
KeyboardKey
FocusRing
FocusScope
SearchDialog
FilterBar
ActionBar
BulkActionBar
InlineEdit
EditableText
CopyButton
PasswordInput
OTPInput
NumberInput
DatePicker
TimePicker
DateTimePicker
ColorPicker
FilePicker
UploadZone
DropZone
AvatarGroup
PresenceAvatar
UserPicker
MemberPicker
SkeletonGroup
ProgressCircle
ProgressBar
StatusIndicator
Banner
InlineAlert
Callout
EmptyState
ErrorState
OfflineState
PermissionState
ResultState
Timeline
ActivityFeed
MediaGrid
ImageGrid
Viewer
Lightbox`.split("\n");

const generalResolution = {
  Combobox: ["partial", "Select + SearchBar", "P2"], Autocomplete: ["composition", "SearchBar + SearchResults", "P2"],
  SplitButton: ["missing", null, "P2"], Toolbar: ["composition", "MessageBatchToolbar / ConversationBatchToolbar", "P2"],
  Breadcrumb: ["missing", null, "P3"], Accordion: ["missing", null, "P2"], Collapsible: ["missing", null, "P2"],
  Tree: ["missing", null, "P2"], TreeSelect: ["missing", null, "P3"], VirtualList: ["composition", "ConversationList / MessageList", "P1"],
  InfiniteList: ["composition", "MessageList loadOlder contract", "P1"], ResizablePane: ["composition", "DesktopWorkbench", "P1"],
  SplitView: ["composition", "ThreePaneLayout", "P1"], AdaptivePane: ["composition", "AppLayout", "P1"], Dock: ["composition", "CallDock", "P2"],
  FloatingPanel: ["composition", "DesktopWorkbench.overlayHost", "P2"], ContextMenu: ["composition", "MessageActionSheet / ConversationActionSheet", "P1"],
  MenuBar: ["missing", null, "P2"], ShortcutHint: ["composition", "CommandPalette command.shortcut", "P2"], KeyboardKey: ["composition", "ShortcutHint", "P3"],
  FocusRing: ["composition", "platform focus primitives + focus token", "P1"], FocusScope: ["composition", "DesktopWorkbench.focusPolicy", "P1"],
  SearchDialog: ["composition", "CommandPalette", "P2"], FilterBar: ["composition", "SearchPanel", "P2"], ActionBar: ["composition", "Button + Toolbar", "P2"],
  BulkActionBar: ["composition", "ConversationBatchToolbar / MessageBatchToolbar", "P1"], InlineEdit: ["partial", "Input + host commit/cancel", "P2"],
  EditableText: ["composition", "Input", "P2"], CopyButton: ["composition", "IconButton + host clipboard", "P2"], PasswordInput: ["partial", "Input with secure host integration", "P2"],
  OTPInput: ["partial", "Input composition", "P3"], NumberInput: ["composition", "Input + Stepper", "P2"], DateTimePicker: ["composition", "DatePicker + TimePicker", "P2"],
  ColorPicker: ["missing", null, "P3"], FilePicker: ["composition", "Composer attach intent", "P1"], UploadZone: ["partial", "TransferQueue + host file adapter", "P2"],
  DropZone: ["partial", "DesktopWorkbench filesDropped intent", "P2"], AvatarGroup: ["composition", "GroupMemberGrid", "P2"], PresenceAvatar: ["composition", "Avatar presence state", "P1"],
  UserPicker: ["composition", "ContactMatchList / ForwardPicker", "P2"], MemberPicker: ["composition", "MemberPanel", "P2"], SkeletonGroup: ["composition", "Skeleton", "P2"],
  ProgressCircle: ["composition", "TransferProgress", "P2"], ProgressBar: ["composition", "TransferProgress", "P1"], StatusIndicator: ["composition", "MessageStatus / Avatar", "P1"],
  Banner: ["composition", "StatusBanner", "P1"], InlineAlert: ["composition", "StatusBanner", "P1"], Callout: ["composition", "StatusBanner", "P2"],
  ErrorState: ["composition", "EmptyState + retry intent", "P1"], OfflineState: ["composition", "StatusBanner", "P1"], PermissionState: ["composition", "PermissionPrompt", "P1"],
  ResultState: ["composition", "EmptyState / StatusBanner", "P2"], Timeline: ["composition", "MessageList", "P2"], ActivityFeed: ["composition", "MomentCard / MessageList", "P3"],
  MediaGrid: ["composition", "ImageGrid", "P2"], Viewer: ["composition", "ImagePreviewModal", "P1"], Lightbox: ["composition", "ImagePreviewModal", "P2"],
};

const publicNames = new Set(spec.components.map((component) => component.name));
const platformNames = ["vue", "flutter", "compose", "ios"];
const general = generalNames.map((name) => {
  const resolution = generalResolution[name] ?? (publicNames.has(name) ? ["existing", name, "P1"] : ["missing", null, "P3"]);
  return {
    capability: name, status: resolution[0], target: resolution[1], priority: resolution[2],
    platformGap: resolution[0] === "missing" ? platformNames : [],
    suggestedContract: {
      ownership: "hostControlled",
      props: ["valueOrState", "disabled", "label"],
      events: ["intent", "change", "close"],
      states: ["default", "focus", "disabled", "loading", "empty", "error"],
    },
  };
});

const imGroups = {
  conversation: ["section", "pinned", "archived", "muted", "draft", "mention", "unreadCounter", "typingPreview", "lastMessageFailure", "presence", "channel", "group", "direct"],
  messageContent: ["text", "image", "multiImage", "video", "audio", "file", "location", "contactCard", "linkPreview", "richText", "codeBlock", "poll", "task", "calendarEvent", "miniApp", "topic", "system", "notice", "threadRoot", "forwarded", "mergedForward", "quoteReply", "edited", "recalled", "deleted", "readOnce", "burnAfterRead"],
  interaction: ["reaction", "quickReaction", "reply", "thread", "forward", "mergeForward", "multiSelect", "bulkDelete", "bulkPin", "copy", "save", "translate", "search", "report", "resend", "retry", "jumpToQuote", "scrollToUnread", "scrollToLatest", "newMessageIndicator"],
  composer: ["text", "richText", "mention", "emoji", "reply", "quote", "file", "image", "video", "voice", "location", "contact", "task", "event", "poll", "link", "multiImage", "command", "slashCommand", "draftPersistence", "editMessage", "sendDisabled", "slowMode", "permissionDenied", "networkDisconnected", "uploadQueue"],
};
const missingIm = new Set(["calendarEvent", "miniApp", "topic", "mergedForward"]);
const partialIm = new Set(["section", "typingPreview", "codeBlock", "quickReaction", "mergeForward", "save", "report", "quote", "location", "contact", "task", "event", "link", "multiImage", "draftPersistence", "slowMode"]);
const capabilityTarget = {
  section: "ConversationList", pinned: "ConversationRow", archived: "ConversationRow", muted: "ConversationRow", draft: "ConversationRow", mention: "ConversationRow", unreadCounter: "ConversationRow", typingPreview: "TypingIndicator", lastMessageFailure: "MessageStatus", presence: "Avatar", channel: "ConversationRow", group: "ConversationRow", direct: "ConversationRow",
  text: "TextMessage", image: "ImageMessage", multiImage: "ImageGrid", video: "VideoMessage", audio: "VoiceMessage", file: "FileMessage", location: "LocationMessage", contactCard: "ContactMessage", linkPreview: "LinkCardMessage", richText: "RichMarkdownInput", codeBlock: "MarkdownPreview", poll: "VoteMessage", task: "TaskMessage", system: "SystemMessage", notice: "AnnouncementBanner", threadRoot: "CommentThread", forwarded: "ForwardPicker", quoteReply: "ComposerReplyStrip", edited: "MessageLifecycle", recalled: "MessageLifecycle", deleted: "MessageLifecycle", readOnce: "MessageLifecycle", burnAfterRead: "MessageLifecycle",
  reaction: "ReactionSummary", quickReaction: "EmojiPicker", reply: "ComposerReplyStrip", thread: "CommentThread", forward: "ForwardPicker", mergeForward: "ForwardPicker", multiSelect: "MessageList", bulkDelete: "MessageBatchToolbar", bulkPin: "MessageBatchToolbar", copy: "MessageActionSheet", save: "MessageActionSheet", translate: "TranslationView", search: "SearchPanel", report: "MessageActionSheet", resend: "MessageList", retry: "MessageStatus", jumpToQuote: "MessageList", scrollToUnread: "UnreadDivider", scrollToLatest: "ScrollToLatest", newMessageIndicator: "ScrollToLatest",
  quote: "ComposerReplyStrip", command: "CommandPalette", slashCommand: "SlashCommandMenu", draftPersistence: "Composer", editMessage: "Composer", sendDisabled: "Composer", slowMode: "Composer", permissionDenied: "PermissionPrompt", networkDisconnected: "StatusBanner", uploadQueue: "TransferQueue",
};
const im = Object.entries(imGroups).flatMap(([group, names]) => names.map((capability) => ({
  group, capability,
  status: missingIm.has(capability) ? "missing" : partialIm.has(capability) ? "partial" : "existing",
  contract: capabilityTarget[capability] ?? "ComposerAction",
  priority: missingIm.has(capability) ? "P2" : partialIm.has(capability) ? "P2" : "P1",
  platforms: Object.fromEntries(platformNames.map((platform) => [platform, missingIm.has(capability) ? "planned" : partialIm.has(capability) ? "composition" : "supported"])),
  missing: missingIm.has(capability),
})));

const maturity = {
  schemaVersion: 1,
  policy: "Reuse a stable component or documented composition before adding a new primitive.",
  statusValues: ["existing", "composition", "partial", "missing"],
  general,
  im,
};

const platformModels = {
  vue: { path: "packages/vue-im-ui/src/shared/contracts/interaction-state.ts", symbols: ["resolveComposerMode", "resolveMessageMode", "reduceSelection", "resolveDesktopShortcut", "resolveSwipeIntent"] },
  flutter: { path: "packages/flutter-im-ui/lib/src/models/interaction_state.dart", symbols: ["resolveComposerMode", "resolveMessageMode", "reduceSelection", "resolveDesktopShortcut", "resolveSwipeIntent"] },
  compose: { path: "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/InteractionState.kt", symbols: ["resolveComposerMode", "resolveMessageMode", "reduceSelection", "resolveDesktopShortcut", "resolveSwipeIntent"] },
  ios: { path: "packages/ios-im-ui/Sources/FlareIMUI/Models/InteractionState.swift", symbols: ["resolveComposerMode", "resolveMessageMode", "reduceSelection", "resolveDesktopShortcut", "resolveSwipeIntent"] },
};

const interactions = {
  schemaVersion: 1,
  ownership: "UI state only; the host supplies authoritative lifecycle data and owns commands, persistence, capability, and permission decisions.",
  platformModels,
  stateMachines: {
    Composer: {
      states: ["idle", "typing", "mentioning", "replying", "editing", "uploading", "recording", "sending", "sendBlocked", "offline", "readOnly", "slowMode", "permissionDenied"],
      precedence: ["readOnly", "permissionDenied", "offline", "slowMode", "sendBlocked", "sending", "recording", "uploading", "editing", "mentioning", "replying", "typing", "idle"],
      events: ["textChanged", "mentionOpened", "replySelected", "editStarted", "uploadStarted", "recordingStarted", "sendRequested", "networkChanged", "permissionChanged", "cancelled"],
    },
    MessageBubble: { states: ["normal", "hover", "selected", "multiSelected", "sending", "sent", "delivered", "read", "failed", "retrying", "edited", "recalled", "deleted", "ephemeral", "expired"], events: ["hovered", "selected", "lifecycleChanged", "retryRequested"] },
    ConversationItem: { states: ["idle", "hover", "focused", "selected", "multiSelected", "swiping", "actionOpen", "disabled"], events: ["focus", "select", "extendSelection", "swipe", "openActions", "closeActions"] },
    MessageList: { states: ["loading", "ready", "empty", "loadingOlder", "olderError", "awayFromLatest", "multiSelect"], events: ["loadOlder", "prepend", "scroll", "jumpLatest", "enterMultiSelect", "exitMultiSelect"] },
    Search: { states: ["idle", "typing", "loading", "success", "empty", "error", "stale"], events: ["queryChanged", "submitted", "completed", "failed", "cancelled"] },
    Thread: { states: ["collapsed", "loading", "ready", "replying", "sending", "error", "closed"], events: ["open", "reply", "send", "retry", "close"] },
    Reaction: { states: ["idle", "pickerOpen", "optimistic", "confirmed", "failed"], events: ["open", "toggle", "ack", "reject", "close"] },
    Upload: { states: ["queued", "transferring", "paused", "completed", "failed", "cancelled"], events: ["start", "progress", "pause", "resume", "complete", "fail", "cancel", "retry"] },
    CallDock: { states: ["hidden", "incoming", "connecting", "active", "reconnecting", "ended", "failed"], events: ["show", "accept", "connect", "disconnect", "reconnect", "end", "fail"] },
    ContextMenu: { states: ["closed", "opening", "open", "busy", "error"], events: ["open", "move", "invoke", "complete", "fail", "close"] },
    MultiSelect: { states: ["inactive", "single", "range", "all", "busy"], events: ["replace", "toggle", "extend", "selectAll", "clear", "commit"] },
  },
  desktopShortcuts: {
    actions: ["search", "commandPalette", "newConversation", "focusComposer", "send", "newline", "closeOverlay", "previousConversation", "nextConversation", "toggleDetails", "reply", "edit", "delete", "copy"],
    reserved: { commandPalette: "Primary+K", search: "Primary+F", newConversation: "Primary+N", send: "Primary+Enter", closeOverlay: "Escape", previousConversation: "Alt+ArrowUp", nextConversation: "Alt+ArrowDown", toggleDetails: "Primary+Shift+D" },
    platformMapping: { vue: "KeyboardEvent.metaKey || ctrlKey", flutter: "SingleActivator.meta/control", compose: "KeyEvent isMetaPressed || isCtrlPressed", ios: "Commands and keyboardShortcut at host scene" },
  },
  mobileGestures: {
    swipeReply: { threshold: 56, horizontalDominance: 1.25, disabledWhen: ["multiSelect", "systemMessage", "gestureClaimedByMedia"], rtlAware: true },
    longPressMessage: { result: "open MessageActionSheet", disabledWhen: ["multiSelect", "busy"] },
    swipeConversation: { leading: "primary host action", trailing: "secondary host actions", destructiveRequiresConfirmation: true },
    platformMapping: { flutter: "GestureDetector/Dismissible adapter", compose: "pointerInput/swipeable adapter", ios: "DragGesture/swipeActions", vue: "Pointer gesture only on touch-capable compact layouts" },
  },
};

const patternNames = ["DesktopWorkbench", "ConversationWorkspace", "ChatWorkspace", "ThreadWorkspace", "SearchWorkspace", "MediaWorkspace", "ContactWorkspace", "GroupWorkspace", "CallWorkspace", "SettingsWorkspace", "NotificationWorkspace"];
const regionMap = {
  DesktopWorkbench: ["navigation", "primaryPane", "contentPane"], ConversationWorkspace: ["conversationList", "conversationContent"],
  ChatWorkspace: ["header", "messageList", "composer"], ThreadWorkspace: ["threadHeader", "rootMessage", "replyList", "composer"],
  SearchWorkspace: ["query", "filters", "results"], MediaWorkspace: ["filters", "mediaGrid", "preview"],
  ContactWorkspace: ["directory", "detail"], GroupWorkspace: ["groupSummary", "members", "permissions"],
  CallWorkspace: ["stage", "participants", "controls"], SettingsWorkspace: ["navigation", "settingsContent"],
  NotificationWorkspace: ["filters", "notificationList", "detail"],
};
const patterns = {
  schemaVersion: 1,
  patterns: Object.fromEntries(patternNames.map((name) => [name, {
    requiredRegions: regionMap[name],
    optionalRegions: ["status", "empty", "error", "overlay", "commandHost"],
    responsiveRules: ["Preserve the primary task", "Collapse supporting regions into a drawer, sheet, or route", "Never render hidden duplicate semantics"],
    stateModel: ["loading", "ready", "empty", "error", "offline", "permissionDenied"],
    accessibility: ["Named regions", "Deterministic focus order", "Focus restoration", "Reduced motion"],
    keyboard: ["Escape closes contextual layers", "Tab follows visual order", "Host may bind documented desktop actions"],
    platformAdaptations: { vue: "desktop-first workbench", flutter: "adaptive desktop/mobile shell", compose: "native navigation and sheets", ios: "NavigationSplitView/navigation stack and native sheets" },
  }])),
};

const outputs = [
  [maturityPath, maturity],
  [interactionsPath, interactions],
  [patternsPath, patterns],
];
const check = process.argv.includes("--check");
let stale = false;
for (const [path, value] of outputs) {
  const content = `${JSON.stringify(value, null, 2)}\n`;
  if (check) {
    if (readFileSync(path, "utf8") !== content) {
      console.error(`stale generated maturity artifact: ${path.pathname}`);
      stale = true;
    }
  } else {
    writeFileSync(path, content);
  }
}
if (stale) process.exit(1);
console.log(`maturity model ${check ? "current" : "written"}: ${general.length} General capabilities, ${im.length} IM capabilities, ${Object.keys(interactions.stateMachines).length} state machines, ${patternNames.length} patterns`);
