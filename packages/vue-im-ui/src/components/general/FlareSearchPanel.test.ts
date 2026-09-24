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
    // 一排:类型胶囊。时间范围是**筛选的筛选**,收进行尾那颗胶囊的菜单里 ——
    // 它原来也铺成一整排,两排在手机上吃掉近百像素,结果要往下翻才看得到。
    const tablists = host.findAll('[role="tablist"]');
    expect(tablists.map((list) => list.attributes("aria-label"))).toEqual(["类型"]);
    const rangeChip = host.get(".flare-search-panel__range");
    expect(rangeChip.text()).toBe("时间范围");
    expect(rangeChip.classes()).not.toContain("is-narrowed");
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

    // 时间范围从行尾胶囊的菜单里选。
    await host.get(".flare-search-panel__range").trigger("click");
    await nextTick();
    const weekItem = [...document.body.querySelectorAll('[role="menuitem"], button')]
      .find((node) => node.textContent?.trim() === "最近七天");
    (weekItem as HTMLElement).click();
    await nextTick();
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
  // 全局搜索(联系人 / 群聊 / 聊天记录):只选类型不算查询 —— 「全部联系人」是通讯录的事。
  // 会话内搜索不传 requireQuery,「空词 + 图片」照旧是一次搜索(上面的用例守着)。
  it("with requireQuery a type alone rests idle, and narrows the next typed query", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const { host, searches } = mountPanel(state, { requireQuery: true, timeRanges: [] });
    await host.findAll('[role="tab"]')[1].trigger("click");
    await nextTick();
    expect(searches).toEqual([]);
    expect(host.find('[role="status"]').exists()).toBe(true);
    await host.get("input[type=search]").setValue("周");
    vi.advanceTimersByTime(300);
    expect(searches).toEqual([{ query: "周", filterId: "image" }]);
  });

  // 空闲态插槽拿到 search(term):点一条最近搜索 = 立即搜这个词,不等 300ms,输入框同步成这个词。
  it("hands the idle slot a search(term) that searches at once", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const searches: unknown[] = [];
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareSearchPanel as Component, { snapshot: state.snapshot, filters, layout: "page", onSearch: (c: unknown) => searches.push(c) }, {
          idle: ({ search }: { search: (term: string) => void }) => h("button", { class: "recent", onClick: () => search("发版") }, "发版"),
        });
      },
    }), { attachTo: document.body });
    expect(host.get(".flare-search-panel").classes()).toContain("flare-search-panel--page");
    expect(host.find('[role="status"]').exists()).toBe(false);
    await host.get(".recent").trigger("click");
    expect(searches).toEqual([{ query: "发版", filterId: "all" }]);
    expect((host.get("input[type=search]").element as HTMLInputElement).value).toBe("发版");
    // 被点的那一行随空闲态一起消失:焦点先落进输入框,不会掉到 <body>(页面的 Esc 就听不到了)。
    expect(document.activeElement).toBe(host.get("input[type=search]").element);
    // 这次搜索很快失败了:停顿结束时不能替用户悄悄重试一遍(词没变,没有新东西可搜)。
    state.snapshot = { criteria: { query: "发版", filterId: "all" }, state: "failure", groups: [], error: "连接中断" };
    await nextTick();
    vi.advanceTimersByTime(1000);
    expect(searches).toHaveLength(1);
    host.unmount();
  });

  // 「离开搜索」在 kit 里已经有主人:搜索框在宿主监听 cancel 时自带取消键。面板只在自己的宿主监听时
  // 才把监听传下去 —— 带返回键的页面里(会话内搜索)不会凭空多出第二个出口。
  it("offers the bar's own way out only to a host that listens for cancel", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    const plain = mountPanel(state);
    expect(plain.host.find(".flare-search__cancel").exists()).toBe(false);
    plain.host.unmount();
    let cancelled = 0;
    const { host } = mountPanel(state, { onCancel: () => { cancelled += 1; } });
    const key = host.get(".flare-search__cancel");
    expect(key.text()).toBe("取消");
    await key.trigger("click");
    expect(cancelled).toBe(1);
    host.unmount();
  });

  // 取消之后不能再冒出一次 search:面板自己那个 300ms 的待发搜索要一起丢掉;宿主随之复位到空闲时,
  // 打了还没提交的字、(requireQuery 下)只选了没搜的类型也一起清掉。
  it("drops its pending search on cancel, and a host reset clears words that were never submitted", async () => {
    const state = reactive({ snapshot: { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] } as FlareSearchSnapshot });
    // 宿主只是关页、不复位快照:待发的那次搜索也必须丢掉(复位路径会顺带清定时器,所以要单独量这一条)。
    const closing = mountPanel(state, { onCancel: () => undefined });
    await closing.host.get("input[type=search]").setValue("周");
    vi.advanceTimersByTime(100);
    await closing.host.get(".flare-search__cancel").trigger("click");
    vi.advanceTimersByTime(1000);
    expect(closing.searches).toEqual([]);
    closing.host.unmount();

    const { host, searches } = mountPanel(state, {
      requireQuery: true,
      onCancel: () => { state.snapshot = { criteria: { query: "", filterId: "all" }, state: "idle", groups: [] }; },
    });
    await host.findAll('[role="tab"]')[1].trigger("click");
    await host.get("input[type=search]").setValue("周");
    vi.advanceTimersByTime(100);
    await host.get(".flare-search__cancel").trigger("click");
    await nextTick();
    vi.advanceTimersByTime(1000);
    expect(searches).toEqual([]);
    expect((host.get("input[type=search]").element as HTMLInputElement).value).toBe("");
    expect(host.findAll('[role="tab"]')[0].attributes("aria-selected")).toBe("true");
    host.unmount();
  });

  // 「查看更多 联系人」与点「联系人」类型是同一个动作:类型是面板自己的状态,宿主改不了,所以面板自己切,
  // 同时照旧把 viewAll 报给宿主。部分来源失败时结果留着,上面一条带重试的提醒。
  it("see-more switches to the type named like the result kind, and a warning sits above kept results", async () => {
    const kinds = { all: "全部", contact: "联系人", message: "聊天记录" };
    const criteria = { query: "周", filterId: "all" };
    const state = reactive({ snapshot: {
      criteria, state: "success", warning: "部分结果没有加载出来",
      groups: [{ kind: "contact", label: "联系人", hasMore: true, items: [{ id: "u1", kind: "contact", title: "周屿" }] }],
    } as FlareSearchSnapshot });
    const searches: unknown[] = [];
    const viewed: unknown[] = [];
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareSearchPanel as Component, { snapshot: state.snapshot, filters: kinds, onSearch: (c: unknown) => searches.push(c), onViewAll: (k: unknown) => viewed.push(k) });
      },
    }), { attachTo: document.body });
    await nextTick();
    expect(host.get(".flare-search-panel__banner").text()).toContain("部分结果没有加载出来");
    // (搜索框自己的外层也叫 .flare-search-row,结果行要限定在结果区里数。)
    expect(host.findAll(".flare-search-results .flare-search-row")).toHaveLength(1);
    await host.get(".flare-search-more").trigger("click");
    expect(viewed).toEqual(["contact"]);
    expect(searches).toEqual([{ query: "周", filterId: "contact" }]);
    expect(host.findAll('[role="tab"]')[1].attributes("aria-selected")).toBe("true");
    host.unmount();
  });
});
