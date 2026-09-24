<script setup lang="ts">
import { computed, getCurrentInstance, nextTick, onBeforeUnmount, onMounted, ref, watch, type Component } from "vue";
import { resolveFormKeyboardIntent } from "../../shared/contracts/form-behavior";
import {
  AddOutline,
  AtOutline,
  ChevronUpOutline,
  CloseOutline,
  HappyOutline,
  ImageOutline,
  MicOutline,
  TextOutline,
  LocationOutline as MoreLocationOutline,
} from "../../shared/icon-glyphs";
import { flareIcons } from "../../shared/icons";
import { NButton, NIcon, NInput } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { FLARE_BREAKPOINT_TABLET_MIN } from "../../shared/contracts/layout";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import { callPlatform } from "../../shared/platform/contract";
import { useFileDrop } from "../../composables/composer/useFileDrop";
import { useMarkdownShortcuts, type MarkdownShortcutKey } from "../../composables/composer/useMarkdownShortcuts";
import { useVoiceRecorder, type VoiceRecordingPayload as RecorderPayload } from "../../composables/composer/useVoiceRecorder";
import { useFlareVoiceRecorderAdapter } from "../../composables/composer/voiceRecorder";
import type { FlareMentionCandidate } from "../../shared/contracts/directory";
import {
  resolveComposerActions,
  type FlareComposerAction,
  type FlareComposerCapabilities,
} from "../../shared/contracts/composer";
import ComposerResizeIcon from "./ComposerResizeIcon.vue";
import ComposerRichMarkdownInput, {
  type RichHeadingLevel,
  type RichMarkdownFormatState,
} from "./ComposerRichMarkdownInput.vue";
import ComposerFormatStrip from "./ComposerFormatStrip.vue";
import ComposerMoreSurface from "./ComposerMoreSurface.vue";
import ComposerUploadStrip, { type FlareComposerUploadPreview as UploadPreview } from "./ComposerUploadStrip.vue";
import ComposerVoicePanel from "./ComposerVoicePanel.vue";
import FlareComposerReplyStrip from "./FlareComposerReplyStrip.vue";
import FlareComposerSendButton from "./FlareComposerSendButton.vue";
import FlareMentionPicker from "./FlareMentionPicker.vue";

/**
 * FlareComposer — the orchestrator. It owns the draft, the active panel and the
 * keyboard, and composes the kit parts for everything else:
 *   · FlareComposerReplyStrip / FlareComposerSendButton / FlareMentionPicker /
 *     FlareComposerActionPanel (through ComposerMoreSurface) are the public parts;
 *   · ComposerUploadStrip / ComposerFormatStrip / ComposerVoicePanel are private parts;
 *   · uploads stay host-owned (`uploadItems` in, retry / remove out);
 *   · microphone access goes through the injectable voice-recorder adapter
 *     (`provideFlareVoiceRecorder`), never through the browser directly;
 *   · the mention roster is host-provided; the composer only filters and inserts.
 */
type ComposerPanel = "emoji" | "sticker" | "more" | null;
export type FlareComposerToolbarPresentation = "minimal" | "expanded";
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
 * `actions`; `id` (or `intent`) is emitted on `build`. `icon` is a semantic Flare icon
 * name or a Vue component; without one, a unified action id (`file`, `video`, ...) keeps
 * its kit glyph. `tone` tints the tile. Omit the prop to keep the built-in default set.
 */
export type FlareComposerAttachAction = FlareComposerAction<Component | string> & {
  tone?: FlareComposerActionTone;
};
export type FlareComposerUploadPreview = UploadPreview;
type VoiceRecordingPayload = RecorderPayload;

