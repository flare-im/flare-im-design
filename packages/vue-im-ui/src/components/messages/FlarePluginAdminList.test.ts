// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, reactive, toRaw } from "vue";
import {
  NButton,
  NDataTable,
  NForm,
  NFormItem,
  NInput,
  NPagination,
} from "naive-ui";
import FlareAdminList from "../data/FlareAdminList.vue";
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
    const click = capturedClick(wrapper, "data-row-action");
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
    const currentClick = capturedClick(wrapper, "data-row-action");
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
    const action = capturedClick(wrapper, "data-row-action");
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
