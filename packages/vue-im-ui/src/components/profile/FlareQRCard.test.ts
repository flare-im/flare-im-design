// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
enableAutoUnmount(afterEach);
import { flareDesignTokens } from "@flare-im/tokens";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareQRCard from "./FlareQRCard.vue";

function mountCard(props: InstanceType<typeof FlareQRCard>["$props"]) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareQRCard, props);
    },
  }));
  return host.findComponent(FlareQRCard);
}

describe("FlareQRCard", () => {
  it("encodes the payload as a named SVG code, dark on light, inside a 4-module quiet zone", async () => {
    const wrapper = mountCard({ name: "Ann", qrPayload: "flare://user/ann" });
    await nextTick();

    const image = wrapper.get("[role=img].flare-qr-card__code");
    expect(image.attributes("aria-label")).toBe("QR code: Ann");
    const svg = image.get("svg");
    const [, , side, sideAgain] = (svg.attributes("viewBox") ?? "").split(" ").map(Number);
    // A real symbol: version 1 is 21 modules, each version adds 4.
    expect(side).toBe(sideAgain);
    expect(side).toBeGreaterThanOrEqual(21);
    expect((side - 17) % 4).toBe(0);
    expect(svg.element.querySelector(`path[fill="${flareDesignTokens.colors.text.primary}"]`)?.getAttribute("d")).toBeTruthy();
    // The panel is the light palette in every theme and the padding is exactly four modules.
    expect(image.attributes("style")).toContain(`padding: ${400 / (side + 8)}%`);
    expect(wrapper.get(".flare-qr-card__hint").text()).toBe("Scan to add me");
  });

  it("re-encodes when the payload grows into a larger symbol", async () => {
    const payload = ref("a");
    const wrapper = mount(defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h(FlareQRCard, { name: "Ann", qrPayload: payload.value });
      },
    }));
    await nextTick();
    const small = Number(wrapper.get("svg").attributes("viewBox")?.split(" ")[2]);
    payload.value = "https://flare.example/add-friend/".padEnd(120, "x");
    await nextTick();
    await nextTick();
    const large = Number(wrapper.get("svg").attributes("viewBox")?.split(" ")[2]);
    expect(large).toBeGreaterThan(small);
    expect(wrapper.get(".flare-qr-card__code").attributes("style")).toContain(`padding: ${400 / (large + 8)}%`);
  });

  it("shows a neutral unavailable panel and no matrix without a payload", () => {
    for (const qrPayload of [undefined, "   "]) {
      const wrapper = mountCard({ name: "Ann", qrPayload });
      expect(wrapper.find(".flare-qr-card__code svg").exists()).toBe(false);
      expect(wrapper.find("[role=img].flare-qr-card__code").exists()).toBe(false);
      expect(wrapper.get(".flare-qr-card__unavailable").text()).toBe("QR code unavailable");
      expect(wrapper.find(".flare-qr-card__hint").exists()).toBe(false);
    }
  });
  it("exports the rendered symbol with its quiet zone inside the SVG", async () => {
    const wrapper = mountCard({ name: "Ann", qrPayload: "https://scan.flare.test/u/vYy5hW5dKbiV8aZraFR4rA" });
    await nextTick();
    const svg = wrapper.vm.exportSvg();
    const document = new DOMParser().parseFromString(svg!, "image/svg+xml");
    const side = Number(wrapper.get("svg").attributes("viewBox")?.split(" ")[2]);
    expect(document.documentElement.getAttribute("viewBox")).toBe(`-4 -4 ${side + 8} ${side + 8}`);
    expect(document.querySelector('rect')?.getAttribute('fill')).toBe(flareDesignTokens.colors.bg.primary);
    expect(document.querySelector('path[shape-rendering="crispEdges"]')).toBeTruthy();
    expect(document.querySelector('[href]')).toBeNull();
  });
  it('never shows the stale QR matrix after expiry or while rotating', () => {
    for (const props of [{ phase: 'ready', refreshInMs: 0 }, { phase: 'refreshing' }] as const) { const view = mount(defineComponent({ setup() { useFlareI18nProvider('en-US'); return () => h(FlareQRCard, { name: 'My code', qrPayload: 'https://scan.test/u/token', ...props }); } })); expect(view.find('.flare-qr-card__code svg').exists()).toBe(false); view.unmount(); }
  });
});

it("keeps refresh, save and share as independent controlled intents", async () => {
  const refresh = vi.fn(), save = vi.fn(), share = vi.fn();
  const card = mountCard({ name: "Ann", qrPayload: "flare://user/ann", onRefresh: refresh, onSave: save, onShare: share });
  const buttons = card.findAll(".flare-qr-card__actions button");
  expect(buttons.map(button => button.text())).toEqual(["Refresh", "Save", "Share"]);
  for (const button of buttons) await button.trigger("click");
  expect(refresh).toHaveBeenCalledTimes(1);
  expect(save).toHaveBeenCalledTimes(1);
  expect(share).toHaveBeenCalledTimes(1);
  expect(card.find(".flare-qr-card__code svg").exists()).toBe(true);
});

it("withholds stale codes and export actions while refreshing and offers retry after failure", () => {
  const retry = vi.fn();
  for (const phase of ["loading", "refreshing", "failed", "ready"] as const) {
    const card = mountCard({ name: "Ann", qrPayload: "flare://user/ann", phase, refreshInMs: phase === "ready" ? 0 : undefined, onRefresh: retry, onSave: vi.fn(), onShare: vi.fn() });
    expect(card.find(".flare-qr-card__code").exists()).toBe(false);
    expect(card.find(".flare-qr-card__actions").exists()).toBe(false);
    expect(card.attributes("aria-busy")).toBe(String(phase === "loading" || phase === "refreshing"));
    if (phase === "failed" || phase === "ready") expect(card.findAll("button").some(button => button.text() === "Retry")).toBe(true);
  }
});
