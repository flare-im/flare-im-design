// @vitest-environment happy-dom
// docs/plugin-experience.md §2 as drawn: spec/plugin-view-vectors.json (actionRoles, statusValues, cardHeader,
// refreshKey, blockBoundInputs, pageStates, result, statusCard, selectOptions) and spec/plugin-refresh-vectors.json
// (afterAction) on mounted pages, views and forms. The pure rules are in shared/contracts/plugin-experience.test.ts.
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount, type VueWrapper } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import type { FlarePluginPageViewModel } from "../../shared/contracts/plugin-ui";
import FlarePluginPage from "./FlarePluginPage.vue";
import FlarePluginView from "./FlarePluginView.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareSelect from "../form/FlareSelect.vue";
import FlarePluginForm from "../form/FlarePluginForm.vue";

enableAutoUnmount(afterEach);
afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
  document.body.innerHTML = "";
});

type Case<T> = T & { name: string; platforms: string[] };
const read = (name: string) => JSON.parse(readFileSync(resolve(__dirname, `../../../../../spec/${name}`), "utf8"));
const vectors = read("plugin-view-vectors.json");
const refreshVectors = read("plugin-refresh-vectors.json");
const vue = <T extends { platforms: string[] }>(cases: T[]) => cases.filter((c) => c.platforms.includes("vue"));
const viewOf = (view: Record<string, unknown>): FlarePluginPageViewModel => ({ available: true, title: "页", fields: [], actions: [], ...view } as FlarePluginPageViewModel);
const page = { pluginId: "x.plugin", page: "x.plugin.page" };
const idsIn = (wrapper: VueWrapper, selector: string) => wrapper.findAll(`${selector} [data-action-id]`).map((n) => n.attributes("data-action-id"));

function renderPage(props: Record<string, unknown>) {
  const state = reactive<Record<string, unknown>>({ page, title: "页", back: true, ...props });
  const events: Array<[string, ...unknown[]]> = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { pointer: "fine" } });
      return () => h(FlarePluginPage as never, {
        ...state,
        onRefresh: (reason: string) => events.push(["refresh", reason]),
        onRetry: () => events.push(["retry"]),
        onDone: () => events.push(["done"]),
        onAction: (id: string) => events.push(["action", id]),
      });
    },
  }), { attachTo: document.body });
  return { wrapper, state, events };
}
function renderView(props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { pointer: "fine" } });
      return () => h(FlarePluginView as never, { onAction: () => undefined, ...props });
    },
  }), { attachTo: document.body });
}

describe("actionRoles drawn (R2)", () => {
  type C = Case<{ embedded: boolean; inlineFormActionId?: string; view: Record<string, unknown>; expect: { places: Record<string, unknown>; chevron?: string[] } }>;
  const cases = vue(vectors.actionRoles as C[]).filter((c) => !c.inlineFormActionId);
  it.each(cases.map((c) => [c.name, c] as const))("%s", async (_, c) => {
    const wrapper = renderView({ view: viewOf(c.view), embedded: c.embedded, actionLayout: c.embedded ? "roles" : "inline", rowsLayout: "list" });
    await flushPromises();
    const places = c.expect.places as Record<string, string[] | Array<{ group: string | null; ids: string[] }>>;
    if (!c.embedded) {
      expect(idsIn(wrapper, "[data-place='footer']")).toEqual(places.footer);
      const items = wrapper.findComponent(FlareActionMenu).props("items") as Array<{ id: string }>;
      expect(items.map((item) => item.id)).toEqual(places.menu);
      return;
    }
    expect(idsIn(wrapper, "[data-place='quick']")).toEqual(places.quick ?? []);
    // R2.1: the quick keys close the overview card, which holds the hero/stats.
    if ((places.quick as string[] | undefined)?.length) {
      expect(wrapper.find("[data-overview-card] [data-place='quick']").exists()).toBe(true);
      expect(wrapper.find("[data-overview-card] [data-block='hero']").exists()).toBe(true);
      expect(wrapper.find("[data-overview-card] [data-place='list']").exists()).toBe(false);
    }
    expect(idsIn(wrapper, "[data-place='bar']")).toEqual([...(places.bar as string[] ?? []), ...(places.barSecondary as string[] ?? [])]);
    expect(idsIn(wrapper, "[data-place='commands']")).toEqual(places.commands ?? []);
    expect(idsIn(wrapper, "[data-place='more']")).toEqual(places.more ?? []);
    expect(idsIn(wrapper, "[data-place='danger']")).toEqual(places.danger ?? []);
    const groups = wrapper.findAll("[data-place='list']").map((node) => ({
      group: node.attributes("data-group") === "list" ? null : node.attributes("data-group"),
      ids: node.findAll("[data-action-id]").map((n) => n.attributes("data-action-id")),
    }));
    expect(groups).toEqual(places.list ?? []);
    // List rows are kit rows in color.text.primary, never brand text keys; only destinations carry the chevron.
    expect(wrapper.findAll("[data-place='list'] .flare-button").length).toBe(0);
    if (c.expect.chevron) expect(wrapper.findAll("[data-place='list'] [data-chevron]").map((n) => n.attributes("data-action-id"))).toEqual(c.expect.chevron);
  });
});

