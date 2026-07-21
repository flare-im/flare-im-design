<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, ref, watch, type Component } from "vue";
import {
  AddCircleOutline,
  AddOutline,
  AppsOutline,
  AtOutline,
  CalendarOutline,
  ChatbubblesOutline,
  CheckboxOutline,
  ChevronDownOutline,
  ChevronUpOutline,
  CloseOutline,
  CodeSlashOutline,
  CodeWorkingOutline,
  ContractOutline,
  DocumentTextOutline,
  ExpandOutline,
  FolderOpenOutline,
  HappyOutline,
  ImageOutline,
  LinkOutline,
  ListOutline,
  LocationOutline,
  MegaphoneOutline,
  MicOutline,
  NotificationsOutline,
  ReaderOutline,
  RemoveOutline,
  ReorderThreeOutline,
  SendOutline,
  TextOutline,
  VideocamOutline,
} from "../../shared/icon-glyphs";
import { NButton, NIcon, NInput } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import ComposerRichMarkdownInput, {
  type RichHeadingLevel,
  type RichMarkdownFormatState,
} from "./ComposerRichMarkdownInput.vue";

type ComposerPanel = "emoji" | "sticker" | "more" | null;
export type FlareComposerMentionCandidate = {
  userId: string;
  label?: string;
  avatarUrl?: string;
};
/** Tone tints available to the "+" attach grid. Unknown tones simply render neutral. */
export type FlareComposerActionTone =
  | "amber" | "cyan" | "green" | "indigo" | "violet" | "rose"
  | "lime" | "sky" | "emerald" | "fuchsia" | "yellow" | "red";
/**
 * One entry in the customizable "+" attach menu. Tenants pass their own list via
 * `attach-actions` — `op` is the id emitted on `build`, `icon` is any Vue component
 * (e.g. a `@vicons` glyph), `tone` tints the tile. Omit the prop to keep the
 * built-in rich default set.
 */
export type FlareComposerAttachAction = {
  op: string;
  label: string;
  icon?: Component;
  tone?: FlareComposerActionTone;
};
type VoiceRecordingPayload = {
  blob: Blob;
  durationMs: number;
  mimeType: string;
  fileName: string;
};
type FormatActionKey =
  | "bold"
  | "strike"
  | "italic"
  | "underline"
  | "ordered"
  | "bullet"
  | "quote"
  | "link"
  | "image"
  | "code"
  | "codeBlock"
  | "divider";
type FormatAction = {
  key: FormatActionKey;
  title: string;
  icon?: Component;
  glyph?: string;
};

const value = defineModel<string>({ default: "" });
// Optional controlled rich-doc state — a host with its own rich-doc send flow can
// v-model these alongside the text model (universal API; unused by hosts that don't).
const richTitle = defineModel<string>("richTitle", { default: "" });
const sendAsRichDoc = defineModel<boolean>("sendAsRichDoc", { default: false });
const composerInputProps = {
  spellcheck: false,
  autocomplete: "off",
  autocapitalize: "off",
  autocorrect: "off",
  inputmode: "text",
} as const;

const props = withDefaults(defineProps<{
  sending?: boolean;
  disabled?: boolean;
  targetName?: string;
  activePanel?: ComposerPanel;
  richMode?: boolean;
  mediaPanelOpen?: boolean;
  replySender?: string;
  replyPreview?: string;
  editing?: boolean;
  editPreview?: string;
  maxLength?: number;
  placeholder?: string;
  statusHint?: string;
  statusHintPulse?: boolean;
  mentionCandidates?: FlareComposerMentionCandidate[];
  /**
   * Customize the "+" attach grid. When provided, replaces the built-in default
   * set — a tenant supplies exactly the actions it supports, in its own order,
   * with its own labels and icons. Omit to keep the default rich set.
   */
  attachActions?: FlareComposerAttachAction[];
  sendVoiceHandler?: (payload: VoiceRecordingPayload) => void | Promise<void>;
}>(), {
  sending: false,
  disabled: false,
  targetName: "",
  activePanel: null,
  richMode: false,
  mediaPanelOpen: false,
  replySender: "",
  replyPreview: "",
  editing: false,
  editPreview: "",
  maxLength: undefined,
  placeholder: "",
  statusHint: "",
  statusHintPulse: false,
  mentionCandidates: () => [],
  attachActions: undefined,
  sendVoiceHandler: undefined,
});

const emit = defineEmits<{
  (event: "toggle-panel", panel: ComposerPanel): void;
  (event: "toggle-rich-mode", enabled: boolean): void;
  (event: "build", op: string): void;
  (event: "clear-reply"): void;
  (event: "clear-edit"): void;
  (event: "send-voice", payload: VoiceRecordingPayload): void;
  /** The user aborted the recording (slid up to cancel, or it failed) — nothing was sent. */
  (event: "voice-cancel"): void;
  (event: "send", text: string): void;
  (event: "user-input", text: string): void;
}>();

