// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { setFlareServerClockOffset } from "../../shared/server-clock";
import FlareCapabilityConsent from "./FlareCapabilityConsent.vue";
import FlareDocumentCapture from "./FlareDocumentCapture.vue";
import FlarePaymentConfirmation from "./FlarePaymentConfirmation.vue";
import type { FlarePaymentOrder } from "../../shared/contracts/capability-ui";

enableAutoUnmount(afterEach);
afterEach(() => {
  document.body.innerHTML = "";
  vi.useRealTimers();
  setFlareServerClockOffset(null);
});

function render(component: unknown, props: Record<string, unknown>, slots: Record<string, () => unknown> = {}) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(component as never, props, slots);
    },
  }), { attachTo: document.body });
}
const click = (selector: string) => (document.body.querySelector(selector) as HTMLButtonElement).click();

describe("FlareCapabilityConsent", () => {
  it("names the plugin and the capability and hands back the choice", async () => {
    const decisions: string[] = [];
    render(FlareCapabilityConsent, { open: true, pluginName: "Realname", capability: "documentCapture", purpose: "Verify who you are", onDecide: (d: string) => decisions.push(d) });
    await flushPromises();
    const text = document.body.textContent ?? "";
    expect(text).toContain("“Realname” wants to use");
    expect(text).toContain("The camera, to photograph a document");
    expect(text).toContain("Verify who you are");
    click("[data-consent=always]");
    click("[data-consent=once]");
    click("[data-consent=deny]");
    expect(decisions).toEqual(["always", "once", "deny"]);
  });

  it("asks a one-time location every time: no always", async () => {
    render(FlareCapabilityConsent, { open: true, pluginName: "Check-in", capability: "locationOnce", params: { precision: "fine" } });
    await flushPromises();
    expect(document.body.querySelector("[data-consent=always]")).toBeNull();
    expect(document.body.textContent).toContain("Your precise location, this time only");
  });

  it("never shows an unknown capability's raw name", async () => {
    render(FlareCapabilityConsent, { open: true, pluginName: "X", capability: "teleport" });
    await flushPromises();
    expect(document.body.querySelector("[data-consent-label]")?.textContent).toBe("A capability of this device");
  });
});

describe("FlarePaymentConfirmation", () => {
  const order = (expiresInMs: number): FlarePaymentOrder => ({
    orderId: "ord-1", amount: "1234.50", currency: "CNY", payee: "Wallet", title: "Red packet", expiresAtMs: Date.now() + expiresInMs, operation: "pay",
  });

  it("draws the order and confirms only before it expires", async () => {
    vi.useFakeTimers();
    const events: string[] = [];
    render(FlarePaymentConfirmation, { open: true, order: order(3000), pluginName: "Red Packet", onConfirm: () => events.push("confirm"), onExpire: () => events.push("expire") });
    await flushPromises();
    expect(document.body.querySelector("[data-payment-amount]")?.textContent).toBe("¥1,234.50");
    expect(document.body.querySelector("[data-payment-payee]")?.textContent).toBe("Wallet");
    expect(document.body.querySelector("[data-payment-countdown]")?.textContent).toContain("00:03");
    click("[data-payment-confirm]");
    expect(events).toEqual(["confirm"]);
    vi.advanceTimersByTime(4000);
    await flushPromises();
    expect(document.body.querySelector("[data-payment-expired]")).not.toBeNull();
    expect(events).toContain("expire");
    click("[data-payment-confirm]");
    expect(events.filter((e) => e === "confirm")).toHaveLength(1);
  });

  it("follows the server clock", async () => {
    setFlareServerClockOffset(10_000);
    render(FlarePaymentConfirmation, { open: true, order: order(5000) });
    await flushPromises();
    expect(document.body.querySelector("[data-payment-expired]")).not.toBeNull();
  });

  it("refuses an amount it cannot read, and locks while the host verifies", async () => {
    const confirms: number[] = [];
    render(FlarePaymentConfirmation, { open: true, order: { ...order(60000), amount: "1e5" }, onConfirm: () => confirms.push(1) });
    await flushPromises();
    click("[data-payment-confirm]");
    expect(confirms).toEqual([]);
    document.body.innerHTML = "";
    const cancels: number[] = [];
    render(FlarePaymentConfirmation, { open: true, order: order(60000), busy: true, onCancel: () => cancels.push(1) });
    await flushPromises();
    expect(document.body.textContent).toContain("Verifying");
  });

  it("holds the host's credential input in its slot", async () => {
    render(FlarePaymentConfirmation, { open: true, order: order(60000) }, { credential: () => h("input", { "data-credential": "true" }) });
    await flushPromises();
    expect(document.body.querySelector("[data-credential]")).not.toBeNull();
  });
});

describe("FlareDocumentCapture", () => {
  it("frames the side with the host's preview and offers the album when the camera is out", async () => {
    render(FlareDocumentCapture, { open: true, side: "holding", maxBytes: 1_000_000, cameraUnavailable: true, capture: async () => null, pickPhoto: async () => null }, { preview: () => h("video", { "data-host-preview": "true" }) });
    await flushPromises();
    expect(document.body.querySelector("[data-host-preview]")).not.toBeNull();
    expect((document.body.querySelector("[data-doc-frame]") as HTMLElement).style.aspectRatio).toMatch(/^0\.75( \/ 1)?$/);
    expect(document.body.querySelector("[data-doc-shoot]")).toBeNull();
    expect(document.body.querySelector("[data-doc-album]")).not.toBeNull();
    expect(document.body.textContent).toContain("The camera is not available");
  });

  it("says when the input does not take a JPEG and hands nothing on", async () => {
    const done: unknown[] = [];
    render(FlareDocumentCapture, { open: true, side: "front", maxBytes: 1_000_000, accept: ["image/png"], capture: async () => new Blob([new Uint8Array([1])], { type: "image/jpeg" }), onDone: (f: unknown) => done.push(f) });
    await flushPromises();
    click("[data-doc-shoot]");
    await flushPromises();
    expect(document.body.querySelector("[data-doc-error]")?.textContent).toContain("Photos are not accepted here");
    expect(done).toEqual([]);
  });
});
