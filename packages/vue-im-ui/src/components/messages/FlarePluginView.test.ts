// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount, type VueWrapper } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { flareMessages } from "../../shared/i18n/messages";
import {
  flarePluginDateTime,
  flarePluginTimeText,
  type FlarePluginActionPayload,
  type FlarePluginUser,
  type FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";
import FlarePluginView from "./FlarePluginView.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";

enableAutoUnmount(afterEach);
afterEach(() => {
  vi.useRealTimers();
  document.body.innerHTML = "";
});

type Fact = Record<string, unknown> & { kind: string };
type ActionFact = { id: string; label: string; variant: string; confirm: string | null; form: boolean };
type ViewVector = {
  id: string;
  platforms: string[];
  view: FlarePluginViewModel;
  embedded?: boolean;
  viewerId?: string;
  displayName?: string;
  expect: {
    title: string;
    bodyHidden: boolean;
    fields: Array<{ label: string; value: string }>;
    blocks: Fact[];
    actions: ActionFact[];
    menu: ActionFact[];
    menuPresentation?: "keys";
    reason: string | null;
  };
};
type Step = {
  tap?: number;
  toggle?: number;
  submit?: boolean;
  host?: { busyActionId?: string | null; error?: string; view?: string; settleToken?: number };
  emit?: { actionId: string; payload: FlarePluginActionPayload };
  selected?: number[];
  interactive?: boolean;
  submitEnabled?: boolean;
};
type DetailKeyCase = {
  name: string;
  platforms: string[];
  view: string;
  detail?: boolean;
  embedded?: boolean;
  busy?: boolean;
  busyActionId?: string;
  handler?: boolean;
  expect: { key: { label: string; enabled: boolean } | null; seeAll?: string | null; opens?: boolean };
};
type InsetSides = { top: string | null; sides: string | null; bottom: string | null };
type CapStep = {
  tap?: number;
  toggle?: number;
  submit?: boolean;
  emit?: { actionId: string; payload: FlarePluginActionPayload };
  selected?: number[];
  enabled?: boolean[];
  submitEnabled?: boolean;
};
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as {
  nowMs: number;
  users: Record<string, FlarePluginUser>;
  views: ViewVector[];
  optimistic: Array<{ name: string; view: string; steps: Step[] }>;
  detailKey: DetailKeyCase[];
  insets: Record<string, InsetSides>;
  maxSelections: Array<{ name: string; platforms: string[]; view: string; embedded?: boolean; steps: CapStep[] }>;
};
const viewOf = (id: string) => vectors.views.find((v) => v.id === id)!.view;
const zh = (flareMessages["zh-CN"] as unknown as { pluginView: { dateTime: string; dateTimeYear: string } }).pluginView;
const resolveUser = (id: string) => vectors.users[id];

function render(props: Record<string, unknown>, { openDetail = true }: { openDetail?: boolean } = {}) {
  const state = reactive<Record<string, unknown>>({ resolveUser, ...props });
  const actions: Array<[string, FlarePluginActionPayload]> = [];
  const details: unknown[] = [];
  const loads: Array<[string, string]> = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlarePluginView as never, {
        ...state,
        onAction: (id: string, payload: FlarePluginActionPayload) => actions.push([id, payload]),
        ...(openDetail ? { onOpenDetail: (row?: unknown) => details.push(row) } : {}),
        onLoadMore: (cursor: string, source: string) => loads.push([cursor, source]),
      });
    },
  }), { attachTo: document.body });
  return { wrapper, state, actions, details, loads };
}

const text = (wrapper: VueWrapper, selector: string) => wrapper.findAll(selector).map((n) => n.text());
const bodyButton = (label: string) =>
  [...document.body.querySelectorAll("button")].find((b) => b.textContent?.trim() === label) as HTMLButtonElement | undefined;

