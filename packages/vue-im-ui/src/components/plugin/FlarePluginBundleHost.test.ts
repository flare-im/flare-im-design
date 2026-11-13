// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import FlarePluginBundleHost from "./FlarePluginBundleHost.vue";
import {
  FLARE_PLUGIN_BUNDLE_SANDBOX,
  flarePluginBridgeErrorKey,
  flarePluginBundleAnswer,
  flarePluginBundleEvent,
  flarePluginBundleExternalUrl,
  flarePluginBundleHostResponse,
  flarePluginBundleMessage,
  type FlarePluginBundleBridge,
} from "./pluginBundleHost";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

function bridge(overrides: Partial<FlarePluginBundleBridge> = {}): FlarePluginBundleBridge & { requests: unknown[] } {
  const requests: unknown[] = [];
  return {
    requests,
    request: vi.fn(async (envelope) => {
      requests.push(envelope);
      return { bridge: 1, id: envelope.id, type: "response", result: {} };
    }),
    close: vi.fn(),
    ...overrides,
  };
}

function frameOf(wrapper: ReturnType<typeof mount>): HTMLIFrameElement {
  return wrapper.find("iframe[data-bundle-frame]").element as HTMLIFrameElement;
}

describe("FlarePluginBundleHost", () => {
  it("frames the entry with scripts and forms only", () => {
    const wrapper = mount(FlarePluginBundleHost, {
      props: { files: "https://plugin-sandbox.example.com/b/abc/", entry: "index.html", bridge: bridge(), presentation: "detail" },
      attachTo: document.body,
    });
    const frame = frameOf(wrapper);
    expect(frame.getAttribute("sandbox")).toBe("allow-scripts allow-forms");
    expect(FLARE_PLUGIN_BUNDLE_SANDBOX).toBe("allow-scripts allow-forms");
    expect(frame.getAttribute("sandbox")).not.toContain("allow-same-origin");
    expect(frame.getAttribute("sandbox")).not.toContain("allow-popups");
    expect(frame.getAttribute("sandbox")).not.toContain("allow-top-navigation");
    expect(frame.getAttribute("src")).toBe("https://plugin-sandbox.example.com/b/abc/index.html");
    expect(frame.getAttribute("referrerpolicy")).toBe("no-referrer");
  });

  it("drops messages that do not come from its own frame", async () => {
    const host = bridge();
    const wrapper = mount(FlarePluginBundleHost, {
      props: { files: "https://plugin-sandbox.example.com/b/abc/", bridge: host, presentation: "detail" },
      attachTo: document.body,
    });
    const hello = { bridge: 1, id: "r-1", type: "request", method: "host.hello", params: {} };
    window.dispatchEvent(new MessageEvent("message", { data: hello, source: window }));
    window.dispatchEvent(new MessageEvent("message", { data: hello, source: null }));
    await flushPromises();
    expect(host.request).not.toHaveBeenCalled();

    const own = frameOf(wrapper).contentWindow;
    window.dispatchEvent(new MessageEvent("message", { data: hello, source: own as Window }));
    await flushPromises();
    expect(host.request).toHaveBeenCalledTimes(1);
    expect(wrapper.attributes("data-state")).toBe("ready");
  });

  it("ends the session when it unmounts", () => {
    const host = bridge();
    const wrapper = mount(FlarePluginBundleHost, {
      props: { files: "https://plugin-sandbox.example.com/b/abc/", bridge: host, presentation: "detail" },
    });
    wrapper.unmount();
    expect(host.close).toHaveBeenCalledTimes(1);
  });

  it("draws a host confirm and answers it once", async () => {
    const hostResult = vi.fn(async () => ({ envelope: { bridge: 1, id: "r-2", type: "response", result: { confirmed: true } } }));
    const host = bridge({
      request: vi.fn(async () => ({ host: { id: "r-2", method: "ui.confirm", params: { title: "Delete?", destructive: true } } })),
      hostResult,
    });
    const wrapper = mount(FlarePluginBundleHost, {
      props: { files: "https://plugin-sandbox.example.com/b/abc/", bridge: host, presentation: "detail" },
      attachTo: document.body,
    });
    const own = frameOf(wrapper).contentWindow as Window;
    window.dispatchEvent(new MessageEvent("message", { data: { bridge: 1, id: "r-2", type: "request", method: "ui.confirm" }, source: own }));
    await flushPromises();
    const ok = document.body.querySelector("[data-bundle-confirm='ok']") as HTMLElement | null;
    expect(ok).not.toBeNull();
    ok?.click();
    await flushPromises();
    expect(hostResult).toHaveBeenCalledWith("r-2", { result: { confirmed: true } });
  });

  it("closes on the bridge's close and reports why", async () => {
    let listener: ((event: unknown) => void) | undefined;
    const host = bridge({ subscribe: (next) => { listener = next as (event: unknown) => void; return () => { listener = undefined; }; } });
    const wrapper = mount(FlarePluginBundleHost, {
      props: { files: "https://plugin-sandbox.example.com/b/abc/", bridge: host, presentation: "detail" },
    });
    listener?.({ close: "withdrawn" });
    await flushPromises();
    expect(wrapper.emitted("closed")?.[0]).toEqual(["withdrawn"]);
    expect(wrapper.find("iframe").exists()).toBe(false);
  });
});