describe("statusValues drawn (R3)", () => {
  type C = Case<{ where: string; item: Record<string, unknown>; expect: { draw: string; text?: string; tone?: string; unknown?: boolean } }>;
  const drawn = vue(vectors.statusValues as C[]).filter((c) => c.where !== "badge");
  it.each(drawn.map((c) => [c.name, c] as const))("%s", async (_, c) => {
    vi.spyOn(console, "warn").mockImplementation(() => undefined);
    const view = c.where === "field" ? viewOf({ fields: [c.item] })
      : c.where === "status" ? viewOf({ blocks: [c.item] })
        : viewOf({ blocks: [{ kind: "rows", source: "s", columns: [{ label: "名称", format: "text" }, { label: "状态", format: "text" }], rows: [{ key: "r", cells: [{ text: "行" }, c.item], actions: [] }], actions: [] }] });
    const wrapper = renderView({ view, embedded: true, rowsLayout: "list", actionLayout: "roles" });
    await flushPromises();
    const tag = wrapper.find("[data-status-tag], [data-row-status]");
    if (c.expect.draw === "text") {
      expect(tag.exists()).toBe(false);
      expect(wrapper.text()).toContain(c.expect.text);
      return;
    }
    expect(tag.attributes("data-tone")).toBe(c.expect.tone);
    expect(tag.text()).toBe(c.expect.unknown ? "未知状态" : c.expect.text);
    // Never the raw value.
    if (c.expect.unknown) expect(wrapper.text()).not.toContain(String(c.item.value ?? c.item.text));
  });
});

describe("references drawn (R3)", () => {
  it("folds reference fields into one References group with copy keys", async () => {
    const c = vue(vectors.references as Array<Case<{ fields: never[]; expect: { main: string[]; references: string[] } }>>)[0];
    const wrapper = renderView({ view: viewOf({ fields: c.fields }), embedded: true, actionLayout: "roles" });
    await flushPromises();
    expect(wrapper.findAll("dl.flare-plugin-view__fields dt").map((n) => n.text())).toEqual(c.expect.main);
    const group = wrapper.get("[data-references]");
    expect(group.element.hasAttribute("open")).toBe(false);
    expect(group.get("summary").text()).toBe("单号与凭据");
    expect(group.findAll("dt").map((n) => n.text())).toEqual(c.expect.references);
    // The copy key is named by pluginView.copyReference ("复制{label}").
    expect(group.findAll("[data-reference-copy]").map((b) => b.attributes("aria-label"))).toEqual(c.expect.references.map((label) => `复制${label}`));
  });
});

