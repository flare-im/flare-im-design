import { afterEach, describe, expect, it, vi } from "vitest";
import { withSameOriginEndpoints } from "./sameOriginEndpoints";

function stubLocation(protocol: string, host: string): void {
  vi.stubGlobal("window", { location: { protocol, host } });
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("withSameOriginEndpoints", () => {
  it("derives proxy paths from the page origin when the host provides nothing", () => {
    stubLocation("http:", "im.example.com");
    const resolved = withSameOriginEndpoints({});
    expect(resolved.VITE_FLARE_WS_URL).toBe("ws://im.example.com/ws");
    expect(resolved.VITE_FLARE_HTTP_URL).toBe("http://im.example.com/api");
  });

  it("upgrades the websocket scheme on https pages", () => {
    stubLocation("https:", "im.example.com");
    expect(withSameOriginEndpoints({}).VITE_FLARE_WS_URL).toBe("wss://im.example.com/ws");
  });

  it("keeps explicit configuration and only fills blanks", () => {
    stubLocation("http:", "im.example.com");
    const resolved = withSameOriginEndpoints({
      VITE_FLARE_WS_URL: "ws://127.0.0.1:60051/ws",
      VITE_FLARE_HTTP_URL: "   ",
    });
    expect(resolved.VITE_FLARE_WS_URL).toBe("ws://127.0.0.1:60051/ws");
    expect(resolved.VITE_FLARE_HTTP_URL).toBe("http://im.example.com/api");
  });

  it("leaves QUIC alone because UDP cannot be routed by path", () => {
    stubLocation("http:", "im.example.com");
    expect(withSameOriginEndpoints({}).VITE_FLARE_QUIC_URL).toBeUndefined();
  });

  it("returns the input untouched outside a browser", () => {
    vi.stubGlobal("window", undefined);
    const env = { VITE_FLARE_WS_URL: "" };
    expect(withSameOriginEndpoints(env)).toBe(env);
  });
});
