// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareAccessPoint, FlareAccessStatus } from "../../utils/accessDiagnostics";
import FlareAccessDiagnostics from "./FlareAccessDiagnostics.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
});

const healthy: FlareAccessStatus = {
  loaded: true,
  accessPointId: "ap-sg-1",
  regionId: "sg",
  protocol: "quic",
  serial: 42,
  source: "https:https://cfg-b.other-cloud.net/flare/v1/abc/",
  stale: false,
  developmentMode: false,
};
const lines: FlareAccessPoint[] = [
  { accessPointId: "ap-sg-1", regionId: "sg", host: "sg1.example.net", status: "active", rttMs: 86, breaker: "closed", pinned: false, current: true },
  { accessPointId: "ap-sg-2", regionId: "sg", host: "sg2.example.net", status: "active", rttMs: 420, breaker: "open", pinned: false, current: false },
  { accessPointId: "ap-de-1", regionId: "de", host: "de1.example.net", status: "draining", breaker: "closed", pinned: false, current: false },
];

function mountPage(props: Record<string, unknown>, locale: "zh-CN" | "en-US" = "zh-CN") {
  const current = ref(props);
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareAccessDiagnostics as Component, current.value);
    },
  }), { attachTo: document.body });
  return current;
}

const page = () => host!.find(".flare-access-diagnostics");
const banners = () => host!.findAll(".flare-status-banner__text").map((banner) => banner.text());
const spoken = () => host!.find(".flare-access-diagnostics__spoken").text();
const row = (id: string) => host!.find(`[data-flare-access-point="${id}"]`);
const button = (label: string) => host!.findAll("button").find((candidate) => candidate.text() === label);
const titles = () => host!.findAll(".flare-access-diagnostics__title").map((title) => title.text());
const fact = (label: string) => {
  const line = host!.findAll(".flare-description-list__item").find((item) => item.find("dt").text() === label);
  return line?.find("dd").text();
};