describe("cardHeader drawn (R5)", () => {
  type C = Case<{ detail: boolean; footerActions: number; menuActions: number; expect: { order: string[]; detailInFooter?: boolean } }>;
  it.each(vue(vectors.cardHeader as C[]).map((c) => [c.name, c] as const))("%s", async (_, c) => {
    const view = viewOf({
      title: "卡片", detail: c.detail,
      actions: Array.from({ length: c.footerActions }, (_, i) => ({ id: `a${i}`, label: `动作${i}`, target: { kind: "operation", operation: `a${i}` } })),
      menuActions: Array.from({ length: c.menuActions }, (_, i) => ({ id: `m${i}`, label: `菜单${i}` })),
    });
    const wrapper = renderView({ view, icon: "poll", onOpenDetail: () => undefined });
    await flushPromises();
    const head = wrapper.get(".flare-plugin-view__head");
    const order = [...head.element.querySelectorAll(".flare-plugin-view__icon, .flare-plugin-view__title, [data-detail-key], [data-plugin-menu]")]
      .map((el) => el.matches(".flare-plugin-view__icon") ? "icon" : el.matches(".flare-plugin-view__title") ? "title" : el.matches("[data-detail-key]") ? "detail" : "more");
    expect(order).toEqual(c.expect.order);
    expect(wrapper.find(".flare-plugin-view__footer [data-detail-key]").exists()).toBe(Boolean(c.expect.detailInFooter));
  });
});

describe("refreshKey drawn (R1)", () => {
  it.each(vue(vectors.refreshKey as Array<Case<{ view: Record<string, unknown>; expect: boolean }>>).map((c) => [c.name, c] as const))("%s", async (_, c) => {
    const { wrapper } = renderPage({ view: viewOf(c.view) });
    await flushPromises();
    expect(wrapper.find("[data-page-refresh]").exists()).toBe(c.expect);
  });
});

describe("blockBoundInputs drawn (R6.1)", () => {
  it("never draws a bound input or its block action as a page key", async () => {
    const c = vue(vectors.blockBoundInputs as Array<Case<{ view: Record<string, unknown> }>>)[0];
    const { wrapper } = renderPage({ view: viewOf(c.view) });
    await flushPromises();
    expect(wrapper.find("[data-inline-action-form]").exists()).toBe(false);
    expect(wrapper.find("[data-input-id='materialId']").exists()).toBe(false);
    expect(wrapper.find("[data-action-id='viewMaterial']").exists()).toBe(false);
    expect(wrapper.find("[data-action-id='apply']").exists()).toBe(true);
  });
});

