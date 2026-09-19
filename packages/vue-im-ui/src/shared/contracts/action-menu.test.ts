import { describe, expect, it } from "vitest";
import { actionMenuEntries, type FlareActionItem } from "./action-menu";

const kinds = (items: FlareActionItem[]) =>
  actionMenuEntries(items).map((entry) => (entry.kind === "item" ? entry.item.id : "|"));

describe("actionMenuEntries", () => {
  it("keeps host order and separates where the group changes", () => {
    expect(kinds([
      { id: "reply", label: "Reply" },
      { id: "recall", label: "Recall", danger: true },
      { id: "copy", label: "Copy" },
      { id: "delete", label: "Delete", danger: true, group: "danger" },
      { id: "report", label: "Report", danger: true },
    ])).toEqual(["reply", "recall", "copy", "|", "delete", "report"]);
  });

  it("leaves hidden actions out before grouping", () => {
    expect(kinds([
      { id: "copy", label: "Copy" },
      { id: "delete", label: "Delete", group: "danger", visible: false },
      { id: "report", label: "Report", group: "danger" },
    ])).toEqual(["copy", "|", "report"]);
    expect(kinds([{ id: "delete", label: "Delete", group: "danger", visible: false }])).toEqual([]);
  });

  it("draws no leading separator and none between items of the same group", () => {
    expect(kinds([
      { id: "search", label: "Search", group: "view" },
      { id: "details", label: "Details", group: "view" },
      { id: "members", label: "Members", group: "manage" },
    ])).toEqual(["search", "details", "|", "members"]);
    expect(kinds([])).toEqual([]);
  });
});
