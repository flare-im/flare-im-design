// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, reactive, toRaw } from "vue";
import {
  NButton,
  NDataTable,
  NDropdown,
  NForm,
  NFormItem,
  NInput,
  NPagination,
} from "naive-ui";
import FlareAdminList from "../data/FlareAdminList.vue";
import FlareAdminRowActions from "../data/FlareAdminRowActions.vue";
import FlarePluginAdminList from "./FlarePluginAdminList.vue";
import FlareButton from "../general/FlareButton.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type {
  FlarePluginRowsBlock,
  FlarePluginStrings,
} from "../../shared/contracts/plugin-ui";

enableAutoUnmount(afterEach);
afterEach(() => {
  document.body.innerHTML = "";
});
const strings: FlarePluginStrings = {
  deadlinePassed: "Ended",
  remaining: "{time}",
  dateTime: "M/d HH:mm",
  dateTimeYear: "y/M/d HH:mm",
  days: "{n}d",
  hours: "{n}h",
  minutes: "{n}m",
  required: "Required",
  tooLong: "Too long",
  outOfRange: "Out of range",
  tooFewItems: "Too few",
  tooManyItems: "Too many",
  duplicateItem: "Duplicate",
  invalid: "Invalid",
};
const originalInput = { id: "r1", expectedRevision: "900719925474099301" };
const block: FlarePluginRowsBlock = {
  kind: "rows",
  source: "plugin.admin.list",
  columns: [
    { label: "Name", format: "text" },
    { label: "Owner", format: "text" },
    { label: "At", format: "time" },
  ],
  actions: [{ id: "edit", label: "Edit record", form: ["name"] }],
  rows: [
    {
      key: "r1",
      cells: [
        { text: "Full untruncated record name" },
        {
          text: "",
          user: {
            state: "ready",
            name: "Alice",
            account: "alice.full.account",
          },
        },
        { text: "", timeMs: 1730000000000 },
      ],
      badge: { text: "Pending", tone: "warning" },
      detailInput: { id: "r1" },
      actions: [{ id: "edit", input: originalInput }],
    },
    {
      key: "r2",
      cells: [{ text: "Second" }, { text: "Other" }, { text: "Unknown time" }],
      actions: [],
    },
    {
      key: "r3",
      cells: [{ text: "Third" }, { text: "Other" }, { text: "Unknown time" }],
      actions: [],
    },
  ],
};
function setup(extra: Record<string, unknown> = {}) {
  const state = reactive<Record<string, unknown>>({
    block,
    strings,
    label: "Records",
    pagination: { page: 2, pageSize: 1, total: 20, pageSizes: [1, 2] },
    ...extra,
  });
  const wrapper = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () =>
          h(FlarePluginAdminList as never, state, {
            filters: () =>
              h(NFormItem, { label: "Keyword" }, () =>
                h(NInput, { value: "Current query" }),
              ),
            actions: () => h(NButton, {}, () => "Create record"),
            tools: () => h(NButton, {}, () => "Export records"),
            "error-actions": () => h(NButton, {}, () => "Retry reading"),
          });
      },
    }),
    { attachTo: document.body },
  );
  return {
    wrapper,
    state,
    adapter: wrapper.getComponent(FlarePluginAdminList),
    list: wrapper.getComponent(FlareAdminList),
  };
}

function cardBlock(): FlarePluginRowsBlock {
  return {
    ...block,
    presentation: "cards",
    actions: [{ ...block.actions[0], confirm: "Review this setting change" }],
    rows: [
      block.rows[0],
      ...Array.from({ length: 8 }, (_, i) => ({
        key: `setting-${i}`,
        cells: [
          { text: `Setting ${i + 2}` },
          { text: "Enabled" },
          { text: "Application" },
        ],
        actions: [],
      })),
      { ...block.rows[0], cells: [{ text: "Duplicate must not appear" }] },
    ],
  };
}