describe("pageStates drawn (R8)", () => {
  type C = Case<{ loading: boolean; elapsedMs?: number; error?: string; offline?: boolean; actionError?: string; view: Record<string, unknown> | null; expect: Record<string, unknown> }>;
  it.each(vue(vectors.pageStates as C[]).map((c) => [c.name, c] as const))("%s", async (_, c) => {
    vi.useFakeTimers();
    const { wrapper } = renderPage({ loading: c.loading, error: c.error, offline: c.offline, actionError: c.actionError, view: c.view ? viewOf(c.view) : undefined });
    if (c.elapsedMs !== undefined) await vi.advanceTimersByTimeAsync(c.elapsedMs);
    await flushPromises();
    const expected = c.expect as { state: string; rows?: number; title?: string; description?: string; action?: string; banner?: { tone: string; text: string; dismissible?: boolean }; actionsDisabled?: boolean; primaryCaption?: string; blockEmpty?: { icon: string; title: string; action: string } };
    if (expected.state === "blank") expect(wrapper.find(".flare-skeleton").exists()).toBe(false);
    if (expected.state === "skeleton") expect(wrapper.findAll("[data-page-skeleton] .sk-list-row")).toHaveLength(expected.rows!);
    if (expected.state === "error") {
      const empty = wrapper.get("[data-page-error]");
      expect(empty.get(".flare-empty__title").text()).toBe("没有读到内容");
      expect(empty.text()).toContain(expected.description);
      expect(wrapper.get("[data-page-retry]").text()).toBe("重试");
    }
    if (expected.banner?.tone === "warning") expect(wrapper.get("[data-page-offline]").text()).toContain("网络不可用");
    if (expected.banner?.tone === "danger") {
      const banner = wrapper.get("[data-page-action-error]");
      expect(banner.text()).toContain(expected.banner.text);
      await banner.get(".flare-status-banner__dismiss").trigger("click");
      expect(wrapper.find("[data-page-action-error]").exists()).toBe(false);
    }
    if (expected.actionsDisabled) {
      const keys = wrapper.findAll("[data-action-id]");
      expect(keys.length).toBeGreaterThan(0);
      expect(keys.every((key) => key.attributes("disabled") !== undefined)).toBe(true);
      expect(wrapper.get("[data-offline-caption]").text()).toBe("联网后可用");
    }
    if (expected.blockEmpty) {
      expect(wrapper.get("[data-rows-empty]").text()).toBe(expected.blockEmpty.title);
      expect(wrapper.getComponent(FlareEmptyState).props("icon")).toBe(expected.blockEmpty.icon);
      expect(wrapper.find(`[data-empty-action='${expected.blockEmpty.action}']`).exists()).toBe(true);
    }
  });
});

describe("result drawn (R7)", () => {
  type C = Case<{ block: Record<string, unknown>; expect: { icon: string; tone: string; title?: string; amount?: string; description?: string; unknown?: boolean; poll: boolean } }>;
  it.each(vue(vectors.result as C[]).map((c) => [c.name, c] as const))("%s", async (_, c) => {
    vi.useFakeTimers();
    vi.spyOn(console, "warn").mockImplementation(() => undefined);
    const { wrapper, events } = renderPage({ view: viewOf({ fields: [{ label: "金额", value: "¥99.00" }], blocks: [c.block], actions: [{ id: "original", label: "查看原单", target: { kind: "page", page: "p" } }] }) });
    await flushPromises();
    expect(wrapper.get("[data-result-icon]").attributes("data-result-icon")).toBe(c.expect.icon);
    expect(wrapper.get("[data-result-tone]").attributes("data-result-tone")).toBe(c.expect.tone);
    expect(wrapper.get(".flare-result__title").text()).toBe(c.expect.unknown ? "未知状态" : c.expect.title);
    if (c.expect.amount) expect(wrapper.get("[data-result-amount]").text()).toBe(c.expect.amount);
    // No refresh key and no archetype places; the actions follow as secondary keys.
    expect(wrapper.find("[data-page-refresh]").exists()).toBe(false);
    expect(wrapper.find("[data-place]").exists()).toBe(false);
    expect(wrapper.get("[data-action-id='original']").attributes("data-action-variant")).toBe("secondary");
    await wrapper.get("[data-result-done]").trigger("click");
    expect(events).toContainEqual(["done"]);
    await vi.advanceTimersByTimeAsync(3000);
    expect(events.filter((e) => e[0] === "refresh")).toEqual(c.expect.poll ? [["refresh", "timer"]] : []);
    if (c.expect.poll) {
      await vi.advanceTimersByTimeAsync(60000);
      const polls = events.filter((e) => e[0] === "refresh").length;
      await vi.advanceTimersByTimeAsync(9000);
      expect(events.filter((e) => e[0] === "refresh").length).toBe(polls);
      expect(polls).toBeLessThanOrEqual(20);
    }
  });
});