describe("bundle host rules", () => {
  it("reads only objects or JSON object text from the frame", () => {
    const frame = {} as Window;
    expect(flarePluginBundleMessage({ source: frame, data: '{"type":"request"}' }, frame)).toEqual({ type: "request" });
    expect(flarePluginBundleMessage({ source: frame, data: "[1]" }, frame)).toBeNull();
    expect(flarePluginBundleMessage({ source: frame, data: "x".repeat(70000) }, frame)).toBeNull();
    expect(flarePluginBundleMessage({ source: {} as Window, data: {} }, frame)).toBeNull();
    expect(flarePluginBundleMessage({ source: frame, data: {} }, null)).toBeNull();
  });

  it("opens https links only", () => {
    expect(flarePluginBundleExternalUrl("https://example.com/a")).toBe("https://example.com/a");
    expect(flarePluginBundleExternalUrl("http://example.com")).toBeNull();
    expect(flarePluginBundleExternalUrl("javascript:alert(1)")).toBeNull();
    expect(flarePluginBundleExternalUrl("https://user:pw@example.com")).toBeNull();
    expect(flarePluginBundleExternalUrl("https://exa mple.com")).toBeNull();
  });

  it("reads answers and events in both shapes", () => {
    expect(flarePluginBundleAnswer({ host: { id: "1", method: "ui.toast" } }).host?.method).toBe("ui.toast");
    expect(flarePluginBundleAnswer({ envelope: { type: "response" } }).envelope).toEqual({ type: "response" });
    expect(flarePluginBundleAnswer({ type: "response", id: "1" }).envelope?.id).toBe("1");
    expect(flarePluginBundleAnswer(null)).toEqual({});
    expect(flarePluginBundleEvent({ type: "event", event: "theme.changed" }).envelope?.event).toBe("theme.changed");
    expect(flarePluginBundleEvent({ close: "evicted" })).toEqual({ close: "evicted" });
  });

  it("names every bridge error with a kit string", () => {
    expect(flarePluginBridgeErrorKey("permission_denied")).toBe("pluginBundle.error.permissionDenied");
    expect(flarePluginBridgeErrorKey("whatever")).toBe("pluginBundle.error.internal");
    expect(flarePluginBundleHostResponse({ id: "a", method: "ui.confirm" }, { error: "cancelled" }))
      .toEqual({ bridge: 1, id: "a", type: "response", error: { code: "cancelled", messageKey: "plugin.bridge.cancelled" } });
  });
});
