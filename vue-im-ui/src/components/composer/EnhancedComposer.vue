<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch, type Component } from "vue";
import {
  AddCircleOutline,
  AddOutline,
  AtOutline,
  CheckboxOutline,
  ChevronUpOutline,
  CloseOutline,
  CodeSlashOutline,
  CodeWorkingOutline,
  HappyOutline,
  ImageOutline,
  LinkOutline,
  ListOutline,
  MicOutline,
  PauseOutline,
  PlayOutline,
  ReaderOutline,
  RemoveOutline,
  ReorderThreeOutline,
  SendOutline,
  TextOutline,
} from "../../shared/icon-glyphs";
// Preserve the classic action-grid icons without changing the input toolbar.
import {
  FolderOpenOutline as MoreFolderOpenOutline,
  VideocamOutline as MoreVideocamOutline,
  LocationOutline as MoreLocationOutline,
  DocumentTextOutline as MoreDocumentTextOutline,
  CheckboxOutline as MoreCheckboxOutline,
  CalendarOutline as MoreCalendarOutline,
  LinkOutline as MoreLinkOutline,
  AppsOutline as MoreAppsOutline,
  ChatbubblesOutline as MoreChatbubblesOutline,
  NotificationsOutline as MoreNotificationsOutline,
  MegaphoneOutline as MoreMegaphoneOutline,
} from "@vicons/ionicons5";
import { Keyboard, Trash2 } from "lucide-vue-next";
import { NButton, NIcon, NInput } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import ComposerResizeIcon from "./ComposerResizeIcon.vue";
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
  disabled?: boolean;
  disabledReason?: string;
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
  /** Temporary transport or slow-mode restriction: draft remains editable. */
  sendBlocked?: boolean;
  /** Muted, removed or read-only conversation; explain through statusHint. */
  readOnly?: boolean;
  moreSearchVisible?: boolean;
  moreCloseVisible?: boolean;
  moreTitleVisible?: boolean;
  disabled?: boolean;
  targetName?: string;
  /** Reset transient panels and recordings when the host changes conversation. */
  conversationKey?: string;
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
  sendBlocked: false, readOnly: false,
  moreSearchVisible: false, moreCloseVisible: false, moreTitleVisible: false,
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
  /** Recording was cancelled; no voice message was submitted. */
  (event: "voice-cancel"): void;
  (event: "send", text: string): void;
  (event: "user-input", text: string): void;
}>();

const root = ref<HTMLElement | null>(null);

// Notify hosts of typing (e.g. to drive typing indicators). Fires on the text model.
watch(value, (next) => emit("user-input", next ?? ""));
const { t } = useFlareI18n();
const editingBlocked = computed(() => props.disabled || props.readOnly);
const canSend = computed(() => !editingBlocked.value && !props.sendBlocked && !props.sending && value.value.trim().length > 0);
const hasInlineEmoji = computed(() => /\[[a-z][a-z0-9_]*\]/.test(value.value));
const useRichEditor = computed(() => props.richMode || sendAsRichDoc.value || hasInlineEmoji.value);
const showReply = computed(() => Boolean(props.replySender?.trim() || props.replyPreview?.trim()));
const showEdit = computed(() => props.editing);
const replyPreviewWarn = computed(() => /fail|error|invalid|expired|warn/i.test(props.replyPreview ?? ""));
const inputExpanded = ref(false);
const mentionMenuOpen = ref(false);
const inputPlaceholder = computed(
  () => props.placeholder || (props.editing ? t("composer.editingPlaceholder") : props.targetName ? t("composer.sendToTarget", { name: props.targetName }) : t("composer.messagePlaceholder")),
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
  { op: "create_file", label: t("composer.file"), icon: MoreFolderOpenOutline, tone: "amber" },
  { op: "create_video", label: t("composer.video"), icon: MoreVideocamOutline, tone: "cyan" },
  { op: "create_location", label: t("composer.location"), icon: MoreLocationOutline, tone: "green" },
  { op: "create_card", label: t("composer.card"), icon: MoreDocumentTextOutline, tone: "indigo" },
  { op: "create_task", label: t("composer.task"), icon: MoreCheckboxOutline, tone: "violet" },
  { op: "create_schedule", label: t("composer.schedule"), icon: MoreCalendarOutline, tone: "rose" },
  { op: "create_vote", label: t("composer.vote"), icon: MoreCheckboxOutline, tone: "lime" },
  { op: "create_link_card", label: t("composer.link"), icon: MoreLinkOutline, tone: "sky" },
  { op: "create_mini_program", label: t("business.miniProgram"), icon: MoreAppsOutline, tone: "emerald" },
  { op: "create_thread_reply", label: t("composer.thread"), icon: MoreChatbubblesOutline, tone: "fuchsia" },
  { op: "create_notification", label: t("composer.notification"), icon: MoreNotificationsOutline, tone: "yellow" },
  { op: "create_announcement", label: t("business.announcement"), icon: MoreMegaphoneOutline, tone: "red" },
]);
// Host-provided actions win; otherwise the default set. This is the single seam
// that makes the "+" menu tenant-configurable.
const moreActions = computed<FlareComposerAttachAction[]>(() =>
  (props.attachActions ?? defaultAttachActions.value).map(action => ({
    ...defaultAttachActions.value.find(item => item.op === action.op), ...action,
  })),
);

