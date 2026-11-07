/**
 * The update prompt, the progress bar and the version panel: what a person sees about a new version. The host hands in
 * the SDK's update status as plain values; these rules turn it into the prompt's phase, words and actions, so every app
 * offers an update the same way. Rules and their table: `spec/update-prompt-vectors.json`, run by all four kits.
 *
 * - forced: `mandatory`, the required state or the fullscreen form; it has no later, no skip and no way to the background;
 * - a forced offer says the host's reason, when there is one, in place of its fixed words;
 * - work under way (downloading, verifying, ready, installing) outranks a leftover error;
 * - the first action drawn is the primary one, and an action is drawn only while the host handles it.
 */
export type FlareUpdatePromptForm = "sheet" | "modal" | "fullscreen";
/** What the bar's colour says; the words around it carry the meaning. */
export type FlareProgressBarTone = "primary" | "success" | "warning" | "danger" | "neutral";
/** Where the fallback goes: the website on a direct install, the app store otherwise. */
export type FlareUpdateFallbackTarget = "website" | "store";
export type FlareUpdatePromptPhase = "offer" | "metered" | "downloading" | "verifying" | "ready" | "installing" | "failed";
export type FlareUpdatePromptLive = "polite" | "assertive";
export type FlareUpdatePromptTitle =
  | "available"
  | "required"
  | "metered"
  | "downloading"
  | "verifying"
  | "ready"
  | "installing"
  | "failed";
export type FlareUpdateFailure =
  | "manifestUnavailable"
  | "manifestRejected"
  | "noArtifact"
  | "insufficientSpace"
  | "downloadFailed"
  | "hashMismatch"
  | "installFailed"
  | "signatureMismatch"
  | "downgradeRejected"
  | "notSkippable"
  | "unknown";
export type FlareUpdatePromptMessage = "reason" | "required" | "requiredReadOnly" | "metered" | "meteredUnknown" | "ready" | FlareUpdateFailure;
export type FlareUpdatePromptAction =
  | "update"
  | "continueDownload"
  | "restart"
  | "retry"
  | "fallback"
  | "later"
  | "background"
  | "skip"
  | "continueReadOnly";

/** `UpdateStatus.progress`, as it arrives. */
export interface FlareUpdateProgress {
  received: number;
  /** Missing while the size is not known yet. */
  total?: number | null;
}

/** What the rules read. The SDK's status fits as it arrives. */
export interface FlareUpdatePromptInput {
  form: FlareUpdatePromptForm;
  mandatory?: boolean;
  /** `UpdateStatus.state`; any other string reads as an offer. */
  state?: string | null;
  progress?: FlareUpdateProgress | null;
  /** `UpdateStatus.error.code`. */
  errorCode?: string | null;
  /** `UpdateStatus.error.retryable`. */
  retryable?: boolean;
  sizeBytes?: number | null;
  canContinueReadOnly?: boolean;
  /** `UpdateStatus.blockReason`: a forced offer says this in place of its fixed words. */
  reason?: string | null;
}

export interface FlareProgressBarValue {
  /** 0..1; null reads as indeterminate. */
  value: number | null;
  /** Whole percent; null reads as indeterminate. */
  percent: number | null;
}

/** What the prompt shows for one status. */
export interface FlareUpdatePromptModel {
  phase: FlareUpdatePromptPhase;
  forced: boolean;
  dismissible: boolean;
  live: FlareUpdatePromptLive;
  title: FlareUpdatePromptTitle;
  message: FlareUpdatePromptMessage | null;
  actions: FlareUpdatePromptAction[];
  /** The release notes are drawn. */
  notes: boolean;
  /** The bar; null draws none. */
  progress: FlareProgressBarValue | null;
}

export type FlareVersionPanelRow = "check" | "update" | "restart";
export type FlareVersionPanelAction = "check" | "update";
export type FlareVersionPanelDetail =
  | "checking"
  | "upToDate"
  | "available"
  | "required"
  | "downloading"
  | "verifying"
  | "ready"
  | "installing"
  | "failed";
export type FlareVersionChannelText = "stable" | "beta" | "internal";

/** What the version panel's update row shows for one state. */
export interface FlareVersionPanelModel {
  row: FlareVersionPanelRow;
  /** What tapping the row does; null disables it. */
  action: FlareVersionPanelAction | null;
  detail: FlareVersionPanelDetail | null;
}

export const FLARE_UPDATE_METERED_CODE = "update.meteredConfirmationRequired";

const FAILURES: Record<string, FlareUpdateFailure> = {
  "update.manifestUnavailable": "manifestUnavailable",
  "update.manifestRejected": "manifestRejected",
  "update.noArtifact": "noArtifact",
  "update.insufficientSpace": "insufficientSpace",
  "update.downloadFailed": "downloadFailed",
  "update.hashMismatch": "hashMismatch",
  "update.installFailed": "installFailed",
  "update.signatureMismatch": "signatureMismatch",
  "update.downgradeRejected": "downgradeRejected",
  "update.notSkippable": "notSkippable",
};

/** What an error code says on the prompt; a code the kit does not know reads as unknown. */
export function flareUpdateFailure(errorCode: string | null | undefined): FlareUpdateFailure {
  return (errorCode ? FAILURES[errorCode] : undefined) ?? "unknown";
}

