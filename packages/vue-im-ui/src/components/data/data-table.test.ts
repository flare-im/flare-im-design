import { describe, expect, it } from "vitest";
import {
  dataTableAriaSort,
  dataTableCellText,
  dataTableIsCursor,
  dataTableNextSort,
  dataTablePageCount,
  dataTablePageSteps,
  dataTableRange,
  dataTableRowKey,
  dataTableSelection,
  dataTableToggleAll,
  dataTableToggleColumn,
  dataTableToggleRow,
  dataTableVisibleColumns,
  type FlareDataTableColumn,
} from "./data-table";

const columns: FlareDataTableColumn[] = [
  { key: "name", title: "Name", hideable: false },
  { key: "email", title: "Email", sortable: true },
  { key: "role", title: "Role" },
];

describe("data-table rules", () => {
  it("identifies a row by a field, by index when the field is missing, or by the host's function", () => {
    expect(dataTableRowKey({ id: 7 }, "id", 0)).toBe("7");
    expect(dataTableRowKey({ name: "a" }, "id", 3)).toBe("3");
    expect(dataTableRowKey({ a: "x", b: "y" }, (row) => `${row.a}:${row.b}`, 0)).toBe("x:y");
  });

  it("cycles a header ascending, descending, then back to the host's order", () => {
    expect(dataTableNextSort(null, "email")).toEqual({ key: "email", order: "asc" });
    expect(dataTableNextSort({ key: "email", order: "asc" }, "email")).toEqual({ key: "email", order: "desc" });
    expect(dataTableNextSort({ key: "email", order: "desc" }, "email")).toBeNull();
    // Another column starts its own cycle.
    expect(dataTableNextSort({ key: "email", order: "desc" }, "role")).toEqual({ key: "role", order: "asc" });
  });

  it("puts aria-sort only on sortable columns and only one of them is sorted", () => {
    expect(dataTableAriaSort(null, columns[0])).toBeUndefined();
    expect(dataTableAriaSort(null, columns[1])).toBe("none");
    expect(dataTableAriaSort({ key: "email", order: "asc" }, columns[1])).toBe("ascending");
    expect(dataTableAriaSort({ key: "email", order: "desc" }, columns[1])).toBe("descending");
    expect(dataTableAriaSort({ key: "role", order: "asc" }, columns[1])).toBe("none");
  });

  it("counts pages and the rows on a page, including an empty table and a page past the end", () => {
    expect(dataTablePageCount({ page: 1, pageSize: 25, total: 120 })).toBe(5);
    expect(dataTablePageCount({ page: 1, pageSize: 25, total: 0 })).toBe(1);
    expect(dataTablePageCount({ page: 1, pageSize: 25, total: 25 })).toBe(1);
    expect(dataTableRange({ page: 1, pageSize: 25, total: 120 })).toEqual({ from: 1, to: 25 });
    expect(dataTableRange({ page: 5, pageSize: 25, total: 120 })).toEqual({ from: 101, to: 120 });
    expect(dataTableRange({ page: 9, pageSize: 25, total: 120 })).toEqual({ from: 101, to: 120 });
    expect(dataTableRange({ page: 1, pageSize: 25, total: 0 })).toEqual({ from: 0, to: 0 });
  });

  it("pages a cursor source that cannot count: from the rows it passed, one page at a time", () => {
    expect(dataTableIsCursor({ page: 1, pageSize: 20 })).toBe(true);
    expect(dataTableIsCursor({ page: 1, pageSize: 20, total: Number.NaN })).toBe(true);
    expect(dataTableIsCursor({ page: 1, pageSize: 20, total: 0 })).toBe(false);
    // The rows of this page, numbered after the pages the person has walked through.
    expect(dataTableRange({ page: 1, pageSize: 20, hasNext: true }, 20)).toEqual({ from: 1, to: 20 });
    expect(dataTableRange({ page: 3, pageSize: 20 }, 7)).toEqual({ from: 1, to: 7 });
    expect(dataTableRange({ page: 1, pageSize: 20 }, 0)).toEqual({ from: 0, to: 0 });
    // No known last page: the count is the page the person is on.
    expect(dataTablePageCount({ page: 3, pageSize: 20, hasNext: true })).toBe(3);
    // Next follows the server's has_more, never a guess from a full page.
    expect(dataTablePageSteps({ page: 1, pageSize: 20, hasNext: true })).toEqual({ previous: false, next: true });
    expect(dataTablePageSteps({ page: 2, pageSize: 20 })).toEqual({ previous: true, next: false });
    expect(dataTablePageSteps({ page: 2, pageSize: 20, hasNext: false })).toEqual({ previous: true, next: false });
    // A counted source ignores hasNext.
    expect(dataTablePageSteps({ page: 5, pageSize: 25, total: 120, hasNext: true })).toEqual({ previous: true, next: false });
    expect(dataTablePageSteps({ page: 1, pageSize: 25, total: 120 })).toEqual({ previous: false, next: true });
  });

  it("shows every column until the chooser has chosen, and keeps a column that cannot be hidden", () => {
    expect(dataTableVisibleColumns(columns, null).map((column) => column.key)).toEqual(["name", "email", "role"]);
    expect(dataTableVisibleColumns(columns, ["role"]).map((column) => column.key)).toEqual(["name", "role"]);
    // The chooser's order never reorders the table.
    expect(dataTableVisibleColumns(columns, ["role", "email"]).map((column) => column.key)).toEqual(["name", "email", "role"]);
  });

  it("hides and shows a column, refusing to hide the last one or one that cannot be hidden", () => {
    expect(dataTableToggleColumn(columns, null, "role", false)).toEqual(["name", "email"]);
    expect(dataTableToggleColumn(columns, ["name", "email"], "role", true)).toEqual(["name", "email", "role"]);
    expect(dataTableToggleColumn(columns, ["name"], "name", false)).toEqual(["name"]);
    const hideable: FlareDataTableColumn[] = [{ key: "a", title: "A" }, { key: "b", title: "B" }];
    expect(dataTableToggleColumn(hideable, ["a"], "a", false)).toEqual(["a"]);
    expect(dataTableToggleColumn(hideable, ["a"], "nope", false)).toEqual(["a"]);
  });

  it("reads the header checkbox from the page, and toggles the page without touching other pages", () => {
    const page = ["1", "2", "3"];
    expect(dataTableSelection(page, [])).toBe("none");
    expect(dataTableSelection(page, ["2", "9"])).toBe("some");
    expect(dataTableSelection(page, ["3", "1", "2"])).toBe("all");
    expect(dataTableSelection([], ["1"])).toBe("none");
    expect(dataTableToggleAll(page, ["9", "2"])).toEqual(["9", "2", "1", "3"]);
    expect(dataTableToggleAll(page, ["9", "1", "2", "3"])).toEqual(["9"]);
    expect(dataTableToggleRow("2", ["1"], true)).toEqual(["1", "2"]);
    expect(dataTableToggleRow("2", ["1", "2"], true)).toEqual(["1", "2"]);
    expect(dataTableToggleRow("1", ["1", "2"], false)).toEqual(["2"]);
  });

  it("draws a missing value as nothing, never as the word null", () => {
    expect(dataTableCellText(null)).toBe("");
    expect(dataTableCellText(undefined)).toBe("");
    expect(dataTableCellText(0)).toBe("0");
    expect(dataTableCellText("x")).toBe("x");
    expect(dataTableCellText({ a: 1 })).toBe('{"a":1}');
  });
});