describe("FlareAccessDiagnostics", () => {
  it("says nothing before the host has read a status, and shows dashes rather than blanks", () => {
    mountPage({ status: null });
    expect(page().attributes("data-flare-access-state")).toBe("normal");
    expect(banners()).toEqual([]);
    expect(fact("接入点")).toContain("—");
    expect(host!.text()).toContain("暂无可用线路");
  });

  it("draws the current line and groups the list by region", () => {
    mountPage({ status: healthy, accessPoints: lines });
    expect(banners()).toEqual(["线路正常"]);
    expect(fact("接入点")).toBe("ap-sg-1");
    expect(fact("协议")).toBe("QUIC");
    expect(fact("延迟")).toBe("86 ms · 良好");
    expect(host!.find(".flare-description-list [data-tone]").attributes("data-tone")).toBe("success");
    expect(fact("清单版本")).toBe("42");
    expect(fact("清单来源")).toBe("镜像 cfg-b.other-cloud.net");
    expect(fact("清单状态")).toBe("有效");
    expect(fact("开发模式")).toBe("关闭");
    expect(host!.findAll(".flare-access-diagnostics__region-title").map((title) => title.text())).toEqual(["sg", "de"]);
    expect(row("ap-sg-1").text()).toContain("当前");
    expect(row("ap-sg-1").text()).toContain("可用");
    expect(row("ap-sg-2").text()).toContain("已熔断");
    expect(row("ap-sg-2").text()).toContain("420 ms · 较差");
    expect(row("ap-de-1").text()).toContain("即将下线");
  });

  it("reads in English", () => {
    mountPage({ status: { ...healthy, stale: true }, accessPoints: lines }, "en-US");
    expect(banners()).toEqual(["The line manifest has expired. You can still connect while it updates."]);
    expect(fact("Manifest status")).toBe("Expired");
    expect(fact("Latency")).toBe("86 ms · Good");
  });

  it("puts recovery first while recovering, and says the kit's words", () => {
    mountPage({ status: { loaded: true, serial: 7, recovering: { rounds: 2, nextRoundAtMs: 91_000 } }, accessPoints: [] });
    expect(page().attributes("data-flare-access-state")).toBe("recovering");
    expect(banners()).toEqual(["服务暂时不可用，正在自动恢复…"]);
    expect(spoken()).toBe("服务暂时不可用，正在自动恢复…");
    expect(titles()).toEqual(["恢复工具", "当前线路", "全部线路"]);
    expect(fact("已尝试恢复轮数")).toBe("2");
  });

  it("keeps the usual order otherwise", () => {
    mountPage({ status: healthy, accessPoints: lines });
    expect(titles()).toEqual(["当前线路", "全部线路", "恢复工具"]);
  });

  it("flags a disagreement about the access point and shows what the server reports", () => {
    mountPage({ status: { ...healthy, connectAck: { accessPointId: "ap-b", accessPointMismatch: true } }, accessPoints: lines });
    expect(page().attributes("data-flare-access-state")).toBe("warning");
    expect(banners()).toEqual(["服务端报告的接入点与当前线路不一致，连接不受影响"]);
    expect(fact("服务端报告的接入点")).toBe("ap-b");
  });

  it("offers a pin only on a line that can carry one, and only while the host listens", async () => {
    const pin = vi.fn();
    mountPage({ status: healthy, accessPoints: lines, onPin: pin });
    expect(row("ap-sg-2").find("button").exists()).toBe(false);
    expect(row("ap-de-1").find("button").exists()).toBe(false);
    const offered = row("ap-sg-1").find("button");
    expect(offered.attributes("aria-label")).toBe("固定 ap-sg-1");
    await offered.trigger("click");
    expect(pin).toHaveBeenCalledWith("ap-sg-1");
    host!.unmount();
    mountPage({ status: healthy, accessPoints: lines });
    expect(row("ap-sg-1").find("button").exists()).toBe(false);
  });

  it("lets go of a pinned line", async () => {
    const unpin = vi.fn();
    mountPage({ status: healthy, accessPoints: [{ ...lines[0], pinned: true }], onUnpin: unpin });
    expect(row("ap-sg-1").text()).toContain("已固定");
    await row("ap-sg-1").find("button").trigger("click");
    expect(unpin).toHaveBeenCalledTimes(1);
  });

  it("draws the recovery actions only while the host listens", () => {
    mountPage({ status: healthy, accessPoints: lines });
    expect(button("立即刷新")).toBeUndefined();
    expect(button("复制诊断")).toBeUndefined();
    expect(button("导入")).toBeUndefined();
  });

  it("refreshes through the host and says how it went", async () => {
    const refresh = vi.fn();
    const current = mountPage({ status: healthy, accessPoints: lines, onRefresh: refresh });
    await button("立即刷新")!.trigger("click");
    expect(refresh).toHaveBeenCalledTimes(1);
    current.value = { ...current.value, refreshing: true };
    await nextTick();
    expect(button("立即刷新")!.attributes("aria-busy")).toBe("true");
    current.value = { ...current.value, refreshing: false, refreshOutcome: "upToDate" };
    await nextTick();
    expect(banners()).toContain("线路已是最新");
    expect(spoken()).toBe("线路已是最新");
  });

  it("asks the host to copy the diagnostics and says how it went", async () => {
    const exportDiagnostics = vi.fn();
    const current = mountPage({ status: healthy, accessPoints: lines, onExportDiagnostics: exportDiagnostics });
    await button("复制诊断")!.trigger("click");
    expect(exportDiagnostics).toHaveBeenCalledTimes(1);
    current.value = { ...current.value, exportOutcome: "copied" };
    await nextTick();
    expect(banners()).toContain("诊断信息已复制");
  });

  it("imports the pasted link as trimmed, and clears it once adopted", async () => {
    const importRecovery = vi.fn();
    const current = mountPage({ status: healthy, accessPoints: lines, onImportRecovery: importRecovery });
    expect(button("导入")!.attributes("disabled")).toBeDefined();
    const field = host!.find("input");
    await field.setValue("  flare-recover://v1?p=a&k=b&s=c \n");
    await button("导入")!.trigger("click");
    expect(importRecovery).toHaveBeenCalledWith("flare-recover://v1?p=a&k=b&s=c");
    current.value = { ...current.value, importOutcome: "rejected", importCode: "rollback" };
    await nextTick();
    expect(banners()).toContain("这条链接比本机线路旧，不需要导入");
    expect((field.element as HTMLInputElement).value).not.toBe("");
    current.value = { ...current.value, importOutcome: "adopted", importCode: null };
    await nextTick();
    await nextTick();
    expect(banners()).toContain("恢复链接已导入，正在切换线路");
    expect((field.element as HTMLInputElement).value).toBe("");
  });

  it("brings the answer to a link into view", async () => {
    const shown = vi.fn();
    const original = Element.prototype.scrollIntoView;
    Element.prototype.scrollIntoView = shown;
    try {
      const current = mountPage({ status: healthy, accessPoints: lines, onImportRecovery: vi.fn() });
      await nextTick();
      expect(shown).not.toHaveBeenCalled();

      current.value = { ...current.value, importing: true };
      await nextTick();
      current.value = { ...current.value, importing: false, importOutcome: "rejected", importCode: "badSignature" };
      await flushPromises();

      expect(shown).toHaveBeenCalledTimes(1);
      expect(shown).toHaveBeenCalledWith({ block: "nearest" });
    } finally {
      Element.prototype.scrollIntoView = original;
    }
  });

  it("names its field and its sections", () => {
    mountPage({ status: healthy, accessPoints: lines, onImportRecovery: vi.fn() });
    const label = host!.find("label.flare-access-diagnostics__label");
    expect(host!.find("input").attributes("id")).toBe(label.attributes("for"));
    const section = host!.find(".flare-access-diagnostics__section");
    expect(section.find("h3").attributes("id")).toBe(section.attributes("aria-labelledby"));
  });
});