const root = ref<HTMLElement | null>(null);

// Notify hosts of typing (e.g. to drive typing indicators). Fires on the text model.
watch(value, (next) => emit("user-input", next ?? ""));
const { t } = useFlareI18n();
const canSend = computed(() => !props.disabled && !props.sending && value.value.trim().length > 0);
const hasInlineEmoji = computed(() => /\[[a-z][a-z0-9_]*\]/.test(value.value));
const useRichEditor = computed(() => props.richMode || sendAsRichDoc.value || hasInlineEmoji.value);
const showReply = computed(() => Boolean(props.replySender?.trim() || props.replyPreview?.trim()));
const showEdit = computed(() => props.editing);
const replyPreviewWarn = computed(() => /fail|error|invalid|expired|warn/i.test(props.replyPreview ?? ""));
const inputExpanded = ref(false);
const mentionMenuOpen = ref(false);
const inputPlaceholder = computed(
  () => props.placeholder || (props.editing ? t("composer.editingPlaceholder") : `To ${props.targetName || "Conversation"}`),
);
const mentionCandidates = computed(() => {
  const seen = new Set<string>();
  return props.mentionCandidates
    .map((candidate) => ({
      userId: candidate.userId.trim(),
      label: candidate.label?.trim() || candidate.userId.trim(),
      avatarUrl: candidate.avatarUrl?.trim() || "",
    }))
    .filter((candidate) => {
      if (!candidate.userId || seen.has(candidate.userId)) return false;
      seen.add(candidate.userId);
      return true;
    })
    .slice(0, 8);
});

// The built-in rich set — used only when the host does not pass `attachActions`.
const defaultAttachActions = computed<FlareComposerAttachAction[]>(() => [
  { op: "create_file", label: t("composer.file"), icon: FolderOpenOutline, tone: "amber" },
  { op: "create_video", label: t("composer.video"), icon: VideocamOutline, tone: "cyan" },
  { op: "create_location", label: t("composer.location"), icon: LocationOutline, tone: "green" },
  { op: "create_card", label: t("composer.card"), icon: DocumentTextOutline, tone: "indigo" },
  { op: "create_task", label: t("composer.task"), icon: CheckboxOutline, tone: "violet" },
  { op: "create_schedule", label: t("composer.schedule"), icon: CalendarOutline, tone: "rose" },
  { op: "create_vote", label: t("composer.vote"), icon: CheckboxOutline, tone: "lime" },
  { op: "create_link_card", label: t("composer.link"), icon: LinkOutline, tone: "sky" },
  { op: "create_mini_program", label: t("business.miniProgram"), icon: AppsOutline, tone: "emerald" },
  { op: "create_thread_reply", label: t("composer.thread"), icon: ChatbubblesOutline, tone: "fuchsia" },
  { op: "create_notification", label: t("composer.notification"), icon: NotificationsOutline, tone: "yellow" },
  { op: "create_announcement", label: t("business.announcement"), icon: MegaphoneOutline, tone: "red" },
]);
// Host-provided actions win; otherwise the default set. This is the single seam
// that makes the "+" menu tenant-configurable.
const moreActions = computed<FlareComposerAttachAction[]>(() =>
  props.attachActions && props.attachActions.length > 0 ? props.attachActions : defaultAttachActions.value,
);

const replyTitle = computed(() =>
  t("composer.replyTo", { name: props.replySender?.trim() || t("composer.replyFallback") }),
);
const sendTitle = computed(() => (props.editing ? t("composer.saveEdit") : t("composer.send")));
const formatActionGroups: ReadonlyArray<ReadonlyArray<FormatAction>> = [
  [
    { key: "bold", glyph: "B", title: "Bold" },
    { key: "strike", glyph: "S", title: "Strikethrough" },
    { key: "italic", glyph: "I", title: "Italic" },
    { key: "underline", glyph: "U", title: "Underline" },
  ],
  [
    { key: "ordered", icon: ReorderThreeOutline, title: "Numbered list" },
    { key: "bullet", icon: ListOutline, title: "Bulleted list" },
    { key: "quote", icon: ReaderOutline, title: "Quote" },
  ],
  [
    { key: "link", icon: LinkOutline, title: "Link" },
    { key: "image", icon: ImageOutline, title: "Image" },
    { key: "code", icon: CodeSlashOutline, title: "Inline code" },
    { key: "codeBlock", icon: CodeWorkingOutline, title: "Code block" },
    { key: "divider", icon: RemoveOutline, title: "Divider" },
  ],
];
const headingOptions: ReadonlyArray<{ level: RichHeadingLevel | null; label: string }> = [
  { level: null, label: "Aa" },
  { level: 1, label: "H1" },
  { level: 2, label: "H2" },
  { level: 3, label: "H3" },
  { level: 4, label: "H4" },
  { level: 5, label: "H5" },
  { level: 6, label: "H6" },
];
const richFormatState = ref<RichMarkdownFormatState>({
  inline: {
    bold: false,
    strike: false,
    italic: false,
    underline: false,
    code: false,
  },
  headingLevel: null,
});

