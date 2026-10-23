// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount, type VueWrapper } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { flareMessages } from "../../shared/i18n/messages";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import {
  flarePluginRowLines,
  type FlarePluginPageActionPayload,
  type FlarePluginPageRef,
  type FlarePluginPageViewModel,
  type FlarePluginRowsBlock,
  type FlarePluginUser,
} from "../../shared/contracts/plugin-ui";
import FlarePluginPage from "./FlarePluginPage.vue";
import FlarePluginView from "./FlarePluginView.vue";

enableAutoUnmount(afterEach);
afterEach(() => {
  vi.useRealTimers();
  document.body.innerHTML = "";
});

type ItemFact = { key: string; badge: { text: string; tone: string } | null; primary: string; secondary: string | null; actions: Array<{ id: string; label: string; variant: string }> };
type BlockFact = Record<string, unknown> & { kind: string };
type PageCase = {
  id: string;
  platforms: string[];
  title: string;
  page: FlarePluginPageRef;
  filters: Record<string, unknown>;
  view: FlarePluginPageViewModel;
  expect: {
    heading: string;
    state: string;
    fields: Array<{ label: string; value: string }>;
    blocks: BlockFact[];
    actions: Array<{ id: string; label: string; variant: string }>;
    filters: Array<{ input: string; label: string; tabs: string[]; selected: string }>;
    loadMore: boolean;
    refresh: boolean;
    empty: string | null;
    retry: boolean;
  };
};
type Tap = { action: string; row?: string } | "loadMore";
type Emit = { actionId: string; payload: FlarePluginPageActionPayload } | null;
type ActionStep = {
  tap?: Tap; confirm?: string | true; cancel?: boolean; form?: string[]; fill?: Record<string, string>; submit?: boolean; emit?: Emit;
  host?: { busyActionId?: string | null }; spinningRows?: string[]; rowKeysEnabled?: boolean;
};
type PagingStep = {
  tap?: Tap;
  emit?: string | Emit | null;
  host?: { view?: FlarePluginPageViewModel; actionError?: string; refreshing?: boolean; loadingMore?: boolean };
  spinning?: boolean;
  enabled?: boolean;
  rowKeys?: string[];
  primaries?: string[];
  loadMore?: boolean;
};
type FilterStep = {
  tabs?: Record<string, string[]>;
  selected?: Record<string, string>;
  choose?: { input: string; tab: string };
  emit?: Record<string, unknown> | null;
  host?: { filters?: Record<string, unknown>; refreshing?: boolean; loadingMore?: boolean };
  enabled?: boolean;
};
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as {
  nowMs: number;
  utcOffsetMinutes: number;
  users: Record<string, FlarePluginUser>;
  pageViews: PageCase[];
  pageActions: Array<{ name: string; platforms: string[]; view: string; steps: ActionStep[] }>;
  pagePaging: Array<{ name: string; platforms: string[]; view: string; steps: PagingStep[] }>;
  pageFilters: Array<{ name: string; platforms: string[]; view: string; filters: Record<string, unknown>; steps: FilterStep[] }>;
};
const vue = <T extends { platforms: string[] }>(cases: T[]) => cases.filter((c) => c.platforms.includes("vue"));
const caseOf = (id: string) => vectors.pageViews.find((c) => c.id === id)!;
const zh = (flareMessages["zh-CN"] as unknown as { pluginView: { dateTime: string; dateTimeYear: string } }).pluginView;

const walletPage: FlarePluginPageRef = { pluginId: "flare.redpacket", page: "flare.redpacket.wallet" };
// A wallet page as the red packet plugin declares it: fields, a recent list, an action and a next page.
const wallet: FlarePluginPageViewModel = {
  available: true,
  title: "钱包",
  fields: [],
  actions: [{ id: "history", label: "全部明细" }],
  blocks: [
    { kind: "fields", fields: [{ label: "可用余额", value: "¥12.30" }, { label: "红包托管中", value: "¥3.00" }] },
    { kind: "entries", items: [{ index: 1, text: "-¥3.00", userId: "u_alice01" }], numbered: false, total: 1, more: false },
  ],
  nextCursor: "page-2",
  data: { balanceText: "¥12.30" },
};

