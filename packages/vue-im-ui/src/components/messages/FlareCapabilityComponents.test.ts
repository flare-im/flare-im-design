// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
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
    // R11: read with the currency's name, not the symbol.
    expect(document.body.querySelector("[data-payment-amount]")?.getAttribute("aria-label")).toBe(`1,234.50 ${new Intl.DisplayNames(["en-US"], { type: "currency" }).of("CNY")}`);
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

  it("notifies initial expiry once and allows a new order to expire independently", async () => {
    vi.useFakeTimers();
    const expire = vi.fn();
    const state = reactive({open: true, order: order(-1000), onExpire: expire});
    render(FlarePaymentConfirmation, state);
    await flushPromises();
    expect(expire).toHaveBeenCalledTimes(1);
    vi.advanceTimersByTime(2000); await flushPromises();
    expect(expire).toHaveBeenCalledTimes(1);
    state.order = {...order(2000), orderId: "ord-2"}; await flushPromises();
    vi.advanceTimersByTime(3000); await flushPromises();
    expect(expire).toHaveBeenCalledTimes(2);
  });
});

describe("FlareDocumentCapture", () => {
  it("locks repeated picking, recovers rejected pickers, and ignores a result for a closed side", async () => {
    let resolve!: (file: Blob | null) => void;
    const pick = vi.fn().mockRejectedValueOnce(new Error("picker failed"))
      .mockImplementationOnce(() => new Promise<Blob | null>(done => {resolve = done;}));
    const done = vi.fn();
    const state = reactive({open: true, side: "front", maxBytes: 1000000, pickPhoto: pick, onDone: done});
    render(FlareDocumentCapture, state);
    await flushPromises(); click("[data-doc-album]"); await flushPromises();
    expect(document.body.querySelector("[data-doc-error]")).not.toBeNull();
    click("[data-doc-album]"); click("[data-doc-album]"); await flushPromises();
    expect(pick).toHaveBeenCalledTimes(2);
    state.open = false; state.side = "back"; await flushPromises();
    resolve(new Blob(["late photo"], {type: "image/png"})); await flushPromises();
    state.open = true; await flushPromises();
    expect(document.body.querySelector("[data-doc-error]")).toBeNull();
    expect(document.body.querySelector("[data-doc-review]")).toBeNull();
    expect(done).not.toHaveBeenCalled();
  });
  it("frames the side with the host's preview and offers the album when the camera is out", async () => {
    render(FlareDocumentCapture, { open: true, side: "holding", maxBytes: 1_000_000, cameraUnavailable: true, capture: async () => null, pickPhoto: async () => null }, { preview: () => h("video", { "data-host-preview": "true" }) });
    await flushPromises();
    expect(document.body.querySelector("[data-host-preview]")).not.toBeNull();
    expect((document.body.querySelector("[data-doc-frame]") as HTMLElement).style.aspectRatio).toMatch(/^0\.75( \/ 1)?$/);
    expect(document.body.querySelector("[data-doc-shoot]")).toBeNull();
    expect(document.body.querySelector("[data-doc-album]")).not.toBeNull();
    expect(document.body.textContent).toContain("Camera unavailable — choose from album");
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

  // §6.4 (round 2): phone full screen on the media stage, PC 560 dialog with "Choose file" and the shutter first.
  function mockViewport(narrow: boolean) {
    vi.stubGlobal("matchMedia", (query: string) => ({ matches: narrow && query.includes("max-width"), media: query, addEventListener() {}, removeEventListener() {}, addListener() {}, removeListener() {} }));
  }
  afterEach(() => vi.unstubAllGlobals());

  it("is a full-screen stage on a narrow viewport even without a provider", async () => {
    mockViewport(true);
    render(FlareDocumentCapture, { open: true, side: "front", maxBytes: 1_000_000, capture: async () => null, pickPhoto: async () => null });
    await flushPromises();
    expect(document.body.querySelector(".flare-doc-capture.is-fullscreen")).not.toBeNull();
    expect(document.body.querySelector("[data-doc-album]")?.textContent).toContain("Album");
  });

  it("is the dialog on a wide viewport: Choose file, and the shutter takes the opening focus for Space", async () => {
    mockViewport(false);
    render(FlareDocumentCapture, { open: true, side: "front", maxBytes: 1_000_000, capture: async () => null, pickPhoto: async () => null });
    await flushPromises();
    expect(document.body.querySelector(".flare-doc-capture.is-fullscreen")).toBeNull();
    expect(document.body.querySelector("[data-doc-album]")?.textContent).toContain("Choose file");
    const keys = [...document.body.querySelectorAll(".flare-doc-capture__actions button")];
    expect(keys[0]?.hasAttribute("data-doc-shoot")).toBe(true);
    expect(keys[0]?.getAttribute("title")).toContain("(Space)");
  });
});

describe("FlarePaymentConfirmation (docs/plugin-experience.md §4.3)", () => {
  const order = (expiresInMs: number): FlarePaymentOrder => ({
    orderId: "ord-9", amount: "26.64", currency: "CNY", payee: "Wallet", title: "Red packet", expiresAtMs: Date.now() + expiresInMs, operation: "pay",
  });

  it("folds the order number behind its row, then shows it with a copy key", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, "clipboard", { value: { writeText }, configurable: true });
    render(FlarePaymentConfirmation, { open: true, order: order(600000) });
    await flushPromises();
    const toggle = document.body.querySelector("[data-payment-order-toggle]") as HTMLButtonElement;
    expect(toggle.getAttribute("aria-expanded")).toBe("false");
    expect(document.body.querySelector("[data-payment-order]")).toBeNull();
    toggle.click(); await flushPromises();
    expect(toggle.getAttribute("aria-expanded")).toBe("true");
    expect(document.body.querySelector("[data-payment-order]")?.textContent).toContain("ord-9");
    const copy = document.body.querySelector("[data-payment-order-copy]") as HTMLButtonElement;
    expect(copy.getAttribute("aria-label")).toBe("Copy Order");
    copy.click(); await flushPromises();
    expect(writeText).toHaveBeenCalledWith("ord-9");
  });

  it("blocks confirm on a shortfall and offers a top-up instead", async () => {
    const events: string[] = [];
    render(FlarePaymentConfirmation, { open: true, order: order(600000), shortfall: "¥6.64", onConfirm: () => events.push("confirm"), onTopUp: () => events.push("topUp") });
    await flushPromises();
    expect(document.body.querySelector("[data-payment-shortfall]")?.textContent).toContain("¥6.64");
    expect((document.body.querySelector("[data-payment-confirm]") as HTMLButtonElement).disabled).toBe(true);
    click("[data-payment-confirm]");
    click("[data-payment-top-up]");
    expect(events).toEqual(["topUp"]);
  });

  it("warns under a minute, then dims the amount and starts again once expired", async () => {
    vi.useFakeTimers();
    const events: string[] = [];
    render(FlarePaymentConfirmation, { open: true, order: order(59_000), onConfirm: () => events.push("confirm"), onCancel: () => events.push("cancel"), onExpire: () => events.push("expire"), onStartAgain: () => events.push("startAgain") });
    await flushPromises();
    expect(document.body.querySelector("[data-payment-countdown]")?.classList.contains("is-closing")).toBe(true);
    vi.advanceTimersByTime(60_000);
    await flushPromises();
    expect(document.body.querySelector("[data-payment-amount]")?.classList.contains("is-expired")).toBe(true);
    const key = document.body.querySelector("[data-payment-confirm]") as HTMLButtonElement;
    expect(key.textContent?.trim()).toBe("Start again");
    expect(key.disabled).toBe(false);
    key.click();
    expect(events).toEqual(["expire", "startAgain"]);
  });

  it("titles itself once, centred in the panel, and cancels with a secondary key (§12.19)", async () => {
    render(FlarePaymentConfirmation, { open: true, order: order(600000) });
    await flushPromises();
    expect(document.body.querySelector("[data-payment-title]")?.textContent).toBe("Confirm payment");
    expect(document.body.querySelector(".flare-sheet__title, .flare-modal__title")).toBeNull();
    expect(document.body.querySelector("[data-payment-cancel]")?.classList.contains("flare-button--secondary")).toBe(true);
  });

  it("shows the host's failure as a danger banner over the keys and keeps the panel open", async () => {
    render(FlarePaymentConfirmation, { open: true, order: order(600000), error: "Wrong password, 2 tries left" });
    await flushPromises();
    const banner = document.body.querySelector(".flare-status-banner--danger");
    expect(banner?.getAttribute("role")).toBe("alert");
    expect(banner?.textContent).toContain("Wrong password, 2 tries left");
    expect(document.body.querySelector("[data-payment-confirmation]")).not.toBeNull();
  });
});