const inputFocused = ref(false);
const richInputRef = ref<InstanceType<typeof ComposerRichMarkdownInput> | null>(null);
const plainInputResetKey = ref(0);
const inputExpandTitle = computed(() => (inputExpanded.value ? "Collapse" : t("composer.expandInput")));
const formatPointerActive = ref(false);
const voiceRecording = ref(false);
const voiceCancelling = ref(false);
const voiceElapsedMs = ref(0);
const voiceError = ref("");
const VOICE_MAX_MS = 65_000;
const VOICE_CANCEL_DISTANCE = 56;
let voicePointerStartY = 0;
let voicePointerElement: HTMLElement | null = null;
let voicePointerId: number | null = null;
let voiceRecorder: MediaRecorder | null = null;
let voiceStream: MediaStream | null = null;
let voiceChunks: BlobPart[] = [];
let voiceStartedAt = 0;
let voiceTimer: number | undefined;
let voiceErrorTimer: number | undefined;
let voiceStopCancelled = false;
let voicePendingFinish = false;
const isMultiline = computed(
  () =>
    inputExpanded.value
    || props.richMode
    || value.value.includes("\n")
    || value.value.length > 56,
);
const inputRows = computed(() => ({
  minRows: inputExpanded.value ? 6 : 1,
  maxRows: inputExpanded.value ? 6 : 6,
}));
const voiceElapsedLabel = computed(() => formatVoiceDuration(voiceElapsedMs.value));
function textarea(): HTMLTextAreaElement | null {
  return root.value?.querySelector(".composer-input textarea") ?? null;
}

function focusInput(): void {
  void nextTick(() => {
    const applyFocus = () => {
      if (useRichEditor.value) {
        richInputRef.value?.focus();
        return;
      }
      textarea()?.focus({ preventScroll: true });
    };
    if (typeof window === "undefined") {
      applyFocus();
      return;
    }
    window.requestAnimationFrame(applyFocus);
  });
}

function toggle(panel: Exclude<ComposerPanel, null>): void {
  if (props.disabled) return;
  const nextPanel = props.activePanel === panel ? null : panel;
  inputExpanded.value = false;
  emit("toggle-panel", nextPanel);
  focusInput();
}

function toggleInputExpanded(): void {
  if (props.disabled) return;
  const nextExpanded = !inputExpanded.value;
  inputExpanded.value = nextExpanded;
  emit("toggle-panel", null);
  focusInput();
}

function toggleRichMode(): void {
  if (props.disabled) return;
  mentionMenuOpen.value = false;
  emit("toggle-rich-mode", !props.richMode);
  emit("toggle-panel", null);
  focusInput();
}

function openMentionPicker(): void {
  if (props.disabled) return;
  emit("toggle-panel", null);
  if (!mentionCandidates.value.length) {
    insertAtCursor("@");
    return;
  }
  mentionMenuOpen.value = !mentionMenuOpen.value;
  focusInput();
}

function selectMention(candidate: FlareComposerMentionCandidate): void {
  const userId = candidate.userId.trim();
  if (!userId) return;
  mentionMenuOpen.value = false;
  insertAtCursor(`@${userId} `);
}

function insertAtCursor(text: string): void {
  if (props.disabled) return;
  if (useRichEditor.value) {
    richInputRef.value?.insertAtCursor(text);
    return;
  }
  const node = textarea();
  if (!node) {
    value.value = `${value.value}${text}`;
    return;
  }
  const start = node.selectionStart ?? value.value.length;
  const end = node.selectionEnd ?? value.value.length;
  const next = `${value.value.slice(0, start)}${text}${value.value.slice(end)}`;
  value.value = props.maxLength ? next.slice(0, props.maxLength) : next;
  const shouldSwitchToRichEditor = /\[[a-z][a-z0-9_]*\]/.test(value.value);
  void nextTick(() => {
    if (shouldSwitchToRichEditor) {
      richInputRef.value?.focus();
      return;
    }
    const offset = Math.min(start + text.length, value.value.length);
    node.focus();
    node.setSelectionRange(offset, offset);
  });
}

function resetInput(nextValue = ""): void {
  const normalized = props.maxLength ? nextValue.slice(0, props.maxLength) : nextValue;
  value.value = normalized;
  const applyPlainInputValue = () => {
    const node = textarea();
    if (node && node.value !== normalized) {
      node.value = normalized;
    }
  };
  if (!useRichEditor.value) {
    applyPlainInputValue();
    plainInputResetKey.value += 1;
    void nextTick(applyPlainInputValue);
  }
}