/** Whether the version line is drawn: the server can refuse the client before any manifest brings a release to name. */
export function flareUpdateVersionShown(version: string | null | undefined): boolean {
  return Boolean(version?.trim());
}

/** A bar's value: clamped to 0..1, or none when it is missing, not finite or asked to be indeterminate. */
export function flareProgressBarValue(value: number | null | undefined, indeterminate = false): FlareProgressBarValue {
  if (indeterminate || value === null || value === undefined || !Number.isFinite(value)) return { value: null, percent: null };
  const shown = Math.min(1, Math.max(0, value));
  return { value: shown, percent: Math.round(shown * 100) };
}

function flareUpdateSizeKnown(sizeBytes: number | null | undefined): boolean {
  return sizeBytes !== null && sizeBytes !== undefined && Number.isFinite(sizeBytes) && sizeBytes >= 0;
}

function phaseOf(input: FlareUpdatePromptInput): FlareUpdatePromptPhase {
  switch (input.state) {
    case "downloading": return "downloading";
    case "verifying": return "verifying";
    case "readyToInstall": return "ready";
    case "installing": return "installing";
  }
  if (input.errorCode === FLARE_UPDATE_METERED_CODE) return "metered";
  if (input.state === "failed" || input.errorCode) return "failed";
  return "offer";
}

function titleOf(phase: FlareUpdatePromptPhase, forced: boolean): FlareUpdatePromptTitle {
  if (phase === "offer") return forced ? "required" : "available";
  return phase;
}

function messageOf(phase: FlareUpdatePromptPhase, forced: boolean, input: FlareUpdatePromptInput): FlareUpdatePromptMessage | null {
  switch (phase) {
    case "offer":
      if (!forced) return null;
      if (input.reason?.trim()) return "reason";
      return input.canContinueReadOnly ? "requiredReadOnly" : "required";
    case "metered": return flareUpdateSizeKnown(input.sizeBytes) ? "metered" : "meteredUnknown";
    case "ready": return "ready";
    case "failed": return flareUpdateFailure(input.errorCode);
    default: return null;
  }
}

function actionsOf(phase: FlareUpdatePromptPhase, forced: boolean, input: FlareUpdatePromptInput): FlareUpdatePromptAction[] {
  const readOnly: FlareUpdatePromptAction[] = input.canContinueReadOnly ? ["continueReadOnly"] : [];
  const tail: FlareUpdatePromptAction[] = forced ? readOnly : ["later"];
  switch (phase) {
    case "offer": return ["update", ...tail, ...(!forced && input.form === "sheet" ? (["skip"] as const) : [])];
    case "metered": return ["continueDownload", ...tail];
    case "downloading":
    case "verifying": return forced ? readOnly : ["background"];
    case "ready": return ["restart", ...tail];
    case "installing": return [];
    case "failed": return [...(input.retryable === false ? [] : (["retry"] as const)), "fallback", ...tail];
  }
}

function progressOf(phase: FlareUpdatePromptPhase, input: FlareUpdatePromptInput): FlareProgressBarValue | null {
  switch (phase) {
    case "downloading": {
      const total = input.progress?.total;
      if (!input.progress || total === null || total === undefined || total <= 0) return { value: null, percent: null };
      return flareProgressBarValue(input.progress.received / total);
    }
    case "verifying":
    case "installing": return { value: null, percent: null };
    default: return null;
  }
}

/** What the prompt shows for one status (`spec/update-prompt-vectors.json`). */
export function flareUpdatePrompt(input: FlareUpdatePromptInput): FlareUpdatePromptModel {
  const forced = Boolean(input.mandatory) || input.state === "required" || input.form === "fullscreen";
  const phase = phaseOf(input);
  return {
    phase,
    forced,
    dismissible: !forced && phase !== "installing",
    live: forced ? "assertive" : "polite",
    title: titleOf(phase, forced),
    message: messageOf(phase, forced, input),
    actions: actionsOf(phase, forced, input),
    notes: phase === "offer" || phase === "metered" || phase === "downloading" || phase === "verifying",
    progress: progressOf(phase, input),
  };
}

/** What the version panel's update row shows for one state (`spec/update-prompt-vectors.json`). */
export function flareVersionPanel(updateState: string | null | undefined): FlareVersionPanelModel {
  switch (updateState) {
    case "checking": return { row: "check", action: null, detail: "checking" };
    case "upToDate": return { row: "check", action: "check", detail: "upToDate" };
    case "available": return { row: "update", action: "update", detail: "available" };
    case "required": return { row: "update", action: "update", detail: "required" };
    case "downloading": return { row: "update", action: null, detail: "downloading" };
    case "verifying": return { row: "update", action: null, detail: "verifying" };
    case "readyToInstall": return { row: "restart", action: "update", detail: "ready" };
    case "installing": return { row: "update", action: null, detail: "installing" };
    case "failed": return { row: "check", action: "check", detail: "failed" };
    default: return { row: "check", action: "check", detail: null };
  }
}

/** The channel's words of its own; null writes the channel as it arrived. */
export function flareVersionChannelText(channel: string | null | undefined): FlareVersionChannelText | null {
  return channel === "stable" || channel === "beta" || channel === "internal" ? channel : null;
}
