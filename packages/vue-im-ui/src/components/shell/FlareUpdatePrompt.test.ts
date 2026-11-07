// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareUpdatePrompt from "./FlareUpdatePrompt.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
  document.body.style.overflow = "";
});

type Listeners = Record<string, () => void>;

function mountPrompt(props: Record<string, unknown>, listeners: Listeners = {}, locale: "zh-CN" | "en-US" = "zh-CN") {
  const state = reactive<Record<string, unknown>>({ open: true, form: "sheet", version: "2.4.0", ...props });
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      useFlarePlatformProvider({ capabilities: { bottomSheet: true } });
      return () => h(FlareUpdatePrompt as Component, { ...state, ...listeners });
    },
  }), { attachTo: document.body });
  return state;
}

const allListeners = (): Listeners => ({
  onUpdate: vi.fn(),
  onLater: vi.fn(),
  onSkip: vi.fn(),
  onRetry: vi.fn(),
  onFallback: vi.fn(),
  onContinueReadOnly: vi.fn(),
});
const query = <T extends Element = HTMLElement>(selector: string) => document.querySelector<T>(selector);
const actions = () => Array.from(document.querySelectorAll<HTMLElement>("[data-flare-update-action]")).map((button) => button.dataset.flareUpdateAction);
const press = async (action: string) => {
  query(`[data-flare-update-action="${action}"]`)?.click();
  await nextTick();
};