function render(props: Record<string, unknown>, { pointer = "fine" as "fine" | "coarse", refresh = true } = {}) {
  const state = reactive<Record<string, unknown>>({ title: "钱包", page: walletPage, back: true, resolveUser: (id: string) => vectors.users[id], ...props });
  const events: Array<[string, ...unknown[]]> = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { pointer } });
      return () => h(FlarePluginPage as never, {
        ...state,
        onBack: () => events.push(["back"]),
        ...(refresh ? { onRefresh: () => events.push(["refresh"]) } : {}),
        onRetry: () => events.push(["retry"]),
        onLoadMore: (cursor: string) => events.push(["loadMore", cursor]),
        onFilter: (values: Record<string, unknown>) => events.push(["filter", values]),
        onAction: (id: string, payload: FlarePluginPageActionPayload) => events.push(["action", id, payload]),
      });
    },
  }), { attachTo: document.body });
  return { wrapper, state, events };
}
function renderCase(c: PageCase, extra: Record<string, unknown> = {}) {
  return render({ title: c.title, page: c.page, filters: c.filters, view: c.view, ...extra });
}

function touch(el: Element, type: string, y: number) {
  const event = new Event(type, { bubbles: true, cancelable: true }) as Event & { touches: Array<{ clientY: number }> };
  Object.defineProperty(event, "touches", { value: type === "touchend" ? [] : [{ clientY: y }] });
  el.dispatchEvent(event);
}
const variantOf = (el: Element) => [...el.classList].find((c) => /^flare-button--(primary|secondary|danger|ghost|quiet|text)$/.test(c))?.slice("flare-button--".length);
const bodyButton = (label: string) => [...document.body.querySelectorAll("button")].find((b) => b.textContent?.trim() === label) as HTMLButtonElement | undefined;
const lastAction = (events: Array<[string, ...unknown[]]>) => events.filter((e) => e[0] === "action").at(-1);
const actionCount = (events: Array<[string, ...unknown[]]>) => events.filter((e) => e[0] === "action").length;

async function tap(wrapper: VueWrapper, target: Tap): Promise<void> {
  if (target === "loadMore") await wrapper.get("[data-page-load-more]").trigger("click");
  else if (target.row) await wrapper.get(`[data-row-key="${target.row}"] [data-row-action="${target.action}"]`).trigger("click");
  else await wrapper.get(`[data-action-id="${target.action}"]`).trigger("click");
  await flushPromises();
}

function expectRows(node: ReturnType<VueWrapper["find"]>, fact: BlockFact, block: FlarePluginRowsBlock): void {
  const items = fact.items as ItemFact[];
  const nodes = node.findAll("[data-row-key]");
  expect(nodes.map((n) => n.attributes("data-row-key"))).toEqual(items.map((i) => i.key));
  items.forEach((item, i) => {
    const el = nodes[i];
    const badge = el.find("[data-row-badge]");
    expect(badge.exists() ? { text: badge.text(), tone: badge.attributes("data-tone") } : null, `${item.key} badge`).toEqual(item.badge);
    // The badge leads the first line.
    if (item.badge) expect(el.get(".flare-plugin-rows__primary").element.firstElementChild?.hasAttribute("data-row-badge")).toBe(true);
    expect(el.get("[data-row-primary]").text()).toBe(item.primary);
    // Time cells: the pure rule holds at the vectors' offset; the page draws the device zone.
    const row = block.rows.find((r) => r.key === item.key)!;
    expect(flarePluginRowLines(block, row, vectors.nowMs, zh, vectors.utcOffsetMinutes).secondary, `${item.key} secondary`).toBe(item.secondary);
    const device = flarePluginRowLines(block, row, vectors.nowMs, zh).secondary;
    const secondary = el.find("[data-row-secondary]");
    expect(secondary.exists() ? secondary.text() : null).toBe(device);
    const keys = el.findAll("[data-row-action]");
    expect(keys.map((k) => ({ id: k.attributes("data-row-action"), label: k.text(), variant: variantOf(k.element) }))).toEqual(item.actions);
  });
  const empty = node.find("[data-rows-empty]");
  expect(empty.exists() ? empty.text() : null).toBe(fact.empty);
  // The table form and the rows block's own load more never show on a page.
  expect(node.find("table").exists()).toBe(false);
  expect(node.find("[data-rows-load-more]").exists()).toBe(false);
}

