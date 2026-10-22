import { describe, expect, it, vi } from "vitest";
import { createFlareBrowserLocationHost } from "./browserLocation";

type Answer = { coords: { latitude: number; longitude: number } } | { code: number; PERMISSION_DENIED?: number };

/** A geolocation API answering each request with the next scripted answer. */
function geolocation(...answers: Answer[]) {
  const getCurrentPosition = vi.fn(
    (ok: PositionCallback, fail: PositionErrorCallback | null | undefined, _options?: PositionOptions) => {
      const answer = answers.shift();
      if (!answer) throw new Error("no scripted answer");
      if ("coords" in answer) ok(answer as unknown as GeolocationPosition);
      else fail?.(answer as unknown as GeolocationPositionError);
    },
  );
  return { getCurrentPosition };
}

const permissions = (state: PermissionState | "throws") => ({
  query: vi.fn(async () => {
    if (state === "throws") throw new TypeError("geolocation is not a permission name here");
    return { state } as PermissionStatus;
  }),
});

const HERE = { coords: { latitude: 39.9087, longitude: 116.3975 } };
const DENIED = { code: 1, PERMISSION_DENIED: 1 };
const TIMEOUT = { code: 3, PERMISSION_DENIED: 1 };
const UNAVAILABLE = { code: 2 };

describe("createFlareBrowserLocationHost", () => {
  it("answers from the Permissions API without a prompt when it knows", async () => {
    const api = geolocation();
    const granted = createFlareBrowserLocationHost({ geolocation: api, permissions: permissions("granted"), secureContext: true });
    const denied = createFlareBrowserLocationHost({ geolocation: api, permissions: permissions("denied"), secureContext: true });
    await expect(granted.ensurePermission()).resolves.toBe(true);
    await expect(denied.ensurePermission()).resolves.toBe(false);
    expect(api.getCurrentPosition).not.toHaveBeenCalled();
  });

  it("shows the browser's prompt while the answer is prompt, and only a refusal is false", async () => {
    for (const [answer, allowed] of [[HERE, true], [DENIED, false], [TIMEOUT, true], [UNAVAILABLE, true]] as const) {
      const api = geolocation(answer);
      const host = createFlareBrowserLocationHost({ geolocation: api, permissions: permissions("prompt"), secureContext: true });
      await expect(host.ensurePermission()).resolves.toBe(allowed);
      expect(api.getCurrentPosition).toHaveBeenCalledTimes(1);
    }
  });

  it("prompts when the browser cannot answer for geolocation or has no Permissions API", async () => {
    const unsure = createFlareBrowserLocationHost({ geolocation: geolocation(DENIED), permissions: permissions("throws"), secureContext: true });
    await expect(unsure.ensurePermission()).resolves.toBe(false);
    const bare = createFlareBrowserLocationHost({ geolocation: geolocation(HERE), permissions: null, secureContext: true });
    await expect(bare.ensurePermission()).resolves.toBe(true);
  });

  it("is denied at once on an insecure page or without the geolocation API", async () => {
    const api = geolocation(HERE);
    const insecure = createFlareBrowserLocationHost({ geolocation: api, permissions: permissions("granted"), secureContext: false });
    await expect(insecure.ensurePermission()).resolves.toBe(false);
    await expect(insecure.requestCurrentLocation()).rejects.toThrow(/secure context/);
    expect(api.getCurrentPosition).not.toHaveBeenCalled();
    const missing = createFlareBrowserLocationHost({ geolocation: null, permissions: permissions("granted"), secureContext: true });
    await expect(missing.ensurePermission()).resolves.toBe(false);
    await expect(missing.requestCurrentLocation()).rejects.toThrow(/unavailable/);
  });

  it("hands the fix the prompt step got to the next request, once", async () => {
    const api = geolocation(HERE, { coords: { latitude: 22.5431, longitude: 114.0579 } });
    const host = createFlareBrowserLocationHost({ geolocation: api, permissions: permissions("prompt"), secureContext: true });
    await host.ensurePermission();
    await expect(host.requestCurrentLocation()).resolves.toEqual({ latitude: 39.9087, longitude: 116.3975 });
    await expect(host.requestCurrentLocation()).resolves.toEqual({ latitude: 22.5431, longitude: 114.0579 });
    expect(api.getCurrentPosition).toHaveBeenCalledTimes(2);
  });

  it("reads a fresh position after a granted answer and rejects when there is none", async () => {
    const api = geolocation(HERE, TIMEOUT);
    const host = createFlareBrowserLocationHost({ geolocation: api, permissions: permissions("granted"), secureContext: true, timeoutMs: 4000, maximumAgeMs: 0 });
    await host.ensurePermission();
    await expect(host.requestCurrentLocation()).resolves.toEqual({ latitude: 39.9087, longitude: 116.3975 });
    expect(api.getCurrentPosition.mock.calls[0]?.[2]).toEqual({ enableHighAccuracy: true, timeout: 4000, maximumAge: 0 });
    await expect(host.requestCurrentLocation()).rejects.toMatchObject({ code: 3 });
  });

  it("reads the page's own navigator when given nothing", async () => {
    const api = geolocation(HERE);
    vi.stubGlobal("navigator", { geolocation: api, permissions: permissions("granted") });
    vi.stubGlobal("isSecureContext", true);
    try {
      const host = createFlareBrowserLocationHost();
      await expect(host.ensurePermission()).resolves.toBe(true);
      await expect(host.requestCurrentLocation()).resolves.toEqual({ latitude: 39.9087, longitude: 116.3975 });
    } finally {
      vi.unstubAllGlobals();
    }
  });
});
