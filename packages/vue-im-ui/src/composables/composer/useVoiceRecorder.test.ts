// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import { mount } from "@vue/test-utils";
import { useVoiceRecorder, type VoiceRecorder } from "./useVoiceRecorder";
import type { FlareVoiceCaptureSession, FlareVoiceRecorderAdapter } from "./voiceRecorder";

class FakeSession implements FlareVoiceCaptureSession {
  mimeType = "audio/webm";
  state: FlareVoiceCaptureSession["state"] = "inactive";
  released = 0;
  data?: (chunk: BlobPart) => void;
  stopped?: () => void;
  errored?: () => void;
  ended?: () => void;
  start() { this.state = "recording"; }
  pause() { this.state = "paused"; }
  resume() { this.state = "recording"; }
  requestData() { this.data?.(new Blob(["chunk"])); }
  stop() { this.state = "inactive"; this.stopped?.(); }
  onData(cb: (chunk: BlobPart) => void) { this.data = cb; }
  onStop(cb: () => void) { this.stopped = cb; }
  onError(cb: () => void) { this.errored = cb; }
  onEnded(cb: () => void) { this.ended = cb; }
  release() { this.released += 1; }
}

function adapter(session: FakeSession, supported = true, open = () => Promise.resolve<FlareVoiceCaptureSession>(session)): FlareVoiceRecorderAdapter {
  return { isSupported: () => supported, open };
}

let host: ReturnType<typeof mount> | undefined;
function setup(a: FlareVoiceRecorderAdapter, onError = vi.fn()) {
  let recorder!: VoiceRecorder;
  host = mount(defineComponent({ setup() { recorder = useVoiceRecorder({ adapter: a, maxMs: 5_000, onError }); return () => h("div"); } }));
  return { recorder, onError };
}
afterEach(() => { host?.unmount(); host = undefined; vi.restoreAllMocks(); });

describe("useVoiceRecorder", () => {
  it("reports an unsupported runtime without touching the adapter", async () => {
    const session = new FakeSession();
    const open = vi.fn(() => Promise.resolve<FlareVoiceCaptureSession>(session));
    const { recorder, onError } = setup(adapter(session, false, open));
    await recorder.start();
    expect(open).not.toHaveBeenCalled();
    expect(onError).toHaveBeenCalledWith("unsupported");
    expect(recorder.recording.value).toBe(false);
  });

  it("records, pauses into a preview, resumes and finalizes with the accumulated duration", async () => {
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:x");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    let now = 1000;
    vi.spyOn(Date, "now").mockImplementation(() => now);
    const session = new FakeSession();
    const { recorder } = setup(adapter(session));
    await recorder.start();
    expect(recorder.recording.value).toBe(true);
    now = 2000;
    recorder.pause();
    expect(recorder.paused.value).toBe(true);
    expect(recorder.elapsedMs.value).toBe(1000);
    expect(recorder.preview.value?.blob.size).toBeGreaterThan(0);
    expect(recorder.previewUrl.value).toBe("blob:x");
    now = 5000;
    recorder.resume();
    now = 6500;
    recorder.pause();
    expect(recorder.elapsedMs.value).toBe(2500);
    const before = recorder.preview.value;
    await recorder.finalize();
    expect(session.released).toBe(1);
    expect(recorder.hasSession.value).toBe(false);
    expect(recorder.preview.value).not.toBe(before);
    expect(recorder.preview.value?.durationMs).toBe(2500);
  });

  it("releases a microphone that arrives after the request was cancelled", async () => {
    const session = new FakeSession();
    let resolve!: (s: FlareVoiceCaptureSession) => void;
    const { recorder } = setup(adapter(session, true, () => new Promise((r) => { resolve = r; })));
    const pending = recorder.start();
    expect(recorder.requestPending.value).toBe(true);
    expect(recorder.cancel()).toBe(true);
    resolve(session);
    await pending;
    expect(session.released).toBe(1);
    expect(recorder.recording.value).toBe(false);
    expect(recorder.hasSession.value).toBe(false);
  });

  it("ignores late chunks and stop callbacks from a cancelled session", async () => {
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:late");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    const session = new FakeSession();
    const { recorder } = setup(adapter(session));
    await recorder.start();
    recorder.cancel();
    session.data?.(new Blob(["late"]));
    session.stopped?.();
    expect(recorder.preview.value).toBeNull();
    expect(recorder.elapsedMs.value).toBe(0);
  });

  it("pauses itself at the cap and refuses to resume past it", async () => {
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:cap");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    let now = 0;
    vi.spyOn(Date, "now").mockImplementation(() => now);
    const session = new FakeSession();
    const { recorder } = setup(adapter(session));
    await recorder.start();
    now = 9000;
    recorder.pause();
    expect(recorder.elapsedMs.value).toBe(5000);
    expect(recorder.atLimit.value).toBe(true);
    recorder.resume();
    expect(recorder.recording.value).toBe(false);
  });

  it("surfaces device loss and microphone failures as errors", async () => {
    const session = new FakeSession();
    const { recorder, onError } = setup(adapter(session));
    await recorder.start();
    session.ended?.();
    expect(onError).toHaveBeenCalledWith("microphone");
    expect(recorder.hasSession.value).toBe(false);
    const failing = adapter(session, true, () => Promise.reject(new Error("denied")));
    const second = setup(failing);
    await second.recorder.start();
    expect(second.onError).toHaveBeenCalledWith("microphone");
  });
});