function expectBlock(_wrapper: VueWrapper, node: ReturnType<VueWrapper["find"]>, fact: Fact, block: Record<string, unknown>): void {
  switch (fact.kind) {
    case "text":
      expect(node.get(".flare-plugin-text__body").text()).toBe(fact.text);
      expect(node.get(".flare-plugin-text__body").classes()).toContain(`is-${fact.style}`);
      expect(node.find("[data-clamped]").exists()).toBe(fact.maxLines !== null);
      break;
    case "fields":
      expect(node.findAll("dt").map((n) => n.text())).toEqual((fact.fields as Array<{ label: string }>).map((f) => f.label));
      expect(node.findAll("dd").map((n) => n.text())).toEqual((fact.fields as Array<{ value: string }>).map((f) => f.value));
      break;
    case "choices": {
      const options = node.findAll("[data-option-index]");
      const facts = fact.options as Array<{ label: string; selected: boolean; enabled?: boolean; percentText: string | null; votesText: string | null; bar: number | null }>;
      expect(options.map((o) => o.get(".flare-plugin-choices__label").text())).toEqual(facts.map((f) => f.label));
      facts.forEach((f, i) => {
        const option = options[i];
        expect(option.classes().includes("is-selected"), `${f.label} selected`).toBe(f.selected);
        expect(option.element.tagName === "BUTTON", `${f.label} tappable`).toBe(fact.interactive);
        if (f.enabled !== undefined) expect(option.attributes("aria-disabled") !== "true", `${f.label} enabled`).toBe(f.enabled);
        expect(option.find("[data-choice-percent]").exists() ? option.get("[data-choice-percent]").text() : null).toBe(f.percentText);
        expect(option.find("[data-choice-votes]").exists() ? option.get("[data-choice-votes]").text() : null).toBe(f.votesText);
        const bar = option.find("[data-choice-bar]");
        expect(bar.exists() ? (bar.element as HTMLElement).style.width : null).toBe(f.bar === null ? null : `${f.bar}%`);
      });
      const submit = node.find("[data-choices-submit]");
      const submitFact = fact.submit as { label: string; enabled: boolean } | null;
      expect(submit.exists()).toBe(submitFact !== null);
      if (submitFact) {
        expect(submit.text()).toBe(submitFact.label);
        expect(submit.attributes("disabled") === undefined).toBe(submitFact.enabled);
      }
      const footer = node.find("[data-choices-footer]");
      expect(footer.exists() ? footer.text() : null).toBe(fact.footer);
      break;
    }
    case "entries": {
      const rows = fact.rows as Array<{
        number: string | null; name: string | null; text: string; group?: string | null; me?: boolean;
        badge?: { text: string; tone: string } | null; order?: string[];
      }>;
      if (rows.some((r) => r.badge !== undefined)) {
        // Badges: the kit tag in the tone, after the name and the me tag, before the text.
        const items = node.findAll("[data-entry-index]");
        rows.forEach((r, i) => {
          const badge = items[i].find("[data-entry-badge]");
          expect(badge.exists() ? { text: badge.text(), tone: badge.attributes("data-tone") } : null, `row ${i} badge`).toEqual(r.badge ?? null);
          if (r.order) {
            const parts = items[i].get(".flare-plugin-entries__line").element.children;
            const order = [...parts].map((el) => (el.hasAttribute("data-entry-name") ? "name" : el.hasAttribute("data-entry-me") ? "me" : el.hasAttribute("data-entry-badge") ? "badge" : "text"));
            expect(order, `row ${i} order`).toEqual(r.order);
          }
        });
      }
      if (rows.some((r) => r.group !== undefined)) {
        // Grouped: a header row precedes each item that opens a group; the viewer's row carries the me tag.
        const items = node.findAll("li");
        const seen: Array<{ group: string | null; me: boolean }> = [];
        let header: string | null = null;
        for (const li of items) {
          if (li.attributes("data-entry-group")) { header = li.text(); continue; }
          seen.push({ group: header, me: li.find("[data-entry-me]").exists() });
          header = null;
        }
        expect(seen).toEqual(rows.map((r) => ({ group: r.group ?? null, me: Boolean(r.me) })));
      }
      expect(node.findAll("[data-entry-index]")).toHaveLength(rows.length);
      expect(text(node as never, "[data-entry-number]")).toEqual(rows.filter((r) => r.number).map((r) => `${r.number}.`));
      expect(text(node as never, "[data-entry-name]")).toEqual(rows.filter((r) => r.name).map((r) => r.name));
      expect(text(node as never, "[data-entry-text]")).toEqual(rows.map((r) => r.text));
      const all = node.find("[data-entries-see-all]");
      expect(all.exists() ? all.text() : null).toBe(fact.seeAll);
      const empty = node.find("[data-entries-empty]");
      expect(empty.exists() ? empty.text() : null).toBe(fact.empty);
      break;
    }
    case "people": {
      const groups = fact.groups as Array<{ label: string; countText: string; avatars: string[]; tone: string }>;
      const rows = node.findAll(".flare-plugin-people__row");
      expect(rows).toHaveLength(groups.length);
      groups.forEach((g, i) => {
        expect(rows[i].get("[data-people-label]").text()).toBe(g.label);
        expect(rows[i].get("[data-people-count]").text()).toBe(g.countText);
        expect(rows[i].attributes("data-people-tone")).toBe(g.tone);
        expect(rows[i].findAll("[data-people-user]").map((a) => a.attributes("data-people-user"))).toEqual(g.avatars);
      });
      break;
    }
    case "status":
      expect(node.get(".flare-tag").text()).toBe(fact.text);
      expect(node.get("[data-status-tone]").attributes("data-status-tone")).toBe(fact.tone);
      expect(node.find(".flare-plugin-status__label").exists() ? node.get(".flare-plugin-status__label").text() : null).toBe(fact.label);
      break;
    case "progress":
      expect(node.get("[data-progress-text]").text()).toBe(fact.text);
      expect((node.get("[data-progress-fill]").element as HTMLElement).style.width).toBe(`${fact.percent}%`);
      break;
    case "time": {
      const time = block as { atMs: number; endMs?: number };
      // Device zone: the vector's text holds where the device is on its offset (480).
      const device = flarePluginTimeText(time.atMs, time.endMs, vectors.nowMs, zh);
      expect(node.get("[data-time-text]").text()).toBe(device);
      if (-new Date(time.atMs).getTimezoneOffset() === 480) expect(device).toBe(fact.text);
      const countdown = node.find("[data-time-countdown]");
      expect(countdown.exists() ? countdown.text() : null).toBe(fact.countdown);
      break;
    }
    case "divider":
      expect((node.element as HTMLElement).tagName).toBe("HR");
      break;
    case "note":
      expect(node.text()).toBe(fact.text);
      expect(node.attributes("data-note-tone")).toBe(fact.tone);
      break;
    case "rows": {
      expect(node.findAll("th").map((n) => n.text()).filter(Boolean).slice(0, (fact.columns as string[]).length)).toEqual(fact.columns);
      const rows = fact.rows as Array<{ key: string; cells: string[]; actions: string[] }>;
      const trs = node.findAll("tbody tr.flare-data-table__row");
      expect(trs).toHaveLength(rows.length);
      const rowsBlock = block as { columns: Array<{ format: string }>; rows: Array<{ cells: Array<{ text: string; timeMs?: number }> }> };
      rows.forEach((r, i) => {
        const cells = trs[i].findAll("td").map((td) => td.text());
        // Time cells: the device zone; the vector's text holds on its offset (480).
        const expected = r.cells.map((c, ci) => {
          const source = rowsBlock.rows[i].cells[ci];
          if (rowsBlock.columns[ci].format !== "time" || source.timeMs === undefined) return c;
          const device = flarePluginDateTime(source.timeMs, Date.now(), zh);
          if (-new Date(source.timeMs).getTimezoneOffset() === 480) expect(device).toBe(c);
          return device;
        });
        expect(cells.slice(0, r.cells.length)).toEqual(expected);
        expect(trs[i].findAll("[data-row-action]").map((b) => b.text())).toEqual(r.actions);
      });
      expect(node.find("[data-rows-load-more]").exists()).toBe(fact.loadMore !== null);
      if (fact.empty) expect(node.text()).toContain(fact.empty as string);
      break;
    }
  }
}