function build(op: string): void {
  if (props.disabled) return;
  inputExpanded.value = false;
  emit("toggle-panel", null);
  emit("build", op);
  focusInput();
}

function preferredVoiceMimeType(): string {
  const candidates = [
    "audio/mp4",
    "audio/mpeg",
    "audio/webm;codecs=opus",
    "audio/webm",
  ];
  if (typeof MediaRecorder === "undefined" || typeof MediaRecorder.isTypeSupported !== "function") {
    return "";
  }
  return candidates.find((candidate) => MediaRecorder.isTypeSupported(candidate)) ?? "";
}

function voiceFileExtension(mimeType: string): string {
  if (/mp4|m4a/i.test(mimeType)) return "m4a";
  if (/mpeg|mp3/i.test(mimeType)) return "mp3";
  if (/ogg/i.test(mimeType)) return "ogg";
  return "webm";
}

function formatVoiceDuration(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = `${totalSeconds % 60}`.padStart(2, "0");
  return `${minutes}:${seconds}`;
}

function showVoiceError(text: string): void {
  voiceError.value = text;
  if (voiceErrorTimer) window.clearTimeout(voiceErrorTimer);
  voiceErrorTimer = window.setTimeout(() => {
    voiceError.value = "";
    voiceErrorTimer = undefined;
  }, 2600);
}

function clearVoiceTimer(): void {
  if (voiceTimer) {
    window.clearInterval(voiceTimer);
    voiceTimer = undefined;
  }
}

function releaseVoicePointer(): void {
  if (voicePointerElement && voicePointerId != null && voicePointerElement.hasPointerCapture?.(voicePointerId)) {
    voicePointerElement.releasePointerCapture(voicePointerId);
  }
  voicePointerElement = null;
  voicePointerId = null;
}

function stopVoiceStream(): void {
  voiceStream?.getTracks().forEach((track) => track.stop());
  voiceStream = null;
}

function resetVoiceRecordingState(): void {
  voiceRecording.value = false;
  voiceCancelling.value = false;
  voiceElapsedMs.value = 0;
  voiceChunks = [];
  voiceStartedAt = 0;
  voiceStopCancelled = false;
  voicePendingFinish = false;
  voiceRecorder = null;
  releaseVoicePointer();
  clearVoiceTimer();
}

function handleVoiceStop(mimeType: string): void {
  const durationMs = Math.min(VOICE_MAX_MS, Math.max(0, Date.now() - voiceStartedAt));
  const cancelled = voiceStopCancelled;
  const chunks = [...voiceChunks];
  stopVoiceStream();
  resetVoiceRecordingState();
  if (cancelled) {
    emit("voice-cancel");
    return;
  }
  const blob = new Blob(chunks, { type: mimeType || "audio/webm" });
  if (!blob.size || durationMs < 250) {
    showVoiceError(t("composer.voiceTooShort"));
    emit("voice-cancel");
    return;
  }
  const finalMimeType = blob.type || mimeType || "audio/webm";
  const payload = {
    blob,
    durationMs,
    mimeType: finalMimeType,
    fileName: `voice-${Date.now()}.${voiceFileExtension(finalMimeType)}`,
  };
  if (typeof props.sendVoiceHandler === "function") {
    void props.sendVoiceHandler(payload);
  } else {
    emit("send-voice", payload);
    root.value?.dispatchEvent(new CustomEvent<VoiceRecordingPayload>("flare-send-voice", {
      detail: payload,
      bubbles: true,
      composed: true,
    }));
    window.dispatchEvent(new CustomEvent<VoiceRecordingPayload>("flare-send-voice", {
      detail: payload,
    }));
  }
}

async function startVoiceRecording(event: PointerEvent): Promise<void> {
  if (props.disabled || props.sending || voiceRecording.value || voiceRecorder) return;
  event.preventDefault();
  voicePointerStartY = event.clientY;
  voicePointerElement = event.currentTarget as HTMLElement;
  voicePointerId = event.pointerId;
  voicePendingFinish = false;
  voicePointerElement?.setPointerCapture?.(event.pointerId);
  emit("toggle-panel", null);
  inputExpanded.value = false;
  if (typeof navigator === "undefined" || !navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
    releaseVoicePointer();
    showVoiceError("Recording not supported here");
    return;
  }

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const mimeType = preferredVoiceMimeType();
    const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream);
    voiceStream = stream;
    voiceRecorder = recorder;
    voiceChunks = [];
    voiceStopCancelled = false;
    voiceStartedAt = Date.now();
    voiceElapsedMs.value = 0;
    recorder.ondataavailable = (chunkEvent) => {
      if (chunkEvent.data.size > 0) voiceChunks.push(chunkEvent.data);
    };
    recorder.onstop = () => handleVoiceStop(recorder.mimeType || mimeType);
    recorder.onerror = () => {
      voiceStopCancelled = true;
      showVoiceError(t("composer.voiceFailed"));
      emit("voice-cancel");
    };
    recorder.start(250);
    voiceRecording.value = true;
    voiceTimer = window.setInterval(() => {
      voiceElapsedMs.value = Math.min(VOICE_MAX_MS, Date.now() - voiceStartedAt);
      if (voiceElapsedMs.value >= VOICE_MAX_MS) stopVoiceRecording(false);
    }, 150);
    if (voicePendingFinish) stopVoiceRecording(voiceCancelling.value);
  } catch (error) {
    stopVoiceStream();
    resetVoiceRecordingState();
    showVoiceError(error instanceof Error ? error.message : "Cannot access microphone");
  }
}