describe("FlarePluginPage (spec/plugin-view-vectors.json pageViews)", () => {
  it.each(vue(vectors.pageViews).map((c) => [c.id, c] as const))("renders %s", async (_, c) => {
    vi.useFakeTimers({ now: vectors.nowMs });
    const { wrapper } = renderCase(c);
    await flushPromises();
    const facts = c.expect;
    expect(wrapper.get("h1").text()).toBe(facts.heading);
    expect(wrapper.get(".flare-plugin-page").attributes("data-state")).toBe(facts.state);
    expect(wrapper.findAll("dl.flare-plugin-view__fields dt").map((n) => n.text())).toEqual(facts.fields.map((f) => f.label));
    expect(wrapper.findAll("dl.flare-plugin-view__fields dd").map((n) => n.text())).toEqual(facts.fields.map((f) => f.value));
    const nodes = wrapper.findAll("[data-block]");
    expect(nodes.map((n) => n.attributes("data-block"))).toEqual(facts.blocks.map((b) => b.kind));
    facts.blocks.forEach((fact, i) => {
      if (fact.kind === "rows") {
        expect(fact.layout).toBe("list");
        expectRows(nodes[i] as never, fact, c.view.blocks![i] as FlarePluginRowsBlock);
      } else if (fact.kind === "note") {
        expect(nodes[i].text()).toBe(fact.text);
        expect(nodes[i].attributes("data-note-tone")).toBe(fact.tone);
      }
    });
    const keys = wrapper.findAll("[data-action-id]");
    expect(keys.map((k) => ({ id: k.attributes("data-action-id"), label: k.text(), variant: variantOf(k.element) }))).toEqual(
      facts.actions.map((a) => ({ id: a.id, label: a.label, variant: a.variant })),
    );
    const filters = wrapper.findAll("[data-page-filter]");
    expect(filters.map((f) => ({
      input: f.attributes("data-page-filter"),
      label: f.attributes("aria-label"),
      tabs: f.findAll("[role=tab]").map((t) => t.text()),
      selected: f.findAll("[role=tab]").find((t) => t.attributes("aria-selected") === "true")?.text(),
    }))).toEqual(facts.filters);
    expect(wrapper.find("[data-page-load-more]").exists()).toBe(facts.loadMore);
    expect(wrapper.find("[data-page-refresh]").exists()).toBe(facts.refresh);
    const empty = wrapper.find("[data-page-unavailable]");
    expect(empty.exists() ? empty.get(".flare-empty__title").text() : null).toBe(facts.empty);
    expect(wrapper.find("[data-page-retry]").exists()).toBe(facts.retry);
  });

  it("retries an unreachable catalog from the empty state", async () => {
    const { wrapper, events } = renderCase(caseOf("unavailable-catalog-unreachable"));
    await flushPromises();
    await wrapper.get("[data-page-retry]").trigger("click");
    expect(events).toEqual([["retry"]]);
    // No pull to refresh on an unavailable page either.
    const touchPage = renderCase(caseOf("unavailable-disabled"), {});
    await flushPromises();
    const scroller = touchPage.wrapper.get(".flare-plugin-page__scroll").element;
    touch(scroller, "touchstart", 100);
    touch(scroller, "touchmove", 260);
    touch(scroller, "touchend", 260);
    expect(touchPage.events).toEqual([]);
  });
});

