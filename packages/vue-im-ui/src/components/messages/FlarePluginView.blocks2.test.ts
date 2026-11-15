// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { setFlareServerClockOffset } from "../../shared/server-clock";
import type { FlarePluginBlock, FlarePluginViewModel } from "../../shared/contracts/plugin-ui";
import FlarePluginView from "./FlarePluginView.vue";
import FlarePluginPage from "./FlarePluginPage.vue";
import FlarePluginUpgradeNotice from "./FlarePluginUpgradeNotice.vue";

enableAutoUnmount(afterEach);
afterEach(() => {
  vi.useRealTimers();
  setFlareServerClockOffset(null);
  document.body.innerHTML = "";
});

const op = (id: string, label: string) => ({ id, label });
function view(blocks: unknown[], extra: Partial<FlarePluginViewModel> = {}): FlarePluginViewModel {
  return { available: true, title: "Dashboard", fields: [], actions: [], blocks: blocks as FlarePluginBlock[], ...extra };
}
function render(model: FlarePluginViewModel, props: Record<string, unknown> = {}, locale = "zh-CN") {
  const root = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider(locale);
        return () => h(FlarePluginView, { view: model, ...props });
      },
    }),
    { attachTo: document.body },
  );
  return root.getComponent(FlarePluginView);
}

describe("PluginView vocabulary 2 blocks", () => {
  it("draws every new block kind", () => {
    const w = render(
      view([
        { kind: "stats", items: [{ label: "Open", value: "12", trend: { text: "+3", direction: "up" } }, { label: "Done", value: "28" }] },
        { kind: "chart", chartKind: "bar", series: [{ points: [{ label: "Mon", value: 3, text: "3" }] }] },
        { kind: "image", asset: "assets/cover.png", aspect: "16:9", alt: "Cover" },
        { kind: "qr", value: "flare://pay/1", valuePath: "/code" },
        { kind: "hero", value: "¥128.60", amount: true, tone: "brand" },
        { kind: "steps", items: [{ label: "Submit", state: "done" }, { label: "Review", state: "current" }] },
        { kind: "banner", tone: "warning", text: "Verify first" },
        { kind: "timeline", items: [{ atMs: 1_700_000_000_000, title: "Paid" }] },
        { kind: "section", label: "More", collapsed: false, blocks: [{ kind: "text", text: "Inside", style: "body" }] },
      ]),
    );
    for (const kind of ["stats", "chart", "image", "qr", "hero", "steps", "banner", "timeline", "section", "text"])
      expect(w.find(`[data-block="${kind}"]`).exists(), kind).toBe(true);
    expect(w.findAll("[data-step-state]").map((s) => s.attributes("data-step-state"))).toEqual(["done", "current"]);
  });

  it("folds a section's children and skips unknown kinds inside it", async () => {
    const w = render(
      view([
        { kind: "section", label: "Details", collapsed: true, blocks: [{ kind: "text", text: "Hidden", style: "body" }, { kind: "sparkline", points: [] }] },
      ]),
    );
    expect(w.find('[data-block="text"]').exists()).toBe(false);
    await w.get("[data-section-toggle]").trigger("click");
    expect(w.get('[data-block="text"]').text()).toBe("Hidden");
    expect(w.findAll("[data-block]").map((b) => b.attributes("data-block"))).toEqual(["section", "text"]);
  });

  it("never folds a section without a label", () => {
    const w = render(view([{ kind: "section", collapsed: true, blocks: [{ kind: "text", text: "Shown", style: "body" }] }]));
    expect(w.find("[data-section-toggle]").exists()).toBe(false);
    expect(w.get('[data-block="text"]').text()).toBe("Shown");
  });

  it("writes a count and a duration in the viewer's language", () => {
    const blocks = [
      { kind: "stats", items: [
        { label: "Members", value: "12345", format: { kind: "count", count: 12345 } },
        { label: "Time", value: "7500000 ms", format: { kind: "duration", ms: 7_500_000 } },
      ] },
    ];
    const zh = render(view(blocks));
    expect(zh.findAll(".flare-metric-tile__number").map((n) => n.text())).toEqual(["1.2万", "2 小时 5 分钟"]);
    const en = render(view(blocks), {}, "en-US");
    expect(en.findAll(".flare-metric-tile__number").map((n) => n.text())).toEqual(["12.3K", "2 h 5 min"]);
  });

  it("runs the actions hero and banner own through the view's pipeline", async () => {
    const w = render(
      view([
        { kind: "hero", value: "¥1", amount: true, tone: "neutral", actions: [op("recharge", "Recharge")] },
        { kind: "banner", tone: "info", text: "Verify", action: op("verify", "Verify now") },
      ]),
      { onAction: () => undefined },
    );
    await w.get('[data-action-id="recharge"]').trigger("click");
    await w.get(".flare-plugin-banner").findAll("button").find((b) => b.text() === "Verify now")!.trigger("click");
    expect(w.emitted("action")).toEqual([["recharge", {}], ["verify", {}]]);
  });

  it("offers to refresh an expired QR code only when the host listens", async () => {
    vi.useFakeTimers();
    vi.setSystemTime(10_000);
    const block = { kind: "qr", value: "code", valuePath: "/code", refreshOperation: "code.refresh", expiresAtPath: "/expiresAt", expiresAtMs: 5_000 };
    const silent = render(view([block]));
    expect(silent.find("[data-qr-expired]").exists()).toBe(true);
    expect(silent.find("[data-qr-refresh]").exists()).toBe(false);
    const listening = render(view([block]), { onQrRefresh: () => undefined });
    await listening.get("[data-qr-refresh]").trigger("click");
    expect(listening.emitted("qrRefresh")).toEqual([[{ operation: "code.refresh", valuePath: "/code", expiresAtPath: "/expiresAt" }]]);
  });

  it("draws only addresses the host fetched for an image", async () => {
    const w = render(view([{ kind: "image", fileId: "f_1", aspect: "1:1", alt: "ID" }]), {
      resolveImage: (source: { fileId?: string }) => Promise.resolve(source.fileId === "f_1" ? "javascript:alert(1)" : undefined),
    });
    await flushPromises();
    expect(w.find("img").exists()).toBe(false);
    const ok = render(view([{ kind: "image", asset: "a.png", aspect: "4:3", alt: "Cover" }]), { resolveImage: () => "https://cdn.example/a.png" });
    await nextTick();
    expect(ok.get("img").attributes("src")).toBe("https://cdn.example/a.png");
    expect(ok.get("img").attributes("alt")).toBe("Cover");
  });

  it("draws a donut's empty text when nothing is positive", () => {
    const w = render(view([{ kind: "chart", chartKind: "donut", series: [], emptyText: "Nothing yet" }]));
    expect(w.get("[data-chart-empty]").text()).toBe("Nothing yet");
  });
});