const moreQuery = ref("");
const morePage = ref(0);
const filteredActions = computed(() => moreActions.value.filter(action =>
  action.label.toLocaleLowerCase().includes(moreQuery.value.toLocaleLowerCase())));
const morePages = computed(() => Math.ceil(filteredActions.value.length / 8));
const pageActions = computed(() => filteredActions.value.slice(morePage.value * 8, morePage.value * 8 + 8));
watch([moreQuery, moreActions], () => { morePage.value = 0; });
watch(() => props.moreSearchVisible, visible => { if (!visible) moreQuery.value = ""; });
const mentionQuery = ref("");
const filteredMentions = computed(() => mentionCandidates.value.filter(candidate =>
  `${candidate.label} ${candidate.userId}`.toLocaleLowerCase().includes(mentionQuery.value.toLocaleLowerCase())));
const voicePanelOpen = ref(false);
const voicePreview = ref<VoiceRecordingPayload | null>(null);
const voicePreviewUrl = ref("");
const voiceSubmitting = ref(false);
const voiceRequestPending = ref(false);
let recordingRequest = 0;
function clearVoicePreview(): void {
  pauseVoicePlayback();
  voicePlaybackMs.value = 0;
  if (voicePreviewUrl.value) URL.revokeObjectURL(voicePreviewUrl.value);
  voicePreviewUrl.value = "";
  voicePreview.value = null;
}
function closePanels(): void {
  mentionMenuOpen.value = false;
  voicePanelOpen.value = false;
  cancelVoiceRecording();
  if (props.activePanel) emit("toggle-panel", null);
}
function openVoicePanel(): void {
  if (editingBlocked.value) return;
  const next = !voicePanelOpen.value;
  closePanels();
  voicePanelOpen.value = next;
}
function onOutsidePointer(event: PointerEvent): void {
  if (!voicePanelOpen.value && !root.value?.contains(event.target as Node)) closePanels();
}
function onPanelEscape(event: KeyboardEvent): void {
  if (event.key !== "Escape") return;
  if (props.activePanel || mentionMenuOpen.value || voicePanelOpen.value) {
    event.preventDefault(); event.stopPropagation(); closePanels(); focusInput();
  } else if (inputExpanded.value) {
    event.preventDefault(); event.stopPropagation(); inputExpanded.value = false; focusInput();
  }
}
watch(() => props.activePanel, panel => {
  if (panel) { mentionMenuOpen.value = false; voicePanelOpen.value = false; cancelVoiceRecording(); }
});
watch(() => props.conversationKey, () => { closePanels(); clearVoicePreview(); inputExpanded.value = false; });
watch(editingBlocked, blocked => { if (blocked) closePanels(); });
watch(() => props.sendBlocked, blocked => { if (blocked && voicePanelOpen.value) cancelVoiceRecording(); });
onMounted(() => document.addEventListener("pointerdown", onOutsidePointer));

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
const inputExpandTitle = computed(() => (inputExpanded.value ? t("composer.collapseInput") : t("composer.expandInput")));
const formatPointerActive = ref(false);
const voiceRecording = ref(false);
const voicePaused = ref(false);
const voicePlaying = ref(false);
const voiceAudio = ref<HTMLAudioElement | null>(null);
const voicePlaybackMs = ref(0);
let voiceAccumulatedMs = 0;
let voiceFinalize: (() => void) | undefined;
function pauseVoicePlayback(): void { voiceAudio.value?.pause(); voicePlaying.value = false; }
async function playVoicePreview(): Promise<void> {
  if (voicePlaying.value) { pauseVoicePlayback(); return; }
  try { await voiceAudio.value?.play(); voicePlaying.value = true; }
  catch { showVoiceError(t("composer.voicePreviewFailed")); }
}
function pauseVoiceRecording(): void {
  if (!voiceRecorder || voiceRecorder.state !== "recording") return;
  voiceAccumulatedMs += Date.now() - voiceStartedAt;
  voiceElapsedMs.value = Math.min(VOICE_MAX_MS, voiceAccumulatedMs);
  voiceRecorder.pause();
  voiceRecording.value = false;
  voicePaused.value = true;
  clearVoiceTimer();
  voiceRecorder.requestData();
}
function resumeVoiceRecording(): void {
  if (!voiceRecorder || voiceRecorder.state !== "paused" || voiceElapsedMs.value >= VOICE_MAX_MS) return;
  pauseVoicePlayback();
  clearVoicePreview();
  voiceRecorder.resume();
  voiceStartedAt = Date.now();
  voicePaused.value = false;
  voiceRecording.value = true;
  startVoiceTimer();
}
function startVoiceTimer(): void {
  clearVoiceTimer();
  voiceTimer = window.setInterval(() => {
    voiceElapsedMs.value = Math.min(VOICE_MAX_MS, voiceAccumulatedMs + Date.now() - voiceStartedAt);
    if (voiceElapsedMs.value >= VOICE_MAX_MS) pauseVoiceRecording();
  }, 150);
}
function updateVoicePreview(mimeType: string): void {
  const blob = new Blob(voiceChunks, { type: mimeType || "audio/webm" });
  if (!blob.size) return;
  clearVoicePreview();
  voicePreview.value = { blob, durationMs: voiceElapsedMs.value, mimeType: blob.type, fileName: `voice-${Date.now()}.${voiceFileExtension(blob.type)}` };
  voicePreviewUrl.value = URL.createObjectURL(blob);
}
function seekVoicePreview(event: Event): void {
  const audio = voiceAudio.value;
  if (!audio) return;
  const seconds = Number((event.target as HTMLInputElement).value) / 1000;
  try { audio.currentTime = seconds; voicePlaybackMs.value = seconds * 1000; } catch { /* Not yet seekable. */ }
}
function returnVoiceKeyboard(): void { closePanels(); focusInput(); }