function updateVoiceRecording(event: PointerEvent): void {
  if (!voiceRecording.value) return;
  event.preventDefault();
  voiceCancelling.value = event.clientY <= voicePointerStartY - VOICE_CANCEL_DISTANCE;
}

function stopVoiceRecording(cancelled: boolean): void {
  if (!voiceRecorder) return;
  voiceStopCancelled = cancelled;
  clearVoiceTimer();
  if (voiceRecorder.state === "inactive") {
    handleVoiceStop(voiceRecorder.mimeType);
    return;
  }
  try {
    voiceRecorder.requestData();
  } catch {
    // Some browsers throw if data is already being flushed; stop() will still emit final data.
  }
  voiceRecorder.stop();
}

function finishVoiceRecording(event: PointerEvent): void {
  event.preventDefault();
  releaseVoicePointer();
  if (!voiceRecorder) {
    voicePendingFinish = true;
    return;
  }
  stopVoiceRecording(voiceCancelling.value);
}

function cancelVoiceRecording(event?: PointerEvent): void {
  event?.preventDefault();
  releaseVoicePointer();
  stopVoiceRecording(voiceCancelling.value);
}

function replaceSelection(before: string, after = before, fallback = ""): void {
  if (props.disabled) return;
  const node = textarea();
  const source = value.value;
  const start = node?.selectionStart ?? source.length;
  const end = node?.selectionEnd ?? source.length;
  const selected = source.slice(start, end) || fallback;
  const next = `${source.slice(0, start)}${before}${selected}${after}${source.slice(end)}`;
  value.value = props.maxLength ? next.slice(0, props.maxLength) : next;
  void nextTick(() => {
    const cursorStart = Math.min(start + before.length, value.value.length);
    const cursorEnd = Math.min(cursorStart + selected.length, value.value.length);
    const target = textarea();
    target?.focus();
    target?.setSelectionRange(cursorStart, cursorEnd);
  });
}

function prefixSelection(prefix: string): void {
  if (props.disabled) return;
  const node = textarea();
  const source = value.value;
  const start = node?.selectionStart ?? source.length;
  const end = node?.selectionEnd ?? source.length;
  const selected = source.slice(start, end) || "";
  const lineStart = source.lastIndexOf("\n", Math.max(0, start - 1)) + 1;
  const next = `${source.slice(0, lineStart)}${prefix}${source.slice(lineStart, end)}${source.slice(end)}`;
  value.value = props.maxLength ? next.slice(0, props.maxLength) : next;
  void nextTick(() => {
    const target = textarea();
    const offset = prefix.length;
    target?.focus();
    target?.setSelectionRange(start + offset, start + offset + selected.length);
  });
}

function applyFormat(key: FormatActionKey): void {
  if (props.richMode) {
    richInputRef.value?.applyFormat(key);
    return;
  }
  if (key === "bold") replaceSelection("**", "**", "Bold");
  else if (key === "strike") replaceSelection("~~", "~~", "Strikethrough");
  else if (key === "italic") replaceSelection("*", "*", "Italic");
  else if (key === "underline") replaceSelection("<u>", "</u>", "Underline");
  else if (key === "ordered") prefixSelection("1. ");
  else if (key === "bullet") prefixSelection("- ");
  else if (key === "quote") prefixSelection("> ");
  else if (key === "link") replaceSelection("[", "](https://)", "Link");
  else if (key === "image") replaceSelection("![", "](https://)", "Image description");
  else if (key === "code") replaceSelection("`", "`", "code");
  else if (key === "codeBlock") replaceSelection("```\n", "\n```", "code");
  else if (key === "divider") insertAtCursor("\n---\n");
}

function isFormatActionActive(key: FormatActionKey): boolean {
  if (key === "bold" || key === "strike" || key === "italic" || key === "underline" || key === "code") {
    return richFormatState.value.inline[key];
  }
  return false;
}

function applyHeadingLevel(raw: string): void {
  const value = Number(raw);
  const level = value >= 1 && value <= 6 ? (value as RichHeadingLevel) : null;
  if (props.richMode) {
    richInputRef.value?.applyHeadingLevel(level);
    return;
  }
  if (level) prefixSelection(`${"#".repeat(level)} `);
}