describe("statusCard drawn (6.1)", () => {
  it.each(vue(vectors.statusCard as Array<Case<{ view: Record<string, unknown>; expect: boolean }>>).map((c) => [c.name, c] as const))("%s", async (_, c) => {
    const { wrapper } = renderPage({ view: viewOf(c.view) });
    await flushPromises();
    expect(wrapper.find("[data-status-card]").exists()).toBe(c.expect);
    if (c.expect) {
      const field = (c.view.fields as Array<{ value: string }>)[0];
      expect(wrapper.get(".flare-plugin-view__status-title").text()).toBe(field.value);
      // The status field is the card's title, not a field line as well.
      expect(wrapper.findAll("dl.flare-plugin-view__fields dd").map((n) => n.text())).not.toContain(field.value);
    }
  });
});

describe("afterAction (R4, plugin-refresh-vectors)", () => {
  type C = { name: string; settle: "ok" | "error" | "formErrors" | "cancelled"; visible: boolean; expect: { refresh: boolean; reason?: string } };
  it.each((refreshVectors.afterAction as C[]).map((c) => [c.name, c] as const))("%s", async (_, c) => {
    const go = { id: "go", label: "执行", target: { kind: "operation", operation: "go" }, ...(c.settle === "cancelled" ? { confirm: "确定执行吗？" } : {}) };
    const { wrapper, state, events } = renderPage({ view: viewOf({ fields: [{ label: "余额", value: "¥1.00" }], actions: [go] }), settleToken: 0 });
    await flushPromises();
    await wrapper.get("[data-action-id='go']").trigger("click");
    await flushPromises();
    if (c.settle === "cancelled") {
      ([...document.body.querySelectorAll("button")].find((b) => b.textContent?.trim() === "取消") as HTMLButtonElement).click();
      await flushPromises();
      expect(events.filter((e) => e[0] === "action")).toEqual([]);
    } else expect(events.filter((e) => e[0] === "action")).toEqual([["action", "go"]]);
    if (c.settle === "error") state.actionError = "没有成功";
    if (c.settle === "formErrors") state.formErrors = [{ input: "x", issue: "required" }];
    if (!c.visible) state.visible = false;
    state.settleToken = 1;
    await flushPromises();
    expect(events.filter((e) => e[0] === "refresh")).toEqual(c.expect.refresh ? [["refresh", c.expect.reason]] : []);
  });
});

describe("list row in flight (R2.5)", () => {
  it("spins in place of the chevron, is busy, and every other action waits", async () => {
    const home = (vectors.actionRoles as Array<{ name: string; view: Record<string, unknown> }>).find((c) => c.name.startsWith("wallet home"))!;
    const wrapper = renderView({ view: viewOf(home.view), embedded: true, actionLayout: "roles", rowsLayout: "list", busyActionId: "history" });
    await flushPromises();
    const row = wrapper.get("[data-action-id='history']");
    expect(row.find("[data-settings-spinner]").exists()).toBe(true);
    expect(row.find(".flare-settings__chev").exists()).toBe(false);
    expect(row.attributes("aria-busy")).toBe("true");
    expect(wrapper.get("[data-action-id='security']").attributes("disabled")).toBeDefined();
    expect(wrapper.find("[data-action-id='security'] .flare-settings__chev").exists()).toBe(true);
  });
});