const voiceElapsedMs = ref(0);
const voiceError = ref("");
const VOICE_MAX_MS = 65_000;
let voiceRecorder: MediaRecorder | null = null;
let voiceStream: MediaStream | null = null;
let voiceChunks: BlobPart[] = [];
let voiceStartedAt = 0;
let voiceTimer: number | undefined;
let voiceErrorTimer: number | undefined;

const isMultiline = computed(
  () =>
    inputExpanded.value
    || props.richMode
    || value.value.includes("\n")
    || value.value.length > 56,
);
const inputRows = computed(() => ({
  minRows: inputExpanded.value ? 6 : 1,
  maxRows: inputExpanded.value ? 14 : 6,
}));
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

/** 点输入行空白处时把焦点交给内部编辑器；点在编辑器自身上则不介入。 */
function onInputRowMousedown(event: MouseEvent): void {
  if (editingBlocked.value) return;
  const target = event.target as HTMLElement | null;
  if (!target) return;
  // 点在真正的编辑元素上：交给浏览器原生处理（保住选中与光标定位）
  if (target.closest("textarea, input, [contenteditable='true']")) return;
  // 点在工具栏按钮上：不抢它们的点击
  if (target.closest("button, a, [role='button']")) return;
  event.preventDefault();
  focusInput();
}

function toggle(panel: Exclude<ComposerPanel, null>): void {
  if (editingBlocked.value) return;
  const nextPanel = props.activePanel === panel ? null : panel;
  mentionMenuOpen.value = false;
  voicePanelOpen.value = false;
  cancelVoiceRecording();
  emit("toggle-panel", nextPanel);
  focusInput();
}