function applyFormatFromPointer(key: FormatActionKey): void {
  if (props.disabled) return;
  formatPointerActive.value = true;
  applyFormat(key);
}

function applyFormatFromClick(key: FormatActionKey): void {
  if (formatPointerActive.value) {
    formatPointerActive.value = false;
    return;
  }
  applyFormat(key);
}

function updateRichFormatState(next: RichMarkdownFormatState): void {
  richFormatState.value = next;
}

function submit(): void {
  if (!useRichEditor.value) {
    const node = textarea();
    if (node && node.value !== value.value) {
      value.value = props.maxLength ? node.value.slice(0, props.maxLength) : node.value;
    }
  }
  if (!canSend.value) return;
  const submittedText = value.value;
  inputExpanded.value = false;
  mentionMenuOpen.value = false;
  emit("toggle-panel", null);
  emit("send", submittedText);
  value.value = "";
  if (!useRichEditor.value) {
    plainInputResetKey.value += 1;
  }
  focusInput();
}

function handleKeydown(event: KeyboardEvent): void {
  if (event.isComposing) return;
  if (event.key === "Escape" && props.activePanel) {
    event.preventDefault();
    emit("toggle-panel", null);
    focusInput();
    return;
  }
  if (event.key === "Escape" && props.editing) {
    event.preventDefault();
    emit("clear-edit");
    focusInput();
    return;
  }
  if (event.key === "Escape" && showReply.value) {
    event.preventDefault();
    emit("clear-reply");
    focusInput();
    return;
  }
  if (event.key === "Escape") {
    if (useRichEditor.value) {
      root.value?.querySelector<HTMLElement>(".composer-rich-markdown-input__editable")?.blur();
    } else {
      textarea()?.blur();
    }
    return;
  }
  if (event.key !== "Enter" || event.shiftKey || event.altKey) return;
  event.preventDefault();
  submit();
}

defineExpose({
  focus: focusInput,
  insertAtCursor,
  resetInput,
});

watch(useRichEditor, (enabled) => {
  if (enabled && inputFocused.value) focusInput();
});

onBeforeUnmount(() => {
  cancelVoiceRecording();
  if (voiceErrorTimer) window.clearTimeout(voiceErrorTimer);
});
</script>