describe("PluginView and PluginPage upgrade notice", () => {
  const placeholder: FlarePluginViewModel = { available: false, unavailableReason: "upgrade_required", minBuild: 41020, title: "Task board", fields: [], actions: [] };

  it("puts the update key in the card when a build is offered", async () => {
    const onUpdate = vi.fn();
    const w = render(placeholder, { upgradeStatus: { available: true, build: 41020 }, onUpdate });
    expect(w.get('[data-upgrade-notice="card"]').attributes("data-upgrade-mode")).toBe("update");
    expect(w.find("[data-unavailable-reason]").exists()).toBe(false);
    await w.get("[data-upgrade-action]").trigger("click");
    expect(onUpdate).toHaveBeenCalledTimes(1);
  });

  it("shows only the copy when no build is offered", () => {
    const w = render(placeholder, { upgradeStatus: { available: false }, onUpdate: () => undefined });
    expect(w.get('[data-upgrade-notice="card"]').text()).toBe("当前版本暂不支持，新版本发布后可用");
    expect(w.find("[data-upgrade-action]").exists()).toBe(false);
  });

  it("draws the whole page for an upgrade_required page", () => {
    const root = mount(
      defineComponent({
        setup() {
          useFlareI18nProvider("zh-CN");
          return () => h(FlarePluginPage, { page: { pluginId: "p", page: "board" }, view: placeholder, upgradeStatus: { available: true }, onUpdate: () => undefined });
        },
      }),
    );
    const notice = root.get('[data-upgrade-notice="page"]');
    expect(notice.attributes("data-upgrade-mode")).toBe("update");
    expect(notice.text()).toContain("Task board");
    expect(root.find("[data-page-unavailable]").exists()).toBe(false);
  });

  it("marks an entry", () => {
    const root = mount(defineComponent({ setup() { useFlareI18nProvider("en-US"); return () => h(FlarePluginUpgradeNotice, { variant: "entry" }); } }));
    expect(root.get('[data-upgrade-notice="entry"]').text()).toBe("Update needed");
  });
});
