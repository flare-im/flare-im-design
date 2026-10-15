// @vitest-environment happy-dom
import { flushPromises, mount, type VueWrapper } from "@vue/test-utils";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import FlareDataTable from "./FlareDataTable.vue";
import type { FlareDataTableColumn } from "./data-table";

const columns: FlareDataTableColumn[] = [
  { key: "name", title: "Name", hideable: false, sortable: true },
  { key: "email", title: "Email", ellipsis: true },
  { key: "role", title: "Role", align: "end" },
];
const rows = [
  { id: "u1", name: "Ada", email: "ada@example.com", role: "admin" },
  { id: "u2", name: "Bo", email: "bo@example.com", role: "member" },
  { id: "u3", name: "Cy", email: null, role: "member" },
];

// Props live in reactive state because VTU's setProps only drives the root wrapper, and the root here
// is the provider that gives the table its language and platform.
function mountTable(props: Record<string, unknown> = {}, slots: Record<string, unknown> = {}, locale: "zh-CN" | "en-US" = "en-US", layoutMode: "pc" | "h5" = "pc") {
  const state = reactive<Record<string, unknown>>({ columns, rows, ...props });
  const Host = defineComponent({
    setup: () => () => h(FlareUiProvider as Component, { themeMode: "light", locale, layoutMode }, {
      default: () => h(FlareDataTable as Component, { ...state }, slots),
    }),
  });
  const host = mount(Host, { attachTo: document.body });
  const set = async (patch: Record<string, unknown>) => {
    Object.assign(state, patch);
    await nextTick();
  };
  return { host, table: host.findComponent(FlareDataTable), set };
}
const emitted = (table: VueWrapper<unknown>, name: string) => table.emitted(name) as unknown[][] | undefined;

afterEach(() => {
  document.body.innerHTML = "";
});