describe("FlareUpdatePrompt", () => {
  it("draws nothing while closed", async () => {
    mountPrompt({ open: false });
    await nextTick();
    expect(query(".flare-update-prompt")).toBeNull();
  });

  it("uses the kit sheet, the kit modal and a page over the whole window", async () => {
    const state = mountPrompt({ form: "sheet" }, allListeners());
    await nextTick();
    expect(query('[data-flare-presentation="sheet"]')).not.toBeNull();

    state.form = "modal";
    await nextTick();
    expect(query('[data-flare-presentation="dialog"]')).not.toBeNull();
    expect(query(".flare-modal--fullscreen")).toBeNull();

    state.form = "fullscreen";
    state.mandatory = true;
    await nextTick();
    expect(query(".flare-modal--fullscreen")).not.toBeNull();
    expect(query(".flare-screen")).not.toBeNull();
  });

  it("offers the update, later and skip on an optional version, with the notes and the size", async () => {
    const listeners = allListeners();
    mountPrompt({ notes: ["Faster sync"], sizeBytes: 52428800, state: "available" }, listeners, "en-US");
    await nextTick();
    expect(query(".flare-update-prompt__title")?.textContent).toBe("New version available");
    expect(query(".flare-update-prompt__version")?.textContent).toBe("Version 2.4.0 · 50.0 MB");
    expect(query(".flare-update-prompt__notes-list")?.textContent).toContain("Faster sync");
    expect(actions()).toEqual(["update", "later", "skip"]);
    expect(query('[data-flare-update-action="update"]')?.textContent).toContain("Update now");
    await press("update");
    await press("later");
    await press("skip");
    expect(listeners.onUpdate).toHaveBeenCalledTimes(1);
    expect(listeners.onLater).toHaveBeenCalledTimes(1);
    expect(listeners.onSkip).toHaveBeenCalledTimes(1);
  });

  it.each([[""], [null]])("draws no version line for %j: the server refused before a manifest arrived", async (version) => {
    mountPrompt({ form: "modal", state: "required", version }, allListeners());
    await nextTick();
    expect(query(".flare-update-prompt__version")).toBeNull();
    expect(query(".flare-update-prompt__title")?.textContent).toBe("需要更新");
    expect(actions()).toEqual(["update"]);
  });

  it("draws an action only while the host listens for it", async () => {
    mountPrompt({ state: "available" }, { onUpdate: vi.fn() });
    await nextTick();
    expect(actions()).toEqual(["update"]);
  });

  it("has no close button and no way out on a forced prompt, and announces it assertively", async () => {
    const listeners = allListeners();
    mountPrompt({ form: "modal", mandatory: true, state: "required" }, listeners);
    await nextTick();
    expect(query(".flare-modal__close")).toBeNull();
    expect(actions()).toEqual(["update"]);
    const spoken = query(".flare-update-prompt__spoken");
    expect(spoken?.getAttribute("aria-live")).toBe("assertive");
    expect(spoken?.getAttribute("role")).toBe("alert");
    query(".flare-modal-scrim")?.click();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await nextTick();
    expect(listeners.onLater).not.toHaveBeenCalled();
  });

  it("offers read-only browsing on a forced prompt when allowed", async () => {
    const listeners = allListeners();
    mountPrompt({ form: "modal", mandatory: true, state: "required", canContinueReadOnly: true }, listeners);
    await nextTick();
    expect(actions()).toEqual(["update", "continueReadOnly"]);
    expect(query('[data-flare-update-action="continueReadOnly"]')?.textContent).toContain("继续浏览");
    await press("continueReadOnly");
    expect(listeners.onContinueReadOnly).toHaveBeenCalledTimes(1);
  });

  it("says the host's reason in place of the fixed words on a forced offer, and announces it", async () => {
    const reason = "这个版本已撤回，请更新。";
    mountPrompt({ form: "fullscreen", mandatory: true, state: "required", reason }, allListeners());
    await nextTick();
    expect(query(".flare-update-prompt__message")?.textContent).toBe(reason);
    expect(query(".flare-update-prompt__spoken")?.textContent).toBe(`需要更新 ${reason}`);
  });

  it("keeps the fixed words for a blank reason and when the prompt is not forced", async () => {
    const state = mountPrompt({ form: "modal", state: "required", reason: "   " }, allListeners());
    await nextTick();
    expect(query(".flare-update-prompt__message")?.textContent).toBe("当前版本已停止支持，更新后才能继续使用。");
    state.state = "available";
    state.reason = "这个版本已撤回，请更新。";
    await nextTick();
    expect(query(".flare-update-prompt__message")).toBeNull();
  });

  it("keeps a failure's own words over the reason", async () => {
    mountPrompt({ form: "modal", mandatory: true, state: "failed", errorCode: "update.downloadFailed", reason: "这个版本已撤回，请更新。" }, allListeners());
    await nextTick();
    expect(query(".flare-update-prompt__message")?.textContent).toBe("下载失败，请检查网络后重试。");
  });

  it("is polite on an optional version, and the scrim asks for later", async () => {
    const listeners = allListeners();
    mountPrompt({ form: "modal", state: "available" }, listeners);
    await nextTick();
    expect(query(".flare-update-prompt__spoken")?.getAttribute("aria-live")).toBe("polite");
    query(".flare-modal-scrim")?.click();
    await nextTick();
    expect(listeners.onLater).toHaveBeenCalledTimes(1);
  });

  it("shows the download with its number and keeps the percent out of the live region", async () => {
    const state = mountPrompt({ state: "downloading", progress: { received: 26214400, total: 52428800 } }, allListeners());
    await nextTick();
    expect(query('[role="progressbar"]')?.getAttribute("aria-valuenow")).toBe("50");
    expect(query(".flare-update-prompt__progress-text")?.textContent).toBe("50% · 25.0 MB / 50.0 MB");
    expect(actions()).toEqual(["background"]);
    const before = query(".flare-update-prompt__spoken")?.textContent;
    state.progress = { received: 39321600, total: 52428800 };
    await nextTick();
    expect(query('[role="progressbar"]')?.getAttribute("aria-valuenow")).toBe("75");
    expect(query(".flare-update-prompt__spoken")?.textContent).toBe(before);
  });

  it("asks for the metered confirmation with the size, and the answer is the update", async () => {
    const listeners = allListeners();
    mountPrompt({ state: "available", errorCode: "update.meteredConfirmationRequired", sizeBytes: 52428800 }, listeners);
    await nextTick();
    expect(query(".flare-update-prompt__message")?.textContent).toBe("当前是计费网络，这次下载约 50.0 MB");
    expect(actions()).toEqual(["continueDownload", "later"]);
    await press("continueDownload");
    expect(listeners.onUpdate).toHaveBeenCalledTimes(1);
  });

  it("says a restart finishes the update and never restarts by itself", async () => {
    const listeners = allListeners();
    mountPrompt({ state: "readyToInstall" }, listeners);
    await nextTick();
    expect(query('[data-flare-update-action="restart"]')?.textContent).toContain("重启以完成更新");
    expect(listeners.onUpdate).not.toHaveBeenCalled();
  });

  it("offers a retry and the website after a failed download on a direct install", async () => {
    const listeners = allListeners();
    mountPrompt({ state: "failed", errorCode: "update.downloadFailed" }, listeners);
    await nextTick();
    expect(query(".flare-update-prompt__message")?.textContent).toBe("下载失败，请检查网络后重试。");
    expect(actions()).toEqual(["retry", "fallback", "later"]);
    expect(query('[data-flare-update-action="fallback"]')?.textContent).toContain("前往官网下载");
    await press("retry");
    await press("fallback");
    expect(listeners.onRetry).toHaveBeenCalledTimes(1);
    expect(listeners.onFallback).toHaveBeenCalledTimes(1);
  });

  it("draws no fallback while the host has no address to send the reader to", async () => {
    const { onFallback: _unbound, ...listeners } = allListeners();
    mountPrompt({ state: "failed", errorCode: "update.downloadFailed" }, listeners);
    await nextTick();
    expect(actions()).toEqual(["retry", "later"]);
  });

  it("sends a store install to the store, and drops the retry when it cannot help", async () => {
    mountPrompt({ state: "failed", errorCode: "update.signatureMismatch", retryable: false, fallbackTarget: "store" }, allListeners());
    await nextTick();
    expect(actions()).toEqual(["fallback", "later"]);
    expect(query('[data-flare-update-action="fallback"]')?.textContent).toContain("前往应用商店");
  });
});
