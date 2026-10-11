import { describe, expect, it } from "vitest";
import {
  flattenPermissionNodes,
  permissionTreeRows,
  permissionTreeSearch,
  permissionTreeStates,
  permissionTreeToggle,
  type FlarePermissionNode,
} from "./permission-tree";

const nodes: FlarePermissionNode[] = [
  {
    code: "users",
    name: "Users",
    children: [
      { code: "users.read", name: "View users" },
      { code: "users.write", name: "Edit users", description: "Rename, freeze" },
      {
        code: "users.admin",
        name: "User administration",
        children: [
          { code: "users.admin.delete", name: "Delete users" },
          { code: "users.admin.export", name: "Export users" },
        ],
      },
    ],
  },
  {
    code: "groups",
    name: "Groups",
    children: [{ code: "groups.read", name: "View groups" }],
  },
  { code: "billing", name: "Billing" },
];

const entries = flattenPermissionNodes(nodes);
const byCode = new Map(entries.map((entry) => [entry.code, entry]));
const noSearch = permissionTreeSearch(entries, byCode, "");

describe("permission-tree rules", () => {
  it("flattens in document order with depth, parent, leaves and sibling positions", () => {
    expect(entries.map((entry) => entry.code)).toEqual([
      "users", "users.read", "users.write", "users.admin", "users.admin.delete", "users.admin.export", "groups", "groups.read", "billing",
    ]);
    expect(byCode.get("users.admin.delete")).toMatchObject({ depth: 2, parent: "users.admin", isLeaf: true, leafCodes: ["users.admin.delete"], posInSet: 1, setSize: 2 });
    expect(byCode.get("users")?.leafCodes).toEqual(["users.read", "users.write", "users.admin.delete", "users.admin.export"]);
    expect(byCode.get("users")?.childCodes).toEqual(["users.read", "users.write", "users.admin"]);
    expect(byCode.get("billing")).toMatchObject({ depth: 0, parent: null, isLeaf: true, posInSet: 3, setSize: 3 });
  });

  it("derives every parent from the leaves: checked, mixed or clear", () => {
    const states = permissionTreeStates(entries, new Set(["users.read", "users.admin.delete", "users.admin.export", "groups.read"]));
    expect(states.get("users")).toBe("indeterminate");
    expect(states.get("users.admin")).toBe("checked");
    expect(states.get("users.write")).toBe("none");
    expect(states.get("groups")).toBe("checked");
    expect(states.get("billing")).toBe("none");
    expect(permissionTreeStates(entries, new Set()).get("users")).toBe("none");
  });

  it("toggles a leaf, checks or clears a whole group, and leaves disabled leaves alone", () => {
    expect(permissionTreeToggle(byCode.get("billing")!, ["groups.read"], new Set())).toEqual(["groups.read", "billing"]);
    const withUsers = permissionTreeToggle(byCode.get("users")!, ["groups.read"], new Set(["users.write"]));
    expect(withUsers).toEqual(["groups.read", "users.read", "users.admin.delete", "users.admin.export"]);
    expect(permissionTreeToggle(byCode.get("users")!, ["users.read", "users.write", "users.admin.delete", "users.admin.export"], new Set(["users.write"]))).toEqual(["users.write"]);
    // A mixed group checks the rest; it does not clear.
    expect(permissionTreeToggle(byCode.get("users")!, ["users.read"], new Set())).toEqual(["users.read", "users.write", "users.admin.delete", "users.admin.export"]);
    // A leaf that is disabled does not move.
    expect(permissionTreeToggle(byCode.get("billing")!, [], new Set(["billing"]))).toEqual([]);
  });

  it("clears a group once every enabled leaf is on, even while an unchecked disabled leaf keeps it mixed", () => {
    const checked = ["groups.read", "users.read", "users.admin.delete", "users.admin.export"];
    const disabled = new Set(["users.write"]);
    expect(permissionTreeStates(entries, new Set(checked)).get("users")).toBe("indeterminate");
    expect(permissionTreeToggle(byCode.get("users")!, checked, disabled)).toEqual(["groups.read"]);
    // The next activation checks them again: the toggle round-trips.
    expect(permissionTreeToggle(byCode.get("users")!, ["groups.read"], disabled)).toEqual(checked);
  });

  it("keeps the ancestors and descendants of a match visible, and forces the ancestors open", () => {
    const search = permissionTreeSearch(entries, byCode, "DELETE");
    expect([...search.matched]).toEqual(["users.admin.delete"]);
    expect([...search.visible!].sort()).toEqual(["users", "users.admin", "users.admin.delete"]);
    expect([...search.open].sort()).toEqual(["users", "users.admin"]);
    const group = permissionTreeSearch(entries, byCode, "administration");
    expect([...group.visible!].sort()).toEqual(["users", "users.admin", "users.admin.delete", "users.admin.export"]);
    expect(permissionTreeSearch(entries, byCode, "freeze").matched.has("users.write")).toBe(true);
    expect(permissionTreeSearch(entries, byCode, "   ").visible).toBeNull();
  });

  it("draws only the rows under open groups, and a search opens what it must", () => {
    const all = new Set(["users", "users.admin", "groups"]);
    expect(permissionTreeRows(entries, all, noSearch).map((entry) => entry.code)).toHaveLength(9);
    expect(permissionTreeRows(entries, new Set(["users"]), noSearch).map((entry) => entry.code)).toEqual([
      "users", "users.read", "users.write", "users.admin", "groups", "billing",
    ]);
    expect(permissionTreeRows(entries, new Set(), noSearch).map((entry) => entry.code)).toEqual(["users", "groups", "billing"]);
    const search = permissionTreeSearch(entries, byCode, "export");
    expect(permissionTreeRows(entries, new Set(), search).map((entry) => entry.code)).toEqual(["users", "users.admin", "users.admin.export"]);
  });

  it("stays one pass over a thousand nodes", () => {
    const big: FlarePermissionNode[] = Array.from({ length: 20 }, (_, module) => ({
      code: `m${module}`,
      name: `Module ${module}`,
      children: Array.from({ length: 7 }, (_, group) => ({
        code: `m${module}.g${group}`,
        name: `Group ${group}`,
        children: Array.from({ length: 6 }, (_, leaf) => ({ code: `m${module}.g${group}.p${leaf}`, name: `Permission ${leaf}` })),
      })),
    }));
    const flat = flattenPermissionNodes(big);
    expect(flat.length).toBe(20 + 20 * 7 + 20 * 7 * 6);
    const map = new Map(flat.map((entry) => [entry.code, entry]));
    const checked = new Set(flat.filter((entry) => entry.isLeaf && entry.code.endsWith("p1")).map((entry) => entry.code));
    const started = performance.now();
    for (let round = 0; round < 50; round += 1) {
      permissionTreeStates(flat, checked);
      permissionTreeRows(flat, new Set(map.keys()), permissionTreeSearch(flat, map, "Permission 3"));
    }
    // Fifty full recomputations of a 1,000-node tree; a per-node walk would be hundreds of times slower.
    expect(performance.now() - started).toBeLessThan(2000);
  });
});