describe("FlarePluginPage actions (pageActions)", () => {
  it.each(vue(vectors.pageActions).map((c) => [c.name, c] as const))("%s", async (_, scenario) => {
    const { wrapper, state, events } = renderCase(caseOf(scenario.view));
    await flushPromises();
    for (const step of scenario.steps) {
      const before = actionCount(events);
      if (step.tap) await tap(wrapper, step.tap);
      if (step.host && "busyActionId" in step.host) {
        state.busyActionId = step.host.busyActionId ?? undefined;
        await flushPromises();
      }
      if (step.spinningRows) {
        const spinning = wrapper.findAll("[data-row-key]").filter((n) => n.findAll("[data-row-action]").some((k) => k.classes().includes("is-loading")));
        expect(spinning.map((n) => n.attributes("data-row-key"))).toEqual(step.spinningRows);
      }
      if (step.rowKeysEnabled !== undefined) {
        const keys = wrapper.findAll("[data-row-action]");
        expect(keys.length).toBeGreaterThan(0);
        expect(keys.every((k) => (k.attributes("disabled") === undefined) === step.rowKeysEnabled)).toBe(true);
      }
      if (typeof step.confirm === "string") expect(document.body.querySelector(".flare-danger-confirm")?.textContent).toContain(step.confirm);
      if (step.confirm === true) {
        const confirm = [...document.body.querySelectorAll(".flare-danger-confirm__actions button")].at(-1) as HTMLButtonElement;
        confirm.click();
        await flushPromises();
      }
      if (step.cancel) {
        bodyButton("取消")!.click();
        await flushPromises();
      }
      if (step.form) {
        const form = document.body.querySelector(".flare-plugin-form");
        expect(form).not.toBeNull();
        for (const label of step.form) expect(form!.textContent).toContain(label);
      }
      if (step.fill) {
        for (const value of Object.values(step.fill)) {
          const input = document.body.querySelector(".flare-plugin-form input") as HTMLInputElement;
          input.value = value;
          input.dispatchEvent(new Event("input"));
        }
        await flushPromises();
      }
      if (step.submit) {
        (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
        await flushPromises();
      }
      if (step.emit === null) expect(actionCount(events)).toBe(before);
      else if (step.emit) expect(lastAction(events)).toEqual(["action", step.emit.actionId, step.emit.payload]);
    }
  });
});

describe("FlarePluginPage paging (pagePaging)", () => {
  it.each(vue(vectors.pagePaging).map((c) => [c.name, c] as const))("%s", async (_, scenario) => {
    const { wrapper, state, events } = renderCase(caseOf(scenario.view));
    await flushPromises();
    for (const step of scenario.steps) {
      const loads = events.filter((e) => e[0] === "loadMore").length;
      if (step.host?.view) state.view = step.host.view;
      if (step.host?.actionError) state.actionError = step.host.actionError;
      if (step.host?.refreshing !== undefined) state.refreshing = step.host.refreshing;
      if (step.host?.loadingMore !== undefined) state.loadingMore = step.host.loadingMore;
      if (step.host) await flushPromises();
      if (step.tap) await tap(wrapper, step.tap);
      if (step.tap === "loadMore") {
        const asked = events.filter((e) => e[0] === "loadMore");
        if (step.emit === null) expect(asked).toHaveLength(loads);
        else expect(asked.at(-1)).toEqual(["loadMore", step.emit]);
      } else if (step.emit && typeof step.emit === "object") {
        expect(lastAction(events)).toEqual(["action", step.emit.actionId, step.emit.payload]);
      }
      const key = wrapper.find("[data-page-load-more]");
      if (step.loadMore !== undefined) expect(key.exists()).toBe(step.loadMore);
      if (step.spinning !== undefined) expect(key.classes()).toContain(step.spinning ? "is-loading" : "flare-button");
      if (step.spinning === false) expect(key.classes()).not.toContain("is-loading");
      if (step.enabled !== undefined) expect(key.attributes("disabled") === undefined).toBe(step.enabled);
      if (step.rowKeys) expect(wrapper.findAll("[data-row-key]").map((n) => n.attributes("data-row-key"))).toEqual(step.rowKeys);
      if (step.primaries) expect(wrapper.findAll("[data-row-primary]").map((n) => n.text())).toEqual(step.primaries);
    }
  });
});

describe("FlarePluginPage filters (pageFilters)", () => {
  it.each(vue(vectors.pageFilters).map((c) => [c.name, c] as const))("%s", async (_, scenario) => {
    const { wrapper, state, events } = render({ ...((({ title, page, view }) => ({ title, page, view }))(caseOf(scenario.view))), filters: scenario.filters });
    await flushPromises();
    for (const step of scenario.steps) {
      const before = events.filter((e) => e[0] === "filter").length;
      if (step.host) {
        Object.assign(state, step.host);
        await flushPromises();
      }
      if (step.choose) {
        const tab = wrapper.get(`[data-page-filter="${step.choose.input}"]`).findAll("[role=tab]").find((t) => t.text() === step.choose!.tab)!;
        await tab.trigger("click");
        await flushPromises();
      }
      const rows = wrapper.findAll("[data-page-filter]");
      if (step.tabs) expect(Object.fromEntries(rows.map((r) => [r.attributes("data-page-filter"), r.findAll("[role=tab]").map((t) => t.text())]))).toEqual(step.tabs);
      if (step.selected) {
        for (const [input, label] of Object.entries(step.selected)) {
          const selected = wrapper.get(`[data-page-filter="${input}"]`).findAll("[role=tab]").filter((t) => t.attributes("aria-selected") === "true");
          expect(selected.map((t) => t.text())).toEqual([label]);
        }
      }
      if (step.emit === null) expect(events.filter((e) => e[0] === "filter")).toHaveLength(before);
      else if (step.emit) expect(events.filter((e) => e[0] === "filter").at(-1)).toEqual(["filter", step.emit]);
      if (step.enabled !== undefined) {
        const tabs = wrapper.get("[data-page-filters]").findAll("[role=tab]");
        expect(tabs.length).toBeGreaterThan(0);
        expect(tabs.map((t) => t.attributes("disabled") === undefined)).toEqual(tabs.map(() => step.enabled));
      }
    }
  });

  it("asks nothing while the tabs wait", async () => {
    const { wrapper, events } = renderCase(caseOf("wallet"), { refreshing: true });
    await flushPromises();
    const tab = wrapper.get('[data-page-filter="kind"]').findAll("[role=tab]")[2];
    await tab.trigger("click");
    expect(events.filter((e) => e[0] === "filter")).toEqual([]);
  });
});

describe("FlarePluginPage", () => {
  it("spins on the first load under the host's title, then draws the view with the shared renderer", async () => {
    const page = render({ loading: true });
    await flushPromises();
    expect(page.wrapper.get(".flare-plugin-page").attributes("data-state")).toBe("loading");
    expect(page.wrapper.text()).toContain("加载中");
    page.state.loading = false;
    page.state.view = wallet;
    await flushPromises();
    const view = page.wrapper.getComponent(FlarePluginView);
    expect(view.props("embedded")).toBe(true);
    expect(view.props("rowsLayout")).toBe("list");
    expect(page.wrapper.get("h1").text()).toBe("钱包");
    expect(page.wrapper.text()).toContain("¥12.30");
  });

  it("shows a failed first load with a retry key, and a failed refresh as a banner above the view", async () => {
    const page = render({ error: "加载失败" });
    await flushPromises();
    expect(page.wrapper.get("[role=alert]").text()).toBe("加载失败");
    await page.wrapper.get("[data-page-retry]").trigger("click");
    expect(page.events).toEqual([["retry"]]);
    page.state.view = wallet;
    await flushPromises();
    expect(page.wrapper.find("[data-page-retry]").exists()).toBe(false);
    expect(page.wrapper.text()).toContain("加载失败");
    expect(page.wrapper.text()).toContain("¥12.30");
  });

  it("loads the next page once per cursor", async () => {
    const page = render({ view: wallet });
    await flushPromises();
    await page.wrapper.get("[data-page-load-more]").trigger("click");
    await page.wrapper.get("[data-page-load-more]").trigger("click");
    expect(page.events).toEqual([["loadMore", "page-2"]]);
    page.state.view = { ...wallet, nextCursor: undefined };
    await flushPromises();
    expect(page.wrapper.find("[data-page-load-more]").exists()).toBe(false);
  });

  it("has a refresh key on pointer devices and only when the host refreshes", async () => {
    const page = render({ view: wallet });
    await flushPromises();
    await page.wrapper.get("[data-page-refresh]").trigger("click");
    expect(page.events).toEqual([["refresh"]]);
    const none = render({ view: wallet }, { refresh: false });
    await flushPromises();
    expect(none.wrapper.find("[data-page-refresh]").exists()).toBe(false);
    const touchPage = render({ view: wallet }, { pointer: "coarse" });
    await flushPromises();
    expect(touchPage.wrapper.find("[data-page-refresh]").exists()).toBe(false);
  });

  it("refreshes on a pull past the threshold, not on a short one", async () => {
    const page = render({ view: wallet }, { pointer: "coarse" });
    await flushPromises();
    const scroller = page.wrapper.get(".flare-plugin-page__scroll").element;
    touch(scroller, "touchstart", 100);
    touch(scroller, "touchmove", 140);
    await flushPromises();
    expect(page.wrapper.get("[data-page-pull]").text()).toBe("下拉刷新");
    touch(scroller, "touchend", 140);
    expect(page.events).toEqual([]);
    touch(scroller, "touchstart", 100);
    touch(scroller, "touchmove", 260);
    await flushPromises();
    expect(page.wrapper.get("[data-page-pull]").text()).toBe("松开刷新");
    touch(scroller, "touchend", 260);
    expect(page.events).toEqual([["refresh"]]);
    page.state.refreshing = true;
    await flushPromises();
    expect(page.wrapper.get("[data-page-pull]").text()).toBe("正在刷新");
  });

  it("sends the page's actions as page action requests and goes back", async () => {
    const page = render({ view: wallet });
    await flushPromises();
    await page.wrapper.get("[data-action-id=history]").trigger("click");
    await page.wrapper.get(".flare-screen__back").trigger("click");
    expect(page.events).toEqual([["action", "history", { page: walletPage, data: { balanceText: "¥12.30" } }], ["back"]]);
  });

  it("draws no back key unless asked", async () => {
    const page = render({ view: wallet, back: false });
    await flushPromises();
    expect(page.wrapper.find(".flare-screen__back").exists()).toBe(false);
  });
});
