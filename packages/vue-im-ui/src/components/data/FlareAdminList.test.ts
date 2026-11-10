// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, reactive, ref } from "vue";
import {
  NButton,
  NCheckbox,
  NDataTable,
  NForm,
  NFormItem,
  NInput,
  NPagination,
  NPopover,
  NSelect,
} from "naive-ui";
import FlareAdminList from "./FlareAdminList.vue";
import FlareDrawer from "../general/FlareDrawer.vue";
import FlareAdminModal from "../form/FlareAdminModal.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  document.body.innerHTML = "";
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});
function layout(columns = 2, width = 1200) {
  const callbacks: (() => void)[] = [];
  vi.stubGlobal(
    "ResizeObserver",
    class {
      constructor(callback: () => void) {
        callbacks.push(callback);
      }
      observe() {}
      disconnect() {}
    },
  );
  const original = HTMLElement.prototype.getBoundingClientRect;
  vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockImplementation(
    function (this: HTMLElement) {
      if (this.classList.contains("flare-admin-list"))
        return new DOMRect(0, 0, width, 800);
      if (this.classList.contains("flare-admin-list__fields"))
        return new DOMRect(0, 0, width, 200);
      if (this.classList.contains("flare-admin-list__field")) {
        const index = Array.from(this.parentElement!.children).indexOf(this);
        return new DOMRect(
          (index % columns) * 290,
          Math.floor(index / columns) * 44,
          280,
          32,
        );
      }
      return original.call(this);
    },
  );
  return async (nextColumns = columns, nextWidth = width) => {
    columns = nextColumns;
    width = nextWidth;
    callbacks[0]();
    await nextTick();
  };
}
function setup(props = {}, slots = {}) {
  const value = ref("retained");
  const state = reactive<Record<string, unknown>>(props);
  const host = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () =>
          h(
            FlareAdminList,
            {
              label: "Users",
              rowKey: "id",
              columns: [
                { key: "name", title: "Name", hideable: false },
                { key: "email", title: "Email" },
              ],
              rows: [{ id: "1", name: "Alice", email: "a@example.invalid" }],
              pagination: {
                page: 1,
                pageSize: 10,
                total: 40,
                pageSizes: [10, 20],
              },
              ...state,
            },
            {
              filters: () =>
                ["First", "Second", "Third"].map((label) =>
                  h(NFormItem, { label }, () =>
                    h(NInput, {
                      value: value.value,
                      "onUpdate:value": (next) => (value.value = next),
                    }),
                  ),
                ),
              actions: () =>
                h(NButton, { type: "primary" }, () => "Create user"),
              ...slots,
            },
          );
      },
    }),
    { attachTo: document.body },
  );
  hosts.push(host);
  return {
    host,
    list: host.findComponent(FlareAdminList),
    value,
    set: async (patch: Record<string, unknown>) => {
      Object.assign(state, patch);
      await nextTick();
    },
  };
}
describe("FlareAdminList / Naive UI composition", () => {
  it("passes native tree children and controlled expansion without selecting or flattening nodes", async () => {
    layout();
    const rows = [
      { id: "root", name: "Menu", children: [{ id: "child", name: "Button" }] },
    ];
    const { list } = setup({ rows, expandedRowKeys: ["root"] });
    const table = list.findComponent(NDataTable);
    expect(table.props("data")).toEqual(rows);
    expect(table.props("expandedRowKeys")).toEqual(["root"]);
    table.vm.$emit("update:expandedRowKeys", []);
    await nextTick();
    expect(list.emitted("update:expandedRowKeys")).toEqual([[[]]]);
    expect(list.emitted("update:checkedRowKeys")).toBeUndefined();
    expect(rows[0].children).toHaveLength(1);
  });
  it("locks native expansion while loading without changing flat list defaults", async () => {
    layout();
    const { list, set } = setup();
    expect(
      list.findComponent(NDataTable).props("expandedRowKeys"),
    ).toBeUndefined();
    await set({ loading: true, expandedRowKeys: ["root"] });
    list.findComponent(NDataTable).vm.$emit("update:expandedRowKeys", []);
    expect(list.emitted("update:expandedRowKeys")).toBeUndefined();
    expect(list.findComponent(NDataTable).props("expandedRowKeys")).toEqual([
      "root",
    ]);
  });
  it.each([
    ["drawer", FlareDrawer],
    ["modal", FlareAdminModal],
  ] as const)(
    "closes only the column chooser from its focused trigger inside a %s",
    async (_kind, Surface) => {
      const close = vi.fn();
      const host = mount(
        defineComponent({
          setup() {
            useFlareI18nProvider("zh-CN");
            return () =>
              h(Surface, { open: true, title: "Details", onClose: close }, () =>
                h(FlareAdminList, {
                  label: "Records",
                  rowKey: "id",
                  embedded: true,
                  columns: [{ key: "name", title: "Name" }],
                  rows: [{ id: "1", name: "Retained" }],
                }),
              );
          },
        }),
        { attachTo: document.body },
      );
      hosts.push(host);
      await nextTick();
      await nextTick();
      const trigger = document.querySelector<HTMLButtonElement>(
        '[aria-label="Details"] .flare-admin-list__settings-trigger button',
      )!;
      trigger.focus();
      trigger.click();
      await nextTick();
      expect(trigger.getAttribute("aria-expanded")).toBe("true");
      trigger.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Escape",
          bubbles: true,
          cancelable: true,
        }),
      );
      await nextTick();
      expect(trigger.getAttribute("aria-expanded")).toBe("false");
      expect(close).not.toHaveBeenCalled();
      expect(document.activeElement).toBe(trigger);
      expect(document.body.style.overflow).toBe("hidden");
      const list = host.findComponent(FlareAdminList);
      expect(list.emitted("update:visibleColumnKeys")).toBeUndefined();
      expect(list.emitted("rowClick")).toBeUndefined();
      trigger.click();
      await nextTick();
      const menu = document.querySelector<HTMLElement>(
        ".flare-admin-list__columns",
      )!;
      menu.querySelector<HTMLElement>('[role="checkbox"]')?.focus();
      menu.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Escape",
          bubbles: true,
          cancelable: true,
        }),
      );
      await nextTick();
      expect(trigger.getAttribute("aria-expanded")).toBe("false");
      expect(close).not.toHaveBeenCalled();
      expect(document.activeElement).toBe(trigger);
      // Once the chooser is closed, Escape belongs to the host again.
      trigger.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Escape",
          bubbles: true,
          cancelable: true,
        }),
      );
      expect(close).toHaveBeenCalledOnce();
    },
  );
  it("labels bounded loaded snapshots without claiming an authoritative server-wide total", () => {
    const { list } = setup({
      pagination: { page: 1, pageSize: 10, total: 40, totalKind: "loaded" },
    });
    expect(list.get(".flare-admin-list__total").text()).toBe(
      "第 1–1 条，已加载 40 条",
    );
    expect(list.findComponent(NPagination).props("itemCount")).toBe(40);
  });
  it("rejects a captured cursor callback after its page/context snapshot changes", async () => {
    const { list, set } = setup({
      pagination: { page: 2, pageSize: 10, hasNext: true },
    });
    const next = list
      .findAllComponents(NButton)
      .find((button) => button.attributes("aria-label") === "下一页")!;
    const old = next.vm.$.vnode.props!.onClick as () => void;
    await set({ pagination: { page: 1, pageSize: 10, hasNext: false } });
    old();
    expect(list.emitted("update:pagination")).toBeUndefined();
  });
  it("keeps unknown totals as cursor navigation without an invented last page or global count", async () => {
    const { list } = setup({
      pagination: { page: 3, pageSize: 10, hasNext: false },
    });
    expect(list.findComponent(NPagination).exists()).toBe(false);
    expect(list.text()).toContain("第 3 页");
    expect(list.get(".flare-admin-list__total").text()).toBe("本页 1 条");
    expect(
      list.get('button[aria-label="下一页"]').attributes("disabled"),
    ).toBeDefined();
    await list.get('button[aria-label="上一页"]').trigger("click");
    expect(list.emitted("update:pagination")?.[0]).toEqual([
      { page: 2, pageSize: 10, hasNext: false },
    ]);
  });
  it("preserves a function row key and cell/action slots without cloning business rows", () => {
    const row = { id: "7", name: "Original" };
    const { list } = setup(
      { rows: [row], rowKey: (r: typeof row) => "kind:" + r.id },
      {
        "cell-name": ({ row: current }: { row: typeof row }) =>
          h("strong", current.name),
        "row-actions": ({ row: current }: { row: typeof row }) =>
          h(NButton, {}, () => "Open " + current.id),
      },
    );
    expect(list.findComponent(NDataTable).props("rowKey")!(row)).toBe("kind:7");
    expect(list.findComponent(NDataTable).props("data")![0].id).toBe("7");
    expect(list.get("strong").text()).toBe("Original");
    expect(list.text()).toContain("Open 7");
  });
  it("groups the reserved actions column once without treating audit action data as controls", async () => {
    const edit = vi.fn(),
      suspend = vi.fn();
    const { list } = setup({
      columns: [
        { key: "name", title: "Name" },
        {
          key: "action",
          title: "Audit action",
          render: () => "catalog.update",
        },
        {
          key: "actions",
          title: "Application operations",
          render: (row: { id: string }) => [
            h(
              NButton,
              { text: true, type: "primary", onClick: () => edit(row.id) },
              () => "Edit",
            ),
            h(
              NButton,
              { text: true, type: "warning", disabled: true, onClick: suspend },
              () => "Suspend",
            ),
          ],
        },
      ],
    });
    const group = list.get(
      '[role="group"][aria-label="Application operations"]',
    );
    expect(group.classes()).toContain("flare-admin-actions");
    expect(group.findAll("button")).toHaveLength(2);
    await group.findAll("button")[0].trigger("click");
    await group.findAll("button")[1].trigger("click");
    expect(edit).toHaveBeenCalledWith("1");
    expect(suspend).not.toHaveBeenCalled();
    expect(list.text()).toContain("catalog.update");
    expect(
      list.find('[role="group"][aria-label="Audit action"]').exists(),
    ).toBe(false);
  });
  it("never selects an ineligible owner through select-all, and write-locks selection separately from reading", async () => {
    const { list, set } = setup({
      selectable: true,
      rows: [
        { id: "owner", name: "Owner" },
        { id: "member", name: "Member" },
      ],
      rowSelectable: (row: { id: string }) => row.id !== "owner",
    });
    const checkboxes = list.findAllComponents(NCheckbox);
    expect(checkboxes[1].props("disabled")).toBe(true);
    checkboxes[0].vm.$emit("update:checked", true);
    await nextTick();
    expect(list.emitted("update:checkedRowKeys")?.at(-1)).toEqual([["member"]]);
    await set({ selectionDisabled: true });
    expect(list.findComponent(NPagination).props("disabled")).toBeFalsy();
    expect(
      list.findAllComponents(NCheckbox).every((c) => c.props("disabled")),
    ).toBe(true);
  });
  it("hides empty notices and retains guarded error/reconciliation notices", () => {
    const { list } = setup({}, { notice: () => [] });
    expect(list.find(".flare-admin-list__notice").exists()).toBe(false);
  });
  it("uses the host custom query actions once instead of adding a second reset/search row", () => {
    const { list } = setup(
      {},
      { "query-actions": () => h(NButton, {}, () => "Scoped refresh") },
    );
    const actions = list.get(".flare-admin-list__query-actions");
    expect(actions.text()).toContain("Scoped refresh");
    expect(actions.text()).not.toContain("重置");
    expect(list.findAll(".flare-admin-list__toolbar")).toHaveLength(1);
  });
  it("shows host errors and loading without inventing empty results, and locks paging while loading", () => {
    const { list } = setup({
      loading: true,
      error: "Current application request failed",
    });
    expect(list.text()).toContain("Current application request failed");
    expect(list.findComponent(NDataTable).props("loading")).toBe(true);
    expect(list.findComponent(NPagination).props("disabled")).toBe(true);
    expect(list.get(".flare-admin-list__total").text()).toBe("正在加载");
  });
  it("retains persistent failure and retry controls without a notification strip when the host owns messages", async () => {
    const retry = vi.fn();
    const { list, set } = setup(
      { error: "Request unavailable", errorPresentation: "neutral" },
      { "error-actions": () => h(NButton, { onClick: retry }, () => "Retry") },
    );
    expect(list.find(".n-alert").exists()).toBe(false);
    const state = list.get('[role="status"]');
    expect(state.text()).toContain("Request unavailable");
    await state.get("button").trigger("click");
    expect(retry).toHaveBeenCalledTimes(1);
    await set({ error: "" });
    expect(list.find('[role="status"]').exists()).toBe(false);
  });
  it("renders genuine empty data with zero total and no selection column for a read-only host", () => {
    const { list } = setup({
      rows: [],
      pagination: { page: 1, pageSize: 10, total: 0 },
    });
    expect(list.findComponent(NDataTable).props("data")).toEqual([]);
    expect(
      (list.findComponent(NDataTable).props("columns") ?? []).some(
        (column) => column.type === "selection",
      ),
    ).toBe(false);
    expect(list.get(".flare-admin-list__total").text()).toBe("共 0 条");
  });
  it("uses actual Naive form/table/pagination and one action/settings toolbar, without duplicate heading or statistics", () => {
    const { list } = setup();
    expect(list.findComponent(NForm).exists()).toBe(true);
    expect(list.findComponent(NDataTable).exists()).toBe(true);
    expect(list.findComponent(NPagination).exists()).toBe(true);
    expect(list.findComponent(NDataTable).props("remote")).toBe(true);
    const toolbar = list.get(".flare-admin-list__toolbar");
    expect(toolbar.text()).toContain("Create user");
    expect(toolbar.text()).toContain("列设置");
    expect(list.find("h1, .n-statistic").exists()).toBe(false);
    expect(list.findAll(".flare-admin-list__toolbar")).toHaveLength(1);
    expect(list.get(".flare-admin-list__footer").text()).toContain(
      "第 1–1 条，共 40 条",
    );
  });
  it("preserves the host render function and leaves all data, permissions and paging to the host", () => {
    const { list } = setup({
      columns: [
        {
          key: "name",
          title: "Name",
          render: (row: { name: string }) => h("strong", `User: ${row.name}`),
        },
      ],
    });
    expect(list.get("strong").text()).toBe("User: Alice");
    expect(list.findComponent(NDataTable).props("pagination")).toBe(false);
  });
  it("folds actual extra rows without duplicate controls or lost values", async () => {
    layout();
    const { list, value } = setup();
    await nextTick();
    expect(list.findAll(".flare-admin-list__field")).toHaveLength(3);
    expect(list.findAll(".is-folded")).toHaveLength(1);
    expect(list.get(".is-folded").attributes("inert")).toBeDefined();
    expect(list.get(".is-folded").attributes("aria-hidden")).toBe("true");
    await list.get(".flare-admin-list__expand").trigger("click");
    const inputs = list
      .findAllComponents(NInput)
      .filter((input) => input.props("value") === "retained");
    expect(inputs).toHaveLength(3);
    inputs[2].vm.$emit("update:value", "changed");
    await nextTick();
    await list.get(".flare-admin-list__expand").trigger("click");
    expect(value.value).toBe("changed");
    expect(list.findAll(".is-folded")).toHaveLength(1);
  });
  it("hides expansion on one real row and reacts to width, not a fixed count", async () => {
    const resize = layout(4);
    const { list } = setup();
    await nextTick();
    expect(list.get(".flare-admin-list__expand").classes()).toContain(
      "is-unneeded",
    );
    await resize(1, 390);
    expect(list.findAll(".is-folded")).toHaveLength(2);
    expect(list.findComponent(NForm).props("labelPlacement")).toBe("top");
    expect(list.findComponent(NPagination).props("simple")).toBe(true);
    await resize(4, 1800);
    expect(list.find(".is-folded").exists()).toBe(false);
    expect(list.findComponent(NForm).props("labelPlacement")).toBe("left");
  });
  it("keeps focused inputs visible when resize would hide them", async () => {
    const resize = layout(4);
    const { list } = setup();
    await nextTick();
    (
      list.findAll(".flare-admin-list__field input")[2]
        .element as HTMLInputElement
    ).focus();
    await resize(1);
    expect(list.find(".is-folded").exists()).toBe(false);
    expect(
      list.get(".flare-admin-list__expand").attributes("aria-expanded"),
    ).toBe("true");
  });
  it("searches with plain Enter but not IME commits, open comboboxes or modified Enter", async () => {
    const { list } = setup();
    const input = list.get(".flare-admin-list__field input");
    await input.trigger("keydown", { key: "Enter", isComposing: true });
    await input.trigger("keydown", { key: "Enter", shiftKey: true });
    input.element.setAttribute("aria-expanded", "true");
    await input.trigger("keydown", { key: "Enter" });
    expect(list.emitted("search")).toBeUndefined();
    input.element.removeAttribute("aria-expanded");
    await input.trigger("keydown", { key: "Enter" });
    expect(list.emitted("search")).toHaveLength(1);
  });
  it("keeps a guarded page-size picker beside the compact numbered pager", async () => {
    const resize = layout();
    const { list, set } = setup();
    await resize(1, 390);
    const picker = list
      .get(".flare-admin-list__compact-page-size")
      .findComponent(NSelect);
    expect(picker.props("options")).toEqual([
      { value: 10, label: "每页 10 条" },
      { value: 20, label: "每页 20 条" },
    ]);
    expect(list.findComponent(NPagination).props("simple")).toBe(true);
    picker.vm.$emit("update:value", 20);
    expect(list.emitted("update:pagination")).toEqual([
      [{ page: 1, pageSize: 20, total: 40, pageSizes: [10, 20] }],
    ]);
    await set({ disabled: true });
    expect(picker.props("disabled")).toBe(true);
    picker.vm.$emit("update:value", 20);
    expect(list.emitted("update:pagination")).toHaveLength(1);
  });
  it("locks query, reset, selection and pagination during writes", async () => {
    const { list } = setup({ disabled: true, selectable: true });
    const buttons = list.findAllComponents(NButton);
    buttons[0].vm.$emit("click");
    buttons[1].vm.$emit("click");
    list.findComponent(NDataTable).vm.$emit("update:checkedRowKeys", ["1"]);
    list.findComponent(NPagination).vm.$emit("update:page", 2);
    list.findComponent(NPagination).vm.$emit("update:pageSize", 20);
    expect(list.emitted("search")).toBeUndefined();
    expect(list.emitted("reset")).toBeUndefined();
    expect(list.emitted("update:checkedRowKeys")).toBeUndefined();
    expect(list.emitted("update:pagination")).toBeUndefined();
  });
  it("names the native checkboxes and uses the real checked callback without weakening the write guard", async () => {
    const { list, set } = setup({ selectable: true });
    const boxes = list.findAllComponents(NCheckbox);
    expect(boxes[0].attributes("aria-label")).toBe("全选本页");
    expect(boxes[1].attributes("aria-label")).toBe("选择第 1 行");
    boxes[1].vm.$emit("update:checked", true);
    expect(list.emitted("update:checkedRowKeys")).toEqual([[["1"]]]);
    await set({ disabled: true });
    expect(
      list.findAllComponents(NCheckbox)[1].attributes("aria-disabled"),
    ).toBe("true");
    list.findAllComponents(NCheckbox)[1].vm.$emit("update:checked", false);
    expect(list.emitted("update:checkedRowKeys")).toHaveLength(1);
  });
  it("accepts only current rows for selection and rejects a callback from a prior row generation", async () => {
    const { list, set } = setup({ selectable: true });
    const table = list.findComponent(NDataTable);
    table.vm.$emit("update:checkedRowKeys", ["foreign"]);
    expect(list.emitted("update:checkedRowKeys")).toBeUndefined();
    const old = table.vm.$props["onUpdate:checkedRowKeys"] as (
      keys: string[],
    ) => void;
    // Model ownership lives outside the table. A stale callback may not clear a new page selection.
    await set({ rows: [{ id: "2", name: "Bob" }] });
    old(["1"]);
    expect(list.emitted("update:checkedRowKeys")).toBeUndefined();
    table.vm.$emit("update:checkedRowKeys", ["2"]);
    expect(list.emitted("update:checkedRowKeys")).toEqual([[["2"]]]);
  });
  it("resets to page one on size changes and validates boundaries and stale paging callbacks", async () => {
    const { list, set } = setup();
    const pager = list.findComponent(NPagination);
    pager.vm.$emit("update:page", 99);
    pager.vm.$emit("update:pageSize", 999);
    expect(list.emitted("update:pagination")).toBeUndefined();
    pager.vm.$emit("update:page", 2);
    expect(list.emitted("update:pagination")?.[0]).toEqual([
      { page: 2, pageSize: 10, total: 40, pageSizes: [10, 20] },
    ]);
    pager.vm.$emit("update:pageSize", 20);
    expect(list.emitted("update:pagination")?.[1]).toEqual([
      { page: 1, pageSize: 20, total: 40, pageSizes: [10, 20] },
    ]);
    const old = pager.vm.$props["onUpdate:page"] as (page: number) => void;
    await set({ pagination: { page: 1, pageSize: 10, total: 1 } });
    old(2);
    expect(list.emitted("update:pagination")).toHaveLength(2);
  });
  it("keeps required columns visible and prevents hiding the final displayed column", async () => {
    const { list } = setup({ visibleColumnKeys: [] });
    expect(list.findComponent(NDataTable).props("columns")).toHaveLength(1);
    list.findComponent(NPopover).vm.$emit("update:show", true);
    await nextTick();
    const boxes = list.findAllComponents(NCheckbox);
    expect(boxes.length).toBe(2);
    expect(boxes[0].props("disabled")).toBe(true);
    boxes[0].vm.$emit("update:checked", false);
    expect(list.emitted("update:visibleColumnKeys")).toBeUndefined();
    boxes[1].vm.$emit("update:checked", true);
    expect(list.emitted("update:visibleColumnKeys")).toEqual([
      [["name", "email"]],
    ]);
  });
});