describe("selectOptions drawn (R6)", () => {
  it("no choices: a disabled select saying why, submit off", async () => {
    const input = { id: "plan", kind: "select", label: "方案", choices: [] };
    const wrapper = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(FlarePluginForm, { inputs: [input] as never }); } }), { attachTo: document.body });
    await flushPromises();
    expect(wrapper.get("[data-input-id='plan']").attributes("data-select-control")).toBe("empty");
    expect(wrapper.getComponent(FlareSelect).props("disabled")).toBe(true);
    expect(wrapper.getComponent(FlareSelect).props("placeholder")).toBe("暂无可选项");
    expect(wrapper.get("[data-input-id='plan']").text()).toContain("暂时无法选择，请稍后再试");
    expect(wrapper.get("[data-form-submit]").attributes("disabled")).toBeDefined();
  });

  type C = Case<{ choices: number; expect: { control: string; disabled: boolean; submitDisabled: boolean } }>;
  it.each(vue(vectors.selectOptions as C[]).map((c) => [c.name, c] as const))("%s", async (_, c) => {
    // Protocol inputs carry no help text: a select without choices always explains with pluginView.noOptionsHelp.
    const input = { id: "plan", kind: "select", label: "方案", choices: Array.from({ length: c.choices }, (_, i) => ({ value: `v${i}`, label: `选项${i}` })) };
    const wrapper = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(FlarePluginForm, { inputs: [input] as never }); } }), { attachTo: document.body });
    await flushPromises();
    expect(wrapper.get("[data-input-id='plan']").attributes("data-select-control")).toBe(c.expect.disabled ? "empty" : c.expect.control);
    if (c.expect.disabled) {
      const select = wrapper.getComponent(FlareSelect);
      expect(select.props("disabled")).toBe(true);
      expect(select.props("placeholder")).toBe("暂无可选项");
      expect(wrapper.get("[data-input-id='plan']").text()).toContain("暂时无法选择，请稍后再试");
    }
    expect(wrapper.get("[data-form-submit]").attributes("disabled") !== undefined).toBe(c.expect.submitDisabled);
  });
});

describe("disabledReason (R2.5)", () => {
  it("disables the key, writes the reason under it, and a list row shows it as its detail", async () => {
    const actions: string[] = [];
    const wrapper = renderView({
      embedded: true,
      actionLayout: "roles",
      onAction: (id: string) => actions.push(id),
      view: viewOf({
        fields: [{ label: "扣款", value: "¥1.00" }],
        actions: [
          { id: "confirm", label: "确认", style: "primary", target: { kind: "operation", operation: "confirm" }, disabledReason: "余额不足" },
          { id: "orders", label: "查看待确认操作", target: { kind: "page", page: "p.orders" }, disabledReason: "暂无待确认操作" },
        ],
      }),
    });
    await flushPromises();
    const key = wrapper.get("[data-action-id='confirm']");
    expect(key.attributes("disabled")).toBeDefined();
    const reason = wrapper.findAll("[data-disabled-reason]").find((node) => node.text() === "余额不足")!;
    expect(reason.exists()).toBe(true);
    expect(key.attributes("aria-describedby")).toBe(reason.attributes("id"));
    const row = wrapper.get("[data-action-id='orders']");
    expect(row.attributes("disabled")).toBeDefined();
    expect(row.text()).toContain("暂无待确认操作");
    await key.trigger("click");
    await row.trigger("click");
    expect(actions).toEqual([]);
  });

  // spec/plugin-view-vectors.json actionDisabled: the core resolved hiddenWhen, then disabledWhen; the kit draws what
  // it got — a disabledReason disables the key in its usual place, with the reason under it.
  type C = Case<{ actions: Array<Record<string, unknown>>; expect: { drawn: string[]; disabled: string[]; captions: Record<string, string> } }>;
  it.each(vue(vectors.actionDisabled as C[]).map((c) => [c.name, c] as const))("actionDisabled: %s", async (_, c) => {
    const ran: string[] = [];
    const wrapper = renderView({ embedded: true, actionLayout: "roles", onAction: (id: string) => ran.push(id), view: viewOf({ actions: c.actions }) });
    await flushPromises();
    const keys = wrapper.findAll("[data-action-id]");
    expect(keys.map((k) => k.attributes("data-action-id"))).toEqual(c.expect.drawn);
    expect(keys.filter((k) => k.attributes("disabled") !== undefined).map((k) => k.attributes("data-action-id"))).toEqual(c.expect.disabled);
    for (const [id, text] of Object.entries(c.expect.captions)) {
      const key = wrapper.get(`[data-action-id='${id}']`);
      const described = key.attributes("aria-describedby");
      // A key's caption is linked by aria-describedby; a list row shows the reason as its detail.
      expect(described ? document.getElementById(described)?.textContent?.trim() : key.text()).toContain(text);
    }
    if (!c.expect.disabled.length) expect(wrapper.find("[data-disabled-reason]").exists()).toBe(false);
    for (const id of c.expect.disabled) await wrapper.get(`[data-action-id='${id}']`).trigger("click");
    expect(ran).toEqual([]);
  });
});

