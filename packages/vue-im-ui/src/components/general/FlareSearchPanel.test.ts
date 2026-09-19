// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareSearchSnapshot } from "../../shared/contracts/search-panel";
import FlareSearchPanel from "./FlareSearchPanel.vue";

const filters = { all: "全部", image: "图片", file: "文件" };
const ranges = [
  { id: "any", label: "不限时间" },
  { id: "week", label: "最近七天", fromTime: 1_000, toTime: 2_000 },
  { id: "broken", label: "无效", fromTime: 5, toTime: 1 },
];

function mountPanel(state: { snapshot: FlareSearchSnapshot }, extra: Record<string, unknown> = {}) {
  const searches: unknown[] = [];
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareSearchPanel as Component, {
        snapshot: state.snapshot, filters, timeRanges: ranges,
        onSearch: (criteria: unknown) => searches.push(criteria),
        ...extra,
      });
    },
  }), { attachTo: document.body });
  return { host, searches };
}

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

describe("FlareSearchPanel", () => {
  it("is composed from the search bar and filter tabs, and rests idle with nothing chosen", () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const { host, searches } = mountPanel(state);
    expect(host.find(".flare-search input[type=search]").attributes("placeholder")).toBe("搜索");
    const tablists = host.findAll('[role="tablist"]');
    expect(tablists.map((list) => list.attributes("aria-label"))).toEqual(["类型", "时间范围"]);
    expect(tablists[1].findAll('[role="tab"]').map((tab) => tab.text())).toEqual(["不限时间", "最近七天"]);
    expect(host.text()).toContain("输入关键词或选择类型");
    expect(searches).toEqual([]);
    host.unmount();
  });

  it("searches after a pause in typing, not per keystroke and not while an IME composes", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const { host, searches } = mountPanel(state);
    const input = host.get("input[type=search]");
    await input.setValue("发");
    await input.setValue("发版");
    vi.advanceTimersByTime(299);
    expect(searches).toEqual([]);
    vi.advanceTimersByTime(1);
    expect(searches).toEqual([{ query: "发版", filterId: "all" }]);

    await host.get(".flare-search-panel").trigger("compositionstart");
    await input.setValue("发版 q");
    vi.advanceTimersByTime(1_000);
    expect(searches).toHaveLength(1);
    await host.get(".flare-search-panel").trigger("compositionend");
    await nextTick();
    vi.advanceTimersByTime(300);
    expect(searches).toEqual([{ query: "发版", filterId: "all" }, { query: "发版 q", filterId: "all" }]);
    host.unmount();
  });

  it("searches at once for a type or a time range, and keeps results on screen while the next query runs", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const { host, searches } = mountPanel(state);
    await host.findAll('[role="tab"]')[2].trigger("click");
    expect(searches).toEqual([{ query: "", filterId: "file" }]);
    state.snapshot = { criteria: { query: "", filterId: "file" }, state: "success", groups: [{ kind: "message", label: "文件", items: [{ id: "m1", kind: "message", title: "清单.pdf" }] }] };
    await nextTick();
    expect(host.text()).toContain("清单.pdf");

    await host.findAll('[role="tab"]')[4].trigger("click");
    expect(searches[1]).toEqual({ query: "", filterId: "file", fromTime: 1_000, toTime: 2_000 });
    await nextTick();
    expect(host.text()).toContain("清单.pdf");
    expect(host.get(".flare-search-panel__results").attributes("aria-busy")).toBe("true");
    host.unmount();
  });

  it("offers a retry after a failure and resets when the host resets its search", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const { host, searches } = mountPanel(state);
    await host.get("input[type=search]").setValue("发版");
    vi.advanceTimersByTime(300);
    state.snapshot = { criteria: { query: "发版", filterId: "all" }, state: "failure", groups: [], error: "连接中断" };
    await nextTick();
    await host.get(".flare-status-banner button").trigger("click");
    expect(searches).toEqual([{ query: "发版", filterId: "all" }, { query: "发版", filterId: "all" }]);

    state.snapshot = { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] };
    await nextTick();
    expect((host.get("input[type=search]").element as HTMLInputElement).value).toBe("");
    expect(host.text()).toContain("输入关键词或选择类型");
    host.unmount();
  });

  it("puts the caret in the search field when asked to", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const { host } = mountPanel(state, { autofocus: true });
    await nextTick();
    expect(document.activeElement).toBe(host.get("input[type=search]").element);
    host.unmount();
  });
});
