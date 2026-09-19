import { inject, provide, type InjectionKey } from "vue";

/**
 * Voice capture is a runtime concern (microphone permission, codec, browser
 * MediaRecorder / a native bridge), so the composer never touches it directly.
 * It talks to this adapter; the default is the web implementation below and a
 * host (Tauri, tests, a native shell) provides its own through
 * `provideFlareVoiceRecorder`.
 */
export type FlareVoiceCaptureState = "inactive" | "recording" | "paused";

export interface FlareVoiceCaptureSession {
  /** MIME type of the produced chunks (may only be known after the first chunk). */
  readonly mimeType: string;
  readonly state: FlareVoiceCaptureState;
  start(timesliceMs: number): void;
  pause(): void;
  resume(): void;
  /** Flush a chunk now (used to build a preview while paused). */
  requestData(): void;
  /** Stop capturing; `onStop` fires once the last chunk is delivered. */
  stop(): void;
  onData(callback: (chunk: BlobPart) => void): void;
  onStop(callback: () => void): void;
  onError(callback: () => void): void;
  /** The input device went away (unplugged, revoked). */
  onEnded(callback: () => void): void;
  /** Release the input device. Safe to call more than once. */
  release(): void;
}

export interface FlareVoiceRecorderAdapter {
  /** Whether capture can be attempted at all in this runtime. */
  isSupported(): boolean;
  /** Acquire the microphone; rejects on permission denial or device errors. */
  open(): Promise<FlareVoiceCaptureSession>;
}

const PREFERRED_MIME_TYPES = ["audio/webm;codecs=opus", "audio/webm", "audio/mp4"];

function preferredMimeType(): string {
  if (typeof MediaRecorder === "undefined" || typeof MediaRecorder.isTypeSupported !== "function") return "";
  return PREFERRED_MIME_TYPES.find((candidate) => MediaRecorder.isTypeSupported(candidate)) ?? "";
}

/** Browser MediaRecorder over `getUserMedia({ audio: true })`. */
export function createWebVoiceRecorderAdapter(): FlareVoiceRecorderAdapter {
  return {
    isSupported() {
      return typeof navigator !== "undefined"
        && Boolean(navigator.mediaDevices?.getUserMedia)
        && typeof MediaRecorder !== "undefined";
    },
    async open() {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mimeType = preferredMimeType();
      const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream);
      let released = false;
      const session: FlareVoiceCaptureSession = {
        get mimeType() { return recorder.mimeType || mimeType; },
        get state() { return recorder.state; },
        start: (timesliceMs) => recorder.start(timesliceMs),
        pause: () => recorder.pause(),
        resume: () => recorder.resume(),
        requestData: () => recorder.requestData(),
        stop: () => { if (recorder.state !== "inactive") recorder.stop(); },
        onData: (callback) => { recorder.ondataavailable = (event) => { if (event.data.size > 0) callback(event.data); }; },
        onStop: (callback) => { recorder.onstop = () => callback(); },
        onError: (callback) => { recorder.onerror = () => callback(); },
        onEnded: (callback) => {
          stream.getTracks().forEach((track) => track.addEventListener?.("ended", callback, { once: true }));
        },
        release: () => {
          if (released) return;
          released = true;
          stream.getTracks().forEach((track) => track.stop());
        },
      };
      return session;
    },
  };
}

const voiceRecorderKey: InjectionKey<FlareVoiceRecorderAdapter> = Symbol("flare-voice-recorder");

/** Install a host voice-capture adapter for every composer below. */
export function provideFlareVoiceRecorder(adapter: FlareVoiceRecorderAdapter): void {
  provide(voiceRecorderKey, adapter);
}

/** The injected adapter, or the web default when a host installed none. */
export function useFlareVoiceRecorderAdapter(): FlareVoiceRecorderAdapter {
  return inject(voiceRecorderKey, null) ?? createWebVoiceRecorderAdapter();
}