const value = defineModel<string>({ default: "" });
// Optional controlled rich-doc state — a host with its own rich-doc send flow can
// v-model these alongside the text model (universal API; unused by hosts that don't).
const richTitle = defineModel<string>("richTitle", { default: "" });
const sendAsRichDoc = defineModel<boolean>("sendAsRichDoc", { default: false });
const props = withDefaults(defineProps<{
  sending?: boolean;
  fileDropEnabled?: boolean;
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
  /** Omit for component-owned panel state; pass a value for controlled state. */
  activePanel?: ComposerPanel;
  richMode?: boolean;
  replySender?: string;
  replyPreview?: string;
  editing?: boolean;
  editPreview?: string;
  maxLength?: number;
  placeholder?: string;
  statusHint?: string;
  statusHintPulse?: boolean;
  mentionCandidates?: FlareComposerMentionCandidate[];
  /** Compact attachment previews rendered inside the composer surface. */
  uploadItems?: readonly FlareComposerUploadPreview[];
  /**
   * `minimal` keeps the everyday toolbar to emoji, attachments and send.
   * `expanded` exposes direct shortcuts for mention, voice, image and rich text.
   */
  toolbarPresentation?: FlareComposerToolbarPresentation;
  /**
   * Customize the "+" attach grid. When provided, replaces the built-in default
   * set. A tenant supplies exactly the actions it supports, in its own order,
   * with its own labels and icons. Omit to keep the restrained default set.
   */
  actions?: FlareComposerAttachAction[];
  capabilities?: FlareComposerCapabilities;
  sendVoiceHandler?: (payload: VoiceRecordingPayload) => void | Promise<void>;
}>(), {
  sending: false,
  sendBlocked: false, readOnly: false,
  moreSearchVisible: false, moreCloseVisible: false, moreTitleVisible: false,
  disabled: false,
  targetName: "",
  richMode: false,
  replySender: "",
  replyPreview: "",
  editing: false,
  editPreview: "",
  maxLength: undefined,
  placeholder: "",
  statusHint: "",
  statusHintPulse: false,
  mentionCandidates: () => [],
  uploadItems: () => [],
  fileDropEnabled: false,
  toolbarPresentation: "minimal",
  actions: undefined,
  capabilities: undefined,
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
  (event: "retry-upload", id: string): void;
  (event: "remove-upload", id: string): void;
  /**
   * The person gave the composer files: dropped on it, or chosen through the platform picker the
   * composer asked for (FR-053). One event either way, so a host uploads in one place.
   */
  (event: "files-drop", files: File[]): void;
}>();

const platform = useFlarePlatformSafe();
const { t } = useFlareI18n();
const root = ref<HTMLElement | null>(null);
const instance = getCurrentInstance();
/** Voice is offered only when a recording has somewhere to go: a handler or a send-voice listener. */
const voiceAvailable = computed(() => Boolean(props.sendVoiceHandler || instance?.vnode.props?.onSendVoice));

// ── Panels ────────────────────────────────────────────────────────────────
const localPanel = ref<ComposerPanel>(null);
const resolvedActivePanel = computed<ComposerPanel>(() =>
  props.activePanel === undefined ? localPanel.value : props.activePanel,
);
/** The emoji or sticker panel is open: the `media-panel` slot is its content. */
const mediaPanelActive = computed(() => resolvedActivePanel.value === "emoji" || resolvedActivePanel.value === "sticker");
function setActivePanel(panel: ComposerPanel): void {
  if (props.activePanel === undefined) localPanel.value = panel;
  emit("toggle-panel", panel);
}
const mentionMenuOpen = ref(false);
/** Index of the "@" the user typed to open the picker; picking a member replaces it. -1 when opened otherwise. */
const mentionTriggerIndex = ref(-1);
const voicePanelOpen = ref(false);
const inputExpanded = ref(false);

// The user's own edits: keystrokes, IME commits, paste, an inserted emoji or mention, a format
// shortcut. They report `user-input` (hosts drive typing indicators from it) and may open the member
// picker. A text the host sets, such as a draft restored on a conversation switch, and the clear
// after sending are not edits.
let userEditPending = false;
function setUserText(next: string): void {
  value.value = next;
  userEditPending = true;
  void nextTick(() => { userEditPending = false; });
  emit("user-input", next);
}
const userText = computed({ get: () => value.value, set: setUserText });
const editingBlocked = computed(() => props.disabled || props.readOnly);
const canSend = computed(() => !editingBlocked.value && !props.sendBlocked && !props.sending && value.value.trim().length > 0);
const hasInlineEmoji = computed(() => /\[[a-z][a-z0-9_]*\]/.test(value.value));
const useRichEditor = computed(() => props.richMode || sendAsRichDoc.value || hasInlineEmoji.value);
const showReply = computed(() => Boolean(props.replySender?.trim() || props.replyPreview?.trim()));
const showEdit = computed(() => props.editing);
const showContext = computed(() => Boolean(props.statusHint) || showEdit.value || showReply.value || props.uploadItems.length > 0);
// Choosing reply or edit on a message (or another message while one is open) puts the caret in the
// input, so the user types right away.
const replyKey = computed(() => (showReply.value ? `${props.replySender}\u0000${props.replyPreview}` : ""));
const editKey = computed(() => (props.editing ? `edit\u0000${props.editPreview}` : ""));
watch([replyKey, editKey], ([reply, edit], [previousReply, previousEdit]) => {
  if ((reply && reply !== previousReply) || (edit && edit !== previousEdit)) focusInput();
});
const hasUploading = computed(() => props.uploadItems.some((item) => (item.state ?? "uploading") === "uploading"));
/**
 * `expanded` 只多给桌面一点余裕，**不再决定基础动作有几个**。
 *
 * 原来 mention / 图片 / 富文本三个是 expanded 专属，于是同一个输入框在手机上只剩
 * 表情 / 语音 / + / 发送 —— 四端同一个 composer，用户换个屏幕宽度就少三个入口，
 * 而且底下面板一开，上面这排还会跟着变。基础动作在哪儿都是同一排七个；
 * 这个开关现在只管工具条里那个「放大输入框」按钮（窄屏它在输入框自己的角上）。
 */
const expandedToolbar = computed(() => props.toolbarPresentation === "expanded");
const replyPreviewWarn = computed(() => /fail|error|invalid|expired|warn/i.test(props.replyPreview ?? ""));
const replyTitle = computed(() =>
  t("composer.replyTo", { name: props.replySender?.trim() || t("composer.replyFallback") }),
);
const sendTitle = computed(() => (props.editing ? t("composer.saveEdit") : t("composer.send")));
const inputPlaceholder = computed(
  () => props.placeholder || (props.editing ? t("composer.editingPlaceholder") : props.targetName ? t("composer.sendToTarget", { name: props.targetName }) : t("composer.messagePlaceholder")),
);
const composerInputProps = computed(() => ({
  spellcheck: false,
  autocomplete: "off",
  autocapitalize: "off",
  autocorrect: "off",
  inputmode: "text",
  "aria-label": editingBlocked.value ? props.statusHint || inputPlaceholder.value : inputPlaceholder.value,
} as const));

// ── File drop (host receives the files; the composer only hosts the target) ──
const drop = useFileDrop({
  enabled: () => props.fileDropEnabled,
  accepts: () => props.fileDropEnabled && !editingBlocked.value && !props.sendBlocked && !props.sending,
  onFiles: (files) => emit("files-drop", files),
});
const dragActive = drop.active;

// ── Mentions (roster is host-provided; the picker filters, the composer inserts) ──
const mentionCandidates = computed(() => {
  const seen = new Set<string>();
  return props.mentionCandidates
    .map((candidate) => ({
      userId: candidate.userId.trim(),
      label: candidate.label?.trim() || candidate.userId.trim(),
      avatarUrl: candidate.avatarUrl?.trim() || "",
    }))
    // The whole roster: the picker filters by name and scrolls, so no member is out of reach.
    .filter((candidate) => {
      if (!candidate.userId || seen.has(candidate.userId)) return false;
      seen.add(candidate.userId);
      return true;
    });
});
const pickerCandidates = computed<FlareMentionCandidate[]>(() =>
  mentionCandidates.value.map((candidate) => ({ id: candidate.userId, name: candidate.label, avatarUrl: candidate.avatarUrl || undefined })),
);

// ── "+" actions (the default is intentionally useful but restrained; business actions are host additions) ──
const defaultAttachActions = computed<FlareComposerAttachAction[]>(() => [
  { id: "image", label: t("composer.image"), icon: ImageOutline },
  // 视频 composer 自己就能拾取(PICKER_INTENTS.video,accept video/*),却一直没出现在「+」里 ——
  // 宿主要么自己再造一个文件框,要么这个能力等于不存在。
  { id: "video", label: t("composer.video"), icon: flareIcons.video },
  { id: "file", label: t("composer.file"), icon: flareIcons.file },
  { id: "voice", label: t("composer.voice"), icon: MicOutline },
  { id: "location", label: t("composer.location"), icon: MoreLocationOutline },
  { id: "contact", label: t("composer.card"), icon: flareIcons.card },
]);
const moreActions = computed<FlareComposerAttachAction[]>(() =>
  resolveComposerActions<Component | string>({
    defaults: defaultAttachActions.value,
    capabilities: props.capabilities,
    actions: props.actions,
  }).filter((action) => voiceAvailable.value || (action.intent ?? action.id) !== "voice"),
);

// ── Voice (capture through the injected adapter; preview / confirm in the panel) ──
const voiceError = ref("");
let voiceErrorTimer: number | undefined;
function showVoiceError(text: string): void {
  voiceError.value = text;
  if (voiceErrorTimer) window.clearTimeout(voiceErrorTimer);
  voiceErrorTimer = window.setTimeout(() => {
    voiceError.value = "";
    voiceErrorTimer = undefined;
  }, 2600);
}
const recorder = useVoiceRecorder({
  adapter: useFlareVoiceRecorderAdapter(),
  onError: (kind) => showVoiceError(t(
    kind === "unsupported" ? "composer.recordingUnavailable"
      : kind === "microphone" ? "composer.microphoneUnavailable"
        : "composer.voiceFailed",
  )),
});
const voiceSubmitting = ref(false);
let voiceGeneration = 0;
function cancelVoiceRecording(): void {
  voiceGeneration += 1;
  if (recorder.cancel()) emit("voice-cancel");
}
async function startVoiceRecording(): Promise<void> {
  if (editingBlocked.value || props.sendBlocked || props.sending) return;
  setActivePanel(null);
  inputExpanded.value = false;
  await recorder.start();
}
async function sendVoicePreview(): Promise<void> {
  if (!recorder.preview.value || editingBlocked.value || props.sendBlocked || props.sending || voiceSubmitting.value) return;
  if (recorder.elapsedMs.value < 250) { showVoiceError(t("composer.voiceTooShort")); return; }
  const generation = voiceGeneration;
  voiceSubmitting.value = true;
  try {
    await recorder.finalize();
    if (generation !== voiceGeneration || !recorder.preview.value || editingBlocked.value || props.sendBlocked) return;
    const payload = recorder.preview.value;
    if (props.sendVoiceHandler) await props.sendVoiceHandler(payload);
    else emit("send-voice", payload);
    if (generation === voiceGeneration) {
      recorder.clearPreview();
      cancelVoiceRecording();
      voicePanelOpen.value = false;
    }
  } catch {
    if (generation === voiceGeneration) showVoiceError(t("composer.voiceFailed"));
  } finally {
    voiceSubmitting.value = false;
  }
}

// ── Panel choreography ─────────────────────────────────────────────────────
function closePanels(): void {
  mentionMenuOpen.value = false;
  mentionTriggerIndex.value = -1;
  voicePanelOpen.value = false;
  cancelVoiceRecording();
  if (resolvedActivePanel.value) setActivePanel(null);
}
function openVoicePanel(): void {
  if (editingBlocked.value) return;
  const next = !voicePanelOpen.value;
  closePanels();
  voicePanelOpen.value = next;
}
function onOutsidePointer(event: PointerEvent): void {
  if (voicePanelOpen.value) return;
  const target = event.target;
  if (root.value?.contains(target as Node)) return;
  // 格式条的文本样式菜单锚定后传送到 body,在 root 之外:点它的一项不是「点到了别处」,
  // 不能顺手把正开着的表情 / 贴纸面板关掉(那会往宿主发一次 toggle-panel(null))。
  if (target instanceof Element && target.closest(".flare-action-menu-popover")) return;
  closePanels();
}
function onPanelEscape(event: KeyboardEvent): void {
  if (event.key !== "Escape") return;
  if (resolvedActivePanel.value || mentionMenuOpen.value || voicePanelOpen.value) {
    event.preventDefault(); event.stopPropagation(); closePanels(); focusInput();
  } else if (inputExpanded.value) {
    event.preventDefault(); event.stopPropagation(); inputExpanded.value = false; focusInput();
  }
}
watch(() => props.activePanel, panel => {
  if (panel) { mentionMenuOpen.value = false; voicePanelOpen.value = false; cancelVoiceRecording(); }
});
watch(() => props.conversationKey, () => { closePanels(); recorder.clearPreview(); inputExpanded.value = false; drop.reset(); });
watch(editingBlocked, blocked => { if (blocked) closePanels(); });
watch(() => props.sendBlocked, blocked => { if (blocked && voicePanelOpen.value) cancelVoiceRecording(); });
onMounted(() => document.addEventListener("pointerdown", onOutsidePointer));

// ── Editor ─────────────────────────────────────────────────────────────────
const richFormatState = ref<RichMarkdownFormatState>({
  inline: { bold: false, strike: false, italic: false, underline: false, code: false },
  headingLevel: null,
});
const inputFocused = ref(false);
const richInputRef = ref<InstanceType<typeof ComposerRichMarkdownInput> | null>(null);
const plainInputResetKey = ref(0);
const inputExpandTitle = computed(() => (inputExpanded.value ? t("composer.collapseInput") : t("composer.expandInput")));
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
  const nextPanel = resolvedActivePanel.value === panel ? null : panel;
  mentionMenuOpen.value = false;
  voicePanelOpen.value = false;
  cancelVoiceRecording();
  setActivePanel(nextPanel);
  focusInput();
}

