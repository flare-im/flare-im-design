// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import type { FlareRedPacketOpenState } from "../../shared/contracts/red-packet";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRedPacketOpenSheet from "./FlareRedPacketOpenSheet.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
  document.body.style.overflow = "";
});

function mountSheet(props: Record<string, unknown> = {}, locale: "zh-CN" | "en-US" = "zh-CN") {
  const state = reactive<Record<string, unknown>>({
    open: true,
    senderName: "小明",
    blessing: "恭喜发财，大吉大利",
    ...props,
  });
  const events: string[] = [];
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareRedPacketOpenSheet as Component, {
        ...state,
        onOpen: () => events.push("open"),
        onViewDetails: () => events.push("viewDetails"),
        onClose: () => events.push("close"),
      });
    },
  }), { attachTo: document.body });
  return { state, events };
}

const surface = () => document.body.querySelector<HTMLElement>('[role="dialog"]')!;
const coin = () => surface().querySelector<HTMLButtonElement>(".flare-rp-open__coin");
const details = () => surface().querySelector<HTMLButtonElement>(".flare-rp-open__details");
const headline = () => surface().querySelector(".flare-rp-open__headline")!.textContent;

describe("FlareRedPacketOpenSheet", () => {
  it("is a named modal envelope over the shared scrim that renders nothing while closed", async () => {
    const { state } = mountSheet({ kindLabel: "拼手气红包" });
    await nextTick();
    expect(surface().getAttribute("aria-modal")).toBe("true");
    expect(surface().getAttribute("aria-label")).toBe("小明的红包");
    expect(surface().dataset.flarePresentation).toBe("dialog");
    expect(surface().parentElement!.classList).toContain("flare-overlay-scrim");
    expect(surface().querySelector(".flare-rp-open__kind")!.textContent).toBe("拼手气红包");
    expect(headline()).toBe("恭喜发财，大吉大利");
    state.open = false;
    await nextTick();
    expect(document.body.querySelector('[role="dialog"]')).toBeNull();
  });

  it("offers 開 when ready, focuses it, and reports the press", async () => {
    const { events } = mountSheet();
    await nextTick();
    await nextTick();
    expect(coin()!.textContent).toContain("開");
    expect(document.activeElement).toBe(coin());
    expect(details()).toBeNull();
    coin()!.click();
    expect(events).toEqual(["open"]);
  });

  it("locks 開 while opening and marks the surface busy", async () => {
    const { events } = mountSheet({ state: "opening" });
    await nextTick();
    expect(coin()!.disabled).toBe(true);
    expect(coin()!.getAttribute("aria-busy")).toBe("true");
    expect(coin()!.getAttribute("aria-label")).toBe("处理中…");
    expect(surface().getAttribute("aria-busy")).toBe("true");
    expect(surface().classList).toContain("is-opening");
    coin()!.click();
    expect(events).toEqual([]);
  });

  it.each([
    ["finished", "手慢了，红包派完了"],
    ["expired", "该红包已超过 24 小时"],
    ["notEligible", "你不能领取这个红包"],
  ] as const)("says why a %s packet does not open and links to the details", async (state, copy) => {
    const { events } = mountSheet({ state });
    await nextTick();
    expect(coin()).toBeNull();
    expect(headline()).toBe(copy);
    details()!.click();
    expect(events).toEqual(["viewDetails"]);
  });

  it("lets the host notice replace the default copy, spaced like body text and capped at three lines", async () => {
    mountSheet({ state: "notEligible", message: "仅 TA 可领取" });
    await nextTick();
    expect(headline()).toBe("仅 TA 可领取");
    expect(surface().querySelector(".flare-rp-open__headline")!.classList).toContain("is-notice");
  });

  it("keeps 開 for a retry after an error and shows why it failed", async () => {
    const { state, events } = mountSheet({ state: "error" });
    await nextTick();
    expect(surface().querySelector('[role="alert"]')!.textContent).toBe("领取失败，请重试");
    state.message = "网络不稳定";
    await nextTick();
    expect(surface().querySelector('[role="alert"]')!.textContent).toBe("网络不稳定");
    expect(headline()).toBe("恭喜发财，大吉大利");
    coin()!.click();
    expect(events).toEqual(["open"]);
  });

  it("closes from the scrim, the close key and Escape, but not from a tap on the envelope", async () => {
    const { events } = mountSheet();
    await nextTick();
    (surface().querySelector(".flare-rp-open__envelope") as HTMLElement).click();
    expect(events).toEqual([]);
    surface().parentElement!.click();
    surface().querySelector<HTMLButtonElement>('[aria-label="关闭"]')!.click();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    expect(events).toEqual(["close", "close", "close"]);
  });

  it("keeps the close key inside the focus trap", async () => {
    mountSheet({ state: "finished" });
    await nextTick();
    await nextTick();
    const close = surface().querySelector<HTMLButtonElement>('[aria-label="关闭"]')!;
    close.focus();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Tab" }));
    expect(document.activeElement).toBe(details());
  });

  it("sets a word label smaller than the ideograph and localizes the sheet", async () => {
    mountSheet({ senderName: "Ming" }, "en-US");
    await nextTick();
    expect(surface().getAttribute("aria-label")).toBe("Red packet from Ming");
    expect(coin()!.classList).toContain("is-word");
    expect(coin()!.getAttribute("aria-label")).toBe("Open");
  });

  it("names every control a screen reader lands on", async () => {
    mountSheet({ state: "finished" });
    await nextTick();
    for (const button of surface().querySelectorAll("button")) {
      expect((button.getAttribute("aria-label") ?? button.textContent ?? "").trim()).not.toBe("");
    }
    expect(surface().querySelector<HTMLButtonElement>('[aria-label="关闭"]')).not.toBeNull();
  });

  it("does not leave the page locked after it closes", async () => {
    const { state } = mountSheet();
    await nextTick();
    expect(document.body.style.overflow).toBe("hidden");
    state.open = false;
    await nextTick();
    expect(document.body.style.overflow).toBe("");
  });

  it.each(["ready", "opening", "finished", "expired", "notEligible", "error"] as FlareRedPacketOpenState[])(
    "stamps state %s for host styling and tests",
    async (state) => {
      mountSheet({ state });
      await nextTick();
      expect(surface().dataset.state).toBe(state);
    },
  );
});