<template>
  <footer
    ref="root"
    class="composer"
    :class="{
      'composer--expanded': Boolean(activePanel),
      'composer--format': richMode,
      'composer--input-expanded': inputExpanded,
      'composer--voice-recording': voiceRecording,
      'composer--disabled': disabled,
    }"
  >
    <section v-if="statusHint" class="composer-status-hint" role="status">
      <span
        class="composer-status-hint__dot"
        :class="{ 'composer-status-hint__dot--pulse': statusHintPulse }"
      />
      <span>{{ statusHint }}</span>
    </section>

    <section v-if="showEdit" class="composer-reply-strip composer-reply-strip--edit">
      <button type="button" class="composer-reply-strip__close" :title="t('composer.cancelEdit')" @click="emit('clear-edit')">
        <n-icon :component="CloseOutline" />
      </button>
      <span class="composer-reply-strip__divider" />
      <strong>{{ t("composer.editingMessage") }}:</strong>
      <span>{{ editPreview || value || t("composer.replyFallback") }}</span>
    </section>

    <section v-else-if="showReply" class="composer-reply-strip" :class="{ 'composer-reply-strip--warn': replyPreviewWarn }">
      <button type="button" class="composer-reply-strip__close" :title="t('composer.cancelReply')" @click="emit('clear-reply')">
        <n-icon :component="CloseOutline" />
      </button>
      <span class="composer-reply-strip__divider" />
      <strong>{{ replyTitle }}:</strong>
      <span>{{ replyPreview }}</span>
    </section>

    <div
      class="composer-field"
      :class="{
        'composer-field--multiline': isMultiline,
        'composer-field--focused': inputFocused,
      }"
      @click.self="focusInput"
    >
      <div v-if="richMode" class="composer-format-strip" aria-label="Rich text" @mousedown.stop>
        <div class="composer-format-group composer-format-group--heading" role="group" aria-label="Heading level">
          <span class="composer-format-heading-icon" aria-hidden="true">
            <n-icon :size="16" :component="TextOutline" />
          </span>
          <select
            class="composer-heading-select"
            :value="richFormatState.headingLevel ?? ''"
            :disabled="disabled"
            title="Heading level"
            aria-label="Heading level"
            @mousedown.stop
            @change="applyHeadingLevel(($event.target as HTMLSelectElement).value)"
          >
            <option
              v-for="option in headingOptions"
              :key="option.level ?? 'paragraph'"
              :value="option.level ?? ''"
            >
              {{ option.label }}
            </option>
          </select>
        </div>
        <div
          v-for="(group, groupIndex) in formatActionGroups"
          :key="`format-group-${groupIndex}`"
          class="composer-format-group"
          role="group"
        >
          <button
            v-for="action in group"
            :key="action.key"
            type="button"
            class="composer-format-button"
            :class="[
              `composer-format-button--${action.key}`,
              { 'is-active': isFormatActionActive(action.key) },
            ]"
            :title="action.title"
            :aria-label="action.title"
            :aria-pressed="isFormatActionActive(action.key)"
            :disabled="disabled"
            @pointerdown.prevent.stop="applyFormatFromPointer(action.key)"
            @click.prevent.stop="applyFormatFromClick(action.key)"
            @keydown.enter.prevent.stop="applyFormat(action.key)"
            @keydown.space.prevent.stop="applyFormat(action.key)"
          >
            <n-icon v-if="action.icon" :size="17" :component="action.icon" />
            <span
              v-else
              class="composer-format-glyph"
              :class="`composer-format-glyph--${action.key}`"
              aria-hidden="true"
            >
              {{ action.glyph }}
            </span>
          </button>
        </div>
      </div>

      <div class="composer-input-layer">
        <div
          class="composer-input-row"
          :class="{
            'composer-input-row--multiline': isMultiline,
            'composer-input-row--focused': inputFocused,
            'composer-input-row--rich-editable': useRichEditor,
          }"
        >
          <ComposerRichMarkdownInput
            v-if="useRichEditor"
            ref="richInputRef"
            v-model="value"
            class="composer-input composer-rich-input"
            :disabled="disabled"
            :formatting-preview="richMode"
            :max-length="maxLength"
            :placeholder="disabled ? statusHint || inputPlaceholder : inputPlaceholder"
            @focus="inputFocused = true"
            @blur="inputFocused = false"
            @format-state-change="updateRichFormatState"
            @keydown="handleKeydown"
          />
          <n-input
            v-else
            :key="plainInputResetKey"
            v-model:value="value"
            class="composer-input"
            type="textarea"
            :disabled="disabled"
            :maxlength="maxLength"
            :autosize="inputRows"
            :input-props="composerInputProps"
            :placeholder="disabled ? statusHint || inputPlaceholder : inputPlaceholder"
            @focus="inputFocused = true"
            @blur="inputFocused = false"
            @keydown="handleKeydown"
          />
          <!-- The expand/collapse toggle lives on the input field's top-right corner.
               No titled header — a single direction-aware chevron: up expands, down
               collapses. On desktop the toolbar carries expand when compact; once
               expanded this corner button is the collapse control. -->
          <button
            type="button"
            class="composer-field-expand"
            :title="inputExpandTitle"
            :aria-label="inputExpandTitle"
            :disabled="disabled"
            @click.stop="toggleInputExpanded"
          >
            <n-icon :size="20" :component="inputExpanded ? ChevronDownOutline : ChevronUpOutline" />
          </button>
        </div>

        <div
          v-if="voiceRecording"
          class="composer-voice-overlay"
          :class="{ 'composer-voice-overlay--cancel': voiceCancelling }"
          role="status"
          aria-live="polite"
        >
          <span class="composer-voice-overlay__icon">
            <n-icon :component="voiceCancelling ? CloseOutline : MicOutline" />
          </span>
          <span class="composer-voice-overlay__copy">
            <strong>{{ voiceCancelling ? t("composer.voiceReleaseCancel") : t("composer.voiceReleaseSend") }}</strong>
            <span>{{ voiceCancelling ? t("composer.voiceSlideDownResume") : t("composer.voiceSlideUpCancel") }}</span>
          </span>
          <span class="composer-voice-overlay__timer">{{ voiceElapsedLabel }} / 1:05</span>
          <span class="composer-voice-overlay__meter" aria-hidden="true">
            <span :style="{ width: `${Math.min(100, Math.max(0, voiceElapsedMs / 650))}%` }" />
          </span>
        </div>
      </div>

      <div v-if="!mediaPanelOpen" class="composer-toolbar">
        <n-button
          circle
          quaternary
          class="composer-toolbar__action composer-expand"
          :class="{ 'is-selected': inputExpanded }"
          :title="inputExpandTitle"
          :aria-label="inputExpandTitle"
          :disabled="disabled"
          @click.stop="toggleInputExpanded"
        >
          <template #icon>
            <n-icon :size="22" :component="inputExpanded ? ContractOutline : ExpandOutline" />
          </template>
        </n-button>
        <n-button circle quaternary :title="t('composer.emoji')" :aria-label="t('composer.emoji')" :class="{ 'is-selected': activePanel === 'emoji' }" :disabled="disabled" @click="toggle('emoji')">
          <template #icon><n-icon :size="22" :component="HappyOutline" /></template>
        </n-button>
        <div class="composer-mention-anchor">
          <n-button circle quaternary :title="t('composer.mention')" :aria-label="t('composer.mention')" :disabled="disabled" @click="openMentionPicker">
            <template #icon><n-icon :size="22" :component="AtOutline" /></template>
          </n-button>
          <div v-if="mentionMenuOpen && mentionCandidates.length" class="composer-mention-menu" role="listbox">
            <button
              v-for="candidate in mentionCandidates"
              :key="candidate.userId"
              type="button"
              class="composer-mention-option"
              @click="selectMention(candidate)"
            >
              <span class="composer-mention-option__avatar">{{ candidate.label.slice(0, 1).toUpperCase() }}</span>
              <span class="composer-mention-option__body">
                <span class="composer-mention-option__label">{{ candidate.label }}</span>
                <span class="composer-mention-option__id">@{{ candidate.userId }}</span>
              </span>
            </button>
          </div>
        </div>
        <n-button
          circle
          quaternary
          :title="t('composer.voice')"
          :aria-label="t('composer.voice')"
          :class="{ 'is-selected': voiceRecording, 'is-cancel': voiceCancelling }"
          :disabled="disabled || sending"
          @pointerdown.prevent.stop="startVoiceRecording"
          @pointermove.prevent.stop="updateVoiceRecording"
          @pointerup.prevent.stop="finishVoiceRecording"
          @pointercancel.prevent.stop="cancelVoiceRecording"
        >
          <template #icon><n-icon :size="22" :component="MicOutline" /></template>
        </n-button>
        <n-button circle quaternary :title="t('composer.image')" :aria-label="t('composer.image')" :disabled="disabled" @click="build('create_image')">
          <template #icon><n-icon :size="22" :component="ImageOutline" /></template>
        </n-button>
        <n-button circle quaternary :title="t('composer.richText')" :aria-label="t('composer.richText')" :class="{ 'is-selected': richMode }" :disabled="disabled" @click="toggleRichMode">
          <template #icon><n-icon :size="22" :component="TextOutline" /></template>
        </n-button>
        <n-button circle quaternary :title="t('composer.more')" :aria-label="t('composer.more')" :disabled="disabled" @click="toggle('more')">
          <template #icon>
            <n-icon :size="22" :component="activePanel === 'more' ? CloseOutline : AddOutline" />
          </template>
        </n-button>
        <button
          type="button"
          class="composer-toolbar__send"
          :disabled="!canSend || sending"
          :title="sendTitle"
          :aria-label="sendTitle"
          @click.stop="submit"
        >
          <n-icon :size="20" :component="SendOutline" />
        </button>
      </div>
    </div>

    <p v-if="!mediaPanelOpen" class="composer-input-hint">
      {{ t("composer.shiftEnterHint") }}
    </p>

    <section v-if="activePanel === 'more'" class="composer-more-grid" :aria-label="t('composer.more')">
      <button
        v-for="action in moreActions"
        :key="action.op"
        type="button"
        class="composer-more-tile"
        :class="action.tone ? `composer-more-tile--${action.tone}` : ''"
        :disabled="disabled"
        @click="build(action.op)"
      >
        <span class="composer-more-tile__icon">
          <n-icon :component="action.icon ?? AddCircleOutline" />
        </span>
        <span>{{ action.label }}</span>
      </button>
    </section>
    <p v-if="voiceError" class="composer-voice-error" role="status">{{ voiceError }}</p>
  </footer>