function toggleInputExpanded(): void {
  if (editingBlocked.value) return;
  closePanels();
  const nextExpanded = !inputExpanded.value;
  inputExpanded.value = nextExpanded;
  focusInput();
}

function toggleRichMode(): void {
  if (editingBlocked.value) return;
  closePanels();
  emit("toggle-rich-mode", !props.richMode);
  setActivePanel(null);
  focusInput();
}

function openMentionPicker(): void {
  if (editingBlocked.value) return;
  setActivePanel(null);
  voicePanelOpen.value = false;
  cancelVoiceRecording();
  mentionTriggerIndex.value = -1;
  mentionMenuOpen.value = !mentionMenuOpen.value;
  focusInput();
}

// Typing "@" at the start of a word opens the member picker when the host provides a roster
// (a group). An "@" inside a word, such as an email address, stays plain text.
watch(value, (next, previous = "") => {
  if (!userEditPending || useRichEditor.value || editingBlocked.value || mentionMenuOpen.value) return;
  // 名册还没到 → 这次不弹(下次输入会再试);这个会话根本不支持 @ → 永远不弹。
  if (!mentionCandidates.value.length || props.capabilities?.mentions === false) return;
  const inserted = next.length - previous.length;
  if (inserted < 1) return;
  // A pure insertion (a keystroke, an IME commit or a paste) starts where the strings first differ.
  let start = 0;
  while (start < previous.length && next[start] === previous[start]) start += 1;
  if (next.slice(start + inserted) !== previous.slice(start)) return;
  const index = start + inserted - 1;
  if (next[index] !== "@" || (index > 0 && !/\s/.test(next[index - 1]))) return;
  setActivePanel(null);
  voicePanelOpen.value = false;
  cancelVoiceRecording();
  mentionTriggerIndex.value = index;
  mentionMenuOpen.value = true;
  // Keep typing to filter: the name the user types next goes to the picker's search.
  void nextTick(() => root.value?.querySelector<HTMLInputElement>(".flare-mention__search")?.focus());
});