// spec/plugin-view-vectors.json pageTabs (4.7): sibling pages as the kit SegmentedControl, a tab event to replace the
// page, and the last tabs kept while the chosen page loads.
describe("pageTabs drawn (4.7)", () => {
  type C = Case<{ page: { pluginId: string; page: string }; view?: Record<string, unknown> | null; views?: Array<Record<string, unknown>>;
    previous?: Record<string, unknown>; loading?: boolean; choose?: number; expect: { tabs: string[] | null; selected?: number; emitted?: string | null } }>;
  const labels = (wrapper: VueWrapper) => wrapper.findAll("[data-page-tabs] [role='tab']").map((tab) => tab.text());
  it.each(vue(vectors.pageTabs as C[]).map((c) => [c.name, c] as const))("pageTabs: %s", async (_, c) => {
    const tabs: string[] = [];
    for (const view of c.views ?? [c.view ?? null]) {
      const { wrapper, state } = renderPage({ page: c.previous ? { pluginId: c.page.pluginId, page: "flare.redpacket.page.received" } : c.page,
        view: view && viewOf(view), loading: Boolean(c.loading), onTab: (page: string) => tabs.push(page) });
      if (c.previous) {
        state.view = viewOf(c.previous); await flushPromises();
        state.page = c.page; state.view = undefined; state.loading = true;
      }
      await flushPromises();
      if (c.expect.tabs === null) { expect(wrapper.find("[data-page-tabs]").exists()).toBe(false); continue; }
      expect(wrapper.get("[data-page-tabs]").attributes("role")).toBe("tablist");
      expect(labels(wrapper)).toEqual(c.expect.tabs);
      const all = wrapper.findAll("[data-page-tabs] [role='tab']");
      expect(all.map((tab) => tab.attributes("aria-selected"))).toEqual(c.expect.tabs.map((_, i) => String(i === c.expect.selected)));
      if (c.choose !== undefined) {
        await all[c.choose].trigger("click");
        expect(tabs).toEqual(c.expect.emitted ? [c.expect.emitted] : []);
      }
    }
  });
});

// spec/plugin-view-vectors.json rowsIcon (4.7, R2.3): a rows block with an icon draws its rows as records.
describe("rowsIcon drawn (4.7)", () => {
  type C = Case<{ block: Record<string, unknown>; expect: { rows?: Array<{ icon: string | null; title?: string; line?: string | null; value?: string;
    tags?: Array<{ text: string; tone: string }> }>; empty?: { icon: string; title: string } } }>;
  it.each(vue(vectors.rowsIcon as C[]).map((c) => [c.name, c] as const))("rowsIcon: %s", async (_, c) => {
    const { wrapper } = renderPage({ view: viewOf({ blocks: [c.block] }), resolveUser: (id: string) => vectors.users[id] });
    await flushPromises();
    if (c.expect.empty) {
      const empty = wrapper.getComponent(FlareEmptyState);
      expect(empty.props("icon")).toBe(c.expect.empty.icon);
      expect(empty.props("title")).toBe(c.expect.empty.title);
      return;
    }
    const items = wrapper.findAll(".flare-plugin-rows__item");
    c.expect.rows!.forEach((want, index) => {
      const item = items[index];
      if (want.icon === null) { expect(item.find("[data-row-title]").exists()).toBe(false); return; }
      expect(item.get("[data-row-icon]").attributes("data-icon")).toBe(want.icon);
      expect(item.get("[data-row-title]").text()).toBe(want.title);
      expect(item.find("[data-row-line]").exists() ? item.get("[data-row-line]").text() : null).toBe(want.line);
      expect(item.get("[data-row-value]").text()).toBe(want.value);
      expect(item.findAll("[data-row-status]").map((tag) => [tag.text(), tag.attributes("data-tone")])).toEqual(want.tags!.map((tag) => [tag.text, tag.tone]));
    });
  });
});