describe("resource card layout", () => {
  it("renders resource slots without table controls and retains cursor paging and busy guards", async () => {
    layout();
    const inspect = vi.fn();
    const { list, set } = setup(
      { layout: "cards", pagination: { page: 1, pageSize: 25, hasNext: true } },
      {
        item: ({
          row,
          disabled,
        }: {
          row: Record<string, unknown>;
          disabled: boolean;
        }) =>
          h("article", [
            h("h3", String(row.name)),
            h("button", { disabled, onClick: inspect }, "Inspect"),
          ]),
      },
    );
    expect(list.findComponent(NDataTable).exists()).toBe(false);
    expect(list.find(".flare-admin-list__settings-trigger").exists()).toBe(
      false,
    );
    expect(list.get('[role="region"]').attributes("aria-label")).toBe("Users");
    expect(list.get("article").text()).toContain("Alice");
    await list.get("article button").trigger("click");
    expect(inspect).toHaveBeenCalledOnce();
    const next = list.findAll(".flare-admin-list__cursor button").at(-1)!;
    await next.trigger("click");
    expect(list.emitted("update:pagination")?.at(-1)).toEqual([
      { page: 2, pageSize: 25, hasNext: true },
    ]);
    await set({ loading: true });
    expect(list.get('[role="region"]').attributes("aria-busy")).toBe("true");
    expect(list.get("article button").attributes("disabled")).toBeDefined();
    await list.get("article button").trigger("click");
    expect(inspect).toHaveBeenCalledOnce();
    await next.trigger("click");
    expect(list.emitted("update:pagination")).toHaveLength(1);
    await set({ loading: false, rows: [{ id: "2", name: "Bob" }] });
    expect(list.get("article").text()).toContain("Bob");
    expect(list.text()).not.toContain("Alice");
  });
  it("announces loading and uses the shared empty/error state without a phantom table", async () => {
    layout();
    const { list, set } = setup({ layout: "cards", rows: [], loading: true });
    expect(list.find('[role="status"]').exists()).toBe(true);
    expect(list.findComponent(NDataTable).exists()).toBe(false);
    await set({ loading: false, error: "Read failed" });
    expect(list.text()).toContain("Read failed");
    expect(list.get(".flare-admin-list__card-empty").text()).not.toBe("");
  });
  it("keeps the shared query bar for a content page without a table or empty column chooser", async () => {
    layout();
    const search = vi.fn();
    const { list } = setup(
      { layout: "content", pagination: undefined, onSearch: search },
      {
        actions: () => [],
        content: () => h("section", { class: "policy-sections" }, "Effective policy"),
      },
    );
    expect(list.findComponent(NDataTable).exists()).toBe(false);
    expect(list.find(".flare-admin-list__toolbar").exists()).toBe(false);
    expect(list.find(".flare-admin-list__footer").exists()).toBe(false);
    expect(list.get(".flare-admin-list__content .policy-sections").text()).toBe(
      "Effective policy",
    );
    expect(list.findAll(".flare-admin-list__field")).toHaveLength(3);
    await list.get(".flare-admin-list__query-actions button").trigger("click");
    expect(search).toHaveBeenCalledOnce();
  });
  it("draws a content page's toolbar only when it has actions", async () => {
    layout();
    const { list } = setup({ layout: "content", pagination: undefined }, {
      content: () => h("p", "Readings"),
    });
    const toolbar = list.get(".flare-admin-list__toolbar");
    expect(toolbar.text()).toContain("Create user");
    expect(toolbar.findComponent(NPopover).exists()).toBe(false);
  });
});