function toggleInputExpanded(): void {
  if (editingBlocked.value) return;
  closePanels();
  const nextExpanded = !inputExpanded.value;
  inputExpanded.value = nextExpanded;
  emit("toggle-panel", null);
  focusInput();
}

function toggleRichMode(): void {
  if (editingBlocked.value) return;
  closePanels();
  emit("toggle-rich-mode", !props.richMode);
  emit("toggle-panel", null);
  focusInput();
}

function openMentionPicker(): void {
  if (editingBlocked.value) return;
  emit("toggle-panel", null);
  voicePanelOpen.value = false;
  cancelVoiceRecording();
  mentionQuery.value = "";
  mentionMenuOpen.value = !mentionMenuOpen.value;
  focusInput();
}

function selectMention(candidate: FlareComposerMentionCandidate): void {
  const userId = candidate.userId.trim();
  if (!userId) return;
  mentionMenuOpen.value = false;
  // 正文里放**显示名**，不是内部 user id —— 用户不该在自己的消息里看到 `@webtest2`。
  // 核心的提及解析按 user_id 与显示名（会话名册里的 nickname）双路匹配，
  // 而这里的 label 正来自同一份名册，所以插显示名一样能解析到人。
  insertAtCursor(`@${candidate.label?.trim() || userId} `);
}

/** @全员：插入核心提及解析认得的记号（all / everyone / 全员 / 所有人）。 */
function selectMentionEveryone(): void {
  mentionMenuOpen.value = false;
  insertAtCursor(`@${t("mention.everyone")} `);
}

function insertAtCursor(text: string): void {
  if (editingBlocked.value) return;
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
  if (editingBlocked.value || moreActions.value.find(action => action.op === op)?.disabled) return;
  closePanels();
  emit("build", op);
  focusInput();
}

function preferredVoiceMimeType(): string {
  const candidates = [
    "audio/webm;codecs=opus",
    "audio/webm",
    "audio/mp4",
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
  return `${String(minutes).padStart(2, "0")}:${seconds}`;
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

function stopVoiceStream(): void {
  voiceStream?.getTracks().forEach((track) => track.stop());
  voiceStream = null;
}

function resetVoiceRecordingState(): void {
  voiceRecording.value = false;
  voiceElapsedMs.value = 0;
  voiceChunks = [];
  voiceStartedAt = 0;
  voiceRecorder = null;
  clearVoiceTimer();
}

function handleVoiceStop(mimeType: string): void {
  stopVoiceStream();
  clearVoiceTimer();
  voiceRecording.value = false;
  voiceRecorder = null;
  updateVoicePreview(mimeType);
  voiceFinalize?.();
  voiceFinalize = undefined;
}

async function sendVoicePreview(): Promise<void> {
  if (!voicePreview.value || editingBlocked.value || props.sendBlocked || props.sending || voiceSubmitting.value) return;
  if (voiceElapsedMs.value < 250) { showVoiceError(t("composer.voiceTooShort")); return; }
  const request = recordingRequest;
  voiceSubmitting.value = true;
  pauseVoicePlayback();
  try {
    if (voiceRecorder && voiceRecorder.state !== "inactive") {
      await new Promise<void>(resolve => { voiceFinalize = resolve; voiceRecorder!.stop(); });
    }
    if (request !== recordingRequest || !voicePreview.value || editingBlocked.value || props.sendBlocked) return;
    if (props.sendVoiceHandler) await props.sendVoiceHandler(voicePreview.value);
    else emit("send-voice", voicePreview.value);
    if (request === recordingRequest) { clearVoicePreview(); cancelVoiceRecording(); voicePanelOpen.value = false; }
  } catch {
    if (request === recordingRequest) showVoiceError(t("composer.voiceFailed"));
  } finally { voiceSubmitting.value = false; }
}

async function startVoiceRecording(): Promise<void> {
  if (editingBlocked.value || props.sendBlocked || props.sending || voiceRecording.value || voiceRecorder || voiceRequestPending.value) return;
  const request = ++recordingRequest;
  voiceRequestPending.value = true;
  clearVoicePreview();
  emit("toggle-panel", null);
  inputExpanded.value = false;
  if (typeof navigator === "undefined" || !navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
    voiceRequestPending.value = false;
    showVoiceError(t("composer.recordingUnavailable"));
    return;
  }

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    if (request !== recordingRequest || editingBlocked.value || props.sendBlocked) { stream.getTracks().forEach(track => track.stop()); return; }
    voiceStream = stream;
    stream.getTracks().forEach(track => track.addEventListener?.("ended", () => {
      if (request !== recordingRequest) return;
      cancelVoiceRecording();
      showVoiceError(t("composer.microphoneUnavailable"));
    }, { once: true }));
    const mimeType = preferredVoiceMimeType();
    const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream);
    voiceRecorder = recorder;
    voiceChunks = [];
    voiceAccumulatedMs = 0;
    voicePaused.value = false;
    voiceError.value = "";
      voiceStartedAt = Date.now();
    voiceElapsedMs.value = 0;
    recorder.ondataavailable = (chunkEvent) => {
      if (request !== recordingRequest) return;
      if (chunkEvent.data.size > 0) voiceChunks.push(chunkEvent.data);
      if (voicePaused.value) updateVoicePreview(recorder.mimeType || mimeType);
    };
    recorder.onstop = () => { if (request === recordingRequest) handleVoiceStop(recorder.mimeType || mimeType); };
    recorder.onerror = () => {
      if (request !== recordingRequest) return;
      showVoiceError(t("composer.voiceFailed"));
      cancelVoiceRecording();
    };
    recorder.start(250);
    voiceRecording.value = true;
    startVoiceTimer();
  } catch (error) {
    if (request !== recordingRequest) return;
    stopVoiceStream();
    resetVoiceRecordingState();
    if (request === recordingRequest) showVoiceError(t("composer.microphoneUnavailable"));
  } finally {
    if (request === recordingRequest) voiceRequestPending.value = false;
  }
}

