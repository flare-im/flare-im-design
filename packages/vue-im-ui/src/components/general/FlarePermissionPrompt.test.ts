// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlarePermissionPrompt from "./FlarePermissionPrompt.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";

const wrappers: ReturnType<typeof mount>[] = [];

function setup(props: Record<string, unknown>, locale = "zh-CN", bottomSheet = true) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      useFlarePlatformProvider({ capabilities: { bottomSheet } });
      return () => h(FlarePermissionPrompt as Component, props);
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host;
}

const buttons = () => [...document.body.querySelectorAll("button")].map((b) => b.textContent?.trim());

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("FlarePermissionPrompt", () => {
  it("renders nothing once granted, in every form", () => {
    setup({ kind: "notifications", state: "granted", onRequest: vi.fn(), onDismiss: vi.fn() });
    setup({ kind: "notifications", state: "granted", softAsk: true, presentation: "sheet", onRequest: vi.fn() });
    expect(document.body.querySelector(".flare-permission-prompt")).toBeNull();
  });

  it("asks for notifications softly: own copy, no state chip, Not now", async () => {
    const onRequest = vi.fn();
    const onDismiss = vi.fn();
    setup({ kind: "notifications", state: "undetermined", softAsk: true, onRequest, onOpenSettings: vi.fn(), onDismiss }, "en-US");
    const prompt = document.body.querySelector(".flare-permission-prompt");
    expect(prompt?.textContent).toContain("Turn on notifications to hear about new messages when the app isn't open.");
    expect(prompt?.querySelector(".flare-permission-prompt__state")).toBeNull();
    expect(buttons()).toEqual(["Turn on notifications", "Not now"]);
    (document.body.querySelectorAll("button")[0] as HTMLButtonElement).click();
    (document.body.querySelectorAll("button")[1] as HTMLButtonElement).click();
    expect(onRequest).toHaveBeenCalledOnce();
    expect(onDismiss).toHaveBeenCalledOnce();
  });

  it("sends the person to settings once notifications were turned off", () => {
    setup({ kind: "notifications", state: "denied", softAsk: true, onRequest: vi.fn(), onOpenSettings: vi.fn(), onDismiss: vi.fn() });
    expect(buttons()).toEqual(["前往设置", "以后再说"]);
    expect(document.body.textContent).toContain("在本应用的通知里打开「允许通知」");
  });

  it("a soft-ask stays away while nothing can be done", () => {
    setup({ kind: "notifications", state: "restricted", softAsk: true, onDismiss: vi.fn() });
    expect(document.body.querySelector(".flare-permission-prompt")).toBeNull();
  });

  it("keeps the blocking panel for other kinds", () => {
    setup({ kind: "microphone", state: "denied", onOpenSettings: vi.fn(), onDismiss: vi.fn() });
    expect(document.body.querySelector(".flare-permission-prompt__state")).not.toBeNull();
    expect(buttons()).toEqual(["前往设置", "知道了"]);
  });

  it("asks in the kit sheet, where closing it is a dismiss", async () => {
    const onDismiss = vi.fn();
    setup({ kind: "notifications", state: "undetermined", softAsk: true, presentation: "sheet", onRequest: vi.fn(), onDismiss });
    const sheet = document.body.querySelector('[data-flare-presentation="sheet"]');
    expect(sheet?.querySelector(".flare-permission-prompt--sheet")).not.toBeNull();
    (document.body.querySelector(".flare-sheet-scrim") as HTMLElement).click();
    expect(onDismiss).toHaveBeenCalledOnce();
  });
});