/** Select the "@" the user typed to open the picker, so the inserted mention replaces it. */
function selectTypedMentionTrigger(): void {
  const index = mentionTriggerIndex.value;
  mentionTriggerIndex.value = -1;
  const node = textarea();
  if (index >= 0 && node && value.value[index] === "@") node.setSelectionRange(index, index + 1);
}

function onMentionPick(picked: FlareMentionCandidate): void {
  if (picked.isEveryone) { selectMentionEveryone(); return; }
  selectMention(mentionCandidates.value.find((candidate) => candidate.userId === picked.id) ?? { userId: picked.id, label: picked.name });
}

function selectMention(candidate: FlareComposerMentionCandidate): void {
  const userId = candidate.userId.trim();
  if (!userId) return;
  mentionMenuOpen.value = false;
  selectTypedMentionTrigger();
  // 正文里放**显示名**，不是内部 user id —— 用户不该在自己的消息里看到 `@webtest2`。
  // 核心的提及解析按 user_id 与显示名（会话名册里的 nickname）双路匹配，
  // 而这里的 label 正来自同一份名册，所以插显示名一样能解析到人。
  insertAtCursor(`@${candidate.label?.trim() || userId} `);
}

/** @全员：插入核心提及解析认得的记号（all / everyone / 全员 / 所有人）。 */
function selectMentionEveryone(): void {
  mentionMenuOpen.value = false;
  selectTypedMentionTrigger();
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
    setUserText(`${value.value}${text}`);
    return;
  }
  const start = node.selectionStart ?? value.value.length;
  const end = node.selectionEnd ?? value.value.length;
  const joined = `${value.value.slice(0, start)}${text}${value.value.slice(end)}`;
  const next = props.maxLength ? joined.slice(0, props.maxLength) : joined;
  setUserText(next);
  const shouldSwitchToRichEditor = /\[[a-z][a-z0-9_]*\]/.test(next);
  void nextTick(() => {
    if (shouldSwitchToRichEditor) {
      richInputRef.value?.focus();
      return;
    }
    const offset = Math.min(start + text.length, next.length);
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

/** Attach intents the platform can serve itself, and what to ask it for. */
const PICKER_INTENTS = {
  image: { operation: "pickImages", capability: "imagePicker" },
  video: { operation: "pickFiles", capability: "filePicker", accept: ["video/*"] },
  file: { operation: "pickFiles", capability: "filePicker" },
} as const;

/**
 * An attach action the platform can serve is served here (FR-053): the composer asks the adapter and
 * reports the files it got, so every host stops clicking a hidden input of its own. Anything the
 * platform cannot do stays an intent for the host, exactly as before — including a cancelled pick,
 * which is the person saying no and means nothing more.
 */
async function pickThrough(picker: (typeof PICKER_INTENTS)[keyof typeof PICKER_INTENTS]): Promise<void> {
  const result = picker.operation === "pickImages"
    ? await callPlatform(platform.adapter.value, "pickImages", { multiple: true })
    : await callPlatform(platform.adapter.value, "pickFiles", "accept" in picker ? { accept: [...picker.accept] } : undefined);
  if (!result.ok) return;
  const files = result.value.map((picked) => picked.file).filter((file): file is File => file instanceof File);
  if (files.length) emit("files-drop", files);
}

function build(id: string): void {
  const action = moreActions.value.find(item => item.id === id);
  if (editingBlocked.value || action?.enabled === false) return;
  const intent = action?.intent ?? id;
  if (intent === "voice") {
    closePanels();
    voicePanelOpen.value = true;
    return;
  }
  closePanels();
  const picker = PICKER_INTENTS[intent as keyof typeof PICKER_INTENTS];
  if (picker && platform.capabilities.value[picker.capability] === "supported") {
    void pickThrough(picker);
    focusInput();
    return;
  }
  emit("build", intent);
  focusInput();
}

// Plain-textarea Markdown shortcuts; the rich editor applies formats itself.
const markdown = useMarkdownShortcuts({
  value: userText,
  textarea,
  maxLength: () => props.maxLength,
  blocked: () => editingBlocked.value,
  insertAtCursor,
});
function applyFormat(key: MarkdownShortcutKey): void {
  if (editingBlocked.value) return;
  if (props.richMode) {
    richInputRef.value?.applyFormat(key);
    return;
  }
  markdown.apply(key);
}
function applyHeadingLevel(level: RichHeadingLevel | null): void {
  if (editingBlocked.value) return;
  if (props.richMode) {
    richInputRef.value?.applyHeadingLevel(level);
    return;
  }
  markdown.applyHeading(level);
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
  setActivePanel(null);
  emit("send", submittedText);
  value.value = "";
  if (!useRichEditor.value) {
    plainInputResetKey.value += 1;
  }
  focusInput();
}

function handleKeydown(event: KeyboardEvent): void {
  // The composer asks the shared contract rather than re-deciding: keyCode 229
  // is the legacy IME signal some Android / Windows keyboards still send without
  // setting `isComposing`.
  const composing = event.isComposing || event.keyCode === 229;
  if (resolveFormKeyboardIntent({ key: event.key, composing }) === "none" && composing) return;
  if (event.key === "Escape" && resolvedActivePanel.value) {
    event.preventDefault();
    setActivePanel(null);
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
  if (event.shiftKey || event.altKey) return;
  if (resolveFormKeyboardIntent({ key: event.key, composing, submitOnEnter: true }) !== "submit") return;
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

/**
 * How wide the composer itself is — not how wide the window is. A chat in a 380px pane of a wide
 * desktop is a phone-shaped composer, and `window.innerWidth` would dress it as a desktop one.
 *
 * Everything inside the composer asks the `flare-composer` container query (composer-studio.css
 * names the container); a container query cannot style its own container, so the bar's own padding,
 * gap and background read this instead. Defaults to the desktop shape, the same side a composer
 * with no layout yet used to land on, so first paint is not a phone bar that jumps.
 */
const isWide = ref(true);
let widthObserver: ResizeObserver | undefined;
watch(root, (element) => {
  widthObserver?.disconnect();
  widthObserver = undefined;
  if (!element) return;
  const measure = () => {
    const width = element.getBoundingClientRect().width;
    // A 0 means "not laid out yet" (hidden tab, pre-paint), not "very narrow".
    if (width === 0) return;
    // 量的是**自己这个容器**的宽度，所以门槛也要用容器级的那一档。
    // 原来比的是窗口级的 900：聊天栏永远比窗口窄（左侧栏 72 + 会话列表 320 + 内距
    // 约 400），于是 1280 的笔记本上这里只有 874 —— composer 永远进不了桌面形态，
    // 工具条一直是手机那条 7 等分的键盘栏，横向摊在近 900px 上。
    const wide = width >= FLARE_BREAKPOINT_TABLET_MIN;
    if (wide !== isWide.value) isWide.value = wide;
  };
  measure();
  if (typeof ResizeObserver !== "undefined") {
    widthObserver = new ResizeObserver(measure);
    widthObserver.observe(element);
  }
}, { flush: "post", immediate: true });

onBeforeUnmount(() => {
  document.removeEventListener("pointerdown", onOutsidePointer);
  cancelVoiceRecording();
  recorder.clearPreview();
  widthObserver?.disconnect();
  if (voiceErrorTimer) window.clearTimeout(voiceErrorTimer);
});
</script>

<template>
  <footer
    ref="root"
    class="composer composer-studio"
    :aria-busy="sending || hasUploading"
    @keydown.capture="onPanelEscape"
    @dragenter="drop.onDragEnter"
    @dragleave="drop.onDragLeave"
    @dragover="drop.onDragOver"
    @drop="drop.onDrop"
    :class="{
      'composer--expanded': Boolean(resolvedActivePanel),
      'composer--format': richMode,
      'composer--input-expanded': inputExpanded,
      // The root says it too, so the rule that needs it does not have to ask `:has()` — an engine
      // without `:has()` drops the whole selector list, taking the class-based half with it.
      'composer--multiline': isMultiline,
      'composer--voice-recording': recorder.recording.value,
      'composer--voice-open': voicePanelOpen,
      'composer--disabled': editingBlocked,
      'composer--read-only': readOnly,
      'composer--send-blocked': sendBlocked,
      'composer--uploading': hasUploading,
      'composer--more-open': resolvedActivePanel === 'more',
      'composer--wide': isWide,
      'composer--toolbar-expanded': expandedToolbar,
    }"
  >
    <div
      class="composer-field"
      data-flare-surface-owner="composer"
      :class="{
        'composer-field--multiline': isMultiline,
        'composer-field--focused': inputFocused,
        'composer-field--context': showContext,
        'composer-field--drag-over': dragActive,
      }"
      @click.self="focusInput"
    >
      <div v-if="dragActive" class="composer-drop-hint" role="status">{{ t('composer.dropFiles') }}</div>
      <section v-if="statusHint" class="composer-status-hint" role="status">
        <span
          class="composer-status-hint__dot"
          :class="{ 'composer-status-hint__dot--pulse': statusHintPulse }"
        />
        <span>{{ statusHint }}</span>
      </section>

      <div v-if="showEdit" class="composer-reply-strip composer-reply-strip--edit">
        <FlareComposerReplyStrip
          tone="edit"
          sender-name=""
          :label="t('composer.editingMessage')"
          :summary="editPreview || value || t('composer.replyFallback')"
          :cancel-label="t('composer.cancelEdit')"
          @cancel="emit('clear-edit')"
        />
      </div>

      <div v-else-if="showReply" class="composer-reply-strip" :class="{ 'composer-reply-strip--warn': replyPreviewWarn }">
        <FlareComposerReplyStrip
          :tone="replyPreviewWarn ? 'warn' : 'default'"
          :sender-name="replySender?.trim() || t('composer.replyFallback')"
          :summary="replyPreview ?? ''"
          :cancel-label="t('composer.cancelReply')"
          :aria-label="replyTitle"
          @cancel="emit('clear-reply')"
        />
      </div>

      <ComposerUploadStrip
        v-if="uploadItems.length"
        :items="uploadItems"
        :blocked="editingBlocked || sending"
        @retry="emit('retry-upload', $event)"
        @remove="emit('remove-upload', $event)"
      />

      <div class="composer-editor-area">
      <ComposerFormatStrip
        v-if="richMode"
        :state="richFormatState"
        :disabled="editingBlocked"
        @apply="applyFormat"
        @heading="applyHeadingLevel"
      />

      <div class="composer-input-layer">
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
            :model-value="value"
            class="composer-input composer-rich-input"
            :disabled="editingBlocked"
            :formatting-preview="richMode"
            :max-length="maxLength"
            :placeholder="inputPlaceholder"
            @focus="inputFocused = true"
            @blur="inputFocused = false"
            @format-state-change="updateRichFormatState"
            @keydown="handleKeydown"
            @update:model-value="setUserText"
          />
          <n-input
            v-else
            :key="plainInputResetKey"
            :value="value"
            class="composer-input"
            type="textarea"
            :disabled="editingBlocked"
            :maxlength="maxLength"
            :autosize="inputRows"
            :input-props="composerInputProps"
            :placeholder="inputPlaceholder"
            @focus="inputFocused = true"
            @blur="inputFocused = false"
            @keydown="handleKeydown"
            @update:value="setUserText"
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
          v-if="expandedToolbar"
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
        <n-button circle quaternary :title="t('composer.emoji')" :aria-label="t('composer.emoji')" :class="{ 'is-selected': resolvedActivePanel === 'emoji' }" :disabled="editingBlocked" @click="toggle('emoji')">
          <template #icon><n-icon aria-hidden="true" :size="20" :component="HappyOutline" /></template>
        </n-button>
        <!-- 单聊不摆 @:由会话的能力位决定,不看名册空不空(群聊名册加载中也是空的)。 -->
        <div v-if="capabilities?.mentions !== false" class="composer-mention-anchor">
          <n-button circle quaternary :title="t('composer.mention')" :aria-label="t('composer.mention')" :class="{ 'is-selected': mentionMenuOpen }" :aria-expanded="mentionMenuOpen" :disabled="editingBlocked" @click="openMentionPicker">
            <template #icon><n-icon aria-hidden="true" :size="20" :component="AtOutline" /></template>
          </n-button>
        </div>
        <n-button
          v-if="voiceAvailable"
          circle
          quaternary
          class="composer-toolbar__voice"
          :title="t('composer.voice')"
          :aria-label="t('composer.voice')"
          :class="{ 'is-selected': voicePanelOpen }"
          :disabled="editingBlocked || sendBlocked || sending"
          @click="openVoicePanel"
        >
          <template #icon><n-icon aria-hidden="true" :size="20" :component="MicOutline" /></template>
        </n-button>
        <n-button circle quaternary class="composer-toolbar__image" :title="t('composer.image')" :aria-label="t('composer.image')" :disabled="editingBlocked" @click="build('image')">
          <template #icon><n-icon aria-hidden="true" :size="20" :component="ImageOutline" /></template>
        </n-button>
        <n-button circle quaternary class="composer-toolbar__rich" :title="t('composer.richText')" :aria-label="t('composer.richText')" :class="{ 'is-selected': richMode }" :disabled="editingBlocked" @click="toggleRichMode">
          <template #icon><n-icon aria-hidden="true" :size="20" :component="TextOutline" /></template>
        </n-button>
        <n-button circle quaternary :title="t('composer.more')" :aria-label="t('composer.more')" :class="{ 'is-selected': resolvedActivePanel === 'more' }" :aria-expanded="resolvedActivePanel === 'more'" :disabled="editingBlocked" @click="toggle('more')">
          <template #icon>
            <n-icon aria-hidden="true" :size="20" :component="resolvedActivePanel === 'more' ? CloseOutline : AddOutline" />
          </template>
        </n-button>
        <FlareComposerSendButton
          class="composer-toolbar__send"
          :active="canSend && !sending"
          :label="sendTitle"
          :title="sendTitle"
          @send="submit"
        />
      </div>
      </div>
    </div>

    <section v-if="mediaPanelActive && !editingBlocked && $slots['media-panel']" class="composer-surface composer-media-surface" :aria-label="t('composer.emoji')">
      <slot name="media-panel" />
    </section>
    <section v-if="mentionMenuOpen" class="composer-surface" :aria-label="t('composer.mention')">
      <div class="composer-mention-menu">
        <FlareMentionPicker
          :candidates="pickerCandidates"
          allow-everyone
          :search-placeholder="t('composer.searchMembers')"
          :everyone-label="t('mention.everyone')"
          :empty-text="t('composer.noResults')"
          @select="onMentionPick"
          @close="closePanels(); focusInput()"
        />
      </div>
    </section>
    <ComposerVoicePanel
      v-if="voicePanelOpen"
      :recorder="recorder"
      :submitting="voiceSubmitting"
      :send-blocked="sendBlocked || sending"
      :send-label="sendTitle"
      @start="startVoiceRecording"
      @pause="recorder.pause()"
      @resume="recorder.resume()"
      @discard="cancelVoiceRecording"
      @send="sendVoicePreview"
      @close="closePanels(); focusInput()"
      @preview-failed="showVoiceError(t('composer.voicePreviewFailed'))"
    />
    <ComposerMoreSurface
      v-if="resolvedActivePanel === 'more' && !editingBlocked"
      :actions="moreActions"
      :search-visible="moreSearchVisible"
      :title-visible="moreTitleVisible"
      :close-visible="moreCloseVisible"
      @select="build($event.id)"
      @close="closePanels"
    />
    <p v-if="voiceError" class="composer-voice-error" role="status">{{ voiceError }}</p>
  </footer>
</template>

<style scoped src="./composer-studio.css"></style>

<style scoped>
.composer-mention-anchor {
  position: relative;
  display: inline-flex;
}
.composer-mention-menu :deep(.flare-mention) {
  width: 100%;
  border: 0;
  border-radius: 0;
  background: transparent;
}
</style>