function cancelVoiceRecording(): void {
  const hadRecording = Boolean(voiceRecorder || voicePreview.value || voiceRequestPending.value);
  recordingRequest += 1;
  voiceRequestPending.value = false;
  if (voiceRecorder && voiceRecorder.state !== "inactive") voiceRecorder.stop();
  stopVoiceStream();
  resetVoiceRecordingState();
  clearVoicePreview();
  voicePaused.value = false;
  voiceAccumulatedMs = 0;
  voiceFinalize?.();
  voiceFinalize = undefined;
  if (hadRecording) emit("voice-cancel");
}

function replaceSelection(before: string, after = before, fallback = ""): void {
  if (editingBlocked.value) return;
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
  if (editingBlocked.value) return;
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
  if (editingBlocked.value) return;
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
  if (editingBlocked.value) return;
  const value = Number(raw);
  const level = value >= 1 && value <= 6 ? (value as RichHeadingLevel) : null;
  if (props.richMode) {
    richInputRef.value?.applyHeadingLevel(level);
    return;
  }
  if (level) prefixSelection(`${"#".repeat(level)} `);
}

function applyFormatFromPointer(key: FormatActionKey): void {
  if (editingBlocked.value) return;
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
  document.removeEventListener("pointerdown", onOutsidePointer);
  cancelVoiceRecording();
  clearVoicePreview();
  if (voiceErrorTimer) window.clearTimeout(voiceErrorTimer);
});
</script>

