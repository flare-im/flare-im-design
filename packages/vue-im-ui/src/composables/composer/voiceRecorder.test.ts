// @vitest-environment happy-dom
import { afterEach, expect, it, vi } from "vitest";
import { createWebVoiceRecorderAdapter } from "./voiceRecorder";
afterEach(() => vi.unstubAllGlobals());
it("releases microphone tracks if constructing MediaRecorder fails", async () => {
  const stop=vi.fn();
  vi.stubGlobal("navigator",{mediaDevices:{getUserMedia:vi.fn().mockResolvedValue({getTracks:()=>[{stop}]})}});
  vi.stubGlobal("MediaRecorder",class { constructor(){throw new Error("codec unavailable");} static isTypeSupported(){return true;} });
  const adapter=createWebVoiceRecorderAdapter();
  await expect(adapter.open()).rejects.toThrow("codec unavailable");
  expect(stop).toHaveBeenCalledTimes(1);
});

it("releases an owned audio source exactly once, including constructor failure", async () => {
  const stop = vi.fn(), release = vi.fn();
  const stream = { getTracks: () => [{ stop }] } as unknown as MediaStream;
  vi.stubGlobal("MediaRecorder", class { state = "inactive"; mimeType = "audio/webm"; static isTypeSupported() { return true; } });
  const adapter = createWebVoiceRecorderAdapter({ acquire: async () => ({ stream, release }) });
  const session = await adapter.open();
  session.release(); session.release();
  expect(stop).toHaveBeenCalledTimes(1);
  expect(release).toHaveBeenCalledTimes(1);
  vi.stubGlobal("MediaRecorder", class { constructor() { throw new Error("codec unavailable"); } static isTypeSupported() { return true; } });
  await expect(adapter.open()).rejects.toThrow("codec unavailable");
  expect(stop).toHaveBeenCalledTimes(2);
  expect(release).toHaveBeenCalledTimes(2);
});