describe("FlarePluginView v2 (spec/plugin-view-vectors.json)", () => {
  it.each(vectors.views.map((v) => [v.id, v] as const))("renders %s", async (_, vector) => {
    vi.useFakeTimers({ now: vectors.nowMs });
    const { wrapper } = render({
      view: vector.view,
      embedded: Boolean(vector.embedded),
      viewerId: vector.viewerId,
      displayName: vector.displayName,
    });
    await flushPromises();
    const facts = vector.expect;
    if (!vector.embedded) expect(wrapper.get(".flare-plugin-view__title").text()).toBe(facts.title);
    const reason = wrapper.find("[data-unavailable-reason]");
    expect(reason.exists() ? reason.text() : null).toBe(facts.reason);
    expect(wrapper.findAll("dl.flare-plugin-view__fields dt").map((n) => n.text())).toEqual(facts.fields.map((f) => f.label));
    expect(wrapper.findAll("dl.flare-plugin-view__fields dd").map((n) => n.text())).toEqual(facts.fields.map((f) => f.value));
    const nodes = wrapper.findAll("[data-block]");
    expect(nodes.map((n) => n.attributes("data-block"))).toEqual(facts.blocks.map((b) => b.kind));
    facts.blocks.forEach((fact, i) => expectBlock(wrapper, nodes[i] as never, fact, vector.view.blocks![i] as never));
    // Embedded views draw their menu actions as keys after the actions; cards open them from the ⋯ key.
    const keyFacts = facts.menuPresentation === "keys" ? [...facts.actions, ...facts.menu] : facts.actions;
    const keys = wrapper.findAll("[data-action-id]");
    expect(keys.map((k) => k.attributes("data-action-id"))).toEqual(keyFacts.map((a) => a.id));
    keyFacts.forEach((a, i) => {
      expect(keys[i].text()).toBe(a.label);
      expect(keys[i].classes()).toContain(`flare-button--${a.variant}`);
    });
    const menu = wrapper.findComponent(FlareActionMenu);
    const cardMenu = facts.menuPresentation === "keys" ? [] : facts.menu;
    expect(wrapper.find("[data-plugin-menu]").exists()).toBe(cardMenu.length > 0);
    if (cardMenu.length) {
      expect(wrapper.get("[data-plugin-menu]").attributes("aria-label")).toBe("更多操作");
      const items = menu.props("items") as Array<{ id: string; label: string; danger?: boolean }>;
      expect(items.map((item) => [item.id, item.label, Boolean(item.danger)])).toEqual(cardMenu.map((a) => [a.id, a.label, a.variant === "danger"]));
    }
  });

  it("runs a ⋯ menu action like a button: confirm first, then the action", async () => {
    const { wrapper, actions } = render({ view: viewOf("poll-v2-menu") });
    await flushPromises();
    wrapper.findComponent(FlareActionMenu).vm.$emit("select", "cancel");
    await flushPromises();
    expect(actions).toEqual([]);
    const confirm = bodyButton("取消投票");
    expect(document.body.textContent).toContain("取消后投票作废，确定取消吗？");
    confirm?.click();
    await flushPromises();
    expect(actions).toEqual([["cancel", {}]]);
  });

  it("disables the ⋯ key while busy and has none without menu actions", async () => {
    const { wrapper, state } = render({ view: viewOf("poll-v2-menu") });
    await flushPromises();
    expect(wrapper.get("[data-plugin-menu]").attributes("disabled")).toBeUndefined();
    state.busyActionId = "vote";
    await flushPromises();
    expect(wrapper.get("[data-plugin-menu]").attributes("disabled")).toBeDefined();
    state.view = viewOf("poll-open-single");
    await flushPromises();
    expect(wrapper.find("[data-plugin-menu]").exists()).toBe(false);
  });

  it("names every unavailable reason in both locales (spec unavailableReasons)", async () => {
    const reasons = (JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as {
      unavailableReasons: Array<{ reason: string; zh: string; en: string }>;
    }).unavailableReasons;
    expect(reasons).toHaveLength(7);
    const zhTree = (flareMessages["zh-CN"] as unknown as { pluginView: { unavailable: Record<string, string> } }).pluginView.unavailable;
    const enTree = (flareMessages["en-US"] as unknown as { pluginView: { unavailable: Record<string, string> } }).pluginView.unavailable;
    for (const r of reasons) {
      const key = r.reason.replace(/_(\w)/g, (_, c: string) => c.toUpperCase());
      expect(zhTree[key], r.reason).toBe(r.zh);
      expect(enTree[key], r.reason).toBe(r.en);
    }
  });

  it("names entries and people from resolveUser, a late answer, or the id's last 4 characters", async () => {
    let answer!: (user: FlarePluginUser) => void;
    const { wrapper } = render({
      view: viewOf("task"),
      resolveUser: (id: string) => (id === "u_bob0002" ? new Promise<FlarePluginUser>((res) => { answer = res; }) : vectors.users[id]),
    });
    await flushPromises();
    const names = () => wrapper.findAll("[data-people-user]").map((a) => a.attributes("data-people-user"));
    expect(names()).toEqual(["u_alice01", "u_bob0002", "u_dave9876"]);
    // The unresolved id draws initials of its last 4 characters until (unless) the host answers.
    expect(wrapper.findAll(".flare-plugin-people__avatar")[2].text()).toContain("9");
    answer({ name: "Bobby" });
    await flushPromises();
    expect(wrapper.findAll(".flare-plugin-people__avatar")[1].text()).toContain("B");
  });

  it("asks the host once per id, even when the resolver is a new function on every render", async () => {
    const asked: string[] = [];
    const { state } = render({ view: viewOf("task"), resolveUser: (id: string) => { asked.push(id); return vectors.users[id]; } });
    await flushPromises();
    state.resolveUser = (id: string) => { asked.push(id); return vectors.users[id]; };
    state.busyActionId = "complete";
    await flushPromises();
    expect(asked).toEqual(["u_alice01", "u_bob0002", "u_dave9876"]);
  });

  it.each(vectors.optimistic.map((v) => [v.name, v] as const))("marks a choice at once and settles it: %s", async (_, scenario) => {
    const { wrapper, state, actions } = render({ view: viewOf(scenario.view) });
    await nextTick();
    for (const step of scenario.steps) {
      if (step.tap !== undefined || step.toggle !== undefined) await wrapper.get(`[data-option-index="${step.tap ?? step.toggle}"]`).trigger("click");
      if (step.submit) await wrapper.get("[data-choices-submit]").trigger("click");
      if (step.host) {
        if ("busyActionId" in step.host) state.busyActionId = step.host.busyActionId ?? undefined;
        if (step.host.error !== undefined) state.error = step.host.error;
        if (step.host.settleToken !== undefined) state.settleToken = step.host.settleToken;
        if (step.host.view) state.view = viewOf(step.host.view);
        await nextTick();
        await nextTick();
      }
      if (step.emit) expect(actions.at(-1)).toEqual([step.emit.actionId, step.emit.payload]);
      if (step.selected) {
        const selected = wrapper.findAll("[data-option-index]").filter((o) => o.classes().includes("is-selected")).map((o) => Number(o.attributes("data-option-index")));
        expect(selected).toEqual(step.selected);
      }
      if (step.interactive !== undefined) expect(wrapper.get("[data-option-index]").element.tagName === "BUTTON").toBe(step.interactive);
      if (step.submitEnabled !== undefined) expect(wrapper.get("[data-choices-submit]").attributes("disabled") === undefined).toBe(step.submitEnabled);
    }
  });

  it.each(vectors.maxSelections.filter((c) => c.platforms.includes("vue")).map((c) => [c.name, c] as const))("caps a multiple choice: %s", async (_, scenario) => {
    const { wrapper, actions } = render({ view: viewOf(scenario.view), embedded: Boolean(scenario.embedded) });
    await nextTick();
    for (const step of scenario.steps) {
      if (step.tap !== undefined || step.toggle !== undefined) await wrapper.get(`[data-option-index="${step.tap ?? step.toggle}"]`).trigger("click");
      if (step.submit) await wrapper.get("[data-choices-submit]").trigger("click");
      const options = wrapper.findAll("[data-option-index]");
      if (step.emit) expect(actions.at(-1)).toEqual([step.emit.actionId, step.emit.payload]);
      if (step.selected) expect(options.filter((o) => o.classes().includes("is-selected")).map((o) => Number(o.attributes("data-option-index")))).toEqual(step.selected);
      if (step.enabled) expect(options.map((o) => o.attributes("aria-disabled") !== "true")).toEqual(step.enabled);
      if (step.submitEnabled !== undefined) expect(wrapper.get("[data-choices-submit]").attributes("disabled") === undefined).toBe(step.submitEnabled);
    }
  });

  it("shows the cap's hint only while the block can be chosen", async () => {
    const view = viewOf("poll-max-selections");
    const { wrapper, state } = render({ view });
    await nextTick();
    expect(wrapper.get("[data-choices-footer]").text()).toBe("最多选 2 项");
    const block = view.blocks![0] as Extract<NonNullable<FlarePluginViewModel["blocks"]>[number], { kind: "choices" }>;
    state.view = { ...view, blocks: [{ ...block, closed: true, action: undefined }] };
    await nextTick();
    expect(wrapper.get("[data-choices-footer]").text()).toBe("已结束");
  });

  it("asks first when the action has a confirmation, and sends nothing on cancel", async () => {
    const { wrapper, actions } = render({ view: viewOf("poll-open-single") });
    await wrapper.get('[data-action-id="close"]').trigger("click");
    await flushPromises();
    expect(document.body.textContent).toContain("结束后不能再投票，确定结束吗？");
    expect(actions).toEqual([]);
    bodyButton("取消")!.click();
    await flushPromises();
    expect(actions).toEqual([]);
    await wrapper.get('[data-action-id="close"]').trigger("click");
    await flushPromises();
    const confirm = [...document.body.querySelectorAll(".flare-danger-confirm button, [role='dialog'] button")]
      .find((b) => b.textContent?.trim() === "结束投票") as HTMLButtonElement;
    confirm.click();
    await flushPromises();
    expect(actions).toEqual([["close", {}]]);
  });

  it("collects an action's form in the sheet, keeps it open on errors and closes it once the host is done", async () => {
    const { wrapper, state, actions } = render({ view: viewOf("solitaire-more") });
    await wrapper.get('[data-action-id="join"]').trigger("click");
    await flushPromises();
    const form = () => document.body.querySelector(".flare-plugin-form");
    expect(form()).not.toBeNull();
    // A submit attempt with the required field empty shows the client's check and sends nothing.
    (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
    await flushPromises();
    expect(form()!.textContent).toContain("必填");
    expect(actions).toEqual([]);
    const area = document.body.querySelector(".flare-plugin-form textarea") as HTMLTextAreaElement;
    area.value = "《小王子》";
    area.dispatchEvent(new Event("input"));
    await flushPromises();
    (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
    await flushPromises();
    expect(actions).toEqual([["join", { formValues: { line: "《小王子》" } }]]);
    // The host validates and answers with errors: the sheet stays with them under the input.
    state.busyActionId = "join";
    await nextTick();
    state.formErrors = [{ input: "line", issue: "duplicateItem" }];
    state.busyActionId = undefined;
    await flushPromises();
    expect(form()).not.toBeNull();
    expect(form()!.textContent).toContain("不能重复");
    // The next attempt succeeds: the sheet closes when the host clears busy.
    state.formErrors = [];
    (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
    state.busyActionId = "join";
    await nextTick();
    state.busyActionId = undefined;
    await flushPromises();
    expect(form()).toBeNull();
    void wrapper;
  });

  describe("settleToken", () => {
    async function openSubmittedForm() {
      const rendered = render({ view: viewOf("solitaire-more") });
      await rendered.wrapper.get('[data-action-id="join"]').trigger("click");
      await flushPromises();
      const area = document.body.querySelector(".flare-plugin-form textarea") as HTMLTextAreaElement;
      area.value = "《小王子》";
      area.dispatchEvent(new Event("input"));
      await flushPromises();
      (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
      await flushPromises();
      expect(rendered.actions).toEqual([["join", { formValues: { line: "《小王子》" } }]]);
      return rendered;
    }
    const form = () => document.body.querySelector(".flare-plugin-form");

    it("closes a submitted form when the host settles without errors, though busy never showed", async () => {
      const { state } = await openSubmittedForm();
      // Busy set and cleared within one frame: the fallback sees nothing.
      state.busyActionId = "join";
      state.busyActionId = undefined;
      await flushPromises();
      expect(form()).not.toBeNull();
      state.settleToken = 1;
      await flushPromises();
      expect(form()).toBeNull();
    });

    it("keeps the form open with the host's form errors", async () => {
      const { state } = await openSubmittedForm();
      state.formErrors = [{ input: "line", issue: "duplicateItem" }];
      state.settleToken = 1;
      await flushPromises();
      expect(form()).not.toBeNull();
      expect(form()!.textContent).toContain("不能重复");
    });

    it("keeps the form open with the host's error and shows it there", async () => {
      const { state } = await openSubmittedForm();
      state.error = "网络异常，请重试";
      state.settleToken = 1;
      await flushPromises();
      expect(form()).not.toBeNull();
      expect(form()!.textContent).toContain("网络异常，请重试");
    });

    it("reverts a choice it carried into a form when the form comes back with errors", async () => {
      const base = viewOf("poll-open-single") as Record<string, any>;
      const view = {
        ...base,
        inputs: [{ id: "note", kind: "text", label: "备注", required: true }],
        blocks: base.blocks.map((block: Record<string, any>) =>
          block.kind === "choices" ? { ...block, action: { ...block.action, form: ["note"] } } : block),
      };
      const { wrapper, state } = render({ view });
      await wrapper.findAll(".flare-plugin-choices__option")[1]!.trigger("click");
      await flushPromises();
      const input = document.body.querySelector(".flare-plugin-form input") as HTMLInputElement;
      input.value = "x";
      input.dispatchEvent(new Event("input"));
      await flushPromises();
      (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
      await flushPromises();
      const selected = () => wrapper.findAll("[data-option-index]").filter((o) => o.classes().includes("is-selected")).map((o) => Number(o.attributes("data-option-index")));
      expect(selected()).toEqual([1]);
      state.formErrors = [{ input: "note", issue: "tooLong" }];
      state.settleToken = 1;
      await flushPromises();
      expect(selected()).toEqual([]);
      expect(form()).not.toBeNull();
    });
  });

  it("pads an embedded view with the sheet insets only when asked", () => {
    const plain = render({ view: viewOf("task"), embedded: true }).wrapper.get(".flare-plugin-view");
    expect(plain.classes()).not.toContain("is-inset-sheet");
    const inset = render({ view: viewOf("task"), embedded: true, inset: "sheet" }).wrapper.get(".flare-plugin-view");
    expect(inset.classes()).toContain("is-inset-sheet");
    const css = readFileSync(resolve(__dirname, "FlarePluginView.vue"), "utf8");
    expect(css).toMatch(/\.is-embedded\.is-inset-sheet \{ padding: var\(--flare-size-spacing-md\) var\(--flare-size-spacing-lg\) var\(--flare-size-spacing-xl\); \}/);
  });

  // spec/plugin-view-vectors.json insets: the sides of every value, on the embedded body.
  it.each(Object.entries(vectors.insets))("pads an embedded view by the inset table: %s", (name, sides) => {
    const root = render({ view: viewOf("task"), embedded: true, inset: name }).wrapper.get(".flare-plugin-view");
    const css = readFileSync(resolve(__dirname, "FlarePluginView.vue"), "utf8");
    const side = (token: string | null) => (token ? `var(--flare-size-spacing-${token})` : "0");
    const modifier = name === "sheet" ? "is-inset-sheet" : name === "sheetTop" ? "is-inset-sheet-top" : null;
    if (!modifier) {
      expect(sides).toEqual({ top: null, sides: null, bottom: null });
      expect(root.classes().some((c) => c.startsWith("is-inset"))).toBe(false);
      return;
    }
    expect(root.classes()).toContain(modifier);
    expect(css).toContain(`.flare-plugin-view.is-embedded.${modifier} { padding: ${side(sides.top)} ${side(sides.sides)} ${side(sides.bottom)}; }`);
  });

  it("keeps the inset on an unavailable embedded view, which still shows its title", () => {
    const { wrapper } = render({ view: viewOf("unavailable"), embedded: true, inset: "sheet" });
    const root = wrapper.get(".flare-plugin-view");
    expect(root.classes()).toEqual(expect.arrayContaining(["is-embedded", "is-inset-sheet", "is-unavailable"]));
    expect(wrapper.get("[data-unavailable-title]").text()).toBe("投票（已失效）");
    expect(wrapper.find(".flare-plugin-view__title").exists()).toBe(false);
    expect(wrapper.find("[data-action-id]").exists()).toBe(false);
    // An available embedded view has no such line: the host's surface carries the title.
    expect(render({ view: viewOf("task"), embedded: true }).wrapper.find("[data-unavailable-title]").exists()).toBe(false);
  });

  it("puts the sheet insets around a card shell a host keeps in a sheet", () => {
    for (const inset of ["sheet", "sheetTop"]) {
      const card = render({ view: viewOf("unavailable"), inset }).wrapper.get(".flare-plugin-view");
      expect(card.classes()).not.toContain("is-embedded");
      expect(card.classes()).toContain(inset === "sheet" ? "is-inset-sheet" : "is-inset-sheet-top");
    }
    const css = readFileSync(resolve(__dirname, "FlarePluginView.vue"), "utf8");
    expect(css).toMatch(/\.is-inset-sheet:not\(\.is-embedded\),\s*\.flare-plugin-view\.is-inset-sheet-top:not\(\.is-embedded\) \{[^}]*margin: var\(--flare-size-spacing-md\) var\(--flare-size-spacing-lg\) var\(--flare-size-spacing-xl\);/);
    expect(css).toMatch(/\.is-inset-sheet-top:not\(\.is-embedded\) \{ margin-bottom: 0; \}/);
  });

  describe("view details key (spec/plugin-view-vectors.json detailKey)", () => {
    it.each(vectors.detailKey.filter((c) => c.platforms.includes("vue")).map((c) => [c.name, c] as const))("%s", async (_, scenario) => {
      const base = viewOf(scenario.view);
      const view = scenario.detail === undefined ? base : { ...base, detail: scenario.detail };
      const { wrapper, details } = render(
        { view, embedded: scenario.embedded ?? false, busy: scenario.busy ?? false, busyActionId: scenario.busyActionId },
        { openDetail: scenario.handler !== false },
      );
      await flushPromises();
      const key = wrapper.find("[data-detail-key]");
      expect(key.exists()).toBe(scenario.expect.key !== null);
      if (scenario.expect.key) {
        expect(key.text()).toBe(scenario.expect.key.label);
        expect(key.attributes("disabled") === undefined).toBe(scenario.expect.key.enabled);
        expect(key.classes()).toEqual(expect.arrayContaining(["flare-button--quiet", "flare-button--sm", "is-block"]));
        // Under the action keys.
        const actions = wrapper.find(".flare-plugin-view__actions");
        if (actions.exists()) expect(actions.element.compareDocumentPosition(key.element) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
      }
      if (scenario.expect.seeAll !== undefined) {
        const all = wrapper.find("[data-entries-see-all]");
        expect(all.exists() ? all.text() : null).toBe(scenario.expect.seeAll);
      }
      if (scenario.expect.opens) {
        await key.trigger("click");
        expect(details).toEqual([undefined]);
      }
    });
  });

  it("sends the selection together with the form when a choices action collects one", async () => {
    const base = viewOf("poll-open-single") as Record<string, any>;
    const view = {
      ...base,
      inputs: [{ id: "note", kind: "text", label: "备注" }],
      blocks: base.blocks.map((block: Record<string, any>) =>
        block.kind === "choices" ? { ...block, action: { ...block.action, form: ["note"] } } : block),
    };
    const { wrapper, actions } = render({ view });
    await wrapper.findAll(".flare-plugin-choices__option")[1]!.trigger("click");
    await flushPromises();
    const area = document.body.querySelector(".flare-plugin-form input") as HTMLInputElement;
    area.value = "去年也是这里";
    area.dispatchEvent(new Event("input"));
    await flushPromises();
    (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
    await flushPromises();
    expect(actions).toEqual([["vote", { selection: [1], formValues: { note: "去年也是这里" } }]]);
    void wrapper;
  });

  it("refreshes the countdown every second in the last hour and every minute before", async () => {
    vi.useFakeTimers({ now: vectors.nowMs });
    const at = vectors.nowMs + 3_600_000 + 30_000;
    const view: FlarePluginViewModel = { available: true, title: "t", fields: [], actions: [], blocks: [{ kind: "time", atMs: at, countdown: true }] };
    const { wrapper } = render({ view });
    await nextTick();
    const countdown = () => wrapper.get("[data-time-countdown]").text();
    expect(countdown()).toBe("剩余 1 小时");
    vi.advanceTimersByTime(60_000);
    await nextTick();
    expect(countdown()).toBe("剩余 59:30");
    vi.advanceTimersByTime(1_000);
    await nextTick();
    expect(countdown()).toBe("剩余 59:29");
    vi.advanceTimersByTime(59 * 60_000 + 29_000);
    await nextTick();
    expect(countdown()).toBe("已截止");
    expect(vi.getTimerCount()).toBe(0);
  });

  it("opens the detail from see all and from an admin row, and pages admin rows", async () => {
    const card = render({ view: viewOf("solitaire-more") });
    await card.wrapper.get("[data-entries-see-all]").trigger("click");
    expect(card.details).toEqual([undefined]);
    const admin = render({ view: viewOf("admin-rows") });
    await flushPromises();
    await admin.wrapper.findAll("tbody tr.flare-data-table__row")[0].trigger("click");
    expect(admin.details).toEqual([{ key: "p1", input: { pollId: "p1" } }]);
    await admin.wrapper.get("[data-rows-load-more]").trigger("click");
    expect(admin.loads).toEqual([["c2", "list"]]);
    await admin.wrapper.get('[data-row-action="close"]').trigger("click");
    await flushPromises();
    const confirm = [...document.body.querySelectorAll("button")].filter((b) => b.textContent?.trim() === "关闭").at(-1) as HTMLButtonElement;
    confirm.click();
    await flushPromises();
    expect(admin.actions).toEqual([["close", { row: { key: "p1", input: { pollId: "p1" } } }]]);
  });

  it("expands collapsed text", async () => {
    const { wrapper } = render({ view: viewOf("announcement") });
    const toggle = wrapper.get("[data-text-toggle]");
    expect(toggle.text()).toBe("展开");
    await toggle.trigger("click");
    expect(wrapper.find("[data-clamped]").exists()).toBe(false);
    expect(wrapper.get("[data-text-toggle]").text()).toBe("收起");
  });

  it("drops the shell and the title row when embedded", () => {
    const { wrapper } = render({ view: viewOf("task"), embedded: true });
    expect(wrapper.get(".flare-plugin-view").classes()).toContain("is-embedded");
    expect(wrapper.find(".flare-plugin-view__title").exists()).toBe(false);
  });

  it("shows the plugin icon in the title row", () => {
    const { wrapper } = render({ view: viewOf("task"), icon: "poll" });
    expect(wrapper.find(".flare-plugin-view__icon").exists()).toBe(true);
  });
});

describe("FlarePluginView v1", () => {
  const view = { available: true, title: "<script>unsafe()</script>", fields: [{ label: "Amount", value: "100" }], actions: [{ id: "claim", label: "Claim" }] };
  it("renders inert text and emits only an action ID", async () => {
    const { wrapper, actions } = render({ view });
    expect(wrapper.find("script").exists()).toBe(false);
    await wrapper.get("[data-action-id]").trigger("click");
    expect(actions).toEqual([["claim", {}]]);
  });
  it("removes actions and private fields from unavailable history", () => {
    const { wrapper } = render({ view: { ...view, available: false } });
    expect(wrapper.find("[data-action-id]").exists()).toBe(false);
    expect(wrapper.find("dl").exists()).toBe(false);
  });
  it("blocks repeated actions while a command is unresolved", () => {
    expect(render({ view, busy: true }).wrapper.get("[data-action-id]").attributes("disabled")).toBeDefined();
    const spinning = render({ view, busyActionId: "claim" }).wrapper.get("[data-action-id]");
    expect(spinning.attributes("disabled")).toBeDefined();
    expect(spinning.classes()).toContain("is-loading");
  });
  it("shows the host's error at the bottom", () => {
    expect(render({ view, error: "领取失败" }).wrapper.text()).toContain("领取失败");
  });
});