<template>
  <footer
    ref="root"
    class="composer composer-studio"
    @keydown.capture="onPanelEscape"
    :class="{
      'composer--expanded': Boolean(activePanel),
      'composer--format': richMode,
      'composer--input-expanded': inputExpanded,
      'composer--voice-recording': voiceRecording,
      'composer--voice-open': voicePanelOpen,
      'composer--disabled': editingBlocked,
      'composer--more-open': activePanel === 'more',
    }"
  >
    <section v-if="statusHint" class="composer-status-hint" role="status">
      <span
        class="composer-status-hint__dot"
        :class="{ 'composer-status-hint__dot--pulse': statusHintPulse }"
      />
      <span>{{ statusHint }}</span>
    </section>

    <section v-show="activePanel !== 'more'" v-if="showEdit" class="composer-reply-strip composer-reply-strip--edit">
      <button type="button" class="composer-reply-strip__close" :title="t('composer.cancelEdit')" @click="emit('clear-edit')">
        <n-icon :component="CloseOutline" />
      </button>
      <span class="composer-reply-strip__divider" />
      <strong>{{ t("composer.editingMessage") }}:</strong>
      <span>{{ editPreview || value || t("composer.replyFallback") }}</span>
    </section>

    <section v-show="activePanel !== 'more'" v-else-if="showReply" class="composer-reply-strip" :class="{ 'composer-reply-strip--warn': replyPreviewWarn }">
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
      <div v-show="activePanel !== 'more'" v-if="richMode" class="composer-format-strip" aria-label="Rich text" @mousedown.stop>
        <div class="composer-format-group composer-format-group--heading" role="group" aria-label="Heading level">
          <button v-for="option in headingOptions" :key="option.label" type="button"
            class="composer-format-button" :class="{ 'is-active': richFormatState.headingLevel === option.level }"
            :aria-label="option.level ? `Heading ${option.level}` : t('composer.paragraph')"
            :aria-pressed="richFormatState.headingLevel === option.level" :disabled="editingBlocked"
            @mousedown.prevent @click="applyHeadingLevel(String(option.level ?? ''))">{{ option.label }}</button>
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
            :disabled="editingBlocked"
            @pointerdown.prevent.stop="applyFormatFromPointer(action.key)"
            @click.prevent.stop="applyFormatFromClick(action.key)"
            @keydown.enter.prevent.stop="applyFormat(action.key)"
            @keydown.space.prevent.stop="applyFormat(action.key)"
          >
            <n-icon v-if="action.icon" :size="14" :component="action.icon" />
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

      <button v-if="activePanel === 'more' && value.trim()" type="button" class="composer-draft-peek" :aria-label="t('composer.resumeDraft')" @click="closePanels(); focusInput()"><n-icon :component="TextOutline" /><span>{{ value }}</span><n-icon :component="ChevronUpOutline" /></button>
      <div v-show="activePanel !== 'more'" class="composer-input-layer">
        <!--
          点输入行的任意空白处都要能开始打字——这是 IM 里最高频的一个动作。
          编辑器（textarea / 富文本）只占这一行的一部分，点到它旁边的空白
          （占位文字右侧、图标之间）时事件落在容器上，焦点进不去内部编辑器，
          于是"看着像点中了输入框，却打不出字"。
          用 mousedown 而不是 click：click 在 mouseup 才触发，那时浏览器
          已经把焦点给了容器，再 focus 会闪一下。preventDefault 阻止容器抢焦点。
          点在编辑器自身上时不介入，交给它原生处理（否则会打断选中/光标定位）。
        -->
        <div
          class="composer-input-row"
          :class="{
            'composer-input-row--multiline': isMultiline,
            'composer-input-row--focused': inputFocused,
            'composer-input-row--rich-editable': useRichEditor,
          }"
          @mousedown="onInputRowMousedown"
        >
          <ComposerRichMarkdownInput
            v-if="useRichEditor"
            ref="richInputRef"
            v-model="value"
            class="composer-input composer-rich-input"
            :disabled="editingBlocked"
            :formatting-preview="richMode"
            :max-length="maxLength"
            :placeholder="editingBlocked ? statusHint || inputPlaceholder : inputPlaceholder"
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
            :disabled="editingBlocked"
            :maxlength="maxLength"
            :autosize="inputRows"
            :input-props="composerInputProps"
            :placeholder="editingBlocked ? statusHint || inputPlaceholder : inputPlaceholder"
            @focus="inputFocused = true"
            @blur="inputFocused = false"
            @keydown="handleKeydown"
          />
          <!-- Same diagonal glyph in both layouts; desktop places it in the tool row. -->
          <button
            type="button"
            class="composer-field-expand"
            :class="{ 'is-selected': inputExpanded }"
            :aria-expanded="inputExpanded"
            :title="inputExpandTitle"
            :aria-label="inputExpandTitle"
            :disabled="editingBlocked"
            @click.stop="toggleInputExpanded"
          >
            <ComposerResizeIcon :expanded="inputExpanded" />
          </button>
        </div>


      </div>

      <div class="composer-toolbar">
        <n-button
          circle
          quaternary
          class="composer-toolbar__action composer-expand"
          :aria-expanded="inputExpanded"
          :class="{ 'is-selected': inputExpanded }"
          :title="inputExpandTitle"
          :aria-label="inputExpandTitle"
          :disabled="editingBlocked"
          @click.stop="toggleInputExpanded"
        >
          <template #icon>
            <ComposerResizeIcon :expanded="inputExpanded" />
          </template>
        </n-button>
        <n-button circle quaternary :title="t('composer.emoji')" :aria-label="t('composer.emoji')" :class="{ 'is-selected': activePanel === 'emoji' }" :disabled="editingBlocked" @click="toggle('emoji')">
          <template #icon><n-icon :size="20" :component="HappyOutline" /></template>
        </n-button>
        <div class="composer-mention-anchor">
          <n-button circle quaternary :title="t('composer.mention')" :aria-label="t('composer.mention')" :class="{ 'is-selected': mentionMenuOpen }" :aria-expanded="mentionMenuOpen" :disabled="editingBlocked" @click="openMentionPicker">
            <template #icon><n-icon :size="20" :component="AtOutline" /></template>
          </n-button>

        </div>
        <n-button
          circle
          quaternary
          :title="t('composer.voice')"
          :aria-label="t('composer.voice')"
          :class="{ 'is-selected': voicePanelOpen }"
          :disabled="editingBlocked || sendBlocked || sending"
          @click="openVoicePanel"
        >
          <template #icon><n-icon :size="20" :component="MicOutline" /></template>
        </n-button>
        <n-button circle quaternary :title="t('composer.image')" :aria-label="t('composer.image')" :disabled="editingBlocked" @click="build('create_image')">
          <template #icon><n-icon :size="20" :component="ImageOutline" /></template>
        </n-button>
        <n-button circle quaternary :title="t('composer.richText')" :aria-label="t('composer.richText')" :class="{ 'is-selected': richMode }" :disabled="editingBlocked" @click="toggleRichMode">
          <template #icon><n-icon :size="20" :component="TextOutline" /></template>
        </n-button>
        <n-button circle quaternary :title="t('composer.more')" :aria-label="t('composer.more')" :class="{ 'is-selected': activePanel === 'more' }" :aria-expanded="activePanel === 'more'" :disabled="editingBlocked" @click="toggle('more')">
          <template #icon>
            <n-icon :size="20" :component="activePanel === 'more' ? CloseOutline : AddOutline" />
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


    <section v-if="mediaPanelOpen && !editingBlocked && $slots['media-panel']" class="composer-surface composer-media-surface" :aria-label="t('composer.emoji')">
      <button type="button" class="composer-surface-close" :aria-label="t('composer.closePanel')" @click="closePanels"><n-icon :component="CloseOutline" /></button>
      <slot name="media-panel" />
    </section>
    <section v-if="mentionMenuOpen" class="composer-surface" :aria-label="t('composer.mention')">
      <button type="button" class="composer-surface-close" :aria-label="t('composer.closePanel')" @click="closePanels"><n-icon :component="CloseOutline" /></button>
          <div v-if="mentionMenuOpen" class="composer-mention-menu">
            <input v-model="mentionQuery" class="composer-panel-search" :placeholder="t('composer.searchMembers')" :aria-label="t('composer.searchMembers')" />
            <p v-if="!filteredMentions.length" role="status">{{ t("composer.noResults") }}</p>
            <button
              type="button"
              class="composer-mention-option composer-mention-option--everyone"
              @click="selectMentionEveryone"
            >
              <span class="composer-mention-option__avatar">@</span>
              <span class="composer-mention-option__body">
                <span class="composer-mention-option__label">{{ t("mention.everyone") }}</span>
                <span class="composer-mention-option__id">{{ t("mention.everyoneDetail") }}</span>
              </span>
            </button>
            <button
              v-for="candidate in filteredMentions"
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
    </section>
    <section v-if="voicePanelOpen" class="composer-voice-inline" :aria-label="t('composer.voice')">
      <button type="button" :disabled="voiceSubmitting" :title="t('composer.returnKeyboard')" :aria-label="t('composer.returnKeyboard')" @click="returnVoiceKeyboard"><Keyboard /></button>
      <button v-if="!voicePaused" type="button" class="voice-primary" :class="{ 'is-recording': voiceRecording }" :disabled="sendBlocked || sending || voiceSubmitting || voiceRequestPending" :aria-busy="voiceRequestPending" :title="voiceRecording ? t('composer.pauseRecording') : t('composer.startRecording')" :aria-label="voiceRecording ? t('composer.pauseRecording') : t('composer.startRecording')" @click="voiceRecording ? pauseVoiceRecording() : startVoiceRecording()"><n-icon :component="voiceRecording ? PauseOutline : MicOutline" /></button>
      <button v-else type="button" :disabled="!voicePreview || voiceSubmitting" :title="t('composer.previewRecording')" :aria-label="t('composer.previewRecording')" :aria-pressed="voicePlaying" @click="playVoicePreview"><n-icon :component="voicePlaying ? PauseOutline : PlayOutline" /></button>
      <div class="voice-track" :class="{ 'is-recording': voiceRecording, 'is-paused': voicePaused }" ><i aria-hidden="true" v-for="n in 64" :key="n" :style="{ height: `${6 + (n * 17 % 20)}px`, animationDelay: `${n % 7 * -.13}s` }" /><input v-if="voicePaused && voicePreview" type="range" min="0" :max="voiceElapsedMs" :value="voicePlaybackMs" :disabled="voiceSubmitting" :aria-label="t('composer.seekRecording')" @input="seekVoicePreview" /></div>
      <time>{{ formatVoiceDuration(voicePlaying ? voicePlaybackMs : voiceElapsedMs) }}</time>
      <button v-if="voicePaused && voiceRecorder" type="button" class="voice-primary" :disabled="voiceSubmitting || voiceElapsedMs >= VOICE_MAX_MS" :title="t('composer.resumeRecording')" :aria-label="t('composer.resumeRecording')" @click="resumeVoiceRecording"><n-icon :component="MicOutline" /></button>
      <button v-if="voicePaused" type="button" :disabled="voiceSubmitting" :title="t('composer.discardRecording')" :aria-label="t('composer.discardRecording')" @click="cancelVoiceRecording"><Trash2 /></button>
      <button v-if="voicePaused" type="button" class="voice-primary" :disabled="!voicePreview || sendBlocked || sending || voiceSubmitting" :aria-busy="voiceSubmitting" :title="sendTitle" :aria-label="sendTitle" @click="sendVoicePreview"><n-icon :component="SendOutline" /></button>
      <audio v-if="voicePreviewUrl" ref="voiceAudio" :src="voicePreviewUrl" @timeupdate="voicePlaybackMs = (voiceAudio?.currentTime ?? 0) * 1000" @ended="voicePlaying = false" @pause="voicePlaying = false" />
    </section>
    <section v-if="activePanel === 'more' && !editingBlocked" class="composer-surface composer-more-surface" :aria-label="t('composer.more')">
      <header v-if="moreSearchVisible || moreTitleVisible || moreCloseVisible" class="composer-more-header">
        <input v-if="moreSearchVisible" v-model="moreQuery" class="composer-panel-search" :placeholder="t('composer.searchActions')" :aria-label="t('composer.searchActions')" />
        <span v-else-if="moreTitleVisible">{{ t('composer.more') }}</span>
        <button v-if="moreCloseVisible" type="button" :aria-label="t('composer.closePanel')" @click="closePanels"><n-icon :component="CloseOutline" /></button>
      </header>
      <div class="composer-more-grid">
        <button v-for="action in pageActions" :key="action.op" type="button" class="composer-more-tile"
          :disabled="editingBlocked || action.disabled" :title="action.disabledReason || action.label" @click="build(action.op)">
          <span class="composer-more-tile__icon"><n-icon :component="action.icon ?? AddCircleOutline" /></span>
          <span>{{ action.label }}</span>
        </button>
      </div>
      <p v-if="!pageActions.length" role="status">{{ t('composer.noResults') }}</p>
      <nav v-if="morePages > 1" class="composer-pages">
        <button v-for="page in morePages" :key="page" type="button" :aria-label="t('composer.page', { page })" :aria-current="morePage === page - 1 ? 'page' : undefined" @click="morePage = page - 1"><span /></button>
      </nav>
    </section>
    <p v-if="voiceError" class="composer-voice-error" role="status">{{ voiceError }}</p>
  </footer>
</template>

<style scoped src="./composer-studio.css"></style>

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