</template>

<style scoped>
.composer-mention-anchor {
  position: relative;
  display: inline-flex;
}

.composer-mention-menu {
  position: absolute;
  left: 0;
  bottom: calc(100% + 8px);
  z-index: 20;
  width: min(260px, 72vw);
  max-height: 280px;
  overflow: auto;
  padding: 6px;
  border: 1px solid var(--border-color, rgba(15, 23, 42, 0.12));
  border-radius: 8px;
  background: var(--card-color, #fff);
  box-shadow: 0 12px 32px rgba(15, 23, 42, 0.18);
}

.composer-mention-option {
  display: grid;
  grid-template-columns: 30px minmax(0, 1fr);
  gap: 8px;
  width: 100%;
  min-height: 40px;
  align-items: center;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: inherit;
  cursor: pointer;
  padding: 5px 7px;
  text-align: left;
}

.composer-mention-option:hover {
  background: var(--hover-color, rgba(15, 23, 42, 0.06));
}

.composer-mention-option__avatar {
  display: grid;
  width: 30px;
  height: 30px;
  place-items: center;
  border-radius: 50%;
  background: var(--primary-color-suppl, rgba(24, 144, 255, 0.14));
  color: var(--primary-color, #1677ff);
  font-size: 13px;
  font-weight: 700;
}

.composer-mention-option__body {
  min-width: 0;
}

.composer-mention-option__label,
.composer-mention-option__id {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.composer-mention-option__label {
  font-size: 13px;
  font-weight: 600;
}

.composer-mention-option__id {
  color: var(--text-color-3, var(--flare-color-robot, #64748b));
  font-size: 12px;
}
</style>