/** The select handler of the row actions holding `key`, as the render that drew it bound it. */
function capturedAction(wrapper: ReturnType<typeof mount>, key: string) {
  const actions = wrapper
    .findAllComponents(FlareAdminRowActions)
    .find((found) =>
      (found.props("actions") as readonly { key: string }[]).some(
        (action) => action.key === key,
      ),
    )!;
  expect(actions).toBeDefined();
  const select = actions.vm.$.vnode.props?.onSelect as (key: string) => void;
  expect(typeof select).toBe("function");
  return () => select(key);
}

function capturedClick(wrapper: ReturnType<typeof mount>, attribute: string) {
  const button = wrapper
    .findAllComponents(FlareButton)
    .find((b) => b.attributes(attribute) !== undefined)!;
  expect(button).toBeDefined();
  const click = button.vm.$.vnode.props?.onClick as () => void;
  expect(typeof click).toBe("function");
  return click;
}

describe("FlarePluginAdminList / native operational list adapter", () => {
  it("keeps explicit cards inside the shared query, toolbar, error and numbered paging container", async () => {
    const { wrapper, list, adapter } = setup({
      block: cardBlock(),
      error: "Read unavailable",
    });
    expect(wrapper.findAll(".flare-admin-policy-card")).toHaveLength(9);
    expect(wrapper.findAllComponents(FlareAdminList)).toHaveLength(1);
    expect(wrapper.findAllComponents(NForm)).toHaveLength(1);
    expect(wrapper.findComponent(NDataTable).exists()).toBe(false);
    expect(wrapper.find(".flare-admin-list__settings-trigger").exists()).toBe(
      false,
    );
    expect(wrapper.findAll(".flare-admin-list__toolbar")).toHaveLength(1);
    for (const text of [
      "Keyword",
      "Create record",
      "Export records",
      "Read unavailable",
      "Retry reading",
      "Full untruncated record name",
      "Enabled",
    ]) {
      expect(wrapper.text()).toContain(text);
    }
    expect(wrapper.text()).not.toContain("Duplicate must not appear");
    expect(wrapper.text()).not.toContain("expectedRevision");
    expect(wrapper.find(".n-alert, .flare-status-banner").exists()).toBe(false);
    expect(list.get(".flare-admin-list__cards").element.parentElement).toBe(
      list.get(".flare-admin-list__footer").element.parentElement,
    );
    list.getComponent(NPagination).vm.$emit("update:pageSize", 2);
    await nextTick();
    expect(adapter.emitted("update:pagination")?.[0]).toEqual([
      { page: 1, pageSize: 2, total: 20, pageSizes: [1, 2] },
    ]);
    expect(wrapper.findAll(".flare-admin-policy-card")).toHaveLength(9);
  });

  it("keeps card action inputs and confirmation metadata exact and rejects stale callbacks", async () => {
    const current = cardBlock();
    const { wrapper, adapter, state } = setup({ block: current });
    const click = capturedAction(wrapper, "edit");
    const detail = capturedClick(wrapper, "data-row-detail");
    click();
    expect(adapter.emitted("rowAction")?.[0]).toEqual([
      current.actions[0],
      current.rows[0],
      originalInput,
    ]);
    expect(toRaw(adapter.emitted("rowAction")![0][2])).toBe(originalInput);
    expect(
      (adapter.emitted("rowAction")![0][0] as { confirm: string }).confirm,
    ).toBe("Review this setting change");
    expect(adapter.emitted("openRow")).toBeUndefined();
    detail();
    expect(adapter.emitted("openRow")?.[0]).toEqual([current.rows[0]]);
    state.block = {
      ...current,
      rows: [
        {
          ...current.rows[0],
          actions: [
            {
              id: "edit",
              input: { ...originalInput, expectedRevision: "new" },
            },
          ],
        },
      ],
    };
    await nextTick();
    click();
    detail();
    expect(adapter.emitted("rowAction")).toHaveLength(1);
    expect(adapter.emitted("openRow")).toHaveLength(1);
    const currentClick = capturedAction(wrapper, "edit");
    state.block = { ...(state.block as FlarePluginRowsBlock), actions: [] };
    await nextTick();
    currentClick();
    expect(adapter.emitted("rowAction")).toHaveLength(1);
  });

  it("locks card callbacks and cursor reads while busy and rejects a previous cursor snapshot", async () => {
    const current = { ...cardBlock(), nextCursor: "original-cursor" };
    const { wrapper, adapter, list, state } = setup({
      block: current,
      pagination: undefined,
    });
    const action = capturedAction(wrapper, "edit");
    const detail = capturedClick(wrapper, "data-row-detail");
    const more = capturedClick(wrapper, "data-rows-load-more");
    expect(wrapper.findAll("[data-rows-load-more]")).toHaveLength(1);
    expect(list.get(".flare-admin-list__footer").text()).toContain(
      "9 loaded items",
    );
    for (const key of ["busy", "loading", "disabled"]) {
      state[key] = true;
      await nextTick();
      for (const button of wrapper.findAll(
        "[data-row-action], [data-row-detail], [data-rows-load-more]",
      ))
        expect(button.attributes("disabled")).toBeDefined();
      action();
      detail();
      more();
      await list.get("input").trigger("keydown", { key: "Enter" });
      expect(adapter.emitted("rowAction")).toBeUndefined();
      expect(adapter.emitted("openRow")).toBeUndefined();
      expect(adapter.emitted("loadMore")).toBeUndefined();
      expect(adapter.emitted("search")).toBeUndefined();
      state[key] = false;
      await nextTick();
    }
    state.block = { ...current, nextCursor: "new-cursor" };
    await nextTick();
    more();
    expect(adapter.emitted("loadMore")).toBeUndefined();
    await wrapper.get("[data-rows-load-more]").trigger("click");
    expect(adapter.emitted("loadMore")?.[0]).toEqual(["new-cursor"]);
    const previousMore = capturedClick(wrapper, "data-rows-load-more");
    state.pagination = {
      page: 1,
      pageSize: 20,
      total: 9,
      pageSizes: [20, 50, 100],
    };
    await nextTick();
    expect(wrapper.find("[data-rows-load-more]").exists()).toBe(false);
    previousMore();
    expect(adapter.emitted("loadMore")).toHaveLength(1);
  });

  it("folds a row's actions past three into more, keeps the detail apart and spins the one in flight", async () => {
    const ids = ["publish", "edit", "simulate", "pause", "resume", "end", "disable", "inherit"];
    const inputs = ids.map((id) => ({ id: "m1", action: id }));
    const many: FlarePluginRowsBlock = {
      ...block,
      actions: ids.map((id) => ({
        id,
        label: `Do ${id}`,
        form: [],
        ...(id === "end" ? { style: "danger" as const } : {}),
      })),
      rows: [
        {
          ...block.rows[0],
          actions: ids.map((id, index) => ({ id, input: inputs[index] })),
        },
        { ...block.rows[1], actions: [{ id: "edit", input: { id: "r2" } }] },
      ],
    };
    const { wrapper, adapter, list, state } = setup({ block: many });
    const first = wrapper.findAllComponents(FlareAdminRowActions)[0];
    expect(first.props("max")).toBe(3);
    expect(first.props("label")).toBe("Full untruncated record name");
    // Two keys on the row and "more" for the other six; the detail key is
    // its own and is not counted.
    expect(first.findAll("[data-row-action]").map((key) => key.text())).toEqual([
      "Do publish",
      "Do edit",
    ]);
    const menu = first.getComponent(NDropdown);
    expect(menu.props("options")).toHaveLength(6);
    const trigger = first.get("[data-row-action-more]");
    expect(trigger.attributes("aria-haspopup")).toBe("menu");
    expect(trigger.attributes("aria-expanded")).toBe("false");
    expect(trigger.attributes("aria-label")).toBe(
      "More actions for Full untruncated record name",
    );
    expect(
      (first.props("actions") as readonly { key: string; danger?: boolean }[]).find(
        (action) => action.key === "end",
      )?.danger,
    ).toBe(true);
    expect(wrapper.findAll("[data-row-detail]")).toHaveLength(1);
    // A row with one action shows it alone; the column fits the widest row.
    const second = wrapper.findAllComponents(FlareAdminRowActions)[1];
    expect(second.findAll("[data-row-action]")).toHaveLength(1);
    expect(second.find("[data-row-action-more]").exists()).toBe(false);
    expect(list.props("rowActionsWidth")).toBe(240);
    // A key in the menu runs its action with the row's exact input.
    menu.vm.$emit("select", "disable");
    expect(adapter.emitted("rowAction")?.[0]).toEqual([
      many.actions[6],
      many.rows[0],
      inputs[6],
    ]);
    expect(toRaw(adapter.emitted("rowAction")![0][2])).toBe(inputs[6]);
    await first.get('[data-row-action="edit"]').trigger("click");
    expect(adapter.emitted("rowAction")?.[1]?.[2]).toEqual(inputs[1]);
    // The action in flight spins where it is drawn: its key, or "more".
    state.busyActionId = "edit";
    state.busyRow = "r1";
    await nextTick();
    expect(
      wrapper.findAllComponents(FlareAdminRowActions)[0].findAllComponents(NButton)[1].props("loading"),
    ).toBe(true);
    state.busyActionId = "end";
    await nextTick();
    const busyMore = wrapper.findAllComponents(FlareAdminRowActions)[0];
    expect(busyMore.get("[data-row-action-more]").attributes("disabled")).toBeDefined();
    expect(
      busyMore.findAllComponents(NButton).find((key) => key.attributes("data-row-action-more") !== undefined)!.props("loading"),
    ).toBe(true);
    // Only the row in flight spins.
    expect(
      wrapper.findAllComponents(FlareAdminRowActions)[1].findAllComponents(NButton)[0].props("loading"),
    ).toBe(false);
  });

  it("folds card actions past three into more as well", () => {
    const ids = ["publish", "edit", "pause", "end"];
    const cards: FlarePluginRowsBlock = {
      ...cardBlock(),
      actions: ids.map((id) => ({ id, label: `Do ${id}`, form: [] })),
      rows: [
        {
          ...block.rows[0],
          actions: ids.map((id) => ({ id, input: { id: "r1", action: id } })),
        },
      ],
    };
    const { wrapper, adapter } = setup({ block: cards });
    const actions = wrapper.getComponent(FlareAdminRowActions);
    expect(actions.findAll("[data-row-action]").map((key) => key.text())).toEqual([
      "Do publish",
      "Do edit",
    ]);
    expect(actions.getComponent(NDropdown).props("options")).toHaveLength(2);
    expect(wrapper.findAll("[data-row-detail]")).toHaveLength(1);
    actions.getComponent(NDropdown).vm.$emit("select", "end");
    expect(adapter.emitted("rowAction")?.[0]?.[2]).toEqual({ id: "r1", action: "end" });
  });

  it("reuses one native query, action toolbar, column chooser and complete identity/time table", () => {
    const { wrapper, list } = setup();
    expect(wrapper.findAllComponents(FlareAdminList)).toHaveLength(1);
    expect(wrapper.findAllComponents(NDataTable)).toHaveLength(1);
    expect(wrapper.findAllComponents(NForm)).toHaveLength(1);
    expect(wrapper.findAll("form form")).toHaveLength(0);
    expect(wrapper.findAll(".flare-admin-list__toolbar")).toHaveLength(1);
    expect(wrapper.find(".flare-admin-list__settings-trigger").exists()).toBe(
      true,
    );
    expect(wrapper.text()).toContain("Create record");
    expect(wrapper.text()).toContain("Export records");
    expect(wrapper.text()).toContain("Pending");
    expect(wrapper.text()).toContain("alice.full.account");
    expect(wrapper.text()).toContain("Full untruncated record name");
    expect(wrapper.text()).not.toContain("expectedRevision");
    expect(wrapper.text()).not.toContain("1730000000000");
    expect(list.findComponent(NDataTable).props("data")).toHaveLength(3);
    expect(
      list
        .props("columns")
        .every((column: { ellipsis?: unknown }) => column.ellipsis === false),
    ).toBe(true);
    expect(wrapper.find(".is-ellipsis").exists()).toBe(false);
  });

  it("preserves the exact declared row action and detail input without treating a button as a row click", async () => {
    const { wrapper, adapter } = setup();
    await wrapper.get('[data-row-action="edit"]').trigger("click");
    const action = adapter.emitted("rowAction")![0];
    expect(action[0]).toEqual(block.actions[0]);
    expect(toRaw(action[1])).toBe(block.rows[0]);
    expect(toRaw(action[2])).toBe(originalInput);
    expect(adapter.emitted("openRow")).toBeUndefined();
    await wrapper.get("[data-row-detail]").trigger("click");
    expect(adapter.emitted("openRow")?.[0]).toEqual([block.rows[0]]);
  });

  it("emits controlled page and page-size changes without slicing rows or mutating the supplied snapshot", async () => {
    const { adapter, list, state } = setup();
    const pager = list.getComponent(NPagination);
    pager.vm.$emit("update:page", 3);
    await nextTick();
    expect(adapter.emitted("update:pagination")?.[0]).toEqual([
      { page: 3, pageSize: 1, total: 20, pageSizes: [1, 2] },
    ]);
    pager.vm.$emit("update:pageSize", 2);
    await nextTick();
    expect(adapter.emitted("update:pagination")?.[1]).toEqual([
      { page: 1, pageSize: 2, total: 20, pageSizes: [1, 2] },
    ]);
    expect(state.pagination).toEqual({
      page: 2,
      pageSize: 1,
      total: 20,
      pageSizes: [1, 2],
    });
    expect(list.getComponent(NDataTable).props("data")).toHaveLength(3);
  });

  it("locks queries, paging, row actions and details while loading or disabled", async () => {
    for (const locked of [{ loading: true }, { disabled: true }]) {
      const { wrapper, adapter, list } = setup(locked);
      for (const button of wrapper.findAll(
        "[data-row-action], [data-row-detail]",
      )) {
        expect(button.attributes("disabled")).toBeDefined();
        await button.trigger("click");
      }
      list.getComponent(NPagination).vm.$emit("update:page", 3);
      const input = list.get("input");
      await input.trigger("keydown", { key: "Enter" });
      expect(adapter.emitted("rowAction")).toBeUndefined();
      expect(adapter.emitted("openRow")).toBeUndefined();
      expect(adapter.emitted("update:pagination")).toBeUndefined();
      expect(adapter.emitted("search")).toBeUndefined();
    }
  });

  it("retains neutral read errors and retry controls with cursor paging and no colored strip", async () => {
    const { wrapper, adapter, list } = setup({
      error: "Reader unavailable",
      pagination: { page: 2, pageSize: 3, hasNext: true },
    });
    expect(wrapper.text()).toContain("Reader unavailable");
    expect(wrapper.text()).toContain("Retry reading");
    expect(wrapper.find(".n-alert, .flare-status-banner").exists()).toBe(false);
    expect(list.findComponent(NPagination).exists()).toBe(false);
    expect(list.get(".flare-admin-list__total").text()).not.toContain("20");
    await list.get('button[aria-label="Next page"]').trigger("click");
    expect(adapter.emitted("update:pagination")?.[0]).toEqual([
      { page: 3, pageSize: 3, hasNext: true },
    ]);
    list.vm.$emit("update:visibleColumnKeys", ["c0"]);
    await nextTick();
    expect(adapter.emitted("update:visibleColumnKeys")?.[0]).toEqual([["c0"]]);
  });

  it("keeps cursor reads and their honest loaded count inside the shared list footer", async () => {
    const { wrapper, adapter, list, state } = setup({
      pagination: undefined,
      block: { ...block, nextCursor: "opaque-next" },
    });
    expect(wrapper.findAllComponents(FlareAdminList)).toHaveLength(1);
    const footer = list.get(".flare-admin-list__footer");
    expect(footer.text()).toContain("3 loaded items");
    expect(footer.text()).not.toContain("of 20");
    expect(list.findComponent(NPagination).exists()).toBe(false);
    expect(wrapper.findAll("[data-rows-load-more]")).toHaveLength(1);
    await footer.get("[data-rows-load-more]").trigger("click");
    expect(adapter.emitted("loadMore")?.[0]).toEqual(["opaque-next"]);

    state.block = { ...block, rows: [] };
    await nextTick();
    expect(list.get(".flare-admin-list__footer").text()).toContain(
      "0 loaded items",
    );
    expect(wrapper.find("[data-rows-load-more]").exists()).toBe(false);
  });
});