describe("FlareDataTable", () => {
  it("opts into a bounded host panel without losing toolbar or pager semantics", () => {
    const { host, table } = mountTable({ fill: true, columnChooser: true,
      pagination: { page: 1, pageSize: 2, total: 6 } });
    expect(table.classes()).toContain("is-fill");
    expect(table.find('[aria-label="Pagination"]').exists()).toBe(true);
    expect(table.find('[aria-label="Next page"]').exists()).toBe(true);
    host.unmount();
  });
  it("is a named table whose headers carry aria-sort only when they sort, and whose cells are labelled", () => {
    const { host, table } = mountTable({ label: "Members" });
    const el = table.get("table");
    expect(el.attributes("role")).toBe("table");
    expect(el.attributes("aria-label")).toBe("Members");
    const headers = table.findAll("th");
    expect(headers.map((th) => th.text())).toEqual(["Name", "Email", "Role"]);
    expect(headers[0].attributes("aria-sort")).toBe("none");
    expect(headers[1].attributes("aria-sort")).toBeUndefined();
    expect(headers[2].attributes("data-align")).toBe("end");
    const cells = table.findAll("tbody tr")[2].findAll("td");
    expect(cells.map((td) => td.text())).toEqual(["Cy", "", "member"]);
    expect(cells.map((td) => td.attributes("data-label"))).toEqual(["Name", "Email", "Role"]);
    expect(cells[1].attributes("title")).toBeUndefined();
    expect(table.findAll("tbody tr")[0].findAll("td")[1].attributes("title")).toBe("ada@example.com");
    // Plain rows are not focusable: nothing listens for a row activation.
    expect(table.find("tbody tr").attributes("tabindex")).toBeUndefined();
    expect(table.find("th button").exists()).toBe(true);
    expect(table.findAll("th")[1].find("button").exists()).toBe(false);
    host.unmount();
  });

  it("reports the next sort and never sorts itself: ascending, descending, then the host's order", async () => {
    const { host, table, set } = mountTable();
    await table.get("th button").trigger("click");
    expect(emitted(table, "update:sort")).toEqual([[{ key: "name", order: "asc" }]]);
    await set({ sort: { key: "name", order: "asc" } });
    expect(table.get("th").attributes("aria-sort")).toBe("ascending");
    await table.get("th button").trigger("click");
    expect(emitted(table, "update:sort")?.[1]).toEqual([{ key: "name", order: "desc" }]);
    await set({ sort: { key: "name", order: "desc" } });
    expect(table.get("th").attributes("aria-sort")).toBe("descending");
    await table.get("th button").trigger("click");
    expect(emitted(table, "update:sort")?.[2]).toEqual([null]);
    // The rows were never reordered by the table.
    expect(table.findAll("tbody tr").map((tr) => tr.find("td").text())).toEqual(["Ada", "Bo", "Cy"]);
    host.unmount();
  });

  it("selects with a tri-state header, keeps keys from other pages, and surfaces the batch toolbar", async () => {
    const { host, table, set } = mountTable({ selectable: true, selectedKeys: ["u2", "other-page"] }, {
      batch: ({ selectedKeys, selectedRows }: { selectedKeys: string[]; selectedRows: Record<string, unknown>[] }) =>
        h("button", { type: "button", class: "host-batch" }, `${selectedKeys.length}/${selectedRows.length}`),
    });
    const header = table.get("thead [role=checkbox]");
    expect(header.attributes("aria-checked")).toBe("mixed");
    expect(header.attributes("aria-label")).toBe("Select all on this page");
    const rowBoxes = table.findAll("tbody [role=checkbox]");
    expect(rowBoxes.map((box) => box.attributes("aria-checked"))).toEqual(["false", "true", "false"]);
    expect(rowBoxes[0].attributes("aria-label")).toBe("Select row 1");
    expect(table.findAll("tbody tr").map((tr) => tr.attributes("aria-selected"))).toEqual(["false", "true", "false"]);

    const toolbar = table.get("[role=toolbar]");
    expect(toolbar.attributes("aria-label")).toBe("Batch actions");
    expect(toolbar.get("[aria-live=polite]").text()).toBe("2 selected");
    expect(toolbar.get(".host-batch").text()).toBe("2/1");

    await header.trigger("click");
    expect(emitted(table, "update:selectedKeys")?.[0]).toEqual([["u2", "other-page", "u1", "u3"]]);
    await set({ selectedKeys: ["u2", "other-page", "u1", "u3"] });
    expect(table.get("thead [role=checkbox]").attributes("aria-checked")).toBe("true");
    await table.get("thead [role=checkbox]").trigger("click");
    expect(emitted(table, "update:selectedKeys")?.[1]).toEqual([["other-page"]]);

    // Unbound, the table keeps the selection itself: after the header cleared the page only the
    // other page's key is left, and row 1's box adds row 1 back on its own.
    await rowBoxes[0].trigger("click");
    expect(emitted(table, "update:selectedKeys")?.[2]).toEqual([["other-page", "u1"]]);
    host.unmount();
  });

  it("leaves selection mode on the exit key and on Escape, like every contextual layer", async () => {
    const { host, table, set } = mountTable({ selectable: true, selectedKeys: ["u1"] });
    await table.get("[aria-keyshortcuts=Escape]").trigger("click");
    expect(emitted(table, "update:selectedKeys")?.[0]).toEqual([[]]);
    await set({ selectedKeys: ["u1"] });
    await nextTick();
    window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }));
    await nextTick();
    expect(emitted(table, "update:selectedKeys")?.[1]).toEqual([[]]);
    await set({ selectedKeys: [] });
    expect(table.find("[role=toolbar]").exists()).toBe(false);
    host.unmount();
  });

  it("pages on the server: it only says which page or page size comes next", async () => {
    const { host, table, set } = mountTable({ pagination: { page: 1, pageSize: 25, total: 120, pageSizes: [10, 25, 50] } });
    const nav = table.get("nav");
    expect(nav.attributes("aria-label")).toBe("Pagination");
    expect(nav.get(".flare-data-table__range").text()).toBe("1–25 of 120");
    expect(nav.get(".flare-data-table__page").text()).toBe("Page 1 of 5");
    const [previous, next] = nav.findAll("button[aria-label]").filter((button) => ["Previous page", "Next page"].includes(button.attributes("aria-label") ?? ""));
    expect(previous.attributes("disabled")).toBeDefined();
    await next.trigger("click");
    expect(emitted(table, "update:pagination")).toEqual([[{ page: 2, pageSize: 25, total: 120, pageSizes: [10, 25, 50] }]]);
    expect(nav.get(".flare-select__trigger").attributes("aria-label")).toBe("Rows per page");
    await nav.get(".flare-select__trigger").trigger("click");
    const option = nav.findAll(".flare-select__option").find((entry) => entry.text().includes("50"));
    await option!.trigger("click");
    expect(emitted(table, "update:pagination")?.[1]).toEqual([{ page: 1, pageSize: 50, total: 120, pageSizes: [10, 25, 50] }]);
    await set({ pagination: { page: 5, pageSize: 25, total: 120 } });
    expect(table.get(".flare-data-table__range").text()).toBe("101–120 of 120");
    expect(table.find(".flare-select").exists()).toBe(false);
    await set({ pagination: { page: 1, pageSize: 25, total: 0 } });
    expect(table.get(".flare-data-table__range").text()).toBe("0 items");
    host.unmount();
  });

  it("pages a cursor source by its next-page flag, one page at a time, without inventing a total", async () => {
    const { host, table, set } = mountTable({ pagination: { page: 1, pageSize: 3, hasNext: true } });
    const nav = table.get("nav");
    const step = (label: string) => nav.findAll("button").find((button) => button.attributes("aria-label") === label)!;
    expect(nav.get(".flare-data-table__range").text()).toBe("1–3");
    expect(nav.get(".flare-data-table__page").text()).toBe("Page 1");
    expect(table.get("table").attributes("aria-rowcount")).toBe("-1");
    expect(step("Previous page").attributes("disabled")).toBeDefined();
    expect(step("Next page").attributes("disabled")).toBeUndefined();
    await step("Next page").trigger("click");
    expect(emitted(table, "update:pagination")).toEqual([[{ page: 2, pageSize: 3, hasNext: true }]]);

    // The last page: the server says there is nothing after it.
    await set({ pagination: { page: 2, pageSize: 3, hasNext: false }, rows: rows.slice(0, 2) });
    expect(table.get(".flare-data-table__range").text()).toBe("4–5");
    expect(table.get(".flare-data-table__page").text()).toBe("Page 2");
    expect(step("Next page").attributes("disabled")).toBeDefined();
    await step("Next page").trigger("click");
    await step("Previous page").trigger("click");
    expect(emitted(table, "update:pagination")?.[1]).toEqual([{ page: 1, pageSize: 3, hasNext: false }]);
    expect(emitted(table, "update:pagination")).toHaveLength(2);

    // Nothing matched at all.
    await set({ pagination: { page: 1, pageSize: 3, hasNext: false }, rows: [] });
    expect(table.get(".flare-data-table__range").text()).toBe("0 items");
    host.unmount();
  });

  it("speaks cursor paging in the kit's Chinese", () => {
    const { host, table } = mountTable({ pagination: { page: 2, pageSize: 3, hasNext: true } }, {}, "zh-CN");
    expect(table.get(".flare-data-table__range").text()).toBe("第 4–6 条");
    expect(table.get(".flare-data-table__page").text()).toBe("第 2 页");
    host.unmount();
  });

  it("lets the person choose columns, hands the choice to the host, and never hides the last one", async () => {
    const { host, table, set } = mountTable({ columnChooser: true, visibleColumns: ["name", "role"] });
    expect(table.findAll("th").map((th) => th.text())).toEqual(["Name", "Role"]);
    const trigger = table.get("[aria-haspopup=dialog]");
    expect(trigger.attributes("aria-label")).toBe("Columns");
    expect(trigger.attributes("aria-expanded")).toBe("false");
    await trigger.trigger("click");
    await flushPromises();
    const dialog = document.body.querySelector<HTMLElement>('[role="dialog"][aria-label="Columns"]');
    expect(dialog).not.toBeNull();
    expect(trigger.attributes("aria-expanded")).toBe("true");
    const boxes = Array.from(dialog!.querySelectorAll<HTMLElement>('[role="checkbox"]'));
    expect(boxes.map((box) => box.getAttribute("aria-checked"))).toEqual(["true", "false", "true"]);
    // Name cannot be hidden by contract; the others can.
    expect(boxes[0].hasAttribute("disabled")).toBe(true);
    expect(boxes[2].hasAttribute("disabled")).toBe(false);
    boxes[1].click();
    await nextTick();
    expect(emitted(table, "update:visibleColumns")?.[0]).toEqual([["name", "email", "role"]]);
    // The host did not write the choice back, so the table keeps it itself and the next change builds on it.
    boxes[2].click();
    await nextTick();
    expect(emitted(table, "update:visibleColumns")?.[1]).toEqual([["name", "email"]]);
    await set({ visibleColumns: ["name"] });
    expect(table.findAll("th").map((th) => th.text())).toEqual(["Name"]);
    expect(dialog!.querySelector<HTMLElement>('[role="checkbox"]')?.hasAttribute("disabled")).toBe(true);
    dialog!.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    await flushPromises();
    expect(trigger.attributes("aria-expanded")).toBe("false");
    host.unmount();
  });

  it("explains an empty page and holds its place while loading", async () => {
    const { host, table, set } = mountTable({ rows: [], emptyText: "No members yet" });
    expect(table.get("tbody").text()).toContain("No members yet");
    expect(table.get(".flare-data-table").attributes("aria-busy")).toBeUndefined();
    await set({ loading: true });
    expect(table.get(".flare-data-table").attributes("aria-busy")).toBe("true");
    expect(table.get("tbody [role=status]").text()).toBe("Loading");
    expect(table.find(".flare-skeleton").exists()).toBe(true);
    expect(table.find(".flare-data-table__row").exists()).toBe(false);
    host.unmount();
    const custom = mountTable({ rows: [] }, { empty: () => h("p", { class: "host-empty" }, "Nothing here") });
    expect(custom.table.get(".host-empty").text()).toBe("Nothing here");
    custom.host.unmount();
  });

  it("activates a row for a host that listens, by pointer or keyboard, but not through its checkbox", async () => {
    const clicks: unknown[] = [];
    const { host, table } = mountTable({ selectable: true, onRowClick: (row: unknown, index: number) => clicks.push([row, index]) });
    const row = table.findAll("tbody tr")[1];
    expect(row.attributes("tabindex")).toBe("0");
    await row.trigger("click");
    expect(clicks).toEqual([[rows[1], 1]]);
    await row.trigger("keydown", { key: "Enter" });
    expect(clicks).toHaveLength(2);
    await row.find("[role=checkbox]").trigger("click");
    expect(clicks).toHaveLength(2);
    expect(emitted(table, "update:selectedKeys")?.[0]).toEqual([["u2"]]);
    host.unmount();
  });

  it("renders a cell through its slot, adds a row-actions column and seats the host's toolbar in the bar", () => {
    const { host, table } = mountTable({}, {
      toolbar: () => h("input", { class: "host-filter", "aria-label": "Filter" }),
      "cell-role": ({ value, row }: { value: string; row: Record<string, unknown> }) => h("em", { class: "role" }, `${row.name}:${value}`),
      "row-actions": ({ row }: { row: Record<string, unknown> }) => h("button", { type: "button", class: "act" }, `edit ${row.name}`),
    });
    expect(table.find(".flare-data-table__bar-lead .host-filter").exists()).toBe(true);
    expect(table.find(".flare-data-table__sort-menu").exists()).toBe(false);
    expect(table.findAll("th").map((th) => th.text())).toEqual(["Name", "Email", "Role", "Actions"]);
    expect(table.findAll("tbody tr")[0].get("em.role").text()).toBe("Ada:admin");
    expect(table.findAll("tbody tr")[0].get("button.act").text()).toBe("edit Ada");
    expect(table.findAll("tbody tr")[0].findAll("td").at(-1)?.attributes("data-label")).toBe("Actions");
    host.unmount();
  });

  it("offers the column chooser as a bottom sheet on the phone form factor", async () => {
    const { host, table } = mountTable({ columnChooser: true }, {}, "en-US", "h5");
    expect(document.body.querySelector('[role="dialog"][aria-label="Columns"]')).toBeNull();
    await table.get("[aria-haspopup=dialog]").trigger("click");
    await flushPromises();
    const sheet = document.body.querySelector<HTMLElement>('[role="dialog"]');
    expect(sheet).not.toBeNull();
    const boxes = Array.from(sheet!.querySelectorAll<HTMLElement>('[role="group"][aria-label="Columns"] [role="checkbox"]'));
    expect(boxes).toHaveLength(3);
    boxes[1].click();
    await nextTick();
    expect(emitted(table, "update:visibleColumns")?.[0]).toEqual([["name", "role"]]);
    host.unmount();
  });

  it("moves sorting and select-all out of the header when its own box is narrow", async () => {
    // The measurement is a ResizeObserver on the root; here it is driven by hand.
    const original = globalThis.ResizeObserver;
    let report: ((entries: { contentRect: { width: number } }[]) => void) | null = null;
    class FakeResizeObserver {
      constructor(callback: (entries: { contentRect: { width: number } }[]) => void) { report = callback; }
      observe() {}
      disconnect() { report = null; }
    }
    globalThis.ResizeObserver = FakeResizeObserver as unknown as typeof ResizeObserver;
    try {
      const { host, table } = mountTable({ selectable: true });
      expect(report).not.toBeNull();
      report!([{ contentRect: { width: 390 } }]);
      await nextTick();
      expect(table.classes()).toContain("is-narrow");
      // The header keeps its titles and aria-sort for assistive technology, but holds no control.
      expect(table.findAll("thead th").map((th) => th.text())).toEqual(["Select", "Name", "Email", "Role"]);
      expect(table.find("thead button").exists()).toBe(false);
      expect(table.find("thead [role=checkbox]").exists()).toBe(false);
      expect(table.findAll("thead th")[1].attributes("aria-sort")).toBe("none");
      expect(table.findAll("tbody [role=checkbox]")).toHaveLength(3);
      // Sorting is the menu in the bar, built from the sortable columns only.
      const sortTrigger = table.get(".flare-data-table__sort-menu [aria-haspopup=menu]");
      await sortTrigger.trigger("click");
      await flushPromises();
      const items = Array.from(document.body.querySelectorAll<HTMLElement>('[role="menu"] [data-action-menu-item]'));
      expect(items.map((item) => item.textContent?.trim())).toEqual(["Name"]);
      items[0].click();
      await flushPromises();
      expect(emitted(table, "update:sort")).toEqual([[{ key: "name", order: "asc" }]]);
      report!([{ contentRect: { width: 900 } }]);
      await nextTick();
      expect(table.classes()).not.toContain("is-narrow");
      expect(table.find("thead button").exists()).toBe(true);
      expect(table.find(".flare-data-table__sort-menu").exists()).toBe(false);
      host.unmount();
      expect(report).toBeNull();
    } finally {
      globalThis.ResizeObserver = original;
    }
  });

  it("speaks the kit's Chinese under a Chinese kit", () => {
    const { host, table } = mountTable({ selectable: true, selectedKeys: ["u1"], pagination: { page: 1, pageSize: 25, total: 3 } }, {}, "zh-CN");
    expect(table.get("table").attributes("aria-label")).toBe("数据表格");
    expect(table.get("[role=toolbar] [aria-live=polite]").text()).toBe("已选 1 项");
    expect(table.get(".flare-data-table__range").text()).toBe("第 1–3 条，共 3 条");
    host.unmount();
  });
});

