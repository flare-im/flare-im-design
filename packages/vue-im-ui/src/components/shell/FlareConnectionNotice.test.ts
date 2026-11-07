// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareConnectionStatus } from "../../utils/connectionNotice";
import FlareConnectionNotice from "./FlareConnectionNotice.vue";

let host: ReturnType<typeof mount> | undefined;
beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(1_000_000);
});
afterEach(() => {
  host?.unmount();
  host = undefined;
  vi.useRealTimers();
});

function mountNotice(status: FlareConnectionStatus | null, listeners: Record<string, () => void> = {}, locale: "zh-CN" | "en-US" = "zh-CN") {
  const current = ref(status);
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareConnectionNotice as Component, { status: current.value, ...listeners });
    },
  }), { attachTo: document.body });
  return { current, root: () => host!.find(".flare-connection-notice") };
}

const bannerText = () => host!.find(".flare-status-banner__text").text();
const banner = () => host!.find(".flare-status-banner");
const spoken = () => host!.find(".flare-connection-notice__spoken").text();

describe("FlareConnectionNotice", () => {
  it("shows nothing while online and says the kit's words once connecting", async () => {
    const { current } = mountNotice({ phase: "online", quality: "poor" });
    expect(banner().exists()).toBe(false);
    current.value = { phase: "connecting" };
    await nextTick();
    expect(bannerText()).toBe("正在连接…");
    expect(spoken()).toBe("正在连接…");
  });

  it("waits a second before saying it is syncing, and shows the progress", async () => {
    const { current } = mountNotice({ phase: "syncing", progress: 0.42 });
    expect(banner().exists()).toBe(false);
    await vi.advanceTimersByTimeAsync(999);
    expect(banner().exists()).toBe(false);
    await vi.advanceTimersByTimeAsync(1);
    expect(bannerText()).toBe("正在同步消息… 42%");
    current.value = { phase: "online" };
    await nextTick();
    expect(banner().exists()).toBe(false);
  });

  it("counts down to the next attempt and retries through the host", async () => {
    const retry = vi.fn();
    mountNotice({ phase: "reconnecting", nextRetryAt: Date.now() + 3000, attempt: 2 }, { onRetry: retry });
    expect(bannerText()).toBe("连接已断开，正在重连… 3 秒后重试");
    // The countdown is not announced every second: only the message is.
    expect(banner().attributes("aria-live")).toBe("off");
    expect(spoken()).toBe("连接已断开，正在重连…");
    await vi.advanceTimersByTimeAsync(1000);
    expect(bannerText()).toBe("连接已断开，正在重连… 2 秒后重试");
    await vi.advanceTimersByTimeAsync(2000);
    expect(bannerText()).toBe("连接已断开，正在重连…");
    const button = host!.find(".flare-status-banner__action");
    expect(button.text()).toBe("立即重试");
    await button.trigger("click");
    expect(retry).toHaveBeenCalledTimes(1);
  });

  it("draws an action only while the host listens for it", () => {
    mountNotice({ phase: "reconnecting" });
    expect(host!.find(".flare-status-banner__action").exists()).toBe(false);
  });

  it("keeps a quick reconnect up for the hold, then lets go", async () => {
    const { current } = mountNotice({ phase: "online" });
    current.value = { phase: "reconnecting" };
    await nextTick();
    await vi.advanceTimersByTimeAsync(300);
    current.value = { phase: "online" };
    await nextTick();
    expect(bannerText()).toBe("连接已断开，正在重连…");
    await vi.advanceTimersByTimeAsync(1200);
    expect(banner().exists()).toBe(false);
  });

  it("offers the way back each action required needs", async () => {
    const signIn = vi.fn();
    const update = vi.fn();
    const { current } = mountNotice({ phase: "actionRequired", reason: "kicked" }, { onSignIn: signIn, onUpdate: update });
    expect(bannerText()).toBe("已在其他设备登录");
    await host!.find(".flare-status-banner__action").trigger("click");
    expect(signIn).toHaveBeenCalledTimes(1);
    current.value = { phase: "actionRequired", reason: "upgradeRequired" };
    await nextTick();
    expect(bannerText()).toBe("需要更新后才能继续使用");
    expect(host!.find(".flare-status-banner__action").text()).toBe("立即更新");
    await host!.find(".flare-status-banner__action").trigger("click");
    expect(update).toHaveBeenCalledTimes(1);
    current.value = { phase: "actionRequired", reason: "tenantUnavailable" };
    await nextTick();
    expect(bannerText()).toBe("服务已暂停");
    expect(host!.find(".flare-status-banner__action").exists()).toBe(false);
  });

  it("wears the development mode badge in every phase and speaks English when the host does", async () => {
    const { current } = mountNotice({ phase: "online", developmentMode: true }, {}, "en-US");
    expect(banner().exists()).toBe(false);
    expect(host!.find(".flare-connection-notice__badge").text()).toBe("Development mode");
    current.value = { phase: "waitingForNetwork", developmentMode: true };
    await nextTick();
    expect(bannerText()).toBe("No network. Reconnects when it is back.");
    current.value = { phase: "serviceUnavailable" };
    await nextTick();
    expect(host!.find(".flare-connection-notice__badge").exists()).toBe(false);
  });
});
