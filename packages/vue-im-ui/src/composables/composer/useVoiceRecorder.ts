import { computed, onBeforeUnmount, ref, type ComputedRef, type Ref } from "vue";
import type { FlareVoiceCaptureSession, FlareVoiceRecorderAdapter } from "./voiceRecorder";

export interface VoiceRecordingPayload {
  blob: Blob;
  durationMs: number;
  mimeType: string;
  fileName: string;
}

export type VoiceRecorderErrorKind = "unsupported" | "microphone" | "failed";

export interface UseVoiceRecorderOptions {
  adapter: FlareVoiceRecorderAdapter;
  /** Hard cap; recording pauses itself at the cap. */
  maxMs?: number;
  /** Chunk cadence handed to the capture session. */
  timesliceMs?: number;
  onError?: (kind: VoiceRecorderErrorKind) => void;
}

export interface VoiceRecorder {
  recording: Ref<boolean>;
  paused: Ref<boolean>;
  /** A microphone request is in flight (permission prompt). */
  requestPending: Ref<boolean>;
  elapsedMs: Ref<number>;
  preview: Ref<VoiceRecordingPayload | null>;
  previewUrl: Ref<string>;
  /** A capture session exists (recording or paused), so resume is possible. */
  hasSession: ComputedRef<boolean>;
  atLimit: ComputedRef<boolean>;
  maxMs: number;
  start(): Promise<void>;
  pause(): void;
  resume(): void;
  /** Stop capturing and settle the preview; resolves once the final chunk landed. */
  finalize(): Promise<void>;
  /** Drop everything (session, preview, timers). Returns whether anything was dropped. */
  cancel(): boolean;
  clearPreview(): void;
}

function fileExtension(mimeType: string): string {
  if (/mp4|m4a/i.test(mimeType)) return "m4a";
  if (/mpeg|mp3/i.test(mimeType)) return "mp3";
  if (/ogg/i.test(mimeType)) return "ogg";
  return "webm";
}

/**
 * Recording state machine of the composer voice panel: acquire → record ⇄ pause
 * → preview → finalize / cancel. Every async callback is guarded by a request
 * token so a session dismissed while the permission prompt was open, or late
 * chunks from a cancelled session, never leak into the next one.
 */
export function useVoiceRecorder(options: UseVoiceRecorderOptions): VoiceRecorder {
  const maxMs = options.maxMs ?? 65_000;
  const timesliceMs = options.timesliceMs ?? 250;
  const recording = ref(false);
  const paused = ref(false);
  const requestPending = ref(false);
  const elapsedMs = ref(0);
  const preview = ref<VoiceRecordingPayload | null>(null);
  const previewUrl = ref("");
  const sessionPresent = ref(false);

  let session: FlareVoiceCaptureSession | null = null;
  let chunks: BlobPart[] = [];
  let startedAt = 0;
  let accumulatedMs = 0;
  let timer: ReturnType<typeof setInterval> | undefined;
  let request = 0;
  let finalizeResolve: (() => void) | undefined;

  const hasSession = computed(() => sessionPresent.value);
  const atLimit = computed(() => elapsedMs.value >= maxMs);

  function clearTimer(): void {
    if (timer !== undefined) clearInterval(timer);
    timer = undefined;
  }
  function tick(): void {
    elapsedMs.value = Math.min(maxMs, accumulatedMs + Date.now() - startedAt);
    if (elapsedMs.value >= maxMs) pause();
  }
  function startTimer(): void {
    clearTimer();
    timer = setInterval(tick, 150);
  }
  function clearPreview(): void {
    if (previewUrl.value) URL.revokeObjectURL(previewUrl.value);
    previewUrl.value = "";
    preview.value = null;
  }
  function settlePreview(mimeType: string): void {
    const blob = new Blob(chunks, { type: mimeType || "audio/webm" });
    if (!blob.size) return;
    clearPreview();
    preview.value = {
      blob,
      durationMs: elapsedMs.value,
      mimeType: blob.type,
      fileName: `voice-${Date.now()}.${fileExtension(blob.type)}`,
    };
    previewUrl.value = URL.createObjectURL(blob);
  }
  function dropSession(): void {
    session?.release();
    session = null;
    sessionPresent.value = false;
    chunks = [];
    startedAt = 0;
    accumulatedMs = 0;
    recording.value = false;
    paused.value = false;
    elapsedMs.value = 0;
    clearTimer();
  }

  async function start(): Promise<void> {
    if (recording.value || session || requestPending.value) return;
    const mine = ++request;
    requestPending.value = true;
    clearPreview();
    if (!options.adapter.isSupported()) {
      requestPending.value = false;
      options.onError?.("unsupported");
      return;
    }
    try {
      const opened = await options.adapter.open();
      if (mine !== request) { opened.release(); return; }
      session = opened;
      sessionPresent.value = true;
      chunks = [];
      accumulatedMs = 0;
      startedAt = Date.now();
      elapsedMs.value = 0;
      paused.value = false;
      opened.onData((chunk) => {
        if (mine !== request) return;
        chunks.push(chunk);
        if (paused.value) settlePreview(opened.mimeType);
      });
      opened.onStop(() => {
        if (mine !== request) return;
        opened.release();
        clearTimer();
        recording.value = false;
        session = null;
        sessionPresent.value = false;
        settlePreview(opened.mimeType);
        finalizeResolve?.();
        finalizeResolve = undefined;
      });
      opened.onError(() => {
        if (mine !== request) return;
        options.onError?.("failed");
        cancel();
      });
      opened.onEnded(() => {
        if (mine !== request) return;
        cancel();
        options.onError?.("microphone");
      });
      opened.start(timesliceMs);
      recording.value = true;
      startTimer();
    } catch {
      if (mine !== request) return;
      dropSession();
      options.onError?.("microphone");
    } finally {
      if (mine === request) requestPending.value = false;
    }
  }

  function pause(): void {
    if (!session || session.state !== "recording") return;
    accumulatedMs += Date.now() - startedAt;
    elapsedMs.value = Math.min(maxMs, accumulatedMs);
    session.pause();
    recording.value = false;
    paused.value = true;
    clearTimer();
    session.requestData();
  }

  function resume(): void {
    if (!session || session.state !== "paused" || atLimit.value) return;
    clearPreview();
    session.resume();
    startedAt = Date.now();
    paused.value = false;
    recording.value = true;
    startTimer();
  }

  async function finalize(): Promise<void> {
    if (!session || session.state === "inactive") return;
    const active = session;
    await new Promise<void>((resolve) => {
      finalizeResolve = resolve;
      active.stop();
    });
  }

  function cancel(): boolean {
    const had = Boolean(session || preview.value || requestPending.value);
    request += 1;
    requestPending.value = false;
    session?.stop();
    dropSession();
    clearPreview();
    finalizeResolve?.();
    finalizeResolve = undefined;
    return had;
  }

  onBeforeUnmount(() => { cancel(); });

  return { recording, paused, requestPending, elapsedMs, preview, previewUrl, hasSession, atLimit, maxMs, start, pause, resume, finalize, cancel, clearPreview };
}

export function formatVoiceDuration(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = `${totalSeconds % 60}`.padStart(2, "0");
  return `${String(minutes).padStart(2, "0")}:${seconds}`;
}