describe("FlareDataTable on narrow containers and in dark mode", () => {
  const source = readFileSync(resolve(__dirname, "FlareDataTable.vue"), "utf8");
  const style = source.slice(source.indexOf("<style"));

  it("stacks rows by its own width, keeps the header for assistive technology, and guards hover", () => {
    expect(style).toMatch(/container-name:\s*flare-data-table/);
    expect(style).toMatch(/@container flare-data-table \(max-width: 599px\)/);
    expect(style).toMatch(/content:\s*attr\(data-label\)/);
    expect(source).toMatch(/role="columnheader"/);
    expect(source).toMatch(/role="cell"/);
    expect(style).not.toMatch(/\.flare-data-table__head\s*\{\s*display:\s*none/);
    // Every hover rule sits behind (hover: hover): a touch screen must not keep a hover state after a tap.
    for (const match of style.matchAll(/:hover/g)) {
      const before = style.slice(0, match.index);
      expect(before.lastIndexOf("@media (hover: hover)")).toBeGreaterThan(before.lastIndexOf("\n}\n"));
    }
  });

  it("paints only with theme tokens, each of which dark mode redefines", () => {
    const tokens = readFileSync(resolve(__dirname, "../../../../../tokens/dist/tokens.css"), "utf8");
    const dark = /\[data-flare-theme="dark"\]\s*\{([^}]*)\}/.exec(tokens)?.[1] ?? "";
    const colours = [...new Set([...style.matchAll(/var\((--flare-color-[\w-]+)\)/g)].map((match) => match[1]))];
    expect(colours.length).toBeGreaterThan(6);
    for (const token of colours) expect(dark, `${token} has no dark value`).toContain(`${token}:`);
    expect(source).not.toMatch(/#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/);
  });
});