// spec/plugin-view-vectors.json rowTap (R2.3): a row whose only action opens a page is that action's button.
describe("rowTap drawn (R2.3)", () => {
  type Row = { key: string; tap: string | null; keys: string[]; chevron: boolean };
  type C = Case<{ block: Record<string, unknown>; expect: { rows: Row[]; emit?: { actionId: string; rowKey: string; input: unknown } } }>;
  it.each(vue(vectors.rowTap as C[]).map((c) => [c.name, c] as const))("rowTap: %s", async (_, c) => {
    const { wrapper, state } = renderPage({ view: viewOf({ blocks: [c.block] }), resolveUser: (id: string) => vectors.users[id] });
    await flushPromises();
    const items = wrapper.findAll(".flare-plugin-rows__item");
    expect(items.map((item) => item.attributes("data-row-key"))).toEqual(c.expect.rows.map((row) => row.key));
    c.expect.rows.forEach((want, index) => {
      const tap = items[index].find("[data-row-tap]");
      expect(tap.exists() ? tap.attributes("data-row-tap") : null, want.key).toBe(want.tap);
      if (want.tap) expect(tap.element.tagName).toBe("BUTTON");
      expect(items[index].findAll("[data-row-action]").map((key) => key.attributes("data-row-action")), want.key).toEqual(want.keys);
      expect(items[index].find("[data-row-chevron]").exists(), want.key).toBe(want.chevron);
    });
    if (!c.expect.emit) return;
    const { actionId, rowKey, input } = c.expect.emit;
    await wrapper.get(`[data-row-key="${rowKey}"] [data-row-tap]`).trigger("click");
    const [id, payload] = wrapper.findComponent(FlarePluginPage).emitted("action")!.at(-1) as [string, { row?: unknown }];
    expect(id).toBe(actionId);
    expect(payload.row).toEqual({ key: rowKey, input });
    // Busy as on a key: the row that ran spins in place of its chevron and every row control waits.
    state.busyActionId = actionId;
    await flushPromises();
    const row = wrapper.get(`[data-row-key="${rowKey}"]`);
    expect(row.find("[data-row-spinner]").exists()).toBe(true);
    expect(row.find("[data-row-chevron]").exists()).toBe(false);
    expect(wrapper.findAll("[data-row-tap]").every((button) => button.attributes("disabled") !== undefined)).toBe(true);
  });
});

// spec/plugin-view-vectors.json formats2 money (R10): a money cell and the hero draw through the payment formatter.
describe("money with its currency drawn (R10)", () => {
  it("writes a row cell and the hero amount with the currency's symbol", async () => {
    const money = { kind: "money", minor: "123456", scale: 2, currency: "CNY" };
    const { wrapper } = renderPage({ view: viewOf({ blocks: [
      { kind: "hero", label: "可用余额", value: "1234.56", amount: true, format: money, tone: "neutral" },
      { kind: "rows", source: "s", columns: [{ label: "余额", format: "text" }, { label: "钱包", format: "text" }],
        rows: [{ key: "w1", cells: [{ text: "1234", format: { kind: "money", minor: "1234", scale: 0, currency: "LABPOINT" } }, { text: "积分" }], actions: [] }], actions: [] },
    ] }) });
    await flushPromises();
    expect(wrapper.text()).toContain("¥1,234.56");
    expect(wrapper.get('[data-row-key="w1"] [data-row-primary]').text()).toBe("1,234 LABPOINT");
  });
});
